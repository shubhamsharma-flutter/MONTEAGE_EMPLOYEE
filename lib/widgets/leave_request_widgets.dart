import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../controllers/leave_list_controller.dart';

String _fmtDate(String? raw) {
  final date = parseLeaveDate(raw);
  return date == null ? '' : DateFormat('dd-MM-yyyy').format(date);
}

Color _statusColor(String status) {
  switch (status) {
    case 'Approved':
      return const Color(0xFF2AB673);
    case 'Rejected':
      return const Color(0xFFD85E5E);
    case 'Pending':
      return const Color(0xFFF0A43C);
    default:
      return const Color(0xFF6A3027);
  }
}

class LeaveFilterBar extends StatelessWidget {
  final String selected;
  final int Function(String filter) countFor;
  final ValueChanged<String> onSelected;

  const LeaveFilterBar({
    super.key,
    required this.selected,
    required this.countFor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFEDE2DC)),
      ),
      child: Row(
        children: leaveStatusFilters.map((filter) {
          final isSelected = selected == filter;
          final color = _statusColor(filter);

          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(16.r),
              onTap: () => onSelected(filter),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  children: [
                    Text(
                      '${countFor(filter)}',
                      style: GoogleFonts.manrope(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    Text(
                      filter,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF756A66),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class LeaveRequestCard extends StatelessWidget {
  /// Shown above the leave type on team leaves; null for the user's own leaves.
  final String? employeeName;
  final String? leaveType;
  final String? fromDate;
  final String? toDate;
  final int days;
  final String? reason;
  final String status;
  final List<LeaveApproval> approvals;

  /// Shown below the approvals, e.g. approve and reject buttons.
  final Widget? footer;

  const LeaveRequestCard({
    super.key,
    this.employeeName,
    required this.leaveType,
    required this.fromDate,
    required this.toDate,
    required this.days,
    required this.reason,
    required this.status,
    required this.approvals,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final reasonText = (reason ?? '').trim();
    final name = employeeName?.trim();
    final hasName = name != null && name.isNotEmpty;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasName)
                      Text(
                        name,
                        style: GoogleFonts.manrope(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF241917),
                        ),
                      ),
                    Text(
                      (leaveType ?? '-').trim(),
                      style: hasName
                          ? GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF756A66),
                            )
                          : GoogleFonts.manrope(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF241917),
                            ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: status),
            ],
          ),
          SizedBox(height: 10.h),
          _Detail(
            icon: Icons.date_range_rounded,
            text:
                '${_fmtDate(fromDate)} - ${_fmtDate(toDate)} '
                '($days ${days == 1 ? 'day' : 'days'})',
          ),
          if (reasonText.isNotEmpty) ...[
            SizedBox(height: 6.h),
            _Detail(icon: Icons.notes_rounded, text: reasonText),
          ],
          Divider(height: 24.h, color: const Color(0xFFEDE2DC)),
          ...approvals.map((approval) => _ApprovalRow(approval: approval)),
          if (footer != null) ...[SizedBox(height: 12.h), footer!],
        ],
      ),
    );
  }
}

class _ApprovalRow extends StatelessWidget {
  final LeaveApproval approval;

  const _ApprovalRow({required this.approval});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              approval.approvedBy.isEmpty
                  ? approval.approver
                  : '${approval.approver} · ${approval.approvedBy}',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: const Color(0xFF756A66),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            approval.status,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: _statusColor(approval.status),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
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

class LeaveMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onRetry;

  const LeaveMessage({
    super.key,
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
