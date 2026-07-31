import 'package:get/get.dart';
import '../controllers/crm_controller.dart';

class CrmBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CrmController>(() => CrmController());
  }
}
