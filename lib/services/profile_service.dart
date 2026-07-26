import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/profilepegawai_model.dart';

class PositionHistoryEntry {
  final String jabatan;
  final int tahun;

  const PositionHistoryEntry({
    required this.jabatan,
    required this.tahun,
  });

  bool get isValid => jabatan.trim().isNotEmpty && tahun > 0;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'jabatan': jabatan.trim(),
        'tahun': tahun,
      };

  factory PositionHistoryEntry.fromMap(
    Map<String, dynamic> data,
  ) {
    return PositionHistoryEntry(
      jabatan: _readString(data['jabatan']),
      tahun: _readInt(data['tahun'] ?? data['tahun_jabatan']),
    );
  }
}

class EducationHistoryEntry {
  final String pendidikan;
  final int tahun;

  const EducationHistoryEntry({
    required this.pendidikan,
    required this.tahun,
  });

  bool get isValid => pendidikan.trim().isNotEmpty && tahun > 0;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'pendidikan': pendidikan.trim(),
        'tahun': tahun,
      };

  factory EducationHistoryEntry.fromMap(
    Map<String, dynamic> data,
  ) {
    return EducationHistoryEntry(
      pendidikan: _readString(data['pendidikan']),
      tahun: _readInt(data['tahun'] ?? data['tahun_lulus_pendidikan']),
    );
  }
}

class TrainingHistoryEntry {
  final String latihanJabatan;
  final int tahun;

  const TrainingHistoryEntry({
    required this.latihanJabatan,
    required this.tahun,
  });

  bool get isValid => latihanJabatan.trim().isNotEmpty && tahun > 0;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'latihan_jabatan': latihanJabatan.trim(),
        'tahun': tahun,
      };

  factory TrainingHistoryEntry.fromMap(
    Map<String, dynamic> data,
  ) {
    return TrainingHistoryEntry(
      latihanJabatan: _readString(
        data['latihan_jabatan'] ?? data['nama_diklat'],
      ),
      tahun: _readInt(data['tahun'] ?? data['tahun_latihan_jabatan']),
    );
  }
}

class ProfileExtendedData {
  final String tempatLahir;
  final DateTime? tanggalLahir;
  final String pendidikan;
  final int tahunLulusPendidikan;
  final String latihanJabatan;
  final int tahunLatihanJabatan;
  final List<PositionHistoryEntry> positionHistory;
  final List<EducationHistoryEntry> educationHistory;
  final List<TrainingHistoryEntry> trainingHistory;

  const ProfileExtendedData({
    required this.tempatLahir,
    required this.tanggalLahir,
    required this.pendidikan,
    required this.tahunLulusPendidikan,
    required this.latihanJabatan,
    required this.tahunLatihanJabatan,
    required this.positionHistory,
    required this.educationHistory,
    required this.trainingHistory,
  });

  factory ProfileExtendedData.fromProfile(
    ProfilePegawaiModel profile,
  ) {
    return ProfileExtendedData(
      tempatLahir: profile.tempat_lahir,
      tanggalLahir: profile.tanggal_lahir?.toDate(),
      pendidikan: profile.pendidikan,
      tahunLulusPendidikan: profile.tahun_lulus_pendidikan,
      latihanJabatan: profile.latihan_jabatan,
      tahunLatihanJabatan: profile.tahun_latihan_jabatan,
      positionHistory: <PositionHistoryEntry>[
        PositionHistoryEntry(
          jabatan: profile.jabatan_sekarang,
          tahun: profile.tahun_jabatan_sekarang,
        ),
        PositionHistoryEntry(
          jabatan: profile.jabatan_sebelumnya,
          tahun: profile.tahun_jabatan_sebelumnya,
        ),
      ].where((PositionHistoryEntry item) => item.isValid).toList(),
      educationHistory: <EducationHistoryEntry>[
        EducationHistoryEntry(
          pendidikan: profile.pendidikan,
          tahun: profile.tahun_lulus_pendidikan,
        ),
      ].where((EducationHistoryEntry item) => item.isValid).toList(),
      trainingHistory: <TrainingHistoryEntry>[
        TrainingHistoryEntry(
          latihanJabatan: profile.latihan_jabatan,
          tahun: profile.tahun_latihan_jabatan,
        ),
      ].where((TrainingHistoryEntry item) => item.isValid).toList(),
    );
  }
}

class ProfileService {
  ProfileService._();

  static final ProfileService instance = ProfileService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _profilesCollection = 'table_data_pegawai';
  static const String _usersCollection = 'users';

  Future<ProfileExtendedData> getExtendedProfileData({
    required String uid,
    required ProfilePegawaiModel fallbackProfile,
  }) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _db.collection(_profilesCollection).doc(uid).get();

    final Map<String, dynamic> data =
        snapshot.data() ?? <String, dynamic>{};

    final List<PositionHistoryEntry> positionHistory =
        _readPositionHistory(data);
    _addLegacyPositions(positionHistory, data);
    _addUniquePosition(
      positionHistory,
      PositionHistoryEntry(
        jabatan: fallbackProfile.jabatan_sekarang,
        tahun: fallbackProfile.tahun_jabatan_sekarang,
      ),
    );
    _addUniquePosition(
      positionHistory,
      PositionHistoryEntry(
        jabatan: fallbackProfile.jabatan_sebelumnya,
        tahun: fallbackProfile.tahun_jabatan_sebelumnya,
      ),
    );

    final List<EducationHistoryEntry> educationHistory =
        _readEducationHistory(data);
    _addUniqueEducation(
      educationHistory,
      EducationHistoryEntry(
        pendidikan: _readString(
          data['pendidikan'] ?? fallbackProfile.pendidikan,
        ),
        tahun: _readInt(
          data['tahun_lulus_pendidikan'] ??
              fallbackProfile.tahun_lulus_pendidikan,
        ),
      ),
    );

    final List<TrainingHistoryEntry> trainingHistory =
        _readTrainingHistory(data);
    _addUniqueTraining(
      trainingHistory,
      TrainingHistoryEntry(
        latihanJabatan: _readString(
          data['latihan_jabatan'] ?? fallbackProfile.latihan_jabatan,
        ),
        tahun: _readInt(
          data['tahun_latihan_jabatan'] ??
              fallbackProfile.tahun_latihan_jabatan,
        ),
      ),
    );

    final String tempatLahir = _readString(
      data['tempat_lahir'] ?? fallbackProfile.tempat_lahir,
    );

    final DateTime? tanggalLahir = _readDateTime(
      data['tanggal_lahir'] ?? fallbackProfile.tanggal_lahir,
    );

    final String pendidikan = _readString(
      data['pendidikan'] ?? fallbackProfile.pendidikan,
    );
    final int tahunPendidikan = _readInt(
      data['tahun_lulus_pendidikan'] ??
          fallbackProfile.tahun_lulus_pendidikan,
    );

    final String latihanJabatan = _readString(
      data['latihan_jabatan'] ?? fallbackProfile.latihan_jabatan,
    );
    final int tahunLatihan = _readInt(
      data['tahun_latihan_jabatan'] ??
          fallbackProfile.tahun_latihan_jabatan,
    );

    return ProfileExtendedData(
      tempatLahir: tempatLahir,
      tanggalLahir: tanggalLahir,
      pendidikan: pendidikan,
      tahunLulusPendidikan: tahunPendidikan,
      latihanJabatan: latihanJabatan,
      tahunLatihanJabatan: tahunLatihan,
      positionHistory: _sortAndDedupePositions(positionHistory),
      educationHistory:
          _sortAndDedupeEducation(educationHistory),
      trainingHistory: _sortAndDedupeTraining(trainingHistory),
    );
  }

  Future<void> updateEmploymentProfile({
    required String uid,
    required String namaLengkap,
    required String nip,
    required String noTelepon,
    required String statusKepegawaian,
    required String jenisAsn,
    required String pangkat,
    required String tempatLahir,
    required DateTime? tanggalLahir,
    required String jabatanSekarang,
    required int tahunJabatanSekarang,
    required String pendidikan,
    required int tahunLulusPendidikan,
    required String latihanJabatan,
    required int tahunLatihanJabatan,
    required String fotoProfil,
  }) async {
    final String cleanUid = uid.trim();
    final String cleanCurrentPosition = jabatanSekarang.trim();
    final String cleanEducation = pendidikan.trim();
    final String cleanTraining = latihanJabatan.trim();
    final String cleanBirthPlace = tempatLahir.trim();

    if (cleanUid.isEmpty) {
      throw const ProfileServiceException(
        'Sesi pengguna tidak valid.',
      );
    }

    if (namaLengkap.trim().isEmpty) {
      throw const ProfileServiceException(
        'Nama pegawai wajib diisi.',
      );
    }

    if (nip.trim().isEmpty) {
      throw const ProfileServiceException(
        'NIP wajib diisi.',
      );
    }

    if (cleanCurrentPosition.isEmpty ||
        !_isValidYear(tahunJabatanSekarang)) {
      throw const ProfileServiceException(
        'Jabatan dan tahun jabatan sekarang wajib diisi dengan benar.',
      );
    }

    if (cleanBirthPlace.isEmpty != (tanggalLahir == null)) {
      throw const ProfileServiceException(
        'Tempat dan tanggal lahir harus diisi bersama-sama.',
      );
    }

    if (!_isOptionalNameYearPairValid(
      cleanEducation,
      tahunLulusPendidikan,
    )) {
      throw const ProfileServiceException(
        'Pendidikan terakhir dan tahun lulus harus diisi bersama-sama.',
      );
    }

    if (!_isOptionalNameYearPairValid(
      cleanTraining,
      tahunLatihanJabatan,
    )) {
      throw const ProfileServiceException(
        'Nama diklat dan tahun diklat harus diisi bersama-sama.',
      );
    }

    final DocumentReference<Map<String, dynamic>> userRef =
        _db.collection(_usersCollection).doc(cleanUid);
    final DocumentReference<Map<String, dynamic>> profileRef =
        _db.collection(_profilesCollection).doc(cleanUid);

    await _db.runTransaction<void>((Transaction transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> userSnapshot =
          await transaction.get(userRef);
      final DocumentSnapshot<Map<String, dynamic>> profileSnapshot =
          await transaction.get(profileRef);

      if (!userSnapshot.exists) {
        throw const ProfileServiceException(
          'Data akun tidak ditemukan.',
        );
      }

      final Map<String, dynamic> oldData =
          profileSnapshot.data() ?? <String, dynamic>{};

      final List<PositionHistoryEntry> positionHistory =
          _readPositionHistory(oldData);
      _addLegacyPositions(positionHistory, oldData);
      _addUniquePosition(
        positionHistory,
        PositionHistoryEntry(
          jabatan: cleanCurrentPosition,
          tahun: tahunJabatanSekarang,
        ),
      );
      final List<PositionHistoryEntry> sortedPositions =
          _sortAndDedupePositions(positionHistory);

      final PositionHistoryEntry? previousPosition =
          _findPreviousPosition(
        sortedPositions,
        currentPosition: cleanCurrentPosition,
        currentYear: tahunJabatanSekarang,
      );

      final List<EducationHistoryEntry> educationHistory =
          _readEducationHistory(oldData);
      _addUniqueEducation(
        educationHistory,
        EducationHistoryEntry(
          pendidikan: _readString(oldData['pendidikan']),
          tahun: _readInt(oldData['tahun_lulus_pendidikan']),
        ),
      );
      _addUniqueEducation(
        educationHistory,
        EducationHistoryEntry(
          pendidikan: cleanEducation,
          tahun: tahunLulusPendidikan,
        ),
      );
      final List<EducationHistoryEntry> sortedEducation =
          _sortAndDedupeEducation(educationHistory);

      final List<TrainingHistoryEntry> trainingHistory =
          _readTrainingHistory(oldData);
      _addUniqueTraining(
        trainingHistory,
        TrainingHistoryEntry(
          latihanJabatan: _readString(oldData['latihan_jabatan']),
          tahun: _readInt(oldData['tahun_latihan_jabatan']),
        ),
      );
      _addUniqueTraining(
        trainingHistory,
        TrainingHistoryEntry(
          latihanJabatan: cleanTraining,
          tahun: tahunLatihanJabatan,
        ),
      );
      final List<TrainingHistoryEntry> sortedTraining =
          _sortAndDedupeTraining(trainingHistory);

      transaction.update(
        userRef,
        <String, dynamic>{
          'nama_lengkap': namaLengkap.trim(),
          'nip': nip.trim(),
          'no_telepon': noTelepon.trim(),
          'updated_at': FieldValue.serverTimestamp(),
        },
      );

      transaction.set(
        profileRef,
        <String, dynamic>{
          'owner_id': cleanUid,
          'status_kepegawaian': statusKepegawaian.trim(),
          'jenis_asn': jenisAsn.trim(),
          'pangkat': pangkat.trim(),
          'tempat_lahir': cleanBirthPlace,
          'tanggal_lahir': tanggalLahir == null
              ? null
              : Timestamp.fromDate(
                  DateTime(
                    tanggalLahir.year,
                    tanggalLahir.month,
                    tanggalLahir.day,
                  ),
                ),
          'jabatan_sekarang': cleanCurrentPosition,
          'tahun_jabatan_sekarang': tahunJabatanSekarang,
          'jabatan_sebelumnya': previousPosition?.jabatan ?? '',
          'tahun_jabatan_sebelumnya':
              previousPosition?.tahun ?? 0,
          'pendidikan': cleanEducation,
          'tahun_lulus_pendidikan': tahunLulusPendidikan,
          'latihan_jabatan': cleanTraining,
          'tahun_latihan_jabatan': tahunLatihanJabatan,
          'riwayat_jabatan': sortedPositions
              .map((PositionHistoryEntry item) => item.toMap())
              .toList(),
          'riwayat_pendidikan': sortedEducation
              .map((EducationHistoryEntry item) => item.toMap())
              .toList(),
          'riwayat_diklat': sortedTraining
              .map((TrainingHistoryEntry item) => item.toMap())
              .toList(),
          'foto_profil': fotoProfil.trim(),
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  static List<PositionHistoryEntry> _readPositionHistory(
    Map<String, dynamic> data,
  ) {
    final dynamic rawHistory = data['riwayat_jabatan'];
    if (rawHistory is! List) return <PositionHistoryEntry>[];

    return rawHistory
        .whereType<Map>()
        .map(
          (Map<dynamic, dynamic> raw) =>
              PositionHistoryEntry.fromMap(
            Map<String, dynamic>.from(raw),
          ),
        )
        .where((PositionHistoryEntry item) => item.isValid)
        .toList();
  }

  static List<EducationHistoryEntry> _readEducationHistory(
    Map<String, dynamic> data,
  ) {
    final dynamic rawHistory = data['riwayat_pendidikan'];
    if (rawHistory is! List) return <EducationHistoryEntry>[];

    return rawHistory
        .whereType<Map>()
        .map(
          (Map<dynamic, dynamic> raw) =>
              EducationHistoryEntry.fromMap(
            Map<String, dynamic>.from(raw),
          ),
        )
        .where((EducationHistoryEntry item) => item.isValid)
        .toList();
  }

  static List<TrainingHistoryEntry> _readTrainingHistory(
    Map<String, dynamic> data,
  ) {
    final dynamic rawHistory = data['riwayat_diklat'];
    if (rawHistory is! List) return <TrainingHistoryEntry>[];

    return rawHistory
        .whereType<Map>()
        .map(
          (Map<dynamic, dynamic> raw) =>
              TrainingHistoryEntry.fromMap(
            Map<String, dynamic>.from(raw),
          ),
        )
        .where((TrainingHistoryEntry item) => item.isValid)
        .toList();
  }

  static void _addLegacyPositions(
    List<PositionHistoryEntry> history,
    Map<String, dynamic> data,
  ) {
    _addUniquePosition(
      history,
      PositionHistoryEntry(
        jabatan: _readString(data['jabatan_sekarang']),
        tahun: _readInt(data['tahun_jabatan_sekarang']),
      ),
    );
    _addUniquePosition(
      history,
      PositionHistoryEntry(
        jabatan: _readString(data['jabatan_sebelumnya']),
        tahun: _readInt(data['tahun_jabatan_sebelumnya']),
      ),
    );
  }

  static PositionHistoryEntry? _findPreviousPosition(
    List<PositionHistoryEntry> history, {
    required String currentPosition,
    required int currentYear,
  }) {
    final String currentKey =
        '${currentPosition.trim().toLowerCase()}|$currentYear';

    for (final PositionHistoryEntry item in history) {
      if (_positionKey(item) != currentKey) return item;
    }

    return null;
  }

  static List<PositionHistoryEntry> _sortAndDedupePositions(
    List<PositionHistoryEntry> source,
  ) {
    final Map<String, PositionHistoryEntry> unique =
        <String, PositionHistoryEntry>{};

    for (final PositionHistoryEntry item in source) {
      if (!item.isValid) continue;
      unique[_positionKey(item)] = PositionHistoryEntry(
        jabatan: item.jabatan.trim(),
        tahun: item.tahun,
      );
    }

    final List<PositionHistoryEntry> result =
        unique.values.toList()
          ..sort((PositionHistoryEntry a, PositionHistoryEntry b) {
            final int yearCompare = b.tahun.compareTo(a.tahun);
            if (yearCompare != 0) return yearCompare;
            return a.jabatan.toLowerCase().compareTo(
                  b.jabatan.toLowerCase(),
                );
          });
    return result;
  }

  static List<EducationHistoryEntry> _sortAndDedupeEducation(
    List<EducationHistoryEntry> source,
  ) {
    final Map<String, EducationHistoryEntry> unique =
        <String, EducationHistoryEntry>{};

    for (final EducationHistoryEntry item in source) {
      if (!item.isValid) continue;
      unique[_educationKey(item)] = EducationHistoryEntry(
        pendidikan: item.pendidikan.trim(),
        tahun: item.tahun,
      );
    }

    final List<EducationHistoryEntry> result =
        unique.values.toList()
          ..sort((EducationHistoryEntry a, EducationHistoryEntry b) {
            final int yearCompare = b.tahun.compareTo(a.tahun);
            if (yearCompare != 0) return yearCompare;
            return a.pendidikan.toLowerCase().compareTo(
                  b.pendidikan.toLowerCase(),
                );
          });
    return result;
  }

  static List<TrainingHistoryEntry> _sortAndDedupeTraining(
    List<TrainingHistoryEntry> source,
  ) {
    final Map<String, TrainingHistoryEntry> unique =
        <String, TrainingHistoryEntry>{};

    for (final TrainingHistoryEntry item in source) {
      if (!item.isValid) continue;
      unique[_trainingKey(item)] = TrainingHistoryEntry(
        latihanJabatan: item.latihanJabatan.trim(),
        tahun: item.tahun,
      );
    }

    final List<TrainingHistoryEntry> result =
        unique.values.toList()
          ..sort((TrainingHistoryEntry a, TrainingHistoryEntry b) {
            final int yearCompare = b.tahun.compareTo(a.tahun);
            if (yearCompare != 0) return yearCompare;
            return a.latihanJabatan.toLowerCase().compareTo(
                  b.latihanJabatan.toLowerCase(),
                );
          });
    return result;
  }

  static void _addUniquePosition(
    List<PositionHistoryEntry> history,
    PositionHistoryEntry item,
  ) {
    if (!item.isValid) return;
    final String key = _positionKey(item);
    if (!history.any(
      (PositionHistoryEntry current) =>
          _positionKey(current) == key,
    )) {
      history.add(item);
    }
  }

  static void _addUniqueEducation(
    List<EducationHistoryEntry> history,
    EducationHistoryEntry item,
  ) {
    if (!item.isValid) return;
    final String key = _educationKey(item);
    if (!history.any(
      (EducationHistoryEntry current) =>
          _educationKey(current) == key,
    )) {
      history.add(item);
    }
  }

  static void _addUniqueTraining(
    List<TrainingHistoryEntry> history,
    TrainingHistoryEntry item,
  ) {
    if (!item.isValid) return;
    final String key = _trainingKey(item);
    if (!history.any(
      (TrainingHistoryEntry current) =>
          _trainingKey(current) == key,
    )) {
      history.add(item);
    }
  }

  static String _positionKey(PositionHistoryEntry item) =>
      '${item.jabatan.trim().toLowerCase()}|${item.tahun}';

  static String _educationKey(EducationHistoryEntry item) =>
      '${item.pendidikan.trim().toLowerCase()}|${item.tahun}';

  static String _trainingKey(TrainingHistoryEntry item) =>
      '${item.latihanJabatan.trim().toLowerCase()}|${item.tahun}';

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

  static bool _isValidYear(int year) =>
      year >= 1900 && year <= 2200;

  static bool _isOptionalNameYearPairValid(
    String name,
    int year,
  ) {
    if (name.isEmpty && year == 0) return true;
    return name.isNotEmpty && _isValidYear(year);
  }
}

class ProfileServiceException implements Exception {
  final String message;

  const ProfileServiceException(this.message);

  @override
  String toString() => message;
}

String _readString(dynamic value) =>
    value?.toString().trim() ?? '';

int _readInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
