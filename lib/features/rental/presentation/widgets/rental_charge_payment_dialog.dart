import 'package:cond_manager/features/rental/domain/entities/rental_inputs.dart';
import 'package:cond_manager/shared/domain/enums/rental_lease_contract_enums.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RentalChargePaymentDialog extends StatefulWidget {
  const RentalChargePaymentDialog({super.key, required this.charge});

  final RentalCharge charge;

  static Future<RentalChargePaymentConfirmation?> show(
    BuildContext context, {
    required RentalCharge charge,
  }) {
    return showDialog<RentalChargePaymentConfirmation>(
      context: context,
      builder: (_) => RentalChargePaymentDialog(charge: charge),
    );
  }

  @override
  State<RentalChargePaymentDialog> createState() => _RentalChargePaymentDialogState();
}

class _RentalChargePaymentDialogState extends State<RentalChargePaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  RentalPaymentMethod _paymentMethod = RentalPaymentMethod.pix;
  late DateTime _paidAt;

  @override
  void initState() {
    super.initState();
    final charge = widget.charge;
    _amountController = TextEditingController(
      text: charge.amount.toStringAsFixed(2).replaceAll('.', ','),
    );
    final now = DateTime.now();
    _paidAt = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double _parseAmount(String text) => double.tryParse(text.replaceAll(',', '.')) ?? 0;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      RentalChargePaymentConfirmation(
        paymentMethod: _paymentMethod,
        paidAmount: _parseAmount(_amountController.text),
        paidAt: _paidAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy');
    final charge = widget.charge;

    return AlertDialog(
      title: const Text('Confirmar pagamento'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                charge.description,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                [
                  if (charge.propertyTitle != null) charge.propertyTitle!,
                  if (charge.dueDate != null) 'Venc.: ${dateFmt.format(charge.dueDate!)}',
                ].whereType<String>().join(' · '),
                style: const TextStyle(color: ClayTokens.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ClayTextField(
                controller: _amountController,
                label: 'Valor pago (R\$) *',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Informe o valor pago';
                  if (_parseAmount(v) <= 0) return 'Valor inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _PaymentDateTile(
                label: 'Data do pagamento',
                date: _paidAt,
                onPick: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _paidAt,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _paidAt = picked);
                },
              ),
              const SizedBox(height: 12),
              ClayDropdownField<RentalPaymentMethod>(
                label: 'Forma de pagamento',
                value: _paymentMethod,
                items: RentalPaymentMethod.values,
                itemLabel: (m) => m.label,
                onChanged: (v) => setState(() => _paymentMethod = v ?? RentalPaymentMethod.pix),
              ),
              const SizedBox(height: 12),
              const Text(
                'A cobrança será marcada como paga e um lançamento será criado no financeiro.',
                style: TextStyle(color: ClayTokens.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Confirmar pagamento'),
        ),
      ],
    );
  }
}

class _PaymentDateTile extends StatelessWidget {
  const _PaymentDateTile({
    required this.label,
    required this.date,
    required this.onPick,
  });

  final String label;
  final DateTime date;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final formatted =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    return ClaySurface(
      depth: ClayDepth.pressed,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: ClayTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatted,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ],
              ),
            ),
            const Icon(Icons.calendar_today_rounded, color: ClayTokens.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
