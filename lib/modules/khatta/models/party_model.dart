import 'package:wholesale_app/shared/models/enums.dart';
import '../customers/models/customer_model.dart';
import '../suppliers/models/supplier_model.dart';
import '../customers/models/ledger_model.dart';

class PartyModel {
  final String id;
  final String name;
  final String phone;
  final String city;
  final String address;
  final PartyType type;
  final double totalBilled;
  final double totalPaidOrReceived;
  final double balance;
  final double openingBalance;
  final String openingBalanceType;
  final bool isActive;
  final double? creditLimit;
  final int? creditDays;
  final List<LedgerTransaction> ledger;
  final Object originalModel;

  PartyModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.city,
    required this.address,
    required this.type,
    required this.totalBilled,
    required this.totalPaidOrReceived,
    required this.balance,
    required this.openingBalance,
    required this.openingBalanceType,
    required this.isActive,
    this.creditLimit,
    this.creditDays,
    required this.ledger,
    required this.originalModel,
  });

  factory PartyModel.fromCustomer(CustomerModel c) {
    return PartyModel(
      id: c.id,
      name: c.name,
      phone: c.phone,
      city: c.city,
      address: c.address,
      type: PartyType.customer,
      totalBilled: c.derivedTotalBilled,
      totalPaidOrReceived: c.derivedTotalReceived,
      balance: c.derivedBalance,
      openingBalance: c.derivedOpeningBalance,
      openingBalanceType: c.openingBalanceType,
      isActive: c.isActive,
      creditLimit: c.creditLimit,
      ledger: c.ledger,
      originalModel: c,
    );
  }

  factory PartyModel.fromSupplier(SupplierModel s) {
    return PartyModel(
      id: s.id,
      name: s.name,
      phone: s.phone,
      city: s.city,
      address: s.address,
      type: PartyType.supplier,
      totalBilled: s.derivedTotalBilled,
      totalPaidOrReceived: s.derivedTotalPaid,
      balance: s.derivedPayable,
      openingBalance: s.derivedOpeningBalance,
      openingBalanceType: s.openingBalanceType,
      isActive: s.isActive,
      creditDays: s.creditDays,
      ledger: s.ledger,
      originalModel: s,
    );
  }

  String get initials {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  bool get isOverdueOrDueSoon {
    if (type == PartyType.customer) {
      final c = originalModel as CustomerModel;
      return c.isOverdue;
    } else {
      final s = originalModel as SupplierModel;
      return s.isDueSoon;
    }
  }

  String get statusCaption {
    if (balance > 0) {
      if (type == PartyType.customer) {
        final c = originalModel as CustomerModel;
        if (c.isOverdue) return 'Overdue ${c.maxOverdueDays} din';
        return 'Lene hain';
      } else {
        return 'Dene hain';
      }
    } else if (balance < 0) {
      return 'Advance';
    } else {
      return 'Cleared';
    }
  }
}
