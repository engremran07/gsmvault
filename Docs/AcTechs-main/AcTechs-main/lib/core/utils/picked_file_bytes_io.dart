import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<Uint8List?> loadPickedFileBytes(PlatformFile source) async {
  final bytes = source.bytes;
  if (bytes != null && bytes.isNotEmpty) {
    return bytes;
  }
  final path = source.path;
  if (path == null || path.isEmpty) {
    return null;
  }
  return File(path).readAsBytes();
}

Future<void> cleanupPickedFile(PlatformFile source) async {
  final path = source.path;
  if (path == null || path.isEmpty) {
    return;
  }

  try {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  } catch (_) {
    // Best effort only.
  }
}
