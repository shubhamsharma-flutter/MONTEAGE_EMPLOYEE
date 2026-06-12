import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/employee_data_controller.dart';
import '../controllers/register_controller.dart';
import '../infrastructure/routes/admin_routes.dart';
import 'FaceRegisterScreen.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final employeeC = Get.isRegistered<EmployeeDataController>()
        ? Get.find<EmployeeDataController>()
        : Get.put(EmployeeDataController());

    if (!employeeC.isHrManager) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
          backgroundColor: const Color(0xFF6A3027),
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Only HR Managers can access employee registration.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF241917),
                  ),
                ),
                SizedBox(height: 18.h),
                FilledButton(
                  onPressed: () => Get.offAllNamed(AdminRoutes.mainScreen),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6A3027),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Back to Dashboard',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final controller = Get.isRegistered<RegisterController>()
        ? Get.find<RegisterController>()
        : Get.put(RegisterController());

    return Obx(
      () => Scaffold(
        backgroundColor: const Color(0xFFF6F1ED),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
            child: Column(
              children: [
                SizedBox(height: 18.h),
                Image.asset(
                  'assets/images/monteage_logo.png',
                  height: 60.h,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 18.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 18.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(color: const Color(0xFFEDE2DC), width: 1),
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
                        'Create Account',
                        style: GoogleFonts.manrope(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF241917),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'Sign up to get started',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          color: const Color(0xFF8B7D77),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 18.h),
                      Form(
                        key: controller.formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label('First Name'),
                            _Input(
                              controller: controller.firstNameController,
                              hint: 'Enter First Name',
                              keyboardType: TextInputType.text,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'First Name is required';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 14.h),
                            _Label('Last Name'),
                            _Input(
                              controller: controller.lastNameController,
                              hint: 'Enter Last Name',
                              keyboardType: TextInputType.text,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Last Name is required';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 14.h),
                            _Label('Department'),
                            _Input(
                              controller: controller.departmentController,
                              hint: 'Enter Department',
                              keyboardType: TextInputType.text,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Department is required';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 14.h),
                            _Label('Email'),
                            _Input(
                              controller: controller.emailController,
                              hint: 'Enter Email',
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Email is required';
                                }
                                if (!GetUtils.isEmail(value)) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 14.h),
                            _Label('Employee Code'),
                            _Input(
                              controller: controller.employeeIdController,
                              hint: 'Enter Your Employee Code',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Employee Code is required';
                                }
                                if (!GetUtils.isNum(value)) {
                                  return 'EmployeeId must be numeric';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 14.h),
                            _Label('Password'),
                            _Input(
                              controller: controller.passwordController,
                              hint: 'Enter Password',
                              obscure: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password is required';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 14.h),
                            _Label('Confirm Password'),
                            _Input(
                              controller: controller.confirmPasswordController,
                              hint: 'Confirm Password',
                              obscure: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Confirm password is required';
                                }
                                if (value != controller.passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 18.h),
                            _ModernButton(
                              text: 'Sign Up',
                              loading: controller.isLoading.value,
                              onTap: controller.register,
                            ),
                            SizedBox(height: 10.h),
                            Center(
                              child: GestureDetector(
                                onTap: () {
                                  Get.offAll(() => const FaceRegisterScreen());
                                },
                                child: Text(
                                  'Already have an account? Login',
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF6A3027),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 16.h),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
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
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;

  const _Input({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
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
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
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
      validator: validator,
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
