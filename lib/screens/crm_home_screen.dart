import 'package:monteage_employee/utils/constants/color_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../controllers/crm_controller.dart';
import '../models/crm_meeting_model.dart';
import '../models/empdropdownmode.dart' as empdrop;
import 'crm_list_screen.dart';
import 'crm_schedule_screen.dart';
import 'crm_knowledge_base_screen.dart';
import 'crm_forms.dart';
import 'crm_add_visit_flow.dart';
import 'crm_event_details_screen.dart';

class CrmHomeScreen extends StatelessWidget {
  const CrmHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CrmController controller = Get.isRegistered<CrmController>()
        ? Get.find<CrmController>()
        : Get.put(CrmController());

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          "CRM",
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColor.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              color: AppColor.primary,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Manage & Schedule",
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  "Leads, deals and client visits, all in one place.",
                  style: GoogleFonts.inter(
                    fontSize: 12.5.sp,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),

          Text(
            "Today's Schedule",
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppColor.textPrimary,
            ),
          ),
          SizedBox(height: 10.h),
          Obx(() {
            final today = controller.todaysMeetings;
            if (today.isEmpty) {
              return _EmptyBox(message: "No meetings scheduled for today.");
            }
            return Column(
              children: today.map((m) => _MeetingTile(meeting: m)).toList(),
            );
          }),
          SizedBox(height: 20.h),

          Text(
            "Quick Actions",
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppColor.textPrimary,
            ),
          ),
          SizedBox(height: 10.h),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8.h,
            crossAxisSpacing: 8.w,
            childAspectRatio: 1.15,
            children: [
              _QuickActionTile(
                icon: Icons.today_rounded,
                label: "Next Day",
                onTap: () => Get.to(() => CrmScheduleScreen(
                      title: "Next Day Schedule",
                      meetings: controller.tomorrowsMeetings,
                    )),
              ),
              _QuickActionTile(
                icon: Icons.view_week_rounded,
                label: "Next Week",
                onTap: () => Get.to(() => CrmScheduleScreen(
                      title: "Next Week Schedule",
                      meetings: controller.thisWeeksMeetings,
                    )),
              ),
              _QuickActionTile(
                icon: Icons.calendar_view_month_rounded,
                label: "Next Month",
                onTap: () => Get.to(() => CrmScheduleScreen(
                      title: "Next Month Schedule",
                      meetings: controller.thisMonthsMeetings,
                    )),
              ),
              _QuickActionTile(
                icon: Icons.trending_up_rounded,
                label: "Opportunities",
                onTap: () => Get.to(() => CrmListScreen(
                      title: "Opportunities",
                      icon: Icons.trending_up_rounded,
                      searchHint: "Search opportunities...",
                      emptyMessage: "No opportunities yet.",
                      items: controller.opportunities,
                      onAdd: () => showAddOpportunitySheet(context, controller),
                    )),
              ),
              _QuickActionTile(
                icon: Icons.menu_book_rounded,
                label: "Knowledge Base",
                onTap: () => Get.to(() => const CrmKnowledgeBaseScreen()),
              ),
              _QuickActionTile(
                icon: Icons.place_rounded,
                label: "Visits",
                onTap: () => Get.to(() => CrmListScreen(
                      title: "Visits",
                      icon: Icons.place_rounded,
                      searchHint: "Search visits...",
                      emptyMessage: "No visits yet.",
                      items: controller.visits,
                      onAdd: () => showAddVisitFlow(context, controller),
                    )),
              ),
              _QuickActionTile(
                icon: Icons.event_rounded,
                label: "Event Details",
                onTap: () => Get.to(() => CrmEventDetailsScreen(controller: controller)),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColor.primary,
        shape: const CircleBorder(),
        onPressed: () => _showAddMeetingSheet(context, controller),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddMeetingSheet(BuildContext context, CrmController controller) async {
    final employees = await crmFetchEmployees();
    if (!context.mounted) return;

    final titleCtrl = TextEditingController();
    final clientNameCtrl = TextEditingController();
    final clientDetailsCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime? pickedDate;
    TimeOfDay? pickedTime;
    final selectedAttendees = <empdrop.Data>[];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColor.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20.w,
                right: 20.w,
                top: 20.h,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.h,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Schedule a Meeting",
                    style: GoogleFonts.inter(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColor.textPrimary,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: titleCtrl,
                    style: GoogleFonts.inter(fontSize: 14.sp),
                    decoration: InputDecoration(
                      hintText: "Meeting title",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2101),
                            );
                            if (picked != null) {
                              setState(() => pickedDate = picked);
                            }
                          },
                          child: Text(pickedDate == null
                              ? "Pick date"
                              : DateFormat('dd MMM yyyy').format(pickedDate!)),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: ctx,
                              initialTime: TimeOfDay.now(),
                            );
                            if (picked != null) {
                              setState(() => pickedTime = picked);
                            }
                          },
                          child: Text(
                              pickedTime == null ? "Pick time" : pickedTime!.format(ctx)),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: clientNameCtrl,
                    style: GoogleFonts.inter(fontSize: 14.sp),
                    decoration: InputDecoration(
                      hintText: "Client name",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: clientDetailsCtrl,
                    maxLines: 2,
                    style: GoogleFonts.inter(fontSize: 14.sp),
                    decoration: InputDecoration(
                      hintText: "Client details (phone, email, etc.)",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  crmFieldLabel("Attendees (optional)"),
                  SizedBox(height: 6.h),
                  crmMultiSelectField(
                    context: context,
                    employees: employees,
                    selected: selectedAttendees,
                    hint: "Select employees to invite",
                    pickerTitle: "Attendees",
                    onChanged: (result) => setState(() {
                      selectedAttendees
                        ..clear()
                        ..addAll(result);
                    }),
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 3,
                    style: GoogleFonts.inter(fontSize: 14.sp),
                    decoration: InputDecoration(
                      hintText: "Notes (optional)",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      onPressed: () {
                        if (titleCtrl.text.trim().isEmpty ||
                            pickedDate == null ||
                            pickedTime == null) {
                          Get.snackbar(
                            "Missing Info",
                            "Please enter a title, date and time.",
                            snackPosition: SnackPosition.BOTTOM,
                          );
                          return;
                        }
                        final dateTime = DateTime(
                          pickedDate!.year,
                          pickedDate!.month,
                          pickedDate!.day,
                          pickedTime!.hour,
                          pickedTime!.minute,
                        );
                        controller.addMeeting(CrmMeeting(
                          title: titleCtrl.text.trim(),
                          dateTime: dateTime,
                          clientName: clientNameCtrl.text.trim(),
                          clientDetails: clientDetailsCtrl.text.trim(),
                          notes: notesCtrl.text.trim(),
                          attendees: selectedAttendees.map((e) => e.employeeName ?? '').toList(),
                        ));
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        "Save",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

}

class _EmptyBox extends StatelessWidget {
  final String message;
  const _EmptyBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColor.border),
      ),
      child: Center(
        child: Text(
          message,
          style: GoogleFonts.inter(fontSize: 12.5.sp, color: AppColor.textMuted),
        ),
      ),
    );
  }
}

class _MeetingTile extends StatelessWidget {
  final CrmMeeting meeting;
  const _MeetingTile({required this.meeting});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColor.border),
      ),
      child: Row(
        children: [
          Icon(Icons.event_rounded, color: AppColor.primary, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meeting.title,
                  style: GoogleFonts.inter(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColor.textPrimary,
                  ),
                ),
                Text(
                  meeting.clientName.isEmpty
                      ? DateFormat('hh:mm a').format(meeting.dateTime)
                      : "${meeting.clientName} · ${DateFormat('hh:mm a').format(meeting.dateTime)}",
                  style: GoogleFonts.inter(fontSize: 11.5.sp, color: AppColor.textMuted),
                ),
                if (meeting.attendees.isNotEmpty) ...[
                  SizedBox(height: 3.h),
                  Text(
                    "With: ${meeting.attendees.join(', ')}",
                    style: GoogleFonts.inter(fontSize: 11.sp, color: AppColor.primary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColor.border),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColor.primary, size: 17.sp),
              SizedBox(height: 4.h),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 9.5.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColor.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
