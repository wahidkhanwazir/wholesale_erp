import 'package:get/get.dart';
import '../controllers/sales_controller.dart';

class SalesBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SalesController>()) {
      Get.lazyPut<SalesController>(() => SalesController());
    }
  }
}
