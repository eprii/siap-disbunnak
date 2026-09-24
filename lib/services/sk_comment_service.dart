import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'notification_service.dart';
import 'profile_completion_service.dart';

class EmployeeSkItem {
  final String collection;
  final String documentId;
  final String ownerId;
  final String jenisLabel;
  final String nomor;
  final DateTime? tanggal;
  final String filePath;
  final String fileName;
  final String status;
  final DateTime? createdAt;
  final Map<String, dynamic> rawData;

  const EmployeeSkItem({
    required this.collection,
    required this.documentId,
    required this.ownerId,
    required this.jenisLabel,
    required this.nomor,
    required this.tanggal,
    required this.filePath,
    required this.fileName,
    required this.status,
    required this.createdAt,
    required this.rawData,
  });

  String get commentKey => '$collection:$documentId';
}

class SkCommentItem {
  final String id;
  final String skId;
  final String ownerId;
  final String namaPengguna;
  final String isiKomentar;
  final int jumlahBalasan;
  final DateTime? createdAt;

  const SkCommentItem({
    required this.id,
    required this.skId,
    required this.ownerId,
    required this.namaPengguna,
    required this.isiKomentar,
    required this.jumlahBalasan,
    required this.createdAt,
  });
}

class SkReplyItem {
  final String id;
  final String commentId;
  final String ownerId;
  final String namaPengguna;
  final String isiBalasan;
  final DateTime? createdAt;

  const SkReplyItem({
    required this.id,
    required this.commentId,
    required this.ownerId,
    required this.namaPengguna,
    required this.isiBalasan,
    required this.createdAt,
  });
}

class SkCommentService {
  SkCommentService._();

  static final SkCommentService instance = SkCommentService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const List<_SkDefinition> _definitions = <_SkDefinition>[
    _SkDefinition(
      collection: 'sk_cpns',
      label: 'SK CPNS',
      numberKeys: <String>['nomor_sk_cpns'],
      dateKeys: <String>['tanggal_sk_cpns'],
      nestedAliases: <String>['cpns', 'sk_cpns'],
    ),
    _SkDefinition(
      collection: 'sk_pns',
      label: 'SK PNS',
      numberKeys: <String>['nomor_sk_pns'],
      dateKeys: <String>['tanggal_sk_pns'],
      nestedAliases: <String>['pns', 'sk_pns'],
    ),
    _SkDefinition(
      collection: 'sk_pangkat',
      label: 'SK Perubahan/Kenaikan Pangkat',
      numberKeys: <String>['nomor_sk_pangkat'],
      dateKeys: <String>['tanggal_sk_pangkat'],
      nestedAliases: <String>['pangkat', 'sk_pangkat'],
    ),
    _SkDefinition(
      collection: 'sk_jabatan',
      label: 'SK Perubahan/Kenaikan Jabatan',
      numberKeys: <String>['nomor_sk'],
      dateKeys: <String>['tanggal_sk'],
      nestedAliases: <String>['jabatan', 'sk_jabatan'],
    ),
    _SkDefinition(
      collection: 'sk_pendidikan',
      label: 'SK Pendidikan',
      numberKeys: <String>['nomor_ijazah', 'nomor_sk'],
      dateKeys: <String>['tanggal_ijazah', 'tanggal_sk'],
      nestedAliases: <String>['pendidikan', 'sk_pendidikan'],
    ),
    _SkDefinition(
      collection: 'sk_diklat',
      label: 'SK Diklat',
      numberKeys: <String>['nomor_sertifikat', 'nomor_sk'],
      dateKeys: <String>['tanggal_sertifikat', 'tanggal_mulai'],
      nestedAliases: <String>['diklat', 'sk_diklat'],
    ),
    _SkDefinition(
      collection: 'sk_penghargaan',
      label: 'SK Penghargaan / Tanda Jasa',
      numberKeys: <String>['nomor_sk', 'kode_penghargaan'],
      dateKeys: <String>['tanggal_sk'],
      nestedAliases: <String>['penghargaan', 'sk_penghargaan'],
    ),
    _SkDefinition(
      collection: 'sk_kgb',
      label: 'SK Kenaikan Gaji Berkala',
      numberKeys: <String>['nomor_sk'],
      dateKeys: <String>['tanggal_sk'],
      nestedAliases: <String>['kgb', 'sk_kgb'],
    ),
    _SkDefinition(
      collection: 'sk_cuti',
      label: 'SK Cuti',
      numberKeys: <String>['nomor_sk'],
      dateKeys: <String>['tanggal_sk'],
      nestedAliases: <String>['cuti', 'sk_cuti'],
    ),
    _SkDefinition(
      collection: 'sk_angka_kredit',
      label: 'SK Angka Kredit',
      numberKeys: <String>['nomor_pak', 'nomor_sk'],
      dateKeys: <String>['tanggal_pak', 'tanggal_sk'],
      nestedAliases: <String>['angka_kredit', 'sk_angka_kredit'],
    ),
    _SkDefinition(
      collection: 'sk_penugasan_tim',
      label: 'SK Penugasan Tim',
      numberKeys: <String>['nomor_sk'],
      dateKeys: <String>['tanggal_sk'],
      nestedAliases: <String>['penugasan_tim', 'sk_penugasan_tim'],
    ),
  ];

  Future<List<EmployeeSkItem>> loadEmployeeSk(String ownerId) async {
    final String cleanOwnerId = ownerId.trim();
    if (cleanOwnerId.isEmpty) return <EmployeeSkItem>[];

    final List<Future<List<EmployeeSkItem>>> requests =
        <Future<List<EmployeeSkItem>>>[];

    for (final _SkDefinition definition in _definitions) {
      requests.add(
        _loadCollection(
          query: _db
              .collection(definition.collection)
              .where('owner_id', isEqualTo: cleanOwnerId),
          definition: definition,
          sourceCollection: definition.collection,
        ),
      );

      for (final String nestedAlias in definition.nestedAliases) {
        requests.add(
          _loadCollection(
            query: _db
                .collection('sk')
                .doc(cleanOwnerId)
                .collection(nestedAlias),
            definition: definition,
            sourceCollection: 'sk/$cleanOwnerId/$nestedAlias',
          ),
        );
      }
    }

    final List<List<EmployeeSkItem>> groups =
        await Future.wait<List<EmployeeSkItem>>(requests);

    final Map<String, EmployeeSkItem> unique =
        <String, EmployeeSkItem>{};

    for (final List<EmployeeSkItem> group in groups) {
      for (final EmployeeSkItem item in group) {
        unique['${item.collection}:${item.documentId}'] = item;
      }
    }

    final List<EmployeeSkItem> result = unique.values.toList()
      ..sort((EmployeeSkItem a, EmployeeSkItem b) {
        final DateTime aDate = a.tanggal ??
            a.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime bDate = b.tanggal ??
            b.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

    return result;
  }

  Future<List<EmployeeSkItem>> _loadCollection({
    required Query<Map<String, dynamic>> query,
    required _SkDefinition definition,
    required String sourceCollection,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await query.get();

    return snapshot.docs.map(
      (QueryDocumentSnapshot<Map<String, dynamic>> doc) {
        final Map<String, dynamic> data = doc.data();
        final String filePath = _firstString(
          data,
          const <String>['file_pdf', 'file_path', 'file_sk'],
        );
        final String storedFileName = _firstString(
          data,
          const <String>['file_name', 'nama_file', 'nama_dokumen'],
        );

        return EmployeeSkItem(
          collection: sourceCollection,
          documentId: doc.id,
          ownerId: _readString(data['owner_id']),
          jenisLabel: definition.label,
          nomor: _firstString(data, definition.numberKeys),
          tanggal: _firstDate(data, definition.dateKeys),
          filePath: filePath,
          fileName: storedFileName.isEmpty
              ? _fileName(filePath)
              : storedFileName,
          status: _firstString(
            data,
            const <String>[
              'status',
              'status_sk',
              'status_verifikasi',
            ],
          ),
          createdAt: _readDateTime(data['created_at']),
          rawData: data,
        );
      },
    ).toList();
  }

  Stream<List<SkCommentItem>> watchComments(String skId) {
    final String cleanSkId = skId.trim();

    return _db
        .collection('comments')
        .where('sk_id', isEqualTo: cleanSkId)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      final List<SkCommentItem> comments = snapshot.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> doc) {
              final Map<String, dynamic> data = doc.data();
              return SkCommentItem(
                id: doc.id,
                skId: _readString(data['sk_id']),
                ownerId: _readString(data['owner_id']),
                namaPengguna: _readString(data['nama_pengguna']).isEmpty
                    ? 'Pengguna'
                    : _readString(data['nama_pengguna']),
                isiKomentar: _readString(data['isi_komentar']),
                jumlahBalasan: _readInt(data['jumlah_balasan']),
                createdAt: _readDateTime(data['created_at']),
              );
            },
          )
          .toList()
        ..sort((SkCommentItem a, SkCommentItem b) {
          final DateTime aDate =
              a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final DateTime bDate =
              b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });

      return comments;
    });
  }

  Stream<List<SkReplyItem>> watchReplies(String commentId) {
    final String cleanCommentId = commentId.trim();

    return _db
        .collection('replies')
        .where('comment_id', isEqualTo: cleanCommentId)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      final List<SkReplyItem> replies = snapshot.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> doc) {
              final Map<String, dynamic> data = doc.data();
              return SkReplyItem(
                id: doc.id,
                commentId: _readString(data['comment_id']),
                ownerId: _readString(data['owner_id']),
                namaPengguna: _readString(data['nama_pengguna']).isEmpty
                    ? 'Pengguna'
                    : _readString(data['nama_pengguna']),
                isiBalasan: _readString(data['isi_balasan']),
                createdAt: _readDateTime(data['created_at']),
              );
            },
          )
          .toList()
        ..sort((SkReplyItem a, SkReplyItem b) {
          final DateTime aDate =
              a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final DateTime bDate =
              b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return aDate.compareTo(bDate);
        });

      return replies;
    });
  }

  Future<void> addComment({
    required String skId,
    required String text,
  }) async {
    final _CurrentUserSnapshot current = await _currentUserSnapshot();
    if (!current.isAdmin) {
      try {
        await ProfileCompletionService.instance.requireCompleteProfile(
          actionLabel: 'mengirim komentar',
        );
      } on ProfileCompletionException catch (error) {
        throw SkCommentException(error.message);
      }
    }

    final String cleanText = text.trim();

    if (cleanText.isEmpty) {
      throw const SkCommentException('Komentar tidak boleh kosong.');
    }

    if (cleanText.length > 1000) {
      throw const SkCommentException(
        'Komentar maksimal 1000 karakter.',
      );
    }

    final DocumentReference<Map<String, dynamic>> commentReference =
        await _db.collection('comments').add(<String, dynamic>{
      'sk_id': skId.trim(),
      'owner_id': current.uid,
      'nama_pengguna': current.name,
      'isi_komentar': cleanText,
      'jumlah_balasan': 0,
      'created_at': FieldValue.serverTimestamp(),
    });

    try {
      await NotificationService.instance.notifyCommentAdded(
        skKey: skId,
        commentId: commentReference.id,
        commentText: cleanText,
        senderName: current.name,
        senderIsAdmin: current.isAdmin,
      );
    } catch (_) {
      // Komentar tetap tersimpan jika notifikasi gagal dibuat.
    }
  }

  Future<void> addReply({
    required String commentId,
    required String text,
  }) async {
    final _CurrentUserSnapshot current = await _currentUserSnapshot();
    if (!current.isAdmin) {
      try {
        await ProfileCompletionService.instance.requireCompleteProfile(
          actionLabel: 'mengirim balasan',
        );
      } on ProfileCompletionException catch (error) {
        throw SkCommentException(error.message);
      }
    }

    final String cleanText = text.trim();

    if (cleanText.isEmpty) {
      throw const SkCommentException('Balasan tidak boleh kosong.');
    }

    if (cleanText.length > 1000) {
      throw const SkCommentException(
        'Balasan maksimal 1000 karakter.',
      );
    }

    final DocumentSnapshot<Map<String, dynamic>> comment =
        await _db.collection('comments').doc(commentId.trim()).get();

    if (!comment.exists) {
      throw const SkCommentException('Komentar sudah tidak tersedia.');
    }

    final DocumentReference<Map<String, dynamic>> replyReference =
        await _db.collection('replies').add(<String, dynamic>{
      'comment_id': commentId.trim(),
      'owner_id': current.uid,
      'nama_pengguna': current.name,
      'isi_balasan': cleanText,
      'created_at': FieldValue.serverTimestamp(),
    });

    try {
      await NotificationService.instance.notifyReplyAdded(
        commentId: commentId,
        replyId: replyReference.id,
        replyText: cleanText,
        senderName: current.name,
        senderIsAdmin: current.isAdmin,
      );
    } catch (_) {
      // Balasan tetap tersimpan jika notifikasi gagal dibuat.
    }
  }

  Future<void> deleteComment(SkCommentItem comment) async {
    final _CurrentUserSnapshot current = await _currentUserSnapshot();
    if (!current.isAdmin && current.uid != comment.ownerId) {
      throw const SkCommentException(
        'Kamu tidak memiliki izin menghapus komentar ini.',
      );
    }

    final QuerySnapshot<Map<String, dynamic>> replies = await _db
        .collection('replies')
        .where('comment_id', isEqualTo: comment.id)
        .limit(1)
        .get();

    if (replies.docs.isNotEmpty) {
      throw const SkCommentException(
        'Komentar yang sudah memiliki balasan tidak dapat dihapus.',
      );
    }

    await _db.collection('comments').doc(comment.id).delete();
  }

  Future<void> deleteReply(SkReplyItem reply) async {
    final _CurrentUserSnapshot current = await _currentUserSnapshot();
    if (!current.isAdmin && current.uid != reply.ownerId) {
      throw const SkCommentException(
        'Kamu tidak memiliki izin menghapus balasan ini.',
      );
    }

    await _db.collection('replies').doc(reply.id).delete();
  }

  Future<_CurrentUserSnapshot> _currentUserSnapshot() async {
    final User? firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      throw const SkCommentException(
        'Sesi pengguna tidak ditemukan. Silakan login kembali.',
      );
    }

    final DocumentSnapshot<Map<String, dynamic>> userDoc =
        await _db.collection('users').doc(firebaseUser.uid).get();
    final Map<String, dynamic> data =
        userDoc.data() ?? <String, dynamic>{};

    final String name = _readString(data['nama_lengkap']).isEmpty
        ? firebaseUser.email ?? 'Pengguna'
        : _readString(data['nama_lengkap']);

    return _CurrentUserSnapshot(
      uid: firebaseUser.uid,
      name: name,
      isAdmin: _readString(data['role']).toLowerCase() == 'admin',
    );
  }

  static String _firstString(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final String value = _readString(data[key]);
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  static DateTime? _firstDate(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final DateTime? value = _readDateTime(data[key]);
      if (value != null) return value;
    }
    return null;
  }

  static String _fileName(String path) {
    final String cleanPath = path.trim();
    if (cleanPath.isEmpty) return '';
    return cleanPath.split('/').last;
  }

  static String _readString(dynamic value) =>
      value?.toString().trim() ?? '';

  static int _readInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '');
  }
}

class _SkDefinition {
  final String collection;
  final String label;
  final List<String> numberKeys;
  final List<String> dateKeys;
  final List<String> nestedAliases;

  const _SkDefinition({
    required this.collection,
    required this.label,
    required this.numberKeys,
    required this.dateKeys,
    this.nestedAliases = const <String>[],
  });
}

class _CurrentUserSnapshot {
  final String uid;
  final String name;
  final bool isAdmin;

  const _CurrentUserSnapshot({
    required this.uid,
    required this.name,
    required this.isAdmin,
  });
}

class SkCommentException implements Exception {
  final String message;

  const SkCommentException(this.message);

  @override
  String toString() => message;
}
