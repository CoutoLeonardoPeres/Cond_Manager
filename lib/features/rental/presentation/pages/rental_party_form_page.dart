import 'package:cond_manager/core/router/navigation_helpers.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_inputs.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_party.dart';
import 'package:cond_manager/features/rental/presentation/providers/rental_providers.dart';
import 'package:cond_manager/shared/domain/enums/rental_party_category.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RentalPartyFormPage extends ConsumerStatefulWidget {
  const RentalPartyFormPage({super.key, this.partyId});

  final String? partyId;

  bool get isEditing => partyId != null;

  @override
  ConsumerState<RentalPartyFormPage> createState() => _RentalPartyFormPageState();
}

class _RentalPartyFormPageState extends ConsumerState<RentalPartyFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _documentController = TextEditingController();
  final _notesController = TextEditingController();

  String _status = 'active';
  RentalPartyCategory _category = RentalPartyCategory.tenant;
  bool _loading = false;
  String? _error;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyInitialCategoryFromRoute());
  }

  void _applyInitialCategoryFromRoute() {
    if (widget.isEditing || !mounted) return;
    final categoryParam = GoRouterState.of(context).uri.queryParameters['category'];
    if (categoryParam == null) return;
    setState(() => _category = RentalPartyCategory.fromValue(categoryParam));
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _documentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _fill(RentalParty p) {
    _fullNameController.text = p.fullName;
    _emailController.text = p.email ?? '';
    ClayMaskedField.setPhone(_phoneController, p.phone);
    ClayMaskedField.setCpf(_documentController, p.documentNumber);
    _notesController.text = p.notes ?? '';
    _status = p.status;
    _category = p.category;
    _loaded = true;
  }

  RentalPartyInput _buildInput(String companyId) => RentalPartyInput(
        companyId: companyId,
        fullName: _fullNameController.text.trim(),
        category: _category,
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        documentNumber:
            _documentController.text.trim().isEmpty ? null : _documentController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        status: _status,
      );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final companyId = ref.read(currentProfileProvider).value?.companyId;
    if (companyId == null) {
      setState(() => _error = 'Empresa não identificada.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final repo = ref.read(rentalRepositoryProvider);
    final input = _buildInput(companyId);

    if (widget.isEditing) {
      final result = await repo.updateParty(widget.partyId!, input);
      if (!mounted) return;
      result.when(
        success: (_) {
          ref.invalidate(rentalPartiesListProvider);
          ref.invalidate(rentalPartyDetailProvider(widget.partyId!));
          context.go(resolveReturnPath(context, fallback: '/rental/parties'));
        },
        failure: (e) => setState(() {
          _loading = false;
          _error = e.message;
        }),
      );
    } else {
      final result = await repo.createParty(input);
      if (!mounted) return;
      result.when(
        success: (_) {
          ref.invalidate(rentalPartiesListProvider);
          context.go(resolveReturnPath(context, fallback: '/rental/parties'));
        },
        failure: (e) => setState(() {
          _loading = false;
          _error = e.message;
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEditing) {
      ref.watch(rentalPartyDetailProvider(widget.partyId!)).whenData((p) {
        if (!_loaded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_loaded) setState(() => _fill(p));
          });
        }
      });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : formColumnsForWidth(constraints.maxWidth);

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    ClaySurface(
                      depth: ClayDepth.raised,
                      radius: ClayTokens.radiusFull,
                      padding: EdgeInsets.zero,
                      child: IconButton(
                        onPressed: () =>
                            context.go(resolveReturnPath(context, fallback: '/rental/parties')),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.isEditing ? 'Editar pessoa' : 'Nova pessoa',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isEditing
                      ? 'Atualize dados de proprietários, inquilinos e hóspedes.'
                      : 'Cadastre uma pessoa para vincular a imóveis, contratos e reservas.',
                  style: const TextStyle(color: ClayTokens.textSecondary, fontSize: 13),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  ClaySurface(
                    depth: ClayDepth.pressed,
                    color: ClayTokens.error.withValues(alpha: 0.1),
                    padding: const EdgeInsets.all(14),
                    child: Text(_error!, style: const TextStyle(color: ClayTokens.error)),
                  ),
                ],
                const SizedBox(height: 20),
                FormGridSection(
                  title: 'Dados pessoais',
                  columns: columns,
                  items: [
                    FormGridField(
                      child: ClayTextField(
                        controller: _fullNameController,
                        label: 'Nome completo *',
                        validator: (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                      ),
                    ),
                    FormGridField(
                      child: ClayTextField(
                        controller: _emailController,
                        label: 'E-mail',
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    FormGridField(
                      child: ClayMaskedField.phone(
                        controller: _phoneController,
                        label: 'Telefone',
                      ),
                    ),
                    FormGridField(
                      child: ClayMaskedField.cpf(
                        controller: _documentController,
                        label: 'CPF',
                      ),
                    ),
                    FormGridField(
                      child: ClayDropdownField<RentalPartyCategory>(
                        label: 'Categoria *',
                        value: _category,
                        items: RentalPartyCategory.values,
                        itemLabel: (c) => c.label,
                        onChanged: (v) {
                          if (v != null) setState(() => _category = v);
                        },
                      ),
                    ),
                    FormGridField(
                      child: ClayDropdownField<String>(
                        label: 'Status',
                        value: _status,
                        items: const ['active', 'inactive'],
                        itemLabel: (s) => s == 'active' ? 'Ativo' : 'Inativo',
                        onChanged: (v) => setState(() => _status = v ?? 'active'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FormGridSection(
                  title: 'Observações',
                  columns: columns,
                  items: [
                    FormGridField(
                      span: columns,
                      child: ClayTextField(
                        controller: _notesController,
                        label: 'Observações',
                        maxLines: 3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: columns >= 3 ? 220 : double.infinity,
                    child: ClayButton(
                      label: widget.isEditing ? 'Salvar' : 'Cadastrar',
                      icon: Icons.save_rounded,
                      isLoading: _loading,
                      onPressed: _loading ? null : _submit,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
