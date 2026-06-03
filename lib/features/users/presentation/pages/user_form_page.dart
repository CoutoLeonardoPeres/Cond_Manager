import 'package:cond_manager/core/utils/invite_link.dart';
import 'package:cond_manager/core/permissions/app_permissions.dart';
import 'package:cond_manager/core/router/navigation_helpers.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/condominiums/domain/entities/condominium.dart';
import 'package:cond_manager/features/condominiums/presentation/providers/condominium_providers.dart';
import 'package:cond_manager/features/users/domain/entities/organization_user.dart';
import 'package:cond_manager/features/users/presentation/providers/users_providers.dart';
import 'package:cond_manager/shared/domain/enums/organization_role.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class UserFormPage extends ConsumerStatefulWidget {
  const UserFormPage({super.key, this.profileId});

  final String? profileId;

  bool get isEditing => profileId != null;

  @override
  ConsumerState<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends ConsumerState<UserFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  OrganizationRole _role = OrganizationRole.analyst;
  ManagementCompany? _company;
  Set<String> _condominiumIds = {};
  String _status = 'active';
  bool _loading = false;
  String? _error;
  bool _loaded = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _fill(OrganizationUser u) {
    _nameController.text = u.fullName;
    _emailController.text = u.email;
    ClayMaskedField.setPhone(_phoneController, u.phone);
    _role = u.organizationRole ?? OrganizationRole.client;
    _condominiumIds = Set<String>.from(u.condominiumIds);
    _status = u.status;
    _loaded = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_company == null) {
      setState(() => _error = 'Selecione a empresa gestora.');
      return;
    }
    if (_role == OrganizationRole.client && _condominiumIds.isEmpty) {
      setState(() => _error = 'Selecione ao menos um condomínio para o cliente.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final repo = ref.read(usersRepositoryProvider);

    if (widget.isEditing) {
      final result = await repo.updateUser(
        profileId: widget.profileId!,
        fullName: _nameController.text,
        phone: _phoneController.text,
        organizationRole: _role,
        companyId: _company!.id,
        condominiumIds: _condominiumIds.toList(),
        status: _status,
      );
      if (!mounted) return;
      result.when(
        success: (_) {
          ref.invalidate(organizationUsersListProvider);
          ref.invalidate(currentProfileProvider);
          context.go('/users');
        },
        failure: (e) => setState(() {
          _loading = false;
          _error = e.message;
        }),
      );
    } else {
      final result = await repo.inviteUser(
        OrganizationUserSaveInput(
          email: _emailController.text,
          fullName: _nameController.text,
          phone: _phoneController.text,
          organizationRole: _role,
          companyId: _company!.id,
          condominiumIds: _condominiumIds.toList(),
          status: _status,
        ),
      );
      if (!mounted) return;
      result.when(
        success: (invite) {
          ref.invalidate(organizationUsersListProvider);
          if (invite.linkedExistingUser) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Usuário vinculado à empresa.')),
            );
            context.go('/users');
            return;
          }
          if (invite.inviteToken != null) {
            _showInviteLinkDialog(
              buildInviteLink(invite.inviteToken!),
              emailSent: invite.emailSent,
              emailError: invite.emailError,
            );
          } else {
            context.go('/users');
          }
        },
        failure: (e) => setState(() {
          _loading = false;
          _error = e.message;
        }),
      );
    }
  }

  Future<void> _deactivate() async {
    if (_company == null || !widget.isEditing) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desativar usuário?'),
        content: const Text('O usuário perderá acesso ao sistema.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Desativar')),
        ],
      ),
    );
    if (ok != true) return;

    final result = await ref.read(usersRepositoryProvider).deactivateUser(
          widget.profileId!,
          _company!.id,
        );
    if (!mounted) return;
    result.when(
      success: (_) {
        ref.invalidate(organizationUsersListProvider);
        context.go('/users');
      },
      failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      ),
    );
  }

  Future<void> _showInviteLinkDialog(
    String link, {
    required bool emailSent,
    String? emailError,
  }) async {
    final emailStatus = emailSent
        ? 'E-mail enviado para o convidado.'
        : emailError != null
            ? 'Não foi possível enviar o e-mail automaticamente ($emailError). '
                'Copie o link abaixo e envie manualmente.'
            : 'Copie o link abaixo e envie para o convidado.';

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(emailSent ? 'Convite enviado' : 'Convite criado'),
        content: SelectableText('$emailStatus\n\n$link'),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: link));
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Link copiado!')),
                );
              }
            },
            child: const Text('Copiar link'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (mounted) context.go('/users');
            },
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).value;
    final companiesAsync = ref.watch(managementCompaniesProvider);
    final condosAsync = ref.watch(accessibleCondominiumsProvider);

    if (widget.isEditing) {
      ref.watch(organizationUserDetailProvider(widget.profileId!)).whenData((u) {
        if (!_loaded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_loaded) {
              setState(() {
                _fill(u);
                _company = ManagementCompany(
                  id: u.companyId ?? '',
                  legalName: u.companyName ?? '',
                );
              });
            }
          });
        }
      });
    } else {
      companiesAsync.whenData((list) {
        if (_company == null && list.isNotEmpty) {
          ManagementCompany? match;
          if (profile?.companyId != null) {
            for (final c in list) {
              if (c.id == profile!.companyId) match = c;
            }
          }
          _company = match ?? list.first;
        }
      });
    }

    final condos = condosAsync.value ?? const <Condominium>[];

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
                        onPressed: () => context.go(resolveReturnPath(context, fallback: '/users')),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.isEditing ? 'Editar usuário' : 'Novo usuário',
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
                      ? 'Atualize dados, papel e condomínios vinculados.'
                      : 'Convide ou vincule um usuário à empresa gestora.',
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
                  title: 'Papel no sistema',
                  columns: columns,
                  items: [
                    FormGridField(
                      span: columns,
                      child: _RoleInfoCard(role: _role),
                    ),
                    FormGridField(
                      child: ClayDropdownField<OrganizationRole>(
                        label: 'Papel organizacional *',
                        value: _role,
                        items: OrganizationRole.values,
                        itemLabel: (r) => r.label,
                        onChanged: (v) => setState(() => _role = v ?? OrganizationRole.analyst),
                      ),
                    ),
                    if (widget.isEditing)
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
                  title: 'Dados do usuário',
                  columns: columns,
                  items: [
                    FormGridField(
                      child: ClayTextField(
                        controller: _nameController,
                        label: 'Nome completo *',
                        validator: (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                      ),
                    ),
                    FormGridField(
                      child: ClayTextField(
                        controller: _emailController,
                        label: 'E-mail *',
                        readOnly: widget.isEditing,
                        validator: (v) => v == null || !v.contains('@') ? 'E-mail inválido' : null,
                      ),
                    ),
                    FormGridField(
                      child: ClayMaskedField.phone(
                        controller: _phoneController,
                        label: 'Telefone',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FormGridSection(
                  title: 'Empresa gestora',
                  columns: columns,
                  items: [
                    FormGridField(
                      span: columns >= 2 ? 2 : 1,
                      child: companiesAsync.when(
                        data: (list) => ClayDropdownField<ManagementCompany>(
                          label: 'Empresa gestora *',
                          value: _company,
                          items: list,
                          itemLabel: (c) => c.displayName,
                          onChanged: widget.isEditing ? null : (v) => setState(() => _company = v),
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
                if (_role == OrganizationRole.client) ...[
                  const SizedBox(height: 16),
                  FormGridSection(
                    title: 'Condomínios com acesso',
                    columns: 1,
                    items: [
                      FormGridField(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Visualizar e abrir chamados apenas nestes condomínios',
                              style: TextStyle(
                                fontSize: 13,
                                color: ClayTokens.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: condos.map((c) {
                                final selected = _condominiumIds.contains(c.id);
                                return FilterChip(
                                  label: Text(c.name),
                                  selected: selected,
                                  onSelected: (v) => setState(() {
                                    if (v) {
                                      _condominiumIds.add(c.id);
                                    } else {
                                      _condominiumIds.remove(c.id);
                                    }
                                  }),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.end,
                    children: [
                      if (widget.isEditing && profile?.permissions.canDelete == true)
                        SizedBox(
                          width: columns >= 3 ? 200 : double.infinity,
                          child: ClayButton(
                            label: 'Desativar usuário',
                            variant: ClayButtonVariant.secondary,
                            icon: Icons.block_rounded,
                            onPressed: _deactivate,
                          ),
                        ),
                      SizedBox(
                        width: columns >= 3 ? 220 : double.infinity,
                        child: ClayButton(
                          label: widget.isEditing ? 'Salvar' : 'Convidar / vincular',
                          icon: Icons.save_rounded,
                          isLoading: _loading,
                          onPressed: _loading ? null : _submit,
                        ),
                      ),
                    ],
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

class _RoleInfoCard extends StatelessWidget {
  const _RoleInfoCard({required this.role});

  final OrganizationRole role;

  @override
  Widget build(BuildContext context) {
    final text = switch (role) {
      OrganizationRole.manager =>
        'Acesso total da empresa e de todos os condomínios vinculados. Pode cadastrar, editar e excluir.',
      OrganizationRole.analyst =>
        'Pode registrar tudo, editar dados da empresa, mas não pode excluir.',
      OrganizationRole.fieldTeam =>
        'Acesso apenas a chamados e ordens de serviço (app mobile de campo).',
      OrganizationRole.client =>
        'Acesso ao portal do condomínio: abrir chamados e acompanhar apenas do(s) condomínio(s) vinculado(s).',
    };

    return ClaySurface(
      depth: ClayDepth.pressed,
      padding: const EdgeInsets.all(12),
      child: Text(text, style: const TextStyle(fontSize: 13, color: ClayTokens.textSecondary, height: 1.4)),
    );
  }
}
