import 'package:cloud_firestore/cloud_firestore.dart';

class SKPenugasanTimModel {
  final String id;
  final String owner_id;
  final String nama_tim;
  final String lingkup_tim;
  final String kedudukan;
  final String nomor_sk;
  final Timestamp tanggal_sk;
  final String pejabat_penetapan;
  final String file_pdf;
  final Timestamp created_at;
  final Timestamp updated_at;

  const SKPenugasanTimModel({
    this.id = '',
    required this.owner_id,
    required this.nama_tim,
    required this.lingkup_tim,
    required this.kedudukan,
    required this.nomor_sk,
    required this.tanggal_sk,
    required this.pejabat_penetapan,
    required this.file_pdf,
    required this.created_at,
    required this.updated_at,
  });

  factory SKPenugasanTimModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};

    return SKPenugasanTimModel(
      id: doc.id,
      owner_id: _readString(data['owner_id']),
      nama_tim: _readString(data['nama_tim']),
      lingkup_tim: _readString(data['lingkup_tim']),
      kedudukan: _readString(data['kedudukan']),
      nomor_sk: _readString(data['nomor_sk']),
      tanggal_sk: _readTimestamp(data['tanggal_sk']),
      pejabat_penetapan: _readString(data['pejabat_penetapan']),
      file_pdf: _readString(data['file_pdf']),
      created_at: _readTimestamp(data['created_at']),
      updated_at: _readTimestamp(data['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'owner_id': owner_id,
      'nama_tim': nama_tim,
      'lingkup_tim': lingkup_tim,
      'kedudukan': kedudukan,
      'nomor_sk': nomor_sk,
      'tanggal_sk': tanggal_sk,
      'pejabat_penetapan': pejabat_penetapan,
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
