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
  }) : ledger = ledger ?? [];

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
    );
  }
}
