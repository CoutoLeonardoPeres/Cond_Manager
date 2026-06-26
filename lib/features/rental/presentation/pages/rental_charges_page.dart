import 'package:cond_manager/core/permissions/app_permissions.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_inputs.dart';
import 'package:cond_manager/features/rental/presentation/providers/rental_providers.dart';
import 'package:cond_manager/shared/domain/enums/rental_charge_status.dart';
import 'package:cond_manager/shared/domain/enums/rental_charge_type.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class RentalChargesPage extends ConsumerWidget {
  const RentalChargesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(rentalChargeListFilterProvider);
    final chargesAsync = ref.watch(rentalChargesListProvider);
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final dateFmt = DateFormat('dd/MM/yyyy');
    final canCreate = ref.watch(currentProfileProvider).value?.permissions.canManageRental ?? false;

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
                    'Aluguéis, depósitos, taxas e recebimentos vinculados a contratos e reservas.',
                    style: TextStyle(color: ClayTokens.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ClayDropdownField<RentalChargeType?>(
                          label: 'Tipo',
                          value: filter.chargeType,
                          items: [null, ...RentalChargeType.values],
                          itemLabel: (t) => t?.label ?? 'Todos',
                          onChanged: (v) => ref.read(rentalChargeListFilterProvider.notifier).state =
                              filter.copyWith(chargeType: v, clearType: v == null),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClayDropdownField<RentalChargeStatus?>(
                          label: 'Status',
                          value: filter.status,
                          items: [null, ...RentalChargeStatus.values],
                          itemLabel: (s) => s?.label ?? 'Todos',
                          onChanged: (v) => ref.read(rentalChargeListFilterProvider.notifier).state =
                              filter.copyWith(status: v, clearStatus: v == null),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: chargesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 3)),
                error: (e, _) => Center(child: Text('$e')),
                data: (charges) {
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
                          if (canCreate) ...[
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
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(rentalChargesListProvider),
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, canCreate ? 88 : 24),
                      itemCount: charges.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _ChargeTile(
                        charge: charges[i],
                        currency: currency,
                        dateFmt: dateFmt,
                        onTap: () => context.go('/rental/charges/${charges[i].id}/edit'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        if (canCreate)
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

class _ChargeTile extends StatelessWidget {
  const _ChargeTile({
    required this.charge,
    required this.currency,
    required this.dateFmt,
    this.onTap,
  });

  final RentalCharge charge;
  final NumberFormat currency;
  final DateFormat dateFmt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (charge.status) {
      RentalChargeStatus.paid => ClayTokens.success,
      RentalChargeStatus.overdue => ClayTokens.error,
      RentalChargeStatus.cancelled => ClayTokens.textSecondary,
      _ => ClayTokens.warning,
    };

    return ClayListTileCard(
      icon: Icons.payments_rounded,
      iconColor: statusColor,
      title: charge.description,
      subtitle: [
        charge.chargeType.label,
        charge.status.label,
        currency.format(charge.amount),
        if (charge.propertyTitle != null) charge.propertyTitle,
        if (charge.partyName != null) charge.partyName,
        if (charge.dueDate != null) 'Venc.: ${dateFmt.format(charge.dueDate!)}',
        if (charge.financialRecordId != null) 'No financeiro',
      ].whereType<String>().join(' · '),
      onTap: onTap,
    );
  }
}
