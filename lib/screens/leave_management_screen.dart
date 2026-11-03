import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../controllers/leave_management_controller.dart';
import '../infrastructure/routes/admin_routes.dart';
import '../models/myleavemodel.dart';
import '../widgets/bottom_nav_wrapper.dart';

// The API sends 0001-01-01 for rows that have no applied dates.
String _fmtDate(String? raw) {
  final dt = DateTime.tryParse(raw ?? '');
  if (dt == null || dt.year <= 1) return '';
  return DateFormat('dd-MM-yyyy').format(dt);
}

class LeaveManagementScreen extends GetView<LeaveManagementController> {
  const LeaveManagementScreen({super.key});

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
            'My Leaves',
            style: GoogleFonts.manrope(
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF241917),
            ),
          ),
          actions: [
            if (controller.canViewTeamLeave)
              IconButton(
                tooltip: 'Team Leave',
                icon: const Icon(
                  Icons.groups_rounded,
                  color: Color(0xFF241917),
                ),
                onPressed: () => Get.toNamed(AdminRoutes.teamLeave),
              ),
            IconButton(
              tooltip: 'My Leave Requests',
              icon: const Icon(Icons.history_rounded, color: Color(0xFF241917)),
              onPressed: () => Get.toNamed(AdminRoutes.leaveList),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFFB54A3A),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Apply Leave'),
          onPressed: () {
            controller.resetForm();
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              backgroundColor: const Color(0xFFF6F1ED),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              ),
              builder: (_) => const _ApplyLeaveSheet(),
            );
          },
        ),
        body: SafeArea(
          top: false,
          child: Obx(() {
            if (controller.isLoading.value && controller.leaves.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.errorMessage.value.isNotEmpty) {
              return _Message(
                icon: Icons.error_outline_rounded,
                text: controller.errorMessage.value,
                onRetry: controller.fetchMyLeaves,
              );
            }

            if (controller.leaves.isEmpty) {
              return _Message(
                icon: Icons.event_busy_rounded,
                text: 'No leaves found',
                onRetry: controller.fetchMyLeaves,
              );
            }

            return RefreshIndicator(
              onRefresh: controller.fetchMyLeaves,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                // Bottom space keeps the last card clear of the Apply button.
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 88.h),
                itemCount: controller.leaves.length,
                separatorBuilder: (_, __) => SizedBox(height: 12.h),
                itemBuilder: (_, i) => _LeaveCard(leave: controller.leaves[i]),
              ),
            );
          }),
        ),
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
          colorScheme: const ColorScheme.light(primary: Color(0xFFB54A3A)),
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
    Widget option(IconData icon, String label, Future<void> Function() onTap) {
      return Builder(
        builder: (ctx) => ListTile(
          leading: Icon(icon, color: const Color(0xFFB54A3A)),
          title: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF241917),
            ),
          ),
          onTap: () {
            Navigator.pop(ctx);
            onTap();
          },
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF6F1ED),
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
              () => _pickImage(ImageSource.camera),
            ),
            option(
              Icons.photo_library_rounded,
              'Choose from Gallery',
              () => _pickImage(ImageSource.gallery),
            ),
            option(Icons.picture_as_pdf_rounded, 'Upload PDF', _pickPdf),
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
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Obx(() {
          final balance = _c.currentBalance;
          final days = _c.numberOfDays;
          final submitting = _c.isSubmitting.value;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apply Leave',
                style: GoogleFonts.manrope(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF241917),
                ),
              ),
              SizedBox(height: 16.h),
              DropdownButtonFormField<LeaveTypeModel>(
                isExpanded: true,
                decoration: _fieldDecoration(
                  _c.isLoadingTypes.value
                      ? 'Loading leave types...'
                      : 'Leave Type',
                ),
                items: _c.leaveTypes
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.leaveType),
                      ),
                    )
                    .toList(),
                onChanged: _c.selectLeaveType,
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'From Date',
                      date: _c.fromDate.value,
                      onTap: () => _pickDate(isFrom: true),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _DateField(
                      label: 'To Date',
                      date: _c.toDate.value,
                      onTap: () => _pickDate(isFrom: false),
                    ),
                  ),
                ],
              ),
              if (days > 0) ...[
                SizedBox(height: 8.h),
                Text(
                  balance == null
                      ? '$days day(s)'
                      : '$days day(s) · Balance: $balance',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: _c.exceedsBalance
                        ? const Color(0xFFD85E5E)
                        : const Color(0xFF756A66),
                  ),
                ),
              ],
              SizedBox(height: 12.h),
              TextField(
                controller: _reasonCtrl,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: _fieldDecoration('Reason'),
              ),
              if (_c.needsPrescription) ...[
                SizedBox(height: 12.h),
                _attachmentField(),
              ],
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB54A3A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  onPressed: submitting ? null : _submit,
                  child: submitting
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Submit'),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _attachmentField() {
    final fileName = _c.prescriptionFileName.value;

    return InkWell(
      borderRadius: BorderRadius.circular(14.r),
      onTap: _showAttachmentOptions,
      child: InputDecorator(
        decoration: _fieldDecoration('Prescription (optional)').copyWith(
          suffixIcon: fileName.isEmpty
              ? const Icon(Icons.upload_file_rounded)
              : IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => _c.setPrescription('', ''),
                ),
        ),
        child: Text(
          fileName.isEmpty ? 'Tap to attach' : fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14.r),
      borderSide: const BorderSide(color: Color(0xFFEDE2DC)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14.r),
      borderSide: const BorderSide(color: Color(0xFFEDE2DC)),
    ),
  );
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
    return InkWell(
      borderRadius: BorderRadius.circular(14.r),
      onTap: onTap,
      child: InputDecorator(
        decoration: _fieldDecoration(label),
        isEmpty: date == null,
        child: Text(
          date == null ? '' : DateFormat('dd-MM-yyyy').format(date!),
          maxLines: 1,
        ),
      ),
    );
  }
}

class _LeaveCard extends StatelessWidget {
  final Data leave;

  const _LeaveCard({required this.leave});

  @override
  Widget build(BuildContext context) {
    final from = _fmtDate(leave.fromDate);
    final to = _fmtDate(leave.toDate);
    final reason = (leave.leaveReason ?? '').trim();

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFEDE2DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  (leave.leaveType ?? '-').trim(),
                  style: GoogleFonts.manrope(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF241917),
                  ),
                ),
              ),
              Text(
                leave.years ?? '',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF756A66),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              _Count(
                label: 'Total',
                value: leave.totalLeave ?? 0,
                color: const Color(0xFF6A3027),
              ),
              _Count(
                label: 'Taken',
                value: leave.totalTakenLeave ?? 0,
                color: const Color(0xFFF0A43C),
              ),
              _Count(
                label: 'Balance',
                value: leave.totalBalanceLeave ?? 0,
                color: const Color(0xFF2AB673),
              ),
            ],
          ),
          if (from.isNotEmpty || to.isNotEmpty) ...[
            SizedBox(height: 12.h),
            _Detail(
              icon: Icons.date_range_rounded,
              text: '$from - $to (${leave.leaveNoofday ?? 0} days)',
            ),
          ],
          if (reason.isNotEmpty) ...[
            SizedBox(height: 6.h),
            _Detail(icon: Icons.notes_rounded, text: reason),
          ],
        ],
      ),
    );
  }
}

class _Count extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _Count({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: GoogleFonts.manrope(
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF756A66),
            ),
          ),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Detail({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16.sp, color: const Color(0xFF756A66)),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: const Color(0xFF241917),
            ),
          ),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onRetry;

  const _Message({
    required this.icon,
    required this.text,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48.sp, color: const Color(0xFF756A66)),
          SizedBox(height: 12.h),
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: const Color(0xFF756A66),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
