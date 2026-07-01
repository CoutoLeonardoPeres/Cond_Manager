import 'package:cond_manager/core/permissions/app_permissions.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_inputs.dart';
import 'package:cond_manager/features/rental/presentation/providers/rental_providers.dart';
import 'package:cond_manager/features/rental/presentation/widgets/rental_charge_tile.dart';
import 'package:cond_manager/features/rental/presentation/widgets/rental_charges_board.dart';
import 'package:cond_manager/features/rental/presentation/widgets/rental_list_filters_bar.dart';
import 'package:cond_manager/shared/domain/enums/rental_charge_type.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class RentalChargesPage extends ConsumerWidget {
  const RentalChargesPage({super.key});

  List<RentalCharge> _applyFilters(List<RentalCharge> charges, RentalChargeListFilter filter) {
    final base = filter.copyWith(quickFilter: RentalChargeQuickFilter.all);
    return charges.where((c) => rentalChargeMatchesFilter(c, base)).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(rentalChargeListFilterProvider);
    final chargesAsync = ref.watch(rentalChargesListProvider);
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final dateFmt = DateFormat('dd/MM/yyyy');
    final canManage = ref.watch(currentProfileProvider).value?.permissions.canManageRental ?? false;

    void updateFilter(RentalChargeListFilter next) {
      ref.read(rentalChargeListFilterProvider.notifier).state = next;
    }

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cobranças',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Novas, atrasadas e pagas organizadas por coluna.',
                    style: TextStyle(color: ClayTokens.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  RentalListFiltersBar(
                    month: filter.month,
                    onMonthChanged: (m) => updateFilter(
                      filter.copyWith(month: m, clearMonth: m == null),
                    ),
                    extra: ClayDropdownField<RentalChargeType?>(
                      label: 'Tipo',
                      value: filter.chargeType,
                      items: [null, ...RentalChargeType.values],
                      itemLabel: (t) => t?.label ?? 'Todos os tipos',
                      onChanged: (v) => updateFilter(
                        filter.copyWith(chargeType: v, clearType: v == null),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: chargesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 3)),
                error: (e, _) => Center(child: Text('$e')),
                data: (charges) {
                  final filtered = _applyFilters(charges, filter);

                  if (charges.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Nenhuma cobrança cadastrada.',
                            style: TextStyle(color: ClayTokens.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          if (canManage) ...[
                            const SizedBox(height: 16),
                            ClayButton(
                              label: 'Nova cobrança',
                              expand: false,
                              icon: Icons.add_rounded,
                              onPressed: () => context.go('/rental/charges/new'),
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text(
                        'Nenhuma cobrança encontrada com os filtros selecionados.',
                        style: TextStyle(color: ClayTokens.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(rentalChargesListProvider),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 640;
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            isMobile ? 10 : 20,
                            0,
                            isMobile ? 10 : 20,
                            canManage ? 88 : 24,
                          ),
                          child: RentalChargesBoard(
                            charges: filtered,
                            currency: currency,
                            dateFmt: dateFmt,
                            canManage: canManage,
                            onOpenCharge: (charge) => context.go('/rental/charges/${charge.id}/edit'),
                            onConfirmPayment: (charge) =>
                                _confirmChargePayment(context, ref, charge),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        if (canManage)
          Positioned(
            right: 20,
            bottom: 20,
            child: ClayButton(
              label: 'Nova cobrança',
              expand: false,
              icon: Icons.add_rounded,
              onPressed: () => context.go('/rental/charges/new'),
            ),
          ),
      ],
    );
  }
}

Future<void> _confirmChargePayment(
  BuildContext context,
  WidgetRef ref,
  RentalCharge charge,
) async {
  final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
  await confirmRentalChargePayment(
    context,
    charge: charge,
    onPaid: (confirmation) async {
      final result = await ref.read(rentalRepositoryProvider).markChargePaid(
            charge.id,
            paymentMethod: confirmation.paymentMethod,
            paidAmount: confirmation.paidAmount,
            paidAt: confirmation.paidAt,
          );
      if (!context.mounted) return;
      result.when(
        success: (_) {
          ref.invalidate(rentalChargesListProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Pagamento de ${currency.format(confirmation.paidAmount)} confirmado via ${confirmation.paymentMethod.label}.',
              ),
            ),
          );
        },
        failure: (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)),
          );
        },
      );
    },
  );
}
