import 'package:flutter/material.dart';
import 'package:wholesale_app/core/constants/app_colors.dart';
import 'package:wholesale_app/core/utils/currency_formatter.dart';
import 'package:wholesale_app/core/utils/date_formatter.dart';
import 'package:wholesale_app/shared/models/enums.dart';
import '../../models/party_model.dart';
import '../../customers/models/ledger_model.dart';
import 'reverse_entry_dialog.dart';

class LedgerTable extends StatelessWidget {
  final PartyModel party;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String typeFilter;

  const LedgerTable({
    super.key,
    required this.party,
    this.fromDate,
    this.toDate,
    required this.typeFilter,
  });

  List<LedgerTransaction> get filteredLedger {
    var list = party.ledger;

    // 1. Filter by Date Range (From Date & To Date)
    if (fromDate != null) {
      final start = DateTime(fromDate!.year, fromDate!.month, fromDate!.day);
      list = list.where((tx) {
        final txDay = DateTime(tx.date.year, tx.date.month, tx.date.day);
        return txDay.isAfter(start) || txDay.isAtSameMomentAs(start);
      }).toList();
    }

    if (toDate != null) {
      final end = DateTime(toDate!.year, toDate!.month, toDate!.day);
      list = list.where((tx) {
        final txDay = DateTime(tx.date.year, tx.date.month, tx.date.day);
        return txDay.isBefore(end) || txDay.isAtSameMomentAs(end);
      }).toList();
    }

    // 2. Filter by Type
    if (typeFilter == 'Sales / Purchases') {
      list = list.where((tx) {
        final ref = tx.referenceType.toLowerCase();
        return ref.contains('sale') || ref.contains('inv') || ref.contains('purchase') || ref.contains('pur');
      }).toList();
    } else if (typeFilter == 'Payments') {
      list = list.where((tx) {
        final ref = tx.referenceType.toLowerCase();
        return ref.contains('payment') || ref.contains('rcv') || ref.contains('pay');
      }).toList();
    } else if (typeFilter == 'Opening') {
      list = list.where((tx) => tx.referenceType.toLowerCase().contains('opening')).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isCustomer = party.type == PartyType.customer;
    final transactions = filteredLedger;

    final billHeader = isCustomer ? 'BILL (Dr)' : 'BILL (Cr)';
    final paymentHeader = isCustomer ? 'WASOOLI (Cr)' : 'ADA-YEGI (Dr)';

    double totalBillSum = 0.0;
    double totalPaymentSum = 0.0;

    for (final tx in transactions) {
      if (isCustomer) {
        totalBillSum += tx.debit;
        totalPaymentSum += tx.credit;
      } else {
        totalBillSum += tx.credit;
        totalPaymentSum += tx.debit;
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const minTableWidth = 840.0;
        final actualWidth = constraints.maxWidth < minTableWidth ? minTableWidth : constraints.maxWidth;

        return SingleChildScrollView(
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
                  // Sticky Header Row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                      border: Border(bottom: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 95, child: Text('DATE', style: _headerStyle)),
                        const SizedBox(width: 170, child: Text('TYPE / REF', style: _headerStyle)),
                        const Expanded(child: Text('DESCRIPTION', style: _headerStyle)),
                        SizedBox(width: 110, child: Text(billHeader, style: _headerStyle, textAlign: TextAlign.right)),
                        SizedBox(width: 110, child: Text(paymentHeader, style: _headerStyle, textAlign: TextAlign.right)),
                        const SizedBox(width: 120, child: Text('BALANCE', style: _headerStyle, textAlign: TextAlign.right)),
                        const SizedBox(width: 40), // Action column
                      ],
                    ),
                  ),

                  // Table Rows List
                  if (transactions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'No ledger entries found for the selected filters.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: transactions.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final tx = transactions[index];
                        final billAmt = isCustomer ? tx.debit : tx.credit;
                        final payAmt = isCustomer ? tx.credit : tx.debit;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          color: tx.isReversed
                              ? AppColors.errorLight.withValues(alpha: 0.3)
                              : (index % 2 == 0 ? Colors.transparent : AppColors.background.withValues(alpha: 0.2)),
                          child: Row(
                            children: [
                              // Date
                              SizedBox(
                                width: 95,
                                child: Text(
                                  DateFormatter.formatDate(tx.date),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: tx.isReversed ? AppColors.textMuted : AppColors.textSecondary,
                                    decoration: tx.isReversed ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              ),

                              // Type / Ref Badge
                              SizedBox(
                                width: 170,
                                child: _buildTypeBadge(tx.referenceType, tx.isReversed),
                              ),

                              // Description
                              Expanded(
                                child: Text(
                                  tx.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: tx.isReversed ? AppColors.textMuted : AppColors.textPrimary,
                                    decoration: tx.isReversed ? TextDecoration.lineThrough : null,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              // Bill Amount (Dr / Cr)
                              SizedBox(
                                width: 110,
                                child: Text(
                                  billAmt > 0 ? CurrencyFormatter.format(billAmt) : '—',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: tx.isReversed
                                        ? AppColors.textMuted
                                        : (billAmt > 0 ? AppColors.error : AppColors.textMuted),
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ),

                              // Payment Amount (Cr / Dr)
                              SizedBox(
                                width: 110,
                                child: Text(
                                  payAmt > 0 ? CurrencyFormatter.format(payAmt) : '—',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: tx.isReversed
                                        ? AppColors.textMuted
                                        : (payAmt > 0 ? AppColors.success : AppColors.textMuted),
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ),

                              // Running Balance
                              SizedBox(
                                width: 120,
                                child: Text(
                                  CurrencyFormatter.format(tx.runningBalance.abs()),
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: tx.isReversed
                                        ? AppColors.textMuted
                                        : (tx.runningBalance > 0 ? (isCustomer ? AppColors.success : AppColors.error) : AppColors.success),
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ),

                              // Reverse Action Menu
                              SizedBox(
                                width: 40,
                                child: tx.isCanBeReversed
                                    ? IconButton(
                                        icon: const Icon(Icons.undo, size: 16, color: AppColors.textMuted),
                                        tooltip: 'Reverse Entry',
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => ReverseEntryDialog(
                                              party: party,
                                              transaction: tx,
                                            ),
                                          );
                                        },
                                      )
                                    : const Tooltip(
                                        message: 'Reverse from the invoice (Sales/Purchases)',
                                        child: Icon(Icons.undo, size: 16, color: Color(0xFFE0E0E0)),
                                      ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  // Table Footer Row (Total / Closing)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                      border: Border(top: BorderSide(color: AppColors.border, width: 2)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 265,
                          child: Text(
                            'Total / Closing',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const Expanded(child: SizedBox()),
                        SizedBox(
                          width: 110,
                          child: Text(
                            CurrencyFormatter.format(totalBillSum),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.error,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 110,
                          child: Text(
                            CurrencyFormatter.format(totalPaymentSum),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.success,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: Text(
                            CurrencyFormatter.format(party.balance.abs()),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: party.balance > 0 ? (isCustomer ? AppColors.success : AppColors.error) : AppColors.success,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeBadge(String ref, bool isReversed) {
    if (isReversed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.errorLight,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'Reversed',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.error),
        ),
      );
    }

    final lower = ref.toLowerCase();

    if (lower.contains('opening')) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Opening',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6D28D9)),
            ),
          ),
        ],
      );
    }

    if (lower.contains('sale') || lower.contains('inv')) {
      String refNum = ref;
      if (refNum.startsWith('Sale ')) {
        refNum = refNum.replaceFirst('Sale ', '');
      }
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEB),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Sale',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFE53935)),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              refNum,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    if (lower.contains('purchase') || lower.contains('pur')) {
      String refNum = ref;
      if (refNum.startsWith('Purchase Bill ')) {
        refNum = refNum.replaceFirst('Purchase Bill ', '');
      }
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Purchase',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFE65100)),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              refNum,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    if (lower.contains('payment') || lower.contains('rcv') || lower.contains('pay')) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Payment',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        ref,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
