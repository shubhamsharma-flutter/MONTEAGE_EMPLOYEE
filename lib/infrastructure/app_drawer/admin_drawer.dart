import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:monteage_employee/controllers/employee_data_controller.dart';
import 'package:monteage_employee/infrastructure/utils/pref_manager.dart';

import '../../infrastructure/routes/admin_routes.dart';

class AdminDrawer extends StatefulWidget {
  const AdminDrawer({super.key});

  @override
  State<AdminDrawer> createState() => _AdminDrawerState();
}

class _AdminDrawerState extends State<AdminDrawer> {
  late final EmployeeDataController employeeC =
      Get.isRegistered<EmployeeDataController>()
          ? Get.find<EmployeeDataController>()
          : Get.put(EmployeeDataController());

  @override
  Widget build(BuildContext context) {
    final currentRoute = Get.currentRoute;

    return Drawer(
      width: 328.w,
      backgroundColor: const Color(0xFFF6F1ED),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 10.h),
              child: _buildHeader(context),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Text(
                'Navigate',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: const Color(0xFF8B7D77),
                ),
              ),
            ),
            SizedBox(height: 10.h),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 12.h),
                children: [
                  _DrawerNavItem(
                    title: 'Dashboard',
                    subtitle: 'Back to your attendance overview',
                    icon: Icons.grid_view_rounded,
                    accent: const Color(0xFF6A3027),
                    isActive: currentRoute == AdminRoutes.mainScreen,
                    onTap: () => _openRoute(context, AdminRoutes.mainScreen),
                  ),
                  //SizedBox(height: 10.h),
                  // _DrawerNavItem(
                  //   title: 'Employee Profile',
                  //   subtitle: 'Review your account details',
                  //   icon: Icons.badge_rounded,
                  //   accent: const Color(0xFF2563EB),
                  //   isActive: currentRoute == AdminRoutes.profile,
                  //   onTap: () => _openRoute(context, AdminRoutes.profile),
                  // ),
                  SizedBox(height: 10.h),
                  _DrawerNavItem(
  title: 'Mark Attendance',
  subtitle: 'Check in or check out with face & location',
  icon: Icons.face_retouching_natural_rounded,
  accent: const Color(0xFF1E8E5A),
  isActive: currentRoute == AdminRoutes.attendance,
  onTap: () => _openRoute(context, AdminRoutes.attendance),
),
SizedBox(height: 10.h),
                  // _DrawerNavItem(
                  //   title: 'Mark Attendance',
                  //   subtitle: 'Face and location based check-in',
                  //   icon: Icons.how_to_reg_rounded,
                  //   accent: const Color(0xFF1E8E5A),
                  //   isActive: currentRoute == AdminRoutes.MARK_FACE_ATTENDANCE,
                  //   onTap: () =>
                  //       _openRoute(context, AdminRoutes.MARK_FACE_ATTENDANCE),
                  // ),
                  // SizedBox(height: 10.h),
                  _DrawerNavItem(
                    title: 'Attendance History',
                    subtitle: 'Browse previous attendance records',
                    icon: Icons.history_rounded,
                    accent: const Color(0xFF4F46E5),
                    isActive: currentRoute == AdminRoutes.attendanceHistory,
                    onTap: () =>
                        _openRoute(context, AdminRoutes.attendanceHistory),
                  ),
                  SizedBox(height: 10.h),
                  _DrawerNavItem(
                    title: 'Today\'s Attendance',
                    subtitle: 'Check your current shift status',
                    icon: Icons.fact_check_rounded,
                    accent: const Color.fromARGB(255, 240, 118, 118),
                    isActive: currentRoute == AdminRoutes.attendanceToday,
                    onTap: () =>
                        _openRoute(context, AdminRoutes.attendanceToday),
                  ),
                  SizedBox(height: 10.h),
                  _DrawerNavItem(
                    title: 'Leave/WFH Approval',
                    subtitle: 'Apply and track your leave and WFH requests',
                    icon: Icons.check_circle_rounded,
                    accent: const Color.fromARGB(255, 221, 233, 111),
                    isActive: currentRoute == AdminRoutes.leaveManagement,
                    onTap: () =>
                        _openRoute(context, AdminRoutes.leaveManagement),
                  ),
                  if (employeeC.isHrManager) ...[
                    SizedBox(height: 10.h),
                    _DrawerNavItem(
                      title: 'Employee Registration',
                      subtitle: 'Register new employees',
                      icon: Icons.person_add_rounded,
                      accent: const Color(0xFF6A3027),
                      isActive: currentRoute == AdminRoutes.registerScreen,
                      onTap: () => _openRoute(context, AdminRoutes.registerScreen),
                    ),
                  ],
                  SizedBox(height: 10.h),
                  if (employeeC.isHrManager)
                    _DrawerNavItem(
                      title: 'All Employee Attendance',
                      subtitle: 'View attendance for all employees',
                      icon: Icons.people_rounded,
                      accent: const Color.fromARGB(255, 111, 233, 231),
                      isActive: currentRoute == AdminRoutes.allEmployeeAttendance,
                      onTap: () => _openRoute(context, AdminRoutes.allEmployeeAttendance),
                    )
                  else
                    _DrawerNavItem(
                      title: 'Manage Tasks',
                      subtitle: 'Monitor and update your assigned tasks',
                      icon: Icons.assignment_rounded,
                      accent: const Color.fromARGB(255, 111, 233, 231),
                      isActive: currentRoute == AdminRoutes.task,
                      onTap: () => _openRoute(context, AdminRoutes.task),
                    ),
                 SizedBox(height: 10.h),
                  // _DrawerNavItem(
                  //   title: 'Check Out',
                  //   subtitle: 'Finish the day with a verified exit',
                  //   icon: Icons.logout_rounded,
                  //   accent: const Color(0xFFC75B2A),
                  //   isActive: currentRoute == AdminRoutes.checkoutattendace,
                  //   onTap: () =>
                  //       _openRoute(context, AdminRoutes.checkoutattendace),
                  // ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    height: 44.h,
                    width: 44.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE6E1),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: const Icon(
                      Icons.power_settings_new_rounded,
                      color: Color(0xFFB54545),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Logout',
                          style: GoogleFonts.manrope(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF241917),
                          ),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          'Clear the current session and return to login.',
                          style: GoogleFonts.inter(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF7B6F6A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _logout(context),
                    child: Text(
                      'Exit',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFB54545),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Obx(() {
      final employee = employeeC.employee.value;
      final name = employee?.employeeName ?? 'Monteage Employee';
      final designation = employee?.designation ?? 'Attendance management workspace';
      final employeeId = employee?.employeeId.toString() ?? 'Employee';

      return Container(
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28.r),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF241917), Color(0xFF6A3027), Color(0xFFC75B43)],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x246A3027),
              blurRadius: 22,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.dashboard_customize_rounded,
                          size: 14.sp, color: Colors.white),
                      SizedBox(width: 6.w),
                      Text(
                        'MONTEAGE',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Material(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(16.r),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16.r),
                    onTap: () => employeeC.loadEmployee(),
                    child: Padding(
                      padding: EdgeInsets.all(10.w),
                      child: const Icon(Icons.refresh_rounded,
                          color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 18.h),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(22.r),
                  ),
                  child: CircleAvatar(
                    radius: 28.r,
                    backgroundColor: const Color(0xFFF5E6DF),
                    child: Icon(
                      Icons.person_rounded,
                      color: const Color(0xFF6A3027),
                      size: 30.sp,
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.15,
                        ),
                      ),
                      SizedBox(height: 5.h),
                      Text(
                        designation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.82),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: [
                          _HeaderPill(
                            label: employeeId,
                            icon: Icons.badge_outlined,
                          ),
                          _HeaderPill(
                            label: 'Active',
                            icon: Icons.check_circle_outline,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            InkWell(
              onTap: () => _openRoute(context, AdminRoutes.profile),
              borderRadius: BorderRadius.circular(18.r),
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18.r),
                  border:
                      Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Open full profile',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 18.sp),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _openRoute(BuildContext context, String route) async {
  Navigator.of(context).pop();
  await Future<void>.delayed(const Duration(milliseconds: 120));

  // For main tab routes — go to MainScreen with correct tab
  if (route == AdminRoutes.mainScreen) {
    Get.offAllNamed(AdminRoutes.mainScreen);
    return;
  }
  if (route == AdminRoutes.task) {
    Get.offAllNamed(AdminRoutes.mainScreen, arguments: {'tab': 1});
    return;
  }
  if (route == AdminRoutes.profile) {
    Get.offAllNamed(AdminRoutes.mainScreen, arguments: {'tab': 3});
    return;
  }

  // For all other screens — just push normally
  if (Get.currentRoute == route) return;
  Get.toNamed(route);
}

  Future<void> _logout(BuildContext context) async {
    Navigator.of(context).pop();
    await PrefManager().clearPref();
    
    // Clear all storage
    GetStorage().erase();

    // Delete controllers
    if (Get.isRegistered<EmployeeDataController>()) {
      Get.delete<EmployeeDataController>(force: true);
    }

    Get.offAllNamed(AdminRoutes.login);
    Get.snackbar(
      'Logged Out',
      'You have been logged out successfully.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }
}

class _DrawerNavItem extends StatelessWidget {
  const _DrawerNavItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.isActive,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 14.w),
          decoration: BoxDecoration(
            color: isActive ? accent.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(
              color: isActive
                  ? accent.withOpacity(0.35)
                  : const Color(0xFFEDE2DC),
              width: isActive ? 1.3 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 14,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 44.h,
                width: 44.h,
                decoration: BoxDecoration(
                  color: accent.withOpacity(isActive ? 0.16 : 0.12),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(icon, color: accent, size: 23.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.manrope(
                        color: const Color(0xFF241917),
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF7B6F6A),
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isActive
                    ? Icons.radio_button_checked
                    : Icons.arrow_forward_ios_rounded,
                color: accent,
                size: isActive ? 18.sp : 15.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: Colors.white),
          SizedBox(width: 6.w),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}