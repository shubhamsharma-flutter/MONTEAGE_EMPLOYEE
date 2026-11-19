import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../screens/home_screen.dart';
import '../screens/task_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/employee_profile_screen.dart';
import 'all_attendance_screen.dart';
import '../bindings/task_binding.dart';
import '../bindings/profile_binding.dart';
import '../controllers/task_controller.dart';
import '../controllers/profile_controller.dart';
import '../bindings/home_binding.dart';
import '../controllers/home_controller.dart';
import '../controllers/employee_data_controller.dart';
import '../controllers/totalattendanceview_controller.dart';
import '../controllers/hr_today_attendance_controller.dart';
import '../widgets/app_ui.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Tab ids are fixed (0 Home, 1 Tasks/All Attendance, 2 Calendar,
  // 3 Profile) because callers open tabs with {'tab': id}.
  int _currentIndex = 0;
  late List<Widget> _screens; // ← change to late
  late List<int> _visibleTabs;

  @override
void initState() {
  super.initState();

  // Register controllers first
  if (!Get.isRegistered<EmployeeDataController>()) Get.put(EmployeeDataController());
  final employeeC = Get.find<EmployeeDataController>();
  final isSalesUser = !employeeC.isHrManager && employeeC.isSalesUser;

  if (!isSalesUser && !Get.isRegistered<TaskController>()) Get.put(TaskController());
  if (!Get.isRegistered<EmployeeProfileController>()) Get.put(EmployeeProfileController(), permanent: true);
  if (!Get.isRegistered<HomeController>()) Get.put(HomeController());

   if (!Get.isRegistered<TotalAttendanceViewController>()) {
    Get.put(TotalAttendanceViewController());
  }
  if (!Get.isRegistered<HrTodayAttendanceController>()) {
    Get.put(HrTodayAttendanceController());
  }

  // Build screens based on role
  if (employeeC.isHrManager) {
    _screens = [
      HomeScreen(),
      const AllAttendanceScreen(),
      CalendarScreen(),
      EmployeeProfileScreen(),
    ];
  } else {
    _screens = [
      HomeScreen(),
      // Sales users have no Tasks tab; keep the slot so tab ids stay fixed.
      isSalesUser ? const SizedBox.shrink() : TaskScreen(),
      CalendarScreen(),
      EmployeeProfileScreen(),
    ];
  }
  _visibleTabs = isSalesUser ? const [0, 2, 3] : const [0, 1, 2, 3];

  // Check if a specific tab was requested
  final args = Get.arguments;
  if (args != null && args is Map && args['tab'] != null) {
    final tab = args['tab'] as int;
    _currentIndex = _visibleTabs.contains(tab) ? tab : 0;
  }
}
  // rest of code stays the same...




  @override
  Widget build(BuildContext context) {
    debugPrint("MAIN SCREEN LOADED");
    final employeeC = Get.find<EmployeeDataController>();
    final isHr = employeeC.isHrManager;

    final navItems = <int, AppNavItem>{
      0: AppNavItem(
        icon: Icons.home_outlined,
        label: 'Home',
        onTap: () => setState(() => _currentIndex = 0),
      ),
      1: AppNavItem(
        icon: isHr ? Icons.groups_outlined : Icons.task_alt_rounded,
        label: isHr ? 'All Attendance' : 'Tasks',
        onTap: () => setState(() => _currentIndex = 1),
      ),
      2: AppNavItem(
        icon: Icons.calendar_month_outlined,
        label: 'Calendar',
        onTap: () => setState(() => _currentIndex = 2),
      ),
      3: AppNavItem(
        icon: Icons.person_outline_rounded,
        label: 'Profile',
        onTap: () => setState(() => _currentIndex = 3),
      ),
    };

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _visibleTabs.indexOf(_currentIndex),
        items: [for (final tab in _visibleTabs) navItems[tab]!],
      ),
    );
  }
}
