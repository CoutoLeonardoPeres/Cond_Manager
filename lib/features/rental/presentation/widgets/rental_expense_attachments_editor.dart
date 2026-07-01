import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/financial/presentation/providers/financial_providers.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_expense_attachment.dart';
import 'package:cond_manager/features/rental/presentation/providers/rental_providers.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

const _maxAttachmentBytes = 20 * 1024 * 1024;

/// NF / recibo — fotos ou PDF. Em criação, arquivos ficam em [pending] até salvar a despesa.
class RentalExpenseAttachmentsEditor extends ConsumerStatefulWidget {
  const RentalExpenseAttachmentsEditor({
    super.key,
    this.expenseId,
    required this.pending,
    required this.onPendingChanged,
    this.enabled = true,
  });

  final String? expenseId;
  final List<PendingRentalExpenseAttachment> pending;
  final ValueChanged<List<PendingRentalExpenseAttachment>> onPendingChanged;
  final bool enabled;

  @override
  ConsumerState<RentalExpenseAttachmentsEditor> createState() =>
      _RentalExpenseAttachmentsEditorState();
}

class _RentalExpenseAttachmentsEditorState extends ConsumerState<RentalExpenseAttachmentsEditor> {
  final _imagePicker = ImagePicker();
  bool _busy = false;
  String? _error;

  String? get _companyId => ref.read(currentProfileProvider).value?.companyId;

  Future<void> _pickPhotos() async {
    if (!widget.enabled || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final images = await _imagePicker.pickMultiImage(imageQuality: 85);
      if (images.isEmpty) return;

      final added = <PendingRentalExpenseAttachment>[];
      for (final file in images) {
        final bytes = await file.readAsBytes();
        final err = _validateBytes(bytes, file.name);
        if (err != null) {
          setState(() => _error = err);
          continue;
        }
        added.add(
          PendingRentalExpenseAttachment(
            bytes: bytes,
            fileName: file.name,
            mimeType: _mimeFromName(file.name),
          ),
        );
      }
      if (added.isEmpty) return;

      if (widget.expenseId != null) {
        await _uploadPending(added);
      } else {
        widget.onPendingChanged([...widget.pending, ...added]);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickPdf() async {
    if (!widget.enabled || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final added = <PendingRentalExpenseAttachment>[];
      for (final file in result.files) {
        final bytes = file.bytes;
        if (bytes == null) continue;
        final name = file.name;
        final err = _validateBytes(bytes, name);
        if (err != null) {
          setState(() => _error = err);
          continue;
        }
        added.add(
          PendingRentalExpenseAttachment(
            bytes: bytes,
            fileName: name,
            mimeType: 'application/pdf',
          ),
        );
      }
      if (added.isEmpty) return;

      if (widget.expenseId != null) {
        await _uploadPending(added);
      } else {
        widget.onPendingChanged([...widget.pending, ...added]);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _validateBytes(Uint8List bytes, String name) {
    if (bytes.length > _maxAttachmentBytes) {
      return 'Arquivo muito grande ($name). Máximo 20 MB.';
    }
    return null;
  }

  String _mimeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.heif')) return 'image/heif';
    return 'image/jpeg';
  }

  Future<void> _uploadPending(List<PendingRentalExpenseAttachment> files) async {
    final expenseId = widget.expenseId;
    final companyId = _companyId;
    if (expenseId == null || companyId == null || files.isEmpty) return;

    final upload = await ref.read(financialRepositoryProvider).uploadRentalExpenseAttachments(
          financialRecordId: expenseId,
          companyId: companyId,
          files: files,
        );

    if (!mounted) return;

    upload.when(
      success: (_) {
        ref.invalidate(rentalExpenseAttachmentsProvider(expenseId));
      },
      failure: (e) => setState(() => _error = e.message),
    );
  }

  Future<void> _removePending(int index) async {
    final next = [...widget.pending]..removeAt(index);
    widget.onPendingChanged(next);
  }

  Future<void> _deleteExisting(RentalExpenseAttachment attachment) async {
    if (!widget.enabled || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result =
          await ref.read(financialRepositoryProvider).deleteRentalExpenseAttachment(attachment);
      if (!mounted) return;
      result.when(
        success: (_) {
          if (widget.expenseId != null) {
            ref.invalidate(rentalExpenseAttachmentsProvider(widget.expenseId!));
          }
        },
        failure: (e) => setState(() => _error = e.message),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final expenseId = widget.expenseId;
    final existingAsync = expenseId != null
        ? ref.watch(rentalExpenseAttachmentsProvider(expenseId))
        : null;

    final existing = existingAsync?.valueOrNull ?? const <RentalExpenseAttachment>[];
    final totalCount = existing.length + widget.pending.length;

    return ClaySurface(
      depth: ClayDepth.pressed,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded, color: ClayTokens.accent, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'NF / Recibo',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
              if (_busy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Anexe fotos ou PDF da nota fiscal ou comprovante de pagamento.',
            style: TextStyle(color: ClayTokens.textSecondary, fontSize: 12),
          ),
          if (widget.enabled) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _busy ? null : _pickPhotos,
                  icon: const Icon(Icons.photo_camera_rounded, size: 18),
                  label: const Text('Foto'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _pickPdf,
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                  label: const Text('PDF'),
                ),
              ],
            ),
          ],
          if (totalCount == 0 && !widget.enabled)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Nenhum anexo.',
                style: TextStyle(color: ClayTokens.textMuted, fontSize: 13),
              ),
            ),
          if (totalCount > 0) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in existing)
                  _AttachmentChip(
                    label: item.fileName ?? 'Anexo',
                    isPdf: item.isPdf,
                    imageUrl: item.isImage ? item.fileUrl : null,
                    onOpen: () => _openUrl(item.fileUrl),
                    onRemove: widget.enabled ? () => _deleteExisting(item) : null,
                  ),
                for (var i = 0; i < widget.pending.length; i++)
                  _PendingAttachmentChip(
                    file: widget.pending[i],
                    onRemove: widget.enabled ? () => _removePending(i) : null,
                  ),
              ],
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: ClayTokens.error, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  const _AttachmentChip({
    required this.label,
    required this.isPdf,
    this.imageUrl,
    required this.onOpen,
    this.onRemove,
  });

  final String label;
  final bool isPdf;
  final String? imageUrl;
  final VoidCallback onOpen;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(ClayTokens.radiusMd),
      child: ClaySurface(
        depth: ClayDepth.raised,
        radius: ClayTokens.radiusMd,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: imageUrl!,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => const _PdfThumb(),
                ),
              )
            else
              const _PdfThumb(),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            if (onRemove != null) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: onRemove,
                child: const Icon(Icons.close_rounded, size: 16, color: ClayTokens.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PendingAttachmentChip extends StatelessWidget {
  const _PendingAttachmentChip({required this.file, this.onRemove});

  final PendingRentalExpenseAttachment file;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final isPdf = file.mimeType == 'application/pdf';
    return ClaySurface(
      depth: ClayDepth.raised,
      radius: ClayTokens.radiusMd,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPdf)
            const _PdfThumb()
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.memory(file.bytes, width: 36, height: 36, fit: BoxFit.cover),
            ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              file.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.cloud_upload_outlined, size: 14, color: ClayTokens.accent),
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: onRemove,
              child: const Icon(Icons.close_rounded, size: 16, color: ClayTokens.muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _PdfThumb extends StatelessWidget {
  const _PdfThumb();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: ClayTokens.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.picture_as_pdf_rounded, color: ClayTokens.error, size: 22),
    );
  }
}

/// Envia anexos pendentes após criar a despesa.
Future<String?> uploadPendingRentalExpenseAttachments({
  required WidgetRef ref,
  required String expenseId,
  required List<PendingRentalExpenseAttachment> pending,
}) async {
  if (pending.isEmpty) return null;
  final companyId = ref.read(currentProfileProvider).value?.companyId;
  if (companyId == null) {
    return 'Não foi possível identificar a empresa para enviar os anexos.';
  }

  final result = await ref.read(financialRepositoryProvider).uploadRentalExpenseAttachments(
        financialRecordId: expenseId,
        companyId: companyId,
        files: pending,
      );

  return result.when(
    success: (_) {
      ref.invalidate(rentalExpenseAttachmentsProvider(expenseId));
      return null;
    },
    failure: (e) => e.message,
  );
}

/// Bottom sheet para anexar NF/recibo em despesas já salvas (ex.: planilha).
Future<void> showRentalExpenseAttachmentsSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String expenseId,
  String? expenseLabel,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: ClayTokens.cardBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(ClayTokens.radiusLg)),
    ),
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (_, scrollController) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(
              'NF / Recibo',
              style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            if (expenseLabel != null && expenseLabel.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                expenseLabel.trim(),
                style: const TextStyle(color: ClayTokens.textSecondary, fontSize: 13),
              ),
            ],
            const SizedBox(height: 16),
            RentalExpenseAttachmentsEditor(
              expenseId: expenseId,
              pending: const [],
              onPendingChanged: (_) {},
            ),
          ],
        ),
      ),
    ),
  );
}
