import 'package:get/get.dart';
import '../controllers/khata_controller.dart';
import '../customers/controllers/customers_controller.dart';
import '../suppliers/controllers/suppliers_controller.dart';

class KhataBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CustomersController>()) {
      Get.put<CustomersController>(CustomersController(), permanent: true);
    }
    if (!Get.isRegistered<SuppliersController>()) {
      Get.put<SuppliersController>(SuppliersController(), permanent: true);
    }
    Get.lazyPut<KhataController>(() => KhataController());
  }
}
