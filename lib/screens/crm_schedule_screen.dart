import 'package:monteage_employee/utils/constants/color_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/crm_meeting_model.dart';

// Shows meetings for one period (Tomorrow / This Week / This Month) —
// opened from the "Schedule" quick action on the CRM home screen.
class CrmScheduleScreen extends StatelessWidget {
  final String title;
  final List<CrmMeeting> meetings;

  const CrmScheduleScreen({
    super.key,
    required this.title,
    required this.meetings,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: meetings.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy_rounded, size: 52.sp, color: AppColor.textMuted),
                  SizedBox(height: 12.h),
                  Text(
                    "No meetings scheduled",
                    style: GoogleFonts.inter(fontSize: 13.sp, color: AppColor.textMuted),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: meetings.length,
              itemBuilder: (_, i) {
                final m = meetings[i];
                return Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColor.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.title,
                        style: GoogleFonts.inter(
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColor.textPrimary,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 14.sp, color: AppColor.primary),
                          SizedBox(width: 6.w),
                          Text(
                            DateFormat('dd MMM yyyy · hh:mm a').format(m.dateTime),
                            style: GoogleFonts.inter(fontSize: 12.sp, color: AppColor.primary),
                          ),
                        ],
                      ),
                      if (m.clientName.isNotEmpty) ...[
                        SizedBox(height: 6.h),
                        Row(
                          children: [
                            Icon(Icons.person_outline_rounded, size: 14.sp, color: AppColor.primary),
                            SizedBox(width: 6.w),
                            Text(
                              m.clientName,
                              style: GoogleFonts.inter(fontSize: 12.sp, color: AppColor.textPrimary),
                            ),
                          ],
                        ),
                      ],
                      if (m.clientDetails.isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        Text(
                          m.clientDetails,
                          style: GoogleFonts.inter(fontSize: 12.sp, color: AppColor.textMuted),
                        ),
                      ],
                      if (m.attendees.isNotEmpty) ...[
                        SizedBox(height: 6.h),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.groups_outlined, size: 14.sp, color: AppColor.primary),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                m.attendees.join(', '),
                                style: GoogleFonts.inter(
                                    fontSize: 12.sp, color: AppColor.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (m.notes.isNotEmpty) ...[
                        SizedBox(height: 6.h),
                        Text(
                          m.notes,
                          style: GoogleFonts.inter(fontSize: 12.sp, color: AppColor.textMuted),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
}
