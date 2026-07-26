import 'package:cloud_firestore/cloud_firestore.dart';

class SKCPNSModel {
  final String id;
  final String owner_id;
  final String nomor_sk_cpns;
  final Timestamp tanggal_sk_cpns;
  final String nomor_spmt;
  final String nomor_sttpl;
  final Timestamp tanggal_sttpl;
  final String nomor_pertek_cpns;
  final Timestamp tmt_cpns;
  final String golongan_awal;
  final String tingkat_pendidikan;
  final String pejabat_pengesahan;
  final String file_pdf;
  final Timestamp created_at;
  final Timestamp updated_at;

  const SKCPNSModel({
    this.id = '',
    required this.owner_id,
    required this.nomor_sk_cpns,
    required this.tanggal_sk_cpns,
    required this.nomor_spmt,
    required this.nomor_sttpl,
    required this.tanggal_sttpl,
    required this.nomor_pertek_cpns,
    required this.tmt_cpns,
    required this.golongan_awal,
    required this.tingkat_pendidikan,
    required this.pejabat_pengesahan,
    required this.file_pdf,
    required this.created_at,
    required this.updated_at,
  });

  factory SKCPNSModel.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return SKCPNSModel(
      id: doc.id,
      owner_id: _readString(data['owner_id']),
      nomor_sk_cpns: _readString(data['nomor_sk_cpns']),
      tanggal_sk_cpns: _readTimestamp(data['tanggal_sk_cpns']),
      nomor_spmt: _readString(data['nomor_spmt']),
      nomor_sttpl: _readString(data['nomor_sttpl']),
      tanggal_sttpl: _readTimestamp(data['tanggal_sttpl']),
      nomor_pertek_cpns: _readString(data['nomor_pertek_cpns']),
      tmt_cpns: _readTimestamp(data['tmt_cpns']),
      golongan_awal: _readString(data['golongan_awal']),
      tingkat_pendidikan: _readString(data['tingkat_pendidikan']),
      pejabat_pengesahan: _readString(data['pejabat_pengesahan']),
      file_pdf: _readString(data['file_pdf']),
      created_at: _readTimestamp(data['created_at']),
      updated_at: _readTimestamp(data['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'owner_id': owner_id,
      'nomor_sk_cpns': nomor_sk_cpns,
      'tanggal_sk_cpns': tanggal_sk_cpns,
      'nomor_spmt': nomor_spmt,
      'nomor_sttpl': nomor_sttpl,
      'tanggal_sttpl': tanggal_sttpl,
      'nomor_pertek_cpns': nomor_pertek_cpns,
      'tmt_cpns': tmt_cpns,
      'golongan_awal': golongan_awal,
      'tingkat_pendidikan': tingkat_pendidikan,
      'pejabat_pengesahan': pejabat_pengesahan,
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
