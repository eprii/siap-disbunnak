import 'package:cloud_firestore/cloud_firestore.dart';

class RiwayatPendidikanModel {
  final String id;
  final String owner_id;
  final String jenjang;
  final String nama_instansi;
  final String jurusan;
  final int tahun_masuk;
  final int tahun_lulus;
  final Timestamp created_at;
  final Timestamp updated_at;

  const RiwayatPendidikanModel({
    this.id = '',
    required this.owner_id,
    required this.jenjang,
    required this.nama_instansi,
    required this.jurusan,
    required this.tahun_masuk,
    required this.tahun_lulus,
    required this.created_at,
    required this.updated_at,
  });

  factory RiwayatPendidikanModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};

    return RiwayatPendidikanModel(
      id: doc.id,
      owner_id: _readString(data['owner_id']),
      jenjang: _readString(data['jenjang']),
      nama_instansi: _readString(data['nama_instansi']),
      jurusan: _readString(data['jurusan']),
      tahun_masuk: _readInt(data['tahun_masuk']),
      tahun_lulus: _readInt(data['tahun_lulus']),
      created_at: _readTimestamp(data['created_at']),
      updated_at: _readTimestamp(data['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'owner_id': owner_id,
      'jenjang': jenjang,
      'nama_instansi': nama_instansi,
      'jurusan': jurusan,
      'tahun_masuk': tahun_masuk,
      'tahun_lulus': tahun_lulus,
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
