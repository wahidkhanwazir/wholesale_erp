import '../../../shared/models/enums.dart';

class PurchaseItem {
  final String productId;
  final String productName;
  final String productCode;
  final String size;
  final String color;
  final int quantity;
  final double unitPrice;
  final double total;

  PurchaseItem({
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.size,
    required this.color,
    required this.quantity,
    required this.unitPrice,
    double? total,
  }) : total = total ?? (quantity * unitPrice);

  PurchaseItem copyWith({
    String? productId,
    String? productName,
    String? productCode,
    String? size,
    String? color,
    int? quantity,
    double? unitPrice,
    double? total,
  }) {
    return PurchaseItem(
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

class PurchaseModel {
  final String id;
  final String purchaseNumber;
  final DateTime date;
  final String supplierId;
  final String supplierName;
  final List<PurchaseItem> items;
  final double subtotal;
  final double discount;
  final double grandTotal;
  final double amountPaid;
  final double remainingPayable;
  final PaymentStatus paymentStatus;
  final PaymentMethod paymentMethod;
  final String? notes;

  PurchaseModel({
    required this.id,
    required this.purchaseNumber,
    required this.date,
    required this.supplierId,
    required this.supplierName,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.grandTotal,
    required this.amountPaid,
    required this.remainingPayable,
    required this.paymentStatus,
    required this.paymentMethod,
    this.notes,
  });

  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity);

  PurchaseModel copyWith({
    String? id,
    String? purchaseNumber,
    DateTime? date,
    String? supplierId,
    String? supplierName,
    List<PurchaseItem>? items,
    double? subtotal,
    double? discount,
    double? grandTotal,
    double? amountPaid,
    double? remainingPayable,
    PaymentStatus? paymentStatus,
    PaymentMethod? paymentMethod,
    String? notes,
  }) {
    return PurchaseModel(
      id: id ?? this.id,
      purchaseNumber: purchaseNumber ?? this.purchaseNumber,
      date: date ?? this.date,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      grandTotal: grandTotal ?? this.grandTotal,
      amountPaid: amountPaid ?? this.amountPaid,
      remainingPayable: remainingPayable ?? this.remainingPayable,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
    );
  }
}
