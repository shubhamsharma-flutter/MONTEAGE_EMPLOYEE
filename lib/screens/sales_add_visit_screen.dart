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
      bottomBar: Container(
        decoration: const BoxDecoration(
          color: AppColor.surface,
          border: Border(top: BorderSide(color: AppColor.border)),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 10.h),
            child: Obx(() => AppPrimaryButton(
                  label: 'Save visit',
                  icon: Icons.check_rounded,
                  isLoading: controller.isSubmitting.value,
                  onPressed: controller.submit,
                )),
          ),
        ),
      ),
      body: Form(
        key: controller.formKey,
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            _LocationCard(controller: controller),
            SizedBox(height: 14.h),
            _FormSection(
              icon: Icons.storefront_rounded,
              color: AppColor.primary,
              title: 'Visit details',
              subtitle: 'Where you went and why',
              children: [
                const AppFieldLabel('Visit type *'),
                _VisitTypeField(controller: controller),
                SizedBox(height: 14.h),
                _field(
                  label: 'Organization name *',
                  controller: controller.organizationController,
                  hint: 'e.g. Sunrise Public School',
                  icon: Icons.business_rounded,
                  capitalization: TextCapitalization.words,
                  validator: (v) =>
                      controller.validateRequired(v, 'organization name'),
                ),
                _field(
                  label: 'Organization address *',
                  controller: controller.addressController,
                  hint: 'Street, area, city',
                  icon: Icons.apartment_rounded,
                  keyboard: TextInputType.streetAddress,
                  maxLines: 2,
                  validator: (v) => controller.validateRequired(v, 'address'),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            _FormSection(
              icon: Icons.person_rounded,
              color: AppColor.accent,
              title: 'Contact person',
              subtitle: 'Who you met at the organization',
              children: [
                _field(
                  label: 'Name *',
                  controller: controller.contactNameController,
                  hint: 'Full name',
                  icon: Icons.badge_rounded,
                  capitalization: TextCapitalization.words,
                  validator: (v) =>
                      controller.validateRequired(v, 'contact name'),
                ),
                _field(
                  label: 'Phone *',
                  controller: controller.phoneController,
                  hint: '10-digit mobile number',
                  icon: Icons.phone_iphone_rounded,
                  keyboard: TextInputType.phone,
                  digitsOnly: true,
                  validator: controller.validatePhone,
                ),
                _field(
                  label: 'Alternate phone',
                  controller: controller.alternatePhoneController,
                  hint: 'Optional',
                  icon: Icons.phone_android_rounded,
                  keyboard: TextInputType.phone,
                  digitsOnly: true,
                  validator: (v) =>
                      controller.validatePhone(v, required: false),
                ),
                _field(
                  label: 'Email',
                  controller: controller.emailController,
                  hint: 'Optional',
                  icon: Icons.alternate_email_rounded,
                  keyboard: TextInputType.emailAddress,
                  validator: controller.validateEmail,
                ),
              ],
            ),
            SizedBox(height: 14.h),
            _FormSection(
              icon: Icons.sticky_note_2_rounded,
              color: AppColor.warning,
              title: 'Notes',
              subtitle: 'Summary of the conversation',
              children: [
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

/// Card with an icon/title header that groups related form fields.
class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIconBox(
                icon: icon,
                color: color,
                background: color.withValues(alpha: 0.10),
                size: 38,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColor.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: AppColor.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          const Divider(height: 1, color: AppColor.border),
          SizedBox(height: 14.h),
          ...children,
        ],
      ),
    );
  }
}

class _VisitTypeField extends StatelessWidget {
  const _VisitTypeField({required this.controller});

  final SalesAddVisitController controller;

  @override
  Widget build(BuildContext context) => Obx(_build);

  Widget _build() {
    if (controller.isLoadingTypes.value) {
      return const InputDecorator(
        decoration: InputDecoration(prefixIcon: Icon(Icons.category_rounded)),
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
      icon: const Icon(Icons.expand_more_rounded),
      decoration:
          const InputDecoration(prefixIcon: Icon(Icons.category_rounded)),
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
    return Obx(() {
      final locating = controller.isLocating.value;
      final error = controller.locationError.value;
      final hasFix = controller.latitude.value != null;
      final color = error.isNotEmpty
          ? AppColor.warning
          : hasFix
              ? AppColor.success
              : AppColor.primary;
      final status = locating
          ? 'Locating…'
          : error.isNotEmpty
              ? 'Location needed'
              : hasFix
                  ? 'Location captured'
                  : 'Tap to capture';

      return Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: controller.captureLocation,
            borderRadius: BorderRadius.circular(14.r),
            child: Padding(
              padding: EdgeInsets.all(14.w),
              child: Row(
                children: [
                  Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      error.isNotEmpty
                          ? Icons.location_off_rounded
                          : hasFix
                              ? Icons.where_to_vote_rounded
                              : Icons.my_location_rounded,
                      color: color,
                      size: 22.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          status,
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          locating
                              ? 'Finding your current location…'
                              : error.isNotEmpty
                                  ? error
                                  : controller.locationText.value,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            height: 1.35,
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
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: color,
                          ),
                        )
                      : Icon(
                          Icons.refresh_rounded,
                          color: AppColor.textMuted,
                          size: 20.sp,
                        ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
