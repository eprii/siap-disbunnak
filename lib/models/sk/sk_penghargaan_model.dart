import 'package:cloud_firestore/cloud_firestore.dart';

class SKPenghargaanModel {
  final String id;
  final String owner_id;
  final String kode_penghargaan;
  final String jenis_penghargaan;
  final String nomor_sk;
  final Timestamp tanggal_sk;
  final int tahun_penghargaan;
  final String pemberi_penghargaan;
  final String file_pdf;
  final Timestamp created_at;
  final Timestamp updated_at;

  const SKPenghargaanModel({
    this.id = '',
    required this.owner_id,
    required this.kode_penghargaan,
    required this.jenis_penghargaan,
    required this.nomor_sk,
    required this.tanggal_sk,
    required this.tahun_penghargaan,
    required this.pemberi_penghargaan,
    required this.file_pdf,
    required this.created_at,
    required this.updated_at,
  });

  factory SKPenghargaanModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};

    return SKPenghargaanModel(
      id: doc.id,
      owner_id: _readString(data['owner_id']),
      kode_penghargaan: _readString(data['kode_penghargaan']),
      jenis_penghargaan: _readString(data['jenis_penghargaan']),
      nomor_sk: _readString(data['nomor_sk']),
      tanggal_sk: _readTimestamp(data['tanggal_sk']),
      tahun_penghargaan: _readInt(data['tahun_penghargaan']),
      pemberi_penghargaan: _readString(data['pemberi_penghargaan']),
      file_pdf: _readString(data['file_pdf']),
      created_at: _readTimestamp(data['created_at']),
      updated_at: _readTimestamp(data['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'owner_id': owner_id,
      'kode_penghargaan': kode_penghargaan,
      'jenis_penghargaan': jenis_penghargaan,
      'nomor_sk': nomor_sk,
      'tanggal_sk': tanggal_sk,
      'tahun_penghargaan': tahun_penghargaan,
      'pemberi_penghargaan': pemberi_penghargaan,
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
