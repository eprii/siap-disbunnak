import 'package:cloud_firestore/cloud_firestore.dart';

class SKDiklatModel {
  final String id;
  final String owner_id;
  final String jenis_diklat;
  final String jenis_diklat_struktural;
  final String jenis_diklat_fungsional;
  final String jenis_diklat_teknis;
  final String nama_kegiatan;
  final String penyelenggara;
  final String lokasi;
  final String angkatan;
  final Timestamp tanggal_mulai;
  final Timestamp tanggal_selesai;
  final int jumlah_jam;
  final String nomor_sertifikat;
  final Timestamp tanggal_sertifikat;
  final String file_pdf;
  final Timestamp created_at;
  final Timestamp updated_at;

  const SKDiklatModel({
    this.id = '',
    required this.owner_id,
    required this.jenis_diklat,
    required this.jenis_diklat_struktural,
    required this.jenis_diklat_fungsional,
    required this.jenis_diklat_teknis,
    required this.nama_kegiatan,
    required this.penyelenggara,
    required this.lokasi,
    required this.angkatan,
    required this.tanggal_mulai,
    required this.tanggal_selesai,
    required this.jumlah_jam,
    required this.nomor_sertifikat,
    required this.tanggal_sertifikat,
    required this.file_pdf,
    required this.created_at,
    required this.updated_at,
  });

  factory SKDiklatModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};

    return SKDiklatModel(
      id: doc.id,
      owner_id: _readString(data['owner_id']),
      jenis_diklat: _readString(data['jenis_diklat']),
      jenis_diklat_struktural: _readString(data['jenis_diklat_struktural']),
      jenis_diklat_fungsional: _readString(data['jenis_diklat_fungsional']),
      jenis_diklat_teknis: _readString(data['jenis_diklat_teknis']),
      nama_kegiatan: _readString(data['nama_kegiatan']),
      penyelenggara: _readString(data['penyelenggara']),
      lokasi: _readString(data['lokasi']),
      angkatan: _readString(data['angkatan']),
      tanggal_mulai: _readTimestamp(data['tanggal_mulai']),
      tanggal_selesai: _readTimestamp(data['tanggal_selesai']),
      jumlah_jam: _readInt(data['jumlah_jam']),
      nomor_sertifikat: _readString(data['nomor_sertifikat']),
      tanggal_sertifikat: _readTimestamp(data['tanggal_sertifikat']),
      file_pdf: _readString(data['file_pdf']),
      created_at: _readTimestamp(data['created_at']),
      updated_at: _readTimestamp(data['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'owner_id': owner_id,
      'jenis_diklat': jenis_diklat,
      'jenis_diklat_struktural': jenis_diklat_struktural,
      'jenis_diklat_fungsional': jenis_diklat_fungsional,
      'jenis_diklat_teknis': jenis_diklat_teknis,
      'nama_kegiatan': nama_kegiatan,
      'penyelenggara': penyelenggara,
      'lokasi': lokasi,
      'angkatan': angkatan,
      'tanggal_mulai': tanggal_mulai,
      'tanggal_selesai': tanggal_selesai,
      'jumlah_jam': jumlah_jam,
      'nomor_sertifikat': nomor_sertifikat,
      'tanggal_sertifikat': tanggal_sertifikat,
      'file_pdf': file_pdf,
      'created_at': created_at,
      'updated_at': updated_at,
    };
  }

  static String _readString(dynamic value) => value?.toString() ?? '';

  static int _readInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static Timestamp _readTimestamp(dynamic value) {
    if (value is Timestamp) return value;
    if (value is DateTime) return Timestamp.fromDate(value);

    final parsedDate = DateTime.tryParse(value?.toString() ?? '');
    if (parsedDate != null) return Timestamp.fromDate(parsedDate);

    return Timestamp.fromMillisecondsSinceEpoch(0);
  }
}
