import 'dart:async';

import 'package:monteage_employee/utils/constants/color_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../controllers/attendance_history_controller.dart';
import '../controllers/employee_data_controller.dart';

import '../controllers/home_controller.dart';
import '../controllers/task_controller.dart';
import '../infrastructure/app_drawer/admin_drawer.dart';
import '../infrastructure/routes/admin_routes.dart';
import '../models/attendance_history_model.dart';
import '../widgets/app_ui.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  static const String _dashboardTag = 'dashboard';

  final HomeController controller = Get.put(HomeController());
  final EmployeeDataController employeeC =
    Get.isRegistered<EmployeeDataController>()
    ? Get.find<EmployeeDataController>()
    : Get.put(EmployeeDataController());
  // Tagged so the Attendance History screen keeps its own controller and alerts.
  final AttendanceHistoryController historyC =
    Get.isRegistered<AttendanceHistoryController>(tag: _dashboardTag)
    ? Get.find<AttendanceHistoryController>(tag: _dashboardTag)
    : Get.put(AttendanceHistoryController(silent: true), tag: _dashboardTag);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  TaskController? get _taskC =>
      Get.isRegistered<TaskController>() ? Get.find<TaskController>() : null;

  Future<void> _refresh() async {
    employeeC.loadEmployee();
    final taskC = _taskC;
    await Future.wait([
      historyC.fetchHistory(),
      if (taskC != null) ...[
        taskC.fetchProjects(),
        taskC.fetchTaskWorks(),
        taskC.fetchReceivedWorks(),
      ],
    ]);
  }

  Future<void> _openAttendance({bool checkout = false}) async {
    await Get.toNamed(
      AdminRoutes.attendance,
      arguments: {'checkout': checkout},
    );
    historyC.fetchHistory();
  }

  void _openTasks() {
    Get.offAllNamed(AdminRoutes.mainScreen, arguments: {'tab': 1});
  }

  Result? get _todayRecord {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    for (final record in historyC.records) {
      if (record.date.startsWith(today)) return record;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: AdminDrawer(),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(bottom: 24.h),
            child: Stack(
              children: [
                Container(
                  height: 236.h,
                  decoration: BoxDecoration(
                    color: AppColor.primary,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(24.r),
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 14.h),
                            _buildPunchCard(),
                            SizedBox(height: 18.h),
                            _buildShortcuts(),
                            SizedBox(height: 20.h),
                            _buildMonthSummary(),
                            if (!employeeC.isHrManager && _taskC != null) ...[
                              SizedBox(height: 20.h),
                              const AppSectionTitle(title: 'My work'),
                              SizedBox(height: 10.h),
                              _buildWorkSummary(_taskC!),
                            ],
                            SizedBox(height: 20.h),
                            _buildMoreLinks(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Obx(() {
      final employee = employeeC.employee.value;
      final details = employee == null
          ? 'Could not load your profile'
          : '${employee.designation}  ·  ${employee.employeeCode}';

      return Padding(
        padding: EdgeInsets.fromLTRB(4.w, 2.h, 16.w, 0),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Menu',
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              onPressed: () => _scaffoldKey.currentState!.openDrawer(),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_greeting()}, ${_firstName(employee?.employeeName)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    details,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            IconButton(
              tooltip: employee == null ? 'Retry' : 'Refresh',
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: _refresh,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPunchCard() {
    return Obx(() {
      // Rebuild when the list changes; _todayRecord reads the same list.
      historyC.records.length;
      final record = _todayRecord;
      final isLoading = historyC.isLoading.value && historyC.records.isEmpty;
      final inTime = _formatTime(record?.timestamp);
      final outTime = _formatTime(record?.checkoutTimestamp);

      return Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 16.h),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColor.border),
          boxShadow: AppShadow.card,
        ),
        child: Column(
          children: [
            const _LiveClock(),
            SizedBox(height: 16.h),
            if (isLoading)
              SizedBox(
                height: 54.h,
                child: const Center(child: CircularProgressIndicator()),
              )
            else if (record == null)
              _PunchButton(
                label: 'Check In',
                icon: Icons.login_rounded,
                color: AppColor.primary,
                onPressed: () => _openAttendance(),
              )
            else if (outTime == null)
              _PunchButton(
                label: 'Check Out',
                icon: Icons.logout_rounded,
                color: AppColor.danger,
                onPressed: () => _openAttendance(checkout: true),
              )
            else
              Container(
                height: 54.h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColor.successTint,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Text(
                  'Attendance complete for today',
                  style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColor.success,
                  ),
                ),
              ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(child: _TimeItem(label: 'Check in', value: inTime)),
                Expanded(child: _TimeItem(label: 'Check out', value: outTime)),
                Expanded(
                  child: _TimeItem(
                    label: 'Hours',
                    value: _workedHours(record),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildShortcuts() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _Shortcut(
            label: 'Leave',
            icon: Icons.event_note_rounded,
            onTap: () => Get.toNamed(AdminRoutes.leaveManagement),
          ),
        ),
        Expanded(
          child: employeeC.isHrManager
              ? _Shortcut(
                  label: 'Employees',
                  icon: Icons.groups_rounded,
                  onTap: () => Get.toNamed(AdminRoutes.allEmployeeAttendance),
                )
              : _Shortcut(
                  label: 'Tasks',
                  icon: Icons.task_alt_rounded,
                  onTap: _openTasks,
                ),
        ),
        Expanded(
          child: _Shortcut(
            label: 'History',
            icon: Icons.history_rounded,
            onTap: () => Get.toNamed(AdminRoutes.attendanceHistory),
          ),
        ),
        Expanded(
          child: _Shortcut(
            label: 'Today',
            icon: Icons.fact_check_rounded,
            onTap: () => Get.toNamed(AdminRoutes.attendanceToday),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthSummary() {
    return Obx(() {
      final month = historyC.filteredRecords;
      final remarks = month.map(historyC.getAttendanceRemark).toList();
      int count(String remark) => remarks.where((r) => r == remark).length;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionTitle(
            title: 'This month',
            subtitle: DateFormat('MMMM yyyy').format(DateTime.now()),
          ),
          SizedBox(height: 10.h),
          AppCard(
            padding: EdgeInsets.symmetric(vertical: 14.h),
            onTap: () => Get.toNamed(AdminRoutes.attendanceHistory),
            child: Row(
              children: [
                Expanded(
                  child: _MonthStat(
                    label: 'Present',
                    value: month.length,
                    color: AppColor.primary,
                  ),
                ),
                Expanded(
                  child: _MonthStat(
                    label: 'On time',
                    value: count('On Time'),
                    color: AppColor.success,
                  ),
                ),
                Expanded(
                  child: _MonthStat(
                    label: 'Late',
                    value: count('Late'),
                    color: AppColor.warning,
                  ),
                ),
                Expanded(
                  child: _MonthStat(
                    label: 'Half day',
                    value: count('Half Day'),
                    color: AppColor.danger,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildWorkSummary(TaskController taskC) {
    return Obx(
      () => AppCard(
        onTap: _openTasks,
        padding: EdgeInsets.symmetric(vertical: 14.h),
        child: Row(
          children: [
            Expanded(
              child: _MonthStat(
                label: 'Projects',
                value: taskC.projects.length,
                color: AppColor.primary,
              ),
            ),
            Expanded(
              child: _MonthStat(
                label: 'Received',
                value: taskC.receivedWorks.length,
                color: AppColor.primary,
              ),
            ),
            Expanded(
              child: _MonthStat(
                label: 'Given',
                value: taskC.taskWorks.length,
                color: AppColor.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreLinks() {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _LinkRow(
            icon: Icons.list_alt_rounded,
            title: 'My Leave Requests',
            onTap: () => Get.toNamed(AdminRoutes.leaveList),
          ),
          if (employeeC.isHrManager) ...[
            const Divider(height: 1),
            _LinkRow(
              icon: Icons.person_add_alt_rounded,
              title: 'Register Employee',
              onTap: () => Get.toNamed(AdminRoutes.registerScreen),
            ),
          ],
          if (employeeC.isSales) ...[
            const Divider(height: 1),
            _LinkRow(
              icon: Icons.handshake_outlined,
              title: 'CRM',
              onTap: () => Get.toNamed(AdminRoutes.crmHome),
            ),
          ],
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _firstName(String? name) {
    final trimmed = (name ?? '').trim();
    return trimmed.isEmpty ? 'there' : trimmed.split(RegExp(r'\s+')).first;
  }

  String? _formatTime(String? timestamp) {
    final parsed = DateTime.tryParse(timestamp ?? '');
    return parsed == null ? null : DateFormat('h:mm a').format(parsed.toLocal());
  }

  String? _workedHours(Result? record) {
    final start = DateTime.tryParse(record?.timestamp ?? '');
    final end = DateTime.tryParse(record?.checkoutTimestamp ?? '');
    if (start == null || end == null) return null;
    final worked = end.difference(start);
    if (worked.isNegative) return null;
    return '${worked.inHours}h ${worked.inMinutes.remainder(60)}m';
  }
}

class _LiveClock extends StatefulWidget {
  const _LiveClock();

  @override
  State<_LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<_LiveClock> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          DateFormat('hh:mm:ss a').format(_now),
          style: GoogleFonts.inter(
            fontSize: 34.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: AppColor.textPrimary,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          DateFormat('EEEE, d MMMM yyyy').format(_now),
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            color: AppColor.textMuted,
          ),
        ),
      ],
    );
  }
}

class _PunchButton extends StatelessWidget {
  const _PunchButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
        icon: Icon(icon, size: 22.sp),
        label: Text(
          label,
          style: GoogleFonts.inter(fontSize: 17.sp, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _TimeItem extends StatelessWidget {
  const _TimeItem({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value ?? '--:--',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: AppColor.textPrimary,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12.sp, color: AppColor.textMuted),
        ),
      ],
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h),
        child: Column(
          children: [
            Container(
              height: 52.h,
              width: 52.h,
              decoration: BoxDecoration(
                color: AppColor.primaryTint,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(icon, color: AppColor.primary, size: 26.sp),
            ),
            SizedBox(height: 6.h),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColor.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthStat extends StatelessWidget {
  const _MonthStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: GoogleFonts.inter(
            fontSize: 22.sp,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(fontSize: 12.sp, color: AppColor.textMuted),
        ),
      ],
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
        child: Row(
          children: [
            Icon(icon, size: 20.sp, color: AppColor.primary),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColor.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20.sp,
              color: AppColor.textDisabled,
            ),
          ],
        ),
      ),
    );
  }
}
