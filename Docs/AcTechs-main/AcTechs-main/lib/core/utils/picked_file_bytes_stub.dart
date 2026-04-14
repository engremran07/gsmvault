import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<Uint8List?> loadPickedFileBytes(PlatformFile source) async {
  return source.bytes;
}

Future<void> cleanupPickedFile(PlatformFile source) async {}
