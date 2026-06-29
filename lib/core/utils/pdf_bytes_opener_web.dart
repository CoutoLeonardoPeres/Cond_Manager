import 'dart:html' as html;
import 'dart:typed_data';

/// Na web, abre o PDF em nova aba (impressão/salvar via navegador).
Future<void> openPdfBytes({
  required Uint8List bytes,
  required String filename,
}) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);

  html.window.open(url, '_blank');

  Future<void>.delayed(const Duration(seconds: 60), () {
    html.Url.revokeObjectUrl(url);
  });
}
