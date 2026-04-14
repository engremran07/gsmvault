import 'dart:convert';
import 'dart:typed_data';

/// Encodes and decodes image bytes to Base64 for Firestore-only persistence.
///
/// This keeps the app free-tier friendly by avoiding Firebase Storage usage
/// for image payloads. Prefer compressed images and small payload sizes.
class Base64ImageCodec {
  const Base64ImageCodec._();

  // Keep logo payloads small enough for Firestore documents on the free tier.
  static const int recommendedMaxLogoBytes = 180 * 1024;

  static String encode(Uint8List bytes) => base64Encode(bytes);

  static Uint8List decode(String value) => base64Decode(value);

  static Uint8List? tryDecodeBytes(String value) {
    if (value.trim().isEmpty) return null;
    try {
      return decode(value);
    } catch (_) {
      return null;
    }
  }

  static String? tryDecodeSvgBytes(Uint8List bytes) {
    try {
      final text = utf8.decode(bytes).trimLeft();
      if (text.isEmpty) return null;
      final normalized = text.toLowerCase();
      return normalized.contains('<svg') ? text : null;
    } catch (_) {
      return null;
    }
  }

  static String? tryDecodeSvg(String value) {
    final bytes = tryDecodeBytes(value);
    if (bytes == null) return null;
    return tryDecodeSvgBytes(bytes);
  }

  static bool isWithinRecommendedLogoLimit(Uint8List bytes) {
    return bytes.lengthInBytes <= recommendedMaxLogoBytes;
  }
}
