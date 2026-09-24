import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'admin_dashboard_service.dart';
import 'notification_service.dart';

import '../config/sk_definitions.dart';

class AdminSkReviewService {
  AdminSkReviewService._();

  static final AdminSkReviewService instance =
      AdminSkReviewService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> updateStatus({
    required String collection,
    required String documentId,
    required SiapSkReviewStatus status,
  }) async {
    final String cleanCollection = collection.trim();
    final String cleanDocumentId = documentId.trim();

    if (!isSiapSkCollection(cleanCollection)) {
      throw const AdminSkReviewException(
        'Jenis collection SK tidak dikenali.',
      );
    }

    if (cleanDocumentId.isEmpty) {
      throw const AdminSkReviewException(
        'Dokumen SK tidak valid.',
      );
    }

    final String adminUid = await _requireActiveAdmin();
    final DocumentReference<Map<String, dynamic>> reference =
        _db.collection(cleanCollection).doc(cleanDocumentId);
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await reference.get();

    if (!snapshot.exists) {
      throw const AdminSkReviewException(
        'Dokumen SK tidak ditemukan.',
      );
    }

    final Map<String, dynamic> update = <String, dynamic>{
      'status': siapSkStatusValue(status),
      'updated_at': FieldValue.serverTimestamp(),
    };

    if (status == SiapSkReviewStatus.pending) {
      update['reviewed_by'] = FieldValue.delete();
      update['reviewed_at'] = FieldValue.delete();
    } else {
      update['reviewed_by'] = adminUid;
      update['reviewed_at'] = FieldValue.serverTimestamp();
    }

    await reference.update(update);

    final String ownerId =
        snapshot.data()?['owner_id']?.toString().trim() ?? '';

    if (ownerId.isNotEmpty) {
      try {
        await NotificationService.instance.notifySkReviewed(
          ownerId: ownerId,
          collection: cleanCollection,
          documentId: cleanDocumentId,
          status: status,
        );
      } catch (_) {
        // Perubahan status tetap berhasil jika notifikasi gagal dibuat.
      }
    }

    AdminDashboardService.instance.notifyDataChanged();
  }

  Future<String> _requireActiveAdmin() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw const AdminSkReviewException(
        'Sesi admin tidak ditemukan. Silakan login kembali.',
      );
    }

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _db.collection('users').doc(currentUser.uid).get();
    final Map<String, dynamic> data =
        snapshot.data() ?? <String, dynamic>{};
    final String role = data['role']?.toString().trim().toLowerCase() ?? '';
    final String accountStatus =
        data['status_akun']?.toString().trim().toLowerCase() ?? '';
    final bool active =
        accountStatus.isEmpty || accountStatus == 'aktif';

    if (!snapshot.exists || role != 'admin' || !active) {
      throw const AdminSkReviewException(
        'Aksi ini hanya dapat dilakukan oleh admin aktif.',
      );
    }

    return currentUser.uid;
  }
}

class AdminSkReviewException implements Exception {
  final String message;

  const AdminSkReviewException(this.message);

  @override
  String toString() => message;
}
