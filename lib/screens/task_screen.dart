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

class TaskScreen extends GetView<TaskController> {
  const TaskScreen({super.key});

  bool get _isProjectManager {
    final box = GetStorage();
    final designation =
        (box.read('Designation') ?? box.read('designation') ?? '')
            .toString()
            .trim()
            .toLowerCase();
    return designation == 'project manager';
  }

  @override
  Widget build(BuildContext context) {
    final isPM = _isProjectManager;

    final tabs = <Tab>[
      const Tab(text: 'My Projects'),
      const Tab(text: 'Given'),
      if (!isPM) const Tab(text: 'Received'),
    ];

    final tabViews = <Widget>[
      _MyProjectsTab(),
      _GivenProjectsTab(),
      if (!isPM) _ReceivedProjectsTab(),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F1ED),
        appBar: AppBar(
          backgroundColor: const Color(0xFF6A3027),
          elevation: 0,
          title: Text(
            'Task Management',
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.manrope(
                fontSize: 13.sp, fontWeight: FontWeight.w700),
            unselectedLabelStyle:
                GoogleFonts.manrope(fontSize: 13.sp, fontWeight: FontWeight.w500),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: tabs,
          ),
        ),
        body: TabBarView(
          children: tabViews,
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
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF6A3027)),
        );
      }
      if (controller.errorMessage.value.isNotEmpty) {
        return _ErrorView(
          message: controller.errorMessage.value,
          onRetry: controller.fetchProjects,
        );
      }
      if (controller.projects.isEmpty) {
        return _EmptyView(message: 'No projects assigned');
      }
      return RefreshIndicator(
        color: const Color(0xFF6A3027),
        onRefresh: controller.fetchProjects,
        child: ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          itemCount: controller.projects.length,
          itemBuilder: (_, i) =>
              _ProjectCard(project: controller.projects[i]),
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
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF6A3027)),
        );
      }
      if (controller.taskWorksError.value.isNotEmpty) {
        return _ErrorView(
          message: controller.taskWorksError.value,
          onRetry: controller.fetchTaskWorks,
        );
      }
      if (controller.taskWorks.isEmpty) {
        return _EmptyView(message: 'No given projects found');
      }
      return RefreshIndicator(
        color: const Color(0xFF6A3027),
        onRefresh: controller.fetchTaskWorks,
        child: ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          itemCount: controller.taskWorks.length,
          itemBuilder: (_, i) =>
              _TaskWorkCard(task: controller.taskWorks[i]),
        ),
      );
    });
  }
}

// ── Tab 3: Received Projects ──────────────────────────────────────────────────

class _ReceivedProjectsTab extends GetView<TaskController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isReceivedLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF6A3027)),
        );
      }
      if (controller.receivedError.value.isNotEmpty) {
        return _ErrorView(
          message: controller.receivedError.value,
          onRetry: controller.fetchReceivedWorks,
        );
      }
      if (controller.receivedWorks.isEmpty) {
        return _EmptyView(message: 'No received projects found');
      }
      return RefreshIndicator(
        color: const Color(0xFF6A3027),
        onRefresh: controller.fetchReceivedWorks,
        child: ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          itemCount: controller.receivedWorks.length,
          itemBuilder: (_, i) =>
              _ReceivedCard(item: controller.receivedWorks[i]),
        ),
      );
    });
  }
}

// ── Received Card ─────────────────────────────────────────────────────────────

class _ReceivedCard extends StatelessWidget {
  final received.RData item;
  const _ReceivedCard({required this.item});

  Color get _statusColor {
    switch ((item.aStatus ?? '').toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'active':
      case 'running':
        return const Color(0xFF4CAF50);
      case 'done':
      case 'complete':
        return Colors.blue;
      default:
        return const Color(0xFF8B7D77);
    }
  }

  String _fmtDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    return raw.split('T').first;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A3027).withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.taskTittle ?? item.projectName ?? 'Untitled',
                    style: GoogleFonts.manrope(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF241917),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                _StatusBadge(label: item.aStatus ?? '', color: _statusColor),
              ],
            ),
          
            if ((item.proDescription ?? '').isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text(
                item.proDescription!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                    fontSize: 12.sp, color: const Color(0xFF6B5C58)),
              ),
            ],
            SizedBox(height: 10.h),
            Row(
              children: [
                if ((item.allocateDate ?? '').isNotEmpty)
                  _DateChip(Icons.calendar_today_rounded,
                      _fmtDate(item.allocateDate)),
                if ((item.allocateDate ?? '').isNotEmpty &&
                    (item.deliveryEstimateDate ?? '').isNotEmpty)
                  SizedBox(width: 8.w),
                if ((item.deliveryEstimateDate ?? '').isNotEmpty)
                  _DateChip(Icons.flag_rounded,
                      _fmtDate(item.endDeliveryEstimateDate),
                      color: const Color(0xFFB54A3A)),
              ],
            ),
            if ((item.employeeName ?? '').isNotEmpty) ...[
              SizedBox(height: 8.h),
              _IconRow(Icons.person_outline_rounded, item.employeeName!),
            ],
            if ((item.priority ?? '').isNotEmpty) ...[
              SizedBox(height: 6.h),
              _IconRow(
                  Icons.flag_circle_outlined, 'Priority: ${item.priority}'),
            ],
          ],
        ),
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
      _AssignTaskSheet(project: project),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Color get _statusColor {
    switch (project.projectStatus.toLowerCase()) {
      case 'active':
      case 'running':
        return const Color(0xFF4CAF50);
      case 'on hold':
      case 'inactive':
        return Colors.orange;
      case 'complete':
      case 'done':
        return Colors.blue;
      default:
        return const Color(0xFF8B7D77);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A3027).withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    project.projectName,
                    style: GoogleFonts.manrope(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF241917),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                _StatusBadge(label: project.projectStatus, color: _statusColor),
              ],
            ),
            if (project.clientName.isNotEmpty) ...[
              SizedBox(height: 6.h),
              _IconRow(Icons.business_rounded, project.clientName),
            ],
            if (project.description.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text(
                project.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                    fontSize: 12.sp, color: const Color(0xFF6B5C58)),
              ),
            ],
            SizedBox(height: 12.h),
            Row(
              children: [
                if (project.assignDate.isNotEmpty)
                  _DateChip(Icons.calendar_today_rounded, project.assignDate),
                if (project.assignDate.isNotEmpty &&
                    project.deliveryDate.isNotEmpty)
                  SizedBox(width: 8.w),
                if (project.deliveryDate.isNotEmpty)
                  _DateChip(Icons.flag_rounded, project.deliveryDate,
                      color: const Color(0xFFB54A3A)),
              ],
            ),
            if (project.assignedTo.isNotEmpty) ...[
              SizedBox(height: 8.h),
              _IconRow(Icons.person_outline_rounded, project.assignedTo),
            ],
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showAssignSheet(context),
                icon: Icon(Icons.add_task_rounded, size: 16.sp),
                label: Text('Assign Task',
                    style: GoogleFonts.manrope(
                        fontSize: 13.sp, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A3027),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 11.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Given Project (Task Work) Card ────────────────────────────────────────────

class _TaskWorkCard extends StatelessWidget {
  final given.Data task;
  const _TaskWorkCard({required this.task});

  Color get _statusColor {
    switch ((task.aStatus ?? '').toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'active':
      case 'running':
        return const Color(0xFF4CAF50);
      case 'done':
      case 'complete':
        return Colors.blue;
      default:
        return const Color(0xFF8B7D77);
    }
  }

  String _fmtDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    return raw.split('T').first;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A3027).withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    task.projectName ?? task.taskTittle ?? 'Untitled',
                    style: GoogleFonts.manrope(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF241917),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                _StatusBadge(
                    label: task.aStatus ?? '', color: _statusColor),
              ],
            ),

            if ((task.proDescription ?? '').isNotEmpty) ...[
              SizedBox(height: 6.h),
              _IconRow(Icons.folder_rounded, task.proDescription!),
            ],

          

            SizedBox(height: 10.h),

            Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              children: [
                if ((task.allocateDate ?? '').isNotEmpty)
                  _LabeledDateChip(
                    label: 'Start',
                    icon: Icons.calendar_today_rounded,
                    date: _fmtDate(task.allocateDate),
                    labelColor: const Color(0xFF6A3027),
                  ),
                if ((task.deliveryEstimateDate ?? '').isNotEmpty)
                  _LabeledDateChip(
                    label: 'Delivery',
                    icon: Icons.flag_rounded,
                    date: _fmtDate(task.endDeliveryEstimateDate),
                    labelColor: const Color(0xFFB54A3A),
                  ),
              ],
            ),

            if ((task.employeeName ?? '').isNotEmpty) ...[
              SizedBox(height: 8.h),
              _IconRow(Icons.person_outline_rounded, task.employeeName!),
            ],

            if ((task.priority ?? '').isNotEmpty) ...[
              SizedBox(height: 6.h),
              _IconRow(Icons.flag_circle_outlined, 'Priority: ${task.priority}'),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: color)),
    );
  }
}

class _IconRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _IconRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13.sp, color: const Color(0xFF8B7D77)),
        SizedBox(width: 4.w),
        Expanded(
          child: Text(text,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                  fontSize: 12.sp, color: const Color(0xFF8B7D77))),
        ),
      ],
    );
  }
}

class _LabeledDateChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final String date;
  final Color labelColor;
  const _LabeledDateChip({
    required this.label,
    required this.icon,
    required this.date,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: labelColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: labelColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: labelColor,
            ),
          ),
          Icon(icon, size: 11.sp, color: labelColor),
          SizedBox(width: 3.w),
          Text(
            date,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _DateChip(this.icon, this.label,
      {this.color = const Color(0xFF8B7D77)});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12.sp, color: color),
        SizedBox(width: 3.w),
        Text(label,
            style: GoogleFonts.inter(fontSize: 11.sp, color: color)),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String message;
  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open_rounded,
              size: 56.sp, color: const Color(0xFFCBC0BA)),
          SizedBox(height: 12.h),
          Text(message,
              style: GoogleFonts.manrope(
                  fontSize: 15.sp, color: const Color(0xFF8B7D77))),
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
            Icon(Icons.error_outline_rounded,
                size: 48.sp, color: const Color(0xFFB54A3A)),
            SizedBox(height: 12.h),
            Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 14.sp, color: const Color(0xFF6A3027))),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A3027),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Assign Task Bottom Sheet ───────────────────────────────────────────────────

class _AssignTaskSheet extends StatefulWidget {
  final ProjectModel project;
  const _AssignTaskSheet({required this.project});

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
  String _recurrence = 'Daily';
  int? _selectedEmpId;
  String? _selectedEmpName;

  static const _priorities = ['High', 'Medium', 'Low'];
  static const _recurrences = ['Daily', 'Weekly', 'Monthly', 'None'];

  @override
  void initState() {
    super.initState();
    _titleCtrl.text = widget.project.projectName;
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
          colorScheme: const ColorScheme.light(primary: Color(0xFF6A3027)),
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
      sProjectId: widget.project.projectId,
      employeeId: _selectedEmpId!,
      taskTitle: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      deliveryDate: _deliveryCtrl.text.trim(),
      endDeliveryDate: _endDeliveryCtrl.text.trim(),
      priority: _priority,
      recurrence: _recurrence,
    );
    if (ok) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F1ED),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 16.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBC0BA),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text('Assign Task',
                style: GoogleFonts.manrope(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF241917))),
            SizedBox(height: 4.h),
            Text(widget.project.projectName,
                style: GoogleFonts.inter(
                    fontSize: 13.sp, color: const Color(0xFF8B7D77))),
            SizedBox(height: 20.h),

            _label('Task Title *'),
            _field(_titleCtrl, 'Enter task title'),
            SizedBox(height: 14.h),

            _label('Employee *'),
            Obx(() {
              if (_c.isEmpLoading.value) {
                return Container(
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: const Color(0xFFE0D5D0)),
                  ),
                  child: const Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Color(0xFF6A3027), strokeWidth: 2),
                    ),
                  ),
                );
              }
              if (_c.boundEmployees.isEmpty) {
                return Container(
                  height: 48.h,
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: const Color(0xFFE0D5D0)),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: const Color(0xFFE0D5D0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedEmpId,
                    isExpanded: true,
                    hint: Text('Select employee',
                        style: GoogleFonts.inter(
                            fontSize: 13.sp, color: const Color(0xFFCBC0BA))),
                    style: GoogleFonts.inter(
                        fontSize: 14.sp, color: const Color(0xFF241917)),
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

            _label('Description'),
            _field(_descCtrl, 'Enter task description', maxLines: 3),
            SizedBox(height: 14.h),

            _label('Priority'),
            _dropdown(_priorities, _priority,
                (v) => setState(() => _priority = v!)),
            SizedBox(height: 14.h),

          


            _label('End Delivery Date'),
            _dateField(_endDeliveryCtrl, 'YYYY-MM-DD'),
            SizedBox(height: 24.h),

            Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _c.isAssigning.value ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A3027),
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
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700)),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: EdgeInsets.only(bottom: 6.h),
        child: Text(text,
            style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6A3027))),
      );

  Widget _field(TextEditingController ctrl, String hint,
          {int maxLines = 1, TextInputType? keyboardType}) =>
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(
            fontSize: 14.sp, color: const Color(0xFF241917)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
              fontSize: 13.sp, color: const Color(0xFFCBC0BA)),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: Color(0xFFE0D5D0))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: Color(0xFFE0D5D0))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide:
                  const BorderSide(color: Color(0xFF6A3027), width: 1.5)),
        ),
      );

  Widget _dropdown(List<String> items, String value,
          void Function(String?) onChanged) =>
      Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: const Color(0xFFE0D5D0)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            style: GoogleFonts.inter(
                fontSize: 14.sp, color: const Color(0xFF241917)),
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      );

  Widget _dateField(TextEditingController ctrl, String hint) => TextField(
        controller: ctrl,
        readOnly: true,
        onTap: () => _pickDate(ctrl),
        style: GoogleFonts.inter(
            fontSize: 14.sp, color: const Color(0xFF241917)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
              fontSize: 13.sp, color: const Color(0xFFCBC0BA)),
          suffixIcon: const Icon(Icons.calendar_today_rounded,
              size: 18, color: Color(0xFF6A3027)),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: Color(0xFFE0D5D0))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: Color(0xFFE0D5D0))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide:
                  const BorderSide(color: Color(0xFF6A3027), width: 1.5)),
        ),
      );
}
