import 'package:get/get.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:intl/intl.dart';

class HomeController extends GetxController {
  // ✅ Fixed current date
  final selectedDate = DateFormat("dd-MM-yyyy").format(DateTime.now()).obs;

  // Google Play in-app update (Android only).
  final appUpdateInfo = Rxn<AppUpdateInfo>();
  final updateCheckError = Rxn<Object>();

  bool get isUpdateAvailable =>
      appUpdateInfo.value?.updateAvailability ==
      UpdateAvailability.updateAvailable;

  bool get isImmediateUpdateAllowed =>
      appUpdateInfo.value?.immediateUpdateAllowed ?? false;

  bool get isFlexibleUpdateAllowed =>
      appUpdateInfo.value?.flexibleUpdateAllowed ?? false;

  @override
  void onInit() {
    super.onInit();
    checkForUpdate();
  }

  /// Queries Play Store for update availability and caches the result in
  /// [appUpdateInfo]. No-op result (error captured) on non-Android platforms.
  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      appUpdateInfo.value = info;
      updateCheckError.value = null;
      return info;
    } catch (e) {
      updateCheckError.value = e;
      return null;
    }
  }

  /// Starts the full-screen blocking update flow.
  Future<AppUpdateResult> performImmediateUpdate() {
    return InAppUpdate.performImmediateUpdate();
  }

  /// Starts a background update download the user can keep using the app
  /// during. Call [completeFlexibleUpdate] once it finishes to install it.
  Future<AppUpdateResult> startFlexibleUpdate() {
    return InAppUpdate.startFlexibleUpdate();
  }

  Future<void> completeFlexibleUpdate() {
    return InAppUpdate.completeFlexibleUpdate();
  }
}
