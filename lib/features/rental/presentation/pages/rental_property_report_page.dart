import 'package:cond_manager/core/permissions/app_permissions.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/rental/presentation/providers/rental_providers.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final rentalPnlFromProvider = StateProvider<DateTime?>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

final rentalPnlToProvider = StateProvider<DateTime?>((ref) => DateTime.now());

final rentalPropertyPnlProvider = FutureProvider.autoDispose((ref) async {
  final from = ref.watch(rentalPnlFromProvider);
  final to = ref.watch(rentalPnlToProvider);
  final result = await ref.watch(rentalRepositoryProvider).propertyPnlReport(
        from: from,
        to: to,
      );
  return result.when(success: (rows) => rows, failure: (e) => throw e);
});

class RentalPropertyReportPage extends ConsumerWidget {
  const RentalPropertyReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final hasBoth = profile?.permissions.hasMaintenanceAndRental ?? false;
    final reportAsync = ref.watch(rentalPropertyPnlProvider);
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Receita × Manutenção por imóvel',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                hasBoth
                    ? 'Compara receita de locação (cobranças pagas) com custo de ordens de serviço '
                        'vinculadas a cada imóvel. Chamados e OS precisam ter o imóvel selecionado.'
                    : 'Ative os módulos Manutenção e Locação para ver custos de manutenção por imóvel. '
                        'A receita de locação aparece com o módulo Locação.',
                style: const TextStyle(color: ClayTokens.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DateFilterTile(
                      label: 'De',
                      value: ref.watch(rentalPnlFromProvider),
                      onPick: (d) => ref.read(rentalPnlFromProvider.notifier).state = d,
                      dateFmt: dateFmt,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DateFilterTile(
                      label: 'Até',
                      value: ref.watch(rentalPnlToProvider),
                      onPick: (d) => ref.read(rentalPnlToProvider.notifier).state = d,
                      dateFmt: dateFmt,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: reportAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 3)),
            error: (e, _) => Center(child: Text('$e')),
            data: (rows) {
              if (rows.isEmpty) {
                return const Center(
                  child: Text(
                    'Nenhum imóvel com movimentação no período.',
                    style: TextStyle(color: ClayTokens.textSecondary),
                  ),
                );
              }

              final totalRevenue = rows.fold<double>(0, (s, r) => s + r.rentalRevenue);
              final totalCost = rows.fold<double>(0, (s, r) => s + r.maintenanceCost);

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(rentalPropertyPnlProvider),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    ClayCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: _SummaryStat(
                              label: 'Receita total',
                              value: currency.format(totalRevenue),
                              color: ClayTokens.success,
                            ),
                          ),
                          Expanded(
                            child: _SummaryStat(
                              label: 'Custo manutenção',
                              value: currency.format(totalCost),
                              color: ClayTokens.warning,
                            ),
                          ),
                          Expanded(
                            child: _SummaryStat(
                              label: 'Resultado',
                              value: currency.format(totalRevenue - totalCost),
                              color: ClayTokens.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...rows.map(
                      (row) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ClayListTileCard(
                          icon: Icons.home_work_rounded,
                          title: row.propertyTitle,
                          subtitle: [
                            if (row.condominiumName != null) row.condominiumName,
                            'Receita: ${currency.format(row.rentalRevenue)}',
                            if (hasBoth) 'Manutenção: ${currency.format(row.maintenanceCost)}',
                            if (hasBoth) 'Líquido: ${currency.format(row.netIncome)}',
                            if (hasBoth && row.ticketCount > 0) '${row.ticketCount} chamado(s)',
                            if (hasBoth && row.workOrderCount > 0) '${row.workOrderCount} OS',
                          ].whereType<String>().join(' · '),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DateFilterTile extends StatelessWidget {
  const _DateFilterTile({
    required this.label,
    required this.value,
    required this.onPick,
    required this.dateFmt,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPick;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    return ClaySurface(
      depth: ClayDepth.pressed,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
        );
        if (picked != null) onPick(picked);
      },
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: ClayTokens.textSecondary)),
          const Spacer(),
          Text(
            value != null ? dateFmt.format(value!) : '—',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: ClayTokens.textSecondary)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: color),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
