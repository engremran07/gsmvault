import 'package:url_launcher/url_launcher.dart';

class WhatsAppLauncher {
  WhatsAppLauncher._();

  static String normalizeNumber(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9+]'), '').trim();
    if (digits.isEmpty) return '';
    if (digits.startsWith('+')) {
      return digits.substring(1);
    }
    if (digits.startsWith('00')) {
      return digits.substring(2);
    }
    return digits;
  }

  static Future<bool> openChat(String rawPhone) async {
    final normalized = normalizeNumber(rawPhone);
    if (normalized.isEmpty) return false;

    final uri = Uri.parse('https://wa.me/$normalized');
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
