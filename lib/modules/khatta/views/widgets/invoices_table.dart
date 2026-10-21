import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:wholesale_app/core/constants/app_colors.dart';
import 'package:wholesale_app/core/utils/currency_formatter.dart';
import 'package:wholesale_app/shared/models/enums.dart';
import '../../models/party_model.dart';
import 'package:wholesale_app/modules/sales/controllers/sales_controller.dart';
import 'package:wholesale_app/modules/purchases/controllers/purchases_controller.dart';

class InvoiceItemData {
  final String invoiceNumber;
  final DateTime date;
  final DateTime dueDate;
  final double amount;
  final double paid;
  final double baqaya;
  final String status;

  InvoiceItemData({
    required this.invoiceNumber,
    required this.date,
    required this.dueDate,
    required this.amount,
    required this.paid,
    required this.baqaya,
    required this.status,
  });
}

class InvoicesTable extends StatefulWidget {
  final PartyModel party;
  final DateTime? fromDate;
  final DateTime? toDate;

  const InvoicesTable({
    super.key,
    required this.party,
    this.fromDate,
    this.toDate,
  });

  @override
  State<InvoicesTable> createState() => _InvoicesTableState();
}

class _InvoicesTableState extends State<InvoicesTable> {
  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  List<InvoiceItemData> get invoiceList {
    final isCustomer = widget.party.type == PartyType.customer;
    final List<InvoiceItemData> list = [];

    // 1. Get all sale / purchase transactions from ledger
    var txList = widget.party.ledger.where((tx) {
      final ref = tx.referenceType.toLowerCase();
      return (ref.contains('sale') || ref.contains('inv') || ref.contains('purchase') || ref.contains('pur')) &&
          !ref.contains('opening') &&
          !tx.isReversed;
    }).toList();

    // 2. Filter by date range
    if (widget.fromDate != null) {
      final start = DateTime(widget.fromDate!.year, widget.fromDate!.month, widget.fromDate!.day);
      txList = txList.where((tx) {
        final txDay = DateTime(tx.date.year, tx.date.month, tx.date.day);
        return txDay.isAfter(start) || txDay.isAtSameMomentAs(start);
      }).toList();
    }

    if (widget.toDate != null) {
      final end = DateTime(widget.toDate!.year, widget.toDate!.month, widget.toDate!.day);
      txList = txList.where((tx) {
        final txDay = DateTime(tx.date.year, tx.date.month, tx.date.day);
        return txDay.isBefore(end) || txDay.isAtSameMomentAs(end);
      }).toList();
    }

    // Try finding SalesController or PurchasesController for exact match
    SalesController? salesCtrl;
    if (isCustomer && Get.isRegistered<SalesController>()) {
      salesCtrl = Get.find<SalesController>();
    }

    PurchasesController? purchasesCtrl;
    if (!isCustomer && Get.isRegistered<PurchasesController>()) {
      purchasesCtrl = Get.find<PurchasesController>();
    }

    // Track total party payments for FIFO allocation if no exact model match
    double unallocatedPayment = widget.party.totalPaidOrReceived;

    for (final tx in txList) {
      final amount = isCustomer ? tx.debit : tx.credit;
      if (amount <= 0) continue;

      // Extract clean invoice / purchase number
      String invNo = tx.referenceType;
      if (invNo.startsWith('Sale ')) {
        invNo = invNo.replaceFirst('Sale ', '');
      } else if (invNo.startsWith('Purchase Bill ')) {
        invNo = invNo.replaceFirst('Purchase Bill ', '');
      } else if (invNo.startsWith('Purchase ')) {
        invNo = invNo.replaceFirst('Purchase ', '');
      }

      double paid = 0.0;
      double baqaya = amount;
      String status = 'Unpaid';
      bool foundExactMatch = false;

      // 1. Check SalesController (Customer)
      if (isCustomer && salesCtrl != null) {
        try {
          final matchedSale = salesCtrl.sales.firstWhere(
            (s) => s.invoiceNumber.toLowerCase() == invNo.toLowerCase() || s.id == tx.id,
          );
          paid = matchedSale.amountPaid;
          baqaya = matchedSale.remainingBalance;
          if (matchedSale.paymentStatus == PaymentStatus.paid || baqaya <= 0) {
            status = 'Paid';
            baqaya = 0.0;
            paid = amount;
          } else if (matchedSale.paymentStatus == PaymentStatus.partial || paid > 0) {
            status = 'Partial';
          } else {
            status = 'Unpaid';
          }
          foundExactMatch = true;
        } catch (_) {}
      }

      // 2. Check PurchasesController (Supplier)
      if (!isCustomer && purchasesCtrl != null) {
        try {
          final matchedPur = purchasesCtrl.purchases.firstWhere(
            (p) => p.purchaseNumber.toLowerCase() == invNo.toLowerCase() || p.id == tx.id,
          );
          paid = matchedPur.amountPaid;
          baqaya = matchedPur.remainingPayable;
          if (matchedPur.paymentStatus == PaymentStatus.paid || baqaya <= 0) {
            status = 'Paid';
            baqaya = 0.0;
            paid = amount;
          } else if (matchedPur.paymentStatus == PaymentStatus.partial || paid > 0) {
            status = 'Partial';
          } else {
            status = 'Unpaid';
          }
          foundExactMatch = true;
        } catch (_) {}
      }

      // 3. FIFO / Direct Payment Fallback if no exact model found
      if (!foundExactMatch) {
        final directPaid = isCustomer ? tx.credit : tx.debit;
        if (directPaid > 0) {
          paid = directPaid.clamp(0.0, amount);
          baqaya = (amount - paid).clamp(0.0, double.infinity);
        } else if (unallocatedPayment > 0) {
          paid = unallocatedPayment.clamp(0.0, amount);
          baqaya = (amount - paid).clamp(0.0, double.infinity);
          unallocatedPayment -= paid;
        } else {
          paid = 0.0;
          baqaya = amount;
        }

        if (baqaya <= 0) {
          status = 'Paid';
          baqaya = 0.0;
        } else if (paid > 0) {
          status = 'Partial';
        } else {
          status = 'Unpaid';
        }
      }

      final dueDate = tx.date.add(Duration(days: widget.party.creditDays ?? 30));

      list.add(
        InvoiceItemData(
          invoiceNumber: invNo,
          date: tx.date,
          dueDate: dueDate,
          amount: amount,
          paid: paid,
          baqaya: baqaya,
          status: status,
        ),
      );
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isCustomer = widget.party.type == PartyType.customer;
    final invoices = invoiceList;

    final col1Header = isCustomer ? 'SALE NO' : 'PURCHASE NO';

    double totalAmountSum = 0.0;
    double totalPaidSum = 0.0;
    double totalBaqayaSum = 0.0;

    for (final inv in invoices) {
      totalAmountSum += inv.amount;
      totalPaidSum += inv.paid;
      totalBaqayaSum += inv.baqaya;
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
                      child: Row(
                        children: [
                          SizedBox(width: 140, child: Text(col1Header, style: _headerStyle)),
                          const SizedBox(width: 130, child: Text('DATE', style: _headerStyle)),
                          const SizedBox(width: 130, child: Text('DUE', style: _headerStyle)),
                          const Expanded(child: Text('AMOUNT', style: _headerStyle, textAlign: TextAlign.right)),
                          const Expanded(child: Text('PAID', style: _headerStyle, textAlign: TextAlign.right)),
                          const Expanded(child: Text('BAQAYA', style: _headerStyle, textAlign: TextAlign.right)),
                          const SizedBox(width: 100, child: Text('STATUS', style: _headerStyle, textAlign: TextAlign.center)),
                        ],
                      ),
                    ),

                    // Table Body
                    if (invoices.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            isCustomer ? 'No sales invoices found.' : 'No purchase bills found.',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: invoices.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final inv = invoices[index];

                          return Material(
                            color: index % 2 == 0 ? Colors.transparent : AppColors.background.withValues(alpha: 0.2),
                            child: InkWell(
                              onTap: () {},
                              hoverColor: AppColors.primary.withValues(alpha: 0.05),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                                child: Row(
                                  children: [
                                    // SALE NO / PURCHASE NO
                                    SizedBox(
                                      width: 140,
                                      child: Text(
                                        inv.invoiceNumber,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),

                                    // DATE
                                    SizedBox(
                                      width: 130,
                                      child: Text(
                                        DateFormat('dd MMM yyyy').format(inv.date),
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),

                                    // DUE DATE
                                    SizedBox(
                                      width: 130,
                                      child: Text(
                                        DateFormat('dd MMM yyyy').format(inv.dueDate),
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),

                                    // AMOUNT
                                    Expanded(
                                      child: Text(
                                        CurrencyFormatter.format(inv.amount),
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                          fontFeatures: [FontFeature.tabularFigures()],
                                        ),
                                      ),
                                    ),

                                    // PAID
                                    Expanded(
                                      child: Text(
                                        CurrencyFormatter.format(inv.paid),
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.success,
                                          fontFeatures: [FontFeature.tabularFigures()],
                                        ),
                                      ),
                                    ),

                                    // BAQAYA
                                    Expanded(
                                      child: Text(
                                        CurrencyFormatter.format(inv.baqaya),
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                          fontFeatures: [FontFeature.tabularFigures()],
                                        ),
                                      ),
                                    ),

                                    // STATUS BADGE
                                    SizedBox(
                                      width: 100,
                                      child: Center(
                                        child: _buildStatusBadge(inv.status),
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
                    if (invoices.isNotEmpty)
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
                            Expanded(
                              child: Text(
                                CurrencyFormatter.format(totalAmountSum),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                CurrencyFormatter.format(totalPaidSum),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.success,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                CurrencyFormatter.format(totalBaqayaSum),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                            const SizedBox(width: 100),
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

  Widget _buildStatusBadge(String status) {
    Color bg = const Color(0xFFFEE2E2); // Light red for Unpaid
    Color fg = const Color(0xFFDC2626);
    String label = 'Unpaid';

    if (status.toLowerCase() == 'paid') {
      bg = const Color(0xFFDCFCE7); // Light green for Paid
      fg = const Color(0xFF16A34A);
      label = 'Paid';
    } else if (status.toLowerCase() == 'partial') {
      bg = const Color(0xFFFEF3C7); // Light amber for Partial
      fg = const Color(0xFFD97706);
      label = 'Partial';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
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
