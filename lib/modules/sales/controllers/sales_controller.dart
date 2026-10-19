import 'package:get/get.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/mock_data/mock_seed_data.dart';
import '../models/sale_model.dart';
import '../../inventory/controllers/inventory_controller.dart';
import '../../khatta/customers/controllers/customers_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';

class SalesController extends GetxController {
  final sales = <SaleModel>[].obs;
  final searchQuery = ''.obs;
  final statusFilter = 'All'.obs;

  @override
  void onInit() {
    super.onInit();
    loadInitialSales();
  }

  void loadInitialSales() {
    sales.assignAll(MockSeedData.getSales());
  }

  List<SaleModel> get filteredSales {
    return sales.where((sale) {
      final matchesSearch =
          sale.invoiceNumber.toLowerCase().contains(
            searchQuery.value.toLowerCase(),
          ) ||
          sale.customerName.toLowerCase().contains(
            searchQuery.value.toLowerCase(),
          );

      final matchesStatus =
          statusFilter.value == 'All' ||
          sale.paymentStatus.displayName.toLowerCase() ==
              statusFilter.value.toLowerCase();

      return matchesSearch && matchesStatus;
    }).toList();
  }

  double get todaySalesTotal {
    return sales
        .where((s) => DateFormatter.isToday(s.date))
        .fold(0.0, (sum, s) => sum + s.grandTotal);
  }

  String generateInvoiceNumber() {
    final year = DateTime.now().year;
    final nextNum = sales.length + 1;
    return 'INV-$year-${nextNum.toString().padLeft(3, '0')}';
  }

  /// Creates a new sale, validates stock, deducts inventory, updates customer khata, and refreshes dashboard
  ({bool success, String message}) createNewSale(SaleModel sale) {
    final inventoryCtrl = Get.find<InventoryController>();

    // 1. Validate sufficient stock for every item
    for (final item in sale.items) {
      final available =
          inventoryCtrl.getProductById(item.productId)?.stockQuantity ?? 0;
      if (available < item.quantity) {
        return (
          success: false,
          message:
              'Insufficient stock for ${item.productName}. Available: $available, Requested: ${item.quantity}',
        );
      }
    }

    // 2. Deduct inventory stock
    for (final item in sale.items) {
      inventoryCtrl.deductStock(item.productId, item.quantity);
    }

    // 3. Record in customer Khata and update customer balances
    final customersCtrl = Get.find<CustomersController>();
    customersCtrl.addSaleToCustomer(sale);

    // 4. Save to reactive sales list
    sales.insert(0, sale);

    // 5. Trigger dashboard update if registered
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().refreshData();
    }

    if (Get.context != null) {
      Get.snackbar(
        'Sale Saved Successfully',
        'Invoice ${sale.invoiceNumber} recorded for ${sale.customerName} (Total: Rs. ${sale.grandTotal.toStringAsFixed(0)})',
        snackPosition: SnackPosition.BOTTOM,
      );
    }

    return (success: true, message: 'Sale created successfully');
  }
}
