import 'package:monteage_employee/utils/constants/color_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;

  // Mock attendance data: date -> status
  final Map<String, String> _attendanceData = {
    _fmt(DateTime.now().subtract(const Duration(days: 1))): 'present',
    _fmt(DateTime.now().subtract(const Duration(days: 2))): 'present',
    _fmt(DateTime.now().subtract(const Duration(days: 3))): 'absent',
    _fmt(DateTime.now().subtract(const Duration(days: 5))): 'present',
    _fmt(DateTime.now().subtract(const Duration(days: 6))): 'present',
    _fmt(DateTime.now().subtract(const Duration(days: 7))): 'leave',
    _fmt(DateTime.now().subtract(const Duration(days: 8))): 'present',
    _fmt(DateTime.now().subtract(const Duration(days: 9))): 'present',
    _fmt(DateTime.now().subtract(const Duration(days: 10))): 'absent',
  };

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  List<DateTime?> _buildCalendarDays() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // 0=Sun

    final List<DateTime?> days = [];
    for (int i = 0; i < startWeekday; i++) {
      days.add(null);
    }
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(_focusedMonth.year, _focusedMonth.month, i));
    }
    return days;
  }

  Color _dayColor(String status) {
    switch (status) {
      case 'present':
        return AppColor.success;
      case 'absent':
        return AppColor.danger;
      case 'leave':
        return AppColor.info;
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = _buildCalendarDays();
    final monthName =
        ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
         'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][_focusedMonth.month];

    // Stats for current month
    final monthDays = _attendanceData.entries.where((e) {
      final d = DateTime.tryParse(e.key);
      return d != null &&
          d.month == _focusedMonth.month &&
          d.year == _focusedMonth.year;
    });
    final presentCount =
        monthDays.where((e) => e.value == 'present').length;
    final absentCount =
        monthDays.where((e) => e.value == 'absent').length;
    final leaveCount =
        monthDays.where((e) => e.value == 'leave').length;

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 16.w,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calendar',
              style: GoogleFonts.inter(
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              'Your attendance overview',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
          child: Column(
            children: [
              // ── Stats Row ──────────────────────────────────────
              Container(
                padding:
                    EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: AppShadow.card,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatChip(
                      label: 'Present',
                      value: '$presentCount',
                      color: AppColor.success,
                      icon: Icons.check_circle_rounded,
                    ),
                    Container(
                        width: 1,
                        height: 36.h,
                        color: AppColor.border),
                    _StatChip(
                      label: 'Absent',
                      value: '$absentCount',
                      color: AppColor.danger,
                      icon: Icons.cancel_rounded,
                    ),
                    Container(
                        width: 1,
                        height: 36.h,
                        color: AppColor.border),
                    _StatChip(
                      label: 'Leave',
                      value: '$leaveCount',
                      color: AppColor.info,
                      icon: Icons.beach_access_rounded,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // ── Calendar Card ──────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: AppShadow.card,
                ),
                child: Column(
                  children: [
                    // Month navigator
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 20.h, 12.w, 0),
                      child: Row(
                        children: [
                          Text(
                            '$monthName ${_focusedMonth.year}',
                            style: GoogleFonts.inter(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColor.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded,
                                color: AppColor.primary),
                            onPressed: _previousMonth,
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded,
                                color: AppColor.primary),
                            onPressed: _nextMonth,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8.h),

                    // Weekday headers
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: Row(
                        children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                            .map(
                              (d) => Expanded(
                                child: Center(
                                  child: Text(
                                    d,
                                    style: GoogleFonts.inter(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w700,
                                      color: AppColor.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    SizedBox(height: 8.h),

                    // Calendar grid
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 12.w, vertical: 4.h),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 7,
                        childAspectRatio: 1,
                        children: days.map((day) {
                          if (day == null) return const SizedBox();
                          final key = _fmt(day);
                          final status = _attendanceData[key];
                          final isToday = _fmt(day) == _fmt(DateTime.now());
                          final isSelected = _selectedDay != null &&
                              _fmt(day) == _fmt(_selectedDay!);
                          final bgColor = status != null
                              ? _dayColor(status)
                              : Colors.transparent;

                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedDay = day),
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 180),
                              margin: EdgeInsets.all(3.w),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColor.textPrimary
                                    : status != null
                                        ? bgColor.withOpacity(0.15)
                                        : Colors.transparent,
                                borderRadius:
                                    BorderRadius.circular(10.r),
                                border: isToday
                                    ? Border.all(
                                        color: AppColor.primary,
                                        width: 1.5)
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${day.day}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.sp,
                                      fontWeight: isToday || isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : status != null
                                              ? _dayColor(status)
                                              : AppColor.textPrimary,
                                    ),
                                  ),
                                  if (status != null)
                                    Container(
                                      margin:
                                          EdgeInsets.only(top: 2.h),
                                      width: 4.w,
                                      height: 4.w,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected
                                            ? Colors.white
                                            : _dayColor(status),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Legend
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 20.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _LegendDot(
                              color: AppColor.success,
                              label: 'Present'),
                          SizedBox(width: 16.w),
                          _LegendDot(
                              color: AppColor.danger,
                              label: 'Absent'),
                          SizedBox(width: 16.w),
                          _LegendDot(
                              color: AppColor.info,
                              label: 'Leave'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Selected Day Detail ────────────────────────────
              if (_selectedDay != null) ...[
                SizedBox(height: 16.h),
                _DayDetailCard(
                  day: _selectedDay!,
                  status: _attendanceData[_fmt(_selectedDay!)],
                  statusColor: _attendanceData[_fmt(_selectedDay!)] != null
                      ? _dayColor(_attendanceData[_fmt(_selectedDay!)]!)
                      : AppColor.textMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label, value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 22.sp, color: color),
        SizedBox(height: 4.h),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: AppColor.textPrimary)),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: AppColor.textMuted)),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 5.w),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: AppColor.textSecondary)),
      ],
    );
  }
}

class _DayDetailCard extends StatelessWidget {
  const _DayDetailCard({
    required this.day,
    required this.status,
    required this.statusColor,
  });

  final DateTime day;
  final String? status;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final dayNames = [
      '', 'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    final monthNames = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: AppShadow.card,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              '${day.day}',
              style: GoogleFonts.inter(
                fontSize: 24.sp,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${dayNames[day.weekday]}, ${monthNames[day.month]} ${day.year}',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColor.textPrimary,
                  ),
                ),
                SizedBox(height: 6.h),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    status != null
                        ? status![0].toUpperCase() + status!.substring(1)
                        : 'No Record',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}