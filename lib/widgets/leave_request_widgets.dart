import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../controllers/leave_list_controller.dart';
import 'leave_ui.dart';

/// Filter bar and list states shared by My Leave Requests and Team Leave.
class LeaveRequestsView extends StatelessWidget {
  final bool isLoading;
  final String errorMessage;
  final String selectedFilter;
  final int Function(String filter) countFor;
  final ValueChanged<String> onFilterSelected;
  final Future<void> Function() onRefresh;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyText;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final Widget? header;

  const LeaveRequestsView({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.selectedFilter,
    required this.countFor,
    required this.onFilterSelected,
    required this.onRefresh,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyText,
    required this.itemCount,
    required this.itemBuilder,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
        child: const LeaveLoadingCards(),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: LeaveMessage(
            icon: Icons.cloud_off_rounded,
            title: 'Something went wrong',
            text: errorMessage,
            actionLabel: 'Try again',
            onAction: onRefresh,
          ),
        ),
      );
    }

    final filter = selectedFilter.toLowerCase();

    return Column(
      children: [
        LeaveFilterBar(
          selected: selectedFilter,
          countFor: countFor,
          onSelected: onFilterSelected,
        ),
        ?header,
        Expanded(
          child: itemCount == 0
              ? Center(
                  child: SingleChildScrollView(
                    child: LeaveMessage(
                      icon: emptyIcon,
                      title: selectedFilter == 'Total'
                          ? emptyTitle
                          : 'No $filter leaves',
                      text: selectedFilter == 'Total'
                          ? emptyText
                          : 'Nothing is $filter right now.',
                      actionLabel: 'Refresh',
                      onAction: onRefresh,
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: LeaveColors.accent,
                  onRefresh: onRefresh,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
                    itemCount: itemCount,
                    separatorBuilder: (_, _) => SizedBox(height: 12.h),
                    itemBuilder: itemBuilder,
                  ),
                ),
        ),
      ],
    );
  }
}

class LeaveFilterBar extends StatelessWidget {
  final String selected;
  final int Function(String filter) countFor;
  final ValueChanged<String> onSelected;

  const LeaveFilterBar({
    super.key,
    required this.selected,
    required this.countFor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 12.h),
      padding: EdgeInsets.all(4.w),
      decoration: leaveCardDecoration(),
      child: Row(
        children: leaveStatusFilters.map((filter) {
          final isSelected = selected == filter;
          final color = leaveStatusColor(filter);

          return Expanded(
            child: Semantics(
              button: true,
              selected: isSelected,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16.r),
                  onTap: () => onSelected(filter),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    decoration: BoxDecoration(
                      color: isSelected ? color : Colors.transparent,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${countFor(filter)}',
                          style: LeaveText.heading(
                            18,
                            color: isSelected ? Colors.white : color,
                          ),
                        ),
                        Text(
                          filter,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: LeaveText.body(
                            11,
                            weight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : LeaveColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class LeaveRequestCard extends StatelessWidget {
  /// Shown above the leave type on team leaves; null for the user's own leaves.
  final String? employeeName;
  final String? leaveType;
  final String? fromDate;
  final String? toDate;
  final int days;
  final String? reason;
  final String status;
  final List<LeaveApproval> approvals;

  /// Shown below the approvals, e.g. approve and reject buttons.
  final Widget? footer;

  const LeaveRequestCard({
    super.key,
    this.employeeName,
    required this.leaveType,
    required this.fromDate,
    required this.toDate,
    required this.days,
    required this.reason,
    required this.status,
    required this.approvals,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final reasonText = (reason ?? '').trim();
    final name = employeeName?.trim() ?? '';
    final type = (leaveType ?? '-').trim();

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: leaveCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              name.isEmpty
                  ? _TypeBadge(leaveType: leaveType)
                  : _NameAvatar(name: name),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? type : name,
                      style: LeaveText.heading(15),
                    ),
                    Text(
                      name.isEmpty ? leaveDayLabel(days) : type,
                      style: LeaveText.body(12),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              _StatusPill(status: status),
            ],
          ),
          SizedBox(height: 12.h),
          _DateRange(
            from: formatLeaveDate(fromDate),
            to: formatLeaveDate(toDate),
            days: days,
          ),
          if (reasonText.isNotEmpty) ...[
            SizedBox(height: 12.h),
            LeaveDetailRow(icon: Icons.notes_rounded, text: reasonText),
          ],
          SizedBox(height: 12.h),
          const Divider(height: 1, color: LeaveColors.border),
          SizedBox(height: 12.h),
          Text(
            'Approvals',
            style: LeaveText.body(
              11,
              weight: FontWeight.w700,
              color: LeaveColors.muted,
            ),
          ),
          SizedBox(height: 8.h),
          for (var i = 0; i < approvals.length; i++) ...[
            if (i > 0)
              Container(
                width: 2,
                height: 10.h,
                margin: EdgeInsets.only(left: 13.w),
                color: LeaveColors.border,
              ),
            _ApprovalStep(approval: approvals[i]),
          ],
          if (footer != null) ...[SizedBox(height: 16.h), footer!],
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String? leaveType;

  const _TypeBadge({required this.leaveType});

  @override
  Widget build(BuildContext context) {
    final color = leaveTypeColor(leaveType);

    return Container(
      width: 44.w,
      height: 44.w,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Icon(leaveTypeIcon(leaveType), size: 22.sp, color: color),
    );
  }
}

class _NameAvatar extends StatelessWidget {
  final String name;

  const _NameAvatar({required this.name});

  String get _initials => name
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .take(2)
      .map((word) => word[0].toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44.w,
      height: 44.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: LeaveColors.accent.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Text(
        _initials,
        style: LeaveText.heading(14, color: LeaveColors.accent),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = leaveStatusColor(status);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(leaveStatusIcon(status), size: 12.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            status,
            style: LeaveText.body(11, weight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class _DateRange extends StatelessWidget {
  final String from;
  final String to;
  final int days;

  const _DateRange({required this.from, required this.to, required this.days});

  Widget _date(String label, String value) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: LeaveText.body(11)),
        SizedBox(height: 2.h),
        Text(
          value,
          style: LeaveText.body(
            13,
            weight: FontWeight.w700,
            color: LeaveColors.ink,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: LeaveColors.background,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          _date('From', from),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 16.sp,
              color: LeaveColors.muted,
            ),
          ),
          _date('To', to),
          SizedBox(width: 8.w),
          Text(
            leaveDayLabel(days),
            style: LeaveText.body(
              12,
              weight: FontWeight.w700,
              color: LeaveColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalStep extends StatelessWidget {
  final LeaveApproval approval;

  const _ApprovalStep({required this.approval});

  @override
  Widget build(BuildContext context) {
    final color = leaveStatusColor(approval.status);

    return Row(
      children: [
        Container(
          width: 28.w,
          height: 28.w,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            leaveStatusIcon(approval.status),
            size: 15.sp,
            color: color,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                approval.approver,
                style: LeaveText.body(
                  13,
                  weight: FontWeight.w600,
                  color: LeaveColors.ink,
                ),
              ),
              if (approval.approvedBy.isNotEmpty)
                Text(approval.approvedBy, style: LeaveText.body(11)),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          approval.status,
          style: LeaveText.body(12, weight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}
