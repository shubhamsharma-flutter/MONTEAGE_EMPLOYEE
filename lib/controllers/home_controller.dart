import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeController extends GetxController {
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.myattendance.monteage';

  // HomeController can be re-created while the app runs, so this is static to
  // keep the alert to once per app launch.
  static bool _updateAlertShown = false;

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
    _showUpdateAlertIfAvailable();
  }

  Future<void> _showUpdateAlertIfAvailable() async {
    await checkForUpdate();
    if (!isUpdateAvailable || _updateAlertShown) return;
    _updateAlertShown = true;

    Get.dialog(
      AlertDialog(
        title: const Text('Update Available'),
        content: const Text(
          'A new version of My Attendance is available. '
          'Please update to get the latest features and fixes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Get.back();
              _startUpdate();
            },
            child: const Text('Update'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// Uses Play's update screen, or opens the store listing if that isn't possible.
  Future<void> _startUpdate() async {
    try {
      if (isImmediateUpdateAllowed) {
        final result = await performImmediateUpdate();
        if (result != AppUpdateResult.inAppUpdateFailed) return;
      }
    } catch (e) {
      debugPrint('In-app update failed: $e');
    }

    await launchUrl(
      Uri.parse(_playStoreUrl),
      mode: LaunchMode.externalApplication,
    );
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
