import '../../../shared/models/enums.dart';

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
  });

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
    );
  }
}
