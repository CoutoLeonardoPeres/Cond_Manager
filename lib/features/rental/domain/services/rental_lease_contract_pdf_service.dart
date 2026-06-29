import 'package:cond_manager/core/utils/pdf_bytes_opener.dart';
import 'package:cond_manager/features/rental/domain/utils/rental_lease_contract_pdf_layout.dart';
import 'package:cond_manager/features/rental/domain/utils/rental_lease_contract_pdf_mapper.dart';
import 'package:cond_manager/features/rental/domain/utils/rental_lease_contract_template.dart';
import 'package:flutter/services.dart';

/// Gera o PDF do contrato de locação e abre o diálogo de impressão/compartilhamento.
class RentalLeaseContractPdfService {
  const RentalLeaseContractPdfService();

  Future<void> previewContract({
    required RentalLeaseContractPdfContext context,
    String? documentName,
  }) async {
    final validation = validateRentalLeaseContractPdfContext(context);
    if (validation != null) {
      throw RentalLeaseContractPdfException(validation);
    }

    final placeholders = buildRentalLeaseContractPlaceholderMap(context);
    final contractText = applyRentalLeaseContractTemplate(placeholders);
    final doc = await RentalLeaseContractPdfLayout.build(
      context: context,
      placeholders: placeholders,
      contractText: contractText,
    );
    final bytes = await doc.save();
    final name = documentName ?? _defaultDocumentName(context);

    await openPdfBytes(bytes: bytes, filename: name);
  }

  Future<Uint8List> generateBytes(RentalLeaseContractPdfContext context) async {
    final validation = validateRentalLeaseContractPdfContext(context);
    if (validation != null) {
      throw RentalLeaseContractPdfException(validation);
    }

    final placeholders = buildRentalLeaseContractPlaceholderMap(context);
    final contractText = applyRentalLeaseContractTemplate(placeholders);
    final doc = await RentalLeaseContractPdfLayout.build(
      context: context,
      placeholders: placeholders,
      contractText: contractText,
    );
    return doc.save();
  }

  String _defaultDocumentName(RentalLeaseContractPdfContext context) {
    final tenant = context.tenant?.fullName ?? 'locatario';
    final safe = tenant
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return 'contrato_locacao_${safe.isEmpty ? 'imovel' : safe}.pdf';
  }
}

class RentalLeaseContractPdfException implements Exception {
  const RentalLeaseContractPdfException(this.message);
  final String message;

  @override
  String toString() => message;
}
