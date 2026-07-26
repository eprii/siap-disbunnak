import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployeeSkFileService {
  EmployeeSkFileService._();

  static final EmployeeSkFileService instance =
      EmployeeSkFileService._();

  static const String _bucket = 'sk';

  SupabaseClient get _client => Supabase.instance.client;

  Future<String> preparePreviewFile({
    required String storagePath,
    required String fileName,
  }) async {
    final Uint8List bytes = await _downloadBytes(storagePath);
    final String safeName = _safeFileName(fileName);

    final Directory previewDirectory = Directory(
      '${Directory.systemTemp.path}/siap_pdf_preview',
    );

    if (!await previewDirectory.exists()) {
      await previewDirectory.create(recursive: true);
    }

    final File localFile = File(
      '${previewDirectory.path}/'
      '${DateTime.now().millisecondsSinceEpoch}_$safeName',
    );

    await localFile.writeAsBytes(
      bytes,
      flush: true,
    );

    return localFile.path;
  }

  Future<String?> downloadFile({
    required String storagePath,
    required String fileName,
  }) async {
    final Uint8List bytes = await _downloadBytes(storagePath);
    final String safeName = _safeFileName(fileName);

    try {
      return await FilePicker.saveFile(
        dialogTitle: 'Simpan dokumen SK',
        fileName: safeName,
        type: FileType.custom,
        allowedExtensions: const <String>['pdf'],
        bytes: bytes,
      );
    } catch (error) {
      throw EmployeeSkFileException(
        'Gagal menyimpan dokumen: $error',
      );
    }
  }

  Future<Uint8List> _downloadBytes(
    String storagePath,
  ) async {
    final String cleanPath = storagePath.trim();

    if (cleanPath.isEmpty) {
      throw const EmployeeSkFileException(
        'File PDF belum tersedia.',
      );
    }

    try {
      if (cleanPath.startsWith('http://') ||
          cleanPath.startsWith('https://')) {
        return _downloadFromUrl(cleanPath);
      }

      return await _client.storage
          .from(_bucket)
          .download(cleanPath);
    } on StorageException catch (error) {
      final String lower = error.message.toLowerCase();

      if (lower.contains('unauthorized') ||
          lower.contains('forbidden') ||
          lower.contains('permission') ||
          lower.contains('row-level security')) {
        throw const EmployeeSkFileException(
          'Kamu tidak memiliki izin membuka dokumen SK ini.',
        );
      }

      throw EmployeeSkFileException(
        error.message.trim().isEmpty
            ? 'Gagal mengambil dokumen dari Storage.'
            : error.message,
      );
    } on EmployeeSkFileException {
      rethrow;
    } catch (error) {
      throw EmployeeSkFileException(
        'Gagal mengambil dokumen: $error',
      );
    }
  }

  Future<Uint8List> _downloadFromUrl(
    String url,
  ) async {
    final HttpClient client = HttpClient();

    try {
      final HttpClientRequest request =
          await client.getUrl(Uri.parse(url));
      final HttpClientResponse response =
          await request.close();

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw EmployeeSkFileException(
          'Server menolak file dengan status '
          '${response.statusCode}.',
        );
      }

      final BytesBuilder builder = BytesBuilder(copy: false);

      await for (final List<int> chunk in response) {
        builder.add(chunk);
      }

      return builder.takeBytes();
    } finally {
      client.close(force: true);
    }
  }

  static String _safeFileName(
    String fileName,
  ) {
    String result = fileName.trim();

    if (result.isEmpty) {
      result = 'dokumen_sk.pdf';
    }

    result = result.replaceAll(
      RegExp(r'[\\/:*?"<>|]'),
      '_',
    );

    if (!result.toLowerCase().endsWith('.pdf')) {
      result = '$result.pdf';
    }

    return result;
  }
}

class EmployeeSkFileException implements Exception {
  final String message;

  const EmployeeSkFileException(this.message);

  @override
  String toString() => message;
}
