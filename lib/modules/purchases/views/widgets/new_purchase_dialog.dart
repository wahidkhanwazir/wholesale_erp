import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../khatta/suppliers/models/supplier_model.dart';
import '../../../inventory/models/product_model.dart';
import '../../models/purchase_model.dart';
import '../../../../shared/models/enums.dart';
import '../../../inventory/controllers/inventory_controller.dart';
import '../../../khatta/suppliers/controllers/suppliers_controller.dart';
import '../../controllers/purchases_controller.dart';

class NewPurchaseDialog extends StatefulWidget {
  const NewPurchaseDialog({super.key});

  @override
  State<NewPurchaseDialog> createState() => _NewPurchaseDialogState();
}

class _NewPurchaseDialogState extends State<NewPurchaseDialog> {
  final _purchasesCtrl = Get.find<PurchasesController>();
  final _inventoryCtrl = Get.find<InventoryController>();
  final _suppliersCtrl = Get.find<SuppliersController>();

  SupplierModel? _selectedSupplier;
  ProductModel? _selectedProduct;
  final _qtyCtrl = TextEditingController(text: '50');
  final _unitPriceCtrl = TextEditingController();
  final _discountCtrl = TextEditingController(text: '0');
  final _paidAmountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  PaymentMethod _paymentMethod = PaymentMethod.bank;
  final List<PurchaseItem> _cartItems = [];

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (_suppliersCtrl.suppliers.isNotEmpty) {
      _selectedSupplier = _suppliersCtrl.suppliers.first;
    }
    if (_inventoryCtrl.products.isNotEmpty) {
      _selectedProduct = _inventoryCtrl.products.first;
      _unitPriceCtrl.text = _selectedProduct!.purchasePrice.toStringAsFixed(0);
    }
    _recalculateTotals();
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _unitPriceCtrl.dispose();
    _discountCtrl.dispose();
    _paidAmountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _onProductChanged(ProductModel? product) {
    if (product == null) return;
    setState(() {
      _selectedProduct = product;
      _unitPriceCtrl.text = product.purchasePrice.toStringAsFixed(0);
    });
  }

  void _addItemToCart() {
    if (_selectedProduct == null) {
      setState(() => _errorMessage = 'Please select a product');
      return;
    }

    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    if (qty <= 0) {
      setState(() => _errorMessage = 'Quantity must be greater than 0');
      return;
    }

    final price =
        double.tryParse(_unitPriceCtrl.text.trim()) ??
        _selectedProduct!.purchasePrice;
    if (price <= 0) {
      setState(() => _errorMessage = 'Unit price must be positive');
      return;
    }

    setState(() {
      _errorMessage = null;
      _cartItems.add(
        PurchaseItem(
          productId: _selectedProduct!.id,
          productName: _selectedProduct!.name,
          productCode: _selectedProduct!.code,
          size: _selectedProduct!.size,
          color: _selectedProduct!.color,
          quantity: qty,
          unitPrice: price,
          total: qty * price,
        ),
      );
      _recalculateTotals();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _cartItems.removeAt(index);
      _recalculateTotals();
    });
  }

  double get _subtotal => _cartItems.fold(0.0, (sum, item) => sum + item.total);

  double get _discount => double.tryParse(_discountCtrl.text.trim()) ?? 0.0;

  double get _grandTotal => (_subtotal - _discount).clamp(0.0, double.infinity);

  double get _amountPaid {
    if (_paymentMethod == PaymentMethod.credit &&
        _paidAmountCtrl.text.trim().isEmpty) {
      return 0.0;
    }
    return double.tryParse(_paidAmountCtrl.text.trim()) ?? _grandTotal;
  }

  double get _remainingPayable =>
      (_grandTotal - _amountPaid).clamp(0.0, double.infinity);

  void _recalculateTotals() {
    if (_paymentMethod == PaymentMethod.credit) {
      if (_paidAmountCtrl.text.isEmpty) {
        _paidAmountCtrl.text = '0';
      }
    } else {
      _paidAmountCtrl.text = _grandTotal.toStringAsFixed(0);
    }
  }

  void _submitPurchase() {
    if (_selectedSupplier == null) {
      setState(() => _errorMessage = 'Please select a supplier');
      return;
    }

    if (_cartItems.isEmpty) {
      setState(
        () => _errorMessage = 'Please add at least one item to purchase bill',
      );
      return;
    }

    final discount = _discount;
    if (discount < 0 || discount > _subtotal) {
      setState(() => _errorMessage = 'Invalid discount amount');
      return;
    }

    final paid = double.tryParse(_paidAmountCtrl.text.trim()) ?? 0.0;
    if (paid < 0 || paid > _grandTotal) {
      setState(() => _errorMessage = 'Paid amount cannot exceed grand total');
      return;
    }

    PaymentStatus status = PaymentStatus.unpaid;
    if (paid >= _grandTotal) {
      status = PaymentStatus.paid;
    } else if (paid > 0) {
      status = PaymentStatus.partial;
    }

    final newPurchase = PurchaseModel(
      id: 'PUR-${DateTime.now().millisecondsSinceEpoch}',
      purchaseNumber: _purchasesCtrl.generatePurchaseNumber(),
      date: DateTime.now(),
      supplierId: _selectedSupplier!.id,
      supplierName: _selectedSupplier!.name,
      items: List.from(_cartItems),
      subtotal: _subtotal,
      discount: discount,
      grandTotal: _grandTotal,
      amountPaid: paid,
      remainingPayable: _grandTotal - paid,
      paymentStatus: status,
      paymentMethod: _paymentMethod,
      notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
    );

    _purchasesCtrl.createNewPurchase(newPurchase);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'Record Stock Purchase from Mill',
      subtitle: 'Add received inventory lot and record supplier payable',
      maxWidth: 780,
      actions: [
        CustomButton(
          text: 'Cancel',
          isSecondary: true,
          onPressed: () => Get.back(),
        ),
        const SizedBox(width: 12),
        CustomButton(
          text: 'Save Purchase & Receive Stock',
          icon: Icons.check_circle_outline,
          onPressed: _submitPurchase,
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
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 18,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 1. Supplier Selection
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Supplier (Textile Mill)',
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
                            setState(() => _selectedSupplier = s);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 4,
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
                                PaymentMethod.credit,
                              ].map((method) {
                                return DropdownMenuItem<PaymentMethod>(
                                  value: method,
                                  child: Text(
                                    method.displayName,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                );
                              }).toList(),
                          onChanged: (method) {
                            if (method != null) {
                              setState(() {
                                _paymentMethod = method;
                                _recalculateTotals();
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),

          // 2. Add Stock Items Section
          Row(
            children: [
              const Icon(
                Icons.add_box_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              const Text(
                'Receive Inventory Lot',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (_selectedProduct != null)
                Text(
                  'Current Stock: ${_selectedProduct!.stockQuantity} pcs',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Product Item',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<ProductModel>(
                          value: _selectedProduct,
                          isExpanded: true,
                          items: _inventoryCtrl.products.map((p) {
                            return DropdownMenuItem<ProductModel>(
                              value: p,
                              child: Text(
                                '${p.name} [${p.code}] (${p.size}/${p.color})',
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: _onProductChanged,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: CustomTextField(
                  label: 'Purchase Qty',
                  controller: _qtyCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: CustomTextField(
                  label: 'Cost Rate (Rs.)',
                  controller: _unitPriceCtrl,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: CustomButton(
                  text: 'Add Lot',
                  icon: Icons.add,
                  onPressed: _addItemToCart,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 3. Purchase Items Table
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  color: AppColors.background,
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          'Product Item',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Size / Color',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Qty',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Unit Cost',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      SizedBox(width: 32),
                    ],
                  ),
                ),
                if (_cartItems.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'No items added to bill yet.',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _cartItems.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Text(
                                '${item.productName} [${item.productCode}]',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${item.size} / ${item.color}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '+${item.quantity} pcs',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                CurrencyFormatter.format(item.unitPrice),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                CurrencyFormatter.format(item.total),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _removeItem(index),
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 16,
                                color: AppColors.error,
                              ),
                              splashRadius: 14,
                              tooltip: 'Remove',
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 4. Calculations Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Subtotal:',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(_subtotal),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Supplier Discount (Rs.):',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(
                      width: 140,
                      child: TextFormField(
                        controller: _discountCtrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (_) => setState(() => _recalculateTotals()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Grand Total:',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(_grandTotal),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Amount Paid (Rs.):',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(
                      width: 140,
                      child: TextFormField(
                        controller: _paidAmountCtrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Remaining Payable (Mill Credit):',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(_remainingPayable),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _remainingPayable > 0
                            ? AppColors.error
                            : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Notes
          CustomTextField(
            label: 'Consignment / Mill Bilty Notes (Optional)',
            hint: 'e.g. Received via Karachi Goods Bilty #4492',
            controller: _notesCtrl,
          ),
        ],
      ),
    );
  }
}
