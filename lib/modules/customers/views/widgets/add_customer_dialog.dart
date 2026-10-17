import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../models/customer_model.dart';
import '../../models/ledger_model.dart';
import '../../../../shared/models/enums.dart';
import '../../controllers/customers_controller.dart';

class AddCustomerDialog extends StatefulWidget {
  const AddCustomerDialog({super.key});

  @override
  State<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<AddCustomerDialog> {
  final _customersCtrl = Get.find<CustomersController>();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _openingBalanceCtrl = TextEditingController(text: '0');

  String _selectedCity = 'Lahore';
  String? _errorMessage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _openingBalanceCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final openingBal = double.tryParse(_openingBalanceCtrl.text.trim()) ?? 0.0;

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Customer/Shop name is required');
      return;
    }

    if (phone.isEmpty) {
      setState(() => _errorMessage = 'Contact phone number is required');
      return;
    }

    final newId = 'CUST-${DateTime.now().millisecondsSinceEpoch % 10000}';
    final initialLedger = <LedgerTransaction>[];

    if (openingBal > 0) {
      initialLedger.add(
        LedgerTransaction(
          id: 'LED-OP-$newId',
          partyId: newId,
          partyType: PartyType.customer,
          date: DateTime.now(),
          referenceType: 'Opening Balance',
          description: 'Previous Ledger Khata Balance Brought Forward',
          debit: openingBal,
          credit: 0.0,
          runningBalance: openingBal,
        ),
      );
    }

    final customer = CustomerModel(
      id: newId,
      name: name,
      phone: phone,
      city: _selectedCity,
      address: address,
      totalPurchases: openingBal,
      amountReceived: 0.0,
      outstandingBalance: openingBal,
      ledger: initialLedger,
    );

    _customersCtrl.addCustomer(customer);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'Register New Customer (Khata Account)',
      subtitle: 'Add wholesale buyer details and opening khata balance',
      maxWidth: 560,
      actions: [
        CustomButton(
          text: 'Cancel',
          isSecondary: true,
          onPressed: () => Get.back(),
        ),
        const SizedBox(width: 12),
        CustomButton(
          text: 'Save Customer',
          icon: Icons.check,
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
          CustomTextField(
            label: 'Customer / Shop Name *',
            hint: 'e.g. Madina Garments House',
            controller: _nameCtrl,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Phone Number *',
                  hint: 'e.g. +92 300 1234567',
                  controller: _phoneCtrl,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'City / Market',
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
                        child: DropdownButton<String>(
                          value: _selectedCity,
                          isExpanded: true,
                          items: AppConstants.pakistaniCities.map((city) {
                            return DropdownMenuItem<String>(
                              value: city,
                              child: Text(
                                city,
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (c) {
                            if (c != null) setState(() => _selectedCity = c);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          CustomTextField(
            label: 'Shop Address / Market Details',
            hint: 'e.g. Shop #12, Azam Cloth Market',
            controller: _addressCtrl,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            label: 'Opening Khata Balance (Rs.)',
            hint: '0',
            controller: _openingBalanceCtrl,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }
}
