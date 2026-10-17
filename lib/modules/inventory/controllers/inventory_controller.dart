import 'package:get/get.dart';
import '../../../data/mock_data/mock_seed_data.dart';
import '../models/product_model.dart';

class InventoryController extends GetxController {
  final products = <ProductModel>[].obs;
  final searchQuery = ''.obs;
  final selectedCategory = 'All Categories'.obs;
  final onlyLowStock = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadInitialProducts();
  }

  void loadInitialProducts() {
    products.assignAll(MockSeedData.getProducts());
  }

  List<ProductModel> get filteredProducts {
    return products.where((product) {
      final matchesSearch =
          product.name.toLowerCase().contains(
            searchQuery.value.toLowerCase(),
          ) ||
          product.code.toLowerCase().contains(
            searchQuery.value.toLowerCase(),
          ) ||
          product.category.toLowerCase().contains(
            searchQuery.value.toLowerCase(),
          );

      final matchesCategory =
          selectedCategory.value == 'All Categories' ||
          product.category == selectedCategory.value;

      final matchesLowStock = !onlyLowStock.value || product.isLowStock;

      return matchesSearch && matchesCategory && matchesLowStock;
    }).toList();
  }

  int get totalProductsCount => products.length;

  int get lowStockCount => products.where((p) => p.isLowStock).length;

  double get totalInventoryValue =>
      products.fold(0.0, (sum, p) => sum + (p.purchasePrice * p.stockQuantity));

  ProductModel? getProductById(String id) {
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  void addProduct(ProductModel product) {
    products.insert(0, product);
    if (Get.context != null) {
      Get.snackbar(
        'Stock Added',
        '${product.name} (${product.code}) was added to inventory.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void updateProduct(ProductModel updatedProduct) {
    final index = products.indexWhere((p) => p.id == updatedProduct.id);
    if (index != -1) {
      products[index] = updatedProduct;
      products.refresh();
      if (Get.context != null) {
        Get.snackbar(
          'Product Updated',
          '${updatedProduct.name} updated successfully.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  bool canDeductStock(String productId, int quantity) {
    final product = getProductById(productId);
    if (product == null) return false;
    return product.stockQuantity >= quantity;
  }

  bool deductStock(String productId, int quantity) {
    final index = products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final current = products[index];
      if (current.stockQuantity >= quantity) {
        products[index] = current.copyWith(
          stockQuantity: current.stockQuantity - quantity,
        );
        products.refresh();
        return true;
      }
    }
    return false;
  }

  void addStock(String productId, int quantity) {
    final index = products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final current = products[index];
      products[index] = current.copyWith(
        stockQuantity: current.stockQuantity + quantity,
      );
      products.refresh();
    }
  }

  String generateProductCode(String category) {
    String prefix = 'ITM';
    if (category.contains('Jeans')) prefix = 'JNS';
    if (category.contains('Shirt')) prefix = 'SHT';
    if (category.contains('Trouser')) prefix = 'TRS';
    if (category.contains('T-Shirt')) prefix = 'TEE';
    if (category.contains('Track')) prefix = 'TRK';
    if (category.contains('Polo')) prefix = 'POL';
    if (category.contains('Kurta')) prefix = 'KRT';

    final count = products.where((p) => p.code.startsWith(prefix)).length + 1;
    return '$prefix-${count.toString().padLeft(3, '0')}';
  }
}
