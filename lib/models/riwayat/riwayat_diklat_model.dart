import 'package:cloud_firestore/cloud_firestore.dart';

class RiwayatDiklatModel {
  final String id;
  final String owner_id;
  final String nama_diklat;
  final String penyelenggara;
  final int tahun;
  final String nomor_sertifikat;
  final Timestamp created_at;
  final Timestamp updated_at;

  const RiwayatDiklatModel({
    this.id = '',
    required this.owner_id,
    required this.nama_diklat,
    required this.penyelenggara,
    required this.tahun,
    required this.nomor_sertifikat,
    required this.created_at,
    required this.updated_at,
  });

  factory RiwayatDiklatModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};

    return RiwayatDiklatModel(
      id: doc.id,
      owner_id: _readString(data['owner_id']),
      nama_diklat: _readString(data['nama_diklat']),
      penyelenggara: _readString(data['penyelenggara']),
      tahun: _readInt(data['tahun']),
      nomor_sertifikat: _readString(data['nomor_sertifikat']),
      created_at: _readTimestamp(data['created_at']),
      updated_at: _readTimestamp(data['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'owner_id': owner_id,
      'nama_diklat': nama_diklat,
      'penyelenggara': penyelenggara,
      'tahun': tahun,
      'nomor_sertifikat': nomor_sertifikat,
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
