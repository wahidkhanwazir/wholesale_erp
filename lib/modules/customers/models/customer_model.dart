import 'ledger_model.dart';

class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final String city;
  final String address;
  final double totalPurchases;
  final double amountReceived;
  final double outstandingBalance;
  final List<LedgerTransaction> ledger;

  CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.city,
    this.address = '',
    required this.totalPurchases,
    required this.amountReceived,
    required this.outstandingBalance,
    List<LedgerTransaction>? ledger,
  }) : ledger = ledger ?? [];

  CustomerModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? city,
    String? address,
    double? totalPurchases,
    double? amountReceived,
    double? outstandingBalance,
    List<LedgerTransaction>? ledger,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      address: address ?? this.address,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      amountReceived: amountReceived ?? this.amountReceived,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
      ledger: ledger ?? List.from(this.ledger),
    );
  }
}
