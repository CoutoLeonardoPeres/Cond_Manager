import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/materials/presentation/providers/material_providers.dart';
import 'package:cond_manager/features/materials/presentation/utils/material_permissions.dart';
import 'package:cond_manager/features/materials/presentation/widgets/material_pricing_preview.dart';
import 'package:cond_manager/features/materials/presentation/widgets/stock_movement_sheet.dart';
import 'package:cond_manager/shared/domain/enums/stock_movement_type.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class MaterialDetailPage extends ConsumerWidget {
  const MaterialDetailPage({super.key, required this.materialId});

  final String materialId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materialAsync = ref.watch(materialDetailProvider(materialId));
    final movementsAsync = ref.watch(materialStockMovementsProvider(materialId));
    final profile = ref.watch(currentProfileProvider).value;
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return materialAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 3)),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (m) {
        final canManage = profile != null && profile.canManageMaterialsIn(m.condominiumId);

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
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
                      onPressed: () => context.go('/materials'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      m.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  if (canManage)
                    IconButton(
                      onPressed: () => context.go('/materials/$materialId/edit'),
                      icon: const Icon(Icons.edit_rounded),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${m.itemType.label} · ${m.status.label}${m.condominiumName != null ? ' · ${m.condominiumName}' : ''}',
                style: const TextStyle(color: ClayTokens.textSecondary),
              ),
              if (m.isLowStock) ...[
                const SizedBox(height: 12),
                ClaySurface(
                  depth: ClayDepth.pressed,
                  color: ClayTokens.warning.withValues(alpha: 0.12),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: ClayTokens.warning),
                      const SizedBox(width: 8),
                      Text(
                        'Estoque baixo: ${m.currentStock} ${m.unitOfMeasureLabel} (mín. ${m.minStock})',
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              MaterialPricingPreview(
                unitCost: m.unitCost,
                purchaseTaxPercent: m.purchaseTaxPercent,
                resaleUnitPrice: m.resaleUnitPrice,
                resaleTaxPercent: m.resaleTaxPercent,
              ),
              const SizedBox(height: 16),
              _InfoSection(
                title: 'Detalhes',
                rows: [
                  _InfoRow(
                    'Fornecedores',
                    m.supplierLinks.isNotEmpty
                        ? m.supplierLinks
                            .map((l) => l.isPrimary ? '${l.displayName} (principal)' : l.displayName)
                            .join(', ')
                        : (m.providerName ?? '—'),
                  ),
                  _InfoRow('Categoria', m.categoryName ?? '—'),
                  _InfoRow('SKU', m.sku ?? '—'),
                  _InfoRow('Unidade de medida', m.unitOfMeasureLabel),
                  _InfoRow('Serviços', m.applicableServicesLabel),
                  if (m.description?.isNotEmpty == true) _InfoRow('Descrição', m.description!),
                ],
              ),
              if (m.isStorable) ...[
                const SizedBox(height: 16),
                ClaySurface(
                  depth: ClayDepth.raised,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Estoque', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text('Atual: ${m.currentStock} ${m.unitOfMeasureLabel}'),
                      Text('Valor custo: ${currency.format(m.stockValueAtCost)}'),
                      Text('Valor repasse: ${currency.format(m.stockValueAtResale)}'),
                      if (canManage) ...[
                        const SizedBox(height: 12),
                        ClayButton(
                          label: 'Entrada / saída',
                          variant: ClayButtonVariant.secondary,
                          expand: false,
                          icon: Icons.swap_vert_rounded,
                          onPressed: () => StockMovementSheet.show(context, m),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Movimentações', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                movementsAsync.when(
                  data: (movements) {
                    if (movements.isEmpty) {
                      return const Text(
                        'Nenhuma movimentação registrada.',
                        style: TextStyle(color: ClayTokens.textSecondary),
                      );
                    }
                    return Column(
                      children: movements.map((mv) {
                        final sign = mv.movementType == StockMovementType.entry ? '+' : '−';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ClaySurface(
                            depth: ClayDepth.pressed,
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${mv.movementType.label} $sign${mv.quantity}',
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      if (mv.notes?.isNotEmpty == true)
                                        Text(
                                          mv.notes!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: ClayTokens.textSecondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  dateFmt.format(mv.createdAt.toLocal()),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: ClayTokens.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.rows});

  final String title;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return ClaySurface(
      depth: ClayDepth.raised,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: ClayTokens.textSecondary)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
