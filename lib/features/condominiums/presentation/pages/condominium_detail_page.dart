import 'package:cond_manager/core/formatters/brazilian_input_format.dart';
import 'package:cond_manager/core/permissions/app_permissions.dart';
import 'package:cond_manager/core/router/navigation_helpers.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/condominiums/domain/entities/condominium.dart';
import 'package:cond_manager/features/condominiums/presentation/condominium_route_prefix.dart';
import 'package:cond_manager/features/condominiums/presentation/providers/condominium_providers.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class CondominiumDetailPage extends ConsumerWidget {
  const CondominiumDetailPage({
    super.key,
    required this.condominiumId,
    this.routePrefix = CondominiumRoutePrefix.maintenance,
  });

  final String condominiumId;
  final CondominiumRoutePrefix routePrefix;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final condoAsync = ref.watch(condominiumDetailProvider(condominiumId));
    final profile = ref.watch(currentProfileProvider).value;
    final perms = profile.permissions;

    return condoAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 3)),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(e.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ClayButton(
                label: 'Tentar novamente',
                variant: ClayButtonVariant.secondary,
                onPressed: () => ref.invalidate(condominiumDetailProvider(condominiumId)),
              ),
            ],
          ),
        ),
      ),
      data: (condo) {
        final canEdit = perms.canEditCondominium(condominiumId);

        return Stack(
          children: [
            SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 8, 20, canEdit ? 88 : 24),
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
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => context.go(
                        resolveReturnPath(context, fallback: routePrefix.list),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          condo.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        if (condo.legalName != null && condo.legalName!.trim().isNotEmpty)
                          Text(
                            condo.legalName!,
                            style: const TextStyle(
                              color: ClayTokens.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _DetailSection(
                title: 'Dados gerais',
                children: [
                  _InfoRow(label: 'CNPJ', value: _formatCnpj(condo.cnpj)),
                  if (condo.createdAt != null)
                    _InfoRow(
                      label: 'Cadastrado em',
                      value: DateFormat('dd/MM/yyyy').format(condo.createdAt!.toLocal()),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _DetailSection(
                title: 'Endereço do condomínio',
                children: [
                  _InfoRow(label: 'CEP', value: _formatCep(condo.zipCode)),
                  _InfoRow(
                    label: 'Endereço',
                    value: Condominium.formattedAddress(
                      street: condo.street,
                      number: condo.number,
                      complement: condo.complement,
                      neighborhood: condo.neighborhood,
                      city: condo.city,
                      state: condo.state,
                      zipCode: null,
                    ),
                  ),
                ],
              ),
              if (_hasSyndic(condo)) ...[
                const SizedBox(height: 16),
                _DetailSection(
                  title: 'Síndico',
                  children: [
                    _InfoRow(label: 'Nome', value: _orDash(condo.syndicName)),
                    _InfoRow(label: 'Telefone', value: _formatPhone(condo.syndicPhone)),
                    _InfoRow(label: 'E-mail', value: _orDash(condo.syndicEmail)),
                  ],
                ),
              ],
              if (_hasManager(condo)) ...[
                const SizedBox(height: 16),
                _DetailSection(
                  title: 'Empresa administradora',
                  children: [
                    _InfoRow(label: 'Empresa', value: _orDash(condo.managerCompany)),
                    _InfoRow(label: 'CNPJ', value: _formatCnpj(condo.managerCnpj)),
                    _InfoRow(label: 'Contato', value: _orDash(condo.managerContactName)),
                    _InfoRow(label: 'Telefone', value: _formatPhone(condo.managerPhone)),
                    _InfoRow(label: 'E-mail', value: _orDash(condo.managerEmail)),
                    if (_hasManagerAddress(condo))
                      _InfoRow(
                        label: 'Endereço',
                        value: Condominium.formattedAddress(
                          street: condo.managerStreet,
                          number: condo.managerNumber,
                          complement: condo.managerComplement,
                          neighborhood: condo.managerNeighborhood,
                          city: condo.managerCity ?? '—',
                          state: condo.managerState ?? '—',
                          zipCode: condo.managerZipCode,
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              _BlocksSection(condominiumId: condominiumId),
            ],
          ),
        ),
            if (canEdit)
              Positioned(
                right: 20,
                bottom: 20,
                child: ClayButton(
                  label: 'Editar dados',
                  expand: false,
                  icon: Icons.edit_rounded,
                  onPressed: () => context.go(routePrefix.edit(condominiumId)),
                ),
              ),
          ],
        );
      },
    );
  }
}

bool _hasSyndic(Condominium c) =>
    _filled(c.syndicName) || _filled(c.syndicPhone) || _filled(c.syndicEmail);

bool _hasManager(Condominium c) =>
    _filled(c.managerCompany) ||
    _filled(c.managerCnpj) ||
    _filled(c.managerContactName) ||
    _filled(c.managerPhone) ||
    _filled(c.managerEmail) ||
    _hasManagerAddress(c);

bool _hasManagerAddress(Condominium c) =>
    _filled(c.managerStreet) ||
    _filled(c.managerCity) ||
    _filled(c.managerZipCode);

bool _filled(String? v) => v != null && v.trim().isNotEmpty;

String _orDash(String? v) => _filled(v) ? v!.trim() : '—';

String _formatCep(String? v) {
  if (!_filled(v)) return '—';
  final d = BrazilianInputFormat.digitsOnly(v!);
  if (d.length == 8) return '${d.substring(0, 5)}-${d.substring(5)}';
  return v!.trim();
}

String _formatCnpj(String? v) {
  if (!_filled(v)) return '—';
  final d = BrazilianInputFormat.digitsOnly(v!);
  if (d.length != 14) return v!.trim();
  return '${d.substring(0, 2)}.${d.substring(2, 5)}.${d.substring(5, 8)}/'
      '${d.substring(8, 12)}-${d.substring(12)}';
}

String _formatPhone(String? v) {
  if (!_filled(v)) return '—';
  final d = BrazilianInputFormat.digitsOnly(v!);
  if (d.length == 11) {
    return '(${d.substring(0, 2)}) ${d.substring(2, 7)}-${d.substring(7)}';
  }
  if (d.length == 10) {
    return '(${d.substring(0, 2)}) ${d.substring(2, 6)}-${d.substring(6)}';
  }
  return v!.trim();
}

class _BlocksSection extends ConsumerWidget {
  const _BlocksSection({required this.condominiumId});

  final String condominiumId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocksAsync = ref.watch(condominiumBlocksProvider(condominiumId));

    return blocksAsync.when(
      loading: () => const _DetailSection(
        title: 'Blocos / Torres',
        children: [
          Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2))),
        ],
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (blocks) {
        if (blocks.isEmpty) {
          return const _DetailSection(
            title: 'Blocos / Torres',
            children: [
              Text(
                'Nenhum bloco ou torre cadastrado.',
                style: TextStyle(color: ClayTokens.textMuted),
              ),
            ],
          );
        }
        return _DetailSection(
          title: 'Blocos / Torres',
          children: blocks
              .map(
                (b) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(b.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ClaySurface(
      depth: ClayDepth.raised,
      radius: ClayTokens.radiusLg,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: ClayTokens.primary,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: ClayTokens.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
