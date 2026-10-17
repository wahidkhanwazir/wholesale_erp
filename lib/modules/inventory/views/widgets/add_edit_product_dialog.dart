import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../models/product_model.dart';
import '../../controllers/inventory_controller.dart';
import '../../../dashboard/controllers/dashboard_controller.dart';

class AddEditProductDialog extends StatefulWidget {
  final ProductModel? productToEdit;

  const AddEditProductDialog({super.key, this.productToEdit});

  @override
  State<AddEditProductDialog> createState() => _AddEditProductDialogState();
}

class _AddEditProductDialogState extends State<AddEditProductDialog> {
  final _inventoryCtrl = Get.find<InventoryController>();

  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _purchasePriceCtrl = TextEditingController();
  final _salePriceCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '50');
  final _thresholdCtrl = TextEditingController(text: '15');

  String _selectedCategory = 'Denim Jeans';
  String _selectedSize = '32';
  String _selectedColor = 'Navy Blue';
  String? _errorMessage;

  bool get _isEditing => widget.productToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final p = widget.productToEdit!;
      _nameCtrl.text = p.name;
      _codeCtrl.text = p.code;
      _purchasePriceCtrl.text = p.purchasePrice.toStringAsFixed(0);
      _salePriceCtrl.text = p.salePrice.toStringAsFixed(0);
      _qtyCtrl.text = p.stockQuantity.toString();
      _thresholdCtrl.text = p.lowStockThreshold.toString();
      _selectedCategory = p.category;
      _selectedSize = p.size;
      _selectedColor = p.color;
    } else {
      _codeCtrl.text = _inventoryCtrl.generateProductCode(_selectedCategory);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _purchasePriceCtrl.dispose();
    _salePriceCtrl.dispose();
    _qtyCtrl.dispose();
    _thresholdCtrl.dispose();
    super.dispose();
  }

  void _onCategoryChanged(String? category) {
    if (category == null) return;
    setState(() {
      _selectedCategory = category;
      if (!_isEditing) {
        _codeCtrl.text = _inventoryCtrl.generateProductCode(category);
      }
    });
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    final purchasePrice =
        double.tryParse(_purchasePriceCtrl.text.trim()) ?? 0.0;
    final salePrice = double.tryParse(_salePriceCtrl.text.trim()) ?? 0.0;
    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    final threshold = int.tryParse(_thresholdCtrl.text.trim()) ?? 15;

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Product name is required');
      return;
    }

    if (code.isEmpty) {
      setState(() => _errorMessage = 'Product code is required');
      return;
    }

    if (purchasePrice <= 0) {
      setState(() => _errorMessage = 'Purchase cost must be greater than 0');
      return;
    }

    if (salePrice <= 0) {
      setState(
        () => _errorMessage = 'Wholesale sale price must be greater than 0',
      );
      return;
    }

    if (qty < 0) {
      setState(() => _errorMessage = 'Stock quantity cannot be negative');
      return;
    }

    if (_isEditing) {
      final updated = widget.productToEdit!.copyWith(
        name: name,
        code: code,
        category: _selectedCategory,
        size: _selectedSize,
        color: _selectedColor,
        purchasePrice: purchasePrice,
        salePrice: salePrice,
        stockQuantity: qty,
        lowStockThreshold: threshold,
      );
      _inventoryCtrl.updateProduct(updated);
    } else {
      final newProduct = ProductModel(
        id: 'PROD-${DateTime.now().millisecondsSinceEpoch % 10000}',
        name: name,
        code: code,
        category: _selectedCategory,
        size: _selectedSize,
        color: _selectedColor,
        purchasePrice: purchasePrice,
        salePrice: salePrice,
        stockQuantity: qty,
        lowStockThreshold: threshold,
      );
      _inventoryCtrl.addProduct(newProduct);
    }

    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().refreshData();
    }

    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: _isEditing ? 'Edit Garment Product' : 'Add New Garment Item',
      subtitle: _isEditing
          ? 'Update product specs, wholesale prices, or stock counts'
          : 'Create a new stock keeping unit in wholesale catalog',
      maxWidth: 640,
      actions: [
        CustomButton(
          text: 'Cancel',
          isSecondary: true,
          onPressed: () => Get.back(),
        ),
        const SizedBox(width: 12),
        CustomButton(
          text: _isEditing ? 'Save Changes' : 'Save Product',
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
          Row(
            children: [
              Expanded(
                flex: 6,
                child: CustomTextField(
                  label: 'Garment Product Name *',
                  hint: 'e.g. Mens Stretch Slim Jeans',
                  controller: _nameCtrl,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: CustomTextField(
                  label: 'SKU / Barcode Code *',
                  hint: 'e.g. JNS-104',
                  controller: _codeCtrl,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Category
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Category',
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
                          value: _selectedCategory,
                          isExpanded: true,
                          items: AppConstants.garmentCategories
                              .where((c) => c != 'All Categories')
                              .map((c) {
                                return DropdownMenuItem<String>(
                                  value: c,
                                  child: Text(
                                    c,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                );
                              })
                              .toList(),
                          onChanged: _onCategoryChanged,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Size
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Size',
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
                          value: _selectedSize,
                          isExpanded: true,
                          items: AppConstants.garmentSizes.map((s) {
                            return DropdownMenuItem<String>(
                              value: s,
                              child: Text(
                                s,
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (s) {
                            if (s != null) setState(() => _selectedSize = s);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Color
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Color',
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
                          value: _selectedColor,
                          isExpanded: true,
                          items: AppConstants.garmentColors.map((color) {
                            return DropdownMenuItem<String>(
                              value: color,
                              child: Text(
                                color,
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (color) {
                            if (color != null) {
                              setState(() => _selectedColor = color);
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Purchase Cost (Rs.) *',
                  hint: 'e.g. 1100',
                  controller: _purchasePriceCtrl,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  label: 'Wholesale Sale Price (Rs.) *',
                  hint: 'e.g. 1650',
                  controller: _salePriceCtrl,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Stock Quantity (pcs) *',
                  controller: _qtyCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  label: 'Low Stock Alert Threshold',
                  controller: _thresholdCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
