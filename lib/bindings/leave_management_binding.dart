import 'package:get/get.dart';
import '../controllers/leave_management_controller.dart';

class LeaveManagementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LeaveController>(() => LeaveController());
  }
}