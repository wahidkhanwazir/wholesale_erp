import '../../../shared/models/enums.dart';

class ProductModel {
  final String id;
  final String name;
  final String code;
  final String category;
  final String size;
  final String color;
  final double purchasePrice;
  final double salePrice;
  final int stockQuantity;
  final int lowStockThreshold;

  ProductModel({
    required this.id,
    required this.name,
    required this.code,
    required this.category,
    required this.size,
    required this.color,
    required this.purchasePrice,
    required this.salePrice,
    required this.stockQuantity,
    this.lowStockThreshold = 15,
  });

  StockStatus get stockStatus {
    if (stockQuantity <= 0) {
      return StockStatus.outOfStock;
    } else if (stockQuantity <= lowStockThreshold) {
      return StockStatus.lowStock;
    }
    return StockStatus.inStock;
  }

  bool get isLowStock => stockQuantity <= lowStockThreshold;

  double get profitMargin => salePrice - purchasePrice;

  String get displayName => '$name ($size / $color)';

  ProductModel copyWith({
    String? id,
    String? name,
    String? code,
    String? category,
    String? size,
    String? color,
    double? purchasePrice,
    double? salePrice,
    int? stockQuantity,
    int? lowStockThreshold,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      category: category ?? this.category,
      size: size ?? this.size,
      color: color ?? this.color,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salePrice: salePrice ?? this.salePrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    );
  }
}
