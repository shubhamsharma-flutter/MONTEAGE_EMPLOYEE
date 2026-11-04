import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/leave_list_controller.dart';
import '../widgets/leave_request_widgets.dart';
import '../widgets/leave_ui.dart';

class LeaveListScreen extends GetView<LeaveListController> {
  const LeaveListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LeaveScaffold(
      title: 'My Leave Requests',
      subtitle: 'Track your requests and approvals',
      body: Obx(() {
        final leaves = controller.filteredLeaves;

        return LeaveRequestsView(
          isLoading: controller.isLoading.value && controller.leaves.isEmpty,
          errorMessage: controller.errorMessage.value,
          selectedFilter: controller.selectedFilter.value,
          countFor: controller.countFor,
          onFilterSelected: (value) => controller.selectedFilter.value = value,
          onRefresh: controller.fetchLeaveList,
          emptyIcon: Icons.event_note_rounded,
          emptyTitle: 'No leave requests yet',
          emptyText: 'Leaves you apply for will appear here.',
          itemCount: leaves.length,
          itemBuilder: (_, i) {
            final leave = leaves[i];
            return LeaveRequestCard(
              leaveType: leave.leaveType,
              fromDate: leave.fromDate,
              toDate: leave.toDate,
              days: leave.leaveNoofday ?? 0,
              reason: leave.leaveReason,
              status: controller.statusOf(leave),
              approvals: controller.approvalsOf(leave),
            );
          },
        );
      }),
    );
  }
}
