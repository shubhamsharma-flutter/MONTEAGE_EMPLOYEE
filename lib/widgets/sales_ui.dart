import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/sales_controller.dart';
import '../models/sales_lead_model.dart';
import '../services/sales_api.dart';
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

/// "Today, 3:30 PM", "Yesterday, …", "Tomorrow, …", else "12 Feb, 3:30 PM".
String formatSalesRelative(String raw) {
  final date = parseSalesDate(raw);
  if (date == null) return raw.trim().isEmpty ? '-' : raw.trim();
  final today = DateUtils.dateOnly(DateTime.now());
  final days = DateUtils.dateOnly(date).difference(today).inDays;
  final time = DateFormat('h:mm a').format(date);
  if (days == 0) return 'Today, $time';
  if (days == -1) return 'Yesterday, $time';
  if (days == 1) return 'Tomorrow, $time';
  return DateFormat(
    date.year == today.year ? 'dd MMM, h:mm a' : 'dd MMM yyyy',
  ).format(date);
}

/// Subtitle shown under each list's title.
String salesListCaption(SalesListType type) {
  switch (type) {
    case SalesListType.todayVisits:
      return 'Visits logged today';
    case SalesListType.allVisits:
      return 'Every visit you have logged';
    case SalesListType.todayFollowups:
      return 'Leads to contact today';
    case SalesListType.completedToday:
      return 'Follow-ups completed today';
    case SalesListType.nextDay:
      return 'Scheduled for tomorrow';
    case SalesListType.nextWeek:
      return 'Scheduled for the coming week';
  }
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

IconData salesStatusIcon(String action) {
  switch (action.trim().toLowerCase()) {
    case 'registered':
      return Icons.verified_rounded;
    case 'closed':
      return Icons.check_circle_rounded;
    case 'not interested':
      return Icons.thumb_down_alt_rounded;
    case 'invalid':
      return Icons.block_rounded;
    case 'duplicate':
      return Icons.content_copy_rounded;
    case 'not eligible':
      return Icons.do_not_disturb_on_rounded;
    case 'not reachable':
      return Icons.phone_missed_rounded;
    case 'contacted':
      return Icons.mark_chat_read_rounded;
    case 'in progress':
      return Icons.autorenew_rounded;
    case 'next session':
      return Icons.event_repeat_rounded;
    case '':
      return Icons.fiber_new_rounded;
    default:
      return Icons.flag_rounded;
  }
}

String salesInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  if (parts.isEmpty) return '?';
  final first = parts.first[0];
  final second = parts.length > 1 ? parts.elementAt(1)[0] : '';
  return (first + second).toUpperCase();
}

const List<Color> _avatarPalette = [
  AppColor.primary,
  AppColor.accent,
  AppColor.info,
  Color(0xFF7C3AED),
  Color(0xFFC2410C),
  Color(0xFFBE185D),
];

/// A stable colour per name, so a lead keeps its avatar colour everywhere.
Color salesAvatarColor(String name) =>
    _avatarPalette[name.trim().toLowerCase().hashCode.abs() %
        _avatarPalette.length];

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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 19.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.8),
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

/// Rounded square with the initials of [name].
class SalesAvatar extends StatelessWidget {
  const SalesAvatar({super.key, required this.name, this.size = 44});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = salesAvatarColor(name);
    return Container(
      width: size.w,
      height: size.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular((size * 0.3).r),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        salesInitials(name),
        style: GoogleFonts.inter(
          fontSize: (size * 0.36).sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
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
      padding: EdgeInsets.fromLTRB(7.w, 4.h, 10.w, 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(salesStatusIcon(action), size: 13.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            action.isEmpty ? 'New' : action,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small icon + text pill for secondary facts (visit type, dates).
class SalesMetaPill extends StatelessWidget {
  const SalesMetaPill({
    super.key,
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? AppColor.textSecondary;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color == null
            ? AppColor.surfaceVariant
            : fg.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.sp, color: fg),
          SizedBox(width: 5.w),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tinted icon + label/value line used on the lead detail screen.
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
      children: [
        AppIconBox(
          icon: icon,
          size: 36,
          color: AppColor.textSecondary,
          background: AppColor.surfaceVariant,
        ),
        SizedBox(width: 12.w),
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
                  fontSize: 13.5.sp,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
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
    final showContact =
        lead.contactName.isNotEmpty && lead.contactName != title;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SalesAvatar(name: title.isEmpty ? '?' : title),
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
                          if (showContact) ...[
                            SizedBox(height: 3.h),
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline_rounded,
                                  size: 14.sp,
                                  color: AppColor.textMuted,
                                ),
                                SizedBox(width: 4.w),
                                Expanded(
                                  child: Text(
                                    lead.contactName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5.sp,
                                      fontWeight: FontWeight.w500,
                                      color: AppColor.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    SalesStatusChip(lead.action),
                  ],
                ),
                SizedBox(height: 12.h),
                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: [
                    if (lead.courseName.isNotEmpty)
                      SalesMetaPill(
                        icon: Icons.category_rounded,
                        label: lead.courseName,
                        color: AppColor.primary,
                      ),
                    if (lead.updateDate.isNotEmpty)
                      SalesMetaPill(
                        icon: Icons.update_rounded,
                        label: 'Updated ${formatSalesRelative(lead.updateDate)}',
                      ),
                  ],
                ),
                if (lead.remarks.isNotEmpty) ...[
                  SizedBox(height: 10.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: AppColor.background,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.format_quote_rounded,
                          size: 16.sp,
                          color: AppColor.textDisabled,
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            lead.remarks,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12.5.sp,
                              height: 1.4,
                              color: AppColor.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 10.h),
          const Divider(height: 1, color: AppColor.border),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
            child: Row(
              children: [
                if (lead.mobile.isNotEmpty)
                  _CardAction(
                    icon: Icons.call_rounded,
                    label: lead.mobile,
                    color: AppColor.success,
                    onTap: () => callSalesNumber(lead.mobile),
                  ),
                if (lead.hasLocation)
                  _CardAction(
                    icon: Icons.directions_rounded,
                    label: 'Map',
                    color: AppColor.accent,
                    onTap: () => openSalesLocation(lead),
                  ),
                const Spacer(),
                if (onUpdate != null)
                  _CardAction(
                    icon: Icons.edit_calendar_rounded,
                    label: 'Update',
                    color: AppColor.primary,
                    onTap: onUpdate!,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardAction extends StatelessWidget {
  const _CardAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: color,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        textStyle: GoogleFonts.inter(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      icon: Icon(icon, size: 17.sp),
      label: Text(label),
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
    backgroundColor: AppColor.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (_) => _FollowupSheet(lead: lead),
  );
  if (saved == true) {
    Get.snackbar(
      'Follow-up updated',
      'Your changes were saved.',
      snackPosition: SnackPosition.BOTTOM,
      icon: const Icon(Icons.check_circle_rounded, color: AppColor.success),
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
  static const _presets = <(String, int)>[
    ('Tomorrow', 1),
    ('In 3 days', 3),
    ('Next week', 7),
  ];

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

  /// [days] from today at 10:00 AM.
  DateTime _presetDate(int days) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + days, 10);
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
    final name = lead.organizationName.isNotEmpty
        ? lead.organizationName
        : lead.contactName;

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
            Row(
              children: [
                SalesAvatar(name: name.isEmpty ? '?' : name, size: 42),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Update follow-up',
                        style: GoogleFonts.inter(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColor.textPrimary,
                        ),
                      ),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          color: AppColor.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            _SheetLabel(icon: Icons.flag_rounded, text: 'Status'),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                for (final a in SalesController.followupActions)
                  _StatusOption(
                    action: a,
                    selected: _action == a,
                    onTap: () => setState(() {
                      _action = a;
                      _error = null;
                    }),
                  ),
              ],
            ),
            SizedBox(height: 20.h),
            _SheetLabel(icon: Icons.event_rounded, text: 'Next follow-up'),
            Row(
              children: [
                for (var i = 0; i < _presets.length; i++) ...[
                  if (i > 0) SizedBox(width: 8.w),
                  Expanded(
                    child: _PresetOption(
                      label: _presets[i].$1,
                      selected: _followupAt == _presetDate(_presets[i].$2),
                      onTap: () => setState(() {
                        _followupAt = _presetDate(_presets[i].$2);
                        _error = null;
                      }),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 10.h),
            InkWell(
              onTap: _pickDateTime,
              borderRadius: BorderRadius.circular(12.r),
              child: InputDecorator(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.schedule_rounded),
                  suffixIcon: Icon(Icons.edit_calendar_rounded),
                ),
                child: Text(
                  _followupAt == null
                      ? 'Or pick a custom date & time'
                      : DateFormat('EEE, dd MMM yyyy · h:mm a')
                          .format(_followupAt!),
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: _followupAt == null
                        ? FontWeight.w400
                        : FontWeight.w600,
                    color: _followupAt == null
                        ? AppColor.textMuted
                        : AppColor.textPrimary,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            _SheetLabel(icon: Icons.notes_rounded, text: 'Remarks'),
            TextField(
              controller: _remarks,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'What happened on this follow-up?',
              ),
            ),
            if (_error != null) ...[
              SizedBox(height: 14.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColor.dangerTint,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 18.sp,
                      color: AppColor.danger,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        _error!,
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColor.danger,
                        ),
                      ),
                    ),
                  ],
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

class _SheetLabel extends StatelessWidget {
  const _SheetLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          Icon(icon, size: 16.sp, color: AppColor.primary),
          SizedBox(width: 6.w),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w700,
              color: AppColor.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  const _StatusOption({
    required this.action,
    required this.selected,
    required this.onTap,
  });

  final String action;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = salesStatusColor(action);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.10) : AppColor.surface,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: selected ? color : AppColor.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              salesStatusIcon(action),
              size: 15.sp,
              color: selected ? color : AppColor.textMuted,
            ),
            SizedBox(width: 6.w),
            Text(
              action,
              style: GoogleFonts.inter(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w600,
                color: selected ? color : AppColor.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetOption extends StatelessWidget {
  const _PresetOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(vertical: 10.h),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColor.primaryTint : AppColor.background,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: selected ? AppColor.primary : AppColor.border,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w700,
                color: selected ? AppColor.primary : AppColor.textPrimary,
              ),
            ),
            Text(
              '10:00 AM',
              style: GoogleFonts.inter(
                fontSize: 10.5.sp,
                color: selected ? AppColor.primary : AppColor.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
