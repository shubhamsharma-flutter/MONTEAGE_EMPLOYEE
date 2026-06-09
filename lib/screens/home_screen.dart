import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/employee_data_controller.dart';

import '../controllers/home_controller.dart';
import '../infrastructure/app_drawer/admin_drawer.dart';
import '../infrastructure/routes/admin_routes.dart';
import 'package:upgrader/upgrader.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final HomeController controller = Get.put(HomeController());
  final EmployeeDataController employeeC =
    Get.isRegistered<EmployeeDataController>()
    ? Get.find<EmployeeDataController>()
    : Get.put(EmployeeDataController());
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return UpgradeAlert(
  barrierDismissible: false,
  upgrader: Upgrader(
    debugDisplayAlways: false,
  ),
  child: Scaffold(
      key: _scaffoldKey,
      drawer: AdminDrawer(),
      backgroundColor: const Color(0xFFF6F1ED),
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 72.h,
        backgroundColor: const Color(0xFFF6F1ED),
        surfaceTintColor: Colors.transparent,
        leadingWidth: 72.w,
        leading: Padding(
          padding: EdgeInsets.only(left: 16.w),
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.menu_rounded, color: Color(0xFF241917)),
              onPressed: () => _scaffoldKey.currentState!.openDrawer(),
            ),
          ),
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MONTEAGE IT SOLUTIONS PVT LTD',
                style: GoogleFonts.manrope(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: const Color(0xFF241917),
                ),
              ),
              Text(
                'Employee dashboard',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF756A66),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroCard(),
              SizedBox(height: 20.h),
              _buildSectionHeader(
                title: 'Quick actions',
                subtitle:
                    'Everything you need to manage today\'s attendance flow.',
              ),
              SizedBox(height: 14.h),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth - 12.w) / 2;

                  return Wrap(
                    spacing: 12.w,
                    runSpacing: 12.h,
                    children: [
                      SizedBox(
  width: 180.w,
  height: 230.h,
  child: _ActionCard(
    eyebrow: 'Attendance',
    title: 'Mark Attendance',
    subtitle: 'Check in or check out with face & location verification.',
    icon: Icons.face_retouching_natural_rounded,
    accent: const Color(0xFF1E8E5A),
    background: const [Color(0xFFE4F7EC), Color(0xFFD6F0E2)],
    onTap: () => Get.toNamed(AdminRoutes.attendance),
  ),
),
                      SizedBox(
                        width: 180.w,
                        height: 230.h,
                        child: _ActionCard(
                          eyebrow: 'Records',
                          title: 'Attendance History',
                          subtitle:
                              'Review past logs and track daily attendance records.',
                          icon: Icons.history_rounded,
                          accent: const Color(0xFF2563EB),
                          background: const [
                            Color(0xFFE6EEFF),
                            Color(0xFFDCE7FF),
                          ],
                          onTap: () =>
                              Get.toNamed(AdminRoutes.attendanceHistory),
                        ),
                      ),
                      SizedBox(
                        width: 180.w,
                        height: 230.h,
                        child: _ActionCard(
                          eyebrow: 'Today',
                          title: 'Today\'s Attendance',
                          subtitle:
                              'See your current status and shift details in one place.',
                          icon: Icons.fact_check_rounded,
                          accent: const Color(0xFF6B5CF6),
                          background: const [
                            Color(0xFFEFECFF),
                            Color(0xFFE6E1FF),
                          ],
                          onTap: () => Get.toNamed(AdminRoutes.attendanceToday),
                        ),
                      ),
                      // SizedBox(
                      //   width: 180.w,
                      //   height: 230.h,
                      //   child: _ActionCard(
                      //     eyebrow: 'End shift',
                      //     title: 'Check Out',
                      //     subtitle:
                      //         'Close the day with a verified check-out submission.',
                      //     icon: Icons.logout_rounded,
                      //     accent: const Color(0xFFC75B2A),
                      //     background: const [
                      //       Color(0xFFFFEBDD),
                      //       Color(0xFFFFE1CC),
                      //     ],
                      //     onTap: () =>
                      //         Get.toNamed(AdminRoutes.checkoutattendace),
                      //   ),
                      // ),
// SizedBox(
//   width: 180.w,
//   height: 230.h,
//   child: _ActionCard(
//     eyebrow: 'Tasks You Assigned',
//     title: 'Given Tasks',
//     subtitle: 'Manage and track the tasks you\'ve assigned, monitor their progress, and ensure completion.',
//     icon: Icons.assignment_rounded,
//     accent: const Color(0xFF00796B), // Accent color (Teal)
//     background: const [
//       Color(0xFFE0F2F1), // Light Teal
//       Color(0xFFB2DFDB), // Pale Teal
//     ],
//     onTap: () => Get.toNamed(AdminRoutes.taskGiven),
//   ),
// ),
// SizedBox(
//   width: 180.w,
//   height: 230.h,
//   child: _ActionCard(
//     eyebrow: 'Tasks Assigned to You',
//     title: 'Received Tasks',
//     subtitle: 'Keep track of your assigned tasks, add progress updates, and mark them complete.',
//     icon: Icons.fact_check_rounded,
//     accent: const Color(0xFFFF7043), // Accent color (Coral)
//     background: const [
//       Color(0xFFFFEBEE), // Light Coral
//       Color(0xFFFFCDD2), // Pale Coral
//     ],
//     onTap: () => Get.toNamed(AdminRoutes.taskReceived),
//   ),
// ),
// SizedBox(
//   width: 180.w,
//   height: 230.h,
//   child: _ActionCard(
//     eyebrow: 'Manage Tasks',
//     title: 'View Task Status',
//     subtitle: 'Monitor and update tasks for efficient workflow.',
//     icon: Icons.task_rounded,
//     accent: const Color(0xFFFF7043), // Green accent for a professional look
//     background: const [
//       Color(0xFFFFEBEE), // Light Coral
//       Color(0xFFFFCDD2), // Slightly deeper mint background
//     ],
//     onTap: () => Get.toNamed(AdminRoutes.task), // Navigate to task screen
//   ),
// ),
SizedBox(
  width: 180.w,
  height: 230.h,
  child: _ActionCard(
    eyebrow: 'Leave/WFH Management',
    title: 'Leave/WFH Approval',
    subtitle: 'Apply for leave/WFH and track your requests.',
    icon: Icons.assignment_rounded,
    accent: const Color(0xFF00796B), // Accent color (Teal)
    background: const [
      Color(0xFFE0F2F1), // Light Teal
      Color(0xFFB2DFDB), // Pale Teal
    ],
    onTap: () => Get.toNamed(AdminRoutes.leaveManagement),
  ),
),
                        
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildHeroCard() {
  return Obx(() {
    final employee = employeeC.employee.value;

    if (employee == null) {
      return _StatusCard(
        icon: Icons.cloud_off_rounded,
        title: 'Profile unavailable',
        description: 'Could not load your profile details.',
        actionLabel: 'Retry',
        onAction: () => employeeC.loadEmployee(),
        accent: const Color(0xFFB54545),
      );
    }

    return Container(
      width: double.infinity,
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
            color: Color(0x2A6A3027),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _TopBadge(
                icon: Icons.auto_awesome_rounded,
                label: 'Workspace',
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
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: CircleAvatar(
                  radius: 30.r,
                  backgroundColor: const Color(0xFFF5E6DF),
                  child: Icon(
                    Icons.person_rounded,
                    color: const Color(0xFF6A3027),
                    size: 32.sp,
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.employeeName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 22.sp,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      employee.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.82),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    _InfoPill(
                      label: employee.designation,
                      icon: Icons.work_outline_rounded,
                      color: const Color(0xFF5F8BFF),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'Employee Code',
                    value: employee.employeeCode,
                  ),
                ),
                _metricDivider(),
                Expanded(
                  child: _MetricTile(
                    label: 'Designation',
                    value: employee.designation,
                  ),
                ),
                _metricDivider(),
                Expanded(
                  child: Obx(
                    () => _MetricTile(
                      label: 'Today',
                      value: controller.selectedDate.value,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  });
}

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: 20.sp,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF221816),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            height: 1.45,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF756A66),
          ),
        ),
      ],
    );
  }

  Widget _metricDivider() {
    return Container(
      height: 34.h,
      width: 1,
      margin: EdgeInsets.symmetric(horizontal: 10.w),
      color: Colors.white.withOpacity(0.16),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.background,
    required this.onTap,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final List<Color> background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24.r),
        child: Ink(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: background,
            ),
            border: Border.all(color: Colors.white.withOpacity(0.55)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: 176.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 44.h,
                      width: 44.h,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Icon(icon, color: accent, size: 24.sp),
                    ),
                    const Spacer(),
                    Container(
                      height: 34.h,
                      width: 34.h,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_outward_rounded,
                        color: accent,
                        size: 18.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                Text(
                  eyebrow.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                    color: accent,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 17.sp,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF201715),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF5F5450),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: color.withOpacity(0.22)),
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

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.72),
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.manrope(
            fontSize: 13.sp,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 54.h,
            width: 54.h,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Icon(icon, color: accent, size: 28.sp),
          ),
          SizedBox(height: 16.h),
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF241917),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B605C),
            ),
          ),
          SizedBox(height: 16.h),
          FilledButton(
            onPressed: onAction,
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
            child: Text(
              actionLabel,
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBadge extends StatelessWidget {
  const _TopBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14.sp),
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
