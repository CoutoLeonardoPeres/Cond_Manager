import 'package:cond_manager/features/preventive/domain/entities/preventive_plan.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';

class PreventiveChecklistEditor extends StatefulWidget {
  const PreventiveChecklistEditor({
    super.key,
    required this.items,
    required this.onChanged,
  });

  final List<PreventiveChecklistItemInput> items;
  final ValueChanged<List<PreventiveChecklistItemInput>> onChanged;

  @override
  State<PreventiveChecklistEditor> createState() => _PreventiveChecklistEditorState();
}

class _PreventiveChecklistEditorState extends State<PreventiveChecklistEditor> {
  final List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
    _syncControllers(widget.items);
  }

  @override
  void didUpdateWidget(PreventiveChecklistEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      _syncControllers(widget.items);
    }
  }

  void _syncControllers(List<PreventiveChecklistItemInput> items) {
    while (_controllers.length < items.length) {
      final i = _controllers.length;
      _controllers.add(TextEditingController(text: items[i].description));
    }
    while (_controllers.length > items.length) {
      _controllers.removeLast().dispose();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      List.generate(
        _controllers.length,
        (i) => PreventiveChecklistItemInput(
          description: _controllers[i].text,
          sortOrder: i,
        ),
      ),
    );
  }

  void _add() {
    widget.onChanged([
      ...widget.items,
      const PreventiveChecklistItemInput(description: ''),
    ]);
    setState(() {
      _controllers.add(TextEditingController());
    });
  }

  void _remove(int index) {
    final next = [...widget.items]..removeAt(index);
    widget.onChanged(next);
    setState(() {
      _controllers[index].dispose();
      _controllers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Checklist da preventiva',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < _controllers.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: ClayTextField(
                    controller: _controllers[i],
                    label: 'Item ${i + 1}',
                    hint: 'Ex.: Verificar nível de óleo',
                    onChanged: (_) => _emit(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: ClayTokens.error),
                  onPressed: () => _remove(i),
                ),
              ],
            ),
          ),
        TextButton.icon(
          onPressed: _add,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Adicionar item'),
        ),
      ],
    );
  }
}
