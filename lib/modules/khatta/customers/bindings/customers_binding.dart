import 'package:get/get.dart';
import '../controllers/customers_controller.dart';

class CustomersBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CustomersController>()) {
      Get.lazyPut<CustomersController>(() => CustomersController());
    }
  }
}
