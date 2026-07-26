import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountUpdateResult {
  final bool verificationEmailSent;
  final bool passwordChanged;

  const AccountUpdateResult({
    required this.verificationEmailSent,
    required this.passwordChanged,
  });
}

class EmailSyncResult {
  final bool emailChangeVerified;
  final String email;

  const EmailSyncResult({
    required this.emailChangeVerified,
    required this.email,
  });

  static const EmailSyncResult none = EmailSyncResult(
    emailChangeVerified: false,
    email: '',
  );
}

class ProfileAccountService {
  ProfileAccountService._();

  static final ProfileAccountService instance =
      ProfileAccountService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _usersCollection = 'users';
  static const String _loginIndexCollection = 'login_index';

  Future<EmailSyncResult>? _activeEmailSync;

  Future<EmailSyncResult> syncFirebaseEmailToFirestore() {
    final Future<EmailSyncResult>? activeSync = _activeEmailSync;
    if (activeSync != null) {
      return activeSync;
    }

    late final Future<EmailSyncResult> operation;
    operation = _performEmailSync().whenComplete(() {
      if (identical(_activeEmailSync, operation)) {
        _activeEmailSync = null;
      }
    });

    _activeEmailSync = operation;
    return operation;
  }

  Future<EmailSyncResult> _performEmailSync() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return EmailSyncResult.none;
    }

    try {
      await currentUser.reload();
    } on FirebaseAuthException {
      return EmailSyncResult.none;
    }

    final User? firebaseUser = _auth.currentUser;
    final String firebaseEmail =
        firebaseUser?.email?.trim().toLowerCase() ?? '';

    if (firebaseUser == null || firebaseEmail.isEmpty) {
      return EmailSyncResult.none;
    }

    final DocumentReference<Map<String, dynamic>> userRef =
        _db.collection(_usersCollection).doc(firebaseUser.uid);

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await userRef.get();
    if (!snapshot.exists) {
      return EmailSyncResult.none;
    }

    final Map<String, dynamic> data =
        snapshot.data() ?? <String, dynamic>{};
    final String storedEmail =
        data['email']?.toString().trim().toLowerCase() ?? '';
    final String pendingEmail =
        data['pending_email']?.toString().trim().toLowerCase() ?? '';
    final String username =
        data['username']?.toString().trim().toLowerCase() ?? '';

    final bool verifiedPendingEmail =
        pendingEmail.isNotEmpty && pendingEmail == firebaseEmail;
    final bool emailNeedsSync = storedEmail != firebaseEmail;

    if (!verifiedPendingEmail && !emailNeedsSync) {
      return EmailSyncResult.none;
    }

    final WriteBatch batch = _db.batch();

    if (emailNeedsSync) {
      batch.update(userRef, <String, dynamic>{
        'email': firebaseEmail,
        'updated_at': FieldValue.serverTimestamp(),
      });
    }

    if (username.isNotEmpty) {
      batch.set(
        _db.collection(_loginIndexCollection).doc(username),
        <String, dynamic>{
          'uid': firebaseUser.uid,
          'email': firebaseEmail,
          'username': username,
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();

    if (!verifiedPendingEmail) {
      return EmailSyncResult.none;
    }

    return EmailSyncResult(
      emailChangeVerified: true,
      email: firebaseEmail,
    );
  }

  Future<bool> completeVerifiedEmailChange() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return false;
    }

    try {
      await currentUser.reload();
    } on FirebaseAuthException {
      return false;
    }

    final User? firebaseUser = _auth.currentUser;
    final String firebaseEmail =
        firebaseUser?.email?.trim().toLowerCase() ?? '';

    if (firebaseUser == null || firebaseEmail.isEmpty) {
      return false;
    }

    final DocumentReference<Map<String, dynamic>> userRef =
        _db.collection(_usersCollection).doc(firebaseUser.uid);
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await userRef.get();

    if (!snapshot.exists) {
      return false;
    }

    final Map<String, dynamic> data =
        snapshot.data() ?? <String, dynamic>{};
    final String pendingEmail =
        data['pending_email']?.toString().trim().toLowerCase() ?? '';
    final String username =
        data['username']?.toString().trim().toLowerCase() ?? '';

    if (pendingEmail.isEmpty || pendingEmail != firebaseEmail) {
      return false;
    }

    final WriteBatch batch = _db.batch();
    batch.update(userRef, <String, dynamic>{
      'email': firebaseEmail,
      'pending_email': FieldValue.delete(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    if (username.isNotEmpty) {
      batch.set(
        _db.collection(_loginIndexCollection).doc(username),
        <String, dynamic>{
          'uid': firebaseUser.uid,
          'email': firebaseEmail,
          'username': username,
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
    return true;
  }

  Future<AccountUpdateResult> updateAccount({
    required String uid,
    required String oldUsername,
    required String oldEmail,
    required String username,
    required String email,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final User? firebaseUser = _auth.currentUser;
    if (firebaseUser == null || firebaseUser.uid != uid.trim()) {
      throw const ProfileAccountException(
        'Sesi pengguna tidak valid.',
      );
    }

    final String cleanOldUsername =
        oldUsername.trim().toLowerCase();
    final String cleanUsername = username.trim().toLowerCase();
    final String cleanOldEmail = oldEmail.trim().toLowerCase();
    final String cleanEmail = email.trim().toLowerCase();
    final String cleanPassword = newPassword.trim();

    if (cleanUsername.isEmpty) {
      throw const ProfileAccountException(
        'Username wajib diisi.',
      );
    }

    if (!_isValidEmail(cleanEmail)) {
      throw const ProfileAccountException(
        'Format email tidak valid.',
      );
    }

    if (cleanPassword.isNotEmpty) {
      if (cleanPassword.length < 6) {
        throw const ProfileAccountException(
          'Kata sandi baru minimal 6 karakter.',
        );
      }

      if (cleanPassword != confirmPassword) {
        throw const ProfileAccountException(
          'Konfirmasi kata sandi baru tidak sama.',
        );
      }
    }

    final bool usernameChanged =
        cleanUsername != cleanOldUsername;
    final bool emailChanged = cleanEmail != cleanOldEmail;

    await _assertUsernameAvailable(
      username: cleanUsername,
      uid: firebaseUser.uid,
    );

    bool verificationEmailSent = false;
    bool passwordChanged = false;

    try {
      if (emailChanged) {
        await firebaseUser.verifyBeforeUpdateEmail(cleanEmail);
        verificationEmailSent = true;
      }

      if (cleanPassword.isNotEmpty) {
        await firebaseUser.updatePassword(cleanPassword);
        passwordChanged = true;
      }
    } on FirebaseAuthException catch (error) {
      throw ProfileAccountException(
        _firebaseMessage(error),
        code: error.code,
      );
    }

    final DocumentReference<Map<String, dynamic>> userRef =
        _db.collection(_usersCollection).doc(firebaseUser.uid);
    final DocumentReference<Map<String, dynamic>> newIndexRef =
        _db.collection(_loginIndexCollection).doc(cleanUsername);
    final DocumentReference<Map<String, dynamic>>? oldIndexRef =
        cleanOldUsername.isEmpty
            ? null
            : _db
                .collection(_loginIndexCollection)
                .doc(cleanOldUsername);

    await _db.runTransaction<void>((Transaction transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> userSnapshot =
          await transaction.get(userRef);
      final DocumentSnapshot<Map<String, dynamic>> newIndexSnapshot =
          await transaction.get(newIndexRef);
      final DocumentSnapshot<Map<String, dynamic>>? oldIndexSnapshot =
          oldIndexRef == null
              ? null
              : await transaction.get(oldIndexRef);

      if (!userSnapshot.exists) {
        throw const ProfileAccountException(
          'Data akun tidak ditemukan.',
        );
      }

      if (newIndexSnapshot.exists) {
        final String ownerUid =
            newIndexSnapshot.data()?['uid']?.toString().trim() ?? '';
        if (ownerUid != firebaseUser.uid) {
          throw const ProfileAccountException(
            'Username sudah digunakan.',
          );
        }
      }

      transaction.update(userRef, <String, dynamic>{
        'username': cleanUsername,
        'username_lower': cleanUsername,
        if (emailChanged) 'pending_email': cleanEmail,
        'updated_at': FieldValue.serverTimestamp(),
      });

      transaction.set(
        newIndexRef,
        <String, dynamic>{
          'uid': firebaseUser.uid,
          'email': cleanOldEmail,
          'username': cleanUsername,
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (usernameChanged &&
          oldIndexRef != null &&
          oldIndexSnapshot?.exists == true) {
        final String oldOwnerUid =
            oldIndexSnapshot!.data()?['uid']?.toString().trim() ?? '';
        if (oldOwnerUid == firebaseUser.uid) {
          transaction.delete(oldIndexRef);
        }
      }
    });

    return AccountUpdateResult(
      verificationEmailSent: verificationEmailSent,
      passwordChanged: passwordChanged,
    );
  }

  Future<void> _assertUsernameAvailable({
    required String username,
    required String uid,
  }) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _db.collection(_loginIndexCollection).doc(username).get();

    if (!snapshot.exists) {
      return;
    }

    final String ownerUid =
        snapshot.data()?['uid']?.toString().trim() ?? '';
    if (ownerUid != uid) {
      throw const ProfileAccountException(
        'Username sudah digunakan.',
      );
    }
  }

  static bool _isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  static String _firebaseMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'requires-recent-login':
        return 'Perubahan email atau kata sandi memerlukan sesi login terbaru. '
            'Silakan logout, login kembali, lalu ulangi perubahan.';
      case 'email-already-in-use':
        return 'Email sudah digunakan oleh akun lain.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'weak-password':
        return 'Kata sandi baru terlalu lemah.';
      case 'network-request-failed':
        return 'Koneksi internet bermasalah.';
      default:
        return error.message ?? 'Gagal memperbarui akun.';
    }
  }
}

class ProfileAccountException implements Exception {
  final String message;
  final String? code;

  const ProfileAccountException(
    this.message, {
    this.code,
  });

  @override
  String toString() => message;
}
