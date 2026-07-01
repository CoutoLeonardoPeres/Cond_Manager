import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/condominiums/domain/entities/condominium.dart';
import 'package:cond_manager/features/condominiums/presentation/providers/condominium_providers.dart';
import 'package:cond_manager/features/financial/presentation/providers/financial_providers.dart';
import 'package:cond_manager/features/financial/presentation/utils/financial_permissions.dart';
import 'package:cond_manager/features/financial/presentation/widgets/financial_list_filters_bar.dart';
import 'package:cond_manager/shared/domain/enums/financial_category.dart';
import 'package:cond_manager/shared/domain/enums/financial_record_type.dart';
import 'package:cond_manager/shared/domain/enums/financial_scope.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:cond_manager/shared/widgets/form/month_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class FinancialRecordsTab extends ConsumerWidget {
  const FinancialRecordsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(financialRecordsListProvider);
    final filter = ref.watch(financialListFilterProvider);
    final condosAsync = ref.watch(accessibleCondominiumsProvider);
    final profile = ref.watch(currentProfileProvider).value;
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
    final dateFmt = DateFormat('dd/MM/yyyy');

    final canCreate = filter.scope == FinancialScope.managementCompany
        ? (profile?.canManageManagementFinancial ?? false)
        : (filter.condominiumId != null
            ? profile?.canManageFinancialIn(filter.condominiumId!) ?? false
            : profile?.canManageManagementFinancial ?? false);

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                MediaQuery.sizeOf(context).width < 640 ? 12 : 20,
                12,
                MediaQuery.sizeOf(context).width < 640 ? 12 : 20,
                8,
              ),
              child: Column(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final narrow = constraints.maxWidth < 380;
                      return SegmentedButton<FinancialScope>(
                        segments: [
                          ButtonSegment(
                            value: FinancialScope.condominium,
                            label: const Text('Condomínio'),
                            icon: narrow ? null : const Icon(Icons.apartment_rounded, size: 18),
                          ),
                          ButtonSegment(
                            value: FinancialScope.managementCompany,
                            label: const Text('Gestora'),
                            icon: narrow ? null : const Icon(Icons.business_rounded, size: 18),
                          ),
                        ],
                        selected: {filter.scope},
                        onSelectionChanged: (s) {
                          ref.read(financialListFilterProvider.notifier).state =
                              filter.copyWith(scope: s.first, clearCondominium: true);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  condosAsync.when(
                    data: (condos) => FinancialListFiltersBar(
                      wideColumns: filter.scope == FinancialScope.condominium ? 4 : 3,
                      fields: [
                        if (filter.scope == FinancialScope.condominium && condos.isNotEmpty)
                          ClayDropdownField<Condominium?>(
                            compact: true,
                            label: 'Condomínio',
                            value: filter.condominiumId != null
                                ? condos.cast<Condominium?>().firstWhere(
                                      (c) => c?.id == filter.condominiumId,
                                      orElse: () => null,
                                    )
                                : null,
                            items: [null, ...condos],
                            itemLabel: (c) => c?.name ?? 'Todos',
                            onChanged: (v) {
                              ref.read(financialListFilterProvider.notifier).state =
                                  filter.copyWith(
                                condominiumId: v?.id,
                                clearCondominium: v == null,
                              );
                            },
                          ),
                        MonthFilterBar(
                          compact: true,
                          month: filter.referenceMonth,
                          onChanged: (m) {
                            ref.read(financialListFilterProvider.notifier).state =
                                filter.withReferenceMonth(m);
                          },
                        ),
                        ClayDropdownField<FinancialRecordType?>(
                          compact: true,
                          label: 'Tipo',
                          value: filter.recordType,
                          items: [null, ...FinancialRecordType.values],
                          itemLabel: (t) => t?.label ?? 'Todos',
                          onChanged: (v) {
                            ref.read(financialListFilterProvider.notifier).state =
                                filter.copyWith(recordType: v, clearRecordType: v == null);
                          },
                        ),
                        ClayDropdownField<FinancialCategory?>(
                          compact: true,
                          label: 'Categoria',
                          value: filter.category,
                          items: [null, ...FinancialCategory.values],
                          itemLabel: (c) => c?.label ?? 'Todas',
                          onChanged: (v) {
                            ref.read(financialListFilterProvider.notifier).state =
                                filter.copyWith(category: v, clearCategory: v == null);
                          },
                        ),
                      ],
                    ),
                    loading: () => FinancialListFiltersBar(
                      fields: [
                        MonthFilterBar(
                          compact: true,
                          month: filter.referenceMonth,
                          onChanged: (m) {
                            ref.read(financialListFilterProvider.notifier).state =
                                filter.withReferenceMonth(m);
                          },
                        ),
                        ClayDropdownField<FinancialRecordType?>(
                          compact: true,
                          label: 'Tipo',
                          value: filter.recordType,
                          items: [null, ...FinancialRecordType.values],
                          itemLabel: (t) => t?.label ?? 'Todos',
                          onChanged: (v) {
                            ref.read(financialListFilterProvider.notifier).state =
                                filter.copyWith(recordType: v, clearRecordType: v == null);
                          },
                        ),
                        ClayDropdownField<FinancialCategory?>(
                          compact: true,
                          label: 'Categoria',
                          value: filter.category,
                          items: [null, ...FinancialCategory.values],
                          itemLabel: (c) => c?.label ?? 'Todas',
                          onChanged: (v) {
                            ref.read(financialListFilterProvider.notifier).state =
                                filter.copyWith(category: v, clearCategory: v == null);
                          },
                        ),
                      ],
                    ),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: recordsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator(strokeWidth: 3)),
                error: (e, _) => Center(child: Text('$e')),
                data: (records) {
                  if (records.isEmpty) {
                    return const Center(
                      child: Text(
                        'Nenhum lançamento no período.',
                        style: TextStyle(color: ClayTokens.textSecondary),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(financialRecordsListProvider),
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, canCreate ? 88 : 24),
                      itemCount: records.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final r = records[index];
                        final isExpense = r.recordType != FinancialRecordType.income;
                        return ClayListTileCard(
                          icon: isExpense
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          iconColor: isExpense ? ClayTokens.error : ClayTokens.success,
                          title: r.description,
                          subtitle: [
                            r.category.label,
                            dateFmt.format(r.referenceDate),
                            if (r.condominiumName != null) r.condominiumName!,
                            currency.format(r.totalWithTax),
                            if (r.isPaid) 'Pago',
                          ].join(' · '),
                          onTap: () => context.go('/financial/${r.id}/edit'),
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
              label: 'Novo lançamento',
              expand: false,
              icon: Icons.add_rounded,
              onPressed: () => context.go(
                Uri(
                  path: '/financial/new',
                  queryParameters: {
                    'scope': filter.scope.value,
                    if (filter.condominiumId != null)
                      'condominiumId': filter.condominiumId!,
                  },
                ).toString(),
              ),
            ),
          ),
      ],
    );
  }
}
