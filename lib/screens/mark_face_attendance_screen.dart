import 'package:monteage_employee/utils/constants/color_constants.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/mark_face_attendance_controller.dart';
import '../widgets/bottom_nav_wrapper.dart';

class MarkFaceAttendanceScreen extends StatefulWidget {
  const MarkFaceAttendanceScreen({super.key});

  @override
  State<MarkFaceAttendanceScreen> createState() =>
      _MarkFaceAttendanceScreenState();
}

class _MarkFaceAttendanceScreenState extends State<MarkFaceAttendanceScreen> {
  late final MarkFaceAttendanceController c;

  @override
  void initState() {
    super.initState();
    c = Get.find<MarkFaceAttendanceController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      c.ensureLocationFetched();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavWrapper(
      child: Scaffold(
        backgroundColor: AppColor.background,
        appBar: AppBar(
          leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                ),
                onPressed: () => Get.back(),
              ),
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mark Attendance',
                  style: GoogleFonts.inter(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Face verification & location check-in',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
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
                SizedBox(height: 6.h),
                Obx(() {
                  final File? img = c.selectedImage.value;
      
                  return Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 240.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: AppColor.success.withOpacity(0.3),
                            width: 2,
                          ),
                          color: Colors.white,
                          image: img != null
                              ? DecorationImage(
                                  image: FileImage(img),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          boxShadow: AppShadow.card,
                        ),
                        child: img == null
                            ? Center(
                                child: Icon(
                                  Icons.face_rounded,
                                  size: 80.sp,
                                  color: AppColor.success.withOpacity(0.3),
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        left: 12.w,
                        bottom: 12.h,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: AppShadow.card,
                          ),
                          child: Obx(() {
                            final loading = c.isLocLoading.value;
                            return Text(
                              loading
                                  ? 'Fetching location...'
                                  : 'Lat: ${c.latText.value} | Lng: ${c.lngText.value}',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            );
                          }),
                        ),
                      ),
                      Positioned(
                        top: 12.h,
                        left: 12.w,
                        child: _CircleActionButton(
                          icon: Icons.my_location_rounded,
                          onTap: c.fetchLocationAll,
                          accentColor: AppColor.success,
                        ),
                      ),
                      if (img != null)
                        Positioned(
                          top: 12.h,
                          right: 12.w,
                          child: _CircleActionButton(
                            icon: Icons.close_rounded,
                            onTap: c.clearPhoto,
                            accentColor: AppColor.danger,
                          ),
                        ),
                    ],
                  );
                }),
                SizedBox(height: 20.h),
                Text(
                  'Capture Your Face',
                  style: GoogleFonts.inter(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColor.textPrimary,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Take a clear, well-lit photo showing your full face. Make sure there are no shadows or glare.',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: AppColor.textSecondary,
                  ),
                ),
                SizedBox(height: 18.h),
                SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: FilledButton.icon(
                    onPressed: c.takePhoto,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColor.success,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: Text(
                      'Take Photo',
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  'Location Details',
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColor.textPrimary,
                  ),
                ),
                SizedBox(height: 12.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColor.border, width: 1),
                    boxShadow: AppShadow.card,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 48.h,
                        width: 48.h,
                        decoration: BoxDecoration(
                          color: AppColor.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: const Icon(
                          Icons.location_on_outlined,
                          color: AppColor.accent,
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Obx(
                          () => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Location',
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColor.textMuted,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                c.addressText.value,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 13.sp,
                                  height: 1.45,
                                  fontWeight: FontWeight.w500,
                                  color: AppColor.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                Obx(() {
                  final loading = c.isSubmittingAttendance.value;
                  return SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: FilledButton(
                      onPressed: loading ? null : c.submitAttendance,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        disabledBackgroundColor: const Color(
                          0xFF6A3027,
                        ).withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: loading
                          ? SizedBox(
                              width: 24.w,
                              height: 24.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Submit Attendance',
                              style: GoogleFonts.inter(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.icon,
    required this.onTap,
    required this.accentColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: AppShadow.card,
        ),
        child: Icon(icon, size: 20.sp, color: accentColor),
      ),
    );
  }
}
