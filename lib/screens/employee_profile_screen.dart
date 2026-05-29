import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/profile_controller.dart';

class EmployeeProfileScreen extends GetView<EmployeeProfileController> {
  const EmployeeProfileScreen({super.key});

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String value,
    Color? accentColor,
  }) {
    final accent = accentColor ?? const Color(0xFF6A3027);

    return Container(
      padding: EdgeInsets.all(16.w),
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
      child: Row(
        children: [
          Container(
            height: 48.h,
            width: 48.h,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(icon, color: accent, size: 24.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8B7D77),
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF241917),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge({
    required String text,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: color),
          SizedBox(width: 6.w),
          Text(
            text,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 11.sp,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1ED),
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 72.h,
        backgroundColor: const Color(0xFFF6F1ED),
        surfaceTintColor: Colors.transparent,
        leadingWidth: 72.w,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile Details',
                style: GoogleFonts.manrope(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF241917),
                ),
              ),
              Text(
                'Your account information',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF756A66),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                SizedBox(height: 16.h),
                Text(
                  'Loading your profile',
                  style: GoogleFonts.manrope(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF241917),
                  ),
                ),
              ],
            ),
          );
        }

        final p = controller.profile.value;
        if (p == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 62.h,
                  width: 62.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB54545).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: const Icon(
                    Icons.cloud_off_rounded,
                    color: Color(0xFFB54545),
                    size: 28,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Profile not available',
                  style: GoogleFonts.manrope(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF241917),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'We could not load your details. Try again.',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF756A66),
                  ),
                ),
                SizedBox(height: 20.h),
                FilledButton(
                  onPressed: controller.fetchProfile,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFB54545),
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 14.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: Text(
                    'Retry',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          );
        }

        final u = p.user;
        final imgUrl = controller.fullImageUrl(u.profileImage);
        final displayName = controller.titleCase(
          u.fullName.isNotEmpty ? u.fullName : '${u.firstName} ${u.lastName}',
        );

        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(18.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28.r),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF241917),
                        Color(0xFF6A3027),
                        Color(0xFFC75B43),
                      ],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x2A6A3027),
                        blurRadius: 22,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(3.w),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(24.r),
                            ),
                            child: CircleAvatar(
                              radius: 32.r,
                              backgroundColor: const Color(0xFFF5E6DF),
                              child: ClipOval(
                                child: imgUrl.isEmpty
                                    ? Icon(
                                        Icons.person_rounded,
                                        color: const Color(0xFF6A3027),
                                        size: 36.sp,
                                      )
                                    : Image.network(
                                        imgUrl,
                                        width: 64.r,
                                        height: 64.r,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Icon(
                                          Icons.person_rounded,
                                          color: const Color(0xFF6A3027),
                                          size: 36.sp,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.manrope(
                                    fontSize: 22.sp,
                                    height: 1.15,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                Text(
                                  controller.titleCase(u.department),
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withOpacity(0.82),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Material(
                          //   color: Colors.white.withOpacity(0.14),
                          //   borderRadius: BorderRadius.circular(16.r),
                          //   child: InkWell(
                          //     borderRadius: BorderRadius.circular(16.r),
                          //     onTap: controller.goToFaceRegister,
                          //     child: Padding(
                          //       padding: EdgeInsets.all(10.w),
                          //       child: const Icon(
                          //         Icons.edit_rounded,
                          //         color: Colors.white,
                          //       ),
                          //     ),
                          //   ),
                         // ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: [
                          _statusBadge(
                            text: u.isActive ? 'Active' : 'Inactive',
                            icon: u.isActive
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: u.isActive
                                ? const Color(0xFF2AB673)
                                : const Color(0xFFD85E5E),
                          ),
                          _statusBadge(
                            text: u.isFaceRegistered
                                ? 'Face Verified'
                                : 'Face Pending',
                            icon: u.isFaceRegistered
                                ? Icons.verified_user
                                : Icons.face_retouching_off,
                            color: u.isFaceRegistered
                                ? const Color(0xFF5F8BFF)
                                : const Color(0xFFF0A43C),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  'Account Information',
                  style: GoogleFonts.manrope(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF241917),
                  ),
                ),
                SizedBox(height: 12.h),
                _infoTile(
                  icon: Icons.badge_rounded,
                  title: 'Employee Code',
                  value: u.employeeId,
                  accentColor: const Color(0xFF2563EB),
                ),
                SizedBox(height: 12.h),
                _infoTile(
                  icon: Icons.person_rounded,
                  title: 'Full Name',
                  value: displayName,
                  accentColor: const Color(0xFF6A3027),
                ),
                SizedBox(height: 12.h),
                _infoTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Username',
                  value: controller.titleCase(u.username),
                  accentColor: const Color(0xFF1E8E5A),
                ),
                SizedBox(height: 12.h),
                _infoTile(
                  icon: Icons.email_rounded,
                  title: 'Email Address',
                  value: u.email,
                  accentColor: const Color(0xFF4F46E5),
                ),
                // SizedBox(height: 12.h),
                // _infoTile(
                //   icon: Icons.tag_rounded,
                //   title: 'User ID',
                //   value: u.id.toString(),
                //   accentColor: const Color(0xFF7C3AED),
                // ),
                SizedBox(height: 24.h),
                Text(
                  'Verification Details',
                  style: GoogleFonts.manrope(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF241917),
                  ),
                ),
                SizedBox(height: 12.h),
                _infoTile(
                  icon: Icons.face_retouching_natural_rounded,
                  title: 'Face Registered At',
                  value: controller.formatDateTimeIndian(u.faceRegisteredAt),
                  accentColor: const Color(0xFF0F9D9A),
                ),
                SizedBox(height: 12.h),
                _infoTile(
                  icon: Icons.calendar_today_rounded,
                  title: 'Date Joined',
                  value: controller.formatDateOnlyIndian(u.dateJoined),
                  accentColor: const Color(0xFFC75B2A),
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        );
      }),
    );
  }
}
