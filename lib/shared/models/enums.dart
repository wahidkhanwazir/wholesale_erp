enum PaymentStatus {
  paid,
  partial,
  unpaid;

  String get displayName {
    switch (this) {
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.partial:
        return 'Partial';
      case PaymentStatus.unpaid:
        return 'Unpaid';
    }
  }
}

enum PaymentMethod {
  cash,
  bank,
  credit,
  cheque;

  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.bank:
        return 'Bank Transfer';
      case PaymentMethod.credit:
        return 'Credit (Khata)';
      case PaymentMethod.cheque:
        return 'Cheque';
    }
  }
}

enum PartyType {
  customer,
  supplier;

  String get displayName {
    switch (this) {
      case PartyType.customer:
        return 'Customer';
      case PartyType.supplier:
        return 'Supplier';
    }
  }
}

enum StockStatus {
  inStock,
  lowStock,
  outOfStock;

  String get displayName {
    switch (this) {
      case StockStatus.inStock:
        return 'In Stock';
      case StockStatus.lowStock:
        return 'Low Stock';
      case StockStatus.outOfStock:
        return 'Out of Stock';
    }
  }
}
