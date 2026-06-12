import 'package:get/get.dart';
import 'package:monteage_employee/controllers/totalattendanceview_controller.dart';

class TotalAttendanceViewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TotalAttendanceViewController>(
      () => TotalAttendanceViewController(),
    );
  }
}
