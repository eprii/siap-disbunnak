class FileHelper {
  FileHelper._();

  static const int maxPdfSizeMb = 20;

  static String getFileName(String path) {
    if (path.trim().isEmpty) return '';

    return path.replaceAll('\\', '/').split('/').last;
  }

  static bool isPdf(String fileName) {
    return fileName.trim().toLowerCase().endsWith('.pdf');
  }

  static bool isValidSize(int sizeInBytes, {int maxSizeMb = maxPdfSizeMb}) {
    final maxSizeInBytes = maxSizeMb * 1024 * 1024;

    return sizeInBytes > 0 && sizeInBytes <= maxSizeInBytes;
  }

  static String formatFileSize(int sizeInBytes) {
    if (sizeInBytes < 1024) {
      return '$sizeInBytes B';
    }

    if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    }

    return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static String sanitizeFileName(String fileName) {
    return fileName
        .trim()
        .replaceAll(RegExp(r'[^\w.\-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }
}
