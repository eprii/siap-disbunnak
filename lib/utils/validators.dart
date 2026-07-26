class Validators {
  Validators._();

  static String? requiredField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName wajib diisi';
    }

    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email wajib diisi';
    }

    final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

    if (!emailPattern.hasMatch(value.trim())) {
      return 'Format email tidak valid';
    }

    return null;
  }

  static String? nip(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'NIP wajib diisi';
    }

    if (!RegExp(r'^\d+$').hasMatch(value.trim())) {
      return 'NIP hanya boleh berisi angka';
    }

    return null;
  }

  static String? year(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Tahun wajib diisi';
    }

    final year = int.tryParse(value.trim());
    final currentYear = DateTime.now().year;

    if (year == null || year < 1900 || year > currentYear + 10) {
      return 'Tahun tidak valid';
    }

    return null;
  }

  static String? positiveInteger(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName wajib diisi';
    }

    final number = int.tryParse(value.trim());

    if (number == null || number < 0) {
      return '$fieldName harus berupa angka positif';
    }

    return null;
  }

  static String? decimal(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName wajib diisi';
    }

    final normalizedValue = value.trim().replaceAll(',', '.');
    final number = double.tryParse(normalizedValue);

    if (number == null || number < 0) {
      return '$fieldName tidak valid';
    }

    return null;
  }
}
