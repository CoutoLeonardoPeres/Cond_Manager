import 'package:cond_manager/features/financial/domain/entities/financial_record.dart';
import 'package:cond_manager/features/financial/presentation/providers/financial_providers.dart';
import 'package:cond_manager/features/rental/domain/utils/rental_expense_allocation.dart';
import 'package:cond_manager/features/rental/presentation/providers/rental_providers.dart';
import 'package:cond_manager/features/tickets/domain/entities/ticket.dart';
import 'package:cond_manager/features/tickets/presentation/providers/ticket_providers.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class RentalExpenseAllocateSheet extends ConsumerStatefulWidget {
  const RentalExpenseAllocateSheet({super.key, required this.expense});

  final FinancialRecord expense;

  static Future<void> show(BuildContext context, FinancialRecord expense) {
    if (expense.unitId != null) {
      return showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Não é possível ratear'),
          content: const Text('Esta despesa já está vinculada a uma unidade específica.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
          child: RentalExpenseAllocateSheet(expense: expense),
        ),
      ),
    );
  }

  @override
  ConsumerState<RentalExpenseAllocateSheet> createState() => _RentalExpenseAllocateSheetState();
}

class _RentalExpenseAllocateSheetState extends ConsumerState<RentalExpenseAllocateSheet> {
  RentalExpenseAllocationMethod _method = RentalExpenseAllocationMethod.equal;
  bool _loading = false;
  String? _error;

  List<({String unitId, String label, double weight})> _weights(List<UnitOption> units) {
    return units.map((u) {
      final weight = _method == RentalExpenseAllocationMethod.byArea
          ? (u.areaSqm ?? 0)
          : 1.0;
      return (unitId: u.id, label: u.label, weight: weight);
    }).toList();
  }

  Future<void> _confirm(List<UnitOption> units) async {
    if (_method == RentalExpenseAllocationMethod.byArea &&
        units.any((u) => u.areaSqm == null || u.areaSqm! <= 0)) {
      setState(() => _error = 'Todas as unidades precisam de metragem (m²) cadastrada.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await ref.read(financialRepositoryProvider).allocateRentalExpenseToUnits(
          expenseId: widget.expense.id,
          method: _method.value,
        );

    if (!mounted) return;

    result.when(
      success: (created) {
        ref.invalidate(rentalExpensesListProvider);
        ref.invalidate(rentalExpenseDueAlertsProvider);
        ref.invalidate(rentalExpenseDetailProvider(widget.expense.id));
        ref.invalidate(rentalExpenseAllocationsProvider(widget.expense.id));
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Despesa rateada em ${created.length} unidade(s).')),
        );
      },
      failure: (e) => setState(() {
        _loading = false;
        _error = e.message;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final condoId = widget.expense.condominiumId;
    final unitsAsync = condoId != null
        ? ref.watch(ticketUnitsProvider(condoId))
        : const AsyncValue<List<UnitOption>>.data([]);

    return ClaySurface(
      depth: ClayDepth.raised,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ratear entre unidades',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ),
              IconButton(
                onPressed: _loading ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          Text(
            'Total: ${currency.format(widget.expense.totalWithTax)} · ${widget.expense.description}',
            style: const TextStyle(color: ClayTokens.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          SegmentedButton<RentalExpenseAllocationMethod>(
            segments: RentalExpenseAllocationMethod.values
                .map((m) => ButtonSegment(value: m, label: Text(m.label, style: const TextStyle(fontSize: 11))))
                .toList(),
            selected: {_method},
            onSelectionChanged: (s) => setState(() => _method = s.first),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: unitsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, _) => Center(child: Text('$e')),
              data: (units) {
                if (units.isEmpty) {
                  return const Center(
                    child: Text('Nenhuma unidade ativa neste condomínio.'),
                  );
                }

                final weighted = _weights(units);
                final shares = computeUnitAllocationShares(
                  totalAmount: widget.expense.totalWithTax,
                  units: weighted.map((w) => (unitId: w.unitId, weight: w.weight)).toList(),
                );

                return ListView.separated(
                  itemCount: weighted.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final row = weighted[index];
                    final share = shares[row.unitId] ?? 0;
                    return ClaySurface(
                      depth: ClayDepth.pressed,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(child: Text(row.label, style: const TextStyle(fontWeight: FontWeight.w600))),
                          if (_method == RentalExpenseAllocationMethod.byArea)
                            Text(
                              '${row.weight.toStringAsFixed(0)} m²',
                              style: const TextStyle(fontSize: 12, color: ClayTokens.textMuted),
                            ),
                          const SizedBox(width: 12),
                          Text(
                            currency.format(share),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: ClayTokens.error)),
          ],
          const SizedBox(height: 12),
          unitsAsync.maybeWhen(
            data: (units) => ClayButton(
              label: 'Confirmar rateio',
              icon: Icons.account_balance_rounded,
              isLoading: _loading,
              onPressed: _loading || units.isEmpty ? null : () => _confirm(units),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
