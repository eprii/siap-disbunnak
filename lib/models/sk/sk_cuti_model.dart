import 'package:cloud_firestore/cloud_firestore.dart';

class SKCutiModel {
  final String id;
  final String owner_id;
  final String jenis_cuti;
  final String nomor_sk;
  final Timestamp tanggal_sk;
  final Timestamp tanggal_mulai;
  final Timestamp tanggal_akhir;
  final int lama_cuti;
  final String pejabat_pengesahan;
  final String keterangan;
  final String file_pdf;
  final Timestamp created_at;
  final Timestamp updated_at;

  const SKCutiModel({
    this.id = '',
    required this.owner_id,
    required this.jenis_cuti,
    required this.nomor_sk,
    required this.tanggal_sk,
    required this.tanggal_mulai,
    required this.tanggal_akhir,
    required this.lama_cuti,
    required this.pejabat_pengesahan,
    required this.keterangan,
    required this.file_pdf,
    required this.created_at,
    required this.updated_at,
  });

  factory SKCutiModel.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return SKCutiModel(
      id: doc.id,
      owner_id: _readString(data['owner_id']),
      jenis_cuti: _readString(data['jenis_cuti']),
      nomor_sk: _readString(data['nomor_sk']),
      tanggal_sk: _readTimestamp(data['tanggal_sk']),
      tanggal_mulai: _readTimestamp(data['tanggal_mulai']),
      tanggal_akhir: _readTimestamp(data['tanggal_akhir']),
      lama_cuti: _readInt(data['lama_cuti']),
      pejabat_pengesahan: _readString(data['pejabat_pengesahan']),
      keterangan: _readString(data['keterangan']),
      file_pdf: _readString(data['file_pdf']),
      created_at: _readTimestamp(data['created_at']),
      updated_at: _readTimestamp(data['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'owner_id': owner_id,
      'jenis_cuti': jenis_cuti,
      'nomor_sk': nomor_sk,
      'tanggal_sk': tanggal_sk,
      'tanggal_mulai': tanggal_mulai,
      'tanggal_akhir': tanggal_akhir,
      'lama_cuti': lama_cuti,
      'pejabat_pengesahan': pejabat_pengesahan,
      'keterangan': keterangan,
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
