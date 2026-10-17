import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../models/customer_model.dart';
import '../../../../shared/models/enums.dart';
import '../../controllers/customers_controller.dart';
import '../../../dashboard/controllers/dashboard_controller.dart';

class ReceivePaymentDialog extends StatefulWidget {
  final CustomerModel? initialCustomer;

  const ReceivePaymentDialog({super.key, this.initialCustomer});

  @override
  State<ReceivePaymentDialog> createState() => _ReceivePaymentDialogState();
}

class _ReceivePaymentDialogState extends State<ReceivePaymentDialog> {
  final _customersCtrl = Get.find<CustomersController>();

  CustomerModel? _selectedCustomer;
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  final DateTime _paymentDate = DateTime.now();

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedCustomer =
        widget.initialCustomer ??
        (_customersCtrl.customers.isNotEmpty
            ? _customersCtrl.customers.first
            : null);

    if (_selectedCustomer != null &&
        _selectedCustomer!.outstandingBalance > 0) {
      _amountCtrl.text = _selectedCustomer!.outstandingBalance.toStringAsFixed(
        0,
      );
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selectedCustomer == null) {
      setState(() => _errorMessage = 'Please select a customer');
      return;
    }

    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
    if (amount <= 0) {
      setState(() => _errorMessage = 'Payment amount must be greater than 0');
      return;
    }

    final success = _customersCtrl.receivePayment(
      customerId: _selectedCustomer!.id,
      amount: amount,
      method: _paymentMethod,
      date: _paymentDate,
      note: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
    );

    if (success) {
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().refreshData();
      }
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'Receive Customer Khata Payment',
      subtitle: 'Record received cash/bank payment and update running ledger',
      maxWidth: 580,
      actions: [
        CustomButton(
          text: 'Cancel',
          isSecondary: true,
          onPressed: () => Get.back(),
        ),
        const SizedBox(width: 12),
        CustomButton(
          text: 'Save Payment Voucher',
          icon: Icons.check_circle_outline,
          onPressed: _submit,
        ),
      ],
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Customer selection
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Customer Account *',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<CustomerModel>(
                    value: _selectedCustomer,
                    isExpanded: true,
                    items: _customersCtrl.customers.map((c) {
                      return DropdownMenuItem<CustomerModel>(
                        value: c,
                        child: Text(
                          '${c.name} (${c.city}) — Balance Due: ${CurrencyFormatter.format(c.outstandingBalance)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (c) {
                      setState(() {
                        _selectedCustomer = c;
                        if (c != null && c.outstandingBalance > 0) {
                          _amountCtrl.text = c.outstandingBalance
                              .toStringAsFixed(0);
                        }
                      });
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (_selectedCustomer != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Current Outstanding Balance:',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(
                      _selectedCustomer!.outstandingBalance,
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _selectedCustomer!.outstandingBalance > 0
                          ? AppColors.error
                          : AppColors.success,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Amount Received (Rs.) *',
                  hint: 'e.g. 50000',
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Method',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<PaymentMethod>(
                          value: _paymentMethod,
                          isExpanded: true,
                          items:
                              [
                                PaymentMethod.cash,
                                PaymentMethod.bank,
                                PaymentMethod.cheque,
                              ].map((m) {
                                return DropdownMenuItem<PaymentMethod>(
                                  value: m,
                                  child: Text(
                                    m.displayName,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                );
                              }).toList(),
                          onChanged: (m) {
                            if (m != null) setState(() => _paymentMethod = m);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          CustomTextField(
            label: 'Payment Voucher Note (Optional)',
            hint: 'e.g. Direct cash collected from Shah Alam market',
            controller: _notesCtrl,
          ),
        ],
      ),
    );
  }
}
