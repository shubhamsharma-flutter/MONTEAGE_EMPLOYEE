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

    return SalesScaffold(
      title: 'Lead Details',
      subtitle: lead.organizationName.isNotEmpty
          ? lead.organizationName
          : lead.contactName,
      bottomBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
          child: AppPrimaryButton(
            label: 'Update follow-up',
            icon: Icons.edit_calendar_rounded,
            onPressed: () async {
              if (await showSalesFollowupSheet(context, lead)) {
                controller.loadHistory();
              }
            },
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
            SizedBox(height: 12.h),
            _QuickActions(lead: lead),
            SizedBox(height: 12.h),
            _DetailsCard(lead: lead),
            SizedBox(height: 24.h),
            const AppSectionTitle(
              title: 'Follow-up history',
              subtitle: 'Every update made on this lead',
            ),
            SizedBox(height: 10.h),
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
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppIconBox(icon: Icons.storefront_rounded, size: 48),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lead.organizationName.isEmpty
                      ? 'Unnamed lead'
                      : lead.organizationName,
                  style: GoogleFonts.inter(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColor.textPrimary,
                  ),
                ),
                if (lead.contactName.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(
                    lead.contactName,
                    style: GoogleFonts.inter(
                      fontSize: 13.5.sp,
                      color: AppColor.textSecondary,
                    ),
                  ),
                ],
                SizedBox(height: 10.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 6.h,
                  children: [
                    SalesStatusChip(lead.action),
                    if (lead.courseName.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColor.surfaceVariant,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          lead.courseName,
                          style: GoogleFonts.inter(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColor.textSecondary,
                          ),
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

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.lead});

  final SalesLead lead;

  @override
  Widget build(BuildContext context) {
    final actions = <(IconData, String, VoidCallback)>[
      if (lead.mobile.isNotEmpty)
        (Icons.call_rounded, 'Call', () => callSalesNumber(lead.mobile)),
      if (lead.email.isNotEmpty)
        (Icons.email_outlined, 'Email', () => emailSalesContact(lead.email)),
      if (lead.hasLocation)
        (Icons.map_outlined, 'Map', () => openSalesLocation(lead)),
    ];
    if (actions.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) SizedBox(width: 10.w),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: actions[i].$3,
              icon: Icon(actions[i].$1, size: 18.sp),
              label: Text(actions[i].$2),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.lead});

  final SalesLead lead;

  @override
  Widget build(BuildContext context) {
    Widget call(String number) => IconButton(
          tooltip: 'Call $number',
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.call_rounded, size: 18.sp, color: AppColor.primary),
          onPressed: () => callSalesNumber(number),
        );

    final rows = <Widget>[
      SalesInfoRow(
        icon: Icons.phone_outlined,
        label: 'Mobile',
        value: lead.mobile,
        trailing: lead.mobile.isEmpty ? null : call(lead.mobile),
      ),
      if (lead.alternateMobile.isNotEmpty)
        SalesInfoRow(
          icon: Icons.phone_android_outlined,
          label: 'Alternate mobile',
          value: lead.alternateMobile,
          trailing: call(lead.alternateMobile),
        ),
      SalesInfoRow(
        icon: Icons.email_outlined,
        label: 'Email',
        value: lead.email,
      ),
      if (lead.alternateEmail.isNotEmpty)
        SalesInfoRow(
          icon: Icons.alternate_email_rounded,
          label: 'Alternate email',
          value: lead.alternateEmail,
        ),
      SalesInfoRow(
        icon: Icons.business_outlined,
        label: 'Organization address',
        value: lead.orgAddress,
        maxLines: 4,
      ),
      if (lead.currentAddress.isNotEmpty)
        SalesInfoRow(
          icon: Icons.my_location_rounded,
          label: 'Visit location',
          value: lead.currentAddress,
          maxLines: 4,
        ),
      SalesInfoRow(
        icon: Icons.event_outlined,
        label: 'Next follow-up',
        value: formatSalesDate(lead.followupDate),
      ),
      if (lead.updateDate.isNotEmpty || lead.createDate.isNotEmpty)
        SalesInfoRow(
          icon: Icons.update_rounded,
          label: 'Last activity',
          value: formatSalesDate(
            lead.updateDate.isNotEmpty ? lead.updateDate : lead.createDate,
          ),
        ),
      if (lead.remarks.isNotEmpty)
        SalesInfoRow(
          icon: Icons.notes_rounded,
          label: 'Remarks',
          value: lead.remarks,
          maxLines: 6,
        ),
    ];

    return AppCard(
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) SizedBox(height: 12.h),
            rows[i],
          ],
        ],
      ),
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
            width: 20.w,
            child: Column(
              children: [
                SizedBox(height: 16.h),
                Container(
                  width: 10.w,
                  height: 10.w,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: AppColor.border),
                  ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: AppCard(
                padding: EdgeInsets.all(14.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            formatSalesDate(entry.updateDate),
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
                      SizedBox(height: 8.h),
                      Text(
                        entry.remarks,
                        style: GoogleFonts.inter(
                          fontSize: 13.5.sp,
                          height: 1.4,
                          color: AppColor.textPrimary,
                        ),
                      ),
                    ],
                    if (entry.followupDate.isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      SalesInfoRow(
                        icon: Icons.event_outlined,
                        value:
                            'Next follow-up: ${formatSalesDate(entry.followupDate)}',
                        maxLines: 1,
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
