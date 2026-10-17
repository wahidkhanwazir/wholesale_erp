import 'package:get/get.dart';
import '../controllers/inventory_controller.dart';

class InventoryBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<InventoryController>()) {
      Get.lazyPut<InventoryController>(() => InventoryController());
    }
  }
}
