import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'totalattendanceview.dart';
import 'hr_today_attendance_view.dart';

/// HR's "All Attendance" nav tab — split into two tabs:
///  • All Attendance   → existing Totalattendanceview (unchanged)
///  • Today's Attendance → new HrTodayAttendanceView
class AllAttendanceScreen extends StatelessWidget {
  const AllAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Container(
              color: Colors.white,
              child: TabBar(
                labelColor: const Color(0xFFB54A3A),
                unselectedLabelColor: const Color(0xFF8B7D77),
                indicatorColor: const Color(0xFFB54A3A),
                labelStyle: GoogleFonts.manrope(
                    fontSize: 13.sp, fontWeight: FontWeight.w700),
                tabs: const [
                  Tab(text: 'All Attendance'),
                  Tab(text: "Today's Attendance"),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                Totalattendanceview(),
                const HrTodayAttendanceView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
