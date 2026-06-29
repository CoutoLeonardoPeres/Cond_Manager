import 'dart:typed_data';

import 'package:printing/printing.dart';

Future<void> openPdfBytes({
  required Uint8List bytes,
  required String filename,
}) {
  return Printing.layoutPdf(
    name: filename,
    onLayout: (_) async => bytes,
  );
}
