import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/task_controller.dart';
import 'task_screen.dart';

// Small palette copy, matching the colors used across the Task screens.
const _kBg = Color(0xFFF6F1ED);
const _kBrand = Color(0xFF6A3027);
const _kTextPrimary = Color(0xFF241917);
const _kTextMuted = Color(0xFF8B7D77);

/// Opened when you tap an employee in the Given tab's "By Employee" list.
/// A fresh screen showing just that employee's tasks, with its own
/// search bar at the top.
class EmployeeTasksScreen extends StatefulWidget {
  final String employeeName;
  final bool canUpdate;

  const EmployeeTasksScreen({
    super.key,
    required this.employeeName,
    required this.canUpdate,
  });

  @override
  State<EmployeeTasksScreen> createState() => _EmployeeTasksScreenState();
}

class _EmployeeTasksScreenState extends State<EmployeeTasksScreen> {
  final _c = Get.find<TaskController>();
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kTextPrimary),
        title: Text(
          widget.employeeName,
          style: GoogleFonts.manrope(
            fontSize: 16.sp,
            fontWeight: FontWeight.w800,
            color: _kTextPrimary,
          ),
        ),
      ),
      body: Obx(() {
        // Step 1: keep only this employee's tasks.
        final myTasks = _c.taskWorks
            .where((t) => (t.employeeName ?? '').trim() == widget.employeeName)
            .toList();

        // Step 2: narrow further by whatever is typed in the search bar.
        final query = _query.trim().toLowerCase();
        final filtered = query.isEmpty
            ? myTasks
            : myTasks.where((t) {
                final text = [
                  t.projectName,
                  t.taskTittle,
                  t.proDescription,
                ].join(' ').toLowerCase();
                return text.contains(query);
              }).toList();

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
              child: SearchField(
                controller: _searchCtrl,
                hint: 'Search tasks...',
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            SizedBox(height: 12.h),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No tasks found',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          color: _kTextMuted,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      color: _kBrand,
                      onRefresh: _c.fetchTaskWorks,
                      child: ListView.builder(
                        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => TaskWorkCard(
                          task: filtered[i],
                          canUpdate: widget.canUpdate,
                        ),
                      ),
                    ),
            ),
          ],
        );
      }),
    );
  }
}
