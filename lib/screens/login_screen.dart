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
import 'package:monteage_employee/utils/constants/color_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/login_controller.dart';
import '../widgets/app_ui.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LoginController controller = Get.isRegistered<LoginController>()
        ? Get.find<LoginController>()
        : Get.put(LoginController());

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AppColor.background,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: [
              const _BrandBackdrop(),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(20.w, 32.h, 20.w, 24.h),
                    child: ConstrainedBox(
                      // Keeps the form a sensible width on tablets.
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        children: [
                          const _BrandHeader(),
                          SizedBox(height: 28.h),
                          _LoginCard(controller: controller),
                          SizedBox(height: 24.h),
                          const _Footer(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Navy gradient band behind the top half of the screen.
class _BrandBackdrop extends StatelessWidget {
  const _BrandBackdrop();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: MediaQuery.of(context).size.height * 0.46,
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColor.primaryDark, AppColor.primary],
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32.r)),
        ),
        child: Stack(
          children: [
            // Soft decorative rings for depth.
            Positioned(
              top: -60.h,
              right: -50.w,
              child: _Ring(size: 200.w),
            ),
            Positioned(
              bottom: -80.h,
              left: -60.w,
              child: _Ring(size: 220.w),
            ),
          ],
        ),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 28,
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: AppColor.surface,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Image.asset(
            "assets/images/monteage_logo.png",
            height: 44.h,
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(height: 20.h),
        Text(
          "Employee Portal",
          style: GoogleFonts.inter(
            fontSize: 22.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.2,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          "Monteage Corporate World",
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({required this.controller});

  final LoginController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 24.h),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColor.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Sign in",
              style: GoogleFonts.inter(
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                color: AppColor.textPrimary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              "Use your employee code and password to continue.",
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                height: 1.4,
                color: AppColor.textMuted,
              ),
            ),
            SizedBox(height: 24.h),
            const AppFieldLabel("Employee Code"),
            TextField(
              controller: controller.userIdController,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              autocorrect: false,
              onChanged: (_) => controller.clearError(),
              style: GoogleFonts.inter(
                fontSize: 15.sp,
                color: AppColor.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: "Enter your employee code",
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            SizedBox(height: 16.h),
            const AppFieldLabel("Password"),
            Obx(() => TextField(
                  controller: controller.passwordController,
                  obscureText: controller.isPasswordHidden.value,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  autocorrect: false,
                  enableSuggestions: false,
                  onChanged: (_) => controller.clearError(),
                  onSubmitted: (_) => controller.login(),
                  style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    color: AppColor.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: "Enter your password",
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      tooltip: controller.isPasswordHidden.value
                          ? "Show password"
                          : "Hide password",
                      onPressed: controller.togglePasswordVisibility,
                      icon: Icon(
                        controller.isPasswordHidden.value
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                )),
            Obx(() {
              final error = controller.errorMessage.value;
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: error == null
                    ? SizedBox(height: 24.h)
                    : Padding(
                        key: ValueKey(error),
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        child: _ErrorBanner(message: error),
                      ),
              );
            }),
            Obx(() => AppPrimaryButton(
                  label: "Sign In",
                  icon: Icons.arrow_forward_rounded,
                  isLoading: controller.isLoading.value,
                  onPressed:
                      controller.isLoading.value ? null : controller.login,
                )),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColor.dangerTint,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColor.danger.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 18.sp, color: AppColor.danger),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: AppColor.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final muted = GoogleFonts.inter(fontSize: 12.sp, color: AppColor.textMuted);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user_outlined,
                size: 14.sp, color: AppColor.textMuted),
            SizedBox(width: 6.w),
            Text("Secure access for Monteage employees", style: muted),
          ],
        ),
        SizedBox(height: 6.h),
        Text(
          "Trouble signing in? Contact your HR administrator.",
          textAlign: TextAlign.center,
          style: muted.copyWith(color: AppColor.textDisabled),
        ),
      ],
    );
  }
}
