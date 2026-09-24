import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config/sk_definitions.dart';
import 'pegawai_directory_service.dart';
import 'sk_comment_service.dart';

class SavedSkRecord {
  final String bookmarkId;
  final String adminId;
  final String ownerId;
  final String skId;
  final String skCollection;
  final DateTime? savedAt;
  final PegawaiDirectoryItem? employee;
  final EmployeeSkItem? sk;

  const SavedSkRecord({
    required this.bookmarkId,
    required this.adminId,
    required this.ownerId,
    required this.skId,
    required this.skCollection,
    required this.savedAt,
    required this.employee,
    required this.sk,
  });

  bool get isAvailable => sk != null;
}

class SavedSkService {
  SavedSkService._();

  static final SavedSkService instance = SavedSkService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<SavedSkRecord>> watchSavedSk() {
    final String adminId = _requireAdminUid();

    return _db
        .collection('table_simpan_data_sk')
        .where('admin_id', isEqualTo: adminId)
        .snapshots()
        .asyncMap(
      (QuerySnapshot<Map<String, dynamic>> snapshot) async {
        final Map<String, Future<PegawaiDirectoryItem?>> employeeFutures =
            <String, Future<PegawaiDirectoryItem?>>{};
        final List<SavedSkRecord> records = await Future.wait(
          snapshot.docs.map(
            (QueryDocumentSnapshot<Map<String, dynamic>> document) =>
                _resolveBookmark(document, employeeFutures),
          ),
        );

        records.sort((SavedSkRecord a, SavedSkRecord b) {
          final DateTime aDate = a.savedAt ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final DateTime bDate = b.savedAt ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });

        return records;
      },
    );
  }

  Future<Set<String>> loadSavedKeys() async {
    final String adminId = _requireAdminUid();
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _db
        .collection('table_simpan_data_sk')
        .where('admin_id', isEqualTo: adminId)
        .get();

    return snapshot.docs.map(
      (QueryDocumentSnapshot<Map<String, dynamic>> document) {
        final Map<String, dynamic> data = document.data();
        return savedKey(
          _readString(data['sk_collection']),
          _readString(data['sk_id']),
        );
      },
    ).where((String key) => key != ':').toSet();
  }

  Future<void> save(EmployeeSkItem item) async {
    final String adminId = _requireAdminUid();
    final String collection = item.collection.trim();
    final String documentId = item.documentId.trim();
    final String ownerId = item.ownerId.trim();

    if (!isSiapSkCollection(collection)) {
      throw const SavedSkException(
        'Dokumen dari struktur arsip lama belum dapat disimpan.',
      );
    }

    if (documentId.isEmpty || ownerId.isEmpty) {
      throw const SavedSkException(
        'Referensi SK atau pemilik dokumen tidak lengkap.',
      );
    }

    final String bookmarkId = _bookmarkId(
      adminId: adminId,
      collection: collection,
      documentId: documentId,
    );

    await _db
        .collection('table_simpan_data_sk')
        .doc(bookmarkId)
        .set(<String, dynamic>{
      'admin_id': adminId,
      'owner_id': ownerId,
      'sk_id': documentId,
      'sk_collection': collection,
      'saved_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeSk(EmployeeSkItem item) async {
    final String adminId = _requireAdminUid();
    final String bookmarkId = _bookmarkId(
      adminId: adminId,
      collection: item.collection,
      documentId: item.documentId,
    );

    await removeBookmark(bookmarkId);
  }

  Future<void> removeBookmark(String bookmarkId) async {
    final String cleanBookmarkId = bookmarkId.trim();
    if (cleanBookmarkId.isEmpty) {
      throw const SavedSkException('Bookmark SK tidak valid.');
    }

    await _db
        .collection('table_simpan_data_sk')
        .doc(cleanBookmarkId)
        .delete();
  }

  static String savedKey(String collection, String documentId) {
    return '${collection.trim()}:${documentId.trim()}';
  }

  Future<SavedSkRecord> _resolveBookmark(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
    Map<String, Future<PegawaiDirectoryItem?>> employeeFutures,
  ) async {
    final Map<String, dynamic> data = document.data();
    final String adminId = _readString(data['admin_id']);
    final String ownerId = _readString(data['owner_id']);
    final String skId = _readString(data['sk_id']);
    final String skCollection = _readString(data['sk_collection']);

    final Future<PegawaiDirectoryItem?> employeeFuture =
        employeeFutures.putIfAbsent(
      ownerId,
      () => PegawaiDirectoryService.instance.getEmployee(ownerId),
    );

    EmployeeSkItem? sk;
    if (isSiapSkCollection(skCollection) && skId.isNotEmpty) {
      final DocumentSnapshot<Map<String, dynamic>> skSnapshot =
          await _db.collection(skCollection).doc(skId).get();

      if (skSnapshot.exists) {
        sk = _mapSk(
          collection: skCollection,
          documentId: skSnapshot.id,
          data: skSnapshot.data() ?? <String, dynamic>{},
          fallbackOwnerId: ownerId,
        );
      }
    }

    return SavedSkRecord(
      bookmarkId: document.id,
      adminId: adminId,
      ownerId: ownerId,
      skId: skId,
      skCollection: skCollection,
      savedAt: _readDateTime(data['saved_at']),
      employee: await employeeFuture,
      sk: sk,
    );
  }

  EmployeeSkItem _mapSk({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
    required String fallbackOwnerId,
  }) {
    final String filePath = _firstString(
      data,
      const <String>['file_pdf', 'file_path', 'file_sk'],
    );
    final String storedFileName = _firstString(
      data,
      const <String>['file_name', 'nama_file', 'nama_dokumen'],
    );

    return EmployeeSkItem(
      collection: collection,
      documentId: documentId,
      ownerId: _readString(data['owner_id']).isEmpty
          ? fallbackOwnerId
          : _readString(data['owner_id']),
      jenisLabel: siapSkLabelForCollection(collection),
      nomor: _firstString(
        data,
        const <String>[
          'nomor_sk_cpns',
          'nomor_sk_pns',
          'nomor_sk_pangkat',
          'nomor_pak',
          'nomor_sertifikat',
          'nomor_ijazah',
          'nomor_sk',
          'nomor_dokumen',
        ],
      ),
      tanggal: _firstDate(
        data,
        const <String>[
          'tanggal_sk_cpns',
          'tanggal_sk_pns',
          'tanggal_sk_pangkat',
          'tanggal_pak',
          'tanggal_sertifikat',
          'tanggal_ijazah',
          'tanggal_sk',
          'tanggal_dokumen',
          'tanggal_mulai',
        ],
      ),
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
  }

  String _requireAdminUid() {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw const SavedSkException('Sesi admin tidak ditemukan.');
    }
    return user.uid;
  }

  static String _bookmarkId({
    required String adminId,
    required String collection,
    required String documentId,
  }) {
    return '${adminId}_${collection.trim()}_${documentId.trim()}'
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
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
      final DateTime? date = _readDateTime(data[key]);
      if (date != null) return date;
    }
    return null;
  }

  static String _fileName(String path) {
    final String clean = path.trim();
    if (clean.isEmpty) return '';
    return clean.split('/').last;
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

class SavedSkException implements Exception {
  final String message;

  const SavedSkException(this.message);

  @override
  String toString() => message;
}
