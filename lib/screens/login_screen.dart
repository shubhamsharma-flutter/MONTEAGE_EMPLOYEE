/*import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/login_controller.dart';
import '../infrastructure/routes/admin_routes.dart';
import 'forgot_passwordscreen.dart';
import 'register_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(LoginController());

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF6F1ED),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      SizedBox(height: 18.h),

                      Image.asset(
                        "assets/images/monteage_logo.png",
                        height: 60.h,
                        fit: BoxFit.contain,
                      ),

                      SizedBox(height: 18.h),

                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 18.w,
                          vertical: 18.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24.r),
                          border: Border.all(
                            color: const Color(0xFFEDE2DC),
                            width: 1,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x12000000),
                              blurRadius: 14,
                              offset: Offset(0, 7),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome Back",
                              style: GoogleFonts.manrope(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF241917),
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              "Sign in to your account",
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                color: const Color(0xFF8B7D77),
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            SizedBox(height: 18.h),

                            _Label("Email"),
                            _Input(
                              controller: c.usernameController,
                              hint: "Enter Username",
                              keyboardType: TextInputType.text,
                            ),

                            SizedBox(height: 14.h),

                            _Label("Password"),
                            Obx(() {
                              return _Input(
                                controller: c.passwordController,
                                hint: "Enter Password",
                                obscure: c.isPasswordHidden.value,
                                suffix: IconButton(
                                  onPressed: c.togglePassword,
                                  icon: Icon(
                                    c.isPasswordHidden.value
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: const Color(0xFF8B7D77),
                                  ),
                                ),
                              );
                            }),

                            // SizedBox(height: 10.h),

                            // Align(
                            //   alignment: Alignment.centerRight,
                            //   child: InkWell(
                            //     onTap: () =>
                            //         Get.toNamed(AdminRoutes.forgotpassword),
                            //     child: Text(
                            //       "Forgot Password?",
                            //       style: GoogleFonts.inter(
                            //         fontSize: 12.sp,
                            //         fontWeight: FontWeight.w600,
                            //         color: const Color(0xFF6A3027),
                            //       ),
                            //     ),
                            //   ),
                            // ),

                            SizedBox(height: 18.h),

                            Obx(() {
                              return _ModernButton(
                                text: "Login",
                                loading: c.isLoading.value,
                                onTap: c.isLoading.value ? null : c.loginUser,
                              );
                            }),

                            SizedBox(height: 16.h),
                          ],
                        ),
                      ),

                      const Spacer(),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        text,
        style: GoogleFonts.manrope(
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF241917),
        ),
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;

  const _Input({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(fontSize: 13.sp),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          color: const Color(0xFFB0B0B0),
          fontSize: 13.sp,
        ),
        filled: true,
        fillColor: const Color(0xFFF6F1ED),
        suffixIcon: suffix,
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFFEDE2DC), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFFEDE2DC), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFF6A3027), width: 1.5),
        ),
      ),
    );
  }
}

class _ModernButton extends StatelessWidget {
  final String text;
  final bool loading;
  final VoidCallback? onTap;

  const _ModernButton({
    required this.text,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF6A3027),
          disabledBackgroundColor: const Color(0xFFC9C9C9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: loading
            ? SizedBox(
                height: 22.h,
                width: 22.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                text,
                style: GoogleFonts.manrope(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
*/
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/login_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LoginController controller = Get.isRegistered<LoginController>()
        ? Get.find<LoginController>()
        : Get.put(LoginController());

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF6F1ED),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      SizedBox(height: 18.h),
                      Image.asset(
                        "assets/images/monteage_logo.png",
                        height: 60.h,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: 18.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 18.w,
                          vertical: 18.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24.r),
                          border: Border.all(
                            color: const Color(0xFFEDE2DC),
                            width: 1,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x12000000),
                              blurRadius: 14,
                              offset: Offset(0, 7),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Monteage Corporate World",
                              style: GoogleFonts.manrope(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF241917),
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              "Login to your account",
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                color: const Color(0xFF8B7D77),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 24.h),

                            // User ID Field
                            Text(
                              "User ID",
                              style: GoogleFonts.manrope(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF241917),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            TextField(
                              controller: controller.userIdController,
                              keyboardType: TextInputType.text,
                              textInputAction: TextInputAction.next,
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                color: const Color(0xFF241917),
                              ),
                              decoration: InputDecoration(
                                hintText: "Enter your employee code",
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 13.sp,
                                  color: const Color(0xFFBDB0AB),
                                ),
                                prefixIcon: Icon(
                                  Icons.person_outline_rounded,
                                  color: const Color(0xFF8B7D77),
                                  size: 20.sp,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF6F1ED),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14.w,
                                  vertical: 14.h,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFEDE2DC),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFEDE2DC),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF6A3027),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 16.h),

                            // Password Field
                            Text(
                              "Password",
                              style: GoogleFonts.manrope(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF241917),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Obx(() => TextField(
                              controller: controller.passwordController,
                              obscureText: controller.isPasswordHidden.value,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => controller.login(),
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                color: const Color(0xFF241917),
                              ),
                              decoration: InputDecoration(
                                hintText: "Enter your password",
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 13.sp,
                                  color: const Color(0xFFBDB0AB),
                                ),
                                prefixIcon: Icon(
                                  Icons.lock_outline_rounded,
                                  color: const Color(0xFF8B7D77),
                                  size: 20.sp,
                                ),
                                suffixIcon: GestureDetector(
                                  onTap: controller.togglePasswordVisibility,
                                  child: Icon(
                                    controller.isPasswordHidden.value
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: const Color(0xFF8B7D77),
                                    size: 20.sp,
                                  ),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF6F1ED),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14.w,
                                  vertical: 14.h,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFEDE2DC),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFEDE2DC),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF6A3027),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            )),
                            SizedBox(height: 24.h),

                            // Login Button
                            Obx(() => SizedBox(
                              width: double.infinity,
                              height: 52.h,
                              child: FilledButton(
                                onPressed: controller.isLoading.value
                                    ? null
                                    : controller.login,
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF6A3027),
                                  disabledBackgroundColor:
                                      const Color(0xFFC9C9C9),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                ),
                                child: controller.isLoading.value
                                    ? SizedBox(
                                        height: 22.h,
                                        width: 22.w,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        "Login",
                                        style: GoogleFonts.manrope(
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            )),
                            SizedBox(height: 16.h),
                          ],
                        ),
                      ),
                      const Spacer(),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}