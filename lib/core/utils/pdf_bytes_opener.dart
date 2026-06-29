import 'dart:typed_data';

import 'pdf_bytes_opener_stub.dart'
    if (dart.library.html) 'pdf_bytes_opener_web.dart' as pdf_opener;

Future<void> openPdfBytes({
  required Uint8List bytes,
  required String filename,
}) =>
    pdf_opener.openPdfBytes(bytes: bytes, filename: filename);
