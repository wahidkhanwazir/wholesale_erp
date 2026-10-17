import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/desktop_layout.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../controllers/sales_controller.dart';
import 'widgets/new_sale_dialog.dart';
import 'widgets/sale_detail_dialog.dart';

class SalesView extends GetView<SalesController> {
  const SalesView({super.key});

  @override
  Widget build(BuildContext context) {
    return DesktopLayout(
      currentRoute: AppRoutes.sales,
      title: AppStrings.navSales,
      subtitle: 'Wholesale sales ledger, dispatch invoices, and credit billing',
      headerActions: [
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
        final salesList = controller.filteredSales;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search & Filter Toolbar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    // Search field
                    Expanded(
                      flex: 4,
                      child: TextField(
                        onChanged: (val) => controller.searchQuery.value = val,
                        decoration: const InputDecoration(
                          hintText: 'Search by Invoice # or Customer name...',
                          prefixIcon: Icon(
                            Icons.search,
                            size: 20,
                            color: AppColors.textMuted,
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Status Filter Tabs
                    Expanded(
                      flex: 6,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text(
                            'Status Filter:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ...['All', 'Paid', 'Partial', 'Unpaid'].map((status) {
                            final isSelected =
                                controller.statusFilter.value.toLowerCase() ==
                                status.toLowerCase();
                            return Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: ChoiceChip(
                                label: Text(status),
                                selected: isSelected,
                                selectedColor: AppColors.primary,
                                backgroundColor: AppColors.background,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                onSelected: (_) {
                                  controller.statusFilter.value = status;
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Sales Data Table
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
                            flex: 3,
                            child: Text('Invoice #', style: _headerStyle),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text('Date', style: _headerStyle),
                          ),
                          Expanded(
                            flex: 4,
                            child: Text('Customer', style: _headerStyle),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('Items', style: _headerStyle),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text('Total Amount', style: _headerStyle),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text('Paid Amount', style: _headerStyle),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text('Remaining Due', style: _headerStyle),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text('Status', style: _headerStyle),
                          ),
                          SizedBox(
                            width: 80,
                            child: Text(
                              'Actions',
                              style: _headerStyle,
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (salesList.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            'No sales found matching criteria.',
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
                        itemCount: salesList.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final sale = salesList[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    sale.invoiceNumber,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    DateFormatter.formatDate(sale.date),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    sale.customerName,
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
                                  flex: 2,
                                  child: Text(
                                    '${sale.totalItemCount} pcs',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    CurrencyFormatter.format(sale.grandTotal),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    CurrencyFormatter.format(sale.amountPaid),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    CurrencyFormatter.format(
                                      sale.remainingBalance,
                                    ),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: sale.remainingBalance > 0
                                          ? AppColors.error
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: StatusBadge.fromPaymentStatus(
                                      sale.paymentStatus,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 80,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: OutlinedButton(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) =>
                                              SaleDetailDialog(sale: sale),
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'View',
                                        style: TextStyle(fontSize: 11),
                                      ),
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
