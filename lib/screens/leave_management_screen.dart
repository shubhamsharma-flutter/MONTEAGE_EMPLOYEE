import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../controllers/leave_list_controller.dart';
import '../controllers/leave_management_controller.dart';
import '../infrastructure/routes/admin_routes.dart';
import '../models/myleavemodel.dart';
import '../widgets/leave_ui.dart';

class LeaveManagementScreen extends GetView<LeaveManagementController> {
  const LeaveManagementScreen({super.key});

  void _openApplySheet(BuildContext context) {
    controller.resetForm();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: LeaveColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (_) => const _ApplyLeaveSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LeaveScaffold(
      title: 'My Leaves',
      subtitle: 'Your balance and requests',
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: LeaveColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Apply Leave'),
        onPressed: () => _openApplySheet(context),
      ),
      body: Obx(() {
        final leaves = controller.leaves.toList();
        final loading = controller.isLoading.value && leaves.isEmpty;
        final error = controller.errorMessage.value;

        return RefreshIndicator(
          color: LeaveColors.accent,
          onRefresh: controller.fetchMyLeaves,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            // Bottom space keeps the last card clear of the Apply button.
            padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 96.h),
            children: [
              if (!loading && error.isEmpty && leaves.isNotEmpty) ...[
                _BalanceSummary(leaves: leaves),
                SizedBox(height: 12.h),
              ],
              _QuickActions(showTeamLeave: controller.canViewTeamLeave),
              SizedBox(height: 20.h),
              if (loading)
                const LeaveLoadingCards(count: 3)
              else if (error.isNotEmpty)
                LeaveMessage(
                  icon: Icons.cloud_off_rounded,
                  title: 'Something went wrong',
                  text: error,
                  actionLabel: 'Try again',
                  onAction: controller.fetchMyLeaves,
                )
              else if (leaves.isEmpty)
                LeaveMessage(
                  icon: Icons.event_busy_rounded,
                  title: 'No leave balance found',
                  text: 'Your leave types will appear here once assigned.',
                  actionLabel: 'Refresh',
                  onAction: controller.fetchMyLeaves,
                )
              else ...[
                Text('Leave balance', style: LeaveText.heading(16)),
                SizedBox(height: 10.h),
                for (final leave in leaves) ...[
                  _BalanceCard(leave: leave),
                  SizedBox(height: 12.h),
                ],
              ],
            ],
          ),
        );
      }),
    );
  }
}

class _BalanceSummary extends StatelessWidget {
  final List<Data> leaves;

  const _BalanceSummary({required this.leaves});

  int _sum(int? Function(Data) field) =>
      leaves.fold(0, (sum, leave) => sum + (field(leave) ?? 0));

  Widget _stat(String label, int value) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$value', style: LeaveText.heading(18, color: Colors.white)),
        Text(label, style: LeaveText.body(11, color: Colors.white)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final types = leaves.length;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [LeaveColors.accent, LeaveColors.accentDark],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total balance',
                  style: LeaveText.body(
                    13,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                leaves.first.years ?? '',
                style: LeaveText.body(12, color: Colors.white),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            '${_sum((leave) => leave.totalBalanceLeave)}',
            style: LeaveText.heading(38, color: Colors.white),
          ),
          Text(
            'across $types leave ${types == 1 ? 'type' : 'types'}',
            style: LeaveText.body(12, color: Colors.white),
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              _stat('Taken', _sum((leave) => leave.totalTakenLeave)),
              _stat('Allotted', _sum((leave) => leave.totalLeave)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final bool showTeamLeave;

  const _QuickActions({required this.showTeamLeave});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            icon: Icons.history_rounded,
            title: 'My Requests',
            subtitle: 'Track status',
            onTap: () => Get.toNamed(AdminRoutes.leaveList),
          ),
        ),
        if (showTeamLeave) ...[
          SizedBox(width: 12.w),
          Expanded(
            child: _ActionTile(
              icon: Icons.groups_rounded,
              title: 'Team Leave',
              subtitle: 'Review requests',
              onTap: () => Get.toNamed(AdminRoutes.teamLeave),
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: leaveCardDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: LeaveColors.accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(icon, size: 20.sp, color: LeaveColors.accent),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: LeaveText.heading(13)),
                      Text(subtitle, style: LeaveText.body(11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final Data leave;

  const _BalanceCard({required this.leave});

  @override
  Widget build(BuildContext context) {
    final color = leaveTypeColor(leave.leaveType);
    final total = leave.totalLeave ?? 0;
    final taken = leave.totalTakenLeave ?? 0;
    final hasDates =
        parseLeaveDate(leave.fromDate) != null ||
        parseLeaveDate(leave.toDate) != null;
    final reason = (leave.leaveReason ?? '').trim();

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: leaveCardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  leaveTypeIcon(leave.leaveType),
                  size: 22.sp,
                  color: color,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (leave.leaveType ?? '-').trim(),
                      style: LeaveText.heading(14),
                    ),
                    Text('Taken $taken of $total', style: LeaveText.body(12)),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Column(
                children: [
                  Text(
                    '${leave.totalBalanceLeave ?? 0}',
                    style: LeaveText.heading(22, color: color),
                  ),
                  Text('left', style: LeaveText.body(11)),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: LinearProgressIndicator(
              value: total > 0 ? (taken / total).clamp(0.0, 1.0) : 0,
              minHeight: 6.h,
              color: color,
              backgroundColor: color.withValues(alpha: 0.12),
              semanticsLabel: '${leave.leaveType} used',
            ),
          ),
          if (hasDates) ...[
            SizedBox(height: 12.h),
            LeaveDetailRow(
              icon: Icons.date_range_rounded,
              text:
                  '${formatLeaveDate(leave.fromDate)} - '
                  '${formatLeaveDate(leave.toDate)} '
                  '(${leaveDayLabel(leave.leaveNoofday ?? 0)})',
            ),
          ],
          if (reason.isNotEmpty) ...[
            SizedBox(height: 6.h),
            LeaveDetailRow(icon: Icons.notes_rounded, text: reason),
          ],
        ],
      ),
    );
  }
}

class _ApplyLeaveSheet extends StatefulWidget {
  const _ApplyLeaveSheet();

  @override
  State<_ApplyLeaveSheet> createState() => _ApplyLeaveSheetState();
}

class _ApplyLeaveSheetState extends State<_ApplyLeaveSheet> {
  final LeaveManagementController _c = Get.find<LeaveManagementController>();
  final TextEditingController _reasonCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (_c.leaveTypes.isEmpty && !_c.isLoadingTypes.value) {
      _c.fetchLeaveTypes();
    }
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDate = isFrom ? today : (_c.fromDate.value ?? today);
    final current = isFrom ? _c.fromDate.value : _c.toDate.value;

    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? firstDate,
      firstDate: firstDate,
      lastDate: DateTime(2101),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: LeaveColors.accent),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;

    if (isFrom) {
      _c.setFromDate(picked);
    } else {
      _c.toDate.value = picked;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
    );
    if (image != null) _c.setPrescription(image.name, image.path);
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.isNotEmpty) {
      _c.setPrescription(
        result.files.first.name,
        result.files.first.path ?? '',
      );
    }
  }

  void _showAttachmentOptions() {
    Widget option(
      IconData icon,
      String label,
      String description,
      Future<void> Function() onTap,
    ) {
      return Builder(
        builder: (ctx) => ListTile(
          leading: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: LeaveColors.accent.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20.sp, color: LeaveColors.accent),
          ),
          title: Text(label, style: LeaveText.heading(14)),
          subtitle: Text(description, style: LeaveText.body(12)),
          onTap: () {
            Navigator.pop(ctx);
            onTap();
          },
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: LeaveColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            option(
              Icons.camera_alt_rounded,
              'Take a Photo',
              'Capture the prescription with your camera',
              () => _pickImage(ImageSource.camera),
            ),
            option(
              Icons.photo_library_rounded,
              'Choose from Gallery',
              'Select an existing image',
              () => _pickImage(ImageSource.gallery),
            ),
            option(
              Icons.picture_as_pdf_rounded,
              'Upload PDF',
              'Pick a PDF from your files',
              _pickPdf,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final reason = _reasonCtrl.text.trim();

    String? missingField;
    if (_c.selectedLeaveType.value == null) {
      missingField = 'Please select a leave type.';
    } else if (_c.fromDate.value == null) {
      missingField = 'Please select a from date.';
    } else if (_c.toDate.value == null) {
      missingField = 'Please select a to date.';
    } else if (reason.isEmpty) {
      missingField = 'Please enter a reason.';
    }

    if (missingField != null) {
      _c.showError(missingField);
      return;
    }

    if (_c.exceedsBalance) {
      _c.showError(
        'You only have ${_c.currentBalance} leave(s) remaining, '
        'but requested ${_c.numberOfDays} day(s).',
      );
      return;
    }

    final submitted = await _c.submitLeave(reason: reason);
    if (submitted && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14.r),
      borderSide: const BorderSide(color: LeaveColors.border),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
        child: Obx(() {
          final types = _c.leaveTypes.toList();
          final selectedId = _c.selectedLeaveType.value?.leaveTypeId;
          final loadingTypes = _c.isLoadingTypes.value;
          final balance = _c.currentBalance;
          final days = _c.numberOfDays;
          final submitting = _c.isSubmitting.value;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Apply Leave', style: LeaveText.heading(20)),
              Text(
                'Fill in the details to send your request',
                style: LeaveText.body(13),
              ),
              const _FieldLabel('Leave type'),
              if (types.isEmpty)
                loadingTypes
                    ? Text('Loading leave types...', style: LeaveText.body(13))
                    : Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Could not load leave types.',
                              style: LeaveText.body(13),
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: LeaveColors.accent,
                            ),
                            onPressed: _c.fetchLeaveTypes,
                            child: const Text('Retry'),
                          ),
                        ],
                      )
              else
                LayoutBuilder(
                  builder: (_, constraints) {
                    final width = (constraints.maxWidth - 10.w) / 2;
                    return Wrap(
                      spacing: 10.w,
                      runSpacing: 10.h,
                      children: [
                        for (final type in types)
                          SizedBox(
                            width: width,
                            child: _LeaveTypeOption(
                              type: type,
                              balance: _c.balanceFor(type.leaveTypeId),
                              selected: type.leaveTypeId == selectedId,
                              onTap: () => _c.selectLeaveType(type),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              const _FieldLabel('Dates'),
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'From',
                      date: _c.fromDate.value,
                      onTap: () => _pickDate(isFrom: true),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _DateField(
                      label: 'To',
                      date: _c.toDate.value,
                      onTap: () => _pickDate(isFrom: false),
                    ),
                  ),
                ],
              ),
              if (days > 0) ...[
                SizedBox(height: 10.h),
                _RequestSummary(
                  days: days,
                  balance: balance,
                  exceeds: _c.exceedsBalance,
                ),
              ],
              const _FieldLabel('Reason'),
              TextField(
                controller: _reasonCtrl,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                style: LeaveText.body(14, color: LeaveColors.ink),
                decoration: InputDecoration(
                  hintText: 'Why do you need this leave?',
                  hintStyle: LeaveText.body(13),
                  filled: true,
                  fillColor: LeaveColors.surface,
                  border: fieldBorder,
                  enabledBorder: fieldBorder,
                  focusedBorder: fieldBorder.copyWith(
                    borderSide: const BorderSide(
                      color: LeaveColors.accent,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              if (_c.needsPrescription) ...[
                const _FieldLabel('Prescription (optional)'),
                _AttachmentField(
                  fileName: _c.prescriptionFileName.value,
                  onTap: _showAttachmentOptions,
                  onRemove: () => _c.setPrescription('', ''),
                ),
              ],
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: LeaveColors.accent,
                    disabledBackgroundColor: LeaveColors.accent.withValues(
                      alpha: 0.6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  onPressed: submitting ? null : _submit,
                  child: submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Submit Request',
                          style: LeaveText.heading(15, color: Colors.white),
                        ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 18.h, bottom: 8.h),
      child: Text(
        text,
        style: LeaveText.body(
          13,
          weight: FontWeight.w700,
          color: LeaveColors.ink,
        ),
      ),
    );
  }
}

class _LeaveTypeOption extends StatelessWidget {
  final LeaveTypeModel type;
  final int? balance;
  final bool selected;
  final VoidCallback onTap;

  const _LeaveTypeOption({
    required this.type,
    required this.balance,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = leaveTypeColor(type.leaveType);

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.10)
                  : LeaveColors.surface,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: selected ? color : LeaveColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(leaveTypeIcon(type.leaveType), size: 20.sp, color: color),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.leaveType,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: LeaveText.body(
                          12,
                          weight: FontWeight.w700,
                          color: LeaveColors.ink,
                        ),
                      ),
                      if (balance != null)
                        Text('$balance left', style: LeaveText.body(11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final picked = date != null;

    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: onTap,
          child: Ink(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: LeaveColors.surface,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: picked ? LeaveColors.accent : LeaveColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 18.sp,
                  color: LeaveColors.accent,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: LeaveText.body(11)),
                      Text(
                        picked
                            ? DateFormat('dd MMM yyyy').format(date!)
                            : 'Select date',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LeaveText.body(
                          13,
                          weight: FontWeight.w700,
                          color: picked ? LeaveColors.ink : LeaveColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestSummary extends StatelessWidget {
  final int days;
  final int? balance;
  final bool exceeds;

  const _RequestSummary({
    required this.days,
    required this.balance,
    required this.exceeds,
  });

  @override
  Widget build(BuildContext context) {
    final color = exceeds ? LeaveColors.rejected : LeaveColors.approved;
    final String detail;
    if (balance == null) {
      detail = '';
    } else if (exceeds) {
      detail = ' · only $balance left';
    } else {
      detail = ' · ${balance! - days} left after this';
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(
            exceeds
                ? Icons.warning_amber_rounded
                : Icons.check_circle_outline_rounded,
            size: 18.sp,
            color: color,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              '${leaveDayLabel(days)} requested$detail',
              style: LeaveText.body(13, weight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentField extends StatelessWidget {
  final String fileName;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _AttachmentField({
    required this.fileName,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final attached = fileName.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: LeaveColors.surface,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: attached ? LeaveColors.accent : LeaveColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                attached
                    ? Icons.description_rounded
                    : Icons.upload_file_rounded,
                size: 22.sp,
                color: LeaveColors.accent,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  attached ? fileName : 'Add a photo or PDF',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LeaveText.body(
                    13,
                    weight: FontWeight.w600,
                    color: attached ? LeaveColors.ink : LeaveColors.muted,
                  ),
                ),
              ),
              if (attached)
                IconButton(
                  tooltip: 'Remove file',
                  icon: const Icon(Icons.close_rounded),
                  color: LeaveColors.muted,
                  onPressed: onRemove,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
