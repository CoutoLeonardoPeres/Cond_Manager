import 'package:cond_manager/core/permissions/app_permissions.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/condominiums/domain/entities/condominium.dart';
import 'package:cond_manager/features/condominiums/presentation/providers/condominium_providers.dart';
import 'package:cond_manager/features/financial/domain/entities/financial_record.dart';
import 'package:cond_manager/features/financial/presentation/providers/financial_providers.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_expense_list_filter.dart';
import 'package:cond_manager/features/rental/presentation/providers/rental_providers.dart';
import 'package:cond_manager/features/rental/presentation/widgets/rental_expense_due_alerts_section.dart';
import 'package:cond_manager/features/rental/presentation/widgets/rental_expenses_spreadsheet.dart';
import 'package:cond_manager/features/rental/presentation/widgets/rental_list_filters_bar.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class RentalExpensesPage extends ConsumerWidget {
  const RentalExpensesPage({super.key});

  static const _condoFilterWidth = 338.0;
  static const _monthFilterWidth = 365.0;
  static const _monthFilterMinHeight = 66.0;

  List<FinancialRecord> _applyFilters(List<FinancialRecord> expenses, RentalExpenseListFilter filter) {
    return expenses.where((e) => rentalExpenseMatchesFilter(e, filter)).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(rentalExpenseListFilterProvider);
    final expensesAsync = ref.watch(rentalExpensesListProvider);
    final condosAsync = ref.watch(accessibleCondominiumsProvider);
    final canCreate = ref.watch(currentProfileProvider).value?.permissions.canManageRental ?? false;

    void updateFilter(RentalExpenseListFilter next) {
      ref.read(rentalExpenseListFilterProvider.notifier).state = next;
    }

    Future<void> generateRecurring() async {
      final month = filter.month ?? DateTime.now();
      final previousMonth = DateTime(month.year, month.month - 1, 1);
      final result = await ref.read(financialRepositoryProvider).generateRecurringRentalExpenses(
            condominiumId: filter.condominiumId,
            month: month,
          );
      if (!context.mounted) return;
      result.when(
        success: (count) {
          ref.invalidate(rentalExpensesListProvider);
          ref.invalidate(rentalExpenseDueAlertsProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                count > 0
                    ? '$count despesa(s) fixa(s) copiada(s) de ${DateFormat('MM/yyyy').format(previousMonth)} para ${DateFormat('MM/yyyy').format(month)}.'
                    : 'Nenhuma despesa nova — fixas de ${DateFormat('MM/yyyy').format(previousMonth)} já existem em ${DateFormat('MM/yyyy').format(month)}.',
              ),
            ),
          );
        },
        failure: (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
        },
      );
    }

    Condominium? selectedCondo;
    final condos = condosAsync.value ?? const <Condominium>[];
    if (filter.condominiumId != null) {
      for (final c in condos) {
        if (c.id == filter.condominiumId) {
          selectedCondo = c;
          break;
        }
      }
    }

    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final summary = expensesAsync.maybeWhen(
      data: (expenses) => computeRentalExpenseSummary(_applyFilters(expenses, filter)),
      orElse: () => const RentalExpenseSummary(
        unpaidTotal: 0,
        unpaidCount: 0,
        paidTotal: 0,
        paidCount: 0,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Despesas',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _ExpenseTotalsCard(
                      label: 'A pagar',
                      amountLabel: currency.format(summary.unpaidTotal),
                      count: summary.unpaidCount,
                      accent: ClayTokens.warning,
                      loading: expensesAsync.isLoading,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ExpenseTotalsCard(
                      label: 'Pagas',
                      amountLabel: currency.format(summary.paidTotal),
                      count: summary.paidCount,
                      accent: ClayTokens.success,
                      loading: expensesAsync.isLoading,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: _condoFilterWidth,
                      child: condosAsync.when(
                        data: (list) {
                          if (list.isEmpty) return const SizedBox.shrink();
                          return ClayDropdownField<Condominium?>(
                            label: 'Condomínio',
                            value: selectedCondo,
                            items: [null, ...list],
                            itemLabel: (c) => c?.name ?? 'Todos',
                            onChanged: (c) => updateFilter(
                              filter.copyWith(
                                condominiumId: c?.id,
                                clearCondominium: c == null,
                              ),
                            ),
                          );
                        },
                        loading: () => const SizedBox(
                          width: _condoFilterWidth,
                          child: LinearProgressIndicator(),
                        ),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: _monthFilterWidth,
                      child: RentalMonthFilterBar(
                        compact: true,
                        minHeight: _monthFilterMinHeight,
                        month: filter.month,
                        onChanged: (m) => updateFilter(
                          filter.copyWith(month: m, clearMonth: m == null),
                        ),
                      ),
                    ),
                    if (canCreate) ...[
                      const SizedBox(width: 8),
                      ClayButton(
                        label: 'Copiar fixas',
                        icon: Icons.event_repeat_rounded,
                        expand: false,
                        onPressed: generateRecurring,
                      ),
                    ],
                    const SizedBox(width: 8),
                    const RentalExpenseDueAlertsSection(badgeOnly: true),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: expensesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 3)),
            error: (e, _) => Center(child: Text('$e')),
            data: (expenses) {
              final filtered = _applyFilters(expenses, filter);

              if (filtered.isEmpty && !canCreate) {
                return const Center(
                  child: Text(
                    'Nenhuma despesa encontrada com os filtros selecionados.',
                    style: TextStyle(color: ClayTokens.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(rentalExpensesListProvider);
                  ref.invalidate(rentalExpenseDueAlertsProvider);
                },
                child: SizedBox.expand(
                  child: RentalExpensesSpreadsheet(
                    expenses: filtered,
                    condominiums: condos,
                    filter: filter,
                    canEdit: canCreate,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ExpenseTotalsCard extends StatelessWidget {
  const _ExpenseTotalsCard({
    required this.label,
    required this.amountLabel,
    required this.count,
    required this.accent,
    required this.loading,
  });

  final String label;
  final String amountLabel;
  final int count;
  final Color accent;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return ClaySurface(
      depth: ClayDepth.pressed,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(ClayTokens.radiusFull),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ClayTokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  loading ? '—' : amountLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
                Text(
                  loading ? '...' : '$count ${count == 1 ? 'conta' : 'contas'}',
                  style: const TextStyle(fontSize: 11, color: ClayTokens.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
