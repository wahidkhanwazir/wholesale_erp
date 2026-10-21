import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:wholesale_app/core/constants/app_colors.dart';
import 'package:wholesale_app/core/utils/currency_formatter.dart';
import 'package:wholesale_app/shared/models/enums.dart';
import '../../models/party_model.dart';
import '../../customers/controllers/customers_controller.dart';
import '../../suppliers/controllers/suppliers_controller.dart';

class PaymentItemData {
  final String id;
  final DateTime date;
  final String receipt;
  final String mode;
  final String note;
  final double amount;
  final bool isReversed;

  PaymentItemData({
    required this.id,
    required this.date,
    required this.receipt,
    required this.mode,
    required this.note,
    required this.amount,
    this.isReversed = false,
  });
}

class PaymentsTable extends StatefulWidget {
  final PartyModel party;
  final DateTime? fromDate;
  final DateTime? toDate;

  const PaymentsTable({
    super.key,
    required this.party,
    this.fromDate,
    this.toDate,
  });

  @override
  State<PaymentsTable> createState() => _PaymentsTableState();
}

class _PaymentsTableState extends State<PaymentsTable> {
  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  List<PaymentItemData> get paymentList {
    final isCustomer = widget.party.type == PartyType.customer;
    final List<PaymentItemData> list = [];
    final Set<String> processedVouchers = {};

    // 1. Fetch from Controller Payments List if available
    if (isCustomer && Get.isRegistered<CustomersController>()) {
      final custCtrl = Get.find<CustomersController>();
      final partyPayments = custCtrl.payments.where((p) => p.partyId == widget.party.id);
      for (final p in partyPayments) {
        processedVouchers.add(p.voucherNumber.toLowerCase());
        list.add(
          PaymentItemData(
            id: p.id,
            date: p.date,
            receipt: p.voucherNumber,
            mode: p.paymentMethod.displayName,
            note: p.notes ?? p.reference ?? 'Payment received',
            amount: p.amount,
            isReversed: p.isReversed,
          ),
        );
      }
    } else if (!isCustomer && Get.isRegistered<SuppliersController>()) {
      final suppCtrl = Get.find<SuppliersController>();
      final partyPayments = suppCtrl.payments.where((p) => p.partyId == widget.party.id);
      for (final p in partyPayments) {
        processedVouchers.add(p.voucherNumber.toLowerCase());
        list.add(
          PaymentItemData(
            id: p.id,
            date: p.date,
            receipt: p.voucherNumber,
            mode: p.paymentMethod.displayName,
            note: p.notes ?? p.reference ?? 'Payment sent',
            amount: p.amount,
            isReversed: p.isReversed,
          ),
        );
      }
    }

    // 2. Fetch from Party Ledger Entries (if not already captured)
    final paymentTxList = widget.party.ledger.where((tx) {
      final amount = isCustomer ? tx.credit : tx.debit;
      final ref = tx.referenceType.toLowerCase();
      return amount > 0 && !ref.contains('opening');
    }).toList();

    for (final tx in paymentTxList) {
      final amount = isCustomer ? tx.credit : tx.debit;
      final voucher = tx.voucherNumber ?? _extractVoucherNo(tx.description, tx.referenceType);

      if (processedVouchers.contains(voucher.toLowerCase())) continue;
      processedVouchers.add(voucher.toLowerCase());

      list.add(
        PaymentItemData(
          id: tx.id,
          date: tx.date,
          receipt: voucher,
          mode: _extractMode(tx.description),
          note: tx.description,
          amount: amount,
          isReversed: tx.isReversed,
        ),
      );
    }

    // Sort by date descending
    list.sort((a, b) => b.date.compareTo(a.date));

    // 3. Filter by Date Range
    var filteredList = list;
    if (widget.fromDate != null) {
      final start = DateTime(widget.fromDate!.year, widget.fromDate!.month, widget.fromDate!.day);
      filteredList = filteredList.where((p) {
        final pDay = DateTime(p.date.year, p.date.month, p.date.day);
        return pDay.isAfter(start) || pDay.isAtSameMomentAs(start);
      }).toList();
    }

    if (widget.toDate != null) {
      final end = DateTime(widget.toDate!.year, widget.toDate!.month, widget.toDate!.day);
      filteredList = filteredList.where((p) {
        final pDay = DateTime(p.date.year, p.date.month, p.date.day);
        return pDay.isBefore(end) || pDay.isAtSameMomentAs(end);
      }).toList();
    }

    return filteredList;
  }

  String _extractVoucherNo(String desc, String ref) {
    final regex = RegExp(r'#?([A-Za-z]+-\d+)');
    final match = regex.firstMatch('$desc $ref');
    if (match != null) {
      return match.group(1)!;
    }
    return 'RCV-${desc.hashCode.abs() % 1000}';
  }

  String _extractMode(String desc) {
    final lower = desc.toLowerCase();
    if (lower.contains('bank') || lower.contains('meezan') || lower.contains('online') || lower.contains('transfer')) {
      return 'Bank Transfer';
    } else if (lower.contains('cheque') || lower.contains('check')) {
      return 'Cheque';
    } else if (lower.contains('easypaisa') || lower.contains('jazzcash')) {
      return 'Mobile Wallet';
    }
    return 'Cash';
  }

  @override
  Widget build(BuildContext context) {
    final payments = paymentList;

    double totalAmountSum = 0.0;
    for (final p in payments) {
      if (!p.isReversed) {
        totalAmountSum += p.amount;
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const minTableWidth = 840.0;
        final actualWidth = constraints.maxWidth < minTableWidth ? minTableWidth : constraints.maxWidth;

        return Scrollbar(
          controller: _horizontalController,
          thumbVisibility: true,
          trackVisibility: true,
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: actualWidth,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Row matching Screenshot 1
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                        border: Border(bottom: BorderSide(color: AppColors.border)),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(width: 120, child: Text('DATE', style: _headerStyle)),
                          SizedBox(width: 140, child: Text('RECEIPT', style: _headerStyle)),
                          SizedBox(width: 140, child: Text('MODE', style: _headerStyle)),
                          Expanded(child: Text('NOTE', style: _headerStyle)),
                          SizedBox(width: 140, child: Text('AMOUNT', style: _headerStyle, textAlign: TextAlign.right)),
                        ],
                      ),
                    ),

                    // Table Body
                    if (payments.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: Text(
                            'Koi payment nahi',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: payments.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final p = payments[index];

                          return Material(
                            color: p.isReversed
                                ? AppColors.errorLight.withValues(alpha: 0.3)
                                : (index % 2 == 0 ? Colors.transparent : AppColors.background.withValues(alpha: 0.2)),
                            child: InkWell(
                              onTap: () {},
                              hoverColor: AppColors.primary.withValues(alpha: 0.05),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                                child: Row(
                                  children: [
                                    // DATE
                                    SizedBox(
                                      width: 120,
                                      child: Text(
                                        DateFormat('dd MMM yyyy').format(p.date),
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: p.isReversed ? AppColors.textMuted : AppColors.textSecondary,
                                          decoration: p.isReversed ? TextDecoration.lineThrough : null,
                                        ),
                                      ),
                                    ),

                                    // RECEIPT / VOUCHER
                                    SizedBox(
                                      width: 140,
                                      child: Text(
                                        p.receipt,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: p.isReversed ? AppColors.textMuted : AppColors.textPrimary,
                                          decoration: p.isReversed ? TextDecoration.lineThrough : null,
                                        ),
                                      ),
                                    ),

                                    // MODE
                                    SizedBox(
                                      width: 140,
                                      child: Text(
                                        p.mode,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: p.isReversed ? AppColors.textMuted : AppColors.textPrimary,
                                        ),
                                      ),
                                    ),

                                    // NOTE
                                    Expanded(
                                      child: Text(
                                        p.note,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: p.isReversed ? AppColors.textMuted : AppColors.textPrimary,
                                          decoration: p.isReversed ? TextDecoration.lineThrough : null,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),

                                    // AMOUNT
                                    SizedBox(
                                      width: 140,
                                      child: Text(
                                        CurrencyFormatter.format(p.amount),
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: p.isReversed ? AppColors.textMuted : AppColors.success,
                                          fontFeatures: const [FontFeature.tabularFigures()],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                    // Table Footer Summary Row
                    if (payments.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: const BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                          border: Border(top: BorderSide(color: AppColors.border, width: 2)),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 400,
                              child: Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const Expanded(child: SizedBox()),
                            SizedBox(
                              width: 140,
                              child: Text(
                                CurrencyFormatter.format(totalAmountSum),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.success,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
    letterSpacing: 0.2,
  );
}
