import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/leave_list_controller.dart';
import '../widgets/bottom_nav_wrapper.dart';
import '../widgets/leave_request_widgets.dart';

class LeaveListScreen extends GetView<LeaveListController> {
  const LeaveListScreen({super.key});

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
            'My Leave Requests',
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
                onRetry: controller.fetchLeaveList,
              );
            }

            final leaves = controller.filteredLeaves;
            final filter = controller.selectedFilter.value;

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
                          icon: Icons.event_busy_rounded,
                          text: filter == 'Total'
                              ? 'No leave requests yet'
                              : 'No ${filter.toLowerCase()} leaves',
                          onRetry: controller.fetchLeaveList,
                        )
                      : RefreshIndicator(
                          onRefresh: controller.fetchLeaveList,
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
                            itemCount: leaves.length,
                            separatorBuilder: (_, _) => SizedBox(height: 12.h),
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
