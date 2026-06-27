import 'package:cached_network_image/cached_network_image.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_property_photo.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

/// Galeria de fotos do imóvel (sem limite de quantidade).
class RentalPropertyPhotosEditor extends StatefulWidget {
  const RentalPropertyPhotosEditor({
    super.key,
    required this.photos,
    required this.onChanged,
    required this.enabled,
  });

  final List<RentalPropertyPhotoDraft> photos;
  final ValueChanged<List<RentalPropertyPhotoDraft>> onChanged;
  final bool enabled;

  @override
  State<RentalPropertyPhotosEditor> createState() => _RentalPropertyPhotosEditorState();
}

class _RentalPropertyPhotosEditorState extends State<RentalPropertyPhotosEditor> {
  final _picker = ImagePicker();
  bool _picking = false;

  Future<void> _pickImages() async {
    if (!widget.enabled || _picking) return;
    setState(() => _picking = true);
    try {
      final images = await _picker.pickMultiImage(imageQuality: 85);
      if (images.isEmpty) return;

      const uuid = Uuid();
      final added = <RentalPropertyPhotoDraft>[];
      for (final file in images) {
        final bytes = await file.readAsBytes();
        added.add(
          RentalPropertyPhotoDraft.pending(
            localKey: uuid.v4(),
            pending: PendingRentalPropertyPhoto(
              bytes: bytes,
              fileName: file.name,
              mimeType: _mimeFromName(file.name),
            ),
          ),
        );
      }
      widget.onChanged([...widget.photos, ...added]);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  String _mimeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.heif')) return 'image/heif';
    return 'image/jpeg';
  }

  void _removeAt(int index) {
    final next = [...widget.photos]..removeAt(index);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.photos.length;
    final crossAxisCount = MediaQuery.sizeOf(context).width >= 720 ? 4 : 3;

    return FormGridSection(
      title: 'Fotos do imóvel',
      columns: 1,
      items: [
        FormGridField(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                count == 0
                    ? 'Adicione quantas fotos quiser para divulgar o imóvel.'
                    : '$count foto${count == 1 ? '' : 's'} selecionada${count == 1 ? '' : 's'}',
                style: const TextStyle(color: ClayTokens.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemCount: count + 1,
                itemBuilder: (context, index) {
                  if (index == count) {
                    return _AddPhotoTile(
                      loading: _picking,
                      enabled: widget.enabled,
                      onTap: _pickImages,
                    );
                  }
                  final draft = widget.photos[index];
                  return _PhotoTile(
                    draft: draft,
                    enabled: widget.enabled,
                    onRemove: () => _removeAt(index),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({
    required this.loading,
    required this.enabled,
    required this.onTap,
  });

  final bool loading;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled && !loading ? onTap : null,
        borderRadius: BorderRadius.circular(ClayTokens.radiusMd),
        child: ClaySurface(
          depth: ClayDepth.pressed,
          radius: ClayTokens.radiusMd,
          padding: EdgeInsets.zero,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_a_photo_rounded,
                        size: 32,
                        color: enabled ? ClayTokens.accent : ClayTokens.muted,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Adicionar',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: enabled ? ClayTokens.accent : ClayTokens.muted,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.draft,
    required this.enabled,
    required this.onRemove,
  });

  final RentalPropertyPhotoDraft draft;
  final bool enabled;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(ClayTokens.radiusMd),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (draft.isPending)
            Image.memory(
              draft.pending!.bytes,
              fit: BoxFit.cover,
            )
          else
            CachedNetworkImage(
              imageUrl: draft.photo!.fileUrl,
              fit: BoxFit.cover,
              placeholder: (_, _) => const ColoredBox(
                color: ClayTokens.surfacePressed,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              errorWidget: (_, _, _) => const ColoredBox(
                color: ClayTokens.surfacePressed,
                child: Icon(Icons.broken_image_outlined, color: ClayTokens.muted),
              ),
            ),
          if (enabled)
            Positioned(
              top: 6,
              right: 6,
              child: Material(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(ClayTokens.radiusFull),
                child: InkWell(
                  onTap: onRemove,
                  borderRadius: BorderRadius.circular(ClayTokens.radiusFull),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Separa rascunhos em pendentes, existentes e IDs removidos.
class RentalPropertyPhotosChanges {
  const RentalPropertyPhotosChanges({
    required this.pendingUploads,
    required this.deletedPhotoIds,
    required this.existingCount,
  });

  final List<PendingRentalPropertyPhoto> pendingUploads;
  final List<String> deletedPhotoIds;
  final int existingCount;

  static RentalPropertyPhotosChanges fromDrafts({
    required List<RentalPropertyPhotoDraft> current,
    required List<RentalPropertyPhotoDraft> initial,
  }) {
    final pendingUploads = current
        .where((d) => d.isPending)
        .map((d) => d.pending!)
        .toList();

    final currentExistingIds = current
        .where((d) => !d.isPending)
        .map((d) => d.photo!.id)
        .toSet();

    final deletedPhotoIds = initial
        .where((d) => !d.isPending)
        .map((d) => d.photo!.id)
        .where((id) => !currentExistingIds.contains(id))
        .toList();

    final existingCount = current.where((d) => !d.isPending).length;

    return RentalPropertyPhotosChanges(
      pendingUploads: pendingUploads,
      deletedPhotoIds: deletedPhotoIds,
      existingCount: existingCount,
    );
  }
}
