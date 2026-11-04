import 'package:monteage_employee/utils/constants/color_constants.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/mark_face_attendance_controller.dart';
import '../controllers/check_out_attendance_controller.dart';
import '../bindings/mark_face_attendance_binding.dart';
import '../bindings/check_out_attendance_binding.dart';
import '../widgets/app_ui.dart';
import '../widgets/bottom_nav_wrapper.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool _isCheckIn = true; // true = Check In, false = Check Out

  late final MarkFaceAttendanceController _checkInC;
  late final CheckOutAttendanceController _checkOutC;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map && args['checkout'] == true) _isCheckIn = false;
    if (!Get.isRegistered<MarkFaceAttendanceController>()) {
      MarkFaceAttendanceBinding().dependencies();
    }
    if (!Get.isRegistered<CheckOutAttendanceController>()) {
      checkoutAttendanceBinding().dependencies();
    }
    _checkInC = Get.find<MarkFaceAttendanceController>();
    _checkOutC = Get.find<CheckOutAttendanceController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInC.ensureLocationFetched();
      _checkOutC.ensureLocationFetched();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavWrapper(
      child: Scaffold(
        appBar: AppBar(title: const Text('Attendance')),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColor.surfaceVariant,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  padding: EdgeInsets.all(4.w),
                  child: Row(
                    children: [
                      _ToggleTab(
                        label: 'Check In',
                        icon: Icons.login_rounded,
                        isActive: _isCheckIn,
                        onTap: () => setState(() => _isCheckIn = true),
                      ),
                      _ToggleTab(
                        label: 'Check Out',
                        icon: Icons.logout_rounded,
                        isActive: !_isCheckIn,
                        onTap: () => setState(() => _isCheckIn = false),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                _isCheckIn
                    ? _AttendanceForm(
                        key: const ValueKey('checkin'),
                        selectedImage: _checkInC.selectedImage,
                        latText: _checkInC.latText,
                        lngText: _checkInC.lngText,
                        addressText: _checkInC.addressText,
                        isLocLoading: _checkInC.isLocLoading,
                        isSubmitting: _checkInC.isSubmittingAttendance,
                        onLocation: _checkInC.fetchLocationAll,
                        onClear: _checkInC.clearPhoto,
                        onTakePhoto: _checkInC.takePhoto,
                        submitLabel: 'Submit Check In',
                        onSubmit: _checkInC.submitAttendance,
                      )
                    : _AttendanceForm(
                        key: const ValueKey('checkout'),
                        selectedImage: _checkOutC.selectedImage,
                        latText: _checkOutC.latText,
                        lngText: _checkOutC.lngText,
                        addressText: _checkOutC.addressText,
                        isLocLoading: _checkOutC.isLocLoading,
                        isSubmitting: _checkOutC.isSubmittingAttendance,
                        onLocation: _checkOutC.fetchLocationAll,
                        onClear: _checkOutC.clearPhoto,
                        onTakePhoto: _checkOutC.takePhoto,
                        submitLabel: 'Submit Check Out',
                        onSubmit: _checkOutC.submitCheckoutAttendance,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleTab extends StatelessWidget {
  const _ToggleTab({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColor.primary : AppColor.textMuted;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: isActive ? AppColor.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(9.r),
            boxShadow: isActive ? AppShadow.card : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18.sp, color: color),
              SizedBox(width: 6.w),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared by check-in and check-out, which only differ in their controller.
class _AttendanceForm extends StatelessWidget {
  const _AttendanceForm({
    super.key,
    required this.selectedImage,
    required this.latText,
    required this.lngText,
    required this.addressText,
    required this.isLocLoading,
    required this.isSubmitting,
    required this.onLocation,
    required this.onClear,
    required this.onTakePhoto,
    required this.submitLabel,
    required this.onSubmit,
  });

  final Rx<File?> selectedImage;
  final RxString latText;
  final RxString lngText;
  final RxString addressText;
  final RxBool isLocLoading;
  final RxBool isSubmitting;
  final VoidCallback onLocation;
  final VoidCallback onClear;
  final VoidCallback onTakePhoto;
  final String submitLabel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: EdgeInsets.all(14.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppSectionTitle(
                title: 'Your photo',
                subtitle: 'Use good light and show your full face.',
              ),
              SizedBox(height: 12.h),
              Obx(() {
                final img = selectedImage.value;
                return _PhotoPreview(
                  img: img,
                  onClear: img != null ? onClear : null,
                );
              }),
              SizedBox(height: 12.h),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: OutlinedButton.icon(
                    onPressed: onTakePhoto,
                    icon: Icon(Icons.photo_camera_outlined, size: 20.sp),
                    label: Text(
                      selectedImage.value == null ? 'Take Photo' : 'Retake Photo',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        AppCard(
          padding: EdgeInsets.all(14.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppIconBox(icon: Icons.location_on_outlined),
              SizedBox(width: 12.w),
              Expanded(
                child: Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current location',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColor.textPrimary,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        addressText.value,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          height: 1.4,
                          color: AppColor.textSecondary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        isLocLoading.value
                            ? 'Fetching location...'
                            : 'Lat ${latText.value}, Lng ${lngText.value}',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: AppColor.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Refresh location',
                onPressed: onLocation,
                icon: const Icon(
                  Icons.my_location_rounded,
                  color: AppColor.primary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),
        Obx(() {
          final loading = isSubmitting.value;
          return AppPrimaryButton(
            label: submitLabel,
            isLoading: loading,
            onPressed: loading ? null : onSubmit,
          );
        }),
      ],
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.img, required this.onClear});

  final File? img;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 220.h,
          decoration: BoxDecoration(
            color: AppColor.background,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: AppColor.border),
            image: img != null
                ? DecorationImage(image: FileImage(img!), fit: BoxFit.cover)
                : null,
          ),
          child: img == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.face_outlined,
                      size: 48.sp,
                      color: AppColor.textDisabled,
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'No photo yet',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: AppColor.textMuted,
                      ),
                    ),
                  ],
                )
              : null,
        ),
        if (onClear != null)
          Positioned(
            top: 8.h,
            right: 8.w,
            child: IconButton.filledTonal(
              tooltip: 'Remove photo',
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded, color: AppColor.danger),
            ),
          ),
      ],
    );
  }
}
