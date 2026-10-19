import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wholesale_app/core/constants/app_colors.dart';
import 'package:wholesale_app/core/utils/currency_formatter.dart';
import 'package:wholesale_app/core/utils/date_formatter.dart';
import 'package:wholesale_app/core/widgets/custom_button.dart';
import '../models/customer_model.dart';
import '../controllers/customers_controller.dart';
import 'widgets/receive_payment_dialog.dart';

class CustomerKhataView extends StatelessWidget {
  final CustomerModel customer;

  const CustomerKhataView({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final customersCtrl = Get.find<CustomersController>();

    return Obx(() {
      // Re-fetch customer reactively if available
      final currentCustomer =
          customersCtrl.getCustomerById(customer.id) ?? customer;

      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Prominent Khata Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Customer Khata',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              currentCustomer.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${currentCustomer.phone} • ${currentCustomer.city} • ${currentCustomer.address}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                CustomButton(
                  text: 'Receive Payment',
                  icon: Icons.payments_outlined,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => ReceivePaymentDialog(
                        initialCustomer: currentCustomer,
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 3 Summary metric pills for the Customer Khata
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    title: 'Total Invoiced Purchases',
                    value: CurrencyFormatter.format(
                      currentCustomer.totalPurchases,
                    ),
                    color: AppColors.primary,
                    bgColor: AppColors.accentLight,
                    icon: Icons.receipt_long_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricTile(
                    title: 'Total Payments Received',
                    value: CurrencyFormatter.format(
                      currentCustomer.amountReceived,
                    ),
                    color: AppColors.success,
                    bgColor: AppColors.successLight,
                    icon: Icons.check_circle_outline,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricTile(
                    title: 'Net Khata Receivable Balance',
                    value: CurrencyFormatter.format(
                      currentCustomer.outstandingBalance,
                    ),
                    color: currentCustomer.outstandingBalance > 0
                        ? AppColors.error
                        : AppColors.success,
                    bgColor: currentCustomer.outstandingBalance > 0
                        ? AppColors.errorLight
                        : AppColors.successLight,
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Ledger Transaction Table
            const Text(
              'Khata Running Ledger (Dr / Cr Statement)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                      border: Border(
                        bottom: BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text('Date', style: _headerStyle),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text('Reference', style: _headerStyle),
                        ),
                        Expanded(
                          flex: 6,
                          child: Text('Description', style: _headerStyle),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Debit (Dr)',
                            style: _headerStyle,
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Credit (Cr)',
                            style: _headerStyle,
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Balance Due',
                            style: _headerStyle,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (currentCustomer.ledger.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: Text(
                          'No transactions in this customer khata yet.',
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
                      itemCount: currentCustomer.ledger.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final tx = currentCustomer.ledger[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          color: index % 2 == 0
                              ? Colors.transparent
                              : AppColors.background.withValues(alpha: 0.3),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  DateFormatter.formatDate(tx.date),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  tx.referenceType,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 6,
                                child: Text(
                                  tx.description,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  tx.debit > 0
                                      ? CurrencyFormatter.format(tx.debit)
                                      : '—',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: tx.debit > 0
                                        ? AppColors.error
                                        : AppColors.textMuted,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  tx.credit > 0
                                      ? CurrencyFormatter.format(tx.credit)
                                      : '—',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: tx.credit > 0
                                        ? AppColors.success
                                        : AppColors.textMuted,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  CurrencyFormatter.format(tx.runningBalance),
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: tx.runningBalance > 0
                                        ? AppColors.textPrimary
                                        : AppColors.success,
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
    });
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
    letterSpacing: 0.2,
  );
}
