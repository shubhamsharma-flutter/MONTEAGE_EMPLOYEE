import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'infrastructure/routes/admin_routes.dart';
import 'services/attendance_sync_service.dart';
import 'services/push_notification_service.dart';
import 'utils/constants/app_theme.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background FCM message: ${message.messageId}');
}

Future<void> firebaseInit() async {
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  // Re-subscribe on every launch so users who stay logged in (or logged in
  // before topics existed) still receive their per-user notifications.
  final employeeId = GetStorage().read("EmployeeId")?.toString();
  if (employeeId != null && employeeId.isNotEmpty) {
    messaging
        .subscribeToTopic(PushNotificationService.topicForEmployee(employeeId))
        .catchError((e) => debugPrint('FCM subscribe error: $e'));
  }

  // Android doesn't display notifications while the app is open, so show them
  // in-app instead.
  FirebaseMessaging.onMessage.listen((message) {
    final notification = message.notification;
    if (notification == null) return;
    Get.snackbar(
      notification.title ?? 'Notification',
      notification.body ?? '',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
    );
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await firebaseInit();
  await AttendanceSyncService.init();
  AttendanceSyncService.startAutoSync();
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'My Attendance',
      debugShowCheckedModeBanner: false,
      getPages: AdminRoutes.routes,

      // ✅ Start from SPLASH (Splash -> BOOT -> HOME/LOGIN)
      initialRoute: AdminRoutes.ADMIN_SPLASH,

      theme: AppTheme.light,

      builder: (context, child) {
        return ScreenUtilInit(
          designSize: const Size(411.42, 890.28),
          child: child!,
        );
      },
    );
  }
}
