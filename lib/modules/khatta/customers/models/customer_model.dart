import 'ledger_model.dart';

class CustomerModel {
  final String id;
  final String name;
  final String contactPerson;
  final String sellerType;
  final String phone;
  final String city;
  final String address;
  final double totalPurchases;
  final double amountReceived;
  final double outstandingBalance;
  final List<LedgerTransaction> ledger;
  final double? creditLimit;
  final bool isActive;
  final double openingBalance;
  final String openingBalanceType; // 'Dr' (Lene hain) or 'Cr' (Advance)

  CustomerModel({
    required this.id,
    required this.name,
    this.contactPerson = '',
    this.sellerType = 'Wholesale Customer',
    required this.phone,
    required this.city,
    this.address = '',
    required this.totalPurchases,
    required this.amountReceived,
    required this.outstandingBalance,
    List<LedgerTransaction>? ledger,
    this.creditLimit,
    this.isActive = true,
    this.openingBalance = 0.0,
    this.openingBalanceType = 'Dr',
  }) : ledger = ledger ?? [];

  /// Derived total balance from ledger entries: sum(debit) - sum(credit)
  double get derivedBalance {
    if (ledger.isEmpty) return outstandingBalance;
    return ledger.fold(0.0, (sum, tx) => sum + (tx.debit - tx.credit));
  }

  /// Derived actual billed total from sales (excluding opening balance)
  double get derivedTotalBilled {
    if (ledger.isEmpty) return totalPurchases;
    return ledger.where((tx) {
      final ref = tx.referenceType.toLowerCase();
      return (ref.startsWith('sale') || ref.contains('inv')) &&
          !ref.contains('opening');
    }).fold(0.0, (sum, tx) => sum + tx.debit);
  }

  /// Derived total received payments
  double get derivedTotalReceived {
    if (ledger.isEmpty) return amountReceived;
    return ledger.where((tx) {
      final ref = tx.referenceType.toLowerCase();
      return !ref.contains('opening');
    }).fold(0.0, (sum, tx) => sum + tx.credit);
  }

  /// Derived opening balance amount
  double get derivedOpeningBalance {
    final opTx = ledger.where((tx) => tx.referenceType.toLowerCase().contains('opening'));
    if (opTx.isNotEmpty) {
      final tx = opTx.first;
      return tx.debit > 0 ? tx.debit : tx.credit;
    }
    return openingBalance;
  }

  /// FIFO Overdue Calculation (>30 days)
  double get overdueAmount {
    final now = DateTime.now();
    double totalOverdue = 0.0;
    for (final tx in ledger) {
      final ref = tx.referenceType.toLowerCase();
      if ((ref.startsWith('sale') || ref.contains('inv') || ref.contains('opening')) && tx.debit > 0) {
        final daysOld = now.difference(tx.date).inDays;
        if (daysOld >= 30) {
          totalOverdue += tx.debit;
        }
      }
    }
    // Net off with total credits received
    final totalCredits = derivedTotalReceived;
    final remainingOverdue = (totalOverdue - totalCredits).clamp(0.0, double.infinity);
    return remainingOverdue;
  }

  bool get isOverdue => overdueAmount > 0;

  int get maxOverdueDays {
    final now = DateTime.now();
    int maxDays = 0;
    for (final tx in ledger) {
      if (tx.debit > 0) {
        final days = now.difference(tx.date).inDays;
        if (days >= 30 && days > maxDays) {
          maxDays = days;
        }
      }
    }
    return maxDays;
  }

  bool get isCreditLimitExceeded {
    if (creditLimit == null || creditLimit! <= 0) return false;
    return derivedBalance > creditLimit!;
  }

  CustomerModel copyWith({
    String? id,
    String? name,
    String? contactPerson,
    String? sellerType,
    String? phone,
    String? city,
    String? address,
    double? totalPurchases,
    double? amountReceived,
    double? outstandingBalance,
    List<LedgerTransaction>? ledger,
    double? creditLimit,
    bool? isActive,
    double? openingBalance,
    String? openingBalanceType,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      sellerType: sellerType ?? this.sellerType,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      address: address ?? this.address,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      amountReceived: amountReceived ?? this.amountReceived,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
      ledger: ledger ?? List.from(this.ledger),
      creditLimit: creditLimit ?? this.creditLimit,
      isActive: isActive ?? this.isActive,
      openingBalance: openingBalance ?? this.openingBalance,
      openingBalanceType: openingBalanceType ?? this.openingBalanceType,
    );
  }
}
