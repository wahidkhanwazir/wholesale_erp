import 'package:get/get.dart';
import '../../modules/inventory/controllers/inventory_controller.dart';
import '../../modules/customers/controllers/customers_controller.dart';
import '../../modules/suppliers/controllers/suppliers_controller.dart';
import '../../modules/sales/controllers/sales_controller.dart';
import '../../modules/purchases/controllers/purchases_controller.dart';
import '../../modules/dashboard/controllers/dashboard_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<InventoryController>(InventoryController(), permanent: true);
    Get.put<CustomersController>(CustomersController(), permanent: true);
    Get.put<SuppliersController>(SuppliersController(), permanent: true);
    Get.put<SalesController>(SalesController(), permanent: true);
    Get.put<PurchasesController>(PurchasesController(), permanent: true);
    Get.put<DashboardController>(DashboardController(), permanent: true);
  }
}
