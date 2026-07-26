import 'package:cloud_firestore/cloud_firestore.dart';

class SKPendidikanModel {
  final String id;
  final String owner_id;
  final String tingkat_pendidikan;
  final String jurusan_pendidikan;
  final String nomor_ijazah;
  final Timestamp tanggal_ijazah;
  final String nama_sekolah;
  final String kota_sekolah;
  final String file_pdf;
  final Timestamp created_at;
  final Timestamp updated_at;

  const SKPendidikanModel({
    this.id = '',
    required this.owner_id,
    required this.tingkat_pendidikan,
    required this.jurusan_pendidikan,
    required this.nomor_ijazah,
    required this.tanggal_ijazah,
    required this.nama_sekolah,
    required this.kota_sekolah,
    required this.file_pdf,
    required this.created_at,
    required this.updated_at,
  });

  factory SKPendidikanModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};

    return SKPendidikanModel(
      id: doc.id,
      owner_id: _readString(data['owner_id']),
      tingkat_pendidikan: _readString(data['tingkat_pendidikan']),
      jurusan_pendidikan: _readString(data['jurusan_pendidikan']),
      nomor_ijazah: _readString(data['nomor_ijazah']),
      tanggal_ijazah: _readTimestamp(data['tanggal_ijazah']),
      nama_sekolah: _readString(data['nama_sekolah']),
      kota_sekolah: _readString(data['kota_sekolah']),
      file_pdf: _readString(data['file_pdf']),
      created_at: _readTimestamp(data['created_at']),
      updated_at: _readTimestamp(data['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'owner_id': owner_id,
      'tingkat_pendidikan': tingkat_pendidikan,
      'jurusan_pendidikan': jurusan_pendidikan,
      'nomor_ijazah': nomor_ijazah,
      'tanggal_ijazah': tanggal_ijazah,
      'nama_sekolah': nama_sekolah,
      'kota_sekolah': kota_sekolah,
      'file_pdf': file_pdf,
      'created_at': created_at,
      'updated_at': updated_at,
    };
  }

  static String _readString(dynamic value) => value?.toString() ?? '';

  static Timestamp _readTimestamp(dynamic value) {
    if (value is Timestamp) return value;
    if (value is DateTime) return Timestamp.fromDate(value);

    final parsedDate = DateTime.tryParse(value?.toString() ?? '');
    if (parsedDate != null) return Timestamp.fromDate(parsedDate);

    return Timestamp.fromMillisecondsSinceEpoch(0);
  }
}
