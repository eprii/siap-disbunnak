import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  WhatsAppService._();

  static final WhatsAppService instance = WhatsAppService._();

  Future<void> openChat({
    required String phoneNumber,
    String? message,
  }) async {
    final String normalized = normalizePhoneNumber(phoneNumber);

    if (normalized.isEmpty) {
      throw const WhatsAppException(
        'Nomor WhatsApp pengguna belum tersedia atau tidak valid.',
      );
    }

    final Map<String, String> queryParameters = <String, String>{};
    final String cleanMessage = message?.trim() ?? '';
    if (cleanMessage.isNotEmpty) {
      queryParameters['text'] = cleanMessage;
    }

    final Uri uri = Uri.https(
      'wa.me',
      '/$normalized',
      queryParameters.isEmpty ? null : queryParameters,
    );

    final bool opened = await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_blank',
    );

    if (!opened) {
      throw const WhatsAppException(
        'WhatsApp atau browser tidak dapat dibuka pada perangkat ini.',
      );
    }
  }

  String normalizePhoneNumber(String value) {
    String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';

    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    }

    if (digits.startsWith('0')) {
      digits = '62${digits.substring(1)}';
    } else if (digits.startsWith('8')) {
      digits = '62$digits';
    }

    if (!digits.startsWith('62')) {
      return '';
    }

    if (digits.length < 10 || digits.length > 15) {
      return '';
    }

    return digits;
  }
}

class WhatsAppException implements Exception {
  final String message;

  const WhatsAppException(this.message);

  @override
  String toString() => message;
}
