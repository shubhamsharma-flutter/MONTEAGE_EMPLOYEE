import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/sales_lead_detail_controller.dart';
import '../models/sales_lead_model.dart';
import '../utils/constants/color_constants.dart';
import '../widgets/app_ui.dart';
import '../widgets/leave_ui.dart';
import '../widgets/sales_ui.dart';

class SalesLeadDetailScreen extends GetView<SalesLeadDetailController> {
  const SalesLeadDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lead = controller.lead;

    Future<void> update() async {
      if (await showSalesFollowupSheet(context, lead)) {
        controller.loadHistory();
      }
    }

    return SalesScaffold(
      title: 'Lead Details',
      subtitle: lead.organizationName.isNotEmpty
          ? lead.organizationName
          : lead.contactName,
      bottomBar: Container(
        decoration: const BoxDecoration(
          color: AppColor.surface,
          border: Border(top: BorderSide(color: AppColor.border)),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 10.h),
            child: AppPrimaryButton(
              label: 'Update follow-up',
              icon: Icons.edit_calendar_rounded,
              onPressed: update,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: controller.loadHistory,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.w),
          children: [
            _HeaderCard(lead: lead),
            SizedBox(height: 14.h),
            _QuickActions(lead: lead),
            SizedBox(height: 14.h),
            _ContactCard(lead: lead),
            SizedBox(height: 14.h),
            _VisitCard(lead: lead),
            SizedBox(height: 24.h),
            const AppSectionTitle(
              title: 'Follow-up history',
              subtitle: 'Every update made on this lead',
            ),
            SizedBox(height: 12.h),
            Obx(() {
              if (controller.isLoading.value && controller.history.isEmpty) {
                return const LeaveLoadingCards(count: 2);
              }
              if (controller.errorMessage.value.isNotEmpty) {
                return AppMessageState(
                  icon: Icons.cloud_off_rounded,
                  title: 'Could not load history',
                  message: controller.errorMessage.value,
                  actionLabel: 'Retry',
                  onAction: controller.loadHistory,
                  color: AppColor.danger,
                );
              }
              if (controller.history.isEmpty) {
                return const AppMessageState(
                  icon: Icons.history_rounded,
                  title: 'No follow-ups yet',
                  message: 'Updates you save on this lead will show here.',
                );
              }
              final entries = controller.history;
              return Column(
                children: [
                  for (var i = 0; i < entries.length; i++)
                    _HistoryTile(
                      entry: entries[i],
                      isLast: i == entries.length - 1,
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.lead});

  final SalesLead lead;

  @override
  Widget build(BuildContext context) {
    final name = lead.organizationName.isEmpty
        ? 'Unnamed lead'
        : lead.organizationName;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColor.primary, AppColor.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: const [
          BoxShadow(
            color: AppColor.primaryGlow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30.w,
            top: -40.h,
            child: Container(
              width: 130.w,
              height: 130.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(18.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 54.w,
                      height: 54.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Text(
                        salesInitials(name),
                        style: GoogleFonts.inter(
                          fontSize: 19.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColor.primary,
                        ),
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          if (lead.contactName.isNotEmpty) ...[
                            SizedBox(height: 3.h),
                            Row(
                              children: [
                                Icon(
                                  Icons.person_rounded,
                                  size: 14.sp,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                                SizedBox(width: 4.w),
                                Expanded(
                                  child: Text(
                                    lead.contactName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    _HeroPill(
                      icon: salesStatusIcon(lead.action),
                      label: lead.action.isEmpty ? 'New' : lead.action,
                    ),
                    if (lead.courseName.isNotEmpty)
                      _HeroPill(
                        icon: Icons.category_rounded,
                        label: lead.courseName,
                      ),
                    if (lead.updateDate.isNotEmpty ||
                        lead.createDate.isNotEmpty)
                      _HeroPill(
                        icon: Icons.update_rounded,
                        label: formatSalesRelative(
                          lead.updateDate.isNotEmpty
                              ? lead.updateDate
                              : lead.createDate,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.sp, color: Colors.white),
          SizedBox(width: 5.w),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.lead});

  final SalesLead lead;

  @override
  Widget build(BuildContext context) {
    final actions = <(IconData, String, Color, VoidCallback)>[
      if (lead.mobile.isNotEmpty)
        (
          Icons.call_rounded,
          'Call',
          AppColor.success,
          () => callSalesNumber(lead.mobile),
        ),
      if (lead.alternateMobile.isNotEmpty)
        (
          Icons.phone_forwarded_rounded,
          'Alt. call',
          AppColor.primary,
          () => callSalesNumber(lead.alternateMobile),
        ),
      if (lead.email.isNotEmpty)
        (
          Icons.mail_rounded,
          'Email',
          AppColor.info,
          () => emailSalesContact(lead.email),
        ),
      if (lead.hasLocation)
        (
          Icons.directions_rounded,
          'Directions',
          AppColor.accent,
          () => openSalesLocation(lead),
        ),
    ];
    if (actions.isEmpty) return const SizedBox.shrink();

    return AppCard(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
      child: Row(
        children: [
          for (final (icon, label, color, onTap) in actions)
            Expanded(
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Column(
                    children: [
                      Container(
                        width: 46.w,
                        height: 46.w,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 22.sp),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColor.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// White card with an icon + title header and divided rows.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.rows,
  });

  final IconData icon;
  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 6.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18.sp, color: AppColor.primary),
              SizedBox(width: 8.w),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14.5.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColor.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColor.border),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10.h),
              child: rows[i],
            ),
          ],
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.lead});

  final SalesLead lead;

  @override
  Widget build(BuildContext context) {
    Widget call(String number) => IconButton.filledTonal(
      tooltip: 'Call $number',
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        backgroundColor: AppColor.successTint,
        foregroundColor: AppColor.success,
      ),
      icon: Icon(Icons.call_rounded, size: 18.sp),
      onPressed: () => callSalesNumber(number),
    );

    return _SectionCard(
      icon: Icons.contact_phone_rounded,
      title: 'Contact',
      rows: [
        SalesInfoRow(
          icon: Icons.phone_iphone_rounded,
          label: 'Mobile',
          value: lead.mobile,
          trailing: lead.mobile.isEmpty ? null : call(lead.mobile),
        ),
        if (lead.alternateMobile.isNotEmpty)
          SalesInfoRow(
            icon: Icons.phone_android_rounded,
            label: 'Alternate mobile',
            value: lead.alternateMobile,
            trailing: call(lead.alternateMobile),
          ),
        SalesInfoRow(
          icon: Icons.alternate_email_rounded,
          label: 'Email',
          value: lead.email,
        ),
        if (lead.alternateEmail.isNotEmpty)
          SalesInfoRow(
            icon: Icons.mark_email_read_rounded,
            label: 'Alternate email',
            value: lead.alternateEmail,
          ),
      ],
    );
  }
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({required this.lead});

  final SalesLead lead;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.storefront_rounded,
      title: 'Visit & notes',
      rows: [
        SalesInfoRow(
          icon: Icons.apartment_rounded,
          label: 'Organization address',
          value: lead.orgAddress,
          maxLines: 4,
        ),
        if (lead.currentAddress.isNotEmpty)
          SalesInfoRow(
            icon: Icons.pin_drop_rounded,
            label: 'Visit location',
            value: lead.currentAddress,
            maxLines: 4,
            trailing: lead.hasLocation
                ? IconButton(
                    tooltip: 'Open in Maps',
                    icon: Icon(
                      Icons.open_in_new_rounded,
                      size: 18.sp,
                      color: AppColor.accent,
                    ),
                    onPressed: () => openSalesLocation(lead),
                  )
                : null,
          ),
        // SalesInfoRow(
        //   icon: Icons.event_outlined,
        //   label: 'Next follow-up',
        //   value: formatSalesDate(lead.followupDate),
        // ),
        if (lead.updateDate.isNotEmpty || lead.createDate.isNotEmpty)
          SalesInfoRow(
            icon: Icons.history_toggle_off_rounded,
            label: 'Last activity',
            value: formatSalesDate(
              lead.updateDate.isNotEmpty ? lead.updateDate : lead.createDate,
            ),
          ),
        if (lead.remarks.isNotEmpty)
          SalesInfoRow(
            icon: Icons.sticky_note_2_rounded,
            label: 'Remarks',
            value: lead.remarks,
            maxLines: 6,
          ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry, required this.isLast});

  final SalesFollowupEntry entry;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = salesStatusColor(entry.subStatus);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30.w,
            child: Column(
              children: [
                SizedBox(height: 12.h),
                Container(
                  width: 28.w,
                  height: 28.w,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Icon(
                    salesStatusIcon(entry.subStatus),
                    size: 14.sp,
                    color: color,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: EdgeInsets.only(top: 4.h),
                      color: AppColor.border,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: AppCard(
                padding: EdgeInsets.all(14.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 14.sp,
                          color: AppColor.textMuted,
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            formatSalesRelative(entry.updateDate),
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColor.textMuted,
                            ),
                          ),
                        ),
                        if (entry.subStatus.isNotEmpty)
                          SalesStatusChip(entry.subStatus),
                      ],
                    ),
                    if (entry.remarks.isNotEmpty) ...[
                      SizedBox(height: 10.h),
                      Text(
                        entry.remarks,
                        style: GoogleFonts.inter(
                          fontSize: 13.5.sp,
                          height: 1.45,
                          color: AppColor.textPrimary,
                        ),
                      ),
                    ],
                    if (entry.followupDate.isNotEmpty) ...[
                      SizedBox(height: 10.h),
                      SalesMetaPill(
                        icon: Icons.event_repeat_rounded,
                        label:
                            'Next follow-up: ${formatSalesRelative(entry.followupDate)}',
                        color: AppColor.primary,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
