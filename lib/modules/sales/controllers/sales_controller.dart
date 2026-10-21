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
  final customerFilter = 'All'.obs;
  final startDate = Rxn<DateTime>();
  final endDate = Rxn<DateTime>();

  @override
  void onInit() {
    super.onInit();
    loadInitialSales();
  }

  void loadInitialSales() {
    sales.assignAll(MockSeedData.getSales());
  }

  void clearDateRange() {
    startDate.value = null;
    endDate.value = null;
  }

  List<String> get availableCustomerNames {
    final names = <String>{};
    for (final s in sales) {
      if (s.customerName.trim().isNotEmpty) {
        names.add(s.customerName.trim());
      }
    }
    if (Get.isRegistered<CustomersController>()) {
      for (final c in Get.find<CustomersController>().customers) {
        if (c.name.trim().isNotEmpty) {
          names.add(c.name.trim());
        }
      }
    }
    final sorted = names.toList()..sort();
    return ['All', ...sorted];
  }

  List<SaleModel> get filteredSales {
    return sales.where((sale) {
      final query = searchQuery.value.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          sale.invoiceNumber.toLowerCase().contains(query) ||
          sale.customerName.toLowerCase().contains(query);

      final statusVal = statusFilter.value.toLowerCase();
      final saleStatus = sale.paymentStatus.displayName.toLowerCase();
      final matchesStatus = statusVal == 'all' ||
          saleStatus == statusVal ||
          (statusVal == 'partially paid' && saleStatus == 'partial') ||
          (statusVal == 'partial' && saleStatus == 'partially paid');

      final customerVal = customerFilter.value.toLowerCase();
      final matchesCustomer = customerVal == 'all' ||
          sale.customerName.toLowerCase() == customerVal;

      final start = startDate.value;
      final end = endDate.value;
      final saleDateZero =
          DateTime(sale.date.year, sale.date.month, sale.date.day);

      final matchesStart = start == null ||
          !saleDateZero.isBefore(DateTime(start.year, start.month, start.day));
      final matchesEnd = end == null ||
          !saleDateZero.isAfter(DateTime(end.year, end.month, end.day));

      return matchesSearch &&
          matchesStatus &&
          matchesCustomer &&
          matchesStart &&
          matchesEnd;
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
