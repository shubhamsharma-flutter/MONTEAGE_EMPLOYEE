import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/sales_controller.dart';
import '../models/sales_lead_model.dart';
import '../utils/constants/color_constants.dart';
import 'app_ui.dart';
import 'bottom_nav_wrapper.dart';

// ---------------------------------------------------------------------------
// Formatting & actions
// ---------------------------------------------------------------------------

/// Parses the CRM's date strings ("2024-02-10T15:30:00" or "2024/02/10 15:30").
DateTime? parseSalesDate(String raw) {
  final v = raw.trim();
  if (v.isEmpty) return null;
  return DateTime.tryParse(v.replaceAll('/', '-'));
}

String formatSalesDate(String raw, {bool withTime = true}) {
  final date = parseSalesDate(raw);
  if (date == null) return raw.trim().isEmpty ? '-' : raw.trim();
  return DateFormat(
    withTime ? 'dd MMM yyyy, h:mm a' : 'dd MMM yyyy',
  ).format(date);
}

Color salesStatusColor(String action) {
  switch (action.trim().toLowerCase()) {
    case 'registered':
    case 'closed':
      return AppColor.success;
    case 'not interested':
    case 'invalid':
    case 'duplicate':
    case 'not eligible':
      return AppColor.danger;
    case 'not reachable':
      return AppColor.warning;
    case '':
      return AppColor.textMuted;
    default:
      return AppColor.info;
  }
}

Future<void> _launch(Uri uri) async {
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok) {
    Get.snackbar(
      'Not available',
      'No app found to open this.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

void callSalesNumber(String number) =>
    _launch(Uri(scheme: 'tel', path: number.trim()));

void emailSalesContact(String email) =>
    _launch(Uri(scheme: 'mailto', path: email.trim()));

void openSalesLocation(SalesLead lead) => _launch(
  Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=${lead.latitude},${lead.longitude}',
  ),
);

// ---------------------------------------------------------------------------
// Layout pieces
// ---------------------------------------------------------------------------

/// Page frame for Sales screens: two-line app bar plus the app's bottom nav.
class SalesScaffold extends StatelessWidget {
  const SalesScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottomBar,
  });

  final String title;
  final String subtitle;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    return BottomNavWrapper(
      child: Scaffold(
        backgroundColor: AppColor.background,
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Get.back(),
          ),
          titleSpacing: 4.w,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          actions: actions,
        ),
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomBar,
        body: SafeArea(top: false, child: body),
      ),
    );
  }
}

class SalesStatusChip extends StatelessWidget {
  const SalesStatusChip(this.action, {super.key});

  final String action;

  @override
  Widget build(BuildContext context) {
    final color = salesStatusColor(action);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        action.isEmpty ? 'New' : action,
        style: GoogleFonts.inter(
          fontSize: 11.5.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// Icon + label/value line used on lead cards and the lead detail screen.
class SalesInfoRow extends StatelessWidget {
  const SalesInfoRow({
    super.key,
    required this.icon,
    required this.value,
    this.label,
    this.maxLines = 2,
    this.trailing,
  });

  final IconData icon;
  final String value;
  final String? label;
  final int maxLines;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 1.h),
          child: Icon(icon, size: 16.sp, color: AppColor.textMuted),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (label != null)
                Text(
                  label!,
                  style: GoogleFonts.inter(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColor.textMuted,
                  ),
                ),
              Text(
                value.isEmpty ? '-' : value,
                maxLines: maxLines,
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
        ?trailing,
      ],
    );
  }
}

class SalesLeadCard extends StatelessWidget {
  const SalesLeadCard({
    super.key,
    required this.lead,
    required this.onTap,
    this.onUpdate,
  });

  final SalesLead lead;
  final VoidCallback onTap;
  final VoidCallback? onUpdate;

  @override
  Widget build(BuildContext context) {
    final title = lead.organizationName.isNotEmpty
        ? lead.organizationName
        : lead.contactName;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 8.w, 6.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppIconBox(icon: Icons.storefront_rounded),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.isEmpty ? 'Unnamed lead' : title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColor.textPrimary,
                        ),
                      ),
                      if (lead.contactName.isNotEmpty &&
                          lead.contactName != title) ...[
                        SizedBox(height: 2.h),
                        Text(
                          lead.contactName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            color: AppColor.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                SalesStatusChip(lead.action),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: Column(
              children: [
                if (lead.courseName.isNotEmpty) ...[
                  SalesInfoRow(
                    icon: Icons.category_outlined,
                    value: lead.courseName,
                    maxLines: 1,
                  ),
                  SizedBox(height: 6.h),
                ],
                SalesInfoRow(
                  icon: Icons.event_outlined,
                  value:
                      'Last Update Date: ${formatSalesDate(lead.updateDate)}',
                  maxLines: 1,
                ),
                if (lead.remarks.isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  SalesInfoRow(icon: Icons.notes_rounded, value: lead.remarks),
                ],
              ],
            ),
          ),
          SizedBox(height: 4.h),
          const Divider(height: 16),
          Row(
            children: [
              if (lead.mobile.isNotEmpty)
                TextButton.icon(
                  onPressed: () => callSalesNumber(lead.mobile),
                  icon: Icon(Icons.call_rounded, size: 18.sp),
                  label: Text(lead.mobile),
                ),
              const Spacer(),
              if (onUpdate != null)
                TextButton.icon(
                  onPressed: onUpdate,
                  icon: Icon(Icons.edit_calendar_rounded, size: 18.sp),
                  label: const Text('Update'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Update follow-up sheet
// ---------------------------------------------------------------------------

/// Asks for the new status, next follow-up time and remarks, then saves
/// them. Resolves to true when the follow-up was saved.
Future<bool> showSalesFollowupSheet(
  BuildContext context,
  SalesLead lead,
) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
    ),
    builder: (_) => _FollowupSheet(lead: lead),
  );
  if (saved == true) {
    Get.snackbar(
      'Follow-up updated',
      'Your changes were saved.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
  return saved == true;
}

class _FollowupSheet extends StatefulWidget {
  const _FollowupSheet({required this.lead});

  final SalesLead lead;

  @override
  State<_FollowupSheet> createState() => _FollowupSheetState();
}

class _FollowupSheetState extends State<_FollowupSheet> {
  final SalesController _sales = Get.find<SalesController>();
  final TextEditingController _remarks = TextEditingController();

  String? _action;
  DateTime? _followupAt;
  String? _error;

  @override
  void initState() {
    super.initState();
    final current = widget.lead.action;
    if (SalesController.followupActions.contains(current)) _action = current;
  }

  @override
  void dispose() {
    _remarks.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _followupAt ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _followupAt != null
          ? TimeOfDay.fromDateTime(_followupAt!)
          : TimeOfDay.now(),
    );
    if (time == null) return;
    setState(() {
      _followupAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_action == null) {
      setState(() => _error = 'Select a status.');
      return;
    }
    if (_followupAt == null) {
      setState(() => _error = 'Pick the next follow-up date and time.');
      return;
    }
    final error = await _sales.updateFollowup(
      lead: widget.lead,
      action: _action!,
      followupAt: _followupAt!,
      remarks: _remarks.text,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lead = widget.lead;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColor.borderStrong,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Update follow-up',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppColor.textPrimary,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              lead.organizationName.isNotEmpty
                  ? lead.organizationName
                  : lead.contactName,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: AppColor.textMuted,
              ),
            ),
            SizedBox(height: 20.h),
            const AppFieldLabel('Status'),
            DropdownButtonFormField<String>(
              initialValue: _action,
              isExpanded: true,
              hint: const Text('Select status'),
              items: SalesController.followupActions
                  .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                  .toList(),
              onChanged: (v) => setState(() {
                _action = v;
                _error = null;
              }),
            ),
            SizedBox(height: 16.h),
            const AppFieldLabel('Next follow-up'),
            InkWell(
              onTap: _pickDateTime,
              borderRadius: BorderRadius.circular(12.r),
              child: InputDecorator(
                decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.event_rounded),
                ),
                child: Text(
                  _followupAt == null
                      ? 'Pick date & time'
                      : DateFormat('dd MMM yyyy, h:mm a').format(_followupAt!),
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: _followupAt == null
                        ? AppColor.textMuted
                        : AppColor.textPrimary,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            const AppFieldLabel('Remarks'),
            TextField(
              controller: _remarks,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'What happened on this follow-up?',
              ),
            ),
            if (_error != null) ...[
              SizedBox(height: 12.h),
              Text(
                _error!,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColor.danger,
                ),
              ),
            ],
            SizedBox(height: 20.h),
            Obx(
              () => AppPrimaryButton(
                label: 'Save follow-up',
                icon: Icons.check_rounded,
                isLoading: _sales.isSaving.value,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
