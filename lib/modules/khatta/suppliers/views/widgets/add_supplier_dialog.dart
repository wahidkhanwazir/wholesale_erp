import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wholesale_app/core/constants/app_colors.dart';
import 'package:wholesale_app/core/constants/app_constants.dart';
import 'package:wholesale_app/core/widgets/app_dialog.dart';
import 'package:wholesale_app/core/widgets/custom_button.dart';
import 'package:wholesale_app/core/widgets/custom_text_field.dart';
import '../../models/supplier_model.dart';
import '../../models/ledger_model.dart';
import 'package:wholesale_app/shared/models/enums.dart';
import '../../controllers/suppliers_controller.dart';

class AddSupplierDialog extends StatefulWidget {
  const AddSupplierDialog({super.key});

  @override
  State<AddSupplierDialog> createState() => _AddSupplierDialogState();
}

class _AddSupplierDialogState extends State<AddSupplierDialog> {
  final _suppliersCtrl = Get.find<SuppliersController>();

  final _nameCtrl = TextEditingController();
  final _contactPersonCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _openingPayableCtrl = TextEditingController(text: '0');

  String _selectedCity = 'Faisalabad';
  String? _errorMessage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactPersonCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _openingPayableCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final contactPerson = _contactPersonCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final openingBal = double.tryParse(_openingPayableCtrl.text.trim()) ?? 0.0;

    if (name.isEmpty) {
      setState(
        () => _errorMessage = 'Supplier / Textile Mill name is required',
      );
      return;
    }

    if (phone.isEmpty) {
      setState(() => _errorMessage = 'Contact phone/WhatsApp number is required');
      return;
    }

    final newId = 'SUPP-${DateTime.now().millisecondsSinceEpoch % 10000}';
    final initialLedger = <LedgerTransaction>[];

    if (openingBal > 0) {
      initialLedger.add(
        LedgerTransaction(
          id: 'LED-OP-$newId',
          partyId: newId,
          partyType: PartyType.supplier,
          date: DateTime.now(),
          referenceType: 'Opening Balance',
          description: 'Previous Mill Outstanding Payable Brought Forward',
          debit: 0.0,
          credit: openingBal,
          runningBalance: openingBal,
        ),
      );
    }

    final supplier = SupplierModel(
      id: newId,
      name: name,
      contactPerson: contactPerson,
      phone: phone,
      city: _selectedCity,
      address: address,
      totalPurchases: openingBal,
      totalPaid: 0.0,
      outstandingPayable: openingBal,
      ledger: initialLedger,
    );

    _suppliersCtrl.addSupplier(supplier);
    Get.back(result: supplier);
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'Register New Textile Mill / Supplier',
      subtitle: 'Add fabric mill or wholesale supplier with required details',
      maxWidth: 580,
      actions: [
        CustomButton(
          text: 'Cancel',
          isSecondary: true,
          onPressed: () => Get.back(),
        ),
        const SizedBox(width: 12),
        CustomButton(
          text: 'Save Supplier',
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

          // Mill / Supplier Name
          CustomTextField(
            label: 'Mill / Supplier Business Name *',
            hint: 'e.g. Master Textile Mills',
            controller: _nameCtrl,
          ),
          const SizedBox(height: 14),

          // Contact Person
          CustomTextField(
            label: 'Contact Person / Mill Representative',
            hint: 'e.g. Tariq Mahmood (Sales Manager)',
            controller: _contactPersonCtrl,
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Phone / WhatsApp *',
                  hint: 'e.g. +92 41 8765432',
                  controller: _phoneCtrl,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'City / Industrial Hub',
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
            label: 'Mill / Factory Address',
            hint: 'e.g. Plot #45, Industrial Estate, Faisalabad',
            controller: _addressCtrl,
          ),
          const SizedBox(height: 14),

          CustomTextField(
            label: 'Opening Payable Balance (Rs.)',
            hint: '0',
            controller: _openingPayableCtrl,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }
}
