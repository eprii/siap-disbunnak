import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';



class StorageService {
  static final StorageService instance =
      StorageService._internal();
  factory StorageService(){
    return instance;
  }
  StorageService._internal();

  final SupabaseClient _client =
      Supabase.instance.client;

  // ================================
  // UPLOAD FOTO PROFIL
  // ================================

  Future<String> uploadProfilePhoto(
      File file,
      String uid,
  ) async {

    final path =
        '$uid/avatar.webp';

    await _client.storage
        .from(
          'profile-photos',
        )
        .upload(
          path,
          file,
          fileOptions:
              const FileOptions(
                upsert:true,
              ),
        );
    return path;

  }

  // ================================
  // SIGNED URL
  // ================================

  Future<String>
  getProfilePhotoUrl(
      String path,
  ) async {

    return await _client.storage
        .from(
          'profile-photos',
        )
        .createSignedUrl(
          path,
          3600,
        );
  }
  // ================================
  // DELETE FOTO
  // ================================

  Future<void> deleteProfilePhoto(
      String path,
  ) async {

    await _client.storage
        .from(
          'profile-photos',
        )
        .remove([
          path,
        ]);
  }
}