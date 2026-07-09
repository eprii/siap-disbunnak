import 'package:cloud_firestore/cloud_firestore.dart';

class DataSKModel {
  final String owner_id;
  final String nama_pegawai;
  final String nip;
  final String nama_sk;
  final String nomor_sk;
  final String deskripsi_sk;
  final String jenis_sk;
  final String file_sk;
  final String tanggal_sk;
  final String tahun_sk;
  final String jabatan_saat_sk;
  final String status;
  final String jumlah_komentar;
  final String created_at;
  final String updated_at;

  DataSKModel({
    required this.owner_id,
    required this.nama_pegawai,
    required this.nip,
    required this.nama_sk,
    required this.nomor_sk,
    required this.deskripsi_sk,
    required this.jenis_sk,
    required this.file_sk,
    required this.tanggal_sk,
    required this.tahun_sk,
    required this.jabatan_saat_sk,
    required this.status,
    required this.jumlah_komentar,
    required this.created_at,
    required this.updated_at,
  });

  factory DataSKModel.fromDocument(DocumentSnapshot doc) {
    return DataSKModel(
      owner_id: doc['owner_id'] ?? '',
      nama_pegawai: doc['nama_pegawai'] ?? '',
      nip: doc['nip'] ?? '',
      nama_sk: doc['nama_sk'] ?? '',
      nomor_sk: doc['nomor_sk'] ?? '',
      deskripsi_sk: doc['deskripsi_sk'] ?? '',
      jenis_sk: doc['jenis_sk'] ?? '',
      file_sk: doc['file_sk'] ?? '',
      tanggal_sk: doc['tanggal_sk'] ?? '',
      tahun_sk: doc['tahun_sk'] ?? '',
      jabatan_saat_sk: doc['jabatan_saat_sk'] ?? '',
      status: doc['status'] ?? '',
      jumlah_komentar: doc['jumlah_komentar'] ?? '',
      created_at: doc['created_at'] ?? '',
      updated_at: doc['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'owner_id': owner_id,
      'nama_pegawai': nama_pegawai,
      'nip': nip,
      'nama_sk': nama_sk,
      'nomor_sk': nomor_sk,
      'deskripsi_sk': deskripsi_sk,
      'jenis_sk': jenis_sk,
      'file_sk': file_sk,
      'tanggal_sk': tanggal_sk,
      'tahun_sk': tahun_sk,
      'jabatan_saat_sk': jabatan_saat_sk,
      'status': status,
      'jumlah_komentar': jumlah_komentar,
      'created_at': created_at,
      'updated_at': updated_at,
    };
  }
}