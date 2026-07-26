import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

class PegawaiDirectoryItem {
  final String uid;
  final String username;
  final String namaLengkap;
  final String nip;
  final String email;
  final String nomorTelepon;
  final String role;
  final String statusAkun;
  final String pangkat;
  final String jabatanSekarang;
  final int tahunJabatanSekarang;
  final String statusKepegawaian;
  final String jenisAsn;
  final String fotoProfil;
  final String tempatLahir;
  final DateTime? tanggalLahir;
  final String pendidikan;
  final int tahunLulusPendidikan;
  final String latihanJabatan;
  final int tahunLatihanJabatan;
  final List<PegawaiHistoryItem> riwayatJabatan;
  final List<PegawaiHistoryItem> riwayatPendidikan;
  final List<PegawaiHistoryItem> riwayatDiklat;

  const PegawaiDirectoryItem({
    required this.uid,
    required this.username,
    required this.namaLengkap,
    required this.nip,
    required this.email,
    required this.nomorTelepon,
    required this.role,
    required this.statusAkun,
    required this.pangkat,
    required this.jabatanSekarang,
    required this.tahunJabatanSekarang,
    required this.statusKepegawaian,
    required this.jenisAsn,
    required this.fotoProfil,
    required this.tempatLahir,
    required this.tanggalLahir,
    required this.pendidikan,
    required this.tahunLulusPendidikan,
    required this.latihanJabatan,
    required this.tahunLatihanJabatan,
    required this.riwayatJabatan,
    required this.riwayatPendidikan,
    required this.riwayatDiklat,
  });

  bool get akunAktif {
    final String value = statusAkun.trim().toLowerCase();
    return value.isEmpty || value == 'aktif';
  }

  bool get isAdmin => role.trim().toLowerCase() == 'admin';
}

class PegawaiHistoryItem {
  final String title;
  final int year;

  const PegawaiHistoryItem({
    required this.title,
    required this.year,
  });

  bool get isValid => title.trim().isNotEmpty && year > 0;
}

class PegawaiDirectoryService {
  PegawaiDirectoryService._();

  static final PegawaiDirectoryService instance =
      PegawaiDirectoryService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<PegawaiDirectoryItem>> watchEmployees() {
    return Stream<List<PegawaiDirectoryItem>>.multi(
      (MultiStreamController<List<PegawaiDirectoryItem>> controller) {
        QuerySnapshot<Map<String, dynamic>>? usersSnapshot;
        QuerySnapshot<Map<String, dynamic>>? profilesSnapshot;

        void emit() {
          if (usersSnapshot == null || profilesSnapshot == null) return;

          try {
            controller.add(
              _joinEmployees(
                usersSnapshot!,
                profilesSnapshot!,
              ),
            );
          } catch (error, stackTrace) {
            controller.addError(error, stackTrace);
          }
        }

        final StreamSubscription<QuerySnapshot<Map<String, dynamic>>>
            usersSubscription = _db
                .collection('users')
                .snapshots()
                .listen(
              (QuerySnapshot<Map<String, dynamic>> snapshot) {
                usersSnapshot = snapshot;
                emit();
              },
              onError: controller.addError,
            );

        final StreamSubscription<QuerySnapshot<Map<String, dynamic>>>
            profilesSubscription = _db
                .collection('table_data_pegawai')
                .snapshots()
                .listen(
              (QuerySnapshot<Map<String, dynamic>> snapshot) {
                profilesSnapshot = snapshot;
                emit();
              },
              onError: controller.addError,
            );

        controller.onCancel = () async {
          await usersSubscription.cancel();
          await profilesSubscription.cancel();
        };
      },
      isBroadcast: true,
    );
  }

  Stream<PegawaiDirectoryItem?> watchEmployee(String uid) {
    final String cleanUid = uid.trim();

    return Stream<PegawaiDirectoryItem?>.multi(
      (MultiStreamController<PegawaiDirectoryItem?> controller) {
        DocumentSnapshot<Map<String, dynamic>>? userSnapshot;
        DocumentSnapshot<Map<String, dynamic>>? profileSnapshot;

        void emit() {
          if (userSnapshot == null || profileSnapshot == null) return;

          if (!userSnapshot!.exists) {
            controller.add(null);
            return;
          }

          controller.add(
            _mapEmployeeData(
              userDocumentId: userSnapshot!.id,
              userData: userSnapshot!.data() ?? <String, dynamic>{},
              profileData:
                  profileSnapshot!.data() ?? <String, dynamic>{},
            ),
          );
        }

        final StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>
            userSubscription = _db
                .collection('users')
                .doc(cleanUid)
                .snapshots()
                .listen(
              (DocumentSnapshot<Map<String, dynamic>> snapshot) {
                userSnapshot = snapshot;
                emit();
              },
              onError: controller.addError,
            );

        final StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>
            profileSubscription = _db
                .collection('table_data_pegawai')
                .doc(cleanUid)
                .snapshots()
                .listen(
              (DocumentSnapshot<Map<String, dynamic>> snapshot) {
                profileSnapshot = snapshot;
                emit();
              },
              onError: controller.addError,
            );

        controller.onCancel = () async {
          await userSubscription.cancel();
          await profileSubscription.cancel();
        };
      },
      isBroadcast: true,
    );
  }

  Future<PegawaiDirectoryItem?> getEmployee(String uid) async {
    final String cleanUid = uid.trim();
    if (cleanUid.isEmpty) return null;

    final List<DocumentSnapshot<Map<String, dynamic>>> snapshots =
        await Future.wait<DocumentSnapshot<Map<String, dynamic>>>(
      <Future<DocumentSnapshot<Map<String, dynamic>>>>[
        _db.collection('users').doc(cleanUid).get(),
        _db.collection('table_data_pegawai').doc(cleanUid).get(),
      ],
    );

    if (!snapshots[0].exists) return null;

    return _mapEmployeeData(
      userDocumentId: snapshots[0].id,
      userData: snapshots[0].data() ?? <String, dynamic>{},
      profileData: snapshots[1].data() ?? <String, dynamic>{},
    );
  }

  List<PegawaiDirectoryItem> _joinEmployees(
    QuerySnapshot<Map<String, dynamic>> usersSnapshot,
    QuerySnapshot<Map<String, dynamic>> profilesSnapshot,
  ) {
    final Map<String, Map<String, dynamic>> profilesByUid =
        <String, Map<String, dynamic>>{};

    for (final QueryDocumentSnapshot<Map<String, dynamic>> profileDoc
        in profilesSnapshot.docs) {
      final Map<String, dynamic> data = profileDoc.data();
      final String ownerId = _readString(data['owner_id']);
      profilesByUid[profileDoc.id] = data;
      if (ownerId.isNotEmpty) profilesByUid[ownerId] = data;
    }

    final List<PegawaiDirectoryItem> employees =
        <PegawaiDirectoryItem>[];

    for (final QueryDocumentSnapshot<Map<String, dynamic>> userDoc
        in usersSnapshot.docs) {
      final Map<String, dynamic> userData = userDoc.data();
      final String uid = _readString(userData['uid']).isEmpty
          ? userDoc.id
          : _readString(userData['uid']);

      final PegawaiDirectoryItem item = _mapEmployeeData(
        userDocumentId: userDoc.id,
        userData: userData,
        profileData: profilesByUid[uid] ?? <String, dynamic>{},
      );

      if (item.akunAktif) employees.add(item);
    }

    employees.sort(
      (PegawaiDirectoryItem a, PegawaiDirectoryItem b) =>
          a.namaLengkap.toLowerCase().compareTo(
                b.namaLengkap.toLowerCase(),
              ),
    );

    return employees;
  }

  PegawaiDirectoryItem _mapEmployeeData({
    required String userDocumentId,
    required Map<String, dynamic> userData,
    required Map<String, dynamic> profileData,
  }) {
    final String uid = _readString(userData['uid']).isEmpty
        ? userDocumentId
        : _readString(userData['uid']);

    final String currentPosition =
        _readString(profileData['jabatan_sekarang']);
    final int currentPositionYear =
        _readInt(profileData['tahun_jabatan_sekarang']);
    final String education = _readString(profileData['pendidikan']);
    final int educationYear =
        _readInt(profileData['tahun_lulus_pendidikan']);
    final String training =
        _readString(profileData['latihan_jabatan']);
    final int trainingYear =
        _readInt(profileData['tahun_latihan_jabatan']);

    final List<PegawaiHistoryItem> positionHistory = _readHistory(
      profileData['riwayat_jabatan'],
      titleKeys: const <String>['jabatan'],
      yearKeys: const <String>['tahun', 'tahun_jabatan'],
    );
    _addUniqueHistory(
      positionHistory,
      PegawaiHistoryItem(
        title: currentPosition,
        year: currentPositionYear,
      ),
    );
    _addUniqueHistory(
      positionHistory,
      PegawaiHistoryItem(
        title: _readString(profileData['jabatan_sebelumnya']),
        year: _readInt(profileData['tahun_jabatan_sebelumnya']),
      ),
    );

    final List<PegawaiHistoryItem> educationHistory = _readHistory(
      profileData['riwayat_pendidikan'],
      titleKeys: const <String>['pendidikan', 'jenjang'],
      yearKeys: const <String>[
        'tahun',
        'tahun_lulus',
        'tahun_lulus_pendidikan',
      ],
    );
    _addUniqueHistory(
      educationHistory,
      PegawaiHistoryItem(
        title: education,
        year: educationYear,
      ),
    );

    final List<PegawaiHistoryItem> trainingHistory = _readHistory(
      profileData['riwayat_diklat'],
      titleKeys: const <String>[
        'latihan_jabatan',
        'nama_diklat',
        'nama_kegiatan',
      ],
      yearKeys: const <String>[
        'tahun',
        'tahun_latihan_jabatan',
      ],
    );
    _addUniqueHistory(
      trainingHistory,
      PegawaiHistoryItem(
        title: training,
        year: trainingYear,
      ),
    );

    _sortHistory(positionHistory);
    _sortHistory(educationHistory);
    _sortHistory(trainingHistory);

    return PegawaiDirectoryItem(
      uid: uid,
      username: _readString(userData['username']),
      namaLengkap: _readString(userData['nama_lengkap']).isEmpty
          ? 'Pengguna'
          : _readString(userData['nama_lengkap']),
      nip: _readString(userData['nip']),
      email: _readString(userData['email']),
      nomorTelepon: _readString(userData['no_telepon']),
      role: _readString(userData['role']),
      statusAkun: _readString(userData['status_akun']),
      pangkat: _readString(profileData['pangkat']),
      jabatanSekarang: currentPosition,
      tahunJabatanSekarang: currentPositionYear,
      statusKepegawaian:
          _readString(profileData['status_kepegawaian']),
      jenisAsn: _readString(profileData['jenis_asn']),
      fotoProfil: _readString(profileData['foto_profil']),
      tempatLahir: _readString(profileData['tempat_lahir']),
      tanggalLahir: _readDateTime(profileData['tanggal_lahir']),
      pendidikan: education,
      tahunLulusPendidikan: educationYear,
      latihanJabatan: training,
      tahunLatihanJabatan: trainingYear,
      riwayatJabatan: positionHistory,
      riwayatPendidikan: educationHistory,
      riwayatDiklat: trainingHistory,
    );
  }

  static List<PegawaiHistoryItem> _readHistory(
    dynamic rawHistory, {
    required List<String> titleKeys,
    required List<String> yearKeys,
  }) {
    if (rawHistory is! List) return <PegawaiHistoryItem>[];

    final List<PegawaiHistoryItem> result = <PegawaiHistoryItem>[];

    for (final dynamic rawItem in rawHistory) {
      if (rawItem is! Map) continue;
      final Map<String, dynamic> data =
          Map<String, dynamic>.from(rawItem);

      String title = '';
      for (final String key in titleKeys) {
        title = _readString(data[key]);
        if (title.isNotEmpty) break;
      }

      int year = 0;
      for (final String key in yearKeys) {
        year = _readInt(data[key]);
        if (year > 0) break;
      }

      _addUniqueHistory(
        result,
        PegawaiHistoryItem(title: title, year: year),
      );
    }

    return result;
  }

  static void _addUniqueHistory(
    List<PegawaiHistoryItem> history,
    PegawaiHistoryItem item,
  ) {
    if (!item.isValid) return;

    final String key =
        '${item.title.trim().toLowerCase()}|${item.year}';

    final bool alreadyExists = history.any(
      (PegawaiHistoryItem current) =>
          '${current.title.trim().toLowerCase()}|${current.year}' == key,
    );

    if (!alreadyExists) history.add(item);
  }

  static void _sortHistory(List<PegawaiHistoryItem> history) {
    history.sort(
      (PegawaiHistoryItem a, PegawaiHistoryItem b) {
        final int yearCompare = b.year.compareTo(a.year);
        if (yearCompare != 0) return yearCompare;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      },
    );
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
