
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/hr_today_attendance_model.dart';
import '../controllers/hr_today_attendance_controller.dart';

// ─────────────────────────────────────────────────────────────
//  ATTENDANCE LOGIC
//  Rules:
//   Check-In:
//    • Up to 10:10 AM (inclusive) → On Time
//    • After 10:10 AM & before 12:00 PM → Late Coming
//    • 12:00 PM or later → Half Day
//   Check-Out:
//    • Before 4:00 PM → Short Leave
//    • After 5:30 PM → Overtime (shows duration)
// ─────────────────────────────────────────────────────────────
class _AttendanceLogic {
  static const int _onTimeMax      = 10 * 60 + 10; // 10:10 AM
  static const int _halfDayFrom    = 12 * 60;       // 12:00 PM
  static const int _shortLeaveMax  = 16 * 60;       // 04:00 PM
  static const int _stdEnd         = 18 * 60 + 30;  // 05:30 PM

  static int? _toMins(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final parts = raw.trim().split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  static String _fmtOvertime(int mins) {
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  static List<_Badge> getBadges(HrTodayAttendanceModel item) {
    final inMins  = _toMins(item.checkInTime);
    final outMins = _toMins(item.checkOutTime);
    final badges  = <_Badge>[];

    // ── Check-In ─────────────────────────────────
    if (inMins != null) {
      if (inMins <= _onTimeMax) {
        badges.add(_Badge.onTime());
      } else if (inMins < _halfDayFrom) {
        badges.add(_Badge.lateComing());
      } else {
        badges.add(_Badge.halfDay());
      }
    }

    // ── Check-Out ────────────────────────────────
    if (outMins != null) {
      if (outMins < _shortLeaveMax) {
        badges.add(_Badge.shortLeave());
      } else if (outMins > _stdEnd) {
        badges.add(_Badge.overtime(_fmtOvertime(outMins - _stdEnd)));
      }
    }

    return badges;
  }
}

// ─────────────────────────────────────────────────────────────
//  BADGE MODEL
// ─────────────────────────────────────────────────────────────
class _Badge {
  final String  label;
  final Color   bg;
  final Color   fg;
  final IconData icon;

  const _Badge({
    required this.label,
    required this.bg,
    required this.fg,
    required this.icon,
  });

  factory _Badge.onTime() => const _Badge(
        label: 'On Time',
        bg:    Color(0xFFE9F9EE),
        fg:    Color(0xFF1E8E3E),
        icon:  Icons.check_circle_outline,
      );

  factory _Badge.lateComing() => const _Badge(
        label: 'Late Coming',
        bg:    Color(0xFFFFF4E5),
        fg:    Color(0xFFE67E22),
        icon:  Icons.watch_later_outlined,
      );

  factory _Badge.halfDay() => const _Badge(
        label: 'Half Day',
        bg:    Color(0xFFFFEEEE),
        fg:    Color(0xFFD93025),
        icon:  Icons.timelapse,
      );

  factory _Badge.shortLeave() => const _Badge(
        label: 'Short Leave',
        bg:    Color(0xFFEEF2FF),
        fg:    Color(0xFF3D5AFE),
        icon:  Icons.logout,
      );

  factory _Badge.overtime(String duration) => _Badge(
        label: 'OT: $duration',
        bg:    const Color(0xFFE8F5E9),
        fg:    const Color(0xFF2E7D32),
        icon:  Icons.trending_up,
      );
}

// ─────────────────────────────────────────────────────────────
//  TODAY'S ATTENDANCE VIEW (all employees, today's snapshot)
// ─────────────────────────────────────────────────────────────
class HrTodayAttendanceView extends GetView<HrTodayAttendanceController> {
  const HrTodayAttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        centerTitle: true,
        title: Text(
          "Today's Attendance",
          style: GoogleFonts.manrope(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1E1E),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () => showSearch(
              context: context,
              delegate: HrTodayAttendanceSearchDelegate(
                attendanceList: controller.attendanceData.toList(),
                controller: controller,
              ),
            ),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.errorMessage.value.isNotEmpty) {
          return _ErrorState(message: controller.errorMessage.value);
        }
        if (controller.attendanceData.isEmpty) {
          return const _EmptyState();
        }
        return RefreshIndicator(
          onRefresh: () => controller.fetchAttendance(),
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            itemCount: controller.attendanceData.length,
            separatorBuilder: (_, __) => SizedBox(height: 12.h),
            itemBuilder: (context, index) => _AttendanceCard(
              item: controller.attendanceData[index],
              controller: controller,
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SEARCH DELEGATE
// ─────────────────────────────────────────────────────────────
class HrTodayAttendanceSearchDelegate extends SearchDelegate {
  final List<HrTodayAttendanceModel> attendanceList;
  final HrTodayAttendanceController controller;

  HrTodayAttendanceSearchDelegate({
    required this.attendanceList,
    required this.controller,
  });

  List<HrTodayAttendanceModel> _filter(String q) {
    if (q.trim().isEmpty) return attendanceList;
    final lq = q.toLowerCase();
    return attendanceList.where((item) =>
        (item.fullName   ?? '').toLowerCase().contains(lq) ||
        (item.employeeId ?? '').toLowerCase().contains(lq) ||
        (item.department ?? '').toLowerCase().contains(lq) ||
        (item.status     ?? '').toLowerCase().contains(lq) ||
        (item.email      ?? '').toLowerCase().contains(lq),
    ).toList();
  }

  @override
  String? get searchFieldLabel => 'Search by name, ID, department...';

  @override
  TextStyle? get searchFieldStyle => GoogleFonts.manrope(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF1E1E1E),
      );

  @override
  ThemeData appBarTheme(BuildContext context) => Theme.of(context).copyWith(
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        inputDecorationTheme: InputDecorationTheme(
          border: InputBorder.none,
          hintStyle: GoogleFonts.manrope(
            fontSize: 14.sp,
            color: const Color(0xFF8A8A8A),
          ),
        ),
        textTheme: TextTheme(
          titleLarge: GoogleFonts.manrope(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E1E1E),
          ),
        ),
      );

  @override
  List<Widget>? buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.black87),
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context)     => _list(_filter(query));

  @override
  Widget buildSuggestions(BuildContext context) => _list(_filter(query));

  Widget _list(List<HrTodayAttendanceModel> results) {
    if (results.isEmpty) {
      return Center(
        child: Text(
          'No matching attendance found',
          style: GoogleFonts.manrope(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF444444),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: results.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (_, i) => _AttendanceCard(
        item: results[i],
        controller: controller,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  ATTENDANCE CARD
// ─────────────────────────────────────────────────────────────
class _AttendanceCard extends StatelessWidget {
  final HrTodayAttendanceModel item;
  final HrTodayAttendanceController controller;

  const _AttendanceCard({required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    final badges = _AttendanceLogic.getBadges(item);

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────
          _header(),
          SizedBox(height: 10.h),

          // ── Attendance Status Badges ─────────────
          if (badges.isNotEmpty) ...[
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: badges.map(_buildBadgeChip).toList(),
            ),
            SizedBox(height: 12.h),
          ],

          // ── Info Rows ────────────────────────────
          _infoRow('Employee ID',    item.employeeId),
          _infoRow('Department',     item.department),
          _infoRow('Check In Date',  item.checkInDate),
          _infoRow('Check In Time',  item.checkInTime),
          _infoRow('Check Out Time', item.checkOutTime),
          _infoRow('Total Time',     item.totalTime),
          SizedBox(height: 10.h),

          // ── Photos ───────────────────────────────
          _imageBlock('Check-in Photo',  item.imageUrl),
          _imageBlock('Check-out Photo', item.checkoutImageUrl),
        ],
      ),
    );
  }

  // ── Header: avatar + name/email + status chip ──
  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 24.r,
          backgroundColor: const Color(0xFFEDEFF3),
          child: Text(
            _initials(item.fullName),
            style: GoogleFonts.manrope(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2A2A2A),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.fullName ?? 'No Name',
                style: GoogleFonts.manrope(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F1F1F),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                item.email ?? '-',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: const Color(0xFF7A7A7A),
                ),
              ),
            ],
          ),
        ),
        _statusChip(item.status),
      ],
    );
  }

  // ── Attendance badge chip (On Time / Late / etc.) ──
  Widget _buildBadgeChip(_Badge badge) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: badge.bg,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: badge.fg.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badge.icon, size: 12.sp, color: badge.fg),
          SizedBox(width: 4.w),
          Text(
            badge.label,
            style: GoogleFonts.manrope(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: badge.fg,
            ),
          ),
        ],
      ),
    );
  }

  // ── Info row ──────────────────────────────────
  Widget _infoRow(String title, String? value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110.w,
            child: Text(
              '$title:',
              style: GoogleFonts.manrope(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6E6E6E),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.isNotEmpty == true ? value! : '-',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF222222),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Present / Absent / Late server status chip ──
  Widget _statusChip(String? status) {
    final value = (status ?? 'Unknown').trim();
    Color bg, fg;
    switch (value.toLowerCase()) {
      case 'present':
      case 'verified':
        bg = const Color(0xFFE9F9EE); fg = const Color(0xFF1E8E3E);
        break;
      case 'absent':
        bg = const Color(0xFFFFEEEE); fg = const Color(0xFFD93025);
        break;
      case 'late':
        bg = const Color(0xFFFFF4E5); fg = const Color(0xFFE67E22);
        break;
      default:
        bg = const Color(0xFFF2F4F7); fg = const Color(0xFF667085);
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: Text(
        value,
        style: GoogleFonts.manrope(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  // ── Photo block ───────────────────────────────
  Widget _imageBlock(String title, String? url) {
    final full = controller.fullImageUrl(url);
    if (full.isEmpty) return const SizedBox();
    return Padding(
      padding: EdgeInsets.only(top: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF241917),
            ),
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(14.r),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                full,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFF1F1F1),
                  alignment: Alignment.center,
                  child: Text(
                    'Image unavailable',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: const Color(0xFF8B7D77),
                    ),
                  ),
                ),
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: const Color(0xFFF1F1F1),
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

// ─────────────────────────────────────────────────────────────
//  EMPTY STATE
// ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 56.sp, color: Colors.grey),
            SizedBox(height: 14.h),
            Text(
              'No attendance data found',
              style: GoogleFonts.manrope(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF222222),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Attendance records will appear here once available.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: const Color(0xFF777777),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  ERROR STATE
// ─────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56.sp, color: Colors.redAccent),
            SizedBox(height: 14.h),
            Text(
              'Something went wrong',
              style: GoogleFonts.manrope(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF222222),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: const Color(0xFF777777),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
