import 'package:cloud_firestore/cloud_firestore.dart';

class SKPangkatModel {
  final String id;
  final String owner_id;
  final String nomor_sk_pangkat;
  final Timestamp tanggal_sk_pangkat;
  final Timestamp tmt_pangkat;
  final String golongan;
  final int masa_kerja_tahun;
  final int masa_kerja_bulan;
  final String pejabat_pengesahan;
  final String file_pdf;
  final Timestamp created_at;
  final Timestamp updated_at;

  const SKPangkatModel({
    this.id = '',
    required this.owner_id,
    required this.nomor_sk_pangkat,
    required this.tanggal_sk_pangkat,
    required this.tmt_pangkat,
    required this.golongan,
    required this.masa_kerja_tahun,
    required this.masa_kerja_bulan,
    required this.pejabat_pengesahan,
    required this.file_pdf,
    required this.created_at,
    required this.updated_at,
  });

  factory SKPangkatModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};

    return SKPangkatModel(
      id: doc.id,
      owner_id: _readString(data['owner_id']),
      nomor_sk_pangkat: _readString(data['nomor_sk_pangkat']),
      tanggal_sk_pangkat: _readTimestamp(data['tanggal_sk_pangkat']),
      tmt_pangkat: _readTimestamp(data['tmt_pangkat']),
      golongan: _readString(data['golongan']),
      masa_kerja_tahun: _readInt(data['masa_kerja_tahun']),
      masa_kerja_bulan: _readInt(data['masa_kerja_bulan']),
      pejabat_pengesahan: _readString(data['pejabat_pengesahan']),
      file_pdf: _readString(data['file_pdf']),
      created_at: _readTimestamp(data['created_at']),
      updated_at: _readTimestamp(data['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'owner_id': owner_id,
      'nomor_sk_pangkat': nomor_sk_pangkat,
      'tanggal_sk_pangkat': tanggal_sk_pangkat,
      'tmt_pangkat': tmt_pangkat,
      'golongan': golongan,
      'masa_kerja_tahun': masa_kerja_tahun,
      'masa_kerja_bulan': masa_kerja_bulan,
      'pejabat_pengesahan': pejabat_pengesahan,
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
