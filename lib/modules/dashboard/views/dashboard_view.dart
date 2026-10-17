import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/desktop_layout.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/custom_button.dart';
import '../controllers/dashboard_controller.dart';
import 'widgets/sales_mini_chart.dart';
import '../../sales/views/widgets/new_sale_dialog.dart';
import '../../purchases/views/widgets/new_purchase_dialog.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return DesktopLayout(
      currentRoute: AppRoutes.dashboard,
      title: AppStrings.navDashboard,
      subtitle: 'Overview of wholesale operations, liquidity, and inventory',
      headerActions: [
        CustomButton(
          text: AppStrings.newPurchase,
          icon: Icons.add_shopping_cart_rounded,
          isSecondary: true,
          onPressed: () {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => const NewPurchaseDialog(),
            );
          },
        ),
        const SizedBox(width: 10),
        CustomButton(
          text: AppStrings.newSale,
          icon: Icons.add_rounded,
          onPressed: () {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => const NewSaleDialog(),
            );
          },
        ),
      ],
      child: Obx(() {
        final todaySales = controller.todaySales;
        final todayPurchases = controller.todayPurchases;
        final receivables = controller.customerReceivables;
        final payables = controller.supplierPayables;
        final totalProducts = controller.totalProducts;
        final lowStockCount = controller.lowStockCount;

        final recentSales = controller.recentSales;
        final recentPurchases = controller.recentPurchases;
        final lowStockProducts = controller.lowStockProducts;
        final weeklySalesData = controller.weeklySalesData;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 6 Summary Metrics Cards (Grid of 6)
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 3;
                  if (constraints.maxWidth >= 1200) {
                    crossAxisCount = 6;
                  } else if (constraints.maxWidth < 650) {
                    crossAxisCount = 2;
                  }

                  const double spacing = 12.0;
                  final double totalSpacing = (crossAxisCount - 1) * spacing;
                  final double cardWidth =
                      (constraints.maxWidth - totalSpacing) / crossAxisCount;
                  const double targetCardHeight = 92.0;
                  final double childAspectRatio = cardWidth / targetCardHeight;

                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    childAspectRatio: childAspectRatio,
                    children: [
                      StatCard(
                        title: "Today's Sales",
                        value: CurrencyFormatter.format(todaySales),
                        icon: Icons.point_of_sale_rounded,
                        iconColor: AppColors.primary,
                        iconBgColor: AppColors.accentLight,
                        subtitle: 'Calculated today',
                      ),
                      StatCard(
                        title: "Today's Purchases",
                        value: CurrencyFormatter.format(todayPurchases),
                        icon: Icons.shopping_bag_outlined,
                        iconColor: AppColors.secondary,
                        iconBgColor: const Color(0xFFE8F5E9),
                        subtitle: 'Inventory receipt',
                      ),
                      StatCard(
                        title: 'Customer Receivables',
                        value: CurrencyFormatter.format(receivables),
                        icon: Icons.account_balance_wallet_outlined,
                        iconColor: AppColors.warning,
                        iconBgColor: AppColors.warningLight,
                        subtitle: 'Outstanding Khata',
                        subtitleColor: AppColors.warning,
                      ),
                      StatCard(
                        title: 'Supplier Payables',
                        value: CurrencyFormatter.format(payables),
                        icon: Icons.assignment_late_outlined,
                        iconColor: AppColors.error,
                        iconBgColor: AppColors.errorLight,
                        subtitle: 'Due to mills / suppliers',
                        subtitleColor: AppColors.error,
                      ),
                      StatCard(
                        title: 'Total Products',
                        value: '$totalProducts SKUs',
                        icon: Icons.category_outlined,
                        iconColor: AppColors.info,
                        iconBgColor: AppColors.infoLight,
                        subtitle: 'In wholesale catalog',
                      ),
                      StatCard(
                        title: 'Low Stock Items',
                        value: '$lowStockCount Items',
                        icon: Icons.warning_amber_rounded,
                        iconColor: lowStockCount > 0
                            ? AppColors.error
                            : AppColors.success,
                        iconBgColor: lowStockCount > 0
                            ? AppColors.errorLight
                            : AppColors.successLight,
                        subtitle: lowStockCount > 0
                            ? 'Requires re-ordering'
                            : 'Stock level healthy',
                        subtitleColor: lowStockCount > 0
                            ? AppColors.error
                            : AppColors.success,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),

              // Middle Section: Weekly Chart + Low Stock Alert Box
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: SalesMiniChart(data: weeklySalesData),
                  ),
                  const SizedBox(width: 16),
                  Expanded(flex: 4, child: _buildLowStockBox(lowStockProducts)),
                ],
              ),

              const SizedBox(height: 16),

              // Bottom Section: Recent Sales + Recent Purchases Tables
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recent Sales Table
                  Expanded(flex: 5, child: _buildRecentSalesTable(recentSales)),
                  const SizedBox(width: 16),
                  // Recent Purchases Table
                  Expanded(
                    flex: 5,
                    child: _buildRecentPurchasesTable(recentPurchases),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildLowStockBox(List lowStockProducts) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Low Stock Warning',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => Get.offNamed(AppRoutes.inventory),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (lowStockProducts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'All items are adequately stocked.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: lowStockProducts.take(4).length,
              separatorBuilder: (_, _) => const Divider(height: 14),
              itemBuilder: (context, index) {
                final product = lowStockProducts[index];
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${product.code} • ${product.size} / ${product.color}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${product.stockQuantity} left',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRecentSalesTable(List recentSales) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Recent Sales',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () => Get.offNamed(AppRoutes.sales),
                child: const Text(
                  'View All Sales',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (recentSales.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No sales recorded yet.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 440),
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2.5),
                    1: FlexColumnWidth(3),
                    2: FlexColumnWidth(2.2),
                    3: FlexColumnWidth(1.8),
                  },
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.border),
                        ),
                      ),
                      children: [
                        Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Invoice',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Customer',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Amount',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ...recentSales.map((sale) {
                      return TableRow(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AppColors.borderLight),
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              sale.invoiceNumber,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              sale.customerName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              CurrencyFormatter.format(sale.grandTotal),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: StatusBadge.fromPaymentStatus(
                              sale.paymentStatus,
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentPurchasesTable(List recentPurchases) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Recent Purchases',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () => Get.offNamed(AppRoutes.purchases),
                child: const Text(
                  'View All Purchases',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (recentPurchases.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No purchases recorded yet.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 440),
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2.5),
                    1: FlexColumnWidth(3),
                    2: FlexColumnWidth(2.2),
                    3: FlexColumnWidth(1.8),
                  },
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.border),
                        ),
                      ),
                      children: [
                        Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Bill #',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Supplier',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Amount',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ...recentPurchases.map((purchase) {
                      return TableRow(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AppColors.borderLight),
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              purchase.purchaseNumber,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              purchase.supplierName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              CurrencyFormatter.format(purchase.grandTotal),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: StatusBadge.fromPaymentStatus(
                              purchase.paymentStatus,
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
