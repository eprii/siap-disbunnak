import 'package:cloud_firestore/cloud_firestore.dart';

class CommentsModel {
  final String id;
  final String sk_id;
  final String owner_id;
  final String nama_pengguna;
  final String isi_komentar;
  final Timestamp created_at;
  final int jumlah_balasan;

  const CommentsModel({
    this.id = '',
    required this.sk_id,
    required this.owner_id,
    required this.nama_pengguna,
    required this.isi_komentar,
    required this.created_at,
    required this.jumlah_balasan,
  });

  factory CommentsModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};

    return CommentsModel(
      id: doc.id,
      sk_id: _readString(data['sk_id']),
      owner_id: _readString(data['owner_id']),
      nama_pengguna: _readString(data['nama_pengguna']),
      isi_komentar: _readString(data['isi_komentar']),
      created_at: _readTimestamp(data['created_at']),
      jumlah_balasan: _readInt(data['jumlah_balasan']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sk_id': sk_id,
      'owner_id': owner_id,
      'nama_pengguna': nama_pengguna,
      'isi_komentar': isi_komentar,
      'created_at': created_at,
      'jumlah_balasan': jumlah_balasan,
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
