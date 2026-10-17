import 'package:get/get.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/mock_data/mock_seed_data.dart';
import '../models/purchase_model.dart';
import '../../inventory/controllers/inventory_controller.dart';
import '../../suppliers/controllers/suppliers_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';

class PurchasesController extends GetxController {
  final purchases = <PurchaseModel>[].obs;
  final searchQuery = ''.obs;
  final statusFilter = 'All'.obs;

  @override
  void onInit() {
    super.onInit();
    loadInitialPurchases();
  }

  void loadInitialPurchases() {
    purchases.assignAll(MockSeedData.getPurchases());
  }

  List<PurchaseModel> get filteredPurchases {
    return purchases.where((purchase) {
      final matchesSearch =
          purchase.purchaseNumber.toLowerCase().contains(
            searchQuery.value.toLowerCase(),
          ) ||
          purchase.supplierName.toLowerCase().contains(
            searchQuery.value.toLowerCase(),
          );

      final matchesStatus =
          statusFilter.value == 'All' ||
          purchase.paymentStatus.displayName.toLowerCase() ==
              statusFilter.value.toLowerCase();

      return matchesSearch && matchesStatus;
    }).toList();
  }

  double get todayPurchasesTotal {
    return purchases
        .where((p) => DateFormatter.isToday(p.date))
        .fold(0.0, (sum, p) => sum + p.grandTotal);
  }

  String generatePurchaseNumber() {
    final year = DateTime.now().year;
    final nextNum = purchases.length + 1;
    return 'PUR-$year-${nextNum.toString().padLeft(3, '0')}';
  }

  /// Creates a new purchase, adds stock to inventory, updates supplier ledger, and refreshes dashboard
  void createNewPurchase(PurchaseModel purchase) {
    final inventoryCtrl = Get.find<InventoryController>();

    // 1. Add received stock into inventory
    for (final item in purchase.items) {
      inventoryCtrl.addStock(item.productId, item.quantity);
    }

    // 2. Record purchase in supplier's ledger & update payable
    final suppliersCtrl = Get.find<SuppliersController>();
    suppliersCtrl.addPurchaseToSupplier(purchase);

    // 3. Save to reactive purchases list
    purchases.insert(0, purchase);

    // 4. Trigger dashboard update if registered
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().refreshData();
    }

    if (Get.context != null) {
      Get.snackbar(
        'Purchase Order Recorded',
        'Bill ${purchase.purchaseNumber} from ${purchase.supplierName} added. Stock updated (+${purchase.totalItemCount} items).',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
