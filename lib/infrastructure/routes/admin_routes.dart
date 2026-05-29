import 'package:get/get.dart';
import 'package:monteage_employee/screens/permission_boot_screen.dart';
import '../../bindings/FaceRegisterBinding.dart';
import '../../bindings/NotificationBinding.dart';
import '../../bindings/attendance_binding.dart';
import '../../bindings/attendance_history_binding.dart';
import '../../bindings/attendance_today_binding.dart';
import '../../bindings/check_out_attendance_binding.dart';
import '../../bindings/face_id_login_binding.dart';
import '../../bindings/forgot_passwordbinding.dart';
import '../../bindings/home_binding.dart';
import '../../bindings/login_binding.dart';
import '../../bindings/mark_face_attendance_binding.dart';
import '../../bindings/profile_binding.dart';
import '../../bindings/register_binding.dart';
import '../../screens/FaceRegisterScreen.dart';
import '../../screens/NotificationScreen.dart';
import '../../screens/admin_splash_screen.dart';
import '../../screens/attendance_details_page.dart';
import '../../screens/attendance_history_screen.dart';
import '../../screens/attendance_today_screen.dart';
import '../../screens/check_out_attendance_screen.dart';
import '../../screens/employee_profile_screen.dart';
import '../../screens/face_id_login_screen.dart';
import '../../screens/forgot_passwordscreen.dart';
import '../../screens/home_screen.dart';
import '../../screens/login_screen.dart';
import '../../screens/mark_face_attendance_screen.dart';
import '../../screens/register_screen.dart';
import '../../bindings/leave_management_binding.dart';
import '../../screens/leave_management_screen.dart';
import '../../bindings/totalattendanceview_binding.dart';
import '../../screens/totalattendanceview.dart';

import '../../bindings/task_binding.dart';
import '../../screens/task_screen.dart';
import '../../screens/main_screen.dart';
import '../../screens/attendance_screen.dart';
import '../../screens/calendar_screen.dart';

class AdminRoutes {
  // ==================
  // Route Names
  // ==================
  static const ADMIN_SPLASH = '/admin/splash';
  static const login = '/login';
  static const HOME = '/home';
  static const NOTIFICATIONS = '/notifications';
  static const MARK_FACE_ATTENDANCE = "/mark-face-attendance";
  static const attendanceDetails = '/attendance-details';
  static const attendanceHistory = "/attendance-history";
  static const registerScreen = '/register';
  static const faceRegister = '/face-register';
  static const attendanceToday = "/attendance-today";
  static const BOOT = "/boot";
  static const checkoutattendace = "/checkoutattendace";
  static const profile = "/profile";
  static const forgotpassword = "/forgotpassword";
  static const leaveManagement = "/leave-management";
  static const faceidlogin = "/faceid-login";
  static const attendance = '/attendance';
  static const mainScreen = '/main';
  static const projects = '/projects';
  static const allEmployeeAttendance = '/all-employee-attendance';
  

  // New Task Routes
  static const taskGiven = '/task-given';
  static const taskReceived = '/task-received';
  static const task = '/task';

  // ==================
  // Route Definitions
  // ==================
  static final List<GetPage> routes = [
    // ---------- SPLASH ----------
    GetPage(
      name: ADMIN_SPLASH,
      page: () => AdminSplashScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: Duration(milliseconds: 400),
    ),

    GetPage(
      name: BOOT,
      page: () => PermissionBootScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: Duration(milliseconds: 200),
    ),

    // ---------- LOGIN ----------
    GetPage(
      name: login,
      page: () => LoginScreen(),
      transition: Transition.rightToLeft,
      binding: LoginBinding(),
    ),

    GetPage(
      name: faceidlogin,
      page: () => FaceIdLoginScreen(),
      transition: Transition.rightToLeft,
      binding: FaceIdLoginBinding(),
    ),

    GetPage(
      name: MARK_FACE_ATTENDANCE,
      page: () => MarkFaceAttendanceScreen(),
      transition: Transition.rightToLeft,
      binding: MarkFaceAttendanceBinding(),
    ),

    GetPage(
      name: profile,
      page: () => EmployeeProfileScreen(),
      transition: Transition.rightToLeft,
      binding: EmployeeProfileBinding(),
    ),

    GetPage(
      name: checkoutattendace,
      page: () => CheckOutAttendanceScreen(),
      transition: Transition.rightToLeft,
      binding: checkoutAttendanceBinding(),
    ),

    // ---------- HOME ----------
    GetPage(
      name: HOME,
      page: () => HomeScreen(),
      transition: Transition.rightToLeft,
      binding: HomeBinding(),
    ),

    // ---------- NOTIFICATIONS ----------
    GetPage(
      name: NOTIFICATIONS,
      page: () => NotificationScreen(),
      transition: Transition.rightToLeft,
      binding: NotificationBinding(),
    ),

    GetPage(
      name: attendanceDetails,
      page: () => AttendanceDetailsPage(),
      transition: Transition.rightToLeft,
      binding: AttendanceBinding(),
    ),

    GetPage(
      name: attendanceHistory,
      page: () => AttendanceHistoryScreen(),
      transition: Transition.rightToLeft,
      binding: AttendanceHistoryBinding(),
    ),

    GetPage(
      name: registerScreen,
      page: () => RegisterScreen(),
      transition: Transition.rightToLeft,
      binding: RegisterBinding(),
    ),

    GetPage(
      name: forgotpassword,
      page: () => ForgotPasswordScreen(),
      transition: Transition.rightToLeft,
      binding: ForgotPasswordBinding(),
    ),

    GetPage(
      name: faceRegister,
      page: () => FaceRegisterScreen(),
      transition: Transition.rightToLeft,
      binding: FaceRegisterBinding(),
    ),

    GetPage(
      name: attendanceToday,
      page: () => AttendanceTodayScreen(),
      transition: Transition.rightToLeft,
      binding: AttendanceTodayBinding(),
    ),

    // ---------- TASKS GIVEN ----------
   

    // ---------- TASKS RECEIVED ----------
    

    GetPage(
      name: task,
      page: () => TaskScreen(),
      transition: Transition.rightToLeft,
      binding: TaskBinding(),
    ),

  GetPage(
     name: leaveManagement,
     page: () => LeaveManagementScreen(),
     transition: Transition.rightToLeft,
     binding: LeaveManagementBinding(),
),


GetPage(
  name: attendance,
  page: () => const AttendanceScreen(),
  transition: Transition.rightToLeft,
),

GetPage(
  name: mainScreen,
  page: () => const MainScreen(),
  transition: Transition.fadeIn,
  bindings: [
    HomeBinding(),
    TaskBinding(),
    EmployeeProfileBinding(),
  ],
),

GetPage(
  name: allEmployeeAttendance,
  page: () =>  Totalattendanceview(),
  transition: Transition.rightToLeft,
  binding: TotalAttendanceViewBinding(),
),




  ];
}
