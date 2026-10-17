import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/desktop_layout.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../controllers/inventory_controller.dart';
import 'widgets/add_edit_product_dialog.dart';

class InventoryView extends GetView<InventoryController> {
  const InventoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return DesktopLayout(
      currentRoute: AppRoutes.inventory,
      title: AppStrings.navInventory,
      subtitle:
          'Wholesale garments stock list, sizes, colors, and inventory levels',
      headerActions: [
        CustomButton(
          text: AppStrings.addProduct,
          icon: Icons.add_rounded,
          onPressed: () {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => const AddEditProductDialog(),
            );
          },
        ),
      ],
      child: Obx(() {
        final productList = controller.filteredProducts;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search & Filters Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    // Search
                    Expanded(
                      flex: 4,
                      child: TextField(
                        onChanged: (val) => controller.searchQuery.value = val,
                        decoration: const InputDecoration(
                          hintText:
                              'Search product name, code (e.g. JNS-101)...',
                          prefixIcon: Icon(
                            Icons.search,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Category Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: controller.selectedCategory.value,
                          items: AppConstants.garmentCategories.map((c) {
                            return DropdownMenuItem<String>(
                              value: c,
                              child: Text(
                                c,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (c) {
                            if (c != null) {
                              controller.selectedCategory.value = c;
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Low Stock Filter Toggle
                    FilterChip(
                      selected: controller.onlyLowStock.value,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 14,
                            color: controller.onlyLowStock.value
                                ? Colors.white
                                : AppColors.warning,
                          ),
                          const SizedBox(width: 6),
                          const Text('Low Stock Alerts Only'),
                        ],
                      ),
                      selectedColor: AppColors.warning,
                      backgroundColor: AppColors.background,
                      labelStyle: TextStyle(
                        color: controller.onlyLowStock.value
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (val) {
                        controller.onlyLowStock.value = val;
                      },
                    ),

                    const Spacer(),

                    // Catalog Stats Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Total Value: ${CurrencyFormatter.format(controller.totalInventoryValue)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Inventory Table
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                        border: Border(
                          bottom: BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text('Code', style: _headerStyle),
                          ),
                          Expanded(
                            flex: 5,
                            child: Text('Product Item', style: _headerStyle),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text('Category', style: _headerStyle),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('Size / Color', style: _headerStyle),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('Cost Price', style: _headerStyle),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('Sale Price', style: _headerStyle),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('Stock Qty', style: _headerStyle),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('Status', style: _headerStyle),
                          ),
                          SizedBox(
                            width: 70,
                            child: Text(
                              'Action',
                              style: _headerStyle,
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (productList.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            'No inventory items found matching criteria.',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: productList.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final product = productList[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    product.code,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 5,
                                  child: Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    product.category,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '${product.size} / ${product.color}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    CurrencyFormatter.format(
                                      product.purchasePrice,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    CurrencyFormatter.format(product.salePrice),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '${product.stockQuantity} pcs',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: product.isLowStock
                                          ? AppColors.error
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: StatusBadge.fromStockStatus(
                                      product.stockStatus,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 70,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                      tooltip: 'Edit Product',
                                      splashRadius: 16,
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (ctx) =>
                                              AddEditProductDialog(
                                                productToEdit: product,
                                              ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
    letterSpacing: 0.2,
  );
}
