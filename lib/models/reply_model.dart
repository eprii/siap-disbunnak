import 'package:cloud_firestore/cloud_firestore.dart';

class RepliesModel {
  final String id;
  final String comment_id;
  final String owner_id;
  final String nama_pengguna;
  final String isi_balasan;
  final Timestamp created_at;

  const RepliesModel({
    this.id = '',
    required this.comment_id,
    required this.owner_id,
    required this.nama_pengguna,
    required this.isi_balasan,
    required this.created_at,
  });

  factory RepliesModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};

    return RepliesModel(
      id: doc.id,
      comment_id: _readString(data['comment_id']),
      owner_id: _readString(data['owner_id']),
      nama_pengguna: _readString(data['nama_pengguna']),
      isi_balasan: _readString(data['isi_balasan']),
      created_at: _readTimestamp(data['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'comment_id': comment_id,
      'owner_id': owner_id,
      'nama_pengguna': nama_pengguna,
      'isi_balasan': isi_balasan,
      'created_at': created_at,
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
