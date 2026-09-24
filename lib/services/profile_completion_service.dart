import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileCompletionStatus {
  final bool isComplete;
  final bool isAdmin;
  final List<String> missingFields;

  const ProfileCompletionStatus({
    required this.isComplete,
    required this.isAdmin,
    required this.missingFields,
  });

  const ProfileCompletionStatus.complete({
    this.isAdmin = false,
  })  : isComplete = true,
        missingFields = const <String>[];

  String get missingFieldsText => missingFields.join(', ');
}

class ProfileCompletionService {
  ProfileCompletionService._();

  static final ProfileCompletionService instance =
      ProfileCompletionService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<ProfileCompletionStatus> checkCurrentUser() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw const ProfileCompletionException(
        'Sesi pengguna tidak ditemukan. Silakan login kembali.',
      );
    }

    return checkUser(user.uid);
  }

  Future<ProfileCompletionStatus> checkUser(String uid) async {
    final String cleanUid = uid.trim();
    if (cleanUid.isEmpty) {
      throw const ProfileCompletionException(
        'Sesi pengguna tidak valid.',
      );
    }

    final List<DocumentSnapshot<Map<String, dynamic>>> snapshots =
        await Future.wait<DocumentSnapshot<Map<String, dynamic>>>(
      <Future<DocumentSnapshot<Map<String, dynamic>>>>[
        _db.collection('users').doc(cleanUid).get(),
        _db.collection('table_data_pegawai').doc(cleanUid).get(),
      ],
    );

    final DocumentSnapshot<Map<String, dynamic>> userSnapshot =
        snapshots[0];
    final DocumentSnapshot<Map<String, dynamic>> profileSnapshot =
        snapshots[1];

    if (!userSnapshot.exists || !profileSnapshot.exists) {
      throw const ProfileCompletionException(
        'Data akun atau profil belum tersedia.',
      );
    }

    final Map<String, dynamic> userData =
        userSnapshot.data() ?? <String, dynamic>{};
    final Map<String, dynamic> profileData =
        profileSnapshot.data() ?? <String, dynamic>{};

    final bool isAdmin =
        _readString(userData['role']).toLowerCase() == 'admin';
    if (isAdmin) {
      return const ProfileCompletionStatus.complete(isAdmin: true);
    }

    final List<String> missing = <String>[];

    if (_readString(userData['nip']).isEmpty) {
      missing.add('NIP');
    }
    if (_readString(userData['no_telepon']).isEmpty) {
      missing.add('nomor telepon');
    }
    if (_readString(profileData['status_kepegawaian']).isEmpty) {
      missing.add('status kepegawaian');
    }
    if (_readString(profileData['pangkat']).isEmpty) {
      missing.add('pangkat');
    }
    if (_readString(profileData['tempat_lahir']).isEmpty) {
      missing.add('tempat lahir');
    }
    if (!_hasDate(profileData['tanggal_lahir'])) {
      missing.add('tanggal lahir');
    }
    if (_readString(profileData['jabatan_sekarang']).isEmpty ||
        _readInt(profileData['tahun_jabatan_sekarang']) <= 0) {
      missing.add('jabatan sekarang dan tahunnya');
    }
    if (!_hasPositionHistory(profileData)) {
      missing.add('riwayat jabatan sebelumnya');
    }
    if (!_hasEducationHistory(profileData)) {
      missing.add('riwayat pendidikan');
    }

    return ProfileCompletionStatus(
      isComplete: missing.isEmpty,
      isAdmin: false,
      missingFields: List<String>.unmodifiable(missing),
    );
  }

  Future<void> requireCompleteProfile({
    required String actionLabel,
  }) async {
    final ProfileCompletionStatus status = await checkCurrentUser();
    if (status.isComplete || status.isAdmin) return;

    throw ProfileIncompleteException(
      'Lengkapi ${status.missingFieldsText} sebelum $actionLabel.',
      missingFields: status.missingFields,
    );
  }

  static bool _hasPositionHistory(Map<String, dynamic> data) {
    final dynamic raw = data['riwayat_jabatan'];
    if (raw is List) {
      final bool hasValidItem = raw.whereType<Map>().any(
            (Map<dynamic, dynamic> item) =>
                _readString(item['jabatan']).isNotEmpty &&
                _readInt(item['tahun'] ?? item['tahun_jabatan']) > 0,
          );
      if (hasValidItem) return true;
    }

    return _readString(data['jabatan_sebelumnya']).isNotEmpty &&
        _readInt(data['tahun_jabatan_sebelumnya']) > 0;
  }

  static bool _hasEducationHistory(Map<String, dynamic> data) {
    final dynamic raw = data['riwayat_pendidikan'];
    if (raw is List) {
      final bool hasValidItem = raw.whereType<Map>().any(
            (Map<dynamic, dynamic> item) =>
                _readString(item['pendidikan'] ?? item['jenjang'])
                    .isNotEmpty &&
                _readInt(
                      item['tahun'] ??
                          item['tahun_lulus'] ??
                          item['tahun_lulus_pendidikan'],
                    ) >
                    0,
          );
      if (hasValidItem) return true;
    }

    return _readString(data['pendidikan']).isNotEmpty &&
        _readInt(data['tahun_lulus_pendidikan']) > 0;
  }

  static bool _hasDate(dynamic value) {
    if (value is Timestamp || value is DateTime) return true;
    return DateTime.tryParse(value?.toString() ?? '') != null;
  }

  static String _readString(dynamic value) =>
      value?.toString().trim() ?? '';

  static int _readInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class ProfileCompletionException implements Exception {
  final String message;

  const ProfileCompletionException(this.message);

  @override
  String toString() => message;
}

class ProfileIncompleteException extends ProfileCompletionException {
  final List<String> missingFields;

  const ProfileIncompleteException(
    super.message, {
    required this.missingFields,
  });
}
