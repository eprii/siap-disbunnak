import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/sk_definitions.dart';
import 'sk_comment_service.dart';

class EmployeeSkManagementService {
  EmployeeSkManagementService._();

  static final EmployeeSkManagementService instance =
      EmployeeSkManagementService._();

  static const String _bucket = 'sk';

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  SupabaseClient get _supabase => Supabase.instance.client;

  bool canDelete(EmployeeSkItem item) {
    final SiapSkReviewStatus status = normalizeSiapSkStatus(item.status);
    return status == SiapSkReviewStatus.pending ||
        status == SiapSkReviewStatus.rejected;
  }

  Future<void> deleteOwnedSk(EmployeeSkItem item) async {
    final firebase_auth.User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw const EmployeeSkManagementException(
        'Sesi login tidak ditemukan.',
      );
    }

    final String currentUid = currentUser.uid;
    final bool ownerMatches = item.ownerId.trim().isEmpty
        ? item.collection.contains('/$currentUid/')
        : item.ownerId.trim() == currentUid;

    if (!ownerMatches) {
      throw const EmployeeSkManagementException(
        'Dokumen ini bukan milik akun yang sedang login.',
      );
    }

    if (!canDelete(item)) {
      throw const EmployeeSkManagementException(
        'SK yang sudah disetujui tidak dapat dihapus.',
      );
    }

    final String collectionPath = item.collection.trim();
    final String documentId = item.documentId.trim();

    if (collectionPath.isEmpty || documentId.isEmpty) {
      throw const EmployeeSkManagementException(
        'Referensi dokumen SK tidak valid.',
      );
    }

    try {
      await _db.collection(collectionPath).doc(documentId).delete();
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw const EmployeeSkManagementException(
          'SK tidak dapat dihapus. Status dokumen mungkin sudah berubah.',
        );
      }

      throw EmployeeSkManagementException(
        error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'Gagal menghapus data SK.',
      );
    }

    final String storagePath = item.filePath.trim();
    if (storagePath.isEmpty ||
        storagePath.startsWith('http://') ||
        storagePath.startsWith('https://')) {
      return;
    }

    try {
      await _supabase.storage.from(_bucket).remove(<String>[storagePath]);
    } on StorageException {
      // Metadata Firestore sudah terhapus. File orphan dapat dibersihkan
      // oleh admin tanpa mengembalikan data yang sudah dihapus pengguna.
    } catch (_) {
      // Cleanup file bersifat best-effort karena Firestore dan Supabase
      // tidak mendukung transaksi lintas layanan.
    }
  }
}

class EmployeeSkManagementException implements Exception {
  final String message;

  const EmployeeSkManagementException(this.message);

  @override
  String toString() => message;
}
