import 'package:cloud_firestore/cloud_firestore.dart';

class SKJabatanModel {
  final String id;
  final String owner_id;
  final String instansi_kerja;
  final String unit_kerja;
  final String satuan_kerja;
  final String jenis_jabatan;
  final String jabatan;
  final String jenis_mutasi;
  final String nomor_sk;
  final Timestamp tanggal_sk;
  final Timestamp tmt_jabatan;
  final String file_pdf;
  final Timestamp created_at;
  final Timestamp updated_at;

  const SKJabatanModel({
    this.id = '',
    required this.owner_id,
    required this.instansi_kerja,
    required this.unit_kerja,
    required this.satuan_kerja,
    required this.jenis_jabatan,
    required this.jabatan,
    required this.jenis_mutasi,
    required this.nomor_sk,
    required this.tanggal_sk,
    required this.tmt_jabatan,
    required this.file_pdf,
    required this.created_at,
    required this.updated_at,
  });

  factory SKJabatanModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};

    return SKJabatanModel(
      id: doc.id,
      owner_id: _readString(data['owner_id']),
      instansi_kerja: _readString(data['instansi_kerja']),
      unit_kerja: _readString(data['unit_kerja']),
      satuan_kerja: _readString(data['satuan_kerja']),
      jenis_jabatan: _readString(data['jenis_jabatan']),
      jabatan: _readString(data['jabatan']),
      jenis_mutasi: _readString(data['jenis_mutasi']),
      nomor_sk: _readString(data['nomor_sk']),
      tanggal_sk: _readTimestamp(data['tanggal_sk']),
      tmt_jabatan: _readTimestamp(data['tmt_jabatan']),
      file_pdf: _readString(data['file_pdf']),
      created_at: _readTimestamp(data['created_at']),
      updated_at: _readTimestamp(data['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'owner_id': owner_id,
      'instansi_kerja': instansi_kerja,
      'unit_kerja': unit_kerja,
      'satuan_kerja': satuan_kerja,
      'jenis_jabatan': jenis_jabatan,
      'jabatan': jabatan,
      'jenis_mutasi': jenis_mutasi,
      'nomor_sk': nomor_sk,
      'tanggal_sk': tanggal_sk,
      'tmt_jabatan': tmt_jabatan,
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
