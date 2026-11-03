import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/team_leave_controller.dart';
import '../models/teameleavemodel.dart';
import '../widgets/bottom_nav_wrapper.dart';
import '../widgets/leave_request_widgets.dart';

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
      return const Center(child: CircularProgressIndicator());
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFD85E5E),
              side: const BorderSide(color: Color(0xFFD85E5E)),
            ),
            onPressed: enabled ? () => onDecision('Rejected') : null,
            child: const Text('Reject'),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2AB673),
              foregroundColor: Colors.white,
            ),
            onPressed: enabled ? () => onDecision('Approved') : null,
            child: const Text('Approve'),
          ),
        ),
      ],
    );
  }
}

class TeamLeaveScreen extends GetView<TeamLeaveController> {
  const TeamLeaveScreen({super.key});

  Future<void> _confirmDecision(
    BuildContext context,
    Data leave,
    String decision,
  ) async {
    final action = decision == 'Approved' ? 'Approve' : 'Reject';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$action Leave'),
        content: Text(
          '$action ${(leave.employeeName ?? 'this employee').trim()}\'s '
          '${(leave.leaveType ?? 'leave').trim()}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
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
    return BottomNavWrapper(
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F1ED),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFFF6F1ED),
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF241917),
            ),
            onPressed: () => Get.back(),
          ),
          titleSpacing: 0,
          title: Text(
            'Team Leave',
            style: GoogleFonts.manrope(
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF241917),
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Obx(() {
            if (controller.isLoading.value && controller.leaves.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.errorMessage.value.isNotEmpty) {
              return LeaveMessage(
                icon: Icons.error_outline_rounded,
                text: controller.errorMessage.value,
                onRetry: controller.fetchTeamLeaves,
              );
            }

            final leaves = controller.filteredLeaves;
            final filter = controller.selectedFilter.value;
            final decidingId = controller.decidingLeaveId.value;

            return Column(
              children: [
                LeaveFilterBar(
                  selected: filter,
                  countFor: controller.countFor,
                  onSelected: (value) =>
                      controller.selectedFilter.value = value,
                ),
                Expanded(
                  child: leaves.isEmpty
                      ? LeaveMessage(
                          icon: Icons.groups_rounded,
                          text: filter == 'Total'
                              ? 'No team leaves yet'
                              : 'No ${filter.toLowerCase()} team leaves',
                          onRetry: controller.fetchTeamLeaves,
                        )
                      : RefreshIndicator(
                          onRefresh: controller.fetchTeamLeaves,
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
                            itemCount: leaves.length,
                            separatorBuilder: (_, _) => SizedBox(height: 12.h),
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
                                            _confirmDecision(
                                              context,
                                              leave,
                                              decision,
                                            ),
                                      )
                                    : null,
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
