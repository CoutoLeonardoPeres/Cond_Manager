import 'package:cond_manager/core/permissions/app_permissions.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_lease.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_lease_list_filter.dart';
import 'package:cond_manager/features/rental/presentation/providers/rental_providers.dart';
import 'package:cond_manager/features/rental/presentation/widgets/rental_list_filters_bar.dart';
import 'package:cond_manager/shared/domain/enums/rental_lease_status.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class RentalLeasesPage extends ConsumerWidget {
  const RentalLeasesPage({super.key});

  List<RentalLease> _filterAndSort(
    List<RentalLease> leases,
    String query,
    RentalLeaseListFilter filter,
  ) {
    final q = query.trim().toLowerCase();
    var list = leases.where((l) => rentalLeaseMatchesFilter(l, filter)).toList();

    if (q.isNotEmpty) {
      list = list.where((l) {
        final haystack = [
          l.tenantName,
          l.propertyTitle,
          l.leaseNumber,
          l.status.label,
        ].whereType<String>().join(' ').toLowerCase();
        return haystack.contains(q);
      }).toList();
    }

    list.sort((a, b) {
      final nameA = (a.tenantName ?? a.propertyTitle).toLowerCase();
      final nameB = (b.tenantName ?? b.propertyTitle).toLowerCase();
      return nameA.compareTo(nameB);
    });
    return list;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leasesAsync = ref.watch(rentalLeasesListProvider);
    final searchQuery = ref.watch(rentalLeaseSearchQueryProvider);
    final filter = ref.watch(rentalLeaseListFilterProvider);
    final dateFmt = DateFormat('dd/MM/yyyy');
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final canCreate = ref.watch(currentProfileProvider).value?.permissions.canManageRental ?? false;

    void updateFilter(RentalLeaseListFilter next) {
      ref.read(rentalLeaseListFilterProvider.notifier).state = next;
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
                    'Contratos',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Locação de longo prazo, corporativa e residencial com inquilinos e vigência.',
                    style: TextStyle(color: ClayTokens.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const minGridWidth = 720.0;
                      final gridWidth = constraints.maxWidth < minGridWidth
                          ? minGridWidth
                          : constraints.maxWidth;

                      final grid = FormGrid(
                        columns: 3,
                        items: [
                          FormGridField(
                            child: ClayTextField(
                              label: 'Pesquisar',
                              hint: 'Inquilino, imóvel ou nº do contrato…',
                              prefixIcon: const Icon(Icons.search_rounded, size: 20),
                              onChanged: (v) =>
                                  ref.read(rentalLeaseSearchQueryProvider.notifier).state = v,
                            ),
                          ),
                          FormGridField(
                            child: RentalMonthFilterBar(
                              compact: true,
                              month: filter.month,
                              onChanged: (m) => updateFilter(
                                filter.copyWith(month: m, clearMonth: m == null),
                              ),
                            ),
                          ),
                          FormGridField(
                            child: ClayDropdownField<RentalLeaseStatus?>(
                              label: 'Status',
                              value: filter.status,
                              items: [null, ...RentalLeaseStatus.values],
                              itemLabel: (s) => s?.label ?? 'Todos',
                              onChanged: (s) => updateFilter(
                                filter.copyWith(status: s, clearStatus: s == null),
                              ),
                            ),
                          ),
                        ],
                      );

                      if (constraints.maxWidth < minGridWidth) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(width: gridWidth, child: grid),
                        );
                      }
                      return grid;
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: leasesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 3)),
                error: (e, _) => Center(child: Text('$e')),
                data: (leases) {
                  final filtered = _filterAndSort(leases, searchQuery, filter);

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

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        searchQuery.trim().isNotEmpty
                            ? 'Nenhum contrato encontrado para "$searchQuery".'
                            : 'Nenhum contrato encontrado com os filtros selecionados.',
                        style: const TextStyle(color: ClayTokens.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(rentalLeasesListProvider),
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, canCreate ? 88 : 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final l = filtered[i];
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
