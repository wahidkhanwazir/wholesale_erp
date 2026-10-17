import '../../../shared/models/enums.dart';

class SaleItem {
  final String productId;
  final String productName;
  final String productCode;
  final String size;
  final String color;
  final int quantity;
  final double unitPrice;
  final double total;

  SaleItem({
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.size,
    required this.color,
    required this.quantity,
    required this.unitPrice,
    double? total,
  }) : total = total ?? (quantity * unitPrice);

  SaleItem copyWith({
    String? productId,
    String? productName,
    String? productCode,
    String? size,
    String? color,
    int? quantity,
    double? unitPrice,
    double? total,
  }) {
    return SaleItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productCode: productCode ?? this.productCode,
      size: size ?? this.size,
      color: color ?? this.color,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      total: total ?? (this.quantity * this.unitPrice),
    );
  }
}

class SaleModel {
  final String id;
  final String invoiceNumber;
  final DateTime date;
  final String customerId;
  final String customerName;
  final List<SaleItem> items;
  final double subtotal;
  final double discount;
  final double grandTotal;
  final double amountPaid;
  final double remainingBalance;
  final PaymentStatus paymentStatus;
  final PaymentMethod paymentMethod;
  final String? notes;

  SaleModel({
    required this.id,
    required this.invoiceNumber,
    required this.date,
    required this.customerId,
    required this.customerName,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.grandTotal,
    required this.amountPaid,
    required this.remainingBalance,
    required this.paymentStatus,
    required this.paymentMethod,
    this.notes,
  });

  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity);

  SaleModel copyWith({
    String? id,
    String? invoiceNumber,
    DateTime? date,
    String? customerId,
    String? customerName,
    List<SaleItem>? items,
    double? subtotal,
    double? discount,
    double? grandTotal,
    double? amountPaid,
    double? remainingBalance,
    PaymentStatus? paymentStatus,
    PaymentMethod? paymentMethod,
    String? notes,
  }) {
    return SaleModel(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      date: date ?? this.date,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      grandTotal: grandTotal ?? this.grandTotal,
      amountPaid: amountPaid ?? this.amountPaid,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
    );
  }
}
