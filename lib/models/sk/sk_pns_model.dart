import 'package:cloud_firestore/cloud_firestore.dart';

class SKPNSModel {
  final String id;
  final String owner_id;
  final String nomor_sk_pns;
  final Timestamp tanggal_sk_pns;
  final Timestamp tmt_pns;
  final String golongan;
  final String pejabat_pengesahan;
  final String file_pdf;
  final Timestamp created_at;
  final Timestamp updated_at;

  const SKPNSModel({
    this.id = '',
    required this.owner_id,
    required this.nomor_sk_pns,
    required this.tanggal_sk_pns,
    required this.tmt_pns,
    required this.golongan,
    required this.pejabat_pengesahan,
    required this.file_pdf,
    required this.created_at,
    required this.updated_at,
  });

  factory SKPNSModel.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return SKPNSModel(
      id: doc.id,
      owner_id: _readString(data['owner_id']),
      nomor_sk_pns: _readString(data['nomor_sk_pns']),
      tanggal_sk_pns: _readTimestamp(data['tanggal_sk_pns']),
      tmt_pns: _readTimestamp(data['tmt_pns']),
      golongan: _readString(data['golongan']),
      pejabat_pengesahan: _readString(data['pejabat_pengesahan']),
      file_pdf: _readString(data['file_pdf']),
      created_at: _readTimestamp(data['created_at']),
      updated_at: _readTimestamp(data['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'owner_id': owner_id,
      'nomor_sk_pns': nomor_sk_pns,
      'tanggal_sk_pns': tanggal_sk_pns,
      'tmt_pns': tmt_pns,
      'golongan': golongan,
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
