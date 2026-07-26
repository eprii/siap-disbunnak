import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/users_model.dart';

class AuthService {
  static final AuthService instance = AuthService._internal();

  factory AuthService() {
    return instance;
  }

  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==========================
  // AUTH STATE
  // ==========================

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ==========================
  // LOGIN
  // ==========================

  Future<UserCredential> login({
    required String identifier,
    required String password,
    bool rememberMe = false,
  }) async {
    final String cleanIdentifier = identifier.trim();
    String email = cleanIdentifier.toLowerCase();

    if (cleanIdentifier.isEmpty || password.isEmpty) {
      throw const AuthServiceException(
        'Email/username dan kata sandi wajib diisi.',
      );
    }

    try {
      // Login dengan username membaca satu dokumen login_index.
      // Rules mengizinkan get sebelum pengguna memiliki sesi Firebase.
      if (!cleanIdentifier.contains('@')) {
        final String username = cleanIdentifier.toLowerCase();

        final DocumentSnapshot<Map<String, dynamic>> indexDoc =
            await _firestore
                .collection('login_index')
                .doc(username)
                .get();

        if (!indexDoc.exists) {
          throw const AuthServiceException(
            'Username tidak ditemukan.',
          );
        }

        email =
            indexDoc.data()?['email']?.toString().trim().toLowerCase() ?? '';

        if (email.isEmpty) {
          throw const AuthServiceException(
            'Data login untuk username ini belum lengkap.',
          );
        }
      }

      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on AuthServiceException {
      rethrow;
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(
        _firebaseAuthMessage(error),
        code: error.code,
      );
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw const AuthServiceException(
          'Akses data login ditolak. Pastikan Firestore Rules terbaru '
          'sudah dipublikasikan.',
          code: 'permission-denied',
        );
      }

      throw AuthServiceException(
        error.message ?? 'Gagal membaca data login.',
        code: error.code,
      );
    }
  }

  // ==========================
  // REGISTER
  // ==========================

  Future<UserCredential> register({
    required String namaLengkap,
    required String email,
    required String password,
  }) async {
    final String cleanName = namaLengkap.trim();
    final String cleanEmail = email.trim().toLowerCase();

    if (cleanName.isEmpty || cleanEmail.isEmpty || password.isEmpty) {
      throw const AuthServiceException(
        'Nama, email, dan kata sandi wajib diisi.',
      );
    }

    UserCredential? credential;

    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      final User? firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const AuthServiceException(
          'Akun Firebase tidak berhasil dibuat.',
        );
      }

      final String uid = firebaseUser.uid;
      final String username = await _createAvailableUsername(
        email: cleanEmail,
        uid: uid,
      );

      final DocumentReference<Map<String, dynamic>> userRef =
          _firestore.collection('users').doc(uid);
      final DocumentReference<Map<String, dynamic>> profileRef =
          _firestore.collection('table_data_pegawai').doc(uid);
      final DocumentReference<Map<String, dynamic>> loginIndexRef =
          _firestore.collection('login_index').doc(username);

      final WriteBatch batch = _firestore.batch();

      batch.set(userRef, <String, dynamic>{
        'uid': uid,
        'nama_lengkap': cleanName,
        'nip': '',
        'email': cleanEmail,
        'username': username,
        'username_lower': username,
        'no_telepon': '',
        'role': 'user',
        'status_akun': 'Aktif',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Profil pegawai dibuat sejak registrasi agar halaman Profil tetap
      // dapat dibuka. Data kepegawaian sengaja dibiarkan kosong dan dapat
      // dilengkapi sendiri oleh pengguna melalui Edit Profil.
      batch.set(profileRef, <String, dynamic>{
        'owner_id': uid,
        'status_kepegawaian': '',
        'jenis_asn': '',
        'pangkat': '',
        'jabatan_sekarang': '',
        'tahun_jabatan_sekarang': 0,
        'jabatan_sebelumnya': '',
        'tahun_jabatan_sebelumnya': 0,
        'tempat_lahir': '',
        'tanggal_lahir': null,
        'pendidikan': '',
        'tahun_lulus_pendidikan': 0,
        'latihan_jabatan': '',
        'tahun_latihan_jabatan': 0,
        'riwayat_jabatan': <Map<String, dynamic>>[],
        'riwayat_pendidikan': <Map<String, dynamic>>[],
        'riwayat_diklat': <Map<String, dynamic>>[],
        'foto_profil': '',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      batch.set(loginIndexRef, <String, dynamic>{
        'uid': uid,
        'email': cleanEmail,
        'username': username,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // createUserWithEmailAndPassword otomatis login.
      // Aplikasi harus kembali ke halaman Login setelah registrasi.
      await _auth.signOut();

      return credential;
    } on AuthServiceException {
      await _cleanupFailedRegistration(credential?.user);
      rethrow;
    } on FirebaseAuthException catch (error) {
      await _cleanupFailedRegistration(credential?.user);
      throw AuthServiceException(
        _firebaseAuthMessage(error),
        code: error.code,
      );
    } on FirebaseException catch (error) {
      await _cleanupFailedRegistration(credential?.user);

      if (error.code == 'permission-denied') {
        throw const AuthServiceException(
          'Akun Firebase berhasil dibuat, tetapi data profil ditolak oleh '
          'Firestore. Pastikan Firestore Rules terbaru sudah dipublikasikan.',
          code: 'permission-denied',
        );
      }

      throw AuthServiceException(
        error.message ?? 'Gagal menyimpan data akun dan profil.',
        code: error.code,
      );
    } catch (error) {
      await _cleanupFailedRegistration(credential?.user);
      throw AuthServiceException(
        'Registrasi gagal: $error',
      );
    }
  }

  Future<String> _createAvailableUsername({
    required String email,
    required String uid,
  }) async {
    final String emailPrefix = email.split('@').first.toLowerCase();
    String base = emailPrefix.replaceAll(
      RegExp(r'[^a-z0-9._-]'),
      '_',
    );

    base = base.replaceAll(RegExp(r'_+'), '_');
    base = base.replaceAll(RegExp(r'^[._-]+|[._-]+$'), '');

    if (base.isEmpty) {
      base = 'pegawai';
    }

    final DocumentSnapshot<Map<String, dynamic>> baseDoc =
        await _firestore.collection('login_index').doc(base).get();

    if (!baseDoc.exists) {
      return base;
    }

    final String shortUid =
        uid.length <= 6 ? uid.toLowerCase() : uid.substring(0, 6).toLowerCase();

    return '${base}_$shortUid';
  }

  Future<void> _cleanupFailedRegistration(User? user) async {
    try {
      if (user != null) {
        await user.delete();
      }
    } catch (_) {
      // Cleanup bersifat best effort.
    }

    try {
      await _auth.signOut();
    } catch (_) {
      // Pastikan AuthGate tidak membawa pengguna ke Home.
    }
  }

  // ==========================
  // WATCH USER FIRESTORE
  // ==========================

  Stream<UsersModel?> watchUser(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((DocumentSnapshot<Map<String, dynamic>> doc) {
      if (!doc.exists) {
        return null;
      }

      return UsersModel.fromDocument(doc);
    });
  }

  // ==========================
  // LOGOUT
  // ==========================

  Future<void> logout() async {
    await _auth.signOut();
  }

  static String _firebaseAuthMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'Email sudah digunakan oleh akun lain.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'weak-password':
        return 'Kata sandi terlalu lemah.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Email, username, atau kata sandi tidak sesuai.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Tunggu beberapa saat sebelum '
            'mencoba kembali.';
      case 'network-request-failed':
        return 'Koneksi internet bermasalah.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan.';
      default:
        return error.message ?? 'Proses autentikasi gagal.';
    }
  }
}

class AuthServiceException implements Exception {
  final String message;
  final String? code;

  const AuthServiceException(
    this.message, {
    this.code,
  });

  @override
  String toString() => message;
}
