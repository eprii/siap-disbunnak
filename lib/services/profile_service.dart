import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/profilepegawai_model.dart';
import 'notification_service.dart';

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
      pendidikan: _readString(
        data['pendidikan'] ?? data['jenjang'],
      ),
      tahun: _readInt(
        data['tahun'] ??
            data['tahun_lulus'] ??
            data['tahun_lulus_pendidikan'],
      ),
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
      tahun: _readInt(
        data['tahun'] ?? data['tahun_latihan_jabatan'],
      ),
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
    _addLegacyPreviousPosition(positionHistory, data);
    _addUniquePosition(
      positionHistory,
      PositionHistoryEntry(
        jabatan: fallbackProfile.jabatan_sebelumnya,
        tahun: fallbackProfile.tahun_jabatan_sebelumnya,
      ),
    );
    final List<PositionHistoryEntry> sortedPositions =
        _sortAndDedupePositions(
      positionHistory.where(
        (PositionHistoryEntry item) => !_samePosition(
          item,
          jabatan: fallbackProfile.jabatan_sekarang,
          tahun: fallbackProfile.tahun_jabatan_sekarang,
        ),
      ).toList(),
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
    final List<EducationHistoryEntry> sortedEducation =
        _sortAndDedupeEducation(educationHistory);
    final EducationHistoryEntry? latestEducation =
        _firstEducation(sortedEducation);

    final List<TrainingHistoryEntry> trainingHistory =
        _readTrainingHistory(data);
    _addUniqueTraining(
      trainingHistory,
      TrainingHistoryEntry(
        latihanJabatan: _normalizeTrainingName(
          _readString(
            data['latihan_jabatan'] ??
                fallbackProfile.latihan_jabatan,
          ),
        ),
        tahun: _readInt(
          data['tahun_latihan_jabatan'] ??
              fallbackProfile.tahun_latihan_jabatan,
        ),
      ),
    );
    final List<TrainingHistoryEntry> sortedTraining =
        _sortAndDedupeTraining(trainingHistory);
    final TrainingHistoryEntry? latestTraining =
        _firstTraining(sortedTraining);

    return ProfileExtendedData(
      tempatLahir: _readString(
        data['tempat_lahir'] ?? fallbackProfile.tempat_lahir,
      ),
      tanggalLahir: _readDateTime(
        data['tanggal_lahir'] ?? fallbackProfile.tanggal_lahir,
      ),
      pendidikan: latestEducation?.pendidikan ?? '',
      tahunLulusPendidikan: latestEducation?.tahun ?? 0,
      latihanJabatan: latestTraining?.latihanJabatan ?? '',
      tahunLatihanJabatan: latestTraining?.tahun ?? 0,
      positionHistory: sortedPositions,
      educationHistory: sortedEducation,
      trainingHistory: sortedTraining,
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
    required List<PositionHistoryEntry> positionHistory,
    required bool movePreviousPositionToHistory,
    required List<EducationHistoryEntry> educationHistory,
    required String latihanJabatan,
    required int tahunLatihanJabatan,
    required String fotoProfil,
  }) async {
    final String cleanUid = uid.trim();
    final String cleanCurrentPosition = jabatanSekarang.trim();
    final String cleanBirthPlace = tempatLahir.trim();
    final String cleanTraining = _normalizeTrainingName(
      latihanJabatan,
    );

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

    if (noTelepon.trim().isEmpty) {
      throw const ProfileServiceException(
        'Nomor telepon wajib diisi.',
      );
    }

    if (statusKepegawaian.trim().isEmpty) {
      throw const ProfileServiceException(
        'Status kepegawaian wajib dipilih.',
      );
    }

    if (pangkat.trim().isEmpty) {
      throw const ProfileServiceException(
        'Pangkat wajib diisi.',
      );
    }

    if (cleanCurrentPosition.isEmpty ||
        !_isValidYear(tahunJabatanSekarang)) {
      throw const ProfileServiceException(
        'Jabatan dan tahun jabatan sekarang wajib diisi dengan benar.',
      );
    }

    if (cleanBirthPlace.isEmpty || tanggalLahir == null) {
      throw const ProfileServiceException(
        'Tempat dan tanggal lahir wajib diisi.',
      );
    }

    if (positionHistory.isEmpty) {
      throw const ProfileServiceException(
        'Tambahkan minimal satu riwayat jabatan sebelumnya.',
      );
    }

    if (educationHistory.isEmpty) {
      throw const ProfileServiceException(
        'Tambahkan minimal satu riwayat pendidikan.',
      );
    }

    final List<PositionHistoryEntry> basePositionHistory =
        positionHistory
            .where(
              (PositionHistoryEntry item) => !_samePosition(
                item,
                jabatan: cleanCurrentPosition,
                tahun: tahunJabatanSekarang,
              ),
            )
            .toList();

    if (positionHistory.any(
      (PositionHistoryEntry item) => !item.isValid,
    )) {
      throw const ProfileServiceException(
        'Setiap riwayat jabatan harus memiliki nama jabatan dan tahun yang valid.',
      );
    }

    final List<EducationHistoryEntry> sortedEducation =
        _sortAndDedupeEducation(educationHistory);

    if (educationHistory.any(
      (EducationHistoryEntry item) => !item.isValid,
    )) {
      throw const ProfileServiceException(
        'Setiap riwayat pendidikan harus memiliki jenjang dan tahun lulus yang valid.',
      );
    }

    if (!_isOptionalNameYearPairValid(
      cleanTraining,
      tahunLatihanJabatan,
    )) {
      throw const ProfileServiceException(
        'Nama diklat dan tahun diklat harus diisi bersama-sama, atau kosongkan keduanya.',
      );
    }

    final EducationHistoryEntry? latestEducation =
        _firstEducation(sortedEducation);

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

      final String oldCurrentPosition =
          _readString(oldData['jabatan_sekarang']);
      final int oldCurrentPositionYear =
          _readInt(oldData['tahun_jabatan_sekarang']);
      final bool currentPositionChanged =
          oldCurrentPosition.trim().toLowerCase() !=
                  cleanCurrentPosition.toLowerCase() ||
              oldCurrentPositionYear != tahunJabatanSekarang;

      final List<PositionHistoryEntry> nextPositionHistory =
          List<PositionHistoryEntry>.from(basePositionHistory);

      if (movePreviousPositionToHistory &&
          currentPositionChanged) {
        _addUniquePosition(
          nextPositionHistory,
          PositionHistoryEntry(
            jabatan: oldCurrentPosition,
            tahun: oldCurrentPositionYear,
          ),
        );
      }

      final List<PositionHistoryEntry> sortedPositions =
          _sortAndDedupePositions(
        nextPositionHistory.where(
          (PositionHistoryEntry item) => !_samePosition(
            item,
            jabatan: cleanCurrentPosition,
            tahun: tahunJabatanSekarang,
          ),
        ).toList(),
      );
      final PositionHistoryEntry? previousPosition =
          _firstPosition(sortedPositions);

      final List<TrainingHistoryEntry> trainingHistory =
          _readTrainingHistory(oldData);
      _addUniqueTraining(
        trainingHistory,
        TrainingHistoryEntry(
          latihanJabatan: _normalizeTrainingName(
            _readString(oldData['latihan_jabatan']),
          ),
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
      final TrainingHistoryEntry? latestTraining =
          _firstTraining(sortedTraining);

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
          'tahun_jabatan_sebelumnya': previousPosition?.tahun ?? 0,
          'pendidikan': latestEducation?.pendidikan ?? '',
          'tahun_lulus_pendidikan': latestEducation?.tahun ?? 0,
          'latihan_jabatan': latestTraining?.latihanJabatan ?? '',
          'tahun_latihan_jabatan': latestTraining?.tahun ?? 0,
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

    try {
      await NotificationService.instance.notifyProfileUpdated(
        ownerId: cleanUid,
      );
    } catch (_) {
      // Penyimpanan profil tidak dibatalkan jika notifikasi gagal dibuat.
    }
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

  static void _addLegacyPreviousPosition(
    List<PositionHistoryEntry> history,
    Map<String, dynamic> data,
  ) {
    _addUniquePosition(
      history,
      PositionHistoryEntry(
        jabatan: _readString(data['jabatan_sebelumnya']),
        tahun: _readInt(data['tahun_jabatan_sebelumnya']),
      ),
    );
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

    final List<PositionHistoryEntry> result = unique.values.toList()
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
      final String level = item.pendidikan.trim();
      unique[level.toLowerCase()] = EducationHistoryEntry(
        pendidikan: level,
        tahun: item.tahun,
      );
    }

    final List<EducationHistoryEntry> result = unique.values.toList()
      ..sort((EducationHistoryEntry a, EducationHistoryEntry b) {
        final int yearCompare = b.tahun.compareTo(a.tahun);
        if (yearCompare != 0) return yearCompare;
        final int rankCompare = _educationRank(
          b.pendidikan,
        ).compareTo(_educationRank(a.pendidikan));
        if (rankCompare != 0) return rankCompare;
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
      final String normalizedName = _normalizeTrainingName(
        item.latihanJabatan,
      );
      final TrainingHistoryEntry normalized = TrainingHistoryEntry(
        latihanJabatan: normalizedName,
        tahun: item.tahun,
      );
      if (!normalized.isValid) continue;
      unique[_trainingKey(normalized)] = normalized;
    }

    final List<TrainingHistoryEntry> result = unique.values.toList()
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
    final String levelKey = item.pendidikan.trim().toLowerCase();
    final int existingIndex = history.indexWhere(
      (EducationHistoryEntry current) =>
          current.pendidikan.trim().toLowerCase() == levelKey,
    );
    if (existingIndex >= 0) {
      if (item.tahun >= history[existingIndex].tahun) {
        history[existingIndex] = item;
      }
      return;
    }
    history.add(item);
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

  static PositionHistoryEntry? _firstPosition(
    List<PositionHistoryEntry> values,
  ) {
    return values.isEmpty ? null : values.first;
  }

  static EducationHistoryEntry? _firstEducation(
    List<EducationHistoryEntry> values,
  ) {
    return values.isEmpty ? null : values.first;
  }

  static TrainingHistoryEntry? _firstTraining(
    List<TrainingHistoryEntry> values,
  ) {
    return values.isEmpty ? null : values.first;
  }

  static int _educationRank(String value) {
    switch (value.trim().toUpperCase()) {
      case 'SD':
        return 1;
      case 'SMP':
        return 2;
      case 'SMA/SMK':
        return 3;
      case 'D-I':
        return 4;
      case 'D-II':
        return 5;
      case 'D-III':
        return 6;
      case 'D-IV':
        return 7;
      case 'S-1':
        return 8;
      case 'S-2':
        return 9;
      case 'S-3':
        return 10;
      default:
        return 0;
    }
  }

  static String _normalizeTrainingName(String value) {
    final String clean = value.trim();
    final String lower = clean.toLowerCase();
    if (lower.isEmpty ||
        lower == '-' ||
        lower == 'tidak ada' ||
        lower == 'belum ada') {
      return '';
    }
    return clean;
  }

  static bool _samePosition(
    PositionHistoryEntry item, {
    required String jabatan,
    required int tahun,
  }) {
    return item.jabatan.trim().toLowerCase() ==
            jabatan.trim().toLowerCase() &&
        item.tahun == tahun;
  }

  static String _positionKey(PositionHistoryEntry item) =>
      '${item.jabatan.trim().toLowerCase()}|${item.tahun}';

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
