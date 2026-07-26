import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePhotoService {
  ProfilePhotoService._();

  static final ProfilePhotoService instance =
      ProfilePhotoService._();

  static const String _bucket = 'profile-photos';

  SupabaseClient get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      throw const ProfilePhotoException(
        'Supabase belum diinisialisasi. Periksa main.dart.',
      );
    }
  }

  Future<String> uploadPhoto({
    required String uid,
    required File file,
  }) async {
    final String cleanUid = uid.trim();
    final firebase_auth.User? currentUser =
        firebase_auth.FirebaseAuth.instance.currentUser;

    if (cleanUid.isEmpty ||
        currentUser == null ||
        currentUser.uid != cleanUid) {
      throw const ProfilePhotoException(
        'Sesi pengguna tidak valid. Silakan login kembali.',
      );
    }

    if (!await file.exists()) {
      throw const ProfilePhotoException(
        'File foto tidak ditemukan.',
      );
    }

    final int size = await file.length();
    if (size <= 0) {
      throw const ProfilePhotoException(
        'File foto kosong atau tidak dapat dibaca.',
      );
    }

    const int maxBytes = 5 * 1024 * 1024;
    if (size > maxBytes) {
      throw const ProfilePhotoException(
        'Ukuran foto profil maksimal 5 MB.',
      );
    }

    final String extension = _extensionFromPath(file.path);
    final String storagePath =
        '$cleanUid/avatar_'
        '${DateTime.now().millisecondsSinceEpoch}'
        '.$extension';

    try {
      // Memastikan token Firebase masih tersedia sebelum request Storage.
      final String? firebaseToken =
          await currentUser.getIdToken(false);

      if (firebaseToken == null ||
          firebaseToken.trim().isEmpty) {
        throw const ProfilePhotoException(
          'Token Firebase tidak tersedia. Silakan login kembali.',
        );
      }

      await _client.storage.from(_bucket).upload(
            storagePath,
            file,
            fileOptions: FileOptions(
              upsert: false,
              contentType: _contentType(extension),
              cacheControl: '3600',
            ),
          );

      return storagePath;
    } on StorageException catch (error) {
      throw ProfilePhotoException(
        _storageMessage(
          error,
          fallback: 'Gagal mengunggah foto profil.',
        ),
      );
    } on ProfilePhotoException {
      rethrow;
    } catch (error) {
      throw ProfilePhotoException(
        'Gagal mengunggah foto profil: $error',
      );
    }
  }

  Future<String> resolvePhotoUrl(
    String storedValue,
  ) async {
    final String cleanValue = storedValue.trim();

    if (cleanValue.isEmpty) return '';
    if (cleanValue.startsWith('http')) {
      return cleanValue;
    }

    try {
      final firebase_auth.User? user =
          firebase_auth.FirebaseAuth.instance.currentUser;

      if (user == null) {
        return '';
      }

      return await _client.storage
          .from(_bucket)
          .createSignedUrl(
            cleanValue,
            86400,
          );
    } on StorageException {
      return '';
    } catch (_) {
      return '';
    }
  }

  Future<void> deletePhoto(
    String storedValue,
  ) async {
    final String cleanValue = storedValue.trim();

    if (cleanValue.isEmpty ||
        cleanValue.startsWith('http')) {
      return;
    }

    final firebase_auth.User? currentUser =
        firebase_auth.FirebaseAuth.instance.currentUser;
    final String firstFolder =
        cleanValue.split('/').first.trim();

    if (currentUser == null ||
        firstFolder != currentUser.uid) {
      throw const ProfilePhotoException(
        'Foto profil tidak dimiliki oleh pengguna '
        'yang sedang login.',
      );
    }

    try {
      final String? firebaseToken =
          await currentUser.getIdToken(false);

      if (firebaseToken == null ||
          firebaseToken.trim().isEmpty) {
        throw const ProfilePhotoException(
          'Token Firebase tidak tersedia. Silakan login kembali.',
        );
      }

      await _client.storage.from(_bucket).remove(
        <String>[cleanValue],
      );
    } on StorageException catch (error) {
      throw ProfilePhotoException(
        _storageMessage(
          error,
          fallback: 'Gagal menghapus foto profil.',
        ),
      );
    } on ProfilePhotoException {
      rethrow;
    } catch (error) {
      throw ProfilePhotoException(
        'Gagal menghapus foto profil: $error',
      );
    }
  }

  static String _storageMessage(
    StorageException error, {
    required String fallback,
  }) {
    final String message = error.message.trim();
    final String lower = message.toLowerCase();

    if (lower.contains('row-level security') ||
        lower.contains('unauthorized') ||
        lower.contains('forbidden') ||
        lower.contains('permission')) {
      return 'Izin Supabase Storage ditolak. '
          'Pastikan Firebase Third-Party Auth aktif, '
          'Supabase.initialize memakai accessToken Firebase, '
          'dan policy bucket profile-photos sudah dijalankan.';
    }

    if (lower.contains('bucket') &&
        lower.contains('not found')) {
      return 'Bucket Supabase "profile-photos" belum dibuat.';
    }

    if (lower.contains('jwt') ||
        lower.contains('token')) {
      return 'Token Firebase tidak diterima Supabase. '
          'Silakan logout lalu login kembali.';
    }

    return message.isEmpty ? fallback : message;
  }

  static String _extensionFromPath(
    String path,
  ) {
    final String fileName = path.split('/').last;
    final int dotIndex = fileName.lastIndexOf('.');

    if (dotIndex < 0 ||
        dotIndex == fileName.length - 1) {
      return 'jpg';
    }

    final String extension =
        fileName.substring(dotIndex + 1).toLowerCase();

    if (<String>{
      'jpg',
      'jpeg',
      'png',
      'webp',
    }.contains(extension)) {
      return extension;
    }

    return 'jpg';
  }

  static String _contentType(
    String extension,
  ) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpeg':
      case 'jpg':
      default:
        return 'image/jpeg';
    }
  }
}

class ProfilePhotoException
    implements Exception {
  final String message;

  const ProfilePhotoException(
    this.message,
  );

  @override
  String toString() => message;
}
