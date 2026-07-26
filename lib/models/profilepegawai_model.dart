import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePegawaiModel {
  final String id;
  final String owner_id;
  final String pangkat;
  final String jabatan_sekarang;
  final int tahun_jabatan_sekarang;
  final String jabatan_sebelumnya;
  final int tahun_jabatan_sebelumnya;
  final String status_kepegawaian;
  final String jenis_asn;
  final String foto_profil;
  final Timestamp updated_at;

  // Data pegawai tambahan. Dibuat opsional agar constructor lama
  // di halaman lain tetap kompatibel.
  final String tempat_lahir;
  final Timestamp? tanggal_lahir;
  final String pendidikan;
  final int tahun_lulus_pendidikan;
  final String latihan_jabatan;
  final int tahun_latihan_jabatan;

  const ProfilePegawaiModel({
    this.id = '',
    required this.owner_id,
    required this.pangkat,
    required this.jabatan_sekarang,
    required this.tahun_jabatan_sekarang,
    required this.jabatan_sebelumnya,
    required this.tahun_jabatan_sebelumnya,
    required this.status_kepegawaian,
    required this.jenis_asn,
    required this.foto_profil,
    required this.updated_at,
    this.tempat_lahir = '',
    this.tanggal_lahir,
    this.pendidikan = '',
    this.tahun_lulus_pendidikan = 0,
    this.latihan_jabatan = '',
    this.tahun_latihan_jabatan = 0,
  });

  factory ProfilePegawaiModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data =
        doc.data() ?? <String, dynamic>{};

    return ProfilePegawaiModel(
      id: doc.id,
      owner_id: _readString(data['owner_id']),
      pangkat: _readString(data['pangkat']),
      jabatan_sekarang: _readString(data['jabatan_sekarang']),
      tahun_jabatan_sekarang:
          _readInt(data['tahun_jabatan_sekarang']),
      jabatan_sebelumnya:
          _readString(data['jabatan_sebelumnya']),
      tahun_jabatan_sebelumnya:
          _readInt(data['tahun_jabatan_sebelumnya']),
      status_kepegawaian:
          _readString(data['status_kepegawaian']),
      jenis_asn: _readString(data['jenis_asn']),
      foto_profil: _readString(data['foto_profil']),
      updated_at: _readTimestamp(data['updated_at']),
      tempat_lahir: _readString(data['tempat_lahir']),
      tanggal_lahir: _readNullableTimestamp(data['tanggal_lahir']),
      pendidikan: _readString(data['pendidikan']),
      tahun_lulus_pendidikan:
          _readInt(data['tahun_lulus_pendidikan']),
      latihan_jabatan: _readString(data['latihan_jabatan']),
      tahun_latihan_jabatan:
          _readInt(data['tahun_latihan_jabatan']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'owner_id': owner_id,
      'pangkat': pangkat,
      'jabatan_sekarang': jabatan_sekarang,
      'tahun_jabatan_sekarang': tahun_jabatan_sekarang,
      'jabatan_sebelumnya': jabatan_sebelumnya,
      'tahun_jabatan_sebelumnya': tahun_jabatan_sebelumnya,
      'status_kepegawaian': status_kepegawaian,
      'jenis_asn': jenis_asn,
      'foto_profil': foto_profil,
      'tempat_lahir': tempat_lahir,
      'tanggal_lahir': tanggal_lahir,
      'pendidikan': pendidikan,
      'tahun_lulus_pendidikan': tahun_lulus_pendidikan,
      'latihan_jabatan': latihan_jabatan,
      'tahun_latihan_jabatan': tahun_latihan_jabatan,
      'updated_at': updated_at,
    };
  }

  static String _readString(dynamic value) =>
      value?.toString().trim() ?? '';

  static int _readInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static Timestamp _readTimestamp(dynamic value) {
    return _readNullableTimestamp(value) ??
        Timestamp.fromMillisecondsSinceEpoch(0);
  }

  static Timestamp? _readNullableTimestamp(dynamic value) {
    if (value is Timestamp) return value;
    if (value is DateTime) return Timestamp.fromDate(value);

    final DateTime? parsedDate =
        DateTime.tryParse(value?.toString() ?? '');
    if (parsedDate != null) {
      return Timestamp.fromDate(parsedDate);
    }

    return null;
  }
}
