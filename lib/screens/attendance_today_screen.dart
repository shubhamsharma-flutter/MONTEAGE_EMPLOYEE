import 'package:monteage_employee/utils/constants/color_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/attendance_today_controller.dart';
import '../models/attendance_today.dart';
import '../widgets/bottom_nav_wrapper.dart';

class AttendanceTodayScreen extends StatelessWidget {
  const AttendanceTodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AttendanceTodayController>();

    return BottomNavWrapper(
      child: Scaffold(
        backgroundColor: AppColor.background,
        appBar: AppBar(
          leading: Padding(
            padding: EdgeInsets.only(left: 12.w),
            child: Container(
              decoration: BoxDecoration(
                color: Color(0x29FFFFFF),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Get.back(),
                  borderRadius: BorderRadius.circular(12.r),
                  child: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 22.sp,
                  ),
                ),
              ),
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Today's Attendance",
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                "View your check-in details",
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          centerTitle: false,
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0x29FFFFFF),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: c.fetchToday,
                    borderRadius: BorderRadius.circular(12.r),
                    child: Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 22.sp,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Obx(() {
          if (c.isLoading.value) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColor.primary),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Loading attendance...',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: AppColor.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }
      
          final AttendanceToday? data = c.today.value;
          if (data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy_rounded,
                    size: 80.sp,
                    color: AppColor.borderStrong.withOpacity(0.6),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    "No attendance marked today",
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColor.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    "Mark your attendance to see details",
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: AppColor.textMuted,
                    ),
                  ),
                ],
              ),
            );
          }
      
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Column(
                children: [
                  _TodayAttendanceCard(data, c),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _TodayAttendanceCard extends StatelessWidget {
  final AttendanceToday data;
  final AttendanceTodayController c;
  const _TodayAttendanceCard(this.data, this.c);

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case "VERIFIED":
        return AppColor.success;
      case "REJECTED":
        return AppColor.danger;
      default:
        return AppColor.warning;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toUpperCase()) {
      case "VERIFIED":
        return Icons.check_circle_rounded;
      case "REJECTED":
        return Icons.cancel_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(data.status);
    final statusIcon = _statusIcon(data.status);

    final lat = data.location.latitude;
    final lng = data.location.longitude;
    final acc = data.location.accuracy;

    //final address = c.cleanAddress(data.location.address);
    final address = c.resolvedAddress.value;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColor.border, width: 1),
        boxShadow: AppShadow.card,
      ),
      child: Column(
        children: [
          // Header with gradient
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColor.primaryDark, AppColor.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _ddMMyyyy(data.timestamp),
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        _timeAmPm(data.timestamp),
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: Colors.white, size: 16.sp),
                      SizedBox(width: 6.w),
                      Text(
                        data.status,
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Marked',
                  value: data.marked ? 'Yes' : 'No',
                  valueColor: data.marked
                      ? AppColor.success
                      : AppColor.textMuted,
                ),
                SizedBox(height: 12.h),
                _InfoRow(
                  icon: Icons.verified_outlined,
                  label: 'Verified',
                  value: data.isVerified ? 'Yes' : 'No',
                  valueColor: data.isVerified
                      ? AppColor.success
                      : AppColor.danger,
                ),
                SizedBox(height: 12.h),

                // Confidence
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColor.background,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColor.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.psychology_rounded,
                            size: 20.sp,
                            color: AppColor.primary,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Confidence Score',
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColor.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.r),
                              child: LinearProgressIndicator(
                                value: data.confidenceScore,
                                minHeight: 8.h,
                                backgroundColor: AppColor.borderStrong,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  data.confidenceScore > 0.7
                                      ? AppColor.success
                                      : data.confidenceScore > 0.4
                                      ? AppColor.warning
                                      : AppColor.danger,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            '${(data.confidenceScore * 100).toStringAsFixed(1)}%',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: data.confidenceScore > 0.7
                                  ? AppColor.success
                                  : data.confidenceScore > 0.4
                                  ? AppColor.warning
                                  : AppColor.danger,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12.h),

                // Location + Address
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColor.background,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColor.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: AppColor.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.location_on_rounded,
                          color: AppColor.accent,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Location',
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColor.textPrimary,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              address,
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                color: AppColor.textMuted,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              'Lat: ${lat == null ? "--" : lat.toStringAsFixed(6)}',
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                color: AppColor.textMuted,
                              ),
                            ),
                            Text(
                              'Lng: ${lng == null ? "--" : lng.toStringAsFixed(6)}',
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                color: AppColor.textMuted,
                              ),
                            ),
                            Text(
                              'Accuracy: ${acc == null ? "--" : acc.toStringAsFixed(0)} m',
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                color: AppColor.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12.h),

                // Face Analysis
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColor.background,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColor.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.face_retouching_natural,
                            size: 20.sp,
                            color: AppColor.primary,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            "Face Analysis",
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColor.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        "Quality Score: ${data.faceAnalysis.qualityScore.toStringAsFixed(2)}",
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: AppColor.textMuted,
                        ),
                      ),
                      Text(
                        "Landmarks Detected: ${data.faceAnalysis.landmarksDetected}",
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: AppColor.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _ddMMyyyy(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return "${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}";
    } catch (_) {
      return "--";
    }
  }

  String _timeAmPm(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
      final ampm = d.hour >= 12 ? "PM" : "AM";
      return "${hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} $ampm";
    } catch (_) {
      return "--";
    }
  }
}

// Info Row
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: AppColor.textMuted),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: AppColor.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: valueColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: valueColor),
          ),
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}
