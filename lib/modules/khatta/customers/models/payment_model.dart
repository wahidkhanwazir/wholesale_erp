import 'package:wholesale_app/shared/models/enums.dart';

class PaymentModel {
  final String id;
  final String voucherNumber;
  final PartyType partyType;
  final String partyId;
  final String partyName;
  final DateTime date;
  final double amount;
  final PaymentMethod paymentMethod;
  final String? reference;
  final String? notes;

  PaymentModel({
    required this.id,
    required this.voucherNumber,
    required this.partyType,
    required this.partyId,
    required this.partyName,
    required this.date,
    required this.amount,
    required this.paymentMethod,
    this.reference,
    this.notes,
  });

  PaymentModel copyWith({
    String? id,
    String? voucherNumber,
    PartyType? partyType,
    String? partyId,
    String? partyName,
    DateTime? date,
    double? amount,
    PaymentMethod? paymentMethod,
    String? reference,
    String? notes,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      voucherNumber: voucherNumber ?? this.voucherNumber,
      partyType: partyType ?? this.partyType,
      partyId: partyId ?? this.partyId,
      partyName: partyName ?? this.partyName,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      reference: reference ?? this.reference,
      notes: notes ?? this.notes,
    );
  }
}
