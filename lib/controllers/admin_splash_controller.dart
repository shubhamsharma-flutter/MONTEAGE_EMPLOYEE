// controllers/admin_splash_controller.dart
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../infrastructure/routes/admin_routes.dart';

class AdminSplashController extends GetxController {
  final box = GetStorage();
  


  @override
  void onInit() {
    super.onInit();

    Future.delayed(const Duration(seconds: 2), () {
      // ✅ Always go to BOOT (BOOT decides HOME vs LOGIN after permission)
      Get.offAllNamed(AdminRoutes.BOOT);
    });
  }
}
