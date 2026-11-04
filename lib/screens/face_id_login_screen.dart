import 'package:monteage_employee/utils/constants/color_constants.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/face_id_login_controller.dart';

class FaceIdLoginScreen extends GetView<FaceIdLoginController> {
  const FaceIdLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        centerTitle: false,
        leading: Padding(
          padding: EdgeInsets.only(left: 12.w),
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 8.h),
            decoration: BoxDecoration(
              color: Color(0x29FFFFFF),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: IconButton(
              onPressed: () => Get.back(),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18.sp,
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Face ID Login",
              style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              "Login using face verification",
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 8.h),

              Obx(() {
                final File? file = controller.selectedImage.value;

                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: controller.isFaceMatched.value
                          ? Colors.green
                          : controller.isFaceDetected.value
                          ? AppColor.success
                          : AppColor.border,
                      width: 1.4,
                    ),
                    boxShadow: AppShadow.card,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 300.h,
                        decoration: BoxDecoration(
                          color: AppColor.background,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: controller.isFaceMatched.value
                                ? Colors.green
                                : controller.isFaceDetected.value
                                ? AppColor.success
                                : AppColor.border,
                            width: 1.6,
                          ),
                          image: file != null
                              ? DecorationImage(
                            image: FileImage(file),
                            fit: BoxFit.cover,
                          )
                              : null,
                        ),
                        child: file == null
                            ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                height: 80.h,
                                width: 80.w,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: AppShadow.card,
                                ),
                                child: Icon(
                                  Icons.face_retouching_natural,
                                  size: 42.sp,
                                  color: AppColor.primary,
                                ),
                              ),
                              SizedBox(height: 14.h),
                              Text(
                                "No image selected",
                                style: GoogleFonts.inter(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColor.textPrimary,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                "Tap on Open Camera to scan your face",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  color: AppColor.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                            : Stack(
                          children: [
                            if (controller.isFaceMatched.value)
                              Positioned(
                                top: 12.h,
                                right: 12.w,
                                child: Container(
                                  padding: EdgeInsets.all(8.w),
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 20.sp,
                                  ),
                                ),
                              )
                            else if (controller.isFaceDetected.value)
                              Positioned(
                                top: 12.h,
                                right: 12.w,
                                child: Container(
                                  padding: EdgeInsets.all(8.w),
                                  decoration: const BoxDecoration(
                                    color: AppColor.success,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.face,
                                    color: Colors.white,
                                    size: 20.sp,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      SizedBox(height: 18.h),

                      Obx(
                            () => Text(
                          controller.statusMessage.value,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            color: controller.isFaceMatched.value
                                ? Colors.green
                                : AppColor.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      SizedBox(height: 12.h),

                      Obx(() {
                        if (controller.matchStatus.value.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        final bool isMatched = controller.isFaceMatched.value;

                        return Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 12.h,
                          ),
                          decoration: BoxDecoration(
                            color: isMatched
                                ? AppColor.successTint
                                : AppColor.dangerTint,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: isMatched
                                  ? Colors.green
                                  : AppColor.danger,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isMatched
                                    ? Icons.verified_rounded
                                    : Icons.error_outline_rounded,
                                color: isMatched
                                    ? Colors.green
                                    : AppColor.danger,
                                size: 20.sp,
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Text(
                                  controller.matchStatus.value,
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: isMatched
                                        ? Colors.green
                                        : AppColor.danger,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      SizedBox(height: 12.h),

                      Obx(() {
                        if (!controller.isFaceMatched.value ||
                            controller.userData.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(14.w),
                          decoration: BoxDecoration(
                            color: AppColor.successTint,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Matched User Details",
                                style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.green,
                                ),
                              ),
                              SizedBox(height: 10.h),
                              _detailRow(
                                "Name",
                                "${controller.userData['full_name'] ?? ''}",
                              ),
                              _detailRow(
                                "Username",
                                "${controller.userData['username'] ?? ''}",
                              ),
                              _detailRow(
                                "Employee ID",
                                "${controller.userData['employee_id'] ?? ''}",
                              ),
                              _detailRow(
                                "Department",
                                "${controller.userData['department'] ?? ''}",
                              ),
                              _detailRow(
                                "Confidence",
                                controller.confidenceScore.value.toString(),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }),

              SizedBox(height: 24.h),

              SizedBox(
                width: double.infinity,
                height: 54.h,
                child: ElevatedButton.icon(
                  onPressed:
                  controller.isChecking.value ? null : controller.takePhoto,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    disabledBackgroundColor: AppColor.textDisabled,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  icon: Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 22.sp,
                  ),
                  label: Text(
                    "Open Camera",
                    style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 14.h),

              Obx(() {
                return SizedBox(
                  width: double.infinity,
                  height: 54.h,
                  child: ElevatedButton(
                    onPressed: controller.isChecking.value ||
                        !controller.isFaceMatched.value
                        ? null
                        : controller.verifyAndGoToHome,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: controller.isFaceMatched.value
                          ? Colors.green
                          : AppColor.success,
                      disabledBackgroundColor: AppColor.textDisabled,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: controller.isChecking.value
                        ? SizedBox(
                      height: 22.h,
                      width: 22.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                        : Text(
                      "Verify Face ID",
                      style: GoogleFonts.inter(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              }),

              SizedBox(height: 14.h),

              Obx(() {
                if (controller.selectedImage.value == null) {
                  return const SizedBox.shrink();
                }

                return SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: OutlinedButton.icon(
                    onPressed:
                    controller.isChecking.value ? null : controller.clearPhoto,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColor.primary,
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: AppColor.primary,
                      size: 20.sp,
                    ),
                    label: Text(
                      "Retake Image",
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColor.primary,
                      ),
                    ),
                  ),
                );
              }),

              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 7.h),
      child: Row(
        children: [
          SizedBox(
            width: 95.w,
            child: Text(
              "$title :",
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: AppColor.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: AppColor.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}