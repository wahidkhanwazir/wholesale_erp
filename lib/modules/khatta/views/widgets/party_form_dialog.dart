import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:wholesale_app/core/constants/app_colors.dart';
import 'package:wholesale_app/core/constants/app_constants.dart';
import 'package:wholesale_app/core/widgets/app_dialog.dart';
import 'package:wholesale_app/core/widgets/custom_button.dart';
import 'package:wholesale_app/shared/models/enums.dart';
import '../../controllers/khata_controller.dart';
import '../../models/party_model.dart';
import '../../customers/models/customer_model.dart';
import '../../suppliers/models/supplier_model.dart';
import '../../customers/models/ledger_model.dart';

class PartyFormDialog extends StatefulWidget {
  final PartyType type;
  final PartyModel? existingParty;

  const PartyFormDialog({
    super.key,
    required this.type,
    this.existingParty,
  });

  @override
  State<PartyFormDialog> createState() => _PartyFormDialogState();
}

class _PartyFormDialogState extends State<PartyFormDialog> {
  final _khataCtrl = Get.find<KhataController>();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _openingBalCtrl = TextEditingController(text: '0');
  final _creditLimitOrDaysCtrl = TextEditingController();

  final _nameFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _addressFocusNode = FocusNode();
  final _openingBalFocusNode = FocusNode();
  final _creditFocusNode = FocusNode();

  String _selectedCity = 'Lahore';
  String _openingType = 'Dr'; // Dr (Lene hain) or Cr (Dene hain)

  String? _nameError;
  String? _phoneError;
  String? _openingError;
  String? _creditError;
  String? _generalError;

  bool get isEdit => widget.existingParty != null;
  bool get isCustomer => widget.type == PartyType.customer;

  @override
  void initState() {
    super.initState();
    _openingType = isCustomer ? 'Dr' : 'Cr';

    if (isEdit) {
      final p = widget.existingParty!;
      _nameCtrl.text = p.name;
      _phoneCtrl.text = p.phone;
      _addressCtrl.text = p.address;
      _selectedCity = p.city;
      _openingBalCtrl.text = p.openingBalance.toStringAsFixed(0);
      _openingType = p.openingBalanceType;

      if (isCustomer && p.creditLimit != null) {
        _creditLimitOrDaysCtrl.text = p.creditLimit!.toStringAsFixed(0);
      } else if (!isCustomer && p.creditDays != null) {
        _creditLimitOrDaysCtrl.text = p.creditDays!.toString();
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _openingBalCtrl.dispose();
    _creditLimitOrDaysCtrl.dispose();

    _nameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _addressFocusNode.dispose();
    _openingBalFocusNode.dispose();
    _creditFocusNode.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() {
      _nameError = null;
      _phoneError = null;
      _openingError = null;
      _creditError = null;
      _generalError = null;
    });

    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final address = _addressCtrl.text.trim();

    // Validation
    if (name.isEmpty) {
      setState(() => _nameError = 'Name is required');
      _nameFocusNode.requestFocus();
      return;
    }

    if (phone.isEmpty) {
      setState(() => _phoneError = 'Contact phone number is required');
      _phoneFocusNode.requestFocus();
      return;
    }

    // Pakistani phone format basic check
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleanPhone.length < 10) {
      setState(() => _phoneError = 'Enter a valid phone number (min 10 digits)');
      _phoneFocusNode.requestFocus();
      return;
    }

    final openingBal = double.tryParse(_openingBalCtrl.text.trim());
    if (openingBal == null) {
      setState(() => _openingError = 'Enter a valid numeric amount');
      _openingBalFocusNode.requestFocus();
      return;
    }

    double? creditLimit;
    int? creditDays;

    if (_creditLimitOrDaysCtrl.text.trim().isNotEmpty) {
      if (isCustomer) {
        creditLimit = double.tryParse(_creditLimitOrDaysCtrl.text.trim());
        if (creditLimit == null) {
          setState(() => _creditError = 'Enter valid credit limit amount');
          _creditFocusNode.requestFocus();
          return;
        }
      } else {
        creditDays = int.tryParse(_creditLimitOrDaysCtrl.text.trim());
        if (creditDays == null) {
          setState(() => _creditError = 'Enter valid credit days (integer)');
          _creditFocusNode.requestFocus();
          return;
        }
      }
    }

    // Check duplicate
    if (isCustomer) {
      final dup = _khataCtrl.customersCtrl.checkDuplicate(name, phone, excludeId: isEdit ? widget.existingParty!.id : null);
      if (dup.isDuplicate) {
        if (dup.field == 'name') {
          setState(() => _nameError = 'Customer name already exists.');
          _nameFocusNode.requestFocus();
        } else {
          setState(() => _phoneError = 'Phone number already registered.');
          _phoneFocusNode.requestFocus();
        }
        return;
      }
    } else {
      final dup = _khataCtrl.suppliersCtrl.checkDuplicate(name, phone, excludeId: isEdit ? widget.existingParty!.id : null);
      if (dup.isDuplicate) {
        if (dup.field == 'name') {
          setState(() => _nameError = 'Supplier name already exists.');
          _nameFocusNode.requestFocus();
        } else {
          setState(() => _phoneError = 'Phone number already registered.');
          _phoneFocusNode.requestFocus();
        }
        return;
      }
    }

    if (isEdit) {
      // Update existing party
      final existing = widget.existingParty!;
      if (isCustomer) {
        final updated = (existing.originalModel as CustomerModel).copyWith(
          name: name,
          phone: phone,
          city: _selectedCity,
          address: address,
          creditLimit: creditLimit,
        );
        final res = _khataCtrl.customersCtrl.updateCustomer(updated);
        if (res.success) {
          Get.back();
          Get.snackbar('Updated', res.message);
        } else {
          setState(() => _generalError = res.message);
        }
      } else {
        final updated = (existing.originalModel as SupplierModel).copyWith(
          name: name,
          phone: phone,
          city: _selectedCity,
          address: address,
          creditDays: creditDays,
        );
        final res = _khataCtrl.suppliersCtrl.updateSupplier(updated);
        if (res.success) {
          Get.back();
          Get.snackbar('Updated', res.message);
        } else {
          setState(() => _generalError = res.message);
        }
      }
    } else {
      // Create new party
      final nowMs = DateTime.now().microsecondsSinceEpoch;
      final newId = isCustomer ? 'CUST-${nowMs % 10000}' : 'SUPP-${nowMs % 10000}';

      final initialLedger = <LedgerTransaction>[];
      if (openingBal > 0) {
        final isDr = _openingType == 'Dr';
        initialLedger.add(
          LedgerTransaction(
            id: 'LED-OP-$newId',
            partyId: newId,
            partyType: widget.type,
            date: DateTime.now(),
            referenceType: 'Opening Balance',
            description: 'Opening Khata Balance Brought Forward',
            debit: isDr ? openingBal : 0.0,
            credit: isDr ? 0.0 : openingBal,
            runningBalance: isDr ? openingBal : -openingBal,
          ),
        );
      }

      if (isCustomer) {
        final cust = CustomerModel(
          id: newId,
          name: name,
          phone: phone,
          city: _selectedCity,
          address: address,
          totalPurchases: 0.0, // Opening balance does NOT count in total purchases/billed
          amountReceived: 0.0,
          outstandingBalance: _openingType == 'Dr' ? openingBal : -openingBal,
          ledger: initialLedger,
          creditLimit: creditLimit,
          openingBalance: openingBal,
          openingBalanceType: _openingType,
        );
        final res = _khataCtrl.customersCtrl.addCustomerResult(cust);
        if (res.success) {
          _khataCtrl.selectParty(newId);
          Get.back();
          Get.snackbar('Saved', res.message);
        } else {
          setState(() => _generalError = res.message);
        }
      } else {
        final supp = SupplierModel(
          id: newId,
          name: name,
          phone: phone,
          city: _selectedCity,
          address: address,
          totalPurchases: 0.0, // Opening balance does NOT count in total purchases/billed
          totalPaid: 0.0,
          outstandingPayable: _openingType == 'Cr' ? openingBal : -openingBal,
          ledger: initialLedger,
          creditDays: creditDays,
          openingBalance: openingBal,
          openingBalanceType: _openingType,
        );
        final res = _khataCtrl.suppliersCtrl.addSupplierResult(supp);
        if (res.success) {
          _khataCtrl.selectParty(newId);
          Get.back();
          Get.snackbar('Saved', res.message);
        } else {
          setState(() => _generalError = res.message);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleText = isEdit
        ? 'Edit ${isCustomer ? "Customer" : "Supplier"} Details'
        : 'Register New ${isCustomer ? "Customer Account" : "Mill / Supplier"}';

    return AppDialog(
      title: titleText,
      subtitle: isCustomer ? 'Enter shop name, contact phone & opening khata' : 'Enter textile mill details & opening payable',
      maxWidth: 580,
      actions: [
        CustomButton(text: 'Cancel', isSecondary: true, onPressed: () => Get.back()),
        const SizedBox(width: 12),
        CustomButton(text: 'Save Details', icon: Icons.check, onPressed: _submit),
      ],
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_generalError != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.error)),
              child: Text(_generalError!, style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 14),
          ],

          _buildField(
            label: '${isCustomer ? "Customer / Shop Name" : "Mill / Supplier Name"} *',
            hint: isCustomer ? 'e.g. Haji Bashir Garments' : 'e.g. Sadaqat Textile Mills',
            controller: _nameCtrl,
            focusNode: _nameFocusNode,
            errorText: _nameError,
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _buildField(
                  label: 'Phone Number *',
                  hint: 'e.g. +92 300 4567891',
                  controller: _phoneCtrl,
                  focusNode: _phoneFocusNode,
                  errorText: _phoneError,
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('City / Market', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: AppConstants.pakistaniCities.contains(_selectedCity) ? _selectedCity : AppConstants.pakistaniCities.first,
                          isExpanded: true,
                          items: AppConstants.pakistaniCities.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
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

          _buildField(
            label: 'Shop Address / Market Details',
            hint: 'e.g. Shop #14, Azam Cloth Market',
            controller: _addressCtrl,
            focusNode: _addressFocusNode,
          ),
          const SizedBox(height: 14),

          if (!isEdit) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: _buildField(
                    label: 'Opening Khata Balance (Rs.)',
                    hint: '0',
                    controller: _openingBalCtrl,
                    focusNode: _openingBalFocusNode,
                    errorText: _openingError,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Balance Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _openingType,
                            isExpanded: true,
                            items: [
                              DropdownMenuItem(value: 'Dr', child: Text(isCustomer ? 'Dr (Lene hain)' : 'Dr (Advance)', style: const TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'Cr', child: Text(isCustomer ? 'Cr (Advance)' : 'Cr (Dene hain)', style: const TextStyle(fontSize: 12))),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _openingType = v);
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
          ],

          _buildField(
            label: isCustomer ? 'Credit Limit (Rs. Optional)' : 'Credit Days (Days Optional)',
            hint: isCustomer ? 'e.g. 150000' : 'e.g. 30',
            controller: _creditLimitOrDaysCtrl,
            focusNode: _creditFocusNode,
            errorText: _creditError,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    String? errorText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            fillColor: AppColors.surface,
            filled: true,
            errorText: errorText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: errorText != null ? AppColors.error : AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: errorText != null ? AppColors.error : AppColors.primary, width: 2)),
          ),
        ),
      ],
    );
  }
}
