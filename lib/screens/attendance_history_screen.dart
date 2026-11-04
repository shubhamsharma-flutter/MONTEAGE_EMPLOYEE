import 'package:monteage_employee/utils/constants/color_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/attendance_history_controller.dart';
import '../models/attendance_history_model.dart';
import '../widgets/bottom_nav_wrapper.dart';

class AttendanceHistoryScreen extends StatelessWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(AttendanceHistoryController());

    return BottomNavWrapper(
      child: Scaffold(
        backgroundColor: AppColor.background,
        appBar: AppBar(
          leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Get.back(),
              ),
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attendance History',
                  style: GoogleFonts.inter(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Review your attendance records',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0x29FFFFFF),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: IconButton(
                  icon: const Icon(Icons.search_rounded, color: Colors.white),
                  onPressed: () => _showSearchDialog(context, c),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              // ── Month Selector ──
              _MonthSelector(c: c),
      
              // ── Stats Card (clickable) ──
              Obx(() {
                c.records.length;
                c.selectedMonth.value;
                c.selectedStatusFilter.value;
                // Compute counts from filteredRecords so they stay in sync
                final records  = c.filteredRecords;
      final total    = records.length;
      final verified = records.where((r) => c.combinedStatus(r) == 'VERIFIED').length;
      final pending  = records.where((r) => c.combinedStatus(r) == 'PENDING').length;
      final rejected = records.where((r) => c.combinedStatus(r) == 'REJECTED').length;
                final current  = c.selectedStatusFilter.value;
      
                return Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColor.border, width: 1),
                      boxShadow: AppShadow.card,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatTile(
                          label: 'Total',
                          value: total.toString(),
                          icon: Icons.view_agenda_rounded,
                          accentColor: AppColor.primary,
                          filter: 'All',
                          currentFilter: current,
                          onTap: () => c.setStatusFilter('All'),
                        ),
                        _vDivider(),
                        _StatTile(
                          label: 'Verified',
                          value: verified.toString(),
                          icon: Icons.check_circle_outline,
                          accentColor: AppColor.success,
                          filter: 'Verified',
                          currentFilter: current,
                          onTap: () => c.setStatusFilter('Verified'),
                        ),
                        _vDivider(),
                        _StatTile(
                          label: 'Pending',
                          value: pending.toString(),
                          icon: Icons.schedule_rounded,
                          accentColor: AppColor.warning,
                          filter: 'Pending',
                          currentFilter: current,
                          onTap: () => c.setStatusFilter('Pending'),
                        ),
                        _vDivider(),
                        _StatTile(
                          label: 'Rejected',
                          value: rejected.toString(),
                          icon: Icons.cancel_outlined,
                          accentColor: AppColor.danger,
                          filter: 'Rejected',
                          currentFilter: current,
                          onTap: () => c.setStatusFilter('Rejected'),
                        ),
                      ],
                    ),
                  ),
                );
              }),
      
              // ── Records list ──
              Expanded(
                child: Obx(() {
                  c.records.length;
                  c.selectedMonth.value;
                  c.selectedStatusFilter.value;
                  if (c.isLoading.value) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          SizedBox(height: 16.h),
                          Text(
                            'Loading your records',
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColor.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
      
                  final records = c.displayRecords;
      
                  if (records.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 64.sp,
                            color: AppColor.textSecondary.withOpacity(0.3),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'No attendance records found',
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColor.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
      
                  return RefreshIndicator(
                    onRefresh: c.fetchHistory,
                    color: AppColor.primary,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                      itemCount: records.length,
                      itemBuilder: (_, i) => _HistoryCard(record: records[i], c: c),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _vDivider() =>
      Container(width: 1, height: 48.h, color: AppColor.border);

  static void _showSearchDialog(BuildContext context, AttendanceHistoryController c) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Search by Date',
                style: GoogleFonts.inter(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColor.textPrimary,
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: c.searchDateController,
                keyboardType: TextInputType.datetime,
                decoration: InputDecoration(
                  hintText: 'dd-MM-yyyy',
                  hintStyle: GoogleFonts.inter(fontSize: 13.sp, color: AppColor.textDisabled),
                  filled: true,
                  fillColor: AppColor.surfaceVariant,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        c.clearFilter();
                        Get.back();
                      },
                      child: Text(
                        'Clear',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: AppColor.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        c.applyDateFilter(c.searchDateController.text.trim());
                        Get.back();
                      },
                      style: FilledButton.styleFrom(backgroundColor: AppColor.primary),
                      child: Text('Search', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// MONTH SELECTOR (dynamic, sliding)
// ─────────────────────────────────────────────

class _MonthSelector extends StatefulWidget {
  final AttendanceHistoryController c;
  const _MonthSelector({required this.c});

  @override
  State<_MonthSelector> createState() => _MonthSelectorState();
}

class _MonthSelectorState extends State<_MonthSelector> {
  late final ScrollController _scrollCtrl;

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// Build list of {year, month} from Jan of the earliest year up to now
  List<Map<String, int>> get _months {
    final now = DateTime.now();
    // Start from Jan of current year (change 'now.year' to a fixed year if needed)
    final start = DateTime(now.year, 1);
    final List<Map<String, int>> result = [];
    var cur = start;
    while (!cur.isAfter(now)) {
      result.add({'year': cur.year, 'month': cur.month});
      cur = DateTime(cur.year, cur.month + 1);
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
    // Scroll to current month after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
  }

  void _scrollToCurrent() {
    final months = _months;
    final now = DateTime.now();
    final idx = months.indexWhere(
      (m) => m['year'] == now.year && m['month'] == now.month,
    );
    if (idx < 0) return;
    final itemW = 80.w + 8.w; // chip width + separator
    final offset = (idx * itemW) - (Get.width / 2) + (itemW / 2);
    _scrollCtrl.animateTo(
      offset.clamp(0, _scrollCtrl.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final months = _months;

    return Obx(() {
      final selected = widget.c.selectedMonth.value; // 'yyyy-MM' string

      return SizedBox(
        height: 44.h,
        child: ListView.separated(
          controller: _scrollCtrl,
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          itemCount: months.length,
          separatorBuilder: (_, __) => SizedBox(width: 8.w),
          itemBuilder: (_, i) {
            final m = months[i];
            final key = '${m['year']}-${m['month']!.toString().padLeft(2, '0')}';
            final isActive = selected == key;
            final label = '${_monthNames[m['month']! - 1]} ${m['year']}';

            return GestureDetector(
              onTap: () {
                widget.c.setMonth(key);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 9.h),
                decoration: BoxDecoration(
                  color: isActive ? AppColor.accent : Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isActive ? AppColor.accent : AppColor.border,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppColor.accent.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : [],
                ),
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.white : AppColor.textPrimary,
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────
// STAT TILE (now clickable with active state)
// ─────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final String filter;
  final String currentFilter;
  final VoidCallback onTap;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.filter,
    required this.currentFilter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentFilter == filter;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isActive ? accentColor.withOpacity(0.10) : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
            border: isActive
                ? Border.all(color: accentColor.withOpacity(0.40), width: 1.2)
                : Border.all(color: Colors.transparent, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(isActive ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                alignment: Alignment.center,
                child: Icon(icon,
                    color: isActive ? accentColor : accentColor.withOpacity(0.5),
                    size: 22.sp),
              ),
              SizedBox(height: 6.h),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: isActive ? accentColor : AppColor.textPrimary,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: isActive ? accentColor : AppColor.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// HISTORY CARD
// ─────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final Result record;
  final AttendanceHistoryController c;

  const _HistoryCard({required this.record, required this.c});

  Color _statusColor(String? s) {
    switch ((s ?? '').toUpperCase()) {
      case 'VERIFIED': return AppColor.success;
      case 'REJECTED': return AppColor.danger;
      case 'PENDING':
      default:         return AppColor.warning;
    }
  }

  Widget _kv(String k, String v, {Color? vColor, FontWeight? vWeight}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(k,
                style: GoogleFonts.inter(fontSize: 12.sp, color: AppColor.textMuted)),
          ),
          Expanded(
            child: Text(v,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: vColor ?? AppColor.textPrimary,
                  fontWeight: vWeight ?? FontWeight.w500,
                )),
          ),
        ],
      ),
    );
  }

  Widget _imageBlock(String title, String? url) {
    final full = c.fullImageUrl(url);
    if (full.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 12.h),
        Text(title,
            style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: AppColor.textPrimary)),
        SizedBox(height: 8.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              full,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColor.surfaceVariant,
                alignment: Alignment.center,
                child: Text('Image unavailable',
                    style: GoogleFonts.inter(fontSize: 11.sp, color: AppColor.textMuted)),
              ),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: AppColor.surfaceVariant,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final checkInColor  = _statusColor(record.status);
    final checkOutColor = _statusColor(record.checkoutStatus);

    final checkInTime  = c.formatIsoTime(record.timestamp);
    final checkOutTime = c.formatIsoTime(record.checkoutTimestamp);
    final headerDate   = c.formatToDdMmYyyy(record.date);

    final remark      = c.getAttendanceRemark(record);
    final remarkColor = c.remarkColor(remark);

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColor.border, width: 1),
        boxShadow: AppShadow.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: AppColor.surfaceVariant),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.all(16.w),
            collapsedIconColor: checkInColor,
            iconColor: checkInColor,
            title: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.titleCase(record.employeeName),
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColor.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'ID: ${record.employeeId} • $headerDate',
                          style: GoogleFonts.inter(fontSize: 11.sp, color: AppColor.textMuted),
                        ),
                        SizedBox(height: 6.h),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: remarkColor.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(6.r),
                                border: Border.all(color: remarkColor.withOpacity(0.5)),
                              ),
                              child: Text(
                                remark,
                                style: GoogleFonts.inter(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w700,
                                  color: remarkColor,
                                ),
                              ),
                            ),
                            if (record.duration?.formatted != null) ...[
                              SizedBox(width: 6.w),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                                decoration: BoxDecoration(
                                  color: AppColor.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(6.r),
                                  border: Border.all(color: AppColor.primary.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.timer_outlined, size: 10.sp, color: AppColor.primary),
                                    SizedBox(width: 3.w),
                                    Text(
                                      record.duration!.formatted,
                                      style: GoogleFonts.inter(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w700,
                                        color: AppColor.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: checkInColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: checkInColor),
                    ),
                    child: Text(
                      record.status ?? '--',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: checkInColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            children: [
              _kv('Username', c.titleCase(record.username)),
              _kv('Check-in Date', c.formatToDdMmYyyy(record.date)),
              _kv('Check-in Time', checkInTime),
              _kv('Face Confidence', record.confidenceScore.toStringAsFixed(3)),
              _kv('Face Detected', record.faceDetected ? 'Yes' : 'No'),
              _kv('Verified', record.isVerified ? 'Yes' : 'No'),
              _kv('Remark', remark, vColor: remarkColor, vWeight: FontWeight.w700),
              Divider(height: 16.h, color: AppColor.surfaceVariant),
              Text('Check-in Location',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColor.textPrimary,
                  )),
              SizedBox(height: 8.h),
              _kv('Latitude', (record.latitude ?? 0).toString()),
              _kv('Longitude', (record.longitude ?? 0).toString()),
              _kv('Accuracy (m)', (record.locationAccuracy ?? 0).toStringAsFixed(1)),
              _imageBlock('Check-in Photo', record.imageUrl),
              Divider(height: 20.h, color: AppColor.surfaceVariant),
              Row(
                children: [
                  Expanded(
                    child: Text('Check-out Details',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColor.textPrimary,
                        )),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: checkOutColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: checkOutColor),
                    ),
                    child: Text(
                      record.checkoutStatus ?? '--',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: checkOutColor,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              _kv('Checkout Date', c.formatToDdMmYyyy(record.checkoutDate)),
              _kv('Checkout Time', checkOutTime),
              _kv(
                'Checkout Confidence',
                record.checkoutConfidenceScore == null
                    ? '--'
                    : record.checkoutConfidenceScore!.toStringAsFixed(3),
              ),
              SizedBox(height: 12.h),
              Text('Check-out Location',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColor.textPrimary,
                  )),
              SizedBox(height: 8.h),
              _kv('Latitude', (record.checkoutLatitude ?? 0).toString()),
              _kv('Longitude', (record.checkoutLongitude ?? 0).toString()),
              _kv('Accuracy (m)', (record.checkoutLocationAccuracy ?? 0).toStringAsFixed(1)),
              _imageBlock('Check-out Photo', record.checkoutImageUrl),
              if (record.isSuspicious) ...[
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColor.danger.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColor.danger),
                  ),
                  child: Text(
                    '⚠ Suspicious: ${record.suspiciousReason ?? "Yes"}',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColor.danger,
                    ),
                  ),
                ),
              ],
              Divider(height: 20.h, color: AppColor.surfaceVariant),
              _kv('Created', c.formatIsoDateTime(record.createdAt)),
              _kv('Updated', c.formatIsoDateTime(record.updatedAt)),
            ],
          ),
        ),
      ),
    );
  }
}