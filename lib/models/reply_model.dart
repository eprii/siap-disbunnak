import 'package:cloud_firestore/cloud_firestore.dart';

class RepliesModel {
  final String comment_id;
  final String owner_id;
  final String nama_pengguna;
  final String isi_balasan;
  final String created_at;

  RepliesModel({
    required this.comment_id,
    required this.owner_id,
    required this.nama_pengguna,
    required this.isi_balasan,
    required this.created_at,
  });

  factory RepliesModel.fromDocument(DocumentSnapshot doc) {
    return RepliesModel(
      comment_id: doc['comment_id'] ?? '',
      owner_id: doc['owner_id'] ?? '',
      nama_pengguna: doc['nama_pengguna'] ?? '',
      isi_balasan: doc['isi_balasan'] ?? '',
      created_at: doc['created_at'] ?? '',
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
}