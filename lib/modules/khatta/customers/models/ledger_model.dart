import 'package:wholesale_app/shared/models/enums.dart';

class LedgerTransaction {
  final String id;
  final String partyId;
  final PartyType partyType;
  final DateTime date;
  final String referenceType;
  final String description;
  final double debit;
  final double credit;
  final double runningBalance;
  final bool isReversed;
  final String? reversedEntryId;
  final String? voucherNumber;

  LedgerTransaction({
    required this.id,
    required this.partyId,
    required this.partyType,
    required this.date,
    required this.referenceType,
    required this.description,
    required this.debit,
    required this.credit,
    required this.runningBalance,
    this.isReversed = false,
    this.reversedEntryId,
    this.voucherNumber,
  });

  /// Rule 4: Reversal is allowed ONLY for Payment, Opening Balance and Adjustment entries.
  /// Sale/Purchase entries must show disabled reverse action.
  bool get isCanBeReversed {
    if (isReversed) return false;
    final ref = referenceType.toLowerCase();
    if (ref.startsWith('sale') ||
        ref.contains('inv-') ||
        ref.startsWith('purchase bill') ||
        ref.contains('pur-')) {
      return false;
    }
    return true;
  }

  LedgerTransaction copyWith({
    String? id,
    String? partyId,
    PartyType? partyType,
    DateTime? date,
    String? referenceType,
    String? description,
    double? debit,
    double? credit,
    double? runningBalance,
    bool? isReversed,
    String? reversedEntryId,
    String? voucherNumber,
  }) {
    return LedgerTransaction(
      id: id ?? this.id,
      partyId: partyId ?? this.partyId,
      partyType: partyType ?? this.partyType,
      date: date ?? this.date,
      referenceType: referenceType ?? this.referenceType,
      description: description ?? this.description,
      debit: debit ?? this.debit,
      credit: credit ?? this.credit,
      runningBalance: runningBalance ?? this.runningBalance,
      isReversed: isReversed ?? this.isReversed,
      reversedEntryId: reversedEntryId ?? this.reversedEntryId,
      voucherNumber: voucherNumber ?? this.voucherNumber,
    );
  }
}
