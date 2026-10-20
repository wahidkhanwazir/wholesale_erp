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
import 'widgets/print_sale_invoice_dialog.dart';
import 'package:wholesale_app/modules/khatta/customers/views/widgets/add_customer_dialog.dart';

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
          text: 'Add Seller',
          icon: Icons.person_add_alt_1_outlined,
          isSecondary: true,
          onPressed: () {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => const AddCustomerDialog(),
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
        final salesList = controller.filteredSales;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search & Filter Toolbar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Search field
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 200, maxWidth: 280),
                      child: SizedBox(
                        height: 38,
                        child: TextField(
                          onChanged: (val) => controller.searchQuery.value = val,
                          decoration: InputDecoration(
                            hintText: 'Search invoice or customer...',
                            hintStyle: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            isDense: true,
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Customer Filter Dropdown
                    PopupMenuButton<String>(
                      tooltip: '',
                      color: const Color(0xFF334155),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Color(0xFF475569)),
                      ),
                      elevation: 8,
                      offset: const Offset(0, 42),
                      onSelected: (val) {
                        controller.customerFilter.value = val;
                      },
                      itemBuilder: (context) {
                        return controller.availableCustomerNames.map((name) {
                          final isSelected = controller.customerFilter.value
                                  .toLowerCase() ==
                              name.toLowerCase();
                          final label = name == 'All' ? 'Customer: All' : name;
                          return PopupMenuItem<String>(
                            value: name,
                            height: 38,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 18,
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                      : const SizedBox.shrink(),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList();
                      },
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: controller.customerFilter.value != 'All'
                                ? AppColors.primary
                                : AppColors.border,
                            width: controller.customerFilter.value != 'All'
                                ? 1.5
                                : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              controller.customerFilter.value == 'All'
                                  ? 'Customer: All'
                                  : 'Customer: ${controller.customerFilter.value}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: controller.customerFilter.value != 'All'
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: controller.customerFilter.value != 'All'
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Status Filter Dropdown
                    PopupMenuButton<String>(
                      tooltip: '',
                      color: const Color(0xFF334155),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Color(0xFF475569)),
                      ),
                      elevation: 8,
                      offset: const Offset(0, 42),
                      onSelected: (val) {
                        controller.statusFilter.value = val;
                      },
                      itemBuilder: (context) {
                        const statuses = [
                          'All',
                          'Paid',
                          'Partially Paid',
                          'Unpaid'
                        ];
                        return statuses.map((status) {
                          final isSelected = controller.statusFilter.value
                                      .toLowerCase() ==
                                  status.toLowerCase() ||
                              (status == 'Partially Paid' &&
                                  controller.statusFilter.value
                                          .toLowerCase() ==
                                      'partial');
                          final label =
                              status == 'All' ? 'Status: All' : status;
                          return PopupMenuItem<String>(
                            value: status,
                            height: 38,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 18,
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                      : const SizedBox.shrink(),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList();
                      },
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: controller.statusFilter.value != 'All'
                                ? AppColors.primary
                                : AppColors.border,
                            width: controller.statusFilter.value != 'All'
                                ? 1.5
                                : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              controller.statusFilter.value == 'All'
                                  ? 'Status: All'
                                  : 'Status: ${controller.statusFilter.value}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: controller.statusFilter.value != 'All'
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: controller.statusFilter.value != 'All'
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Custom Date Range filter
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Start Date
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate:
                                  controller.startDate.value ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              controller.startDate.value = picked;
                            }
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: controller.startDate.value != null
                                    ? AppColors.primary
                                    : AppColors.border,
                                width:
                                    controller.startDate.value != null ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  controller.startDate.value != null
                                      ? DateFormatter.formatNumeric(
                                          controller.startDate.value!,
                                        )
                                      : 'dd/mm/yyyy',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: controller.startDate.value != null
                                        ? AppColors.textPrimary
                                        : AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 14,
                                  color: AppColors.textMuted,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'to',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),

                        // End Date
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: controller.endDate.value ??
                                  (controller.startDate.value ??
                                      DateTime.now()),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              controller.endDate.value = picked;
                            }
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: controller.endDate.value != null
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: controller.endDate.value != null ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  controller.endDate.value != null
                                      ? DateFormatter.formatNumeric(
                                          controller.endDate.value!,
                                        )
                                      : 'dd/mm/yyyy',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: controller.endDate.value != null
                                        ? AppColors.textPrimary
                                        : AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 14,
                                  color: AppColors.textMuted,
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (controller.startDate.value != null ||
                            controller.endDate.value != null) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: controller.clearDateRange,
                            icon: const Icon(Icons.close_rounded, size: 16),
                            tooltip: 'Reset date filter',
                            splashRadius: 16,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ],
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
                            width: 130,
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
                                  width: 130,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton(
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
                                      const SizedBox(width: 6),
                                      OutlinedButton(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (ctx) =>
                                                PrintSaleInvoiceDialog(
                                                  sale: sale,
                                                ),
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
                                          'Print',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                      ),
                                    ],
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
