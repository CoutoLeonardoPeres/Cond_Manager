import 'package:cond_manager/features/condominiums/presentation/providers/condominium_providers.dart';
import 'package:cond_manager/features/financial/presentation/providers/financial_providers.dart';
import 'package:cond_manager/features/financial/presentation/widgets/financial_list_filters_bar.dart';
import 'package:cond_manager/features/financial/presentation/widgets/financial_report_view.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:cond_manager/shared/widgets/form/month_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FinancialCondoReportTab extends ConsumerWidget {
  const FinancialCondoReportTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(financialCondoReportFilterProvider);
    final condosAsync = ref.watch(accessibleCondominiumsProvider);
    final summaryAsync = ref.watch(financialReportProvider(query));

    void updateQuery(FinancialReportQuery next) {
      ref.read(financialCondoReportFilterProvider.notifier).state = next;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: condosAsync.when(
            data: (condos) {
              final fields = <Widget>[
                MonthFilterBar(
                  compact: true,
                  month: query.referenceMonth,
                  onChanged: (m) => updateQuery(query.withReferenceMonth(m)),
                ),
              ];

              if (condos.isNotEmpty) {
                final items = [
                  const _CondoOpt(id: null, label: 'Todos os condomínios'),
                  ...condos.map((c) => _CondoOpt(id: c.id, label: c.name)),
                ];
                final sel = items.firstWhere(
                  (o) => o.id == query.condominiumId,
                  orElse: () => items.first,
                );
                fields.add(
                  ClayDropdownField<_CondoOpt>(
                    compact: true,
                    label: 'Condomínio',
                    value: sel,
                    items: items,
                    itemLabel: (o) => o.label,
                    onChanged: (v) => updateQuery(
                      query.copyWith(
                        condominiumId: v?.id,
                        clearCondominium: v == null || v.id == null,
                      ),
                    ),
                  ),
                );
              }

              return FinancialListFiltersBar(
                wideColumns: fields.length.clamp(1, 2),
                fields: fields,
              );
            },
            loading: () => FinancialListFiltersBar(
              fields: [
                MonthFilterBar(
                  compact: true,
                  month: query.referenceMonth,
                  onChanged: (m) => updateQuery(query.withReferenceMonth(m)),
                ),
              ],
            ),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ),
        Expanded(
          child: FinancialReportView(
            title: 'Relatório por condomínio',
            summaryAsync: summaryAsync,
            onRefresh: () async => ref.invalidate(financialReportProvider(query)),
          ),
        ),
      ],
    );
  }
}

class _CondoOpt {
  const _CondoOpt({required this.id, required this.label});
  final String? id;
  final String label;
}
