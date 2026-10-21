import 'package:get/get.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/mock_data/mock_seed_data.dart';
import '../models/purchase_model.dart';
import '../../inventory/controllers/inventory_controller.dart';
import '../../khatta/suppliers/controllers/suppliers_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';

class PurchasesController extends GetxController {
  final purchases = <PurchaseModel>[].obs;
  final searchQuery = ''.obs;
  final statusFilter = 'All'.obs;
  final supplierFilter = 'All'.obs;
  final startDate = Rxn<DateTime>();
  final endDate = Rxn<DateTime>();

  @override
  void onInit() {
    super.onInit();
    loadInitialPurchases();
  }

  void loadInitialPurchases() {
    purchases.assignAll(MockSeedData.getPurchases());
  }

  void clearDateRange() {
    startDate.value = null;
    endDate.value = null;
  }

  List<String> get availableSupplierNames {
    final names = <String>{};
    for (final p in purchases) {
      if (p.supplierName.trim().isNotEmpty) {
        names.add(p.supplierName.trim());
      }
    }
    if (Get.isRegistered<SuppliersController>()) {
      for (final s in Get.find<SuppliersController>().suppliers) {
        if (s.name.trim().isNotEmpty) {
          names.add(s.name.trim());
        }
      }
    }
    final sorted = names.toList()..sort();
    return ['All', ...sorted];
  }

  List<PurchaseModel> get filteredPurchases {
    return purchases.where((purchase) {
      final query = searchQuery.value.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          purchase.purchaseNumber.toLowerCase().contains(query) ||
          purchase.supplierName.toLowerCase().contains(query);

      final statusVal = statusFilter.value.toLowerCase();
      final purchaseStatus = purchase.paymentStatus.displayName.toLowerCase();
      final matchesStatus = statusVal == 'all' ||
          purchaseStatus == statusVal ||
          (statusVal == 'partially paid' && purchaseStatus == 'partial') ||
          (statusVal == 'partial' && purchaseStatus == 'partially paid');

      final supplierVal = supplierFilter.value.toLowerCase();
      final matchesSupplier = supplierVal == 'all' ||
          purchase.supplierName.toLowerCase() == supplierVal;

      final start = startDate.value;
      final end = endDate.value;
      final purchaseDateZero =
          DateTime(purchase.date.year, purchase.date.month, purchase.date.day);

      final matchesStart = start == null ||
          !purchaseDateZero.isBefore(DateTime(start.year, start.month, start.day));
      final matchesEnd = end == null ||
          !purchaseDateZero.isAfter(DateTime(end.year, end.month, end.day));

      return matchesSearch &&
          matchesStatus &&
          matchesSupplier &&
          matchesStart &&
          matchesEnd;
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
