import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePegawaiModel {
  final String owner_id;
  final String pangkat;
  final String jabatan_sekarang;
  final String tahun_jabatan_sekarang;
  final String jabatan_sebelumnya;
  final String tahun_jabatan_sebelumnya;
  final String latihan_jabatan;
  final String tahun_latihan_jabatan;
  final String pendidikan;
  final String tahun_lulus_pendidikan;
  final String foto_profil;
  final String updated_at;

  ProfilePegawaiModel({
    required this.owner_id,
    required this.pangkat,
    required this.jabatan_sekarang,
    required this.tahun_jabatan_sekarang,
    required this.jabatan_sebelumnya,
    required this.tahun_jabatan_sebelumnya,
    required this.latihan_jabatan,
    required this.tahun_latihan_jabatan,
    required this.pendidikan,
    required this.tahun_lulus_pendidikan,
    required this.foto_profil,
    required this.updated_at,
  });

  factory ProfilePegawaiModel.fromDocument(DocumentSnapshot doc) {
    return ProfilePegawaiModel(
      owner_id: doc['owner_id'] ?? '',
      pangkat: doc['pangkat'] ?? '',
      jabatan_sekarang: doc['jabatan_sekarang'] ?? '',
      tahun_jabatan_sekarang: doc['tahun_jabatan_sekarang'] ?? '',
      jabatan_sebelumnya: doc['jabatan_sebelumnya'] ?? '',
      tahun_jabatan_sebelumnya: doc['tahun_jabatan_sebelumnya'] ?? '',
      latihan_jabatan: doc['latihan_jabatan'] ?? '',
      tahun_latihan_jabatan: doc['tahun_latihan_jabatan'] ?? '',
      pendidikan: doc['pendidikan'] ?? '',
      tahun_lulus_pendidikan: doc['tahun_lulus_pendidikan'] ?? '',
      foto_profil: doc['foto_profil'] ?? '',
      updated_at: doc['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'owner_id': owner_id,
      'pangkat': pangkat,
      'jabatan_sekarang': jabatan_sekarang,
      'tahun_jabatan_sekarang': tahun_jabatan_sekarang,
      'jabatan_sebelumnya': jabatan_sebelumnya,
      'tahun_jabatan_sebelumnya': tahun_jabatan_sebelumnya,
      'latihan_jabatan': latihan_jabatan,
      'tahun_latihan_jabatan': tahun_latihan_jabatan,
      'pendidikan': pendidikan,
      'tahun_lulus_pendidikan': tahun_lulus_pendidikan,
      'foto_profil': foto_profil,
      'updated_at': updated_at,
    };
  }

}