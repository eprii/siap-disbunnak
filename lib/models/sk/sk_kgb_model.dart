import 'package:cloud_firestore/cloud_firestore.dart';

class SKKGBModel {
  final String id;
  final String owner_id;
  final String golongan;
  final String nomor_sk;
  final Timestamp tanggal_sk;
  final Timestamp tmt_kgb;
  final int masa_kerja_tahun;
  final int masa_kerja_bulan;
  final int gaji_pokok;
  final String pejabat_penetapan;
  final String file_pdf;
  final Timestamp created_at;
  final Timestamp updated_at;

  const SKKGBModel({
    this.id = '',
    required this.owner_id,
    required this.golongan,
    required this.nomor_sk,
    required this.tanggal_sk,
    required this.tmt_kgb,
    required this.masa_kerja_tahun,
    required this.masa_kerja_bulan,
    required this.gaji_pokok,
    required this.pejabat_penetapan,
    required this.file_pdf,
    required this.created_at,
    required this.updated_at,
  });

  factory SKKGBModel.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return SKKGBModel(
      id: doc.id,
      owner_id: _readString(data['owner_id']),
      golongan: _readString(data['golongan']),
      nomor_sk: _readString(data['nomor_sk']),
      tanggal_sk: _readTimestamp(data['tanggal_sk']),
      tmt_kgb: _readTimestamp(data['tmt_kgb']),
      masa_kerja_tahun: _readInt(data['masa_kerja_tahun']),
      masa_kerja_bulan: _readInt(data['masa_kerja_bulan']),
      gaji_pokok: _readInt(data['gaji_pokok']),
      pejabat_penetapan: _readString(data['pejabat_penetapan']),
      file_pdf: _readString(data['file_pdf']),
      created_at: _readTimestamp(data['created_at']),
      updated_at: _readTimestamp(data['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'owner_id': owner_id,
      'golongan': golongan,
      'nomor_sk': nomor_sk,
      'tanggal_sk': tanggal_sk,
      'tmt_kgb': tmt_kgb,
      'masa_kerja_tahun': masa_kerja_tahun,
      'masa_kerja_bulan': masa_kerja_bulan,
      'gaji_pokok': gaji_pokok,
      'pejabat_penetapan': pejabat_penetapan,
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
