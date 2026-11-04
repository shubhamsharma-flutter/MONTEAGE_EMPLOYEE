import 'package:monteage_employee/utils/constants/color_constants.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/FaceRegisterController.dart';

class FaceRegisterScreen extends StatelessWidget {
  const FaceRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ ensure single instance
    if (!Get.isRegistered<FaceRegisterController>()) {
      Get.put(FaceRegisterController());
    }
    final controller = Get.find<FaceRegisterController>();

    return Scaffold(
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
              "Face Registration",
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              "Register your face for attendance",
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        child: Column(
          children: [
            SizedBox(height: 10.h),

            Obx(() {
              final File? img = controller.selectedImage.value;

              return Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 240.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColor.success,
                        width: 2.5,
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
                              Icons.camera_alt_rounded,
                              size: 72.sp,
                              color: AppColor.success,
                            ),
                          )
                        : null,
                  ),

                  if (img != null)
                    Positioned(
                      top: 12.h,
                      right: 12.w,
                      child: _circleIcon(
                        icon: Icons.close,
                        onTap: controller.clearPhoto,
                      ),
                    ),
                ],
              );
            }),

            SizedBox(height: 20.h),

            Text(
              "Capture Your Face",
              style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: AppColor.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "Make sure your face is clearly visible and well-lit",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: AppColor.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),

            SizedBox(height: 24.h),

            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: FilledButton.icon(
                onPressed: controller.takePhoto,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColor.success,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                icon: Icon(Icons.camera_alt_rounded, size: 22.sp),
                label: Text(
                  "Take Photo",
                  style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            Obx(() {
              final loading = controller.isSubmitting.value;
              return SizedBox(
                width: double.infinity,
                height: 52.h,
                child: FilledButton.icon(
                  onPressed: loading ? null : controller.submitRegistration,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    disabledBackgroundColor: AppColor.textDisabled,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  icon: loading
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Icon(Icons.check_circle_outline, size: 20.sp),
                  label: Text(
                    loading ? "Registering..." : "Submit Registration",
                    style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }),

            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }

  Widget _circleIcon({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: AppShadow.card,
        ),
        child: Icon(icon, size: 18.sp, color: AppColor.success),
      ),
    );
  }
}
