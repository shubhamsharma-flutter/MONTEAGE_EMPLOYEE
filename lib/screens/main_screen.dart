import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

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

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late List<Widget> _screens; // ← change to late

  @override
void initState() {
  super.initState();

  // Register controllers first
  if (!Get.isRegistered<TaskController>()) Get.put(TaskController());
  if (!Get.isRegistered<EmployeeProfileController>()) Get.put(EmployeeProfileController(), permanent: true);
  if (!Get.isRegistered<HomeController>()) Get.put(HomeController());
  if (!Get.isRegistered<EmployeeDataController>()) Get.put(EmployeeDataController());
   
   if (!Get.isRegistered<TotalAttendanceViewController>()) {
    Get.put(TotalAttendanceViewController());
  }
  if (!Get.isRegistered<HrTodayAttendanceController>()) {
    Get.put(HrTodayAttendanceController());
  }

  // Get employee controller to check role
  final employeeC = Get.find<EmployeeDataController>();

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
      TaskScreen(),
      CalendarScreen(),
      EmployeeProfileScreen(),
    ];
  }

  // Check if a specific tab was requested
  final args = Get.arguments;
  if (args != null && args is Map && args['tab'] != null) {
    _currentIndex = args['tab'] as int;
  }
}
  // rest of code stays the same...


  

  @override
  Widget build(BuildContext context) {
    debugPrint("MAIN SCREEN LOADED");
    final employeeC = Get.find<EmployeeDataController>();
    final isHr = employeeC.isHrManager;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 20,
              offset: Offset(0, -6),
            ),
          ],
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isActive: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                if (isHr)
                  _NavItem(
                    icon: Icons.people_rounded,
                    label: 'All Attendance',
                    isActive: _currentIndex == 1,
                    onTap: () => setState(() => _currentIndex = 1),
                  )
                else
                  _NavItem(
                    icon: Icons.task_rounded,
                    label: 'Tasks',
                    isActive: _currentIndex == 1,
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                _NavItem(
                  icon: Icons.calendar_month_rounded,
                  label: 'Calendar',
                  isActive: isHr ? _currentIndex == 2 : _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = isHr ? 2 : 2),
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  isActive: isHr ? _currentIndex == 3 : _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = isHr ? 3 : 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF6A3027);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isActive ? accent.withOpacity(0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24.sp,
              color: isActive ? accent : const Color(0xFFB0A09A),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? accent : const Color(0xFFB0A09A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}