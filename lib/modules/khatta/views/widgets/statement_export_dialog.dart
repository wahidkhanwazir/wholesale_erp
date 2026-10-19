import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:wholesale_app/core/constants/app_colors.dart';
import 'package:wholesale_app/core/utils/currency_formatter.dart';
import 'package:wholesale_app/core/widgets/custom_button.dart';
import 'package:wholesale_app/shared/models/enums.dart';
import '../../models/party_model.dart';

class StatementExportDialog extends StatelessWidget {
  final PartyModel party;

  const StatementExportDialog({
    super.key,
    required this.party,
  });

  void _printStatement() {
    final isCustomer = party.type == PartyType.customer;
    final buffer = StringBuffer();

    buffer.writeln('========================================');
    buffer.writeln('OFFICIAL KHATA STATEMENT');
    buffer.writeln('Wholesale ERP System');
    buffer.writeln('========================================');
    buffer.writeln('Party Name: ${party.name}');
    buffer.writeln('Phone: ${party.phone}');
    if (party.city.isNotEmpty) buffer.writeln('City: ${party.city}');
    if (party.address.isNotEmpty) buffer.writeln('Address: ${party.address}');
    buffer.writeln('Statement Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}');
    buffer.writeln('----------------------------------------');
    buffer.writeln('FINANCIAL SUMMARY:');
    buffer.writeln('Opening Balance: Rs. ${party.openingBalance.toStringAsFixed(0)}');
    buffer.writeln('Total Billed: Rs. ${party.totalBilled.toStringAsFixed(0)}');
    buffer.writeln('Total Paid/Received: Rs. ${party.totalPaidOrReceived.toStringAsFixed(0)}');
    final balType = party.balance > 0 ? (isCustomer ? 'Lene hain' : 'Dene hain') : 'Cleared';
    buffer.writeln('Closing Balance (Baqaya): Rs. ${party.balance.abs().toStringAsFixed(0)} ($balType)');
    buffer.writeln('----------------------------------------');
    buffer.writeln('LEDGER TRANSACTIONS:');

    if (party.ledger.isEmpty) {
      buffer.writeln('No transaction records found.');
    } else {
      for (final tx in party.ledger) {
        final dateStr = DateFormat('dd/MM/yyyy').format(tx.date);
        final drStr = tx.debit > 0 ? 'Dr: Rs.${tx.debit.toStringAsFixed(0)}' : '';
        final crStr = tx.credit > 0 ? 'Cr: Rs.${tx.credit.toStringAsFixed(0)}' : '';
        final amountStr = [drStr, crStr].where((s) => s.isNotEmpty).join(' | ');
        buffer.writeln('$dateStr | ${tx.referenceType} | $amountStr | Balance: Rs.${tx.runningBalance.toStringAsFixed(0)}');
      }
    }

    buffer.writeln('========================================');

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    Get.snackbar(
      'Print Ready',
      'Full Khata statement formatted & copied to clipboard. Ready for printing/PDF.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCustomer = party.type == PartyType.customer;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surface,
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Khata Statement – ${party.name}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${party.phone} • ${party.city}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Financial Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Billed', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(party.totalBilled),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 32, color: AppColors.border),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          isCustomer ? 'Wasooli (Received)' : 'Ada-yegi (Paid)',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(party.totalPaidOrReceived),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.success),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 32, color: AppColors.border),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isCustomer ? 'Baqaya (Lene hain)' : 'Baqaya (Dene hain)',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(party.balance.abs()),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: party.balance > 0 ? (isCustomer ? AppColors.success : AppColors.error) : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Recent Ledger Table Preview
            const Text(
              'Ledger Statement Preview',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),

            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: DataTable(
                  columnSpacing: 16,
                  headingRowHeight: 36,
                  dataRowMaxHeight: 40,
                  dataRowMinHeight: 36,
                  headingRowColor: WidgetStateProperty.all(AppColors.background),
                  columns: const [
                    DataColumn(label: Text('DATE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                    DataColumn(label: Text('REF / TYPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                    DataColumn(label: Text('DEBIT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                    DataColumn(label: Text('CREDIT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                    DataColumn(label: Text('BALANCE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                  ],
                  rows: party.ledger.map((tx) {
                    return DataRow(
                      cells: [
                        DataCell(Text(DateFormat('dd/MM/yy').format(tx.date), style: const TextStyle(fontSize: 12))),
                        DataCell(Text(tx.referenceType, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                        DataCell(Text(tx.debit > 0 ? CurrencyFormatter.format(tx.debit) : '-', style: const TextStyle(fontSize: 12))),
                        DataCell(Text(tx.credit > 0 ? CurrencyFormatter.format(tx.credit) : '-', style: const TextStyle(fontSize: 12))),
                        DataCell(Text(CurrencyFormatter.format(tx.runningBalance), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Close', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                ),
                const SizedBox(width: 12),
                CustomButton(
                  text: 'Print / Copy Statement',
                  icon: Icons.print_outlined,
                  onPressed: () {
                    _printStatement();
                    Get.back();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
