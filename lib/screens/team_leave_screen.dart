import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/team_leave_controller.dart';
import '../models/teameleavemodel.dart';
import '../widgets/leave_request_widgets.dart';
import '../widgets/leave_ui.dart';

class TeamLeaveScreen extends GetView<TeamLeaveController> {
  const TeamLeaveScreen({super.key});

  Future<void> _confirmDecision(
    BuildContext context,
    Data leave,
    String decision,
  ) async {
    final approve = decision == 'Approved';
    final action = approve ? 'Approve' : 'Reject';
    final color = approve ? LeaveColors.approved : LeaveColors.rejected;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LeaveColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        icon: Icon(leaveStatusIcon(decision), color: color),
        title: Text('$action Leave', style: LeaveText.heading(17)),
        content: Text(
          '$action ${(leave.employeeName ?? 'this employee').trim()}\'s '
          '${(leave.leaveType ?? 'leave').trim()} '
          '(${leaveDayLabel(leave.leaveNoofday ?? 0)})?',
          textAlign: TextAlign.center,
          style: LeaveText.body(14),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: LeaveColors.muted),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: color),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.decideLeave(leave, decision);
  }

  @override
  Widget build(BuildContext context) {
    return LeaveScaffold(
      title: 'Team Leave',
      subtitle: 'Review your team\'s requests',
      body: Obx(() {
        final leaves = controller.filteredLeaves;
        final decidingId = controller.decidingLeaveId.value;
        final waiting = controller.awaitingDecisionCount;

        return LeaveRequestsView(
          isLoading: controller.isLoading.value && controller.leaves.isEmpty,
          errorMessage: controller.errorMessage.value,
          selectedFilter: controller.selectedFilter.value,
          countFor: controller.countFor,
          onFilterSelected: (value) => controller.selectedFilter.value = value,
          onRefresh: controller.fetchTeamLeaves,
          emptyIcon: Icons.groups_rounded,
          emptyTitle: 'No team leaves yet',
          emptyText: 'Leave requests from your team will appear here.',
          header: waiting > 0 ? _WaitingBanner(count: waiting) : null,
          itemCount: leaves.length,
          itemBuilder: (_, i) {
            final leave = leaves[i];
            return LeaveRequestCard(
              employeeName: leave.employeeName,
              leaveType: leave.leaveType,
              fromDate: leave.fromDate,
              toDate: leave.toDate,
              days: leave.leaveNoofday ?? 0,
              reason: leave.leaveReason,
              status: controller.statusOf(leave),
              approvals: controller.approvalsOf(leave),
              footer: controller.canDecide(leave)
                  ? _DecisionButtons(
                      busy: decidingId == leave.eLeaveAId,
                      enabled: decidingId == null,
                      onDecision: (decision) =>
                          _confirmDecision(context, leave, decision),
                    )
                  : null,
            );
          },
        );
      }),
    );
  }
}

class _WaitingBanner extends StatelessWidget {
  final int count;

  const _WaitingBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: LeaveColors.pending.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_active_rounded,
            size: 18.sp,
            color: LeaveColors.pending,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              count == 1
                  ? '1 leave is waiting for your decision'
                  : '$count leaves are waiting for your decision',
              style: LeaveText.body(
                13,
                weight: FontWeight.w600,
                color: LeaveColors.pending,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DecisionButtons extends StatelessWidget {
  final bool busy;
  final bool enabled;
  final ValueChanged<String> onDecision;

  const _DecisionButtons({
    required this.busy,
    required this.enabled,
    required this.onDecision,
  });

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return const SizedBox(
        height: 44,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: LeaveColors.accent,
            ),
          ),
        ),
      );
    }

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14.r),
    );

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: LeaveColors.rejected,
              side: const BorderSide(color: LeaveColors.rejected),
              minimumSize: const Size.fromHeight(44),
              shape: shape,
            ),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Reject'),
            onPressed: enabled ? () => onDecision('Rejected') : null,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: LeaveColors.approved,
              minimumSize: const Size.fromHeight(44),
              shape: shape,
            ),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Approve'),
            onPressed: enabled ? () => onDecision('Approved') : null,
          ),
        ),
      ],
    );
  }
}
