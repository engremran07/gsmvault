import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'picked_file_bytes_stub.dart'
    if (dart.library.io) 'picked_file_bytes_io.dart'
    as impl;

Future<Uint8List?> loadPickedFileBytes(PlatformFile source) {
  return impl.loadPickedFileBytes(source);
}

Future<void> cleanupPickedFile(PlatformFile source) {
  return impl.cleanupPickedFile(source);
}
