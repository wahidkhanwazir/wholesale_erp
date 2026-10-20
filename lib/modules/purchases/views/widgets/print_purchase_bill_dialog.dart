import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wholesale_app/core/constants/app_colors.dart';
import 'package:wholesale_app/core/utils/currency_formatter.dart';
import 'package:wholesale_app/core/utils/date_formatter.dart';
import 'package:wholesale_app/core/widgets/app_dialog.dart';
import 'package:wholesale_app/core/widgets/custom_button.dart';
import 'package:wholesale_app/core/widgets/status_badge.dart';
import '../../models/purchase_model.dart';

class PrintPurchaseBillDialog extends StatelessWidget {
  final PurchaseModel purchase;

  const PrintPurchaseBillDialog({super.key, required this.purchase});

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'Print Purchase Bill Voucher',
      subtitle: 'Preview printable supplier receiving voucher for ${purchase.purchaseNumber}',
      maxWidth: 720,
      actions: [
        CustomButton(
          text: 'Cancel',
          isSecondary: true,
          onPressed: () => Get.back(),
        ),
        const SizedBox(width: 8),
        CustomButton(
          text: 'Print Voucher',
          icon: Icons.print_rounded,
          onPressed: () {
            Get.back();
            Get.snackbar(
              'Print Job Sent',
              'Purchase Bill ${purchase.purchaseNumber} sent to printer successfully.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppColors.primary,
              colorText: Colors.white,
              icon: const Icon(Icons.print_rounded, color: Colors.white),
            );
          },
        ),
      ],
      content: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Business Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.local_shipping_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'AL-REHMAN GARMENTS',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Stock Receiving & Goods Inward Note',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Text(
                      'Main Warehouse / Shop #12-14, Azam Cloth Market, Lahore',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'PURCHASE BILL',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        purchase.purchaseNumber,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 14),

            // Meta Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SUPPLIER / VENDOR:',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      purchase.supplierName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Textile Mill / Vendor Accounts Payable',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Bill Date: ',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        Text(
                          DateFormatter.formatDate(purchase.date),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Text(
                          'Payment: ',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        StatusBadge.fromPaymentStatus(purchase.paymentStatus),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Items Table
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
                      border: Border(bottom: BorderSide(color: AppColors.border)),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 28,
                          child: Text('#', style: _colHeaderStyle),
                        ),
                        Expanded(
                          flex: 5,
                          child: Text('Item Description', style: _colHeaderStyle),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('Code / Size', style: _colHeaderStyle),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('Qty', textAlign: TextAlign.center, style: _colHeaderStyle),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text('Rate', textAlign: TextAlign.right, style: _colHeaderStyle),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text('Total', textAlign: TextAlign.right, style: _colHeaderStyle),
                        ),
                      ],
                    ),
                  ),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: purchase.items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, idx) {
                      final item = purchase.items[idx];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 28,
                              child: Text(
                                '${idx + 1}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ),
                            Expanded(
                              flex: 5,
                              child: Text(
                                item.productName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${item.productCode} (${item.size})',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${item.quantity} pcs',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                CurrencyFormatter.format(item.unitPrice),
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                CurrencyFormatter.format(item.total),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
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

            const SizedBox(height: 14),

            // Totals breakdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Item Count: ${purchase.totalItemCount} pcs',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Payment Method: ${purchase.paymentMethod.displayName}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                SizedBox(
                  width: 240,
                  child: Column(
                    children: [
                      _buildSummaryRow('Subtotal:', CurrencyFormatter.format(purchase.subtotal)),
                      if (purchase.discount > 0)
                        _buildSummaryRow(
                          'Discount:',
                          '- ${CurrencyFormatter.format(purchase.discount)}',
                          color: AppColors.error,
                        ),
                      const Divider(height: 8, color: AppColors.border),
                      _buildSummaryRow(
                        'Total Bill:',
                        CurrencyFormatter.format(purchase.grandTotal),
                        isBold: true,
                      ),
                      _buildSummaryRow(
                        'Paid Amount:',
                        CurrencyFormatter.format(purchase.amountPaid),
                        color: AppColors.success,
                      ),
                      _buildSummaryRow(
                        'Balance Payable:',
                        CurrencyFormatter.format(purchase.remainingPayable),
                        color: purchase.remainingPayable > 0 ? AppColors.error : AppColors.success,
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 14),

            // Signatures
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 30),
                    Text(
                      '__________________________',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    Text(
                      "Received By (Store Incharge)",
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(height: 30),
                    Text(
                      '__________________________',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    Text(
                      'Supplier Representative Signature',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildSummaryRow(
    String label,
    String value, {
    Color? color,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  static const TextStyle _colHeaderStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
  );
}
