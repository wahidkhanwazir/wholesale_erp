import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:wholesale_app/core/constants/app_colors.dart';
import 'package:wholesale_app/core/utils/currency_formatter.dart';
import 'package:wholesale_app/core/utils/date_formatter.dart';
import 'package:wholesale_app/core/widgets/app_dialog.dart';
import 'package:wholesale_app/core/widgets/custom_button.dart';
import 'package:wholesale_app/shared/models/enums.dart';
import '../../controllers/khata_controller.dart';
import '../../models/party_model.dart';
import '../../config/khata_strings.dart';

class PaymentDialog extends StatefulWidget {
  final PartyType type;
  final PartyModel? initialParty;

  const PaymentDialog({
    super.key,
    required this.type,
    this.initialParty,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _khataCtrl = Get.find<KhataController>();

  PartyModel? _selectedParty;
  final _amountCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final _amountFocusNode = FocusNode();
  final _partySearchController = TextEditingController();

  DateTime _paymentDate = DateTime.now();
  String _paymentMethodName = 'Cash';

  String? _partyError;
  String? _amountError;
  String? _generalError;
  bool _showOverpaymentWarning = false;
  double _overpaymentAdvanceAmount = 0.0;

  bool get isCustomer => widget.type == PartyType.customer;

  @override
  void initState() {
    super.initState();
    if (widget.initialParty != null) {
      _selectedParty = widget.initialParty;
      _partySearchController.text = _selectedParty!.name;
      if (_selectedParty!.balance > 0) {
        _amountCtrl.text = _selectedParty!.balance.toStringAsFixed(0);
      }
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _refCtrl.dispose();
    _notesCtrl.dispose();
    _partySearchController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  PaymentMethod _getMappedPaymentMethod() {
    switch (_paymentMethodName) {
      case 'Cheque':
        return PaymentMethod.cheque;
      case 'Bank Transfer':
      case 'JazzCash':
      case 'Easypaisa':
        return PaymentMethod.bank;
      case 'Cash':
      default:
        return PaymentMethod.cash;
    }
  }

  void _fillFullAmount() {
    if (_selectedParty != null && _selectedParty!.balance > 0) {
      _amountCtrl.text = _selectedParty!.balance.toStringAsFixed(0);
      setState(() => _amountError = null);
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate.isAfter(now) ? now : _paymentDate,
      firstDate: DateTime(2020),
      lastDate: now, // Rule 4: No future dates!
    );
    if (picked != null) {
      setState(() => _paymentDate = picked);
    }
  }

  void _submit() {
    setState(() {
      _partyError = null;
      _amountError = null;
      _generalError = null;
    });

    if (_selectedParty == null) {
      setState(() => _partyError = 'Please select a ${isCustomer ? "customer" : "supplier"} account.');
      return;
    }

    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _amountError = 'Enter a valid payment amount greater than 0.');
      _amountFocusNode.requestFocus();
      return;
    }

    // Rule 3: Check overpayment
    final currentBalance = _selectedParty!.balance;
    if (currentBalance > 0 && amount > currentBalance && !_showOverpaymentWarning) {
      final advanceAmt = amount - currentBalance;
      setState(() {
        _showOverpaymentWarning = true;
        _overpaymentAdvanceAmount = advanceAmt;
      });
      return;
    }

    final method = _getMappedPaymentMethod();
    final noteWithMethod = _paymentMethodName == 'JazzCash' || _paymentMethodName == 'Easypaisa'
        ? '$_paymentMethodName${_notesCtrl.text.trim().isNotEmpty ? " - ${_notesCtrl.text.trim()}" : ""}'
        : _notesCtrl.text.trim();

    if (isCustomer) {
      final res = _khataCtrl.customersCtrl.receivePaymentResult(
        customerId: _selectedParty!.id,
        amount: amount,
        method: method,
        date: _paymentDate,
        note: noteWithMethod,
        reference: _refCtrl.text.trim(),
      );

      if (res.success) {
        Get.back();
        Get.snackbar('Payment Recorded', res.message);
      } else {
        setState(() => _generalError = res.message);
      }
    } else {
      final res = _khataCtrl.suppliersCtrl.paySupplierResult(
        supplierId: _selectedParty!.id,
        amount: amount,
        method: method,
        date: _paymentDate,
        note: noteWithMethod,
        reference: _refCtrl.text.trim(),
      );

      if (res.success) {
        Get.back();
        Get.snackbar('Payment Recorded', res.message);
      } else {
        setState(() => _generalError = res.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleText = isCustomer ? KhataStrings.receivePayment : KhataStrings.paySupplier;
    final activeParties = isCustomer
        ? _khataCtrl.customersCtrl.customers.where((c) => c.isActive).map((c) => PartyModel.fromCustomer(c)).toList()
        : _khataCtrl.suppliersCtrl.suppliers.where((s) => s.isActive).map((s) => PartyModel.fromSupplier(s)).toList();

    return AppDialog(
      title: titleText,
      subtitle: isCustomer ? 'Record received cash/bank payment voucher and update running ledger' : 'Record bank/cash disbursement voucher to textile mill',
      maxWidth: 580,
      actions: [
        CustomButton(text: 'Cancel', isSecondary: true, onPressed: () => Get.back()),
        const SizedBox(width: 12),
        CustomButton(
          text: _showOverpaymentWarning ? 'Confirm & Save Advance' : 'Save Payment Voucher',
          icon: Icons.check_circle_outline,
          onPressed: _submit,
        ),
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

          // Overpayment Warning Banner (Rule 3)
          if (_showOverpaymentWarning) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFB74D)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Payment amount exceeds current balance! Rs. ${CurrencyFormatter.format(_overpaymentAdvanceAmount)} will become advance balance.',
                      style: const TextStyle(color: Color(0xFFE65100), fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Searchable Autocomplete Party Picker (Rule 4)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${isCustomer ? "Customer" : "Supplier / Mill"} Account *', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              Autocomplete<PartyModel>(
                displayStringForOption: (option) => '${option.name} (${option.city})',
                initialValue: TextEditingValue(text: _selectedParty != null ? '${_selectedParty!.name} (${_selectedParty!.city})' : ''),
                optionsBuilder: (textEditingValue) {
                  if (textEditingValue.text.isEmpty) return activeParties;
                  final q = textEditingValue.text.toLowerCase();
                  return activeParties.where((p) => p.name.toLowerCase().contains(q) || p.phone.toLowerCase().contains(q) || p.city.toLowerCase().contains(q));
                },
                onSelected: (party) {
                  setState(() {
                    _selectedParty = party;
                    _partyError = null;
                    _showOverpaymentWarning = false;
                    if (party.balance > 0) {
                      _amountCtrl.text = party.balance.toStringAsFixed(0);
                    }
                  });
                },
                fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                  return TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search by name, phone, city...',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      fillColor: AppColors.surface,
                      filled: true,
                      errorText: _partyError,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _partyError != null ? AppColors.error : AppColors.border)),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Current Balance Badge
          if (_selectedParty != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Current Outstanding Balance:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text(
                    CurrencyFormatter.format(_selectedParty!.balance.abs()),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _selectedParty!.balance > 0 ? AppColors.error : AppColors.success),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 14),

          // Amount Row with Full Amount Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Amount (Rs.) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        if (_selectedParty != null && _selectedParty!.balance > 0)
                          InkWell(
                            onTap: _fillFullAmount,
                            child: const Text('Full amount', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _amountCtrl,
                      focusNode: _amountFocusNode,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(fontSize: 13),
                      onChanged: (_) => setState(() => _showOverpaymentWarning = false),
                      decoration: InputDecoration(
                        hintText: 'e.g. 50000',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                        fillColor: AppColors.surface,
                        filled: true,
                        errorText: _amountError,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Date Picker
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Voucher Date *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(DateFormatter.formatDate(_paymentDate), style: const TextStyle(fontSize: 13)),
                            const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textMuted),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Payment Method & Reference
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Payment Method', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _paymentMethodName,
                          isExpanded: true,
                          items: ['Cash', 'Bank Transfer', 'Cheque', 'JazzCash', 'Easypaisa'].map((m) {
                            return DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13)));
                          }).toList(),
                          onChanged: (m) {
                            if (m != null) setState(() => _paymentMethodName = m);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cheque / Ref #', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _refCtrl,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g. MCB-98412',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                        fillColor: AppColors.surface,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Notes
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Voucher Note (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              TextField(
                controller: _notesCtrl,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. Cash collected directly in Shah Alam Market',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  fillColor: AppColors.surface,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
