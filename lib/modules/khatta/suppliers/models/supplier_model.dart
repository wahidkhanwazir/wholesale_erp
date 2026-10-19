import 'ledger_model.dart';

class SupplierModel {
  final String id;
  final String name;
  final String phone;
  final String city;
  final String address;
  final double totalPurchases;
  final double totalPaid;
  final double outstandingPayable;
  final List<LedgerTransaction> ledger;
  final int? creditDays;
  final bool isActive;
  final double openingBalance;
  final String openingBalanceType; // 'Cr' (Dene hain) or 'Dr' (Advance)

  SupplierModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.city,
    this.address = '',
    required this.totalPurchases,
    required this.totalPaid,
    required this.outstandingPayable,
    List<LedgerTransaction>? ledger,
    this.creditDays,
    this.isActive = true,
    this.openingBalance = 0.0,
    this.openingBalanceType = 'Cr',
  }) : ledger = ledger ?? [];

  /// Derived total payable from ledger entries: sum(credit) - sum(debit)
  double get derivedPayable {
    if (ledger.isEmpty) return outstandingPayable;
    return ledger.fold(0.0, (sum, tx) => sum + (tx.credit - tx.debit));
  }

  /// Derived actual billed total from purchases (excluding opening balance)
  double get derivedTotalBilled {
    if (ledger.isEmpty) return totalPurchases;
    return ledger.where((tx) {
      final ref = tx.referenceType.toLowerCase();
      return (ref.contains('purchase') || ref.contains('pur')) &&
          !ref.contains('opening');
    }).fold(0.0, (sum, tx) => sum + tx.credit);
  }

  /// Derived total payments paid to supplier
  double get derivedTotalPaid {
    if (ledger.isEmpty) return totalPaid;
    return ledger.where((tx) {
      final ref = tx.referenceType.toLowerCase();
      return !ref.contains('opening');
    }).fold(0.0, (sum, tx) => sum + tx.debit);
  }

  /// Derived opening balance amount
  double get derivedOpeningBalance {
    final opTx = ledger.where((tx) => tx.referenceType.toLowerCase().contains('opening'));
    if (opTx.isNotEmpty) {
      final tx = opTx.first;
      return tx.credit > 0 ? tx.credit : tx.debit;
    }
    return openingBalance;
  }

  /// Due this week or past credit days
  bool get isDueSoon {
    if (derivedPayable <= 0) return false;
    final now = DateTime.now();
    final allowedDays = creditDays ?? 30;
    for (final tx in ledger) {
      if (tx.credit > 0) {
        final daysOld = now.difference(tx.date).inDays;
        if (daysOld >= (allowedDays - 7)) {
          return true;
        }
      }
    }
    return false;
  }

  SupplierModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? city,
    String? address,
    double? totalPurchases,
    double? totalPaid,
    double? outstandingPayable,
    List<LedgerTransaction>? ledger,
    int? creditDays,
    bool? isActive,
    double? openingBalance,
    String? openingBalanceType,
  }) {
    return SupplierModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      address: address ?? this.address,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      totalPaid: totalPaid ?? this.totalPaid,
      outstandingPayable: outstandingPayable ?? this.outstandingPayable,
      ledger: ledger ?? List.from(this.ledger),
      creditDays: creditDays ?? this.creditDays,
      isActive: isActive ?? this.isActive,
      openingBalance: openingBalance ?? this.openingBalance,
      openingBalanceType: openingBalanceType ?? this.openingBalanceType,
    );
  }
}
