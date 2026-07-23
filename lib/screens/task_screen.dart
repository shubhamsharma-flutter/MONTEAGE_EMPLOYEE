import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/task_controller.dart';
import '../models/empdropdownmode.dart' as empdrop;
import '../models/givenmodelpm.dart' as given;
import '../models/project_model.dart';
import '../models/recevedmodel.dart' as received;
import 'employee_tasks_screen.dart';

// ── Palette ──────────────────────────────────────────────────────────────────

String get _designation {
  final box = GetStorage();
  return (box.read('Designation') ?? box.read('designation') ?? '')
      .toString()
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}

bool get _isProjectManager =>
    _designation == 'project manager' ||
    _designation == 'projectmanager' ||
    _designation == 'pm' ||
    _designation == 'project_manager' ||
    (_designation.contains('project') && _designation.contains('manager'));

bool get _isTeamLeader =>
    _designation == 'team leader' ||
    _designation == 'teamleader' ||
    _designation == 'tl' ||
    _designation == 'team_leader' ||
    _designation == 'team lead' ||
    (_designation.contains('team') && _designation.contains('lead'));

bool get _isRegularEmployee => !_isProjectManager && !_isTeamLeader;

// ─────────────────────────────────────────────────────────────────────────
// TASK BADGE
// ─────────────────────────────────────────────────────────────────────────

class TaskBadge extends StatelessWidget {
  final String label;
  final Color color;
  const TaskBadge(this.label, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// EMPLOYEE LIST SHEET
// ─────────────────────────────────────────────────────────────────────────

class _EmployeeListSheet extends StatefulWidget {
  final TaskController controller;
  const _EmployeeListSheet({required this.controller});

  @override
  State<_EmployeeListSheet> createState() => _EmployeeListSheetState();
}

class _EmployeeListSheetState extends State<_EmployeeListSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.80,
      decoration: BoxDecoration(
        color: const Color(0xFFF6F1ED),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      child: Column(
        children: [
          SizedBox(height: 12.h),
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: const Color(0xFFCBC0BA),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 14.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Employee List',
                  style: GoogleFonts.manrope(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF241917),
                  ),
                ),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8DDD9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, size: 18.sp, color: const Color(0xFF6A3027)),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF241917)),
              decoration: InputDecoration(
                hintText: 'Search employee…',
                hintStyle: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF8B7D77)),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6A3027)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: const BorderSide(color: Color(0xFFB54A3A), width: 1.5),
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          const Divider(color: Color(0xFFE0D5D0), height: 1),
          Expanded(
            child: Obx(() {
              final c = widget.controller;
              if (c.isLoading.value && c.employees.isEmpty) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF6A3027)));
              }
              final filtered = c.employees
                  .where((e) => e.employeeName.toLowerCase().contains(_search.toLowerCase()))
                  .toList();
              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 48.sp, color: const Color(0xFF8B7D77)),
                      SizedBox(height: 12.h),
                      Text(
                        _search.isEmpty ? 'No employees found' : 'No results for "$_search"',
                        style: GoogleFonts.inter(fontSize: 14.sp, color: const Color(0xFF8B7D77)),
                      ),
                      if (_search.isEmpty) ...[
                        SizedBox(height: 16.h),
                        ElevatedButton.icon(
                          onPressed: () async {
                            Get.back();
                            await c.fetchAll();
                            Get.bottomSheet(
                              _EmployeeListSheet(controller: c),
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                            );
                          },
                          icon: Icon(Icons.refresh_rounded, size: 16.sp, color: Colors.white),
                          label: Text('Retry',
                              style: GoogleFonts.manrope(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB54A3A),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final emp = filtered[i];
                  return GestureDetector(
                    onTap: () {
                      Get.back();
                      Get.bottomSheet(
                        _EmployeeDetailSheet(employee: emp),
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                      );
                    },
                    child: Container(
                      margin: EdgeInsets.only(bottom: 10.h),
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14.r),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 6,
                              offset: Offset(0, 3))
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20.r,
                            backgroundColor:
                                const Color(0xFFB54A3A).withOpacity(0.12),
                            child: Text(
                              emp.employeeName.isNotEmpty
                                  ? emp.employeeName[0]
                                  : '?',
                              style: GoogleFonts.manrope(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFB54A3A)),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(emp.employeeName,
                                    style: GoogleFonts.manrope(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF241917))),
                                SizedBox(height: 3.h),
                                Text('Code: ${emp.employeeCode}',
                                    style: GoogleFonts.inter(
                                        fontSize: 11.sp,
                                        color: const Color(0xFF8B7D77))),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: const Color(0xFF6A3027), size: 20.sp),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────
// EMPLOYEE DETAIL SHEET
// ─────────────────────────────────────────────────────────────────────────

class _EmployeeDetailSheet extends StatelessWidget {
  final EmployeeModel employee;
  const _EmployeeDetailSheet({required this.employee});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: const Color(0xFFF6F1ED),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      child: Column(
        children: [
          SizedBox(height: 12.h),
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
                color: const Color(0xFFCBC0BA),
                borderRadius: BorderRadius.circular(2.r)),
          ),
          SizedBox(height: 14.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Get.back();
                    Get.bottomSheet(
                      _EmployeeListSheet(
                          controller: Get.find<TaskController>()),
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: const BoxDecoration(
                        color: Color(0xFFE8DDD9), shape: BoxShape.circle),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 16.sp, color: const Color(0xFF6A3027)),
                  ),
                ),
                SizedBox(width: 10.w),
                CircleAvatar(
                  radius: 20.r,
                  backgroundColor: const Color(0xFFB54A3A).withOpacity(0.12),
                  child: Text(
                    employee.employeeName.isNotEmpty
                        ? employee.employeeName[0]
                        : '?',
                    style: GoogleFonts.manrope(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFB54A3A)),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(employee.employeeName,
                      style: GoogleFonts.manrope(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF241917))),
                ),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: const BoxDecoration(
                        color: Color(0xFFE8DDD9), shape: BoxShape.circle),
                    child: Icon(Icons.close,
                        size: 18.sp, color: const Color(0xFF6A3027)),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          const Divider(color: Color(0xFFE0D5D0), height: 1),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Employee Details',
                      style: GoogleFonts.manrope(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF241917))),
                  SizedBox(height: 20.h),
                  _row('Employee ID', employee.employeeId.toString()),
                  SizedBox(height: 12.h),
                  _row('Employee Code', employee.employeeCode),
                  SizedBox(height: 12.h),
                  _row('Name', employee.employeeName),
                  SizedBox(height: 12.h),
                  _row('Team Lead', employee.isTeamLead ? 'Yes' : 'No'),
                  if (employee.teamLeadId != null) ...[
                    SizedBox(height: 12.h),
                    _row('Team Lead ID', employee.teamLeadId!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Row(
        children: [
          Text('$label: ',
              style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8B7D77))),
          Expanded(
            child: Text(value,
                style: GoogleFonts.inter(
                    fontSize: 14.sp, color: const Color(0xFF241917))),
          ),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────
// TASK SCREEN
// ─────────────────────────────────────────────────────────────────────────

class TaskScreen extends GetView<TaskController> {
  const TaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final _c = controller;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1ED),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFF6F1ED),
        elevation: 0,
        title: Text('Tasks',
            style: GoogleFonts.manrope(
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF241917))),
        actions: [
          Obx(() => IconButton(
                icon: Icon(
                  _c.isSearchExpanded.value
                      ? Icons.search_off_rounded
                      : Icons.search_rounded,
                  color: const Color(0xFF6A3027),
                ),
                onPressed: _c.toggleSearch,
              )),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6A3027)),
            onPressed: _c.fetchAll,
          ),
        ],
      ),
      body: Obx(() {
        if (_c.isLoading.value) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6A3027)));
        }
        return _Body(c: _c);
      }),
      floatingActionButton: (_isRegularEmployee || _c.effectiveTab != 0)
          ? null
          : FloatingActionButton(
              onPressed: () => Get.bottomSheet(
                _TaskForm(c: _c),
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
              ),
              backgroundColor: const Color(0xFFB54A3A),
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// BODY
// ─────────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final TaskController c;
  const _Body({required this.c});

  @override
  Widget build(BuildContext context) {
    final isManager = _isProjectManager;
    final isTL = _isTeamLeader;
    final isRegular = _isRegularEmployee;

    if ((isManager || isTL) && !Get.isRegistered<ProjectController>()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!Get.isRegistered<ProjectController>()) Get.put(ProjectController());
      });
    }

    if (isRegular) {
      return Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 0),
            child: Column(
              children: [
                _TabToggle(c: c),
                SizedBox(height: 12.h),
                Obx(() {
                  if (!c.isSearchExpanded.value) return const SizedBox.shrink();
                  return Column(
                    children: [
                      _SearchBar(
                          onChanged: c.setSearch,
                          hint: 'Search by title or date…'),
                      SizedBox(height: 12.h),
                    ],
                  );
                }),
                _StatsCard(c: c, showEmpTile: false),
                SizedBox(height: 12.h),
              ],
            ),
          ),
          Expanded(child: _RegularTaskList(c: c)),
        ],
      );
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 0),
          child: Obx(() {
            final tab = c.effectiveTab;
            final isPMProjectsTab = isManager && tab == 1;
            final isTLProjectsTab = isTL && tab == 2;
            final pc = Get.find<ProjectController>();

            return Column(
              children: [
                _TabToggle(c: c),
                SizedBox(height: 12.h),
                if (c.isSearchExpanded.value) ...[
                  _SearchBar(
                    onChanged: isPMProjectsTab
                        ? pc.setSearch
                        : isTLProjectsTab
                            ? pc.setTLSearch
                            : c.setSearch,
                    hint: (isPMProjectsTab || isTLProjectsTab)
                        ? 'Search by project name…'
                        : 'Search by title or date…',
                  ),
                  SizedBox(height: 12.h),
                ],
                isPMProjectsTab
                    ? _ProjectStatsCard(pc: pc)
                    : isTLProjectsTab
                        ? _TLProjectStatsCard(pc: pc)
                        : _StatsCard(c: c, showEmpTile: isManager),
                SizedBox(height: 12.h),
              ],
            );
          }),
        ),
        Expanded(
          child: Obx(() {
            final tab = c.effectiveTab;
            return _buildList(isManager, isTL, tab);
          }),
        ),
      ],
    );
  }

  Widget _buildList(bool isManager, bool isTL, int tab) {
    if (isManager && tab == 1) {
      if (!Get.isRegistered<ProjectController>()) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!Get.isRegistered<ProjectController>()) Get.put(ProjectController());
        });
        return const Center(
            child: CircularProgressIndicator(color: Color(0xFF6A3027)));
      }
      final pc = Get.find<ProjectController>();
      return Obx(() {
        final projects = pc.filteredProjects;
        if (pc.isLoading.value && projects.isEmpty) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6A3027)));
        }
        if (projects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_off_outlined,
                    size: 58.sp, color: const Color(0xFF8B7D77)),
                SizedBox(height: 12.h),
                Text('No projects found',
                    style: GoogleFonts.manrope(
                        fontSize: 15.sp, color: const Color(0xFF8B7D77))),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          itemCount: projects.length,
          itemBuilder: (_, i) => _ProjectCard(project: projects[i]),
        );
      });
    }

    if (isTL && tab == 2) {
      if (!Get.isRegistered<ProjectController>()) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!Get.isRegistered<ProjectController>()) Get.put(ProjectController());
        });
        return const Center(
            child: CircularProgressIndicator(color: Color(0xFF6A3027)));
      }
      final pc = Get.find<ProjectController>();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (pc.tlAllocateProjects.isEmpty && !pc.isLoading.value)
          pc.fetchTLAllocateProjects();
      });
      return Obx(() {
        if (pc.isLoading.value && pc.tlAllocateProjects.isEmpty) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6A3027)));
        }
        final projects = pc.filteredTLAllocateProjects;
        if (projects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_off_outlined,
                    size: 58.sp, color: const Color(0xFF8B7D77)),
                SizedBox(height: 12.h),
                Text(
                  'No projects found',
                  style: GoogleFonts.manrope(
                      fontSize: 15.sp, color: const Color(0xFF8B7D77)),
                ),
                SizedBox(height: 16.h),
                ElevatedButton.icon(
                  onPressed: () => pc.fetchTLAllocateProjects(),
                  icon: Icon(Icons.refresh_rounded, size: 16.sp, color: Colors.white),
                  label: Text('Retry',
                      style: GoogleFonts.manrope(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB54A3A),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          itemCount: projects.length,
          itemBuilder: (_, i) => _TLAllocateProjectCard(project: projects[i]),
        );
      });
    }

    return Obx(() {
      final tasks = c.filteredTasks;
      if (tasks.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_outlined,
                  size: 58.sp, color: const Color(0xFF8B7D77)),
              SizedBox(height: 12.h),
              Text('No tasks found',
                  style: GoogleFonts.manrope(
                      fontSize: 15.sp, color: const Color(0xFF8B7D77))),
            ],
          ),
        );
      }
      return ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: tasks.length,
        itemBuilder: (_, i) => _TaskCard(task: tasks[i], c: c),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────
// REGULAR EMPLOYEE TASK LIST
// ─────────────────────────────────────────────────────────────────────────

class _RegularTaskList extends StatelessWidget {
  final TaskController c;
  const _RegularTaskList({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (c.isLoading.value) {
        return const Center(
            child: CircularProgressIndicator(color: Color(0xFF6A3027)));
      }
      final tasks = c.filteredTasks;
      if (tasks.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_outlined,
                  size: 58.sp, color: const Color(0xFF8B7D77)),
              SizedBox(height: 12.h),
              Text('No tasks assigned to you',
                  style: GoogleFonts.manrope(
                      fontSize: 15.sp, color: const Color(0xFF8B7D77))),
              SizedBox(height: 16.h),
              ElevatedButton.icon(
                onPressed: () => c.fetchAll(),
                icon:
                    Icon(Icons.refresh_rounded, size: 16.sp, color: Colors.white),
                label: Text('Refresh',
                    style: GoogleFonts.manrope(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB54A3A),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        );
      }
      return ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: tasks.length,
        itemBuilder: (_, i) => _TaskCard(task: tasks[i], c: c),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────
// TAB TOGGLE
// ─────────────────────────────────────────────────────────────────────────

class _TabToggle extends StatelessWidget {
  final TaskController c;
  const _TabToggle({required this.c});

  @override
  Widget build(BuildContext context) {
    final isManager = _isProjectManager;
    final isTL = _isTeamLeader;
    return Obx(() {
      final _ = c.activeTab.value;
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE8DDD9),
          borderRadius: BorderRadius.circular(14.r),
        ),
        padding: EdgeInsets.all(4.w),
        child: Row(
          children: [
            if (isManager) ...[
              _tab('Given', 0),
              _tab('Projects', 1),
            ] else if (isTL) ...[
              _tab('Given', 0),
              _tab('Received', 1),
              _tab('Projects', 2),
            ] else ...[
              _tab('Tasks', 0),
            ],
          ],
        ),
      );
    });
  }

  Widget _tab(String label, int index) {
    final active = c.effectiveTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => c.switchTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFB54A3A) : Colors.transparent,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : const Color(0xFF8B7D77),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// SEARCH BAR
// ─────────────────────────────────────────────────────────────────────────

class _DetailSection extends StatelessWidget {
  final String label;
  final Widget child;
  const _DetailSection({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style:
          GoogleFonts.inter(fontSize: 14.sp, color: const Color(0xFF241917)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF8B7D77)),
        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6A3027)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(vertical: 12.h),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: const BorderSide(color: Color(0xFFB54A3A), width: 1.5),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DetailRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: const [
          BoxShadow(
              color: Color(0x12000000), blurRadius: 14, offset: Offset(0, 7))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatTile(
              c: c,
              label: 'Total',
              value: () => c.totalCount,
              icon: Icons.view_agenda_rounded,
              color: const Color(0xFF6A3027),
              filter: 'All'),
          _divider(),
          _StatTile(
              c: c,
              label: 'Active',
              value: () => c.activeCount,
              icon: Icons.play_circle_outline_rounded,
              color: Colors.orange,
              filter: 'Active'),
          _divider(),
          _StatTile(
              c: c,
              label: 'Completed',
              value: () => c.approvedCount,
              icon: Icons.check_circle_rounded,
              color: Colors.green,
              filter: 'Approved'),
          _divider(),
          _StatTile(
              c: c,
              label: 'Overdue',
              value: () => c.overdueCount,
              icon: Icons.warning_amber_rounded,
              color: Colors.red,
              filter: 'Overdue'),
          if (showEmpTile) ...[_divider(), _EmpTileWidget(c: c)],
        ],
      ),
    );
  }
}

class _AttachmentLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _AttachmentLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final active = c.selectedFilter.value == filter;
      return GestureDetector(
        onTap: () => c.setFilter(filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: active ? color.withOpacity(0.10) : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
            border: active
                ? Border.all(color: color.withOpacity(0.40), width: 1.2)
                : Border.all(color: Colors.transparent, width: 1.2),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 24.sp,
                  color: active ? color : color.withOpacity(0.40)),
              SizedBox(height: 5.h),
              Text('${value()}',
                  style: GoogleFonts.manrope(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: active ? color : const Color(0xFF241917))),
              SizedBox(height: 2.h),
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: active ? color : const Color(0xFF8B7D77))),
            ],
          ),
        ),
      );
    });
  }
}

/// Downloads the attachment on tap (Android, via [FileDownloader]) and opens
/// it with the device's default viewer. Falls back to launching the URL
/// externally on platforms the downloader plugin doesn't support.
class _AttachmentDownloadTile extends StatefulWidget {
  final String url;
  const _AttachmentDownloadTile({required this.url});

  @override
  Widget build(BuildContext context) {
    return Obx(() => _EmpListTile(
          count: c.employees.length,
          onTap: () => Get.bottomSheet(
            _EmployeeListSheet(controller: c),
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
          ),
        ));
  }
}

class _EmpListTile extends StatefulWidget {
  final VoidCallback onTap;
  final int count;
  const _EmpListTile({required this.onTap, required this.count});

  @override
  State<_EmpListTile> createState() => _EmpListTileState();
}

class _EmpListTileState extends State<_EmpListTile> {
  bool _pressed = false;
  static const _color = Color(0xFF6A3027);

  @override
  Widget build(BuildContext context) {
    final label = _downloading
        ? 'Downloading… ${_progress.toStringAsFixed(0)}%'
        : (_localPath != null ? 'Open File' : 'View File');

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.people_alt_rounded,
                size: 24.sp,
                color: _pressed ? _color : _color.withOpacity(0.40)),
            SizedBox(height: 5.h),
            Text('${widget.count}',
                style: GoogleFonts.manrope(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: _pressed ? _color : const Color(0xFF241917))),
            SizedBox(height: 2.h),
            Text('Emp List',
                style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: _pressed ? _color : const Color(0xFF8B7D77))),
          ],
        ),
      ),
    );
  }
}

// Normalized by stripping everything but letters so stray casing/spacing/
// punctuation from the API ("Team Leader", "TeamLeader", "team_leader", ...)
// still matches.
String _readDesignation() {
  final box = GetStorage();
  final raw = (box.read('Designation') ?? box.read('designation') ?? '')
      .toString();
  return raw.toLowerCase().replaceAll(RegExp('[^a-z]'), '');
}

bool _isCurrentUserProjectManager() => _readDesignation() == 'projectmanager';

// ── Task Screen ────────────────────────────────────────────────────────────

class TaskScreen extends GetView<TaskController> {
  const TaskScreen({super.key});

  String get _designation => _readDesignation();

  bool get _isProjectManager => _isCurrentUserProjectManager();
  bool get _isTeamLeader => _designation == 'teamleader';
  bool get _isDeveloper => _designation == 'developer';

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final projects = pc.allProjects;
      final current = pc.selectedFilter.value;
      return Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: const [
            BoxShadow(
                color: Color(0x12000000), blurRadius: 14, offset: Offset(0, 7))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _pTile('Total', '${projects.length}', Icons.folder_outlined,
                const Color(0xFF6A3027), 'All', current),
            _divider(),
            _pTile(
                'Running',
                '${projects.where((p) => p.projectStatus == 'Running').length}',
                Icons.play_circle_outline_rounded,
                Colors.green,
                'Running',
                current),
            _divider(),
            _pTile(
                'Complete',
                '${projects.where((p) => p.projectStatus == 'Complete').length}',
                Icons.check_circle_outline_rounded,
                Colors.blue,
                'Complete',
                current),
            _divider(),
            _pTile(
                'On Hold',
                '${projects.where((p) => p.projectStatus == 'On Hold').length}',
                Icons.pause_circle_outline_rounded,
                Colors.orange,
                'On Hold',
                current),
          ],
        ),
      );
    });
  }

  Widget _divider() =>
      Container(height: 38.h, width: 1, color: const Color(0xFFE8DDD9));

  Widget _pTile(String label, String value, IconData icon, Color color,
      String filter, String current) {
    final active = current == filter;
    return GestureDetector(
      onTap: () => pc.setFilter(filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          border: active
              ? Border.all(color: color.withOpacity(0.40), width: 1.2)
              : Border.all(color: Colors.transparent, width: 1.2),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 24.sp,
                color: active ? color : color.withOpacity(0.40)),
            SizedBox(height: 5.h),
            Text(value,
                style: GoogleFonts.manrope(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: active ? color : const Color(0xFF241917))),
            SizedBox(height: 2.h),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: active ? color : const Color(0xFF8B7D77))),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// TL PROJECT STATS CARD
// ─────────────────────────────────────────────────────────────────────────

class _TLProjectStatsCard extends StatelessWidget {
  final ProjectController pc;
  const _TLProjectStatsCard({required this.pc});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final all = pc.tlAllocateProjects;
      final uniqueProjects =
          all.map((p) => p.sProjectId).toSet().length;
      final uniqueMembers =
          all.map((p) => p.employeeId).toSet().length;

      return Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: const [
            BoxShadow(
                color: Color(0x12000000), blurRadius: 14, offset: Offset(0, 7))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _statTile(
              label: 'Total',
              value: '${all.length}',
              icon: Icons.folder_outlined,
              color: const Color(0xFF6A3027),
            ),
            _divider(),
            _statTile(
              label: 'Projects',
              value: '$uniqueProjects',
              icon: Icons.work_outline_rounded,
              color: Colors.blue,
            ),
            _divider(),
            _statTile(
              label: 'Members',
              value: '$uniqueMembers',
              icon: Icons.people_outline_rounded,
              color: Colors.green,
            ),
          ],
        ),
      );
    });
  }

  Widget _divider() =>
      Container(height: 38.h, width: 1, color: const Color(0xFFE8DDD9));

  Widget _statTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 22.sp, color: color),
        SizedBox(height: 5.h),
        Text(value,
            style: GoogleFonts.manrope(
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF241917))),
        SizedBox(height: 2.h),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 9.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8B7D77))),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// STATUS HELPERS
// ─────────────────────────────────────────────────────────────────────────

Color _statusColor(String status) {
  switch (status) {
    case 'Approved':
    case 'Done':
    case 'Complete':
      return Colors.green;
    case 'AwaitingLeadApproval':
    case 'AwaitingAssignerApproval':
    case 'AwaitingPMApproval':
    case 'Submitted':
      return Colors.blue;
    case 'LeadRejected':
    case 'AssignerRejected':
    case 'PMRejected':
      return Colors.red;
    case 'Pending':
    default:
      return Colors.orange;
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'AwaitingLeadApproval':
      return 'Awaiting TL';
    case 'AwaitingAssignerApproval':
      return 'Awaiting Assigner';
    case 'AwaitingPMApproval':
      return 'Awaiting PM';
    case 'LeadRejected':
      return 'TL Rejected';
    case 'AssignerRejected':
      return 'Assigner Rejected';
    case 'PMRejected':
      return 'PM Rejected';
    default:
      return status;
  }
}

/// Progress for the linear progress bar — based on Data.effectiveStatus.
double _taskProgress(Data t) {
  final hasJunior =
      (t.juniorId ?? '').trim().isNotEmpty && t.juniorId != '0';
  final hasTL = t.teamLeadId.trim().isNotEmpty;
  final totalSteps = (hasJunior && hasTL) ? 3 : 2;

  switch (t.effectiveStatus) {
    case 'Pending':
      return 0.0;
    case 'Submitted':
      return 1 / (totalSteps + 1);
    case 'AwaitingLeadApproval':
      return totalSteps == 3 ? 0.33 : 0.5;
    case 'AwaitingAssignerApproval':
      return totalSteps == 3 ? 0.67 : 0.5;
    case 'AwaitingPMApproval':
      return totalSteps == 3 ? 0.85 : 0.75;
    case 'Approved':
    case 'Done':
    case 'Complete':
      return 1.0;
    case 'LeadRejected':
    case 'AssignerRejected':
    case 'PMRejected':
      return 0.05;
    default:
      return 0.0;
  }
}

// ─────────────────────────────────────────────────────────────────────────
// REMARK TILE
// ─────────────────────────────────────────────────────────────────────────

class _RemarkTile extends StatelessWidget {
  final String byLabel;
  final RemarkModel remark;
  const _RemarkTile({required this.byLabel, required this.remark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 8.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.red.withOpacity(0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.comment_outlined, size: 14.sp, color: Colors.red),
          SizedBox(width: 6.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$byLabel: ${remark.rejectedBy}',
                    style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.red.shade700)),
                SizedBox(height: 3.h),
                Text(remark.remark,
                    style: GoogleFonts.inter(
                        fontSize: 12.sp, color: const Color(0xFF241917))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// REJECT DIALOG
// ─────────────────────────────────────────────────────────────────────────

Future<String?> _showRejectDialog(BuildContext context) async {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFFF6F1ED),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
      title: Text('Rejection Remark',
          style: GoogleFonts.manrope(
              fontWeight: FontWeight.w800, color: const Color(0xFF241917))),
      content: TextField(
        controller: ctrl,
        maxLines: 3,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Enter reason for rejection…',
          hintStyle: GoogleFonts.inter(
              fontSize: 13.sp, color: const Color(0xFF8B7D77)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide:
                const BorderSide(color: Color(0xFFB54A3A), width: 1.5),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Cancel',
              style: GoogleFonts.manrope(color: const Color(0xFF8B7D77))),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB54A3A),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r)),
            elevation: 0,
          ),
          onPressed: () {
            final text = ctrl.text.trim();
            if (text.isEmpty) return;
            Navigator.pop(ctx, text);
          },
          child: Text('Reject',
              style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// MARK-DONE DIALOG
// ─────────────────────────────────────────────────────────────────────────

Future<String?> _showMarkDoneDialog(BuildContext context) async {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFFF6F1ED),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
      title: Text('Mark as Done',
          style: GoogleFonts.manrope(
              fontWeight: FontWeight.w800, color: const Color(0xFF241917))),
      content: TextField(
        controller: ctrl,
        maxLines: 3,
        autofocus: true,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
              fontSize: 13.sp, color: const Color(0xFF8B7D77)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide:
                const BorderSide(color: Color(0xFF4CAF50), width: 1.5),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Cancel',
              style: GoogleFonts.manrope(color: const Color(0xFF8B7D77))),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r)),
            elevation: 0,
          ),
          onPressed: () => Navigator.pop(
              ctx,
              ctrl.text.trim().isEmpty
                  ? 'Task completed'
                  : ctrl.text.trim()),
          child: Text('Submit',
              style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// TASK CARD  — now uses Data instead of old flat TaskModel
// ─────────────────────────────────────────────────────────────────────────

class _TaskCard extends StatefulWidget {
  final Data task;          // ← Data, not old TaskModel
  final TaskController c;
  const _TaskCard({required this.task, required this.c});

  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _anim;
  late final Animation<double> _rotate;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _rotate = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _anim.forward() : _anim.reverse();
  }

  bool _needsAction(TaskController c) {
    final t = widget.task;
    final s = t.effectiveStatus;
    final isApiPendingReview =
        (t.aStatus == 'Done' || t.aStatus == 'InProgress') && t.overrideStatus == null;
    if (_isProjectManager) {
      final isGiven = c.givenTasks.any((g) => g.uniqueId == t.uniqueId);
      return isGiven &&
          (s == 'Submitted' ||
              s == 'AwaitingPMApproval' ||
              s == 'AwaitingAssignerApproval' ||
              isApiPendingReview);
    }
    if (_isTeamLeader) {
      final isGiven = c.givenTasks.any((g) => g.uniqueId == t.uniqueId);
      return isGiven && (s == 'AwaitingLeadApproval' || isApiPendingReview);
    }
    return false;
  }

  Color get _priorityColor {
    switch (widget.task.priority) {
      case 'High':
        return Colors.red;
      case 'Low':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    final statusColor = _statusColor(t.effectiveStatus);
    final progress = _taskProgress(t);
    final isApproved = TaskStatus.isApproved(t.effectiveStatus);

    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: t.isOverdue && !isApproved
            ? Border.all(color: Colors.red.withOpacity(0.45), width: 1.4)
            : Border.all(color: Colors.transparent),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(18.r),
              bottom: Radius.circular(_expanded ? 0 : 18.r),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 12.w, 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.title,
                          style: GoogleFonts.manrope(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF241917)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Obx(() {
                        final _ = widget.c.allTasks.length;
                        if (!_needsAction(widget.c))
                          return const SizedBox.shrink();
                        return Container(
                          width: 8.w,
                          height: 8.w,
                          margin: EdgeInsets.only(right: 4.w),
                          decoration: const BoxDecoration(
                              color: Colors.red, shape: BoxShape.circle),
                        );
                      }),
                      SizedBox(width: 2.w),
                      RotationTransition(
                        turns: _rotate,
                        child: Icon(Icons.expand_more_rounded,
                            color: const Color(0xFF6A3027), size: 22.sp),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 4.h,
                    children: [
                      TaskBadge(_statusLabel(t.effectiveStatus), statusColor),
                      TaskBadge(t.priority ?? 'Medium', _priorityColor),
                      if (t.isOverdue && !isApproved)
                        TaskBadge('Overdue', Colors.red),
                      if ((t.projectName ?? '').isNotEmpty)
                        TaskBadge(t.projectName!, const Color(0xFF6A3027)),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5.h,
                      backgroundColor: const Color(0xFFE8DDD9),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isApproved ? Colors.green : statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _ExpandedTaskBody(task: t, c: widget.c),
            crossFadeState:
                _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// EXPANDED TASK BODY  — uses Data
// ─────────────────────────────────────────────────────────────────────────

class _ExpandedTaskBody extends StatelessWidget {
  final Data task;
  final TaskController c;
  const _ExpandedTaskBody({required this.task, required this.c});

  /// Always resolve the live copy from the observable list.
  Data _live() =>
      c.allTasks.firstWhere((x) => x.uniqueId == task.uniqueId,
          orElse: () => task);

  static bool _isApproved(String s) => TaskStatus.isApproved(s);
  static bool _isRejected(String s) => TaskStatus.isRejected(s);

  bool _isGivenByMe(Data t) =>
      c.givenTasks.any((g) => g.uniqueId == t.uniqueId);

  static String _stepLabel(String status) {
    switch (status) {
      case 'Pending':
        return 'Not started';
      case 'Submitted':
        return 'Employee submitted';
      case 'AwaitingLeadApproval':
        return 'Awaiting TL review';
      case 'AwaitingPMApproval':
        return 'Awaiting PM approval';
      case 'Approved':
      case 'Done':
      case 'Complete':
        return 'Fully approved';
      case 'LeadRejected':
        return 'TL rejected';
      case 'PMRejected':
        return 'PM rejected';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final live = _live();
      final status = live.effectiveStatus;

      final isPM = _isProjectManager;
      final isTL = _isTeamLeader;
      final isEmp = _isRegularEmployee;
      final currentTab = c.effectiveTab;

      final isGiven = _isGivenByMe(live);

      // API returns "Done"/"InProgress" to mean "employee submitted, awaiting review".
      // Don't treat these as fully approved when they're in the given list.
      final isApiPendingReview = isGiven &&
          (live.aStatus == 'Done' || live.aStatus == 'InProgress') &&
          live.overrideStatus == null;

      final approved = _isApproved(status) && !isApiPendingReview;
      final rejected = _isRejected(status);

      final hasJunior =
          (live.juniorId ?? '').trim().isNotEmpty && live.juniorId != '0';
      final hasTL = live.teamLeadId.trim().isNotEmpty;
      final is3Way = hasJunior && hasTL;

      final isWorkerCtx = isEmp || (isTL && currentTab == 1);

      final canDone = c.canMarkDone(live);
      final isAwaiting = c.isSubmittedAwaitingReview(live);

      final tlShouldReview = isTL &&
          currentTab == 0 &&
          isGiven &&
          (status == TaskStatus.awaitingTL ||
              (status == TaskStatus.submitted && is3Way) ||
              isApiPendingReview);

      final pmShouldReview = isPM &&
          currentTab == 0 &&
          isGiven &&
          (status == TaskStatus.awaitingPM ||
              (status == TaskStatus.submitted && !is3Way) ||
              isApiPendingReview);

      final canLApprove = c.canLeadApprove(live) || tlShouldReview;
      final canPApprove = c.canPMApprove(live) || pmShouldReview;
      final anyReviewAction = canLApprove || canPApprove;

      String reviewerMsg = '';
      if (canLApprove) {
        reviewerMsg =
            'Employee has submitted this task. Review and approve or reject.';
      } else if (canPApprove) {
        reviewerMsg = is3Way
            ? 'Team lead has approved this task. Give your final PM approval.'
            : 'Task submitted by the assignee. Give your final approval.';
      }

      String workerWaitMsg = '';
      if (isAwaiting && !canDone) {
        switch (status) {
          case 'Submitted':
          case 'AwaitingPMApproval':
          case 'AwaitingAssignerApproval':
            workerWaitMsg = 'Submitted to PM. Awaiting final approval.';
            break;
          case 'AwaitingLeadApproval':
            workerWaitMsg = 'Submitted. Awaiting team lead review.';
            break;
        }
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: Color(0xFFF0E8E4), height: 1),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Approval chain ──────────────────────────────────
                _ApprovalChain(task: live, is3Way: is3Way),
                SizedBox(height: 14.h),

                // ── Description ─────────────────────────────────────
                if (live.description.isNotEmpty) ...[
                  Text('Description',
                      style: GoogleFonts.manrope(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF8B7D77))),
                  SizedBox(height: 4.h),
                  Text(live.description,
                      style: GoogleFonts.inter(
                          fontSize: 13.sp, color: const Color(0xFF241917))),
                  SizedBox(height: 12.h),
                ],

                // ── Meta ────────────────────────────────────────────
                if (!isEmp)
                  _MetaRow(
                      label: 'Assigned by',
                      value: live.assignedByName.isNotEmpty
                          ? live.assignedByName
                          : '—'),
                _MetaRow(
                  label: 'Assigned to',
                  value: () {
                    if (hasJunior && (live.juniorName ?? '').isNotEmpty)
                      return live.juniorName!;
                    if (live.teamLeadName.isNotEmpty) return live.teamLeadName;
                    return '—';
                  }(),
                ),
                if (live.startDate.isNotEmpty)
                  _MetaRow(label: 'Start', value: live.startDate),
                if (live.dueDate.isNotEmpty)
                  _MetaRow(label: 'Due', value: live.dueDate),
                if ((live.recurrence ?? '').isNotEmpty &&
                    live.recurrence != 'None')
                  _MetaRow(label: 'Recurrence', value: live.recurrence!),
                SizedBox(height: 10.h),

                // ── Rejection remarks ────────────────────────────────
                if (live.leadRemark != null)
                  _RemarkTile(byLabel: 'TL', remark: live.leadRemark!),
                if (live.assignerRemark != null)
                  _RemarkTile(
                      byLabel: 'Assigner', remark: live.assignerRemark!),
                if (live.pmRemark != null)
                  _RemarkTile(byLabel: 'PM', remark: live.pmRemark!),

                SizedBox(height: 8.h),

                // ── Approved badge ───────────────────────────────────
                if (approved) ...[
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10.r),
                      border:
                          Border.all(color: Colors.green.withOpacity(0.30)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline_rounded,
                            size: 16.sp, color: Colors.green),
                        SizedBox(width: 8.w),
                        Text('Task completed and approved ✓',
                            style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700)),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),
                ],

                // ── Rejected resubmit prompt ─────────────────────────
                if (rejected && isWorkerCtx) ...[
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 12.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                          color: Colors.orange.withOpacity(0.30)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.replay_rounded,
                            size: 15.sp, color: Colors.orange),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                              'Your submission was rejected. See the remark above and resubmit.',
                              style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  color: Colors.orange.shade800)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),
                ],

                // ── Worker wait-state banner ─────────────────────────
                if (workerWaitMsg.isNotEmpty && !approved) ...[
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 12.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                          color: Colors.blue.withOpacity(0.20)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.hourglass_empty_rounded,
                            size: 15.sp, color: Colors.blue),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(workerWaitMsg,
                              style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  color: Colors.blue.shade800)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),
                ],

                // ── Reviewer action banner ───────────────────────────
                if (anyReviewAction) ...[
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 12.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                          color: Colors.amber.withOpacity(0.35)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notification_important_rounded,
                            size: 15.sp, color: Colors.amber.shade800),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(reviewerMsg,
                              style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.amber.shade900)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),
                ],

                // ═══════════════════════════════════════════════════════
                // ACTION BUTTONS
                // ═══════════════════════════════════════════════════════
                if (c.isSubmitting.value)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      child: const CircularProgressIndicator(
                          color: Color(0xFF6A3027), strokeWidth: 2.5),
                    ),
                  )
                else ...[

                  // ── WORKER: Mark Done ────────────────────────────────
                  if (isWorkerCtx) ...[
                    if (canDone || isAwaiting)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: canDone
                              ? () async {
                                  final desc =
                                      await _showMarkDoneDialog(context);
                                  if (desc != null)
                                    c.markDone(live.uniqueId,
                                        description: desc);
                                }
                              : null,
                          icon: Icon(
                            isAwaiting
                                ? Icons.hourglass_top_rounded
                                : Icons.check_rounded,
                            size: 16.sp,
                            color: Colors.white,
                          ),
                          label: Text(
                            isAwaiting
                                ? 'Submitted — awaiting review'
                                : rejected
                                    ? 'Resubmit task'
                                    : 'Mark as done',
                            style: GoogleFonts.manrope(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isAwaiting
                                ? Colors.grey.shade400
                                : rejected
                                    ? Colors.orange
                                    : const Color(0xFF4CAF50),
                            disabledBackgroundColor: Colors.grey.shade400,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r)),
                            elevation: 0,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                          ),
                        ),
                      ),
                    SizedBox(height: 8.h),
                  ],

                  // ── TL REVIEWER ──────────────────────────────────────
                  if (canLApprove) ...[
                    _SectionLabel('Team Lead Review'),
                    SizedBox(height: 8.h),
                    _ApproveRejectRow(
                      approveLabel: 'Approve',
                      approveIcon: Icons.thumb_up_alt_rounded,
                      approveColor: const Color(0xFF4CAF50),
                      rejectColor: const Color(0xFFB54A3A),
                      onApprove: () => c.leadApprove(live.uniqueId),
                      onReject: (r) => c.leadReject(live.uniqueId, r),
                      context: context,
                    ),
                  ),
                ),
              ),
            SizedBox(width: 4.w),
            Icon(Icons.chevron_right_rounded, size: 18.sp, color: _kTextMuted),
          ],
        ),
      ),
    );
  }
}

// ── Tab 3: Received Projects ──────────────────────────────────────────────────

class _ReceivedProjectsTab extends StatefulWidget {
  final bool canAssign;
  final bool canUpdate;
  const _ReceivedProjectsTab({this.canAssign = false, this.canUpdate = false});

  @override
  State<_ReceivedProjectsTab> createState() => _ReceivedProjectsTabState();
}

class _ReceivedProjectsTabState extends State<_ReceivedProjectsTab> {
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
    final status = task.effectiveStatus;
    final steps = <_ChainStep>[];

    if (is3Way) {
      steps.addAll([
        _ChainStep(
          label: 'Employee',
          sub: task.juniorName ?? task.teamLeadName,
          state: _empState(status),
        ),
        _ChainStep(
          label: 'TL Review',
          sub: task.teamLeadName,
          state: _tlState(status),
        ),
        _ChainStep(
          label: 'PM Approve',
          sub: 'PM',
          state: _pmState(status),
        ),
      ]);
    } else {
      steps.addAll([
        _ChainStep(
          label: 'In Progress',
          sub: task.teamLeadName.isNotEmpty ? task.teamLeadName : '—',
          state: _empState(status),
        ),
        _ChainStep(
          label: 'PM Approve',
          sub: 'PM',
          state: _pmState(status),
        ),
      ]);
    }

    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: _kBrand.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5.w, color: accentColor),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardTitleRow extends StatelessWidget {
  final String title;
  final String status;
  final Color statusColor;
  const _CardTitleRow({
    required this.title,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: _kTextPrimary,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        _StatusPill(label: status, color: statusColor),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20.w,
          height: 20.w,
          decoration: BoxDecoration(
            color: _color.withOpacity(
                step.state == _StepState.pending ? 0.10 : 0.16),
            shape: BoxShape.circle,
            border: Border.all(color: _color, width: 1.4),
          ),
          child: Icon(_icon, size: 10.sp, color: _color),
        ),
        SizedBox(height: 3.h),
        Text(step.label,
            style: GoogleFonts.inter(
                fontSize: 8.sp, fontWeight: FontWeight.w700, color: _color)),
        if (step.sub != null && step.sub!.isNotEmpty)
          Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 7.sp, color: const Color(0xFF8B7D77)),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

class _PriorityPill extends StatelessWidget {
  final String priority;
  const _PriorityPill({required this.priority});

  @override
  Widget build(BuildContext context) {
    if (priority.isEmpty) return const SizedBox.shrink();
    final color = _priorityColor(priority);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(text,
          style: GoogleFonts.inter(
              fontSize: 10.sp, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String? label;
  final String value;
  final bool highlight;
  const _MetaChip({
    required this.icon,
    this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(10.r)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14.sp, color: color),
            SizedBox(width: 4.w),
            Text(label,
                style: GoogleFonts.manrope(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ],
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 10.5.sp,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w400,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  final String name;
  const _PersonRow({required this.name});

  @override
  Widget build(BuildContext context) {
    if (name.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        Container(
          width: 22.w,
          height: 22.w,
          decoration: BoxDecoration(
            color: _kBrand.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              _initials(name),
              style: GoogleFonts.manrope(
                fontSize: 9.5.sp,
                fontWeight: FontWeight.w800,
                color: _kBrand,
              ),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onApprove,
            icon: Icon(approveIcon, size: 15.sp, color: Colors.white),
            label: Text(approveLabel,
                style: GoogleFonts.manrope(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: approveColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r)),
              elevation: 0,
              padding: EdgeInsets.symmetric(vertical: 11.h),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              final remark = await _showRejectDialog(context);
              if (remark != null) onReject(remark);
            },
            icon: Icon(Icons.cancel_outlined, size: 15.sp, color: rejectColor),
            label: Text('Reject',
                style: GoogleFonts.manrope(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: rejectColor)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: rejectColor, width: 1.4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r)),
              padding: EdgeInsets.symmetric(vertical: 11.h),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Received Card ─────────────────────────────────────────────────────────────

class _ReceivedCard extends StatelessWidget {
  final received.RData item;
  final bool canAssign;
  final bool canUpdate;
  const _ReceivedCard({
    required this.item,
    this.canAssign = false,
    this.canUpdate = false,
  });

  void _showAssignSheet(BuildContext context) {
    Get.bottomSheet(
      _AssignTaskSheet(
        projectId: item.sProjectId ?? 0,
        projectName: item.projectName ?? item.taskTittle ?? '',
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _showUpdateSheet(BuildContext context) {
    Get.bottomSheet(
      _UpdateProgressSheet(
        proAllocatId: item.proAllocatId ?? 0,
        taskTitle: item.taskTittle ?? item.projectName ?? '',
        currentProgress: item.progress,
        notifyEmployeeId: item.employeeId1,
        notifyEmployeeName: item.employeeName1,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = item.aStatus ?? '';
    final priority = item.priority ?? '';
    final person = item.employeeName ?? '';

    return _CardShell(
      accentColor: _statusColor(status),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90.w,
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8B7D77))),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.inter(
                    fontSize: 11.sp, color: const Color(0xFF241917))),
          ),
        ],
      ),
    );
  }
}

// ── My Project Card ───────────────────────────────────────────────────────────

class _TaskForm extends StatefulWidget {
  final TaskController c;
  final Data? existing;          // ← Data, not old TaskModel
  final String? preselectedProjectId;
  final String? preselectedProjectName;
  const _TaskForm({
    required this.c,
    this.existing,
    this.preselectedProjectId,
    this.preselectedProjectName,
  });

  @override
  State<_TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<_TaskForm> {
  late final TextEditingController _title;
  late final TextEditingController _desc;
  late final TextEditingController _startDate;
  late final TextEditingController _dueDate;
  late final TextEditingController _empSearch;

  List<String> _selectedEmployeeIds = [];
  String? _selectedJuniorId;
  String _priority = 'Medium';
  String _recurrence = 'None';
  DateTime _startDt = DateTime.now();
  DateTime? _dueDt;
  String? _projectId;
  String? _projectName;
  final List<Map<String, dynamic>> _attachments = [];

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _desc = TextEditingController(text: e?.description ?? '');
    _dueDate = TextEditingController(text: e?.dueDate ?? '');
    _empSearch = TextEditingController();
    _priority = e?.priority ?? 'Medium';
    _recurrence = e?.recurrence ?? 'None';
    // Pre-fill assigned employee from Data.teamLeadId
    _selectedEmployeeIds =
        (e?.teamLeadId.isNotEmpty == true) ? [e!.teamLeadId] : [];
    _selectedJuniorId = e?.juniorId;
    _projectId = widget.preselectedProjectId ?? e?.sProjectId?.toString();
    _projectName = widget.preselectedProjectName ?? e?.projectName;

    _startDt = e?.startDate.isNotEmpty == true
        ? DateTime.tryParse(e!.startDate) ?? DateTime.now()
        : DateTime.now();
    _startDate = TextEditingController(
        text: DateFormat('dd-MM-yyyy').format(_startDt));
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _startDate.dispose();
    _dueDate.dispose();
    _empSearch.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'webp'],
    );
    if (result == null) return;
    setState(() {
      for (final f in result.files) {
        if (f.path != null) {
          _attachments.add({
            'name': f.name,
            'path': f.path!,
            'type': f.extension?.toLowerCase() == 'pdf' ? 'pdf' : 'image',
          });
        }
      }
    });
  }

  Future<void> _pickCamera() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked == null) return;
    setState(() => _attachments.add({
          'name': picked.name,
          'path': picked.path,
          'type': 'image',
        }));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.90,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (_, scroll) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF6F1ED),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        ),
        child: Column(
          children: [
            SizedBox(height: 12.h),
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                  color: const Color(0xFFCBC0BA),
                  borderRadius: BorderRadius.circular(2.r)),
            ),
            SizedBox(height: 14.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEdit ? 'Edit Task' : 'Assign New Task',
                    style: GoogleFonts.manrope(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF241917)),
                  ),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: const BoxDecoration(
                          color: Color(0xFFE8DDD9), shape: BoxShape.circle),
                      child: Icon(Icons.close,
                          size: 18.sp, color: const Color(0xFF6A3027)),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            const Divider(color: Color(0xFFE0D5D0), height: 1),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 40.h),
                children: [
                  if (_isProjectManager || _isTeamLeader) ...[
                    _label('Link to Project'),
                    SizedBox(height: 6.h),
                    _projectDropdown(),
                    SizedBox(height: 14.h),
                  ],
                  _label('Select Employees'),
                  SizedBox(height: 6.h),
                  _employeeSelector(),
                  SizedBox(height: 14.h),
                  _label('Module / Task *'),
                  SizedBox(height: 6.h),
                  _field(_title, 'e.g. Review Q2 report'),
                  SizedBox(height: 14.h),
                  _label('Description'),
                  SizedBox(height: 6.h),
                  _field(_desc, 'Brief details…', maxLines: 3),
                  SizedBox(height: 14.h),
                  _label('Attachments (optional)'),
                  SizedBox(height: 6.h),
                  _attachmentSection(),
                  SizedBox(height: 14.h),
                  _label('Start Date'),
                  SizedBox(height: 6.h),
                  _datePicker(
                    ctrl: _startDate,
                    selected: _startDt,
                    hint: 'Select start date',
                    onPicked: (d) => setState(() {
                      _startDt = d;
                      _startDate.text = DateFormat('dd-MM-yyyy').format(d);
                    }),
                  ),
                  SizedBox(height: 14.h),
                  _label('Due Date'),
                  SizedBox(height: 6.h),
                  _datePicker(
                    ctrl: _dueDate,
                    selected: _dueDt,
                    hint: 'Select due date',
                    onPicked: (d) => setState(() {
                      _dueDt = d;
                      _dueDate.text = DateFormat('dd-MM-yyyy').format(d);
                    }),
                  ),
                  SizedBox(height: 14.h),
                  _label('Recurrence'),
                  SizedBox(height: 8.h),
                  _chips(
                    ['Daily', 'Weekly', 'Alternate', 'Monthly', 'None'],
                    _recurrence,
                    (v) => setState(() => _recurrence = v),
                  ),
                  SizedBox(height: 14.h),
                  _label('Priority'),
                  SizedBox(height: 8.h),
                  _chips(
                    ['High', 'Medium', 'Low'],
                    _priority,
                    (v) => setState(() => _priority = v),
                    colors: {
                      'High': Colors.red,
                      'Medium': Colors.orange,
                      'Low': Colors.green
                    },
                  ),
                  SizedBox(height: 28.h),
                  Obx(() => SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              widget.c.isSubmitting.value ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB54A3A),
                            disabledBackgroundColor:
                                const Color(0xFFB54A3A).withOpacity(0.5),
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.r)),
                            elevation: 0,
                          ),
                          child: widget.c.isSubmitting.value
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  _isEdit ? 'Save Changes' : 'Assign Task',
                                  style: GoogleFonts.manrope(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white),
                                ),
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _employeeSelector() {
    final employees = widget.c.employees;
    return GestureDetector(
      onTap: () async {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => StatefulBuilder(
            builder: (ctx, setModal) {
              String search = _empSearch.text;
              return Obx(() {
                final emps = widget.c.employees;
                final isLoading = widget.c.isLoading.value;
                final filtered = emps
                    .where((e) => e.employeeName
                        .toLowerCase()
                        .contains(search.toLowerCase()))
                    .toList();

                if (isLoading && emps.isEmpty) {
                  return Container(
                    height: MediaQuery.of(context).size.height * 0.65,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F1ED),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24.r)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                            color: Color(0xFF6A3027)),
                        SizedBox(height: 16.h),
                        Text('Loading employees…',
                            style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                color: const Color(0xFF241917))),
                      ],
                    ),
                  );
                }

                if (emps.isEmpty) {
                  return Container(
                    height: MediaQuery.of(context).size.height * 0.65,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F1ED),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24.r)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 48.sp, color: const Color(0xFF8B7D77)),
                        SizedBox(height: 12.h),
                        Text('No employees loaded yet',
                            style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                color: const Color(0xFF8B7D77))),
                        SizedBox(height: 16.h),
                        ElevatedButton.icon(
                          onPressed: () async => widget.c.fetchAll(),
                          icon: Icon(Icons.refresh_rounded,
                              size: 16.sp, color: Colors.white),
                          label: Text('Retry',
                              style: GoogleFonts.manrope(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB54A3A),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Container(
                  height: MediaQuery.of(context).size.height * 0.65,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F1ED),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24.r)),
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 12.h),
                      Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                            color: const Color(0xFFCBC0BA),
                            borderRadius: BorderRadius.circular(2.r)),
                      ),
                      SizedBox(height: 14.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Text('Select Employees',
                            style: GoogleFonts.manrope(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF241917))),
                      ),
                      SizedBox(height: 10.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: TextField(
                          controller: _empSearch,
                          onChanged: (v) {
                            search = v;
                            setModal(() {});
                          },
                          style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              color: const Color(0xFF241917)),
                          decoration: InputDecoration(
                            hintText: 'Search by name…',
                            hintStyle: GoogleFonts.inter(
                                fontSize: 13.sp,
                                color: const Color(0xFF8B7D77)),
                            prefixIcon: const Icon(Icons.search_rounded,
                                color: Color(0xFF6A3027)),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 11.h),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: const BorderSide(
                                  color: Color(0xFFB54A3A), width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      const Divider(color: Color(0xFFE0D5D0), height: 1),
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(
                              vertical: 8.h, horizontal: 16.w),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final emp = filtered[i];
                            final id = emp.employeeId.toString();
                            final sel = _selectedEmployeeIds.contains(id);
                            return ListTile(
                              onTap: () {
                                setModal(() {
                                  setState(() {
                                    sel
                                        ? _selectedEmployeeIds.remove(id)
                                        : _selectedEmployeeIds.add(id);
                                  });
                                });
                              },
                              leading: Container(
                                width: 24.w,
                                height: 24.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: sel
                                      ? const Color(0xFFB54A3A)
                                      : const Color(0xFFE8DDD9),
                                ),
                                child: sel
                                    ? Icon(Icons.check,
                                        size: 14.sp, color: Colors.white)
                                    : null,
                              ),
                              title: Text(emp.employeeName,
                                  style: GoogleFonts.inter(
                                      fontSize: 13.sp,
                                      color: const Color(0xFF241917))),
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 4.w),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding:
                            EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB54A3A),
                              padding:
                                  EdgeInsets.symmetric(vertical: 14.h),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14.r)),
                              elevation: 0,
                            ),
                            child: Text(
                              'Done (${_selectedEmployeeIds.length} selected)',
                              style: GoogleFonts.manrope(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              });
            },
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFFE0D5D0)),
        ),
        child: Row(
          children: [
            Icon(Icons.people_outline_rounded,
                size: 17.sp, color: const Color(0xFF6A3027)),
            SizedBox(width: 10.w),
            Expanded(
              child: _selectedEmployeeIds.isEmpty
                  ? Text(
                      employees.isEmpty
                          ? 'Loading employees…'
                          : 'Tap to select employees',
                      style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          color: const Color(0xFF8B7D77)),
                    )
                  : Wrap(
                      spacing: 6.w,
                      runSpacing: 4.h,
                      children: _selectedEmployeeIds.map((id) {
                        final emp = employees.firstWhereOrNull(
                            (e) => e.employeeId.toString() == id);
                        return Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB54A3A).withOpacity(0.10),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                                color: const Color(0xFFB54A3A)
                                    .withOpacity(0.35)),
                          ),
                          child: Text(
                            emp?.employeeName ?? id,
                            style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFB54A3A)),
                          ),
                        );
                      }).toList(),
                    ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                color: const Color(0xFF6A3027)),
          ],
        ),
      ),
    );
  }

  Widget _projectDropdown() {
    if (!Get.isRegistered<ProjectController>()) Get.put(ProjectController());
    final pc = Get.find<ProjectController>();
    final isTL = _isTeamLeader;
    final projectOptions = <Map<String, String>>[];
    if (isTL) {
      final seen = <int>{};
      for (final p in pc.tlAllocateProjects) {
        if (p.sProjectId != 0 && seen.add(p.sProjectId)) {
          projectOptions.add({
            'id': p.sProjectId.toString(),
            'name': p.projectName,
          });
        }
      }
    } else {
      for (final p in pc.allProjects) {
        projectOptions.add(
            {'id': p.projectId.toString(), 'name': p.projectName});
      }
    }
    final selectedId = _projectId?.isEmpty == true ? null : _projectId;
    final locked = widget.preselectedProjectId != null;
    final seenIds = <String>{};

    final items = <DropdownMenuItem<String>>[
      DropdownMenuItem<String>(
        value: null,
        child: Text('None (standalone task)',
            style: GoogleFonts.inter(fontSize: 13.sp)),
      ),
    ];

    if (locked && selectedId != null) {
      seenIds.add(selectedId);
      items.add(DropdownMenuItem<String>(
        value: selectedId,
        child: Row(
          children: [
            Icon(Icons.folder_outlined,
                size: 14.sp, color: const Color(0xFF6A3027)),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                _projectName?.isNotEmpty == true
                    ? _projectName!
                    : 'Selected Project',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 13.sp),
              ),
            ),
          ],
        ),
      ));
    }

    for (final project in projectOptions) {
      final id = project['id'];
      if (id == null || id.isEmpty || seenIds.contains(id)) continue;
      seenIds.add(id);
      items.add(DropdownMenuItem<String>(
        value: id,
        child: Row(
          children: [
            Icon(Icons.folder_outlined,
                size: 14.sp, color: const Color(0xFF6A3027)),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(project['name'] ?? '',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 13.sp)),
            ),
          ],
        ),
      ));
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE0D5D0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedId,
          onChanged: locked
              ? null
              : (v) => setState(() {
                    _projectId = v;
                    if (v == null) {
                      _projectName = null;
                      return;
                    }
                    final sel = projectOptions
                        .firstWhereOrNull((p) => p['id'] == v);
                    _projectName = sel?['name'] ?? _projectName;
                  }),
          hint: Text('None (standalone task)',
              style: GoogleFonts.inter(
                  fontSize: 13.sp, color: const Color(0xFF8B7D77))),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF6A3027)),
          items: items,
        ),
      ),
    );
  }
}

// ── Shared bottom-sheet chrome ──────────────────────────────────────────────

class _SheetHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SheetHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _attachBtn(Icons.image_outlined, 'Photo / PDF',
                const Color(0xFF6A3027), _pickFiles),
            SizedBox(width: 10.w),
            _attachBtn(Icons.camera_alt_outlined, 'Camera',
                const Color(0xFFB54A3A), _pickCamera),
          ],
        ),
        if (_attachments.isNotEmpty) ...[
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _attachments.asMap().entries.map((e) {
              final i = e.key;
              final a = e.value;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 72.w,
                    height: 72.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: const Color(0xFFE0D5D0)),
                    ),
                    child: a['type'] == 'image'
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(9.r),
                            child: Image.file(
                              File(a['path'] as String),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.broken_image_outlined,
                                  color: Color(0xFF8B7D77)),
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.picture_as_pdf_rounded,
                                  color: Colors.red.shade400, size: 28.sp),
                              SizedBox(height: 4.h),
                              Padding(
                                padding:
                                    EdgeInsets.symmetric(horizontal: 4.w),
                                child: Text(a['name'] as String,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                        fontSize: 9.sp,
                                        color: const Color(0xFF241917))),
                              ),
                            ],
                          ),
                  ),
                  Positioned(
                    top: -6.h,
                    right: -6.w,
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _attachments.removeAt(i)),
                      child: Container(
                        width: 18.w,
                        height: 18.w,
                        decoration: const BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle),
                        child: Icon(Icons.close,
                            size: 11.sp, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _attachBtn(
          IconData icon, String label, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
          decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16.sp, color: color),
              SizedBox(width: 6.w),
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ],
          ),
        ),
      );

  Widget _label(String t) => Text(t,
      style: GoogleFonts.manrope(
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF241917)));

  Widget _field(TextEditingController ctrl, String hint,
          {int maxLines = 1}) =>
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: GoogleFonts.inter(
            fontSize: 14.sp, color: const Color(0xFF241917)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
              fontSize: 13.sp, color: const Color(0xFF8B7D77)),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFFE0D5D0))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFFE0D5D0))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide:
                  const BorderSide(color: Color(0xFFB54A3A), width: 1.5)),
        ),
      );

  Widget _datePicker({
    required TextEditingController ctrl,
    required Function(DateTime) onPicked,
    DateTime? selected,
    String hint = 'Select date',
  }) =>
      GestureDetector(
        onTap: () async {
          final p = await showDatePicker(
            context: context,
            initialDate: selected ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2101),
            builder: (ctx, child) => Theme(
              data: Theme.of(ctx).copyWith(
                  colorScheme: const ColorScheme.light(
                      primary: Color(0xFFB54A3A))),
              child: child!,
            ),
          );
          if (p != null) onPicked(p);
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFE0D5D0)),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 17.sp, color: const Color(0xFF6A3027)),
              SizedBox(width: 10.w),
              Text(
                ctrl.text.isEmpty ? hint : ctrl.text,
                style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: ctrl.text.isEmpty
                        ? const Color(0xFF8B7D77)
                        : const Color(0xFF241917)),
              ),
            ],
          ),
        ),
      );

  Widget _chips(
    List<String> opts,
    String selected,
    ValueChanged<String> onSel, {
    Map<String, Color>? colors,
  }) =>
      Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: opts.map((o) {
          final sel = selected == o;
          final color = colors?[o] ?? const Color(0xFFB54A3A);
          return GestureDetector(
            onTap: () => onSel(o),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 9.h),
              decoration: BoxDecoration(
                color: sel ? color.withOpacity(0.12) : Colors.white,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                    color: sel ? color : const Color(0xFFE0D5D0)),
              ),
              child: Text(o,
                  style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: sel ? color : const Color(0xFF241917))),
            ),
          );
        }).toList(),
      );

  void _submit() {
    if (_title.text.trim().isEmpty || _selectedEmployeeIds.isEmpty) {
      Get.snackbar('Missing Info',
          'Title and at least one employee are required',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (_isEdit) {
      // Use Data.uniqueId as the taskId for the update call
      widget.c.updateTask(widget.existing!.uniqueId, {
        'title': _title.text.trim(),
        'description': _desc.text.trim(),
        'start_date': _startDate.text,
        'due_date': _dueDate.text,
        'priority': _priority,
        'recurrence': _recurrence,
        'team_lead_ids': _selectedEmployeeIds.join(','),
        'junior_id': _selectedJuniorId,
        'project_id': _projectId,
        'project_name': _projectName,
      });
    } else {
      widget.c.assignTask(
        teamLeadId: _selectedEmployeeIds,
        juniorId: _selectedJuniorId,
        title: _title.text.trim(),
        description: _desc.text.trim(),
        startDate: _startDate.text,
        dueDate: _dueDate.text,
        priority: _priority,
        recurrence: _recurrence,
        projectId: _projectId,
        projectName: _projectName,
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────
// PROJECT CARD  (PM → Projects tab) — unchanged, uses ProjectModel
// ─────────────────────────────────────────────────────────────────────────

class _ProjectCard extends StatefulWidget {
  final ProjectModel project;
  const _ProjectCard({required this.project});

  @override
  State<_AssignTaskSheet> createState() => _AssignTaskSheetState();
}

class _AssignTaskSheetState extends State<_AssignTaskSheet> {
  final _c = Get.find<TaskController>();
  final _titleCtrl = TextEditingController();
  final _empNameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _deliveryCtrl = TextEditingController();
  final _endDeliveryCtrl = TextEditingController();
  String _priority = 'High';
  final String _recurrence = 'Daily';
  int? _selectedEmpId;
  String? _selectedEmpName;

  bool get _hasFixedEmployee => widget.initialEmployeeId != null;

  static const _priorities = ['High', 'Medium', 'Low'];

  @override
  void initState() {
    super.initState();
    _localStatus = widget.project.projectStatus;
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _rotate = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _empNameCtrl.dispose();
    _descCtrl.dispose();
    _deliveryCtrl.dispose();
    _endDeliveryCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: const ColorScheme.light(primary: _kBrand)),
        child: child!,
      ),
    );
    if (picked != null) {
      ctrl.text = _fmtDate(
        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}',
      );
    }
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      Get.snackbar(
        'Missing',
        'Task title is required',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
  }

  void _setStatus(String label) {
    final ns = _toggleMap[label]!;
    if (_localStatus == ns) return;
    setState(() => _localStatus = ns);
    if (!Get.isRegistered<ProjectController>()) Get.put(ProjectController());
    Get.find<ProjectController>()
        .updateProjectStatus(widget.project.projectId.toString(), ns);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 4))
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetHeader(
              icon: Icons.add_task_rounded,
              title: 'Assign Task',
              subtitle: widget.projectName,
            ),
            SizedBox(height: 20.h),
            _sheetLabel('Task Title *'),
            TextField(
              controller: _titleCtrl,
              style: GoogleFonts.inter(fontSize: 14.sp, color: _kTextPrimary),
              decoration: _sheetFieldDecoration(
                'Enter task title',
                prefixIcon: Icons.title_rounded,
              ),
            ),
            SizedBox(height: 14.h),
            _sheetLabel('Employee *'),
            if (_hasFixedEmployee)
              TextField(
                controller: _empNameCtrl,
                readOnly: true,
                style: GoogleFonts.inter(fontSize: 14.sp, color: _kTextPrimary),
                decoration: _sheetFieldDecoration(
                  'Employee name',
                  prefixIcon: Icons.person_rounded,
                ),
              )
            else
              Obx(() {
                if (_c.isEmpLoading.value) {
                  return Container(
                    height: 48.h,
                    decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4.r)),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.projectName,
                            style: GoogleFonts.manrope(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF241917))),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Icon(Icons.person_outline_rounded,
                                size: 12.sp, color: const Color(0xFF8B7D77)),
                            SizedBox(width: 4.w),
                            Text(p.clientName,
                                style: GoogleFonts.inter(
                                    fontSize: 11.sp,
                                    color: const Color(0xFF8B7D77))),
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20.r)),
                              child: Text(_localStatus,
                                  style: GoogleFonts.inter(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w700,
                                      color: color)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  RotationTransition(
                    turns: _rotate,
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        size: 22.sp, color: const Color(0xFF6A3027)),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _ProjectExpandedBody(
              project: p,
              localStatus: _localStatus,
              onStatusChange: _setStatus,
              reverseMap: _reverseMap,
              statusColor: _statusColor,
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }
}

// ── Update Progress Bottom Sheet ────────────────────────────────────────────

class _Assignprojecttotl extends StatefulWidget {
  final int projectId;
  final String projectName;
  const _Assignprojecttotl({
    required this.projectId,
    required this.projectName,
  });

  @override
  State<_Assignprojecttotl> createState() => _AssignprojecttotlState();
}

class _AssignprojecttotlState extends State<_Assignprojecttotl> {
  final _c = Get.find<TaskController>();
  int? _selectedEmpId;

  @override
  void initState() {
    super.initState();
    _c.fetchProjectManagerTeamList();
  }

  Future<void> _submit() async {
    if (_selectedEmpId == null) {
      Get.snackbar(
        'Missing',
        'Please select a team leader',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final ok = await _c.assignProjectToTeamLead(
      sProjectId: widget.projectId,
      employeeId: _selectedEmpId!,
    );
    if (ok) {
      Get.back();
      Get.snackbar(
        'Success',
        'Project assigned to team leader',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: _kSuccess,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Divider(
            color: const Color(0xFFF0E8E4),
            height: 1,
            indent: 14.w,
            endIndent: 14.w),
        Padding(
          padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 14.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row(Icons.person_outline_rounded, 'Client', project.clientName),
              SizedBox(height: 8.h),
              _row(Icons.folder_outlined, 'Project', project.projectName),
              SizedBox(height: 8.h),
              if (project.assignedTo.isNotEmpty) ...[
                _row(Icons.assignment_ind_outlined, 'Assigned To',
                    project.assignedTo),
                SizedBox(height: 8.h),
              ],
              _row(Icons.info_outline_rounded, 'Status', localStatus),
              if (project.description != null &&
                  project.description!.isNotEmpty) ...[
                SizedBox(height: 8.h),
                _row(Icons.description_outlined, 'Description',
                    project.description!),
              ],
              SizedBox(height: 14.h),
              Obx(() {
                final pc = _pc;
                final taskWorks = pc
                    .taskWorksByProject(project.projectId.toString());
                if (pc.isTaskWorksLoading.value) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(
                          color: Color(0xFF6A3027), strokeWidth: 2),
                    ),
                  );
                }
                if (taskWorks.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.work_outline_rounded,
                            size: 13.sp, color: const Color(0xFF6A3027)),
                        SizedBox(width: 6.w),
                        Text('Allocated Work (${taskWorks.length})',
                            style: GoogleFonts.manrope(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF241917))),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    ...taskWorks.map((tw) => _TaskWorkTile(taskWork: tw)),
                  ],
                );
              }),
              SizedBox(height: 14.h),
              Text('Change Status',
                  style: GoogleFonts.manrope(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF8B7D77))),
              SizedBox(height: 8.h),
              Row(
                children: [
                  _chip('Active', Colors.green),
                  SizedBox(width: 8.w),
                  _chip('Inactive', Colors.orange),
                  SizedBox(width: 8.w),
                  _chip('Done', Colors.blue),
                ],
              ),
              SizedBox(height: 14.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.find<TaskController>().switchTab(0);
                    Get.bottomSheet(
                      _TaskForm(
                        c: Get.find<TaskController>(),
                        preselectedProjectId:
                            project.projectId.toString(),
                        preselectedProjectName: project.projectName,
                      ),
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                    );
                  },
                  icon: Icon(Icons.add_task_rounded,
                      size: 16.sp, color: Colors.white),
                  label: Text(
                    localStatus == 'On Hold'
                        ? 'Reassign Task'
                        : 'Assign Task',
                    style: GoogleFonts.manrope(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
              );
            }),
            SizedBox(height: 24.h),
            Obx(
              () => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _c.isAssigningToTl.value ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: localStatus == 'On Hold'
                        ? Colors.orange
                        : const Color(0xFFB54A3A),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r)),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: _c.isAssigningToTl.value
                      ? SizedBox(
                          height: 20.h,
                          width: 20.h,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Assign Project',
                          style: GoogleFonts.manrope(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Update Progress Bottom Sheet ────────────────────────────────────────────

class _StatusOption {
  final String label;
  final IconData icon;
  final Color color;
  const _StatusOption(this.label, this.icon, this.color);
}

class _StatusCard extends StatelessWidget {
  final _StatusOption option;
  final bool selected;
  final VoidCallback onTap;
  const _StatusCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 6.w),
        decoration: BoxDecoration(
          color: selected ? option.color.withValues(alpha: 0.12) : _kSurface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
              color: selected ? color : const Color(0xFFE0D5D0),
              width: selected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7.w,
              height: 7.w,
              decoration: BoxDecoration(
                  color: selected ? color : color.withOpacity(0.4),
                  shape: BoxShape.circle),
            ),
            SizedBox(width: 5.w),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: selected ? color : const Color(0xFF8B7D77))),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14.sp, color: const Color(0xFF6A3027)),
          SizedBox(width: 8.w),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: GoogleFonts.manrope(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF8B7D77)),
                  ),
                  TextSpan(
                    text: value,
                    style: GoogleFonts.inter(
                        fontSize: 12.sp, color: const Color(0xFF241917)),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
}

class _UpdateProgressSheet extends StatefulWidget {
  final int proAllocatId;
  final String taskTitle;
  final String? currentProgress;
  final int? notifyEmployeeId;
  final String? notifyEmployeeName;
  const _UpdateProgressSheet({
    required this.proAllocatId,
    required this.taskTitle,
    this.currentProgress,
    this.notifyEmployeeId,
    this.notifyEmployeeName,
  });

  @override
  State<_UpdateProgressSheet> createState() => _UpdateProgressSheetState();
}

class _UpdateProgressSheetState extends State<_UpdateProgressSheet> {
  final _c = Get.find<TaskController>();
  final _descCtrl = TextEditingController();
  final _progressCtrl = TextEditingController();
  String? _selectedStatus;

  static const _statusOptions = [
    _StatusOption('Pending', Icons.hourglass_empty_rounded, _kDanger),
    _StatusOption('Running', Icons.autorenew_rounded, _kWarning),
    _StatusOption('Completed', Icons.check_circle_rounded, _kSuccess),
  ];

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _rotate = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_descCtrl.text.trim().isEmpty) {
      Get.snackbar(
        'Missing',
        'Description is required',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final progress = int.tryParse(_progressCtrl.text.trim());
    if (progress == null || progress < 0 || progress > 100) {
      Get.snackbar(
        'Missing',
        'Enter a valid progress (0-100)',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (_selectedStatus == null) {
      Get.snackbar(
        'Missing',
        'Please select a status',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final ok = await _c.updateProgress(
      proAllocatId: widget.proAllocatId,
      empDescription: _descCtrl.text.trim(),
      progress: progress,
      status: _selectedStatus!,
      taskTitle: widget.taskTitle,
      notifyEmployeeId: widget.notifyEmployeeId,
      notifyEmployeeName: widget.notifyEmployeeName,
    );
    if (ok) {
      Get.back();
      Get.snackbar(
        'Success',
        'Progress updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: _kSuccess,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(18.r),
              bottom: Radius.circular(_expanded ? 0 : 18.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(14.w),
              child: Row(
                children: [
                  Container(
                    width: 4.w,
                    height: 44.h,
                    decoration: BoxDecoration(
                        color: _statusColor,
                        borderRadius: BorderRadius.circular(4.r)),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.data
                                      ?.firstWhereOrNull(
                                          (d) => d.projectName != null)
                                      ?.projectName
                                      ?.isNotEmpty ==
                                  true
                              ? p.data!
                                  .firstWhere((d) => d.projectName != null)
                                  .projectName!
                              : 'Unnamed Project',
                          style: GoogleFonts.manrope(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF241917)),
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Icon(Icons.person_outline_rounded,
                                size: 12.sp, color: const Color(0xFF8B7D77)),
                            SizedBox(width: 4.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                  color: _statusColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20.r)),
                              child: Text(
                                (p.data
                                                ?.firstWhereOrNull(
                                                    (d) => d.aStatus != null)
                                                ?.aStatus
                                                ?.isEmpty ==
                                            true
                                        ? null
                                        : p.data
                                            ?.firstWhereOrNull(
                                                (d) => d.aStatus != null)
                                            ?.aStatus) ??
                                    'Pending',
                                style: GoogleFonts.inter(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                    color: _statusColor),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  RotationTransition(
                    turns: _rotate,
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        size: 22.sp, color: const Color(0xFF6A3027)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// TL ALLOCATE PROJECT CARD  (MobProjectAllocateTL item)
// ─────────────────────────────────────────────────────────────────────────

class _TLAllocateProjectCard extends StatelessWidget {
  final TLAllocateProject project;
  const _TLAllocateProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    final dateLabel = project.assignDate != null
        ? fmt.format(project.assignDate!)
        : '—';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4.w,
              height: 56.h,
              decoration: BoxDecoration(
                  color: const Color(0xFF6A3027),
                  borderRadius: BorderRadius.circular(4.r)),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.projectName.isNotEmpty
                        ? project.projectName
                        : 'Unnamed Project',
                    style: GoogleFonts.manrope(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF241917)),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded,
                          size: 12.sp, color: const Color(0xFF8B7D77)),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          project.employeeName.isNotEmpty
                              ? project.employeeName
                              : '—',
                          style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: const Color(0xFF241917)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(Icons.assignment_ind_outlined,
                          size: 12.sp, color: const Color(0xFF8B7D77)),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          project.assignBy.isNotEmpty
                              ? 'By ${project.assignBy}'
                              : '—',
                          style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: const Color(0xFF8B7D77)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.calendar_today_outlined,
                          size: 11.sp, color: const Color(0xFF8B7D77)),
                      SizedBox(width: 3.w),
                      Text(
                        dateLabel,
                        style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: const Color(0xFF8B7D77)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Update Project Status Bottom Sheet (PM) ─────────────────────────────────

class _UpdateStatusSheet extends StatefulWidget {
  final int projectId;
  final String projectName;
  final String? currentStatus;
  const _UpdateStatusSheet({
    required this.projectId,
    required this.projectName,
    this.currentStatus,
  });

  @override
  State<_UpdateStatusSheet> createState() => _UpdateStatusSheetState();
}

class _UpdateStatusSheetState extends State<_UpdateStatusSheet> {
  final _c = Get.find<TaskController>();
  String? _selectedStatus;

  static const _statusOptions = [
    _StatusOption('Pending', Icons.hourglass_empty_rounded, _kDanger),
    _StatusOption('In Progress', Icons.autorenew_rounded, _kWarning),
    _StatusOption('On-Hold', Icons.autorenew_rounded, _kWarning),
    _StatusOption('Completed', Icons.check_circle_rounded, _kSuccess),
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
  }

  Future<void> _submit() async {
    if (_selectedStatus == null) {
      Get.snackbar(
        'Missing',
        'Please select a status',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final ok = await _c.updateProjectStatus(
      sProjectId: widget.projectId,
      status: _selectedStatus!,
    );
    if (ok) {
      Get.back();
      Get.snackbar(
        'Success',
        'Status updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: _kSuccess,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F1ED),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
            color: taskWork.isOverdue
                ? Colors.red.shade200
                : const Color(0xFFE0D5D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  taskWork.taskTittle?.isNotEmpty == true
                      ? taskWork.taskTittle!
                      : taskWork.proDescription ?? 'No title',
                  style: GoogleFonts.manrope(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF241917)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20.r)),
                child: Text(taskWork.aStatus,
                    style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: _statusColor)),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              Icon(Icons.people_outline_rounded,
                  size: 12.sp, color: const Color(0xFF6A3027)),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  [
                    if (taskWork.employeeName.isNotEmpty)
                      taskWork.employeeName,
                    if (taskWork.employeeName1.isNotEmpty)
                      taskWork.employeeName1,
                  ].join(' → '),
                  style: GoogleFonts.inter(
                      fontSize: 11.sp, color: const Color(0xFF241917)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 11.sp, color: const Color(0xFF8B7D77)),
              SizedBox(width: 4.w),
              Text('Due: $dueLabel',
                  style: GoogleFonts.inter(
                      fontSize: 11.sp, color: const Color(0xFF8B7D77))),
              if (taskWork.isOverdue) ...[
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8.r)),
                  child: Text('Overdue',
                      style: GoogleFonts.inter(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.red)),
                ),
              ],
              if (taskWork.priority != null) ...[
                const Spacer(),
                Text(
                  taskWork.priority!,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: taskWork.priority == 'High'
                        ? Colors.red
                        : taskWork.priority == 'Low'
                            ? Colors.green
                            : Colors.orange,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
