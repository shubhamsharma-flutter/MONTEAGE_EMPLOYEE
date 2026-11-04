import 'package:monteage_employee/utils/constants/color_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/forgot_passwordcontroller.dart';

class ForgotPasswordScreen extends GetView<ForgotPasswordController> {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: const Text("Forgot Password"),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),

              Text(
                "Reset your password",
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColor.textPrimary,
                ),
              ),

              SizedBox(height: 6.h),

              Text(
                "Enter your registered email address and we’ll send you reset instructions.",
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColor.textMuted,
                ),
              ),

              SizedBox(height: 24.h),

              Text(
                "Email",
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColor.textSecondary,
                ),
              ),

              SizedBox(height: 8.h),

              TextField(
                controller: controller.emailC,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: "Enter your email",
                  hintStyle: TextStyle(
                    color: AppColor.textDisabled,
                    fontSize: 13.sp,
                  ),
                  filled: true,
                  fillColor: AppColor.surfaceVariant,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 14.h,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              SizedBox(height: 24.h),

              Obx(() => SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.sendResetLink,
                  style: ElevatedButton.styleFrom(
                    disabledBackgroundColor: AppColor.primaryLight,
                    disabledForegroundColor: Colors.white,
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                      : Text(
                    "Send Reset Link",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
