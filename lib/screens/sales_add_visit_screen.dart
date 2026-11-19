import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/sales_add_visit_controller.dart';
import '../models/sales_lead_model.dart';
import '../utils/constants/color_constants.dart';
import '../widgets/app_ui.dart';
import '../widgets/sales_ui.dart';

class SalesAddVisitScreen extends GetView<SalesAddVisitController> {
  const SalesAddVisitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SalesScaffold(
      title: 'Add Visit',
      subtitle: 'Log a new client visit',
      bottomBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
          child: Obx(() => AppPrimaryButton(
                label: 'Save visit',
                icon: Icons.check_rounded,
                isLoading: controller.isSubmitting.value,
                onPressed: controller.submit,
              )),
        ),
      ),
      body: Form(
        key: controller.formKey,
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            _LocationCard(controller: controller),
            SizedBox(height: 20.h),
            const AppSectionTitle(title: 'Visit'),
            SizedBox(height: 12.h),
            const AppFieldLabel('Visit type *'),
            Obx(() => _VisitTypeField(controller: controller)),
            SizedBox(height: 14.h),
            _field(
              label: 'Organization name *',
              controller: controller.organizationController,
              hint: 'e.g. Sunrise Public School',
              icon: Icons.business_outlined,
              capitalization: TextCapitalization.words,
              validator: (v) =>
                  controller.validateRequired(v, 'organization name'),
            ),
            _field(
              label: 'Organization address *',
              controller: controller.addressController,
              hint: 'Street, area, city',
              icon: Icons.location_city_outlined,
              keyboard: TextInputType.streetAddress,
              maxLines: 2,
              validator: (v) => controller.validateRequired(v, 'address'),
            ),
            SizedBox(height: 6.h),
            const AppSectionTitle(title: 'Contact person'),
            SizedBox(height: 12.h),
            _field(
              label: 'Name *',
              controller: controller.contactNameController,
              hint: 'Full name',
              icon: Icons.person_outline_rounded,
              capitalization: TextCapitalization.words,
              validator: (v) => controller.validateRequired(v, 'contact name'),
            ),
            _field(
              label: 'Phone *',
              controller: controller.phoneController,
              hint: '10-digit mobile number',
              icon: Icons.phone_outlined,
              keyboard: TextInputType.phone,
              digitsOnly: true,
              validator: controller.validatePhone,
            ),
            _field(
              label: 'Alternate phone',
              controller: controller.alternatePhoneController,
              hint: 'Optional',
              icon: Icons.phone_android_outlined,
              keyboard: TextInputType.phone,
              digitsOnly: true,
              validator: (v) => controller.validatePhone(v, required: false),
            ),
            _field(
              label: 'Email',
              controller: controller.emailController,
              hint: 'Optional',
              icon: Icons.email_outlined,
              keyboard: TextInputType.emailAddress,
              validator: controller.validateEmail,
            ),
            _field(
              label: 'Remarks *',
              controller: controller.remarksController,
              hint: 'What was discussed?',
              icon: Icons.notes_rounded,
              maxLines: 3,
              capitalization: TextCapitalization.sentences,
              validator: (v) => controller.validateRequired(v, 'remarks'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboard = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.none,
    bool digitsOnly = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppFieldLabel(label),
          TextFormField(
            controller: controller,
            keyboardType: keyboard,
            textCapitalization: capitalization,
            maxLines: maxLines,
            maxLength: digitsOnly ? 10 : null,
            inputFormatters:
                digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
            validator: validator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon),
              counterText: '',
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitTypeField extends StatelessWidget {
  const _VisitTypeField({required this.controller});

  final SalesAddVisitController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoadingTypes.value) {
      return const InputDecorator(
        decoration: InputDecoration(prefixIcon: Icon(Icons.category_outlined)),
        child: LinearProgressIndicator(),
      );
    }
    if (controller.visitTypes.isEmpty) {
      return InputDecorator(
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.error_outline_rounded),
          suffixIcon: IconButton(
            tooltip: 'Retry',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: controller.loadVisitTypes,
          ),
        ),
        child: Text(
          controller.typesError.value.isEmpty
              ? 'No visit types available.'
              : controller.typesError.value,
          style: GoogleFonts.inter(fontSize: 13.sp, color: AppColor.danger),
        ),
      );
    }
    return DropdownButtonFormField<SalesVisitType>(
      initialValue: controller.selectedType.value,
      isExpanded: true,
      hint: const Text('Select visit type'),
      decoration:
          const InputDecoration(prefixIcon: Icon(Icons.category_outlined)),
      items: controller.visitTypes
          .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
          .toList(),
      onChanged: (t) => controller.selectedType.value = t,
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.controller});

  final SalesAddVisitController controller;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: controller.captureLocation,
      child: Obx(() {
        final locating = controller.isLocating.value;
        final error = controller.locationError.value;
        final hasFix = controller.latitude.value != null;
        final color = error.isNotEmpty
            ? AppColor.warning
            : hasFix
                ? AppColor.success
                : AppColor.primary;

        return Row(
          children: [
            AppIconBox(
              icon: error.isNotEmpty
                  ? Icons.location_off_rounded
                  : Icons.my_location_rounded,
              color: color,
              background: color.withValues(alpha: 0.10),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your current location',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColor.textMuted,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    locating
                        ? 'Finding your location…'
                        : error.isNotEmpty
                            ? error
                            : controller.locationText.value,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColor.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            locating
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.refresh_rounded,
                    color: AppColor.textMuted, size: 20.sp),
          ],
        );
      }),
    );
  }
}
