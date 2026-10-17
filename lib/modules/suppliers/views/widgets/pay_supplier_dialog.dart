import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../models/supplier_model.dart';
import '../../../../shared/models/enums.dart';
import '../../controllers/suppliers_controller.dart';
import '../../../dashboard/controllers/dashboard_controller.dart';

class PaySupplierDialog extends StatefulWidget {
  final SupplierModel? initialSupplier;

  const PaySupplierDialog({super.key, this.initialSupplier});

  @override
  State<PaySupplierDialog> createState() => _PaySupplierDialogState();
}

class _PaySupplierDialogState extends State<PaySupplierDialog> {
  final _suppliersCtrl = Get.find<SuppliersController>();

  SupplierModel? _selectedSupplier;
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  PaymentMethod _paymentMethod = PaymentMethod.bank;
  final DateTime _paymentDate = DateTime.now();

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedSupplier =
        widget.initialSupplier ??
        (_suppliersCtrl.suppliers.isNotEmpty
            ? _suppliersCtrl.suppliers.first
            : null);

    if (_selectedSupplier != null &&
        _selectedSupplier!.outstandingPayable > 0) {
      _amountCtrl.text = _selectedSupplier!.outstandingPayable.toStringAsFixed(
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
    if (_selectedSupplier == null) {
      setState(() => _errorMessage = 'Please select a supplier');
      return;
    }

    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
    if (amount <= 0) {
      setState(() => _errorMessage = 'Payment amount must be greater than 0');
      return;
    }

    final success = _suppliersCtrl.paySupplier(
      supplierId: _selectedSupplier!.id,
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
      title: 'Make Payment to Mill / Supplier',
      subtitle: 'Record bank/cash disbursement and update mill payable ledger',
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

          // Supplier selection
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Supplier / Mill *',
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
                  child: DropdownButton<SupplierModel>(
                    value: _selectedSupplier,
                    isExpanded: true,
                    items: _suppliersCtrl.suppliers.map((s) {
                      return DropdownMenuItem<SupplierModel>(
                        value: s,
                        child: Text(
                          '${s.name} (${s.city}) — Payable: ${CurrencyFormatter.format(s.outstandingPayable)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (s) {
                      setState(() {
                        _selectedSupplier = s;
                        if (s != null && s.outstandingPayable > 0) {
                          _amountCtrl.text = s.outstandingPayable
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

          if (_selectedSupplier != null)
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
                    'Current Outstanding Payable:',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(
                      _selectedSupplier!.outstandingPayable,
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _selectedSupplier!.outstandingPayable > 0
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
                  label: 'Disbursement Amount (Rs.) *',
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
                                PaymentMethod.bank,
                                PaymentMethod.cash,
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
            label: 'Disbursement Note (Optional)',
            hint: 'e.g. Online transfer via HBL reference #9412',
            controller: _notesCtrl,
          ),
        ],
      ),
    );
  }
}
