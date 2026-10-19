import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wholesale_app/core/constants/app_colors.dart';
import 'package:wholesale_app/core/utils/currency_formatter.dart';
import 'package:wholesale_app/core/widgets/app_dialog.dart';
import 'package:wholesale_app/core/widgets/custom_button.dart';
import 'package:wholesale_app/shared/models/enums.dart';
import '../../controllers/khata_controller.dart';
import '../../models/party_model.dart';
import '../../customers/models/ledger_model.dart';

class ReverseEntryDialog extends StatefulWidget {
  final PartyModel party;
  final LedgerTransaction transaction;

  const ReverseEntryDialog({
    super.key,
    required this.party,
    required this.transaction,
  });

  @override
  State<ReverseEntryDialog> createState() => _ReverseEntryDialogState();
}

class _ReverseEntryDialogState extends State<ReverseEntryDialog> {
  final _khataCtrl = Get.find<KhataController>();
  final _reasonCtrl = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _reasonCtrl.text.trim();
    if (widget.party.type == PartyType.customer) {
      final res = _khataCtrl.customersCtrl.reverseLedgerEntry(
        customerId: widget.party.id,
        transactionId: widget.transaction.id,
        reason: reason,
      );
      if (res.success) {
        Get.back();
        Get.snackbar('Entry Reversed', res.message);
      } else {
        setState(() => _errorMessage = res.message);
      }
    } else {
      final res = _khataCtrl.suppliersCtrl.reverseLedgerEntry(
        supplierId: widget.party.id,
        transactionId: widget.transaction.id,
        reason: reason,
      );
      if (res.success) {
        Get.back();
        Get.snackbar('Entry Reversed', res.message);
      } else {
        setState(() => _errorMessage = res.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.transaction;
    final amt = tx.debit > 0 ? tx.debit : tx.credit;

    return AppDialog(
      title: 'Reverse Ledger Entry?',
      subtitle: 'An opposite ledger transaction will be posted to neutralize this entry.',
      maxWidth: 520,
      actions: [
        CustomButton(text: 'Cancel', isSecondary: true, onPressed: () => Get.back()),
        const SizedBox(width: 12),
        CustomButton(
          text: 'Confirm Reversal',
          icon: Icons.undo,
          onPressed: _submit,
        ),
      ],
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.error)),
              child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 14),
          ],

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${widget.party.name} (${widget.party.city})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                Text('Reference: ${tx.referenceType}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                Text('Description: ${tx.description}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Text('Amount: ${CurrencyFormatter.format(amt)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Reason for Reversal (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              TextField(
                controller: _reasonCtrl,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. Duplicate entry correction',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  fillColor: AppColors.surface,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
