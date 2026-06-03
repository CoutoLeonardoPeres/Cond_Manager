import 'package:cond_manager/features/condominiums/presentation/providers/condominium_providers.dart';
import 'package:cond_manager/features/financial/presentation/providers/financial_providers.dart';
import 'package:cond_manager/features/financial/presentation/widgets/financial_report_view.dart';
import 'package:cond_manager/shared/domain/enums/financial_scope.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FinancialCondoReportTab extends ConsumerWidget {
  const FinancialCondoReportTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(financialCondoReportFilterProvider);
    final condosAsync = ref.watch(accessibleCondominiumsProvider);
    final summaryAsync = ref.watch(financialReportProvider(query));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: condosAsync.when(
            data: (condos) {
              if (condos.isEmpty) return const SizedBox.shrink();
              final items = [
                const _CondoOpt(id: null, label: 'Todos os condomínios'),
                ...condos.map((c) => _CondoOpt(id: c.id, label: c.name)),
              ];
              final sel = items.firstWhere(
                (o) => o.id == query.condominiumId,
                orElse: () => items.first,
              );
              return ClayDropdownField<_CondoOpt>(
                label: 'Condomínio',
                value: sel,
                items: items,
                itemLabel: (o) => o.label,
                onChanged: (v) {
                  ref.read(financialCondoReportFilterProvider.notifier).state =
                      FinancialReportQuery(
                    scope: FinancialScope.condominium,
                    condominiumId: v?.id,
                    fromDate: query.fromDate,
                    toDate: query.toDate,
                  );
                },
              );
            },
            loading: () => const LinearProgressIndicator(),
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
