import 'package:cond_manager/core/permissions/app_permissions.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/rental/presentation/providers/rental_providers.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class RentalLeasesPage extends ConsumerWidget {
  const RentalLeasesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leasesAsync = ref.watch(rentalLeasesListProvider);
    final dateFmt = DateFormat('dd/MM/yyyy');
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
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
                    'Contratos',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Locação de longo prazo, corporativa e residencial com inquilinos e vigência.',
                    style: TextStyle(color: ClayTokens.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            Expanded(
              child: leasesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 3)),
                error: (e, _) => Center(child: Text('$e')),
                data: (leases) {
                  if (leases.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Nenhum contrato cadastrado.',
                            style: TextStyle(color: ClayTokens.textSecondary),
                          ),
                          if (canCreate) ...[
                            const SizedBox(height: 16),
                            ClayButton(
                              label: 'Novo contrato',
                              expand: false,
                              icon: Icons.add_rounded,
                              onPressed: () => context.go('/rental/leases/new'),
                            ),
                          ],
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(rentalLeasesListProvider),
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, canCreate ? 88 : 24),
                      itemCount: leases.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final l = leases[i];
                        return ClayListTileCard(
                          icon: Icons.description_rounded,
                          title: l.tenantName ?? l.propertyTitle,
                          subtitle: [
                            l.propertyTitle,
                            l.status.label,
                            '${dateFmt.format(l.startDate)}${l.endDate != null ? ' → ${dateFmt.format(l.endDate!)}' : ''}',
                            currency.format(l.monthlyRent),
                          ].join(' · '),
                          onTap: () => context.go('/rental/leases/${l.id}/edit'),
                        );
                      },
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
              label: 'Novo contrato',
              expand: false,
              icon: Icons.add_rounded,
              onPressed: () => context.go('/rental/leases/new'),
            ),
          ),
      ],
    );
  }
}
