import 'package:get/get.dart';
import 'app_routes.dart';
import '../../modules/dashboard/views/dashboard_view.dart';
import '../../modules/dashboard/bindings/dashboard_binding.dart';
import '../../modules/sales/views/sales_view.dart';
import '../../modules/sales/bindings/sales_binding.dart';
import '../../modules/purchases/views/purchases_view.dart';
import '../../modules/purchases/bindings/purchases_binding.dart';
import '../../modules/khatta/customers/views/customers_view.dart';
import '../../modules/khatta/customers/bindings/customers_binding.dart';
import '../../modules/khatta/suppliers/views/suppliers_view.dart';
import '../../modules/khatta/suppliers/bindings/suppliers_binding.dart';
import '../../modules/inventory/views/inventory_view.dart';
import '../../modules/inventory/bindings/inventory_binding.dart';

class AppPages {
  static const initial = AppRoutes.dashboard;

  static final routes = [
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardView(),
      binding: DashboardBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.sales,
      page: () => const SalesView(),
      binding: SalesBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.purchases,
      page: () => const PurchasesView(),
      binding: PurchasesBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.customers,
      page: () => const CustomersView(),
      binding: CustomersBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.suppliers,
      page: () => const SuppliersView(),
      binding: SuppliersBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.inventory,
      page: () => const InventoryView(),
      binding: InventoryBinding(),
      transition: Transition.fadeIn,
    ),
  ];
}
