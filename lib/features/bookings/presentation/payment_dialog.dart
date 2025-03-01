import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/strings.dart';
import '../../../database/models/booking.dart';
import '../controllers/booking_controller.dart';

class PaymentDialog extends ConsumerStatefulWidget {
  final Booking booking;

  const PaymentDialog({
    super.key,
    required this.booking,
  });

  @override
  ConsumerState<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  double _remainingAmount = 0;
  PaymentStatus _currentStatus = PaymentStatus.unpaid;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.booking.amountPaid.toString();
    _currentStatus = widget.booking.paymentStatus;
    _calculateRemainingAmount();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _calculateRemainingAmount() {
    setState(() {
      final amountPaid = double.tryParse(_amountController.text) ?? 0;
      _remainingAmount = widget.booking.totalPrice - amountPaid;
      if (_remainingAmount < 0) _remainingAmount = 0;
      
      // Обновляем статус оплаты
      if (amountPaid >= widget.booking.totalPrice) {
        _currentStatus = PaymentStatus.paid;
      } else if (amountPaid > 0) {
        _currentStatus = PaymentStatus.partiallyPaid;
      } else {
        _currentStatus = PaymentStatus.unpaid;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(Strings.payment),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${Strings.totalPrice}: ${widget.booking.totalPrice}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: Strings.paymentAmount,
                hintText: Strings.paymentAmountHint,
                border: const OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return Strings.required;
                }
                final amount = double.tryParse(value);
                if (amount == null || amount < 0) {
                  return Strings.invalidPrice;
                }
                return null;
              },
              onChanged: (value) {
                _calculateRemainingAmount();
              },
            ),
            const SizedBox(height: 16),
            Text(
              '${Strings.remainingAmount}: $_remainingAmount',
              style: TextStyle(
                color: _remainingAmount > 0 ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('${Strings.paymentStatus}: '),
                Text(
                  Strings.paymentStatuses[_currentStatus.name] ?? _currentStatus.name,
                  style: TextStyle(
                    color: _currentStatus == PaymentStatus.paid
                        ? Colors.green
                        : _currentStatus == PaymentStatus.partiallyPaid
                            ? Colors.orange
                            : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(Strings.cancel),
        ),
        TextButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final amount = double.parse(_amountController.text);
              await ref.read(bookingControllerProvider).updatePayment(
                    widget.booking.uuid,
                    amount,
                  );
              if (mounted) {
                Navigator.of(context).pop(true);
              }
            }
          },
          child: Text(Strings.save),
        ),
      ],
    );
  }
}
