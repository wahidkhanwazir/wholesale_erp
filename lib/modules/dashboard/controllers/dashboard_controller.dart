import 'package:get/get.dart';
import '../../sales/models/sale_model.dart';
import '../../purchases/models/purchase_model.dart';
import '../../inventory/models/product_model.dart';
import '../models/dashboard_day_sales.dart';
export '../models/dashboard_day_sales.dart';
import '../../sales/controllers/sales_controller.dart';
import '../../purchases/controllers/purchases_controller.dart';
import '../../customers/controllers/customers_controller.dart';
import '../../suppliers/controllers/suppliers_controller.dart';
import '../../inventory/controllers/inventory_controller.dart';

class DashboardController extends GetxController {
  final refreshTrigger = 0.obs;

  void refreshData() {
    refreshTrigger.value++;
  }

  double get todaySales {
    // Observe trigger so Obx rebuilds when refreshData() is called
    refreshTrigger.value;
    if (!Get.isRegistered<SalesController>()) return 0.0;
    return Get.find<SalesController>().todaySalesTotal;
  }

  double get todayPurchases {
    refreshTrigger.value;
    if (!Get.isRegistered<PurchasesController>()) return 0.0;
    return Get.find<PurchasesController>().todayPurchasesTotal;
  }

  double get customerReceivables {
    refreshTrigger.value;
    if (!Get.isRegistered<CustomersController>()) return 0.0;
    return Get.find<CustomersController>().totalReceivables;
  }

  double get supplierPayables {
    refreshTrigger.value;
    if (!Get.isRegistered<SuppliersController>()) return 0.0;
    return Get.find<SuppliersController>().totalPayables;
  }

  int get totalProducts {
    refreshTrigger.value;
    if (!Get.isRegistered<InventoryController>()) return 0;
    return Get.find<InventoryController>().totalProductsCount;
  }

  int get lowStockCount {
    refreshTrigger.value;
    if (!Get.isRegistered<InventoryController>()) return 0;
    return Get.find<InventoryController>().lowStockCount;
  }

  List<SaleModel> get recentSales {
    refreshTrigger.value;
    if (!Get.isRegistered<SalesController>()) return [];
    final list = Get.find<SalesController>().sales;
    return list.take(5).toList();
  }

  List<PurchaseModel> get recentPurchases {
    refreshTrigger.value;
    if (!Get.isRegistered<PurchasesController>()) return [];
    final list = Get.find<PurchasesController>().purchases;
    return list.take(5).toList();
  }

  List<ProductModel> get lowStockProducts {
    refreshTrigger.value;
    if (!Get.isRegistered<InventoryController>()) return [];
    final list = Get.find<InventoryController>().products;
    return list.where((p) => p.isLowStock).toList();
  }

  List<DashboardDaySales> get weeklySalesData {
    refreshTrigger.value;
    final now = DateTime.now();
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final result = <DashboardDaySales>[];

    final allSales = Get.isRegistered<SalesController>()
        ? Get.find<SalesController>().sales
        : <SaleModel>[];

    for (int i = 6; i >= 0; i--) {
      final targetDate = now.subtract(Duration(days: i));
      final dayLabel = dayNames[targetDate.weekday - 1];

      final dateLabel =
          '${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';

      final matchingSales = allSales.where(
        (s) =>
            s.date.year == targetDate.year &&
            s.date.month == targetDate.month &&
            s.date.day == targetDate.day,
      );

      final total = matchingSales.fold(0.0, (sum, s) => sum + s.grandTotal);
      result.add(
        DashboardDaySales(
          dayLabel: dayLabel,
          dateLabel: dateLabel,
          date: targetDate,
          amount: total,
          count: matchingSales.length,
        ),
      );
    }

    return result;
  }
}
