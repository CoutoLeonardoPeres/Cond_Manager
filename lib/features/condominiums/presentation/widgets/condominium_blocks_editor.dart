import 'package:cond_manager/features/condominiums/domain/entities/condominium_block.dart';
import 'package:cond_manager/features/condominiums/presentation/providers/condominium_providers.dart';
import 'package:cond_manager/features/tickets/presentation/providers/ticket_providers.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Editor de blocos/torres do condomínio (persistência imediata quando [condominiumId] existe).
class CondominiumBlocksEditor extends ConsumerStatefulWidget {
  const CondominiumBlocksEditor({
    super.key,
    required this.condominiumId,
    this.pendingBlocks,
    this.onPendingChanged,
    this.columns = 1,
  });

  final String? condominiumId;
  final List<String>? pendingBlocks;
  final ValueChanged<List<String>>? onPendingChanged;
  final int columns;

  bool get isDeferred => condominiumId == null;

  @override
  ConsumerState<CondominiumBlocksEditor> createState() => _CondominiumBlocksEditorState();
}

class _CondominiumBlocksEditorState extends ConsumerState<CondominiumBlocksEditor> {
  final _newNameController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _newNameController.dispose();
    super.dispose();
  }

  Future<void> _addBlock() async {
    final name = _newNameController.text.trim();
    if (name.isEmpty) return;

    if (widget.isDeferred) {
      final next = [...?widget.pendingBlocks, name];
      widget.onPendingChanged?.call(next);
      _newNameController.clear();
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final repo = ref.read(condominiumBlockRepositoryProvider);
    final blocks = ref.read(condominiumBlocksProvider(widget.condominiumId!)).valueOrNull ?? const [];
    final result = await repo.create(
      widget.condominiumId!,
      CondominiumBlockInput(name: name, sortOrder: blocks.length),
    );

    if (!mounted) return;

    result.when(
      success: (_) {
        ref.invalidate(condominiumBlocksProvider(widget.condominiumId!));
        ref.invalidate(ticketUnitsProvider);
        _newNameController.clear();
        setState(() => _saving = false);
      },
      failure: (e) => setState(() {
        _saving = false;
        _error = e.message;
      }),
    );
  }

  Future<void> _renameBlock(CondominiumBlock block, String name) async {
    if (widget.isDeferred || name.trim().isEmpty || name.trim() == block.name) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final result = await ref.read(condominiumBlockRepositoryProvider).update(
          block.id,
          CondominiumBlockInput(name: name.trim(), sortOrder: block.sortOrder),
        );

    if (!mounted) return;

    result.when(
      success: (_) {
        ref.invalidate(condominiumBlocksProvider(widget.condominiumId!));
        ref.invalidate(ticketUnitsProvider);
        setState(() => _saving = false);
      },
      failure: (e) => setState(() {
        _saving = false;
        _error = e.message;
      }),
    );
  }

  Future<void> _removeBlock(CondominiumBlock block) async {
    if (widget.isDeferred) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover bloco/torre?'),
        content: Text('Remover "${block.name}"? Unidades vinculadas perderão essa referência.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remover', style: TextStyle(color: ClayTokens.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final result = await ref.read(condominiumBlockRepositoryProvider).delete(block.id);

    if (!mounted) return;

    result.when(
      success: (_) {
        ref.invalidate(condominiumBlocksProvider(widget.condominiumId!));
        ref.invalidate(ticketUnitsProvider);
        setState(() => _saving = false);
      },
      failure: (e) => setState(() {
        _saving = false;
        _error = e.message;
      }),
    );
  }

  void _removePending(int index) {
    final next = [...?widget.pendingBlocks]..removeAt(index);
    widget.onPendingChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isDeferred) {
      return _buildShell(
        context,
        children: [
          if (widget.pendingBlocks != null && widget.pendingBlocks!.isNotEmpty)
            ...widget.pendingBlocks!.asMap().entries.map(
                  (e) => _PendingRow(
                    name: e.value,
                    onRemove: _saving ? null : () => _removePending(e.key),
                  ),
                ),
          _AddRow(
            controller: _newNameController,
            saving: _saving,
            onAdd: _addBlock,
          ),
        ],
      );
    }

    final blocksAsync = ref.watch(condominiumBlocksProvider(widget.condominiumId!));

    return blocksAsync.when(
      loading: () => _buildShell(
        context,
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ],
      ),
      error: (e, _) => _buildShell(
        context,
        children: [
          Text(e.toString(), style: const TextStyle(color: ClayTokens.error, fontSize: 13)),
        ],
      ),
      data: (blocks) => _buildShell(
        context,
        children: [
          if (blocks.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Nenhum bloco ou torre cadastrado. Adicione abaixo.',
                style: TextStyle(color: ClayTokens.textMuted, fontSize: 13),
              ),
            ),
          ...blocks.map(
            (b) => _BlockRow(
              block: b,
              enabled: !_saving,
              onRename: (name) => _renameBlock(b, name),
              onRemove: () => _removeBlock(b),
            ),
          ),
          _AddRow(
            controller: _newNameController,
            saving: _saving,
            onAdd: _addBlock,
          ),
        ],
      ),
    );
  }

  Widget _buildShell(BuildContext context, {required List<Widget> children}) {
    return FormGridSection(
      title: 'Blocos / Torres',
      columns: widget.columns,
      items: [
        FormGridField(
          span: widget.columns,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Cadastre os blocos ou torres do condomínio. As unidades poderão ser vinculadas a eles.',
                style: TextStyle(color: ClayTokens.textSecondary, fontSize: 13, height: 1.35),
              ),
              const SizedBox(height: 12),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: ClayTokens.error, fontSize: 13)),
                const SizedBox(height: 8),
              ],
              ...children,
            ],
          ),
        ),
      ],
    );
  }
}

class _BlockRow extends StatefulWidget {
  const _BlockRow({
    required this.block,
    required this.enabled,
    required this.onRename,
    required this.onRemove,
  });

  final CondominiumBlock block;
  final bool enabled;
  final ValueChanged<String> onRename;
  final VoidCallback onRemove;

  @override
  State<_BlockRow> createState() => _BlockRowState();
}

class _BlockRowState extends State<_BlockRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.block.name);
  }

  @override
  void didUpdateWidget(covariant _BlockRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.block.name != _controller.text) {
      _controller.text = widget.block.name;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() => widget.onRename(_controller.text);

  @override
  Widget build(BuildContext context) {
    final dirty = _controller.text.trim() != widget.block.name;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: ClayTextField(
              controller: _controller,
              label: 'Nome',
              readOnly: !widget.enabled,
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (dirty)
            IconButton(
              tooltip: 'Salvar nome',
              onPressed: widget.enabled ? _save : null,
              icon: const Icon(Icons.check_rounded, color: ClayTokens.accent),
            ),
          IconButton(
            tooltip: 'Remover',
            onPressed: widget.enabled ? widget.onRemove : null,
            icon: const Icon(Icons.delete_outline_rounded, color: ClayTokens.error),
          ),
        ],
      ),
    );
  }
}

class _PendingRow extends StatelessWidget {
  const _PendingRow({required this.name, required this.onRemove});

  final String name;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClaySurface(
        depth: ClayDepth.pressed,
        radius: ClayTokens.radiusSm,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
            IconButton(
              tooltip: 'Remover',
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddRow extends StatelessWidget {
  const _AddRow({
    required this.controller,
    required this.saving,
    required this.onAdd,
  });

  final TextEditingController controller;
  final bool saving;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: ClayTextField(
            controller: controller,
            label: 'Novo bloco ou torre',
            readOnly: saving,
          ),
        ),
        const SizedBox(width: 8),
        ClayButton(
          label: 'Adicionar',
          icon: Icons.add_rounded,
          expand: false,
          isLoading: saving,
          onPressed: saving ? null : onAdd,
        ),
      ],
    );
  }
}
