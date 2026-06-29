import 'package:cond_manager/features/rental/domain/utils/rental_lease_contract_pdf_mapper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart' show PdfGoogleFonts;

/// Paleta e tipografia do contrato em PDF.
class _ContractPdfTheme {
  static const accent = PdfColor.fromInt(0xFF5C4DCE);
  static const accentDark = PdfColor.fromInt(0xFF3D3489);
  static const accentSoft = PdfColor.fromInt(0xFFF4F2FC);
  static const textPrimary = PdfColor.fromInt(0xFF1E1B2E);
  static const textSecondary = PdfColor.fromInt(0xFF5C5670);
  static const border = PdfColor.fromInt(0xFFE4E0F0);
  static const white = PdfColor.fromInt(0xFFFFFFFF);
}

/// Monta o documento PDF com capa-resumo, cláusulas estruturadas e bloco de assinaturas.
class RentalLeaseContractPdfLayout {
  static Future<pw.Document> build({
    required RentalLeaseContractPdfContext context,
    required Map<String, String> placeholders,
    required String contractText,
  }) async {
    final regular = await PdfGoogleFonts.nunitoRegular();
    final bold = await PdfGoogleFonts.nunitoBold();
    final semiBold = await PdfGoogleFonts.nunitoSemiBold();

    final doc = pw.Document(
      title: 'Contrato de Locação de Imóvel',
      author: 'Cond Manager',
    );

    final bodyStyle = pw.TextStyle(font: regular, fontSize: 9.5, lineSpacing: 3, color: _ContractPdfTheme.textPrimary);
    final clauseTitleStyle = pw.TextStyle(font: bold, fontSize: 10.5, color: _ContractPdfTheme.accentDark, letterSpacing: 0.3);
    final subClauseStyle = pw.TextStyle(font: semiBold, fontSize: 9.5, color: _ContractPdfTheme.textPrimary);

    final lines = contractText.split('\n');
    final parsed = _parseContractLines(lines);
    final signatureStart = parsed.indexWhere((l) => l.kind == _LineKind.signatureIntro);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(44, 52, 44, 56),
        header: (ctx) => _pageHeader(ctx, placeholders, bold, semiBold),
        footer: (ctx) => _pageFooter(ctx, regular),
        build: (ctx) => [
          _heroBlock(placeholders, bold, semiBold, regular),
          pw.SizedBox(height: 18),
          _partiesRow(placeholders, bold, semiBold, regular),
          pw.SizedBox(height: 14),
          _propertyCard(placeholders, bold, semiBold, regular),
          pw.SizedBox(height: 20),
          _keyTermsRow(placeholders, bold, semiBold, regular),
          pw.SizedBox(height: 22),
          pw.Divider(color: _ContractPdfTheme.border, thickness: 0.8),
          pw.SizedBox(height: 14),
          ..._buildBodyWidgets(
            parsed.take(signatureStart >= 0 ? signatureStart : parsed.length),
            bodyStyle,
            clauseTitleStyle,
            subClauseStyle,
          ),
          if (signatureStart >= 0) ...[
            pw.SizedBox(height: 16),
            pw.Divider(color: _ContractPdfTheme.border, thickness: 0.8),
            pw.SizedBox(height: 12),
            ..._buildSignatureBlock(
              parsed.skip(signatureStart),
              placeholders,
              bold,
              semiBold,
              regular,
            ),
          ],
        ],
      ),
    );

    return doc;
  }

  static pw.Widget _pageHeader(
    pw.Context ctx,
    Map<String, String> p,
    pw.Font bold,
    pw.Font semiBold,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        children: [
          pw.Container(height: 3, color: _ContractPdfTheme.accent),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'COND MANAGER',
                    style: pw.TextStyle(font: bold, fontSize: 9, color: _ContractPdfTheme.accent, letterSpacing: 1.2),
                  ),
                  pw.Text(
                    'Locação',
                    style: pw.TextStyle(font: semiBold, fontSize: 7.5, color: _ContractPdfTheme.textSecondary),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  if ((p['CONTRATO_NUMERO'] ?? '').isNotEmpty)
                    pw.Text(
                      'Contrato nº ${p['CONTRATO_NUMERO']}',
                      style: pw.TextStyle(font: semiBold, fontSize: 8, color: _ContractPdfTheme.textSecondary),
                    ),
                  pw.Text(
                    'Gerado em ${p['CONTRATO_DATA_GERACAO'] ?? '—'}',
                    style: pw.TextStyle(font: semiBold, fontSize: 7.5, color: _ContractPdfTheme.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _pageFooter(pw.Context ctx, pw.Font regular) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Documento gerado eletronicamente',
            style: pw.TextStyle(font: regular, fontSize: 7, color: _ContractPdfTheme.textSecondary),
          ),
          pw.Text(
            'Página ${ctx.pageNumber} de ${ctx.pagesCount}',
            style: pw.TextStyle(font: regular, fontSize: 7, color: _ContractPdfTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  static pw.Widget _heroBlock(
    Map<String, String> p,
    pw.Font bold,
    pw.Font semiBold,
    pw.Font regular,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: pw.BoxDecoration(
        gradient: const pw.LinearGradient(
          colors: [_ContractPdfTheme.accent, _ContractPdfTheme.accentDark],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'CONTRATO DE LOCAÇÃO DE IMÓVEL',
            style: pw.TextStyle(font: bold, fontSize: 16, color: _ContractPdfTheme.white, letterSpacing: 0.5),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            p['TIPO_LOCACAO'] ?? 'Locação',
            style: pw.TextStyle(font: semiBold, fontSize: 10, color: PdfColors.white),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            p['IMOVEL_ENDERECO_COMPLETO'] ?? '—',
            style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColor.fromInt(0xFFE8E4FF)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _partiesRow(
    Map<String, String> p,
    pw.Font bold,
    pw.Font semiBold,
    pw.Font regular,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: _partyCard('LOCADOR', p, bold, semiBold, regular)),
        pw.SizedBox(width: 10),
        pw.Expanded(child: _partyCard('LOCATÁRIO', p, bold, semiBold, regular, prefix: 'LOCATARIO')),
      ],
    );
  }

  static pw.Widget _partyCard(
    String title,
    Map<String, String> p,
    pw.Font bold,
    pw.Font semiBold,
    pw.Font regular, {
    String prefix = 'LOCADOR',
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _ContractPdfTheme.accentSoft,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _ContractPdfTheme.border, width: 0.6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(font: bold, fontSize: 8, color: _ContractPdfTheme.accent, letterSpacing: 1),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            p['${prefix}_NOME'] ?? '—',
            style: pw.TextStyle(font: semiBold, fontSize: 10, color: _ContractPdfTheme.textPrimary),
          ),
          pw.SizedBox(height: 4),
          _infoLine('CPF/CNPJ', p['${prefix}_CPF_CNPJ'], regular),
          _infoLine('E-mail', p['${prefix}_EMAIL'], regular),
          _infoLine('Telefone', p['${prefix}_TELEFONE'], regular),
        ],
      ),
    );
  }

  static pw.Widget _infoLine(String label, String? value, pw.Font regular) {
    if (value == null || value.trim().isEmpty || value == '________________') return pw.SizedBox();
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: pw.TextStyle(font: regular, fontSize: 8, color: _ContractPdfTheme.textSecondary),
            ),
            pw.TextSpan(
              text: value,
              style: pw.TextStyle(font: regular, fontSize: 8.5, color: _ContractPdfTheme.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _propertyCard(
    Map<String, String> p,
    pw.Font bold,
    pw.Font semiBold,
    pw.Font regular,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _ContractPdfTheme.border, width: 0.6),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('IMÓVEL', style: pw.TextStyle(font: bold, fontSize: 8, color: _ContractPdfTheme.accent, letterSpacing: 1)),
          pw.SizedBox(height: 6),
          pw.Text(
            p['IMOVEL_ENDERECO_COMPLETO'] ?? '—',
            style: pw.TextStyle(font: semiBold, fontSize: 10, color: _ContractPdfTheme.textPrimary),
          ),
          pw.SizedBox(height: 4),
          pw.Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              if ((p['IMOVEL_TIPO'] ?? '').isNotEmpty) _chip(p['IMOVEL_TIPO']!, regular),
              if ((p['IMOVEL_QUARTOS'] ?? '').isNotEmpty) _chip('${p['IMOVEL_QUARTOS']} quartos', regular),
              if ((p['CONDOMINIO_NOME'] ?? '').isNotEmpty) _chip(p['CONDOMINIO_NOME']!, regular),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _chip(String text, pw.Font regular) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: pw.BoxDecoration(
        color: _ContractPdfTheme.accentSoft,
        borderRadius: pw.BorderRadius.circular(20),
      ),
      child: pw.Text(text, style: pw.TextStyle(font: regular, fontSize: 7.5, color: _ContractPdfTheme.accentDark)),
    );
  }

  static pw.Widget _keyTermsRow(
    Map<String, String> p,
    pw.Font bold,
    pw.Font semiBold,
    pw.Font regular,
  ) {
    final items = <(String, String)>[
      ('Início', p['DATA_INICIO_LOCACAO'] ?? '—'),
      ('Término', p['DATA_TERMINO_LOCACAO'] ?? '—'),
      ('Aluguel', p['VALOR_ALUGUEL_MENSAL'] != null ? 'R\$ ${p['VALOR_ALUGUEL_MENSAL']}' : '—'),
      ('Caução', p['VALOR_CAUCAO'] != null ? 'R\$ ${p['VALOR_CAUCAO']}' : '—'),
      ('Vencimento', p['DIA_VENCIMENTO_ALUGUEL'] != null ? 'Dia ${p['DIA_VENCIMENTO_ALUGUEL']}' : '—'),
      ('Finalidade', p['FINALIDADE_LOCACAO'] ?? '—'),
    ];

    return pw.Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _ContractPdfTheme.border, width: 0.5),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    items[i].$1.toUpperCase(),
                    style: pw.TextStyle(font: bold, fontSize: 6.5, color: _ContractPdfTheme.textSecondary, letterSpacing: 0.6),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    items[i].$2,
                    style: pw.TextStyle(font: semiBold, fontSize: 8, color: _ContractPdfTheme.textPrimary),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  static List<pw.Widget> _buildBodyWidgets(
    Iterable<_ParsedLine> lines,
    pw.TextStyle bodyStyle,
    pw.TextStyle clauseTitleStyle,
    pw.TextStyle subClauseStyle,
  ) {
    final widgets = <pw.Widget>[];
    var skipPreamble = true;

    for (final line in lines) {
      if (skipPreamble &&
          (line.kind == _LineKind.preamble ||
              line.kind == _LineKind.title ||
              line.kind == _LineKind.blank)) {
        continue;
      }
      skipPreamble = false;

      switch (line.kind) {
        case _LineKind.blank:
          widgets.add(pw.SizedBox(height: 6));
        case _LineKind.clauseTitle:
          widgets.add(pw.SizedBox(height: 10));
          widgets.add(
            pw.Container(
              padding: const pw.EdgeInsets.only(left: 10, top: 6, bottom: 6),
              decoration: const pw.BoxDecoration(
                border: pw.Border(left: pw.BorderSide(color: _ContractPdfTheme.accent, width: 3)),
                color: _ContractPdfTheme.accentSoft,
              ),
              child: pw.Text(line.text, style: clauseTitleStyle),
            ),
          );
        case _LineKind.subClause:
          widgets.add(pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4, left: 4),
            child: pw.Text(line.text, style: subClauseStyle, textAlign: pw.TextAlign.justify),
          ));
        case _LineKind.listItem:
          widgets.add(pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2, left: 14),
            child: pw.Text(line.text, style: bodyStyle, textAlign: pw.TextAlign.justify),
          ));
        default:
          widgets.add(pw.Padding(
            padding: const pw.EdgeInsets.only(top: 3),
            child: pw.Text(line.text, style: bodyStyle, textAlign: pw.TextAlign.justify),
          ));
      }
    }
    return widgets;
  }

  static List<pw.Widget> _buildSignatureBlock(
    Iterable<_ParsedLine> lines,
    Map<String, String> p,
    pw.Font bold,
    pw.Font semiBold,
    pw.Font regular,
  ) {
    return [
      pw.Text(
        'ASSINATURAS',
        style: pw.TextStyle(font: bold, fontSize: 10, color: _ContractPdfTheme.accentDark, letterSpacing: 0.5),
      ),
      pw.SizedBox(height: 6),
      pw.Text(
        'Local: ${p['LOCAL_ASSINATURA'] ?? '—'}   •   Data: ${p['DATA_ASSINATURA'] ?? '—'}',
        style: pw.TextStyle(font: regular, fontSize: 9, color: _ContractPdfTheme.textSecondary),
      ),
      pw.SizedBox(height: 16),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(child: _signatureField('LOCADOR', p['LOCADOR_NOME'], p['LOCADOR_CPF_CNPJ'], bold, regular)),
          pw.SizedBox(width: 12),
          pw.Expanded(child: _signatureField('LOCATÁRIO / INQUILINO', p['LOCATARIO_NOME'], p['LOCATARIO_CPF_CNPJ'], bold, regular)),
        ],
      ),
      pw.SizedBox(height: 20),
      pw.Row(
        children: [
          pw.Expanded(child: _signatureField('TESTEMUNHA 1', p['TESTEMUNHA1_NOME'], p['TESTEMUNHA1_CPF'], bold, regular)),
          pw.SizedBox(width: 12),
          pw.Expanded(child: _signatureField('TESTEMUNHA 2', p['TESTEMUNHA2_NOME'], p['TESTEMUNHA2_CPF'], bold, regular)),
        ],
      ),
    ];
  }

  static pw.Widget _signatureField(String role, String? name, String? doc, pw.Font bold, pw.Font regular) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          height: 42,
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: _ContractPdfTheme.border, width: 0.8)),
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(role, style: pw.TextStyle(font: bold, fontSize: 7.5, color: _ContractPdfTheme.accent, letterSpacing: 0.6)),
        if (name != null && name != '________________')
          pw.Text(name, style: pw.TextStyle(font: regular, fontSize: 8.5, color: _ContractPdfTheme.textPrimary)),
        if (doc != null && doc != '________________')
          pw.Text('CPF/CNPJ: $doc', style: pw.TextStyle(font: regular, fontSize: 8, color: _ContractPdfTheme.textSecondary)),
      ],
    );
  }
}

enum _LineKind { blank, title, preamble, clauseTitle, subClause, listItem, signatureIntro, body }

class _ParsedLine {
  const _ParsedLine(this.text, this.kind);
  final String text;
  final _LineKind kind;
}

final _clauseTitleRe = RegExp(r'^\d+\.\s+[A-ZÁÉÍÓÚÂÊÔÃÕÇ]');
final _subClauseRe = RegExp(r'^\d+\.\d+\.');
final _listItemRe = RegExp(r'^[a-z]\)');

List<_ParsedLine> _parseContractLines(List<String> lines) {
  final result = <_ParsedLine>[];
  for (final raw in lines) {
    final text = raw.trimRight();
    if (text.trim().isEmpty) {
      result.add(const _ParsedLine('', _LineKind.blank));
      continue;
    }
    if (text == 'CONTRATO DE LOCAÇÃO DE IMÓVEL') {
      result.add(_ParsedLine(text, _LineKind.title));
    } else if (text.startsWith('E, por estarem justas')) {
      result.add(_ParsedLine(text, _LineKind.signatureIntro));
    } else if (_clauseTitleRe.hasMatch(text) && !_subClauseRe.hasMatch(text)) {
      result.add(_ParsedLine(text, _LineKind.clauseTitle));
    } else if (_subClauseRe.hasMatch(text)) {
      result.add(_ParsedLine(text, _LineKind.subClause));
    } else if (_listItemRe.hasMatch(text.trimLeft())) {
      result.add(_ParsedLine(text, _LineKind.listItem));
    } else if (text.startsWith('LOCADOR:') ||
        text.startsWith('LOCATÁRIO') ||
        text.startsWith('têm entre si')) {
      result.add(_ParsedLine(text, _LineKind.preamble));
    } else {
      result.add(_ParsedLine(text, _LineKind.body));
    }
  }
  return result;
}
