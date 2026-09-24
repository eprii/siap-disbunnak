import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config/sk_definitions.dart';
import '../models/notification_model.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String _collectionName = 'notifications';

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _db.collection(_collectionName);

  Stream<List<SiapNotificationModel>> watchCurrentNotifications() {
    final String? uid = _auth.currentUser?.uid;
    if (uid == null || uid.trim().isEmpty) {
      return Stream<List<SiapNotificationModel>>.value(
        const <SiapNotificationModel>[],
      );
    }

    return _notifications
        .where('recipient_id', isEqualTo: uid)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      final List<SiapNotificationModel> items = snapshot.docs
          .map(SiapNotificationModel.fromDocument)
          .toList();

      items.sort(
        (SiapNotificationModel a, SiapNotificationModel b) {
          final DateTime aDate = a.createdAt ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final DateTime bDate = b.createdAt ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        },
      );

      return items;
    });
  }

  Stream<int> watchUnreadCount() {
    return watchCurrentNotifications().map(
      (List<SiapNotificationModel> items) => items
          .where((SiapNotificationModel item) => !item.isRead)
          .length,
    );
  }

  Future<void> markAsRead(String notificationId) async {
    final String uid = _requireCurrentUid();
    final String cleanId = notificationId.trim();

    if (cleanId.isEmpty) return;

    final DocumentReference<Map<String, dynamic>> reference =
        _notifications.doc(cleanId);
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await reference.get();

    if (!snapshot.exists) return;

    final Map<String, dynamic> data =
        snapshot.data() ?? <String, dynamic>{};
    final String recipientId = _readString(data['recipient_id']);

    if (recipientId != uid) {
      throw const NotificationServiceException(
        'Notifikasi ini bukan milik akun yang sedang digunakan.',
      );
    }

    if (data['is_read'] == true) return;

    await reference.update(<String, dynamic>{
      'is_read': true,
      'read_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAllAsRead() async {
    final String uid = _requireCurrentUid();
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _notifications
            .where('recipient_id', isEqualTo: uid)
            .get();

    final List<QueryDocumentSnapshot<Map<String, dynamic>>> unread =
        snapshot.docs
            .where(
              (QueryDocumentSnapshot<Map<String, dynamic>> document) =>
                  document.data()['is_read'] != true,
            )
            .toList();

    if (unread.isEmpty) return;

    for (int start = 0; start < unread.length; start += 400) {
      final int end = (start + 400) > unread.length
          ? unread.length
          : start + 400;
      final WriteBatch batch = _db.batch();

      for (final QueryDocumentSnapshot<Map<String, dynamic>> document
          in unread.sublist(start, end)) {
        batch.update(document.reference, <String, dynamic>{
          'is_read': true,
          'read_at': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    }
  }

  Future<void> notifySkSubmitted({
    required String ownerId,
    required String collection,
    required String documentId,
  }) async {
    final _CurrentAccount sender = await _currentAccount();
    final String label = siapSkLabelForCollection(collection);

    await createNotification(
      recipientId: ownerId,
      recipientRole: 'user',
      eventType: 'sk_submitted',
      category: SiapNotificationCategory.information,
      title: '$label berhasil dikirim',
      message:
          'Dokumen sudah tersimpan dan menunggu pemeriksaan admin.',
      sourceCollection: collection,
      sourceDocumentId: documentId,
      sourceOwnerId: ownerId,
      dedupKey: 'sk_submitted:$collection:$documentId:$ownerId',
    );

    final List<_RecipientAccount> admins = await _activeAdmins();
    for (final _RecipientAccount admin in admins) {
      await createNotification(
        recipientId: admin.uid,
        recipientRole: 'admin',
        eventType: 'sk_submitted',
        category: SiapNotificationCategory.warning,
        title: '${sender.name} mengunggah $label',
        message: 'Dokumen baru menunggu pemeriksaan admin.',
        sourceCollection: collection,
        sourceDocumentId: documentId,
        sourceOwnerId: ownerId,
        dedupKey:
            'sk_submitted:$collection:$documentId:${admin.uid}',
      );
    }
  }

  Future<void> notifySkReviewed({
    required String ownerId,
    required String collection,
    required String documentId,
    required SiapSkReviewStatus status,
  }) async {
    if (status == SiapSkReviewStatus.pending) return;

    final _CurrentAccount reviewer = await _currentAccount();
    final String label = siapSkLabelForCollection(collection);
    final bool approved = status == SiapSkReviewStatus.approved;

    await createNotification(
      recipientId: ownerId,
      recipientRole: 'user',
      eventType: approved ? 'sk_approved' : 'sk_rejected',
      category: approved
          ? SiapNotificationCategory.information
          : SiapNotificationCategory.warning,
      title: approved
          ? '${reviewer.name} menyetujui $label'
          : '${reviewer.name} menolak $label',
      message: approved
          ? 'Dokumen telah diperiksa dan disetujui.'
          : 'Dokumen perlu diperbaiki. Buka Profil untuk melihat detail dan mengunggah ulang.',
      sourceCollection: collection,
      sourceDocumentId: documentId,
      sourceOwnerId: ownerId,
      dedupKey:
          '${approved ? 'approved' : 'rejected'}:$collection:$documentId',
    );
  }

  Future<void> notifyProfileUpdated({
    required String ownerId,
  }) async {
    await createNotification(
      recipientId: ownerId,
      recipientRole: 'user',
      eventType: 'profile_updated',
      category: SiapNotificationCategory.information,
      title: 'Data profil diperbarui',
      message: 'Perubahan data pegawai berhasil disimpan.',
      sourceOwnerId: ownerId,
    );
  }

  Future<void> notifyCommentAdded({
    required String skKey,
    required String commentId,
    required String commentText,
    required String senderName,
    required bool senderIsAdmin,
  }) async {
    final _SkContext? context = await _resolveSkContext(skKey);
    if (context == null || context.ownerId.isEmpty) return;

    final String currentUid = _requireCurrentUid();
    final String cleanSenderName = _displayName(senderName);
    final String excerpt = _notificationExcerpt(commentText);

    if (senderIsAdmin) {
      if (context.ownerId == currentUid) return;

      await createNotification(
        recipientId: context.ownerId,
        recipientRole: 'user',
        eventType: 'comment_added',
        category: SiapNotificationCategory.warning,
        title: '$cleanSenderName mengomentari ${context.label}',
        message: excerpt,
        sourceCollection: context.collection,
        sourceDocumentId: context.documentId,
        sourceOwnerId: context.ownerId,
        dedupKey:
            'comment:$commentId:${context.ownerId}',
      );
      return;
    }

    if (currentUid != context.ownerId) {
      // User biasa tidak boleh mengirim notifikasi ke user lain.
      return;
    }

    final List<_RecipientAccount> admins = await _activeAdmins();
    for (final _RecipientAccount admin in admins) {
      if (admin.uid == currentUid) continue;

      await createNotification(
        recipientId: admin.uid,
        recipientRole: 'admin',
        eventType: 'comment_added',
        category: SiapNotificationCategory.warning,
        title: '$cleanSenderName berkomentar pada ${context.label}',
        message: excerpt,
        sourceCollection: context.collection,
        sourceDocumentId: context.documentId,
        sourceOwnerId: context.ownerId,
        dedupKey: 'comment:$commentId:${admin.uid}',
      );
    }
  }

  Future<void> notifyReplyAdded({
    required String commentId,
    required String replyId,
    required String replyText,
    required String senderName,
    required bool senderIsAdmin,
  }) async {
    final DocumentSnapshot<Map<String, dynamic>> comment =
        await _db.collection('comments').doc(commentId.trim()).get();

    if (!comment.exists) return;

    final Map<String, dynamic> data =
        comment.data() ?? <String, dynamic>{};
    final String commentOwnerId = _readString(data['owner_id']);
    final String skKey = _readString(data['sk_id']);
    final _SkContext? context = await _resolveSkContext(skKey);
    final String currentUid = _requireCurrentUid();
    final String cleanSenderName = _displayName(senderName);
    final String excerpt = _notificationExcerpt(replyText);

    if (commentOwnerId.isNotEmpty && commentOwnerId != currentUid) {
      final _RecipientAccount? recipient =
          await _recipientAccount(commentOwnerId);

      if (recipient != null &&
          (senderIsAdmin || recipient.role == 'admin')) {
        await createNotification(
          recipientId: recipient.uid,
          recipientRole: recipient.role,
          eventType: 'reply_added',
          category: SiapNotificationCategory.warning,
          title: context == null
              ? '$cleanSenderName membalas komentarmu'
              : '$cleanSenderName membalas pada ${context.label}',
          message: excerpt,
          sourceCollection: context?.collection ?? '',
          sourceDocumentId: context?.documentId ?? '',
          sourceOwnerId: context?.ownerId ?? '',
          dedupKey: 'reply:$replyId:${recipient.uid}',
        );
      }
      return;
    }

    final String skOwnerId = context?.ownerId ?? '';
    if (senderIsAdmin) {
      if (skOwnerId.isEmpty || skOwnerId == currentUid) return;

      await createNotification(
        recipientId: skOwnerId,
        recipientRole: 'user',
        eventType: 'reply_added',
        category: SiapNotificationCategory.warning,
        title: context == null
            ? '$cleanSenderName mengirim balasan'
            : '$cleanSenderName membalas pada ${context.label}',
        message: excerpt,
        sourceCollection: context?.collection ?? '',
        sourceDocumentId: context?.documentId ?? '',
        sourceOwnerId: skOwnerId,
        dedupKey: 'reply:$replyId:$skOwnerId',
      );
      return;
    }

    if (skOwnerId.isEmpty || currentUid != skOwnerId) return;

    final List<_RecipientAccount> admins = await _activeAdmins();
    for (final _RecipientAccount admin in admins) {
      if (admin.uid == currentUid) continue;

      await createNotification(
        recipientId: admin.uid,
        recipientRole: 'admin',
        eventType: 'reply_added',
        category: SiapNotificationCategory.warning,
        title: context == null
            ? '$cleanSenderName mengirim balasan'
            : '$cleanSenderName membalas pada ${context.label}',
        message: excerpt,
        sourceCollection: context?.collection ?? '',
        sourceDocumentId: context?.documentId ?? '',
        sourceOwnerId: skOwnerId,
        dedupKey: 'reply:$replyId:${admin.uid}',
      );
    }
  }

  Future<void> createNotification({
    required String recipientId,
    required String recipientRole,
    required String eventType,
    required SiapNotificationCategory category,
    required String title,
    required String message,
    String sourceCollection = '',
    String sourceDocumentId = '',
    String sourceOwnerId = '',
    String dedupKey = '',
  }) async {
    final String senderId = _requireCurrentUid();
    final String cleanRecipientId = recipientId.trim();

    if (cleanRecipientId.isEmpty) {
      throw const NotificationServiceException(
        'Penerima notifikasi tidak valid.',
      );
    }

    final String cleanDedupKey = dedupKey.trim();
    final DocumentReference<Map<String, dynamic>> reference =
        cleanDedupKey.isEmpty
            ? _notifications.doc()
            : _notifications.doc(
                _notificationDocumentId(
                  cleanRecipientId,
                  cleanDedupKey,
                ),
              );

    if (cleanDedupKey.isNotEmpty) {
      final DocumentSnapshot<Map<String, dynamic>> existing =
          await reference.get();
      if (existing.exists) return;
    }

    await reference.set(<String, dynamic>{
      'recipient_id': cleanRecipientId,
      'recipient_role': _normalizeRole(recipientRole),
      'sender_id': senderId,
      'event_type': _limit(eventType, 80),
      'category': siapNotificationCategoryValue(category),
      'source_collection': _limit(sourceCollection, 200),
      'source_document_id': _limit(sourceDocumentId, 200),
      'source_owner_id': _limit(sourceOwnerId, 200),
      'title': _limit(title, 140),
      'message': _limit(message, 500),
      'is_read': false,
      'created_at': FieldValue.serverTimestamp(),
      'read_at': null,
      'dedup_key': _limit(cleanDedupKey, 300),
    });
  }

  Future<_CurrentAccount> _currentAccount() async {
    final String uid = _requireCurrentUid();
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _db.collection('users').doc(uid).get();
    final Map<String, dynamic> data =
        snapshot.data() ?? <String, dynamic>{};

    return _CurrentAccount(
      name: _readString(data['nama_lengkap']).isEmpty
          ? _auth.currentUser?.email ?? 'Pengguna'
          : _readString(data['nama_lengkap']),
    );
  }

  Future<List<_RecipientAccount>> _activeAdmins() async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _db
        .collection('users')
        .where('role', whereIn: const <String>['admin', 'Admin'])
        .get();

    return snapshot.docs
        .where((QueryDocumentSnapshot<Map<String, dynamic>> document) {
          final String status = _readString(
            document.data()['status_akun'],
          ).toLowerCase();
          return status.isEmpty || status == 'aktif';
        })
        .map(
          (QueryDocumentSnapshot<Map<String, dynamic>> document) =>
              _RecipientAccount(
            uid: document.id,
            role: 'admin',
          ),
        )
        .toList();
  }

  Future<_RecipientAccount?> _recipientAccount(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _db.collection('users').doc(uid.trim()).get();
    if (!snapshot.exists) return null;

    final Map<String, dynamic> data =
        snapshot.data() ?? <String, dynamic>{};
    return _RecipientAccount(
      uid: snapshot.id,
      role: _normalizeRole(_readString(data['role'])),
    );
  }

  Future<_SkContext?> _resolveSkContext(String skKey) async {
    final String cleanKey = skKey.trim();
    final int separator = cleanKey.lastIndexOf(':');

    if (separator <= 0 || separator >= cleanKey.length - 1) {
      return null;
    }

    final String collection = cleanKey.substring(0, separator);
    final String documentId = cleanKey.substring(separator + 1);
    final DocumentReference<Map<String, dynamic>> reference;

    if (collection.contains('/')) {
      reference = _db.doc('$collection/$documentId');
    } else {
      reference = _db.collection(collection).doc(documentId);
    }

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await reference.get();
    final Map<String, dynamic> data =
        snapshot.data() ?? <String, dynamic>{};

    String ownerId = _readString(data['owner_id']);
    if (ownerId.isEmpty && collection.startsWith('sk/')) {
      final List<String> segments = collection.split('/');
      if (segments.length >= 2) ownerId = segments[1];
    }

    return _SkContext(
      collection: collection,
      documentId: documentId,
      ownerId: ownerId,
      label: _labelForSourceCollection(collection),
    );
  }

  String _requireCurrentUid() {
    final String? uid = _auth.currentUser?.uid;
    if (uid == null || uid.trim().isEmpty) {
      throw const NotificationServiceException(
        'Sesi pengguna tidak ditemukan. Silakan login kembali.',
      );
    }
    return uid;
  }

  static String _labelForSourceCollection(String collection) {
    if (!collection.contains('/')) {
      return siapSkLabelForCollection(collection);
    }

    final String alias = collection.split('/').last.toLowerCase();
    if (alias.contains('cpns')) return 'SK CPNS';
    if (alias == 'pns' || alias.contains('sk_pns')) return 'SK PNS';
    if (alias.contains('pangkat')) return 'SK Pangkat';
    if (alias.contains('jabatan')) return 'SK Jabatan';
    if (alias.contains('pendidikan')) return 'SK Pendidikan';
    if (alias.contains('diklat')) return 'SK Diklat';
    if (alias.contains('penghargaan')) return 'SK Penghargaan';
    if (alias.contains('kgb')) return 'SK KGB';
    if (alias.contains('cuti')) return 'SK Cuti';
    if (alias.contains('angka_kredit')) return 'SK Angka Kredit';
    if (alias.contains('penugasan')) return 'SK Penugasan Tim';
    return 'Dokumen SK';
  }

  static String _notificationDocumentId(
    String recipientId,
    String dedupKey,
  ) {
    final String value = '$recipientId:$dedupKey'
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');

    if (value.length <= 600) return value;
    return value.substring(0, 600);
  }

  static String _normalizeRole(String value) {
    return value.trim().toLowerCase() == 'admin' ? 'admin' : 'user';
  }

  static String _limit(String value, int maxLength) {
    final String clean = value.trim();
    if (clean.length <= maxLength) return clean;
    return clean.substring(0, maxLength);
  }

  static String _displayName(String value) {
    final String clean = value.trim();
    return clean.isEmpty ? 'Pengguna' : clean;
  }

  static String _notificationExcerpt(String value) {
    final String clean = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.isEmpty) return 'Buka notifikasi untuk melihat detail.';
    if (clean.length <= 120) return clean;
    return '${clean.substring(0, 117)}...';
  }

  static String _readString(dynamic value) =>
      value?.toString().trim() ?? '';
}

class _CurrentAccount {
  final String name;

  const _CurrentAccount({
    required this.name,
  });
}

class _RecipientAccount {
  final String uid;
  final String role;

  const _RecipientAccount({
    required this.uid,
    required this.role,
  });
}

class _SkContext {
  final String collection;
  final String documentId;
  final String ownerId;
  final String label;

  const _SkContext({
    required this.collection,
    required this.documentId,
    required this.ownerId,
    required this.label,
  });
}

class NotificationServiceException implements Exception {
  final String message;

  const NotificationServiceException(this.message);

  @override
  String toString() => message;
}
