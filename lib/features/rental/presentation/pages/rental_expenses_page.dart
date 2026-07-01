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

class RentalExpensesPage extends ConsumerStatefulWidget {
  const RentalExpensesPage({super.key});

  @override
  ConsumerState<RentalExpensesPage> createState() => _RentalExpensesPageState();
}

class _RentalExpensesPageState extends ConsumerState<RentalExpensesPage> {
  final _spreadsheetKey = GlobalKey<RentalExpensesSpreadsheetState>();

  List<FinancialRecord> _applyFilters(List<FinancialRecord> expenses, RentalExpenseListFilter filter) {
    return expenses.where((e) => rentalExpenseMatchesFilter(e, filter)).toList();
  }

  @override
  Widget build(BuildContext context) {
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
                    ? '$count despesa(s) fixa(s) copiada(s) de ${DateFormat('MM/yyyy').format(previousMonth)} para ${DateFormat('MM/yyyy').format(month)} (sem valor).'
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

    final isMobile = MediaQuery.sizeOf(context).width < 640;

    void onAddLine() {
      if (isMobile) {
        _spreadsheetKey.currentState?.openMobileDraftSheet();
      } else {
        _spreadsheetKey.currentState?.addDraftRow();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
              padding: EdgeInsets.fromLTRB(isMobile ? 12 : 20, 8, isMobile ? 12 : 20, 6),
              child: isMobile
                  ? _MobileExpensesHeader(
                      filter: filter,
                      condosAsync: condosAsync,
                      selectedCondo: selectedCondo,
                      canCreate: canCreate,
                      summary: summary,
                      expensesLoading: expensesAsync.isLoading,
                      currency: currency,
                      onMonthChanged: (m) => updateFilter(
                        filter.copyWith(month: m, clearMonth: m == null),
                      ),
                      onCondoChanged: (c) => updateFilter(
                        filter.copyWith(
                          condominiumId: c?.id,
                          clearCondominium: c == null,
                        ),
                      ),
                      onAddLine: onAddLine,
                      onCopyRecurring: generateRecurring,
                    )
                  : _DesktopExpensesHeader(
                      filter: filter,
                      condosAsync: condosAsync,
                      selectedCondo: selectedCondo,
                      canCreate: canCreate,
                      summary: summary,
                      expensesLoading: expensesAsync.isLoading,
                      currency: currency,
                      onMonthChanged: (m) => updateFilter(
                        filter.copyWith(month: m, clearMonth: m == null),
                      ),
                      onCondoChanged: (c) => updateFilter(
                        filter.copyWith(
                          condominiumId: c?.id,
                          clearCondominium: c == null,
                        ),
                      ),
                      onAddLine: onAddLine,
                      onCopyRecurring: generateRecurring,
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
                        key: _spreadsheetKey,
                        expenses: filtered,
                        condominiums: condos,
                        filter: filter,
                        canEdit: canCreate,
                        showAddRowButton: false,
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

class _MobileExpensesHeader extends StatelessWidget {
  const _MobileExpensesHeader({
    required this.filter,
    required this.condosAsync,
    required this.selectedCondo,
    required this.canCreate,
    required this.summary,
    required this.expensesLoading,
    required this.currency,
    required this.onMonthChanged,
    required this.onCondoChanged,
    required this.onAddLine,
    required this.onCopyRecurring,
  });

  final RentalExpenseListFilter filter;
  final AsyncValue<List<Condominium>> condosAsync;
  final Condominium? selectedCondo;
  final bool canCreate;
  final RentalExpenseSummary summary;
  final bool expensesLoading;
  final NumberFormat currency;
  final ValueChanged<DateTime?> onMonthChanged;
  final ValueChanged<Condominium?> onCondoChanged;
  final VoidCallback onAddLine;
  final VoidCallback onCopyRecurring;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Despesas',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        RentalMonthFilterBar(
          compact: true,
          month: filter.month,
          onChanged: onMonthChanged,
        ),
        const SizedBox(height: 10),
        condosAsync.when(
          data: (list) {
            if (list.isEmpty) return const SizedBox.shrink();
            return ClayDropdownField<Condominium?>(
              label: 'Condomínio',
              value: selectedCondo,
              items: [null, ...list],
              itemLabel: (c) => c?.name ?? 'Todos',
              onChanged: onCondoChanged,
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => const SizedBox.shrink(),
        ),
        if (canCreate) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClayButton(
                  label: 'Adicionar',
                  icon: Icons.add_rounded,
                  size: ClayButtonSize.sm,
                  onPressed: onAddLine,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCopyRecurring,
                  icon: const Icon(Icons.event_repeat_rounded, size: 16),
                  label: const Text(
                    'Copiar fixas',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ExpenseTotalsCard(
                label: 'A pagar',
                amountLabel: currency.format(summary.unpaidTotal),
                count: summary.unpaidCount,
                accent: ClayTokens.warning,
                loading: expensesLoading,
                compact: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ExpenseTotalsCard(
                label: 'Pagas',
                amountLabel: currency.format(summary.paidTotal),
                count: summary.paidCount,
                accent: ClayTokens.success,
                loading: expensesLoading,
                compact: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DesktopExpensesHeader extends StatelessWidget {
  const _DesktopExpensesHeader({
    required this.filter,
    required this.condosAsync,
    required this.selectedCondo,
    required this.canCreate,
    required this.summary,
    required this.expensesLoading,
    required this.currency,
    required this.onMonthChanged,
    required this.onCondoChanged,
    required this.onAddLine,
    required this.onCopyRecurring,
  });

  final RentalExpenseListFilter filter;
  final AsyncValue<List<Condominium>> condosAsync;
  final Condominium? selectedCondo;
  final bool canCreate;
  final RentalExpenseSummary summary;
  final bool expensesLoading;
  final NumberFormat currency;
  final ValueChanged<DateTime?> onMonthChanged;
  final ValueChanged<Condominium?> onCondoChanged;
  final VoidCallback onAddLine;
  final VoidCallback onCopyRecurring;

  static const _condoFilterWidth = 308.0;
  static const _monthFilterWidth = 365.0;
  static const _monthFilterMinHeight = 66.0;
  static const _totalsWidthFactor = 0.30;
  static const _alertBadgeScale = 1.3;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _monthFilterMinHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Despesas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              SizedBox(
                width: _monthFilterWidth,
                child: RentalMonthFilterBar(
                  compact: true,
                  minHeight: _monthFilterMinHeight,
                  month: filter.month,
                  onChanged: onMonthChanged,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final totalsWidth = constraints.maxWidth * _totalsWidthFactor;
            final cardWidth = (totalsWidth - 8) / 2;

            return Row(
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
                        onChanged: onCondoChanged,
                      );
                    },
                    loading: () => const SizedBox(
                      width: _condoFilterWidth,
                      child: LinearProgressIndicator(),
                    ),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ),
                if (canCreate) ...[
                  const SizedBox(width: 8),
                  _ExpenseToolbarButton(
                    label: 'Adicionar linha',
                    icon: Icons.add_rounded,
                    onTap: onAddLine,
                  ),
                  const SizedBox(width: 8),
                  _ExpenseToolbarButton(
                    label: 'Copiar fixas',
                    icon: Icons.event_repeat_rounded,
                    onTap: onCopyRecurring,
                  ),
                ],
                Expanded(
                  child: SizedBox(
                    height: _monthFilterMinHeight,
                    child: Center(
                      child: Transform.scale(
                        scale: _alertBadgeScale,
                        alignment: Alignment.center,
                        child: const RentalExpenseDueAlertsSection(
                          badgeOnly: true,
                          compact: true,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: totalsWidth,
                  child: Row(
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: _ExpenseTotalsCard(
                          label: 'A pagar',
                          amountLabel: currency.format(summary.unpaidTotal),
                          count: summary.unpaidCount,
                          accent: ClayTokens.warning,
                          loading: expensesLoading,
                          compact: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: cardWidth,
                        child: _ExpenseTotalsCard(
                          label: 'Pagas',
                          amountLabel: currency.format(summary.paidTotal),
                          count: summary.paidCount,
                          accent: ClayTokens.success,
                          loading: expensesLoading,
                          compact: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ExpenseToolbarButton extends StatelessWidget {
  const _ExpenseToolbarButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ClayTokens.accent.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: ClayTokens.accent),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700, color: ClayTokens.accent),
              ),
            ],
          ),
        ),
      ),
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
    this.compact = false,
  });

  final String label;
  final String amountLabel;
  final int count;
  final Color accent;
  final bool loading;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final labelSize = compact ? 9.0 : 11.0;
    final amountSize = compact ? 12.0 : 16.0;
    final countSize = compact ? 9.0 : 11.0;
    final barHeight = compact ? 22.0 : 36.0;
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 6)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 10);

    return ClaySurface(
      depth: ClayDepth.pressed,
      padding: padding,
      child: Row(
        children: [
          Container(
            width: 3,
            height: barHeight,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(ClayTokens.radiusFull),
            ),
          ),
          SizedBox(width: compact ? 6 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w600,
                    color: ClayTokens.textSecondary,
                  ),
                ),
                SizedBox(height: compact ? 1 : 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    loading ? '—' : amountLabel,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: amountSize,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ),
                Text(
                  loading ? '...' : '$count ${count == 1 ? 'conta' : 'contas'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: countSize, color: ClayTokens.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
