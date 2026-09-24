import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'admin_dashboard_service.dart';

class AdminUserService {
  AdminUserService._();

  static final AdminUserService instance = AdminUserService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> updateAccountStatus({
    required String userId,
    required bool active,
  }) async {
    final String cleanUserId = userId.trim();
    if (cleanUserId.isEmpty) {
      throw const AdminUserException('UID pengguna tidak valid.');
    }

    final String adminUid = await _requireActiveAdmin();
    if (cleanUserId == adminUid) {
      throw const AdminUserException(
        'Status akun admin yang sedang digunakan tidak dapat diubah.',
      );
    }

    final DocumentReference<Map<String, dynamic>> userReference =
        _db.collection('users').doc(cleanUserId);
    final DocumentSnapshot<Map<String, dynamic>> userSnapshot =
        await userReference.get();

    if (!userSnapshot.exists) {
      throw const AdminUserException('Akun pengguna tidak ditemukan.');
    }

    final Map<String, dynamic> data =
        userSnapshot.data() ?? <String, dynamic>{};
    final String role = data['role']?.toString().trim().toLowerCase() ?? '';

    if (role != 'user') {
      throw const AdminUserException(
        'Hanya akun pegawai yang dapat diaktifkan atau dinonaktifkan.',
      );
    }

    await userReference.update(<String, dynamic>{
      'status_akun': active ? 'Aktif' : 'Nonaktif',
      'updated_at': FieldValue.serverTimestamp(),
    });

    AdminDashboardService.instance.notifyDataChanged();
  }

  Future<String> _requireActiveAdmin() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw const AdminUserException(
        'Sesi admin tidak ditemukan. Silakan login kembali.',
      );
    }

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _db.collection('users').doc(currentUser.uid).get();
    final Map<String, dynamic> data =
        snapshot.data() ?? <String, dynamic>{};
    final String role = data['role']?.toString().trim().toLowerCase() ?? '';
    final String status =
        data['status_akun']?.toString().trim().toLowerCase() ?? '';
    final bool active = status.isEmpty || status == 'aktif';

    if (!snapshot.exists || role != 'admin' || !active) {
      throw const AdminUserException(
        'Aksi ini hanya dapat dilakukan oleh admin aktif.',
      );
    }

    return currentUser.uid;
  }
}

class AdminUserException implements Exception {
  final String message;

  const AdminUserException(this.message);

  @override
  String toString() => message;
}
