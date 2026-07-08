import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/task_controller.dart';
import '../models/project_model.dart';
import '../models/givenmodelpm.dart' as given;
import '../models/recevedmodel.dart' as received;
import '../models/empdropdownmode.dart' as empdrop;

// ── Palette ──────────────────────────────────────────────────────────────────

const _kBrand = Color(0xFF6A3027);
const _kBrandDark = Color(0xFF4A2019);
const _kBg = Color(0xFFF6F1ED);
const _kSurface = Colors.white;
const _kTextPrimary = Color(0xFF241917);
const _kTextSecondary = Color(0xFF6B5C58);
const _kTextMuted = Color(0xFF8B7D77);
const _kBorder = Color(0xFFE0D5D0);
const _kSuccess = Color(0xFF4CAF50);
const _kInfo = Color(0xFF3B82C4);
const _kWarning = Color(0xFFE0A03D);
const _kDanger = Color(0xFFC24B3F);

Color _statusColor(String? status) {
  switch ((status ?? '').trim().toLowerCase()) {
    case 'pending':
      return _kDanger;
    case 'active':
    case 'running':
    case 'in progress':
      return _kWarning;
    case 'done':
    case 'complete':
    case 'completed':
      return _kSuccess;
    case 'on hold':
    case 'inactive':
      return _kWarning;
    default:
      return _kTextMuted;
  }
}

Color _priorityColor(String? priority) {
  switch ((priority ?? '').trim().toLowerCase()) {
    case 'high':
      return _kDanger;
    case 'medium':
      return _kWarning;
    case 'low':
      return _kSuccess;
    default:
      return _kTextMuted;
  }
}

String _fmtDate(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  return raw.split('T').first;
}

String _initials(String? name) {
  final trimmed = (name ?? '').trim();
  if (trimmed.isEmpty) return '?';
  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}

// ── Task Screen ────────────────────────────────────────────────────────────

class TaskScreen extends GetView<TaskController> {
  const TaskScreen({super.key});

  // Normalized by stripping everything but letters so stray casing/spacing/
  // punctuation from the API ("Team Leader", "TeamLeader", "team_leader", ...)
  // still matches.
  String get _designation {
    final box = GetStorage();
    final raw =
        (box.read('Designation') ?? box.read('designation') ?? '').toString();
    return raw.toLowerCase().replaceAll(RegExp('[^a-z]'), '');
  }

  bool get _isProjectManager => _designation == 'projectmanager';
  bool get _isTeamLeader => _designation == 'teamleader';
  bool get _isDeveloper => _designation == 'developer';

  @override
  Widget build(BuildContext context) {
    final isPM = _isProjectManager;
    final isTL = _isTeamLeader;
    final isDev = _isDeveloper;

    final tabs = <Tab>[
      if (!isDev) const Tab(text: 'My Projects'),
      if (!isDev) const Tab(text: 'Given'),
      if (!isPM) const Tab(text: 'Received'),
    ];

    final tabViews = <Widget>[
      if (!isDev) _MyProjectsTab(),
      if (!isDev) _GivenProjectsTab(),
      if (!isPM)
        _ReceivedProjectsTab(canAssign: isTL, canUpdate: isTL || isDev),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: _kBg,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_kBrand, _kBrandDark],
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(28),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40.w,
                            height: 40.w,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Icon(Icons.task_alt_rounded,
                                color: Colors.white, size: 22.sp),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Task Management',
                                  style: GoogleFonts.manrope(
                                    color: Colors.white,
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  'Track and manage your work',
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 18.h),
                      Container(
                        height: 46.h,
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: TabBar(
                          indicator: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(11.r),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          splashBorderRadius: BorderRadius.circular(11.r),
                          labelColor: _kBrand,
                          unselectedLabelColor: Colors.white,
                          labelStyle: GoogleFonts.manrope(
                              fontSize: 12.5.sp, fontWeight: FontWeight.w700),
                          unselectedLabelStyle: GoogleFonts.manrope(
                              fontSize: 12.5.sp, fontWeight: FontWeight.w600),
                          tabs: tabs,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          body: TabBarView(children: tabViews),
        ),
      ),
    );
  }
}

// ── Tab 1: My Projects ────────────────────────────────────────────────────────

class _MyProjectsTab extends GetView<TaskController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const _LoadingView();
      }
      if (controller.errorMessage.value.isNotEmpty) {
        return _ErrorView(
          message: controller.errorMessage.value,
          onRetry: controller.fetchProjects,
        );
      }
      if (controller.projects.isEmpty) {
        return const _EmptyView(
          icon: Icons.folder_open_rounded,
          message: 'No projects assigned',
        );
      }
      return RefreshIndicator(
        color: _kBrand,
        onRefresh: controller.fetchProjects,
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          itemCount: controller.projects.length,
          itemBuilder: (_, i) => _ProjectCard(project: controller.projects[i]),
        ),
      );
    });
  }
}

// ── Tab 2: Given Projects ─────────────────────────────────────────────────────

class _GivenProjectsTab extends GetView<TaskController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isTaskWorksLoading.value) {
        return const _LoadingView();
      }
      if (controller.taskWorksError.value.isNotEmpty) {
        return _ErrorView(
          message: controller.taskWorksError.value,
          onRetry: controller.fetchTaskWorks,
        );
      }
      if (controller.taskWorks.isEmpty) {
        return const _EmptyView(
          icon: Icons.send_rounded,
          message: 'No given projects found',
        );
      }
      return RefreshIndicator(
        color: _kBrand,
        onRefresh: controller.fetchTaskWorks,
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          itemCount: controller.taskWorks.length,
          itemBuilder: (_, i) => _TaskWorkCard(task: controller.taskWorks[i]),
        ),
      );
    });
  }
}

// ── Tab 3: Received Projects ──────────────────────────────────────────────────

class _ReceivedProjectsTab extends GetView<TaskController> {
  final bool canAssign;
  final bool canUpdate;
  const _ReceivedProjectsTab({this.canAssign = false, this.canUpdate = false});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isReceivedLoading.value) {
        return const _LoadingView();
      }
      if (controller.receivedError.value.isNotEmpty) {
        return _ErrorView(
          message: controller.receivedError.value,
          onRetry: controller.fetchReceivedWorks,
        );
      }
      if (controller.receivedWorks.isEmpty) {
        return const _EmptyView(
          icon: Icons.inbox_rounded,
          message: 'No received projects found',
        );
      }
      return RefreshIndicator(
        color: _kBrand,
        onRefresh: controller.fetchReceivedWorks,
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          itemCount: controller.receivedWorks.length,
          itemBuilder: (_, i) => _ReceivedCard(
              item: controller.receivedWorks[i],
              canAssign: canAssign,
              canUpdate: canUpdate),
        ),
      );
    });
  }
}

// ── Shared card shell ──────────────────────────────────────────────────────

class _CardShell extends StatelessWidget {
  final Color accentColor;
  final Widget child;
  const _CardShell({required this.accentColor, required this.child});

  @override
  Widget build(BuildContext context) {
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
  const _CardTitleRow(
      {required this.title, required this.status, required this.statusColor});

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
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.w,
            height: 6.w,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 5.w),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w700,
                  color: color)),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_rounded, size: 11.sp, color: color),
          SizedBox(width: 4.w),
          Text(priority,
              style: GoogleFonts.inter(
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String? label;
  final String value;
  final bool highlight;
  const _MetaChip(
      {required this.icon,
      this.label,
      required this.value,
      this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final color = highlight ? _kDanger : _kTextMuted;
    final textColor = highlight ? _kDanger : _kTextSecondary;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: highlight ? _kDanger.withValues(alpha: 0.1) : _kBg,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
            color: highlight ? _kDanger.withValues(alpha: 0.35) : _kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.sp, color: color),
          SizedBox(width: 4.w),
          if (label != null) ...[
            Text('$label ',
                style: GoogleFonts.inter(
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w700,
                    color: textColor)),
          ],
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 10.5.sp,
                  fontWeight: highlight ? FontWeight.w700 : FontWeight.w400,
                  color: textColor)),
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
                  fontSize: 9.5.sp, fontWeight: FontWeight.w800, color: _kBrand),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(name,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: _kTextSecondary)),
        ),
      ],
    );
  }
}

class _CardActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool filled;
  const _CardActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 16.sp),
          label: Text(label,
              style: GoogleFonts.manrope(
                  fontSize: 13.sp, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kBrand,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: EdgeInsets.symmetric(vertical: 11.h),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r)),
          ),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16.sp, color: _kBrand),
        label: Text(label,
            style: GoogleFonts.manrope(
                fontSize: 13.sp, fontWeight: FontWeight.w700, color: _kBrand)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _kBrand),
          padding: EdgeInsets.symmetric(vertical: 11.h),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r)),
        ),
      ),
    );
  }
}

// ── Received Card ─────────────────────────────────────────────────────────────

class _ReceivedCard extends StatelessWidget {
  final received.RData item;
  final bool canAssign;
  final bool canUpdate;
  const _ReceivedCard(
      {required this.item, this.canAssign = false, this.canUpdate = false});

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
          _CardTitleRow(
            title: item.taskTittle ?? item.projectName ?? 'Untitled',
            status: status,
            statusColor: _statusColor(status),
          ),
          if ((item.proDescription ?? '').isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              item.proDescription!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 12.sp, color: _kTextSecondary),
            ),
          ],
          if ((item.allocateDate ?? '').isNotEmpty ||
              (item.deliveryEstimateDate ?? '').isNotEmpty) ...[
            SizedBox(height: 10.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              children: [
                if ((item.allocateDate ?? '').isNotEmpty)
                  _MetaChip(
                      icon: Icons.calendar_today_rounded,
                      label: 'Start',
                      value: _fmtDate(item.allocateDate)),
                if ((item.deliveryEstimateDate ?? '').isNotEmpty)
                  _MetaChip(
                      icon: Icons.flag_rounded,
                      label: 'Due',
                      value: _fmtDate(item.endDeliveryEstimateDate),
                      highlight: true),
              ],
            ),
          ],
          if (person.isNotEmpty || priority.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Row(
              children: [
                Expanded(child: _PersonRow(name: person)),
                if (priority.isNotEmpty) _PriorityPill(priority: priority),
              ],
            ),
          ],
          if (canAssign) ...[
            SizedBox(height: 12.h),
            _CardActionButton(
              label: 'Assign Task',
              icon: Icons.add_task_rounded,
              onPressed: () => _showAssignSheet(context),
            ),
          ],
          if (canUpdate) ...[
            SizedBox(height: canAssign ? 8.h : 12.h),
            _CardActionButton(
              label: 'Update',
              icon: Icons.update_rounded,
              filled: false,
              onPressed: () => _showUpdateSheet(context),
            ),
          ],
        ],
      ),
    );
  }
}

// ── My Project Card ───────────────────────────────────────────────────────────

class _ProjectCard extends StatelessWidget {
  final ProjectModel project;
  const _ProjectCard({required this.project});

  void _showAssignSheet(BuildContext context) {
    Get.bottomSheet(
      _AssignTaskSheet(
        projectId: project.projectId,
        projectName: project.projectName,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      accentColor: _statusColor(project.projectStatus),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitleRow(
            title: project.projectName,
            status: project.projectStatus,
            statusColor: _statusColor(project.projectStatus),
          ),
          if (project.clientName.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Icons.business_rounded, size: 13.sp, color: _kTextMuted),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(project.clientName,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 12.sp, color: _kTextMuted)),
                ),
              ],
            ),
          ],
          if (project.description.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              project.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 12.sp, color: _kTextSecondary),
            ),
          ],
          if (project.assignDate.isNotEmpty ||
              project.deliveryDate.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              children: [
                if (project.assignDate.isNotEmpty)
                  _MetaChip(
                      icon: Icons.calendar_today_rounded,
                      label: 'Start',
                      value: project.assignDate),
                if (project.deliveryDate.isNotEmpty)
                  _MetaChip(
                      icon: Icons.flag_rounded,
                      label: 'Due',
                      value: project.deliveryDate,
                      highlight: true),
              ],
            ),
          ],
          if (project.assignedTo.isNotEmpty) ...[
            SizedBox(height: 10.h),
            _PersonRow(name: project.assignedTo),
          ],
          SizedBox(height: 12.h),
          _CardActionButton(
            label: 'Assign Task',
            icon: Icons.add_task_rounded,
            onPressed: () => _showAssignSheet(context),
          ),
        ],
      ),
    );
  }
}

// ── Given Project (Task Work) Card ────────────────────────────────────────────

class _TaskWorkCard extends StatelessWidget {
  final given.Data task;
  const _TaskWorkCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final status = task.aStatus ?? '';
    final priority = task.priority ?? '';
    final person = task.employeeName ?? '';

    return _CardShell(
      accentColor: _statusColor(status),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitleRow(
            title: task.projectName ?? task.taskTittle ?? 'Untitled',
            status: status,
            statusColor: _statusColor(status),
          ),
          if ((task.proDescription ?? '').isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              task.proDescription!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 12.sp, color: _kTextSecondary),
            ),
          ],
          if ((task.allocateDate ?? '').isNotEmpty ||
              (task.deliveryEstimateDate ?? '').isNotEmpty) ...[
            SizedBox(height: 10.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              children: [
                if ((task.allocateDate ?? '').isNotEmpty)
                  _MetaChip(
                      icon: Icons.calendar_today_rounded,
                      label: 'Start',
                      value: _fmtDate(task.allocateDate)),
                if ((task.deliveryEstimateDate ?? '').isNotEmpty)
                  _MetaChip(
                      icon: Icons.flag_rounded,
                      label: 'Delivery',
                      value: _fmtDate(task.endDeliveryEstimateDate),
                      highlight: true),
              ],
            ),
          ],
          if (person.isNotEmpty || priority.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Row(
              children: [
                Expanded(child: _PersonRow(name: person)),
                if (priority.isNotEmpty) _PriorityPill(priority: priority),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Loading / Empty / Error states ──────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: _kBrand, strokeWidth: 2.5),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyView({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84.w,
            height: 84.w,
            decoration: BoxDecoration(
              color: _kBrand.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36.sp, color: _kBrand.withValues(alpha: 0.5)),
          ),
          SizedBox(height: 16.h),
          Text(message,
              style: GoogleFonts.manrope(
                  fontSize: 14.5.sp,
                  fontWeight: FontWeight.w600,
                  color: _kTextMuted)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76.w,
              height: 76.w,
              decoration: BoxDecoration(
                color: _kDanger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded,
                  size: 34.sp, color: _kDanger),
            ),
            SizedBox(height: 14.h),
            Text(message,
                textAlign: TextAlign.center,
                style:
                    GoogleFonts.inter(fontSize: 13.5.sp, color: _kTextSecondary)),
            SizedBox(height: 18.h),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBrand,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r)),
              ),
            ),
          ],
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
  const _SheetHeader(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: _kBorder,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
        ),
        SizedBox(height: 18.h),
        Row(
          children: [
            Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(
                color: _kBrand.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(11.r),
              ),
              child: Icon(icon, color: _kBrand, size: 19.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.manrope(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w800,
                          color: _kTextPrimary)),
                  SizedBox(height: 2.h),
                  Text(subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 12.5.sp, color: _kTextMuted)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

Widget _sheetLabel(String text) => Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Text(text,
          style: GoogleFonts.inter(
              fontSize: 12.sp, fontWeight: FontWeight.w600, color: _kBrand)),
    );

InputDecoration _sheetFieldDecoration(String hint, {IconData? prefixIcon}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFFCBC0BA)),
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, size: 18, color: _kTextMuted),
      filled: true,
      fillColor: _kSurface,
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: _kBorder)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: _kBorder)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: _kBrand, width: 1.5)),
    );

// ── Assign Task Bottom Sheet ───────────────────────────────────────────────────

class _AssignTaskSheet extends StatefulWidget {
  final int projectId;
  final String projectName;
  const _AssignTaskSheet({required this.projectId, required this.projectName});

  @override
  State<_AssignTaskSheet> createState() => _AssignTaskSheetState();
}

class _AssignTaskSheetState extends State<_AssignTaskSheet> {
  final _c = Get.find<TaskController>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _deliveryCtrl = TextEditingController();
  final _endDeliveryCtrl = TextEditingController();
  String _priority = 'High';
  final String _recurrence = 'Daily';
  int? _selectedEmpId;
  String? _selectedEmpName;

  static const _priorities = ['High', 'Medium', 'Low'];

  @override
  void initState() {
    super.initState();
    _titleCtrl.text = widget.projectName;
    _c.fetchBindEmployees();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
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
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _kBrand),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      ctrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      Get.snackbar('Missing', 'Task title is required',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (_selectedEmpId == null) {
      Get.snackbar('Missing', 'Please select an employee',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final ok = await _c.assignTask(
      sProjectId: widget.projectId,
      employeeId: _selectedEmpId!,
      taskTitle: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      deliveryDate: _deliveryCtrl.text.trim(),
      endDeliveryDate: _endDeliveryCtrl.text.trim(),
      priority: _priority,
      recurrence: _recurrence,
    );
    if (ok) {
      Get.back();
      Get.snackbar('Success', 'Task assigned successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: _kSuccess,
          colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 12.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
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
              decoration: _sheetFieldDecoration('Enter task title',
                  prefixIcon: Icons.title_rounded),
            ),
            SizedBox(height: 14.h),
            _sheetLabel('Employee *'),
            Obx(() {
              if (_c.isEmpLoading.value) {
                return Container(
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: _kBorder),
                  ),
                  child: const Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: _kBrand, strokeWidth: 2),
                    ),
                  ),
                );
              }
              if (_c.boundEmployees.isEmpty) {
                return Container(
                  height: 48.h,
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('No employees bound to this project',
                        style: GoogleFonts.inter(
                            fontSize: 13.sp, color: const Color(0xFFCBC0BA))),
                  ),
                );
              }
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: _kBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedEmpId,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: _kTextMuted),
                    hint: Text('Select employee',
                        style: GoogleFonts.inter(
                            fontSize: 13.sp, color: const Color(0xFFCBC0BA))),
                    style: GoogleFonts.inter(fontSize: 14.sp, color: _kTextPrimary),
                    items: _c.boundEmployees
                        .where((e) => e.employeeId != null)
                        .map((e) => DropdownMenuItem<int>(
                              value: e.employeeId,
                              child: Text(e.employeeName ?? 'ID ${e.employeeId}'),
                            ))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedEmpId = v;
                        _selectedEmpName = _c.boundEmployees
                            .firstWhere((e) => e.employeeId == v,
                                orElse: () => empdrop.Data())
                            .employeeName;
                      });
                    },
                  ),
                ),
              );
            }),
            SizedBox(height: 14.h),
            _sheetLabel('Description'),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              style: GoogleFonts.inter(fontSize: 14.sp, color: _kTextPrimary),
              decoration: _sheetFieldDecoration('Enter task description'),
            ),
            SizedBox(height: 14.h),
            _sheetLabel('Priority'),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: _kBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _priority,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: _kTextMuted),
                  style: GoogleFonts.inter(fontSize: 14.sp, color: _kTextPrimary),
                  items: _priorities
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _priority = v!),
                ),
              ),
            ),
            SizedBox(height: 14.h),
            _sheetLabel('End Delivery Date'),
            TextField(
              controller: _endDeliveryCtrl,
              readOnly: true,
              onTap: () => _pickDate(_endDeliveryCtrl),
              style: GoogleFonts.inter(fontSize: 14.sp, color: _kTextPrimary),
              decoration:
                  _sheetFieldDecoration('YYYY-MM-DD', prefixIcon: Icons.event_rounded),
            ),
            SizedBox(height: 24.h),
            Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _c.isAssigning.value ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kBrand,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r)),
                    ),
                    child: _c.isAssigning.value
                        ? SizedBox(
                            height: 20.h,
                            width: 20.h,
                            child: const CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text('Assign Task',
                            style: GoogleFonts.manrope(
                                fontSize: 15.sp, fontWeight: FontWeight.w700)),
                  ),
                )),
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
  const _StatusCard(
      {required this.option, required this.selected, required this.onTap});

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
            color: selected ? option.color : _kBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(option.icon, size: 20.sp, color: option.color),
            SizedBox(height: 5.h),
            Text(
              option.label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 10.5.sp,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? option.color : _kTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpdateProgressSheet extends StatefulWidget {
  final int proAllocatId;
  final String taskTitle;
  final String? currentProgress;
  const _UpdateProgressSheet({
    required this.proAllocatId,
    required this.taskTitle,
    this.currentProgress,
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
    _StatusOption('Pending', Icons.hourglass_empty_rounded, _kWarning),
    _StatusOption('In Progress', Icons.autorenew_rounded, _kSuccess),
    _StatusOption('Completed', Icons.check_circle_rounded, _kInfo),
  ];

  @override
  void initState() {
    super.initState();
    _progressCtrl.text = widget.currentProgress ?? '';
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_descCtrl.text.trim().isEmpty) {
      Get.snackbar('Missing', 'Description is required',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final progress = int.tryParse(_progressCtrl.text.trim());
    if (progress == null || progress < 0 || progress > 100) {
      Get.snackbar('Missing', 'Enter a valid progress (0-100)',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (_selectedStatus == null) {
      Get.snackbar('Missing', 'Please select a status',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final ok = await _c.updateProgress(
      proAllocatId: widget.proAllocatId,
      empDescription: _descCtrl.text.trim(),
      progress: progress,
      status: _selectedStatus!,
    );
    if (ok) {
      Get.back();
      Get.snackbar('Success', 'Progress updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: _kSuccess,
          colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 12.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetHeader(
              icon: Icons.update_rounded,
              title: 'Update Progress',
              subtitle: widget.taskTitle,
            ),
            SizedBox(height: 20.h),
            _sheetLabel('Description *'),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              style: GoogleFonts.inter(fontSize: 14.sp, color: _kTextPrimary),
              decoration: _sheetFieldDecoration('Enter progress description'),
            ),
            SizedBox(height: 14.h),
            _sheetLabel('Progress (%) *'),
            TextField(
              controller: _progressCtrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(fontSize: 14.sp, color: _kTextPrimary),
              decoration: _sheetFieldDecoration('0 - 100',
                  prefixIcon: Icons.percent_rounded),
            ),
            SizedBox(height: 14.h),
            _sheetLabel('Status *'),
            Row(
              children: _statusOptions
                  .map((opt) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: opt == _statusOptions.last ? 0 : 8.w),
                          child: _StatusCard(
                            option: opt,
                            selected: _selectedStatus == opt.label,
                            onTap: () =>
                                setState(() => _selectedStatus = opt.label),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            SizedBox(height: 24.h),
            Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _c.isUpdatingProgress.value ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kBrand,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r)),
                    ),
                    child: _c.isUpdatingProgress.value
                        ? SizedBox(
                            height: 20.h,
                            width: 20.h,
                            child: const CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text('Update',
                            style: GoogleFonts.manrope(
                                fontSize: 15.sp, fontWeight: FontWeight.w700)),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
