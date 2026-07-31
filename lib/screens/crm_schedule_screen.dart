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
      backgroundColor: const Color(0xFFF6F1ED),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F1ED),
        elevation: 0,
        title: Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF241917),
          ),
        ),
      ),
      body: meetings.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy_rounded, size: 52.sp, color: const Color(0xFF8B7D77)),
                  SizedBox(height: 12.h),
                  Text(
                    "No meetings scheduled",
                    style: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF8B7D77)),
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
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: const Color(0xFFEDE2DC)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.title,
                        style: GoogleFonts.manrope(
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF241917),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 14.sp, color: const Color(0xFF6A3027)),
                          SizedBox(width: 6.w),
                          Text(
                            DateFormat('dd MMM yyyy · hh:mm a').format(m.dateTime),
                            style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF6A3027)),
                          ),
                        ],
                      ),
                      if (m.clientName.isNotEmpty) ...[
                        SizedBox(height: 6.h),
                        Row(
                          children: [
                            Icon(Icons.person_outline_rounded, size: 14.sp, color: const Color(0xFF6A3027)),
                            SizedBox(width: 6.w),
                            Text(
                              m.clientName,
                              style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF241917)),
                            ),
                          ],
                        ),
                      ],
                      if (m.clientDetails.isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        Text(
                          m.clientDetails,
                          style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF8B7D77)),
                        ),
                      ],
                      if (m.attendees.isNotEmpty) ...[
                        SizedBox(height: 6.h),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.groups_outlined, size: 14.sp, color: const Color(0xFF6A3027)),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                m.attendees.join(', '),
                                style: GoogleFonts.inter(
                                    fontSize: 12.sp, color: const Color(0xFF241917)),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (m.notes.isNotEmpty) ...[
                        SizedBox(height: 6.h),
                        Text(
                          m.notes,
                          style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF8B7D77)),
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
