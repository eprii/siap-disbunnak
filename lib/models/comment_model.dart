import 'package:cloud_firestore/cloud_firestore.dart';

class CommentsModel {
  final String sk_id;
  final String owner_id;
  final String nama_pengguna;
  final String isi_komentar;
  final String created_at;
  final String jumlah_balasan;

  CommentsModel({
    required this.sk_id,
    required this.owner_id,
    required this.nama_pengguna,
    required this.isi_komentar,
    required this.created_at,
    required this.jumlah_balasan,
  });

  factory CommentsModel.fromDocument(DocumentSnapshot doc) {
    return CommentsModel(
      sk_id: doc['sk_id'] ?? '',
      owner_id: doc['owner_id'] ?? '',
      nama_pengguna: doc['nama_pengguna'] ?? '',
      isi_komentar: doc['isi_komentar'] ?? '',
      created_at: doc['created_at'] ?? '',
      jumlah_balasan: doc['jumlah_balasan'] ?? '',
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
}