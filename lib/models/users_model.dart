import 'package:cloud_firestore/cloud_firestore.dart';

class UsersModel {
  final String id;
  final String uid;
  final String username;
  final String nama_lengkap;
  final String nip;
  final String email;
  final String no_telepon;
  final String role;
  final String status_akun;
  final Timestamp created_at;
  final Timestamp updated_at;

  const UsersModel({
    this.id = '',
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

  factory UsersModel.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return UsersModel(
      id: doc.id,
      uid: _readString(data['uid']),
      username: _readString(data['username']),
      nama_lengkap: _readString(data['nama_lengkap']),
      nip: _readString(data['nip']),
      email: _readString(data['email']),
      no_telepon: _readString(data['no_telepon']),
      role: _readString(data['role']),
      status_akun: _readString(data['status_akun']),
      created_at: _readTimestamp(data['created_at']),
      updated_at: _readTimestamp(data['updated_at']),
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

  static String _readString(dynamic value) => value?.toString() ?? '';

  static Timestamp _readTimestamp(dynamic value) {
    if (value is Timestamp) return value;
    if (value is DateTime) return Timestamp.fromDate(value);

    final parsedDate = DateTime.tryParse(value?.toString() ?? '');
    if (parsedDate != null) return Timestamp.fromDate(parsedDate);

    return Timestamp.fromMillisecondsSinceEpoch(0);
  }
}
