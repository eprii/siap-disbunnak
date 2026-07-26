import 'package:cloud_firestore/cloud_firestore.dart';

class DateFormatter {
  DateFormatter._();

  static const List<String> _namaBulan = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static String formatDate(DateTime? date) {
    if (date == null) return '-';

    return '${date.day} ${_namaBulan[date.month - 1]} ${date.year}';
  }

  static String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '-';

    return formatDate(timestamp.toDate());
  }

  static String formatIsoString(String? value) {
    if (value == null || value.trim().isEmpty) return '-';

    final date = DateTime.tryParse(value);
    return date == null ? value : formatDate(date);
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return '-';

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '${formatDate(date)}, $hour.$minute';
  }
}
