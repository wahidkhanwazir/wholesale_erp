import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:wholesale_app/core/constants/app_colors.dart';
import 'package:wholesale_app/core/widgets/custom_button.dart';
import 'package:wholesale_app/shared/models/enums.dart';
import '../../models/party_model.dart';
import '../../customers/controllers/customers_controller.dart';
import '../../suppliers/controllers/suppliers_controller.dart';
import 'package:wholesale_app/modules/sales/models/sale_model.dart';
import 'package:wholesale_app/modules/purchases/models/purchase_model.dart';

class QuickBillDialog extends StatefulWidget {
  final PartyModel party;

  const QuickBillDialog({
    super.key,
    required this.party,
  });

  @override
  State<QuickBillDialog> createState() => _QuickBillDialogState();
}

class _QuickBillDialogState extends State<QuickBillDialog> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  late TextEditingController _billNoController;
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    final isCustomer = widget.party.type == PartyType.customer;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final defaultBillNo = isCustomer
        ? 'INV-${DateTime.now().year}-${(nowMs % 100).toString().padLeft(2, '0')}'
        : 'PUR-${DateTime.now().year}-${(nowMs % 100).toString().padLeft(2, '0')}';

    _billNoController = TextEditingController(text: defaultBillNo);
  }

  @override
  void dispose() {
    _billNoController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveBill() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      Get.snackbar(
        'Invalid Amount',
        'Please enter a valid amount greater than 0',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    final isCustomer = widget.party.type == PartyType.customer;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final billNo = _billNoController.text.trim().isNotEmpty
        ? _billNoController.text.trim()
        : (isCustomer ? 'INV-$nowMs' : 'PUR-$nowMs');
    final desc = _descriptionController.text.trim();

    if (isCustomer) {
      final sale = SaleModel(
        id: 'SALE-$nowMs',
        invoiceNumber: billNo,
        date: _selectedDate,
        customerId: widget.party.id,
        customerName: widget.party.name,
        items: [
          SaleItem(
            productId: 'CUSTOM',
            productName: desc.isNotEmpty ? desc : 'Khata Credit Sale',
            productCode: 'GEN',
            size: 'N/A',
            color: 'N/A',
            quantity: 1,
            unitPrice: amount,
            total: amount,
          ),
        ],
        subtotal: amount,
        discount: 0.0,
        grandTotal: amount,
        amountPaid: 0.0,
        remainingBalance: amount,
        paymentStatus: PaymentStatus.unpaid,
        paymentMethod: PaymentMethod.credit,
        notes: desc,
      );

      final customersCtrl = Get.find<CustomersController>();
      customersCtrl.addSaleToCustomer(sale);

      Get.back();
      Get.snackbar(
        'Sale Recorded',
        'New sale of Rs. ${amount.toStringAsFixed(0)} added for ${widget.party.name}. Bill #$billNo',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
      );
    } else {
      final purchase = PurchaseModel(
        id: 'PUR-$nowMs',
        purchaseNumber: billNo,
        date: _selectedDate,
        supplierId: widget.party.id,
        supplierName: widget.party.name,
        items: [
          PurchaseItem(
            productId: 'CUSTOM',
            productName: desc.isNotEmpty ? desc : 'Khata Purchase Bill',
            productCode: 'GEN',
            size: 'N/A',
            color: 'N/A',
            quantity: 1,
            unitPrice: amount,
            total: amount,
          ),
        ],
        subtotal: amount,
        discount: 0.0,
        grandTotal: amount,
        amountPaid: 0.0,
        remainingPayable: amount,
        paymentStatus: PaymentStatus.unpaid,
        paymentMethod: PaymentMethod.credit,
        notes: desc,
      );

      final suppliersCtrl = Get.find<SuppliersController>();
      suppliersCtrl.addPurchaseToSupplier(purchase);

      Get.back();
      Get.snackbar(
        'Purchase Recorded',
        'New purchase of Rs. ${amount.toStringAsFixed(0)} recorded for ${widget.party.name}. Bill #$billNo',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCustomer = widget.party.type == PartyType.customer;
    final dialogTitle = isCustomer
        ? 'New Sale – ${widget.party.name}'
        : 'New Purchase – ${widget.party.name}';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Text(
                dialogTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 20),

              // Row 1: Date & Bill No
              Row(
                children: [
                  // Date Field
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Date',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('MM/dd/yyyy').format(_selectedDate),
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Bill No Field
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bill no',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 44,
                          child: TextFormField(
                            controller: _billNoController,
                            style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Row 2: Description
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 44,
                    child: TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        hintText: isCustomer ? 'e.g. Lawn suits sale on credit' : 'e.g. Fabric purchase',
                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Row 3: Amount (Rs.) *
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Amount (Rs.) *',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Enter bill amount';
                      if ((double.tryParse(val.trim()) ?? 0) <= 0) return 'Amount must be > 0';
                      return null;
                    },
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      hintText: '0',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Bottom Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Cancel Button
                  OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Save Button
                  CustomButton(
                    text: 'Save',
                    onPressed: _saveBill,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
