import 'package:get/get.dart';
import '../controllers/team_leave_controller.dart';

class TeamLeaveBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TeamLeaveController>(() => TeamLeaveController());
  }
}
