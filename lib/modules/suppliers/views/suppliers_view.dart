import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/desktop_layout.dart';
import '../../../core/widgets/custom_button.dart';
import '../controllers/suppliers_controller.dart';
import 'widgets/add_supplier_dialog.dart';
import 'widgets/pay_supplier_dialog.dart';
import 'supplier_ledger_view.dart';

class SuppliersView extends GetView<SuppliersController> {
  const SuppliersView({super.key});

  @override
  Widget build(BuildContext context) {
    return DesktopLayout(
      currentRoute: AppRoutes.suppliers,
      title: AppStrings.navSuppliers,
      subtitle:
          'Textile mills directory, fabric suppliers, and accounts payable ledger',
      headerActions: [
        CustomButton(
          text: AppStrings.paySupplier,
          icon: Icons.payments_outlined,
          isSecondary: true,
          onPressed: () {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => PaySupplierDialog(
                initialSupplier: controller.selectedSupplier.value,
              ),
            );
          },
        ),
        const SizedBox(width: 10),
        CustomButton(
          text: AppStrings.addSupplier,
          icon: Icons.domain_add_outlined,
          onPressed: () {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => const AddSupplierDialog(),
            );
          },
        ),
      ],
      child: Obx(() {
        final supplierList = controller.filteredSuppliers;
        final selected =
            controller.selectedSupplier.value ??
            (supplierList.isNotEmpty ? supplierList.first : null);

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Panel: Supplier Directory List (38%)
              Expanded(
                flex: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      // Search Box
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: TextField(
                          onChanged: (val) =>
                              controller.searchQuery.value = val,
                          decoration: const InputDecoration(
                            hintText: 'Search mill name, city, phone...',
                            prefixIcon: Icon(
                              Icons.search,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                      const Divider(height: 1),

                      // Supplier List Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        color: AppColors.background,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'SUPPLIERS (${supplierList.length})',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Text(
                              'NET PAYABLE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Supplier List
                      Expanded(
                        child: supplierList.isEmpty
                            ? const Center(
                                child: Text(
                                  'No suppliers found.',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: supplierList.length,
                                separatorBuilder: (_, _) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final supplier = supplierList[index];
                                  final isSelected =
                                      selected?.id == supplier.id;

                                  return Material(
                                    color: isSelected
                                        ? AppColors.accentLight.withValues(
                                            alpha: 0.5,
                                          )
                                        : Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        controller.selectSupplier(supplier);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          border: isSelected
                                              ? const Border(
                                                  left: BorderSide(
                                                    color: AppColors.secondary,
                                                    width: 4,
                                                  ),
                                                )
                                              : null,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    supplier.name,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: isSelected
                                                          ? FontWeight.w700
                                                          : FontWeight.w600,
                                                      color:
                                                          AppColors.textPrimary,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    '${supplier.city} • ${supplier.phone}',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  CurrencyFormatter.format(
                                                    supplier.outstandingPayable,
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        supplier.outstandingPayable >
                                                            0
                                                        ? AppColors.error
                                                        : AppColors.success,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  supplier.outstandingPayable >
                                                          0
                                                      ? 'Due to Mill'
                                                      : 'Cleared',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        supplier.outstandingPayable >
                                                            0
                                                        ? AppColors.error
                                                        : AppColors.success,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // Right Panel: Supplier Ledger Statement (62%)
              Expanded(
                flex: 6,
                child: selected != null
                    ? SingleChildScrollView(
                        child: SupplierLedgerView(supplier: selected),
                      )
                    : Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Center(
                          child: Text(
                            'Select a supplier to view their running ledger.',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
