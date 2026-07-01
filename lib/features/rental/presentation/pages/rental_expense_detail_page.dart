import 'package:cond_manager/core/permissions/app_permissions.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/rental/domain/utils/rental_expense_mapping.dart';
import 'package:cond_manager/features/rental/presentation/providers/rental_providers.dart';
import 'package:cond_manager/features/rental/presentation/widgets/rental_expense_allocate_sheet.dart';
import 'package:cond_manager/features/rental/presentation/widgets/rental_expense_attachments_editor.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class RentalExpenseDetailPage extends ConsumerWidget {
  const RentalExpenseDetailPage({super.key, required this.expenseId});

  final String expenseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseAsync = ref.watch(rentalExpenseDetailProvider(expenseId));
    final allocationsAsync = ref.watch(rentalExpenseAllocationsProvider(expenseId));
    final canManage = AppPermissions(ref.watch(currentProfileProvider).value).canManageRental;
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final dateFmt = DateFormat('dd/MM/yyyy');

    return expenseAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 3)),
      error: (e, _) => Center(child: Text('$e')),
      data: (expense) {
        final typeLabel = rentalExpenseTypeLabel(
          entryType: expense.rentalExpenseEntryType,
          billType: expense.condominiumBillType,
          serviceType: expense.expenseServiceType,
          materialCategoryName: expense.materialCategoryName,
        );
        final scopeLabel = rentalExpenseScopeLabel(
          unitLabel: expense.unitLabel,
          condominiumName: expense.condominiumName,
        );
        final hasAllocations = allocationsAsync.valueOrNull?.isNotEmpty == true;
        final canAllocate = canManage &&
            expense.unitId == null &&
            !expense.isAllocationChild &&
            !hasAllocations;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/rental/expenses'),
                    icon: const Icon(Icons.arrow_back_rounded),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      expense.description,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(typeLabel, style: const TextStyle(color: ClayTokens.primary, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              ClaySurface(
                depth: ClayDepth.raised,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _InfoRow('Escopo', scopeLabel),
                    _InfoRow('Condomínio', expense.condominiumName ?? '—'),
                    if (expense.unitLabel != null) _InfoRow('Unidade', expense.unitLabel!),
                    _InfoRow('Data', dateFmt.format(expense.referenceDate)),
                    _InfoRow('Valor', currency.format(expense.amount)),
                    if (expense.taxAmount > 0) _InfoRow('Impostos', currency.format(expense.taxAmount)),
                    _InfoRow('Total', currency.format(expense.totalWithTax), highlight: true),
                    _InfoRow('Status', expense.isPaid ? 'Pago' : 'Em aberto'),
                    if (expense.isRecurringTemplate)
                      _InfoRow('Recorrência', 'Modelo mensal · dia ${expense.recurrenceDayOfMonth ?? 1}'),
                    if (expense.recurrenceTemplateId != null)
                      const _InfoRow('Origem', 'Gerada de modelo mensal'),
                    if (hasAllocations) const _InfoRow('Rateio', 'Distribuída entre unidades'),
                    if (expense.notes != null && expense.notes!.trim().isNotEmpty)
                      _InfoRow('Observações', expense.notes!),
                  ],
                ),
              ),
              if (hasAllocations) ...[
                const SizedBox(height: 16),
                Text(
                  'Parcelas por unidade',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                allocationsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (items) => Column(
                    children: items
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ClaySurface(
                              depth: ClayDepth.pressed,
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.unitLabel ?? item.description,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  Text(
                                    currency.format(item.totalWithTax),
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              RentalExpenseAttachmentsEditor(
                expenseId: expenseId,
                pending: const [],
                onPendingChanged: (_) {},
                enabled: canManage,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  if (canAllocate)
                    ClayButton(
                      label: 'Ratear entre unidades',
                      icon: Icons.account_balance_rounded,
                      expand: false,
                      onPressed: () => RentalExpenseAllocateSheet.show(context, expense),
                    ),
                  ClayButton(
                    label: 'Editar',
                    icon: Icons.edit_rounded,
                    expand: false,
                    onPressed: () => context.go('/rental/expenses/$expenseId/edit'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, {this.highlight = false});

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: ClayTokens.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                fontSize: highlight ? 16 : 14,
                color: highlight ? ClayTokens.success : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
