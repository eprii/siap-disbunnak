import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'pegawai_directory_service.dart';

class SavedUserRecord {
  final String bookmarkId;
  final String adminId;
  final String ownerId;
  final DateTime? savedAt;
  final PegawaiDirectoryItem? employee;

  const SavedUserRecord({
    required this.bookmarkId,
    required this.adminId,
    required this.ownerId,
    required this.savedAt,
    required this.employee,
  });
}

class SavedUserService {
  SavedUserService._();

  static final SavedUserService instance = SavedUserService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<SavedUserRecord>> watchSavedUsers() {
    final String adminId = _requireAdminUid();

    return _db
        .collection('table_simpan_user')
        .where('admin_id', isEqualTo: adminId)
        .snapshots()
        .asyncMap(
      (QuerySnapshot<Map<String, dynamic>> snapshot) async {
        final Map<String, Future<PegawaiDirectoryItem?>> employeeFutures =
            <String, Future<PegawaiDirectoryItem?>>{};

        final List<SavedUserRecord> records = await Future.wait(
          snapshot.docs.map(
            (QueryDocumentSnapshot<Map<String, dynamic>> document) async {
              final Map<String, dynamic> data = document.data();
              final String ownerId = _readString(data['owner_id']);
              final Future<PegawaiDirectoryItem?> employeeFuture =
                  employeeFutures.putIfAbsent(
                ownerId,
                () => PegawaiDirectoryService.instance.getEmployee(ownerId),
              );

              return SavedUserRecord(
                bookmarkId: document.id,
                adminId: _readString(data['admin_id']),
                ownerId: ownerId,
                savedAt: _readDateTime(data['saved_at']),
                employee: await employeeFuture,
              );
            },
          ),
        );

        records.sort((SavedUserRecord a, SavedUserRecord b) {
          final DateTime aDate =
              a.savedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final DateTime bDate =
              b.savedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });

        return records;
      },
    );
  }

  Stream<Set<String>> watchSavedOwnerIds() {
    final String adminId = _requireAdminUid();

    return _db
        .collection('table_simpan_user')
        .where('admin_id', isEqualTo: adminId)
        .snapshots()
        .map(
      (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> document) =>
                _readString(document.data()['owner_id']),
          )
          .where((String ownerId) => ownerId.isNotEmpty)
          .toSet(),
    );
  }

  Future<void> saveUser(String ownerId) async {
    final String adminId = _requireAdminUid();
    final String cleanOwnerId = ownerId.trim();

    if (cleanOwnerId.isEmpty) {
      throw const SavedUserException('Pegawai yang dipilih tidak valid.');
    }

    final String bookmarkId = _bookmarkId(
      adminId: adminId,
      ownerId: cleanOwnerId,
    );

    await _db.collection('table_simpan_user').doc(bookmarkId).set(
      <String, dynamic>{
        'admin_id': adminId,
        'owner_id': cleanOwnerId,
        'saved_at': FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> removeUser(String ownerId) async {
    final String adminId = _requireAdminUid();
    final String cleanOwnerId = ownerId.trim();

    if (cleanOwnerId.isEmpty) {
      throw const SavedUserException('Pegawai yang dipilih tidak valid.');
    }

    await _db
        .collection('table_simpan_user')
        .doc(
          _bookmarkId(
            adminId: adminId,
            ownerId: cleanOwnerId,
          ),
        )
        .delete();
  }

  Future<void> removeBookmark(String bookmarkId) async {
    final String cleanBookmarkId = bookmarkId.trim();
    if (cleanBookmarkId.isEmpty) {
      throw const SavedUserException('Bookmark pegawai tidak valid.');
    }

    await _db
        .collection('table_simpan_user')
        .doc(cleanBookmarkId)
        .delete();
  }

  String _requireAdminUid() {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw const SavedUserException('Sesi admin tidak ditemukan.');
    }
    return user.uid;
  }

  static String _bookmarkId({
    required String adminId,
    required String ownerId,
  }) {
    return '${adminId.trim()}_${ownerId.trim()}'
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
  }

  static String _readString(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value.trim());
    return null;
  }
}

class SavedUserException implements Exception {
  final String message;

  const SavedUserException(this.message);

  @override
  String toString() => message;
}
