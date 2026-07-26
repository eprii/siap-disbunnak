import 'package:cloud_firestore/cloud_firestore.dart';

class SKAngkaKreditModel {
  final String id;
  final String owner_id;
  final String nomor_pak;
  final Timestamp tanggal_pak;
  final int bulan_mulai_penilaian;
  final int bulan_selesai_penilaian;
  final int tahun_mulai_penilaian;
  final int tahun_selesai_penilaian;
  final double kredit_utama;
  final double kredit_penunjang;
  final double total_kredit;
  final String jabatan_terkait;
  final bool pak_integrasi;
  final bool integrasi;
  final bool konversi;
  final String file_pdf;
  final Timestamp created_at;
  final Timestamp updated_at;

  const SKAngkaKreditModel({
    this.id = '',
    required this.owner_id,
    required this.nomor_pak,
    required this.tanggal_pak,
    required this.bulan_mulai_penilaian,
    required this.bulan_selesai_penilaian,
    required this.tahun_mulai_penilaian,
    required this.tahun_selesai_penilaian,
    required this.kredit_utama,
    required this.kredit_penunjang,
    required this.total_kredit,
    required this.jabatan_terkait,
    required this.pak_integrasi,
    required this.integrasi,
    required this.konversi,
    required this.file_pdf,
    required this.created_at,
    required this.updated_at,
  });

  factory SKAngkaKreditModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};

    return SKAngkaKreditModel(
      id: doc.id,
      owner_id: _readString(data['owner_id']),
      nomor_pak: _readString(data['nomor_pak']),
      tanggal_pak: _readTimestamp(data['tanggal_pak']),
      bulan_mulai_penilaian: _readInt(data['bulan_mulai_penilaian']),
      bulan_selesai_penilaian: _readInt(data['bulan_selesai_penilaian']),
      tahun_mulai_penilaian: _readInt(data['tahun_mulai_penilaian']),
      tahun_selesai_penilaian: _readInt(data['tahun_selesai_penilaian']),
      kredit_utama: _readDouble(data['kredit_utama']),
      kredit_penunjang: _readDouble(data['kredit_penunjang']),
      total_kredit: _readDouble(data['total_kredit']),
      jabatan_terkait: _readString(data['jabatan_terkait']),
      pak_integrasi: _readBool(data['pak_integrasi']),
      integrasi: _readBool(data['integrasi']),
      konversi: _readBool(data['konversi']),
      file_pdf: _readString(data['file_pdf']),
      created_at: _readTimestamp(data['created_at']),
      updated_at: _readTimestamp(data['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'owner_id': owner_id,
      'nomor_pak': nomor_pak,
      'tanggal_pak': tanggal_pak,
      'bulan_mulai_penilaian': bulan_mulai_penilaian,
      'bulan_selesai_penilaian': bulan_selesai_penilaian,
      'tahun_mulai_penilaian': tahun_mulai_penilaian,
      'tahun_selesai_penilaian': tahun_selesai_penilaian,
      'kredit_utama': kredit_utama,
      'kredit_penunjang': kredit_penunjang,
      'total_kredit': total_kredit,
      'jabatan_terkait': jabatan_terkait,
      'pak_integrasi': pak_integrasi,
      'integrasi': integrasi,
      'konversi': konversi,
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

  static double _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _readBool(dynamic value) {
    if (value is bool) return value;
    return value?.toString().toLowerCase() == 'true';
  }

  static Timestamp _readTimestamp(dynamic value) {
    if (value is Timestamp) return value;
    if (value is DateTime) return Timestamp.fromDate(value);

    final parsedDate = DateTime.tryParse(value?.toString() ?? '');
    if (parsedDate != null) return Timestamp.fromDate(parsedDate);

    return Timestamp.fromMillisecondsSinceEpoch(0);
  }
}
