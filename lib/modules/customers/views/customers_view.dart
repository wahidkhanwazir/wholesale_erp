import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/desktop_layout.dart';
import '../../../core/widgets/custom_button.dart';
import '../controllers/customers_controller.dart';
import 'widgets/add_customer_dialog.dart';
import 'widgets/receive_payment_dialog.dart';
import 'customer_khata_view.dart';

class CustomersView extends GetView<CustomersController> {
  const CustomersView({super.key});

  @override
  Widget build(BuildContext context) {
    return DesktopLayout(
      currentRoute: AppRoutes.customers,
      title: AppStrings.navCustomers,
      subtitle:
          'Customer directory, credit khata management, and payment receipts',
      headerActions: [
        CustomButton(
          text: AppStrings.receivePayment,
          icon: Icons.payments_outlined,
          isSecondary: true,
          onPressed: () {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => ReceivePaymentDialog(
                initialCustomer: controller.selectedCustomer.value,
              ),
            );
          },
        ),
        const SizedBox(width: 10),
        CustomButton(
          text: AppStrings.addCustomer,
          icon: Icons.person_add_alt_1_outlined,
          onPressed: () {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => const AddCustomerDialog(),
            );
          },
        ),
      ],
      child: Obx(() {
        final customerList = controller.filteredCustomers;
        final selected =
            controller.selectedCustomer.value ??
            (customerList.isNotEmpty ? customerList.first : null);

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Panel: Customer Directory List (38%)
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
                            hintText: 'Search customer name, city, phone...',
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

                      // Customer List Header
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
                              'CUSTOMERS (${customerList.length})',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Text(
                              'OUTSTANDING KHATA',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Customer List
                      Expanded(
                        child: customerList.isEmpty
                            ? const Center(
                                child: Text(
                                  'No customers found.',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: customerList.length,
                                separatorBuilder: (_, _) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final customer = customerList[index];
                                  final isSelected =
                                      selected?.id == customer.id;

                                  return Material(
                                    color: isSelected
                                        ? AppColors.accentLight.withValues(
                                            alpha: 0.5,
                                          )
                                        : Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        controller.selectCustomer(customer);
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
                                                    color: AppColors.primary,
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
                                                    customer.name,
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
                                                    '${customer.city} • ${customer.phone}',
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
                                                    customer.outstandingBalance,
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        customer.outstandingBalance >
                                                            0
                                                        ? AppColors.error
                                                        : AppColors.success,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  customer.outstandingBalance >
                                                          0
                                                      ? 'Receivable'
                                                      : 'Cleared',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        customer.outstandingBalance >
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

              // Right Panel: Customer Khata Statement & Details (62%)
              Expanded(
                flex: 6,
                child: selected != null
                    ? SingleChildScrollView(
                        child: CustomerKhataView(customer: selected),
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
                            'Select a customer to view their Customer Khata.',
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
