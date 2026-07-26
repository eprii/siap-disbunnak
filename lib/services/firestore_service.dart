import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/profilepegawai_model.dart';
import '../models/users_model.dart';

class FirestoreService {
  static final FirestoreService instance =
      FirestoreService._internal();

  factory FirestoreService() {
    return instance;
  }

  FirestoreService._internal();

  final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  static const String _usersCollection = 'users';
  static const String _profilesCollection =
      'table_data_pegawai';
  static const String _loginIndexCollection =
      'login_index';

  Future<UsersModel?> getUserData(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _db
            .collection(_usersCollection)
            .doc(uid)
            .get();

    if (!doc.exists) {
      return null;
    }

    return UsersModel.fromDocument(doc);
  }

  Stream<UsersModel?> watchUser(String uid) {
    return _db
        .collection(_usersCollection)
        .doc(uid)
        .snapshots()
        .map((DocumentSnapshot<Map<String, dynamic>> doc) {
      if (!doc.exists) {
        return null;
      }

      return UsersModel.fromDocument(doc);
    });
  }

  Future<ProfilePegawaiModel?> getProfilePegawai(
    String uid,
  ) async {
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _db
            .collection(_profilesCollection)
            .doc(uid)
            .get();

    if (!doc.exists) {
      return null;
    }

    return ProfilePegawaiModel.fromDocument(doc);
  }

  Stream<ProfilePegawaiModel?> watchProfilePegawai(
    String uid,
  ) {
    return _db
        .collection(_profilesCollection)
        .doc(uid)
        .snapshots()
        .map((DocumentSnapshot<Map<String, dynamic>> doc) {
      if (!doc.exists) {
        return null;
      }

      return ProfilePegawaiModel.fromDocument(doc);
    });
  }

  Future<void> updateFotoProfil(
    String uid,
    String url,
  ) async {
    await _db
        .collection(_profilesCollection)
        .doc(uid)
        .update(<String, dynamic>{
      'foto_profil': url,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProfileData({
    required String uid,
    required String oldUsername,
    required String email,
    required String namaLengkap,
    required String nip,
    required String username,
    required String noTelepon,
    required String statusKepegawaian,
    required String jenisAsn,
    required String pangkat,
    required String jabatanSekarang,
    required int tahunJabatanSekarang,
    required String jabatanSebelumnya,
    required int tahunJabatanSebelumnya,
  }) async {
    final String cleanUid = uid.trim();
    final String cleanOldUsername =
        oldUsername.trim().toLowerCase();
    final String cleanUsername =
        username.trim().toLowerCase();
    final String cleanEmail = email.trim().toLowerCase();

    if (cleanUid.isEmpty) {
      throw const FirestoreProfileException(
        'Sesi pengguna tidak valid.',
      );
    }

    if (cleanUsername.isEmpty) {
      throw const FirestoreProfileException(
        'Username wajib diisi.',
      );
    }

    if (tahunJabatanSekarang < 1900 ||
        tahunJabatanSekarang > 2200) {
      throw const FirestoreProfileException(
        'Tahun jabatan sekarang tidak valid.',
      );
    }

    if (tahunJabatanSebelumnya < 1900 ||
        tahunJabatanSebelumnya > 2200) {
      throw const FirestoreProfileException(
        'Tahun jabatan sebelumnya tidak valid.',
      );
    }

    final DocumentReference<Map<String, dynamic>>
        userRef = _db
            .collection(_usersCollection)
            .doc(cleanUid);

    final DocumentReference<Map<String, dynamic>>
        profileRef = _db
            .collection(_profilesCollection)
            .doc(cleanUid);

    final bool usernameChanged =
        cleanUsername != cleanOldUsername;

    final DocumentReference<Map<String, dynamic>>
        newIndexRef = _db
            .collection(_loginIndexCollection)
            .doc(cleanUsername);

    final DocumentReference<Map<String, dynamic>>?
        oldIndexRef = cleanOldUsername.isEmpty
            ? null
            : _db
                .collection(_loginIndexCollection)
                .doc(cleanOldUsername);

    await _db.runTransaction<void>(
      (Transaction transaction) async {
        final DocumentSnapshot<Map<String, dynamic>>
            userSnapshot = await transaction.get(userRef);

        if (!userSnapshot.exists) {
          throw const FirestoreProfileException(
            'Data akun tidak ditemukan.',
          );
        }

        DocumentSnapshot<Map<String, dynamic>>?
            newIndexSnapshot;
        DocumentSnapshot<Map<String, dynamic>>?
            oldIndexSnapshot;

        if (usernameChanged) {
          newIndexSnapshot =
              await transaction.get(newIndexRef);

          if (oldIndexRef != null) {
            oldIndexSnapshot =
                await transaction.get(oldIndexRef);
          }

          if (newIndexSnapshot.exists) {
            final String ownerUid = newIndexSnapshot
                    .data()?['uid']
                    ?.toString()
                    .trim() ??
                '';

            if (ownerUid != cleanUid) {
              throw const FirestoreProfileException(
                'Username sudah digunakan.',
              );
            }
          }
        }

        transaction.update(
          userRef,
          <String, dynamic>{
            'nama_lengkap': namaLengkap.trim(),
            'nip': nip.trim(),
            'username': cleanUsername,
            'username_lower': cleanUsername,
            'no_telepon': noTelepon.trim(),
            'updated_at': FieldValue.serverTimestamp(),
          },
        );

        transaction.set(
          profileRef,
          <String, dynamic>{
            'owner_id': cleanUid,
            'status_kepegawaian':
                statusKepegawaian.trim(),
            'jenis_asn': jenisAsn.trim(),
            'pangkat': pangkat.trim(),
            'jabatan_sekarang':
                jabatanSekarang.trim(),
            'tahun_jabatan_sekarang':
                tahunJabatanSekarang,
            'jabatan_sebelumnya':
                jabatanSebelumnya.trim(),
            'tahun_jabatan_sebelumnya':
                tahunJabatanSebelumnya,
            'updated_at': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        if (usernameChanged) {
          transaction.set(
            newIndexRef,
            <String, dynamic>{
              'uid': cleanUid,
              'email': cleanEmail,
              'username': cleanUsername,
              'updated_at': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

          if (oldIndexRef != null &&
              oldIndexSnapshot?.exists == true) {
            final String oldOwnerUid =
                oldIndexSnapshot!
                        .data()?['uid']
                        ?.toString()
                        .trim() ??
                    '';

            if (oldOwnerUid == cleanUid) {
              transaction.delete(oldIndexRef);
            }
          }
        }
      },
    );
  }
}

class FirestoreProfileException implements Exception {
  final String message;

  const FirestoreProfileException(this.message);

  @override
  String toString() => message;
}
