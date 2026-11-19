import 'package:get/get.dart';
import '../controllers/sales_add_visit_controller.dart';
import '../controllers/sales_controller.dart';
import '../controllers/sales_lead_detail_controller.dart';

class SalesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SalesController>(() => SalesController());
  }
}

class SalesAddVisitBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SalesAddVisitController>(() => SalesAddVisitController());
  }
}

class SalesLeadDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SalesLeadDetailController>(() => SalesLeadDetailController());
  }
}
