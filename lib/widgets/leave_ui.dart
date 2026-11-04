import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../controllers/leave_list_controller.dart';
import 'bottom_nav_wrapper.dart';

/// Colours shared by every leave screen.
class LeaveColors {
  static const background = Color(0xFFF6F1ED);
  static const surface = Colors.white;
  static const ink = Color(0xFF241917);
  static const muted = Color(0xFF756A66);
  static const border = Color(0xFFEDE2DC);
  static const accent = Color(0xFFB54A3A);
  static const accentDark = Color(0xFF6A3027);

  // Dark enough to stay readable as text on white and on tinted backgrounds.
  static const approved = Color(0xFF1E8A57);
  static const pending = Color(0xFFB26A00);
  static const rejected = Color(0xFFC8433F);
}

/// Text styles shared by every leave screen.
class LeaveText {
  static TextStyle heading(double size, {Color color = LeaveColors.ink}) =>
      GoogleFonts.manrope(
        fontSize: size.sp,
        fontWeight: FontWeight.w800,
        color: color,
      );

  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color color = LeaveColors.muted,
  }) => GoogleFonts.inter(fontSize: size.sp, fontWeight: weight, color: color);
}

BoxDecoration leaveCardDecoration() => BoxDecoration(
  color: LeaveColors.surface,
  borderRadius: BorderRadius.circular(20.r),
  border: Border.all(color: LeaveColors.border),
  boxShadow: const [
    BoxShadow(color: Color(0x0F000000), blurRadius: 14, offset: Offset(0, 6)),
  ],
);

String formatLeaveDate(String? raw) {
  final date = parseLeaveDate(raw);
  return date == null ? '-' : DateFormat('dd MMM yyyy').format(date);
}

String leaveDayLabel(int days) => '$days ${days == 1 ? 'day' : 'days'}';

Color leaveStatusColor(String status) {
  switch (status) {
    case 'Approved':
      return LeaveColors.approved;
    case 'Rejected':
      return LeaveColors.rejected;
    case 'Pending':
      return LeaveColors.pending;
    default:
      return LeaveColors.accentDark;
  }
}

IconData leaveStatusIcon(String status) {
  switch (status) {
    case 'Approved':
      return Icons.check_rounded;
    case 'Rejected':
      return Icons.close_rounded;
    case 'Pending':
      return Icons.hourglass_empty_rounded;
    default:
      return Icons.info_outline_rounded;
  }
}

IconData leaveTypeIcon(String? leaveType) {
  final type = (leaveType ?? '').toUpperCase();
  if (type.contains('SICK')) return Icons.medical_services_rounded;
  if (type.contains('PAID')) return Icons.beach_access_rounded;
  if (type.contains('SHORT')) return Icons.timer_rounded;
  if (type.contains('HALF')) return Icons.hourglass_bottom_rounded;
  if (type.contains('HOME') || type.contains('WFH')) {
    return Icons.home_work_rounded;
  }
  return Icons.event_available_rounded;
}

Color leaveTypeColor(String? leaveType) {
  final type = (leaveType ?? '').toUpperCase();
  if (type.contains('SICK')) return const Color(0xFFC8433F);
  if (type.contains('PAID')) return const Color(0xFF00796B);
  if (type.contains('SHORT')) return const Color(0xFF6C4AB6);
  if (type.contains('HALF')) return const Color(0xFFB26A00);
  if (type.contains('HOME') || type.contains('WFH')) {
    return const Color(0xFF2B6CB0);
  }
  return LeaveColors.accent;
}

/// Page frame with the same header style as Attendance History.
class LeaveScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget body;
  final Widget? floatingActionButton;

  const LeaveScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.body,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavWrapper(
      child: Scaffold(
        backgroundColor: LeaveColors.background,
        appBar: AppBar(
          elevation: 0,
          toolbarHeight: 72.h,
          backgroundColor: LeaveColors.background,
          surfaceTintColor: Colors.transparent,
          leadingWidth: 72.w,
          leading: Padding(
            padding: EdgeInsets.only(left: 16.w),
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(
                color: LeaveColors.surface,
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
                tooltip: 'Back',
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: LeaveColors.ink,
                ),
                onPressed: () => Get.back(),
              ),
            ),
          ),
          titleSpacing: 4.w,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: LeaveText.heading(20)),
              Text(subtitle, style: LeaveText.body(12)),
            ],
          ),
        ),
        floatingActionButton: floatingActionButton,
        body: SafeArea(top: false, child: body),
      ),
    );
  }
}

/// Fading placeholder cards shown while a list loads for the first time.
class LeaveLoadingCards extends StatefulWidget {
  final int count;

  const LeaveLoadingCards({super.key, this.count = 4});

  @override
  State<LeaveLoadingCards> createState() => _LeaveLoadingCardsState();
}

class _LeaveLoadingCardsState extends State<LeaveLoadingCards>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
    lowerBound: 0.45,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  Widget _bar(double width, double height) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: LeaveColors.border,
      borderRadius: BorderRadius.circular(8.r),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: FadeTransition(
        opacity: _fade,
        child: Column(
          children: List.generate(
            widget.count,
            (_) => Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(16.w),
              decoration: leaveCardDecoration(),
              child: Row(
                children: [
                  _bar(44.w, 44.w),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _bar(140.w, 14.h),
                        SizedBox(height: 10.h),
                        _bar(double.infinity, 10.h),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Error and empty states: icon, short message and one action.
class LeaveMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final String actionLabel;
  final VoidCallback onAction;

  const LeaveMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              color: LeaveColors.accent.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36.sp, color: LeaveColors.accent),
          ),
          SizedBox(height: 16.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: LeaveText.heading(16),
          ),
          SizedBox(height: 4.h),
          Text(text, textAlign: TextAlign.center, style: LeaveText.body(13)),
          SizedBox(height: 16.h),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: LeaveColors.accent,
              side: const BorderSide(color: LeaveColors.accent),
              minimumSize: const Size(120, 44),
            ),
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class LeaveDetailRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const LeaveDetailRow({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16.sp, color: LeaveColors.muted),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(text, style: LeaveText.body(13, color: LeaveColors.ink)),
        ),
      ],
    );
  }
}
