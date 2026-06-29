import 'package:cond_manager/core/formatters/brazilian_input_format.dart';
import 'package:cond_manager/core/services/viacep_service.dart';
import 'package:cond_manager/features/rental/domain/entities/tenant_intake_form_models.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DynamicTenantIntakeForm extends StatefulWidget {
  const DynamicTenantIntakeForm({
    super.key,
    required this.definition,
    required this.onSubmit,
    this.initialValues = const {},
    this.loading = false,
    this.showSubmitButton = true,
    this.relaxRequiredValidation = false,
    this.onIdentityLookup,
  });

  final TenantIntakeFormDefinition definition;
  final Future<void> Function(Map<String, String> values) onSubmit;
  final Map<String, String> initialValues;
  final bool loading;
  final bool showSubmitButton;
  final bool relaxRequiredValidation;
  /// Disparado ao completar CPF, telefone ou WhatsApp (busca de pessoa existente).
  final void Function()? onIdentityLookup;

  @override
  State<DynamicTenantIntakeForm> createState() => DynamicTenantIntakeFormState();
}

class DynamicTenantIntakeFormState extends State<DynamicTenantIntakeForm> {
  static const _identityLookupFields = {
    'LOCATARIO_CPF',
    'LOCATARIO_TELEFONE',
    'LOCATARIO_WHATSAPP',
  };

  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  final _values = <String, String>{};
  bool _cepLoading = false;

  @override
  void initState() {
    super.initState();
    for (final section in widget.definition.sections) {
      for (final field in section.fields) {
        final initial = widget.initialValues[field.name] ?? field.defaultValue ?? '';
        _values[field.name] = initial;
        _controllers[field.name] = TextEditingController(text: initial);
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, String> get _currentValues {
    for (final entry in _controllers.entries) {
      _values[entry.key] = entry.value.text;
    }
    return Map<String, String>.from(_values);
  }

  Future<void> _lookupCep(String cep) async {
    final digits = BrazilianInputFormat.digitsOnly(cep);
    if (digits.length != 8) return;
    setState(() => _cepLoading = true);
    final result = await ViaCepService.lookup(digits);
    if (!mounted) return;
    setState(() => _cepLoading = false);
    if (result == null) return;
    if (result.street != null) _setField('LOCATARIO_LOGRADOURO', result.street!);
    if (result.complement != null && result.complement!.isNotEmpty) {
      _setField('LOCATARIO_COMPLEMENTO', result.complement!);
    }
    if (result.neighborhood != null) _setField('LOCATARIO_BAIRRO', result.neighborhood!);
    if (result.city != null) _setField('LOCATARIO_CIDADE', result.city!);
    if (result.state != null) _setField('LOCATARIO_ESTADO', result.state!);
  }

  void _setField(String name, String value) {
    _values[name] = value;
    _controllers[name]?.text = value;
    setState(() {});
  }

  Future<void> _pickDate(String fieldName) async {
    final current = _controllers[fieldName]?.text ?? '';
    DateTime initial = DateTime.now();
    if (current.isNotEmpty) {
      try {
        final parts = current.split('/');
        if (parts.length == 3) {
          initial = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      } catch (_) {}
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      final formatted = DateFormat('dd/MM/yyyy').format(picked);
      _controllers[fieldName]?.text = formatted;
      _values[fieldName] = formatted;
      setState(() {});
    }
  }

  Future<void> _pickTime(String fieldName) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      _controllers[fieldName]?.text = formatted;
      _values[fieldName] = formatted;
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant DynamicTenantIntakeForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValues != widget.initialValues) {
      applyValues(widget.initialValues);
    }
  }

  /// Aplica valores nos campos (uso externo após busca por CPF/telefone).
  void applyValues(Map<String, String> values) {
    _applyInitialValues(values);
    if (mounted) setState(() {});
  }

  void _applyInitialValues(Map<String, String> initialValues) {
    for (final section in widget.definition.sections) {
      for (final field in section.fields) {
        final initial = initialValues[field.name] ?? field.defaultValue ?? '';
        _values[field.name] = initial;
        _controllers[field.name]?.text = initial;
      }
    }
  }

  void _maybeTriggerIdentityLookup(String fieldName) {
    if (!_identityLookupFields.contains(fieldName)) return;
    widget.onIdentityLookup?.call();
  }

  /// Valida e retorna os valores para uso em formulários embutidos (cadastro interno).
  bool validateForSave() {
    if (!_formKey.currentState!.validate()) return false;
    final values = _currentValues;
    if (widget.relaxRequiredValidation) {
      if ((values['LOCATARIO_NOME_COMPLETO'] ?? '').trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe o nome completo do locatário/inquilino.')),
        );
        return false;
      }
      return true;
    }
    for (final section in widget.definition.sections) {
      for (final field in section.fields) {
        if (!field.isVisible(values)) continue;
        if (field.required && (values[field.name]?.trim().isEmpty ?? true)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Preencha: ${field.label}')),
          );
          return false;
        }
      }
    }
    return true;
  }

  Map<String, String> collectValues() => _currentValues;

  int _fieldSpan(TenantIntakeFormField field, int columns) {
    if (field.type == 'textarea') return columns;
    const wideFields = {
      'LOCATARIO_NOME_COMPLETO',
      'IMOVEL_DESEJADO',
      'LOCATARIO_LOGRADOURO',
      'LOCATARIO_ENDERECO_TRABALHO',
      'LOCATARIO_EMPRESA_TRABALHO',
    };
    if (wideFields.contains(field.name)) {
      return columns >= 2 ? 2 : 1;
    }
    return 1;
  }

  List<FormGridField> _sectionGridItems(TenantIntakeFormSection section, int columns) {
    final values = _currentValues;
    final items = <FormGridField>[];
    for (final field in section.fields) {
      if (!field.isVisible(values)) continue;
      items.add(
        FormGridField(
          span: _fieldSpan(field, columns),
          child: _buildFieldContent(field),
        ),
      );
    }
    return items;
  }

  Future<void> _handleSubmit() async {
    if (!validateForSave()) return;
    await widget.onSubmit(_currentValues);
  }

  Widget _buildFieldContent(TenantIntakeFormField field) {
    final controller = _controllers[field.name]!;

    switch (field.type) {
      case 'select':
        final values = _currentValues;
        final selected = values[field.name];
        final valid = field.options.any((o) => o.value == selected) ? selected : null;
        return ClayDropdownField<String>(
          label: field.required ? '${field.label} *' : field.label,
          value: valid,
          items: field.options.map((o) => o.value).toList(),
          itemLabel: (v) => field.options.firstWhere((o) => o.value == v).label,
          onChanged: (v) => setState(() {
            _values[field.name] = v ?? '';
            controller.text = v ?? '';
          }),
        );
      case 'textarea':
        return ClayTextField(
          controller: controller,
          label: field.required ? '${field.label} *' : field.label,
          maxLines: 3,
          onChanged: (v) => _values[field.name] = v,
        );
      case 'date':
        return InkWell(
          onTap: () => _pickDate(field.name),
          child: IgnorePointer(
            child: ClayTextField(
              controller: controller,
              label: field.required ? '${field.label} *' : field.label,
              readOnly: true,
              suffixIcon: const Icon(Icons.calendar_today_rounded, size: 20),
            ),
          ),
        );
      case 'time':
        return InkWell(
          onTap: () => _pickTime(field.name),
          child: IgnorePointer(
            child: ClayTextField(
              controller: controller,
              label: field.required ? '${field.label} *' : field.label,
              readOnly: true,
              suffixIcon: const Icon(Icons.schedule_rounded, size: 20),
            ),
          ),
        );
      case 'email':
        return ClayTextField(
          controller: controller,
          label: field.required ? '${field.label} *' : field.label,
          keyboardType: TextInputType.emailAddress,
          onChanged: (v) => _values[field.name] = v,
        );
      case 'tel':
        return ClayMaskedField.phone(
          controller: controller,
          label: field.required ? '${field.label} *' : field.label,
          onComplete: () async {
            _values[field.name] = controller.text;
            _maybeTriggerIdentityLookup(field.name);
          },
        );
      case 'currency':
      case 'number':
        return ClayTextField(
          controller: controller,
          label: field.required ? '${field.label} *' : field.label,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) => _values[field.name] = v,
          validator: field.min != null
              ? (v) {
                  final n = num.tryParse((v ?? '').replaceAll(',', '.'));
                  if (v != null && v.isNotEmpty && n != null && n < field.min!) {
                    return 'Mínimo: ${field.min}';
                  }
                  return null;
                }
              : null,
        );
      default:
        if (field.mask == '000.000.000-00') {
          return ClayMaskedField.cpf(
            controller: controller,
            label: field.required ? '${field.label} *' : field.label,
            onComplete: () async {
              _values[field.name] = controller.text;
              _maybeTriggerIdentityLookup(field.name);
            },
          );
        }
        if (field.mask == '00000-000') {
          return ClayMaskedField.cep(
            controller: controller,
            label: field.required ? '${field.label} *' : field.label,
            suffixIcon: _cepLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
            onComplete: () async {
              _values[field.name] = controller.text;
              await _lookupCep(controller.text);
            },
          );
        }
        return ClayTextField(
          controller: controller,
          label: field.required ? '${field.label} *' : field.label,
          hint: field.placeholder,
          onChanged: (v) => _values[field.name] = v,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : formColumnsForWidth(constraints.maxWidth);

        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final section in widget.definition.sections) ...[
                ClaySurface(
                  depth: ClayDepth.raised,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        section.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: ClayTokens.accent,
                            ),
                      ),
                      if (section.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          section.description!,
                          style: const TextStyle(color: ClayTokens.textSecondary, fontSize: 13),
                        ),
                      ],
                      const SizedBox(height: 14),
                      FormGrid(columns: columns, items: _sectionGridItems(section, columns)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              if (widget.showSubmitButton)
                ClayButton(
                  label: widget.definition.submitButtonLabel,
                  icon: Icons.send_rounded,
                  isLoading: widget.loading,
                  onPressed: widget.loading ? null : _handleSubmit,
                ),
            ],
          ),
        );
      },
    );
  }
}

Map<String, dynamic> tenantIntakeValuesToJsonMap(Map<String, String> values) =>
    Map<String, dynamic>.from(values);

String buildTenantIntakeWhatsappMessage({
  required TenantIntakeFormDefinition definition,
  required String link,
  String? tenantName,
}) {
  final template = (tenantName != null && tenantName.trim().isNotEmpty)
      ? definition.whatsappMessageTemplate
      : definition.whatsappFallbackMessage;
  return template
      .replaceAll('{{FORM_LINK}}', link)
      .replaceAll('{{LOCATARIO_NOME_COMPLETO}}', tenantName?.trim() ?? '');
}
