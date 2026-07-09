import 'package:cloud_firestore/cloud_firestore.dart';

class UsersModel {
  final String uid;
  final String username;
  final String nama_lengkap;
  final String nip;
  final String email;
  final String no_telepon;
  final String role;
  final String status_akun;
  final String created_at;
  final String updated_at;

  UsersModel({
    required this.uid,
    required this.username,
    required this.nama_lengkap,
    required this.nip,
    required this.email,
    required this.no_telepon,
    required this.role,
    required this.status_akun,
    required this.created_at,
    required this.updated_at,
  });

  factory UsersModel.fromDocument(DocumentSnapshot doc) {
    return UsersModel(
      uid: doc['uid'] ?? '',
      username: doc['username'] ?? '',
      nama_lengkap: doc['nama_lengkap'] ?? '',
      nip: doc['nip'] ?? '',
      email: doc['email'] ?? '',
      no_telepon: doc['no_telepon'] ?? '',
      role: doc['role'] ?? '',
      status_akun: doc['status_akun'] ?? '',
      created_at: doc['created_at'] ?? '',
    updated_at: doc['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'nama_lengkap': nama_lengkap,
      'nip': nip,
      'email': email,
      'no_telepon': no_telepon,
      'role': role,
      'status_akun': status_akun,
      'created_at': created_at,
      'updated_at': updated_at,
    };
  }
}

