import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../controllers/leave_management_controller.dart';
import '../widgets/bottom_nav_wrapper.dart';

// ── Date helper ───────────────────────────────────────────────────────────────
String _fmtDate(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  final dt = DateTime.tryParse(raw);
  if (dt == null) return raw;
  return DateFormat('dd-MM-yyyy').format(dt);
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class LeaveManagementScreen extends StatelessWidget {
  LeaveManagementScreen({super.key});

  final TextEditingController _searchCtrl = TextEditingController();
  final RxBool _searchVisible = false.obs;

  LeaveController get _c => LeaveController.to;

  void _openLeaveForm() {
    Get.bottomSheet(
      LeaveFormBottomSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isApprover = _c.employeeRole != EmployeeRole.employee;
    return BottomNavWrapper(
      child: DefaultTabController(
        length: isApprover ? 2 : 1,
        child: Scaffold(
        backgroundColor: const Color(0xFFF6F1ED),
        appBar: AppBar(
          title: Obx(() => _searchVisible.value
              ? TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  onChanged: (v) => _c.searchQuery.value = v,
                  style: GoogleFonts.inter(
                      fontSize: 14.sp, color: const Color(0xFF241917)),
                  decoration: InputDecoration(
                    hintText: "Search by type or date...",
                    hintStyle: GoogleFonts.inter(
                        fontSize: 13.sp, color: const Color(0xFF8B7D77)),
                    border: InputBorder.none,
                  ),
                )
              : Text(
                  "Leave and WFH ",
                  style: GoogleFonts.manrope(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF241917)),
                )),
          backgroundColor: const Color(0xFFF6F1ED),
          elevation: 0,
          bottom: isApprover
              ? TabBar(
                  labelColor: const Color(0xFFB54A3A),
                  unselectedLabelColor: const Color(0xFF8B7D77),
                  indicatorColor: const Color(0xFFB54A3A),
                  labelStyle: GoogleFonts.manrope(
                      fontSize: 13.sp, fontWeight: FontWeight.w700),
                  tabs: const [
                    Tab(text: "My Leaves"),
                    Tab(text: "Team Leaves"),
                  ],
                )
              : null,
          actions: [
            Obx(() => IconButton(
                  icon: Icon(
                    _searchVisible.value
                        ? Icons.close_rounded
                        : Icons.search_rounded,
                    color: const Color(0xFF6A3027),
                  ),
                  onPressed: () {
                    _searchVisible.value = !_searchVisible.value;
                    if (!_searchVisible.value) {
                      _searchCtrl.clear();
                      _c.searchQuery.value = '';
                    }
                  },
                )),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6A3027)),
              onPressed: _c.refreshAll,
            ),
          ],
        ),
        body: isApprover
            ? TabBarView(children: [
                _myLeavesBody(),
                _teamLeavesBody(),
              ])
            : _myLeavesBody(),
        floatingActionButton: FloatingActionButton(
          onPressed: _openLeaveForm,
          backgroundColor: const Color(0xFFB54A3A),
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    ));
  }
  Widget _myLeavesBody() {
    return Obx(() {
      if (_c.isLoadingLeaves.value) {
        return const Center(
            child: CircularProgressIndicator(color: Color(0xFFB54A3A)));
      }
      final visibleLeaves = _c.filteredLeaves;
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          children: [
            SizedBox(height: 4.h),
            _LeaveStatsCard(),
            SizedBox(height: 14.h),
            Obx(() => Row(
                  children: [
                    Text(
                      _c.selectedFilter.value == 'Total'
                          ? "Leave/WFH History"
                          : "${_c.selectedFilter.value} Leaves",
                      style: GoogleFonts.manrope(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF241917)),
                    ),
                    SizedBox(width: 8.w),
                    if (_c.selectedFilter.value != 'Total')
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: _filterColor(_c.selectedFilter.value)
                              .withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          "${visibleLeaves.length}",
                          style: GoogleFonts.manrope(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: _filterColor(_c.selectedFilter.value),
                          ),
                        ),
                      ),
                  ],
                )),
            SizedBox(height: 12.h),
            Expanded(
              child: visibleLeaves.isEmpty
                  ? _emptyState()
                  : RefreshIndicator(
                      color: const Color(0xFFB54A3A),
                      onRefresh: () async => _c.refreshAll(),
                      child: ListView.builder(
                        itemCount: visibleLeaves.length,
                        itemBuilder: (_, i) => _LeaveCard(
                          leave: visibleLeaves[i],
                          onApprove: (id) => _c.approveLeave(id),
                          onReject: (id) => _showRejectDialog(id),
                          // View-only here — you can't approve your own leave.
                          canApprove: false,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      );
    });
  }

  Widget _teamLeavesBody() {
    return _TeamLeavesTab(onReject: _showRejectDialog);
  }

  void _showRejectDialog(String id) {
    final remarksCtrl = TextEditingController();
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      backgroundColor: const Color(0xFFF6F1ED),
      title: Text("Rejection Remarks",
          style: GoogleFonts.manrope(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF241917))),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Please provide a reason for rejection:",
              style: GoogleFonts.inter(
                  fontSize: 13.sp, color: const Color(0xFF8B7D77))),
          SizedBox(height: 12.h),
          TextField(
            controller: remarksCtrl,
            maxLines: 3,
            style: GoogleFonts.inter(
                fontSize: 13.sp, color: const Color(0xFF241917)),
            decoration: InputDecoration(
              hintText: "Enter rejection remarks...",
              hintStyle: GoogleFonts.inter(
                  fontSize: 12.sp, color: const Color(0xFF8B7D77)),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: const BorderSide(color: Color(0xFFE0D5D0))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: const BorderSide(color: Color(0xFFE0D5D0))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: const BorderSide(
                      color: Color(0xFFB54A3A), width: 1.5)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text("Cancel",
              style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: const Color(0xFF8B7D77),
                  fontWeight: FontWeight.w600)),
        ),
        ElevatedButton(
          onPressed: () {
            final remarks = remarksCtrl.text.trim();
            if (remarks.isEmpty) {
              Get.snackbar("Required", "Please enter rejection remarks.",
                  backgroundColor: Colors.orange.shade50,
                  colorText: Colors.orange.shade800,
                  snackPosition: SnackPosition.BOTTOM);
              return;
            }
            Get.back();
            _c.rejectLeave(id, remarks);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB54A3A),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            elevation: 0,
          ),
          child: Text("Reject",
              style: GoogleFonts.manrope(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ),
      ],
    ));
  }

  Color _filterColor(String filter) {
    switch (filter) {
      case 'Pending':
        return Colors.orange;
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return const Color(0xFF6A3027);
    }
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_outlined,
                size: 56.sp, color: const Color(0xFF8B7D77)),
            SizedBox(height: 12.h),
            Obx(() => Text(
                  _c.selectedFilter.value == 'Total'
                      ? "No leave/WFH history found"
                      : "No ${_c.selectedFilter.value} leaves found",
                  style: GoogleFonts.manrope(
                      fontSize: 15.sp, color: const Color(0xFF8B7D77)),
                )),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// TEAM LEAVES TAB — "By Employee" quick filter for TL/HR/PM approvers.
// Selecting an employee shows all of that employee's leaves; the ones still
// Pending carry Approve/Reject actions. Which employees appear here (HR/PM
// see everyone, TL sees only their juniors) is decided by the backend's
// MobTeamEmployeeLeaveList response for the logged-in approver.
// ─────────────────────────────────────────────────────────────────────────────

Color _teamStatusColor(String status) {
  switch (status) {
    case 'Pending':
      return Colors.orange;
    case 'Approved':
      return Colors.green;
    case 'Rejected':
      return Colors.red;
    default:
      return const Color(0xFF6A3027);
  }
}

class _TeamLeavesTab extends StatefulWidget {
  final void Function(String) onReject;
  const _TeamLeavesTab({required this.onReject});

  @override
  State<_TeamLeavesTab> createState() => _TeamLeavesTabState();
}

class _TeamLeavesTabState extends State<_TeamLeavesTab> {
  LeaveController get _c => LeaveController.to;
  String? _employeeFilter;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_c.isLoadingTeamLeaves.value) {
        return const Center(
            child: CircularProgressIndicator(color: Color(0xFFB54A3A)));
      }
      final all = _c.teamLeaveHistory;
      if (all.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.group_outlined,
                  size: 56.sp, color: const Color(0xFF8B7D77)),
              SizedBox(height: 12.h),
              Text("No team leave requests",
                  style: GoogleFonts.manrope(
                      fontSize: 15.sp, color: const Color(0xFF8B7D77))),
            ],
          ),
        );
      }

      // Group leaves by employee so the approver can pick a person first.
      final Map<String, Map<String, int>> byEmployee = {};
      for (final l in all) {
        final name = (l['employee_name'] ?? '').toString().trim();
        if (name.isEmpty) continue;
        final entry = byEmployee.putIfAbsent(
            name, () => {'Pending': 0, 'Approved': 0, 'Rejected': 0});
        final status = (l['status'] ?? 'Pending').toString();
        entry[status] = (entry[status] ?? 0) + 1;
      }

      final filtered = _employeeFilter == null
          ? all
          : all
              .where((l) =>
                  (l['employee_name'] ?? '').toString().trim() ==
                  _employeeFilter)
              .toList();

      return RefreshIndicator(
        color: const Color(0xFFB54A3A),
        onRefresh: () async => _c.fetchTeamLeaveList(),
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          children: [
            if (byEmployee.isNotEmpty) ...[
              Text('By Employee',
                  style: GoogleFonts.manrope(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF241917))),
              SizedBox(height: 10.h),
              ...byEmployee.entries.map((e) => _EmployeeLeaveRow(
                    name: e.key,
                    counts: e.value,
                    selected: _employeeFilter == e.key,
                    onTap: () => setState(() {
                      _employeeFilter =
                          _employeeFilter == e.key ? null : e.key;
                    }),
                  )),
              SizedBox(height: 18.h),
            ],
            Row(
              children: [
                Text(
                  _employeeFilter == null
                      ? 'Leave Requests'
                      : "$_employeeFilter's Leaves",
                  style: GoogleFonts.manrope(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF241917)),
                ),
                SizedBox(width: 8.w),
                Text('(${filtered.length})',
                    style: GoogleFonts.inter(
                        fontSize: 12.sp, color: const Color(0xFF8B7D77))),
                const Spacer(),
                if (_employeeFilter != null)
                  GestureDetector(
                    onTap: () => setState(() => _employeeFilter = null),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close_rounded,
                            size: 14.sp, color: const Color(0xFFB54A3A)),
                        SizedBox(width: 3.w),
                        Text('Clear',
                            style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFB54A3A))),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: 10.h),
            if (filtered.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: Center(
                  child: Text('No leave requests for this employee',
                      style: GoogleFonts.inter(
                          fontSize: 13.sp, color: const Color(0xFF8B7D77))),
                ),
              )
            else
              ...filtered.map((l) => _LeaveCard(
                    leave: l,
                    onApprove: (id) => _c.approveLeave(id),
                    onReject: widget.onReject,
                    showEmployeeName: _employeeFilter == null,
                    canApprove: true,
                  )),
          ],
        ),
      );
    });
  }
}

class _EmployeeLeaveRow extends StatelessWidget {
  final String name;
  final Map<String, int> counts;
  final bool selected;
  final VoidCallback onTap;

  const _EmployeeLeaveRow({
    required this.name,
    required this.counts,
    required this.selected,
    required this.onTap,
  });

  String _initials(String n) {
    final parts = n.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFB54A3A);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: selected ? brand.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border:
              Border.all(color: selected ? brand : const Color(0xFFE0D5D0)),
        ),
        child: Row(
          children: [
            Container(
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(
                color: brand.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _initials(name),
                  style: GoogleFonts.manrope(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      color: brand),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(name,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF241917))),
            ),
            for (final status in ['Pending', 'Approved', 'Rejected'])
              if ((counts[status] ?? 0) > 0)
                Padding(
                  padding: EdgeInsets.only(left: 6.w),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 7.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: _teamStatusColor(status).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(7.r),
                    ),
                    child: Text(
                      '${counts[status]}',
                      style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: _teamStatusColor(status)),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATS CARD — 4 clickable tiles (Balance tile removed as requested)
// ─────────────────────────────────────────────────────────────────────────────

class _LeaveStatsCard extends StatelessWidget {
  _LeaveStatsCard();

  LeaveController get _c => LeaveController.to;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 4.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: const [
            BoxShadow(
                color: Color(0x12000000),
                blurRadius: 14,
                offset: Offset(0, 7))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatTile(
              label: "Total",
              value: "${_c.totalCount}",
              icon: Icons.view_agenda_rounded,
              color: const Color(0xFF6A3027),
              isSelected: _c.selectedFilter.value == 'Total',
              onTap: () => _c.selectedFilter.value = 'Total',
            ),
            _vDivider(),
            _StatTile(
              label: "Pending",
              value: "${_c.pendingCount}",
              icon: Icons.pending_actions_rounded,
              color: Colors.orange,
              isSelected: _c.selectedFilter.value == 'Pending',
              onTap: () => _c.selectedFilter.value = 'Pending',
            ),
            _vDivider(),
            _StatTile(
              label: "Approved",
              value: "${_c.approvedCount}",
              icon: Icons.check_circle_rounded,
              color: Colors.green,
              isSelected: _c.selectedFilter.value == 'Approved',
              onTap: () => _c.selectedFilter.value = 'Approved',
            ),
            _vDivider(),
            _StatTile(
              label: "Rejected",
              value: "${_c.rejectedCount}",
              icon: Icons.cancel_rounded,
              color: Colors.red,
              isSelected: _c.selectedFilter.value == 'Rejected',
              onTap: () => _c.selectedFilter.value = 'Rejected',
            ),
          ],
        ),
      );
    });
  }

  Widget _vDivider() =>
      Container(height: 40.h, width: 1, color: const Color(0xFFE8DDD9));
}

class _StatTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          border: isSelected
              ? Border.all(color: color.withOpacity(0.35), width: 1.2)
              : Border.all(color: Colors.transparent, width: 1.2),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 22.sp,
                color: isSelected ? color : color.withOpacity(0.65)),
            SizedBox(height: 6.h),
            Text(value,
                style: GoogleFonts.manrope(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? color : const Color(0xFF241917))),
            SizedBox(height: 2.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color:
                            isSelected ? color : const Color(0xFF8B7D77))),
                if (isSelected) ...[
                  SizedBox(width: 2.w),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      size: 10.sp, color: color),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LEAVE CARD (unchanged from original — works off Map<String, dynamic>)
// ─────────────────────────────────────────────────────────────────────────────

class _LeaveCard extends StatefulWidget {
  final Map<String, dynamic> leave;
  final Function(String) onApprove;
  final Function(String) onReject;
  final bool showEmployeeName;
  final bool canApprove;

  const _LeaveCard({
    required this.leave,
    required this.onApprove,
    required this.onReject,
    this.showEmployeeName = false,
    this.canApprove = false,
  });

  @override
  State<_LeaveCard> createState() => _LeaveCardState();
}

class _LeaveCardState extends State<_LeaveCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _animCtrl;
  late Animation<double> _expandAnim;
  late Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _expandAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _rotateAnim = Tween<double>(begin: 0, end: 0.5).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _animCtrl.forward() : _animCtrl.reverse();
  }

  Color get _statusColor {
    switch (widget.leave['status']) {
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData get _statusIcon {
    switch (widget.leave['status']) {
      case 'Approved':
        return Icons.check_circle_rounded;
      case 'Rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.pending_actions_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final leave = widget.leave;
    final leaveType = (leave['leave_type'] ?? '').toString();
    final fromFormatted = _fmtDate(leave['from_date']);
    final toFormatted = _fmtDate(leave['to_date']);
    final isPending = leave['status'] == 'Pending';
    final remarks = (leave['remarks'] ?? '').toString().trim();
    final workHandover = (leave['work_handover_to'] ?? '').toString().trim();

    String numberOfDays = '';
    final from = DateTime.tryParse(leave['from_date'] ?? '');
    final to = DateTime.tryParse(leave['to_date'] ?? '');
    if (from != null && to != null) {
      final days = to.difference(from).inDays + 1;
      numberOfDays = days > 0 ? '$days day${days > 1 ? 's' : ''}' : '1 day';
    }
    // Fallback: use stored no_of_days if dates not parseable
    if (numberOfDays.isEmpty && (leave['no_of_days'] ?? 0) > 0) {
      final d = leave['no_of_days'] as int;
      numberOfDays = '$d day${d > 1 ? 's' : ''}';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: _expanded
                ? _statusColor.withOpacity(0.10)
                : const Color(0x0A000000),
            blurRadius: _expanded ? 14 : 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: _expanded
            ? Border.all(color: _statusColor.withOpacity(0.25), width: 1.2)
            : Border.all(color: Colors.transparent, width: 1.2),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _toggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F1ED),
                      borderRadius: BorderRadius.circular(8.r),
                      border:
                          Border.all(color: const Color(0xFFE0D5D0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.category_outlined,
                            size: 12.sp,
                            color: const Color(0xFF6A3027)),
                        SizedBox(width: 4.w),
                        Text(
                          leaveType.isEmpty ? 'Leave' : leaveType,
                          style: GoogleFonts.manrope(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF6A3027)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      (fromFormatted.isNotEmpty && toFormatted.isNotEmpty)
                          ? '$fromFormatted – $toFormatted'
                          : '',
                      style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: const Color(0xFF8B7D77)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  _StatusBadge(
                      label: leave['status'] ?? 'Pending',
                      color: _statusColor,
                      icon: _statusIcon),
                  SizedBox(width: 6.w),
                  RotationTransition(
                    turns: _rotateAnim,
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        size: 20.sp, color: const Color(0xFFCBC0BA)),
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _expandAnim,
            axisAlignment: -1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(
                    color: _statusColor.withOpacity(0.15),
                    height: 1,
                    indent: 14.w,
                    
                    endIndent: 14.w),
                Padding(
                  padding:
                      EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 4.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.showEmployeeName && (leave['employee_name'] ?? '').isNotEmpty) ...[
                        _infoRow(Icons.person_outline_rounded, "Employee",
                            '${leave['employee_name']} (${leave['employee_code']})'),
                        SizedBox(height: 10.h),
                      ],
                      _infoRow(Icons.description_outlined, "Reason",
                          leave['reason'] ?? ''),
                      if (workHandover.isNotEmpty) ...[
                        SizedBox(height: 10.h),
                        _infoRow(Icons.swap_horiz_rounded,
                            "Work Handled By", workHandover),
                      ],
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          Expanded(
                              child: _smallInfoBox(
                                  icon: Icons.calendar_month_rounded,
                                  label: "From",
                                  value: fromFormatted)),
                          SizedBox(width: 8.w),
                          Expanded(
                              child: _smallInfoBox(
                                  icon: Icons.event_available_rounded,
                                  label: "To",
                                  value: toFormatted)),
                        ],
                      ),
                      if (numberOfDays.isNotEmpty) ...[
                        SizedBox(height: 10.h),
                        _infoRow(Icons.timelapse_rounded, "Duration",
                            numberOfDays),
                      ],
                      SizedBox(height: 10.h),
                      _infoRow(Icons.people_alt_outlined, "Approval To",
                          leave['approved_to'] ?? ''),
                      SizedBox(height: 10.h),
                      _infoRow(Icons.access_time_rounded, "Applied On",
                          _fmtDate(leave['applied_on'])),
                      if (leave['status'] == 'Rejected' &&
                          remarks.isNotEmpty) ...[
                        SizedBox(height: 10.h),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 10.h),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius:
                                BorderRadius.circular(10.r),
                            border: Border.all(
                                color: Colors.red.shade100),
                          ),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  size: 13.sp,
                                  color: Colors.red.shade600),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(children: [
                                    TextSpan(
                                      text: "Remark: ",
                                      style: GoogleFonts.manrope(
                                          fontSize: 11.sp,
                                          fontWeight:
                                              FontWeight.w700,
                                          color: Colors
                                              .red.shade700),
                                    ),
                                    TextSpan(
                                      text: remarks,
                                      style: GoogleFonts.inter(
                                          fontSize: 11.sp,
                                          color:
                                              Colors.red.shade800),
                                    ),
                                  ]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (isPending && widget.canApprove) ...[
                        SizedBox(height: 14.h),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    widget.onReject(leave['id']),
                                icon: Icon(Icons.close_rounded,
                                    size: 14.sp,
                                    color: Colors.red.shade700),
                                label: Text("Reject",
                                    style: GoogleFonts.manrope(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.red.shade700)),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                      color: Colors.red.shade300),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(
                                              10.r)),
                                  padding: EdgeInsets.symmetric(
                                      vertical: 11.h),
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    widget.onApprove(leave['id']),
                                icon: Icon(Icons.check_rounded,
                                    size: 14.sp,
                                    color: Colors.white),
                                label: Text("Approve",
                                    style: GoogleFonts.manrope(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Colors.green.shade600,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(
                                              10.r)),
                                  padding: EdgeInsets.symmetric(
                                      vertical: 11.h),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      SizedBox(height: 14.h),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14.sp, color: const Color(0xFF6A3027)),
        SizedBox(width: 8.w),
        Expanded(
          child: RichText(
            text: TextSpan(children: [
              TextSpan(
                text: "$label: ",
                style: GoogleFonts.manrope(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF8B7D77)),
              ),
              TextSpan(
                text: value,
                style: GoogleFonts.inter(
                    fontSize: 11.sp, color: const Color(0xFF241917)),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _smallInfoBox(
      {required IconData icon,
      required String label,
      required String value}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F1ED),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFE0D5D0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14.sp, color: const Color(0xFF6A3027)),
          SizedBox(width: 6.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 9.sp,
                        color: const Color(0xFF8B7D77),
                        fontWeight: FontWeight.w600)),
                SizedBox(height: 2.h),
                Text(value,
                    style: GoogleFonts.manrope(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF241917))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS BADGE
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _StatusBadge(
      {required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20.r)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: color),
          SizedBox(width: 4.w),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM SHEET FORM — wired to LeaveController
// ─────────────────────────────────────────────────────────────────────────────

class LeaveFormBottomSheet extends StatefulWidget {
  const LeaveFormBottomSheet({super.key});

  @override
  State<LeaveFormBottomSheet> createState() => _LeaveFormBottomSheetState();
}

class _LeaveFormBottomSheetState extends State<LeaveFormBottomSheet> {
  late TextEditingController _reasonCtrl;
  late TextEditingController _fromDateCtrl;
  late TextEditingController _toDateCtrl;
  late TextEditingController _workHandoverCtrl;

  LeaveController get _c => LeaveController.to;

  @override
  void initState() {
    super.initState();
    _reasonCtrl = TextEditingController();
    _fromDateCtrl = TextEditingController();
    _toDateCtrl = TextEditingController();
    _workHandoverCtrl = TextEditingController();
    // Reset controller form state
    _c.selectedLeaveType.value = null;
    _c.fromDate.value = null;
    _c.toDate.value = null;
    _c.prescriptionFileName.value = '';
    _c.prescriptionFilePath.value = '';
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _fromDateCtrl.dispose();
    _toDateCtrl.dispose();
    _workHandoverCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final firstDate = isFrom ? today : (_c.fromDate.value ?? today);
    final initialDate = isFrom
        ? (_c.fromDate.value ?? today)
        : (_c.toDate.value ?? firstDate);

    final picked = await showDatePicker(
      context: context,
      initialDate:
          initialDate.isBefore(firstDate) ? firstDate : initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2101),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme:
                const ColorScheme.light(primary: Color(0xFFB54A3A))),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          _c.fromDate.value = picked;
          _fromDateCtrl.text = DateFormat('dd-MM-yyyy').format(picked);
          if (_c.toDate.value != null &&
              _c.toDate.value!.isBefore(picked)) {
            _c.toDate.value = null;
            _toDateCtrl.clear();
          }
        } else {
          _c.toDate.value = picked;
          _toDateCtrl.text = DateFormat('dd-MM-yyyy').format(picked);
        }
      });
    }
  }

  Future<void> _pickPrescription() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF6F1ED),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Upload Prescription",
                  style: GoogleFonts.manrope(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF241917))),
              SizedBox(height: 16.h),
              ListTile(
                onTap: () async {
                  Navigator.pop(ctx);
                  final XFile? image = await ImagePicker().pickImage(
                      source: ImageSource.camera, imageQuality: 85);
                  if (image != null) {
                    setState(() {
                      _c.prescriptionFileName.value = image.name;
                      _c.prescriptionFilePath.value = image.path;
                    });
                  }
                },
                leading: _uploadIcon(Icons.camera_alt_rounded),
                title: Text("Take a Photo",
                    style: GoogleFonts.manrope(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF241917))),
                subtitle: Text("Use camera to capture prescription",
                    style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: const Color(0xFF8B7D77))),
              ),
              SizedBox(height: 4.h),
              ListTile(
                onTap: () async {
                  Navigator.pop(ctx);
                  final XFile? image = await ImagePicker().pickImage(
                      source: ImageSource.gallery, imageQuality: 85);
                  if (image != null) {
                    setState(() {
                      _c.prescriptionFileName.value = image.name;
                      _c.prescriptionFilePath.value = image.path;
                    });
                  }
                },
                leading: _uploadIcon(Icons.photo_library_rounded),
                title: Text("Choose from Gallery",
                    style: GoogleFonts.manrope(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF241917))),
                subtitle: Text("Select an existing image",
                    style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: const Color(0xFF8B7D77))),
              ),
              SizedBox(height: 4.h),
              ListTile(
                onTap: () async {
                  Navigator.pop(ctx);
                  final result = await FilePicker.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf']);
                  if (result != null && result.files.isNotEmpty) {
                    setState(() {
                      _c.prescriptionFileName.value = result.files.first.name;
                      _c.prescriptionFilePath.value = result.files.first.path ?? '';
                    });
                  }
                },
                leading: _uploadIcon(Icons.picture_as_pdf_rounded),
                title: Text("Upload PDF",
                    style: GoogleFonts.manrope(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF241917))),
                subtitle: Text("Pick a PDF from your files",
                    style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: const Color(0xFF8B7D77))),
              ),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _uploadIcon(IconData icon) => Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: const Color(0xFFB54A3A).withOpacity(0.10),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFFB54A3A), size: 20.sp),
      );

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.50,
      maxChildSize: 0.96,
      builder: (context, scroll) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF6F1ED),
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(28.r)),
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
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Apply Leave/WFH",
                        style: GoogleFonts.manrope(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF241917))),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: const BoxDecoration(
                            color: Color(0xFFE8DDD9),
                            shape: BoxShape.circle),
                        child: Icon(Icons.close,
                            size: 18.sp,
                            color: const Color(0xFF6A3027)),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.h),
              const Divider(color: Color(0xFFE0D5D0), height: 1),
              Expanded(
                child: Obx(() {
                  final selectedType = _c.selectedLeaveType.value;
                  final balance = _c.currentBalance;
                  final days = _c.numberOfDays;
                  final exceeds = _c.exceedsBalance;
                  final needsHandover = _c.needsHandover;
                  final needsPrescription = _c.needsPrescription;
                  final prescription = _c.prescriptionFileName.value;

                  return ListView(
                    controller: scroll,
                    padding:
                        EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 40.h),
                    children: [
                      _label("Type *"),
                      SizedBox(height: 6.h),
                      _leaveTypeDropdown(),
                      SizedBox(height: 16.h),
                      _label("Reason *"),
                      SizedBox(height: 6.h),
                      _field(_reasonCtrl, "Enter reason...",
                          maxLines: 4),
                      SizedBox(height: 16.h),
                      if (needsHandover) ...[
                        _label("Work will be handled by *"),
                        SizedBox(height: 4.h),
                        Text(
                          "Mention the colleague who will manage your responsibilities.",
                          style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: const Color(0xFF8B7D77)),
                        ),
                        SizedBox(height: 6.h),
                        _field(_workHandoverCtrl,
                            "E.g. Aman Verma"),
                        SizedBox(height: 16.h),
                      ],
                      _label("From Date *"),
                      SizedBox(height: 6.h),
                      _dateBox(
                          controller: _fromDateCtrl,
                          hint: "Select from date",
                          onTap: () => _pickDate(isFrom: true)),
                      SizedBox(height: 16.h),
                      _label("To Date *"),
                      SizedBox(height: 6.h),
                      _dateBox(
                          controller: _toDateCtrl,
                          hint: "Select to date",
                          onTap: () => _pickDate(isFrom: false)),
                      SizedBox(height: 16.h),
                      _label("Number of Days"),
                      SizedBox(height: 6.h),
                      _readOnlyBox(
                        icon: Icons.timelapse_rounded,
                        value: days > 0
                            ? "$days day${days > 1 ? 's' : ''}"
                            : "—",
                        valueColor: exceeds ? Colors.red.shade700 : null,
                      ),
                      // ── Balance summary banner (right after Number of Days) ──
                      if (selectedType != null) ...[
                        SizedBox(height: 10.h),
                        _BalanceBanner(
                          leaveType: selectedType.leaveType,
                          balance: balance,
                          requestedDays: days,
                        ),
                      ],
                      if (needsPrescription) ...[
                        SizedBox(height: 16.h),
                        _label("Doctor's Prescription"),
                        SizedBox(height: 4.h),
                        Text(
                          "Please upload a valid prescription from a registered doctor.",
                          style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: const Color(0xFF8B7D77)),
                        ),
                        SizedBox(height: 6.h),
                        _prescriptionUploadBox(prescription),
                      ],
                      SizedBox(height: 24.h),
                      Obx(() => SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _c.isSubmitting.value
                                  ? null
                                  : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFFB54A3A),
                                disabledBackgroundColor:
                                    const Color(0xFFB54A3A)
                                        .withOpacity(0.5),
                                padding: EdgeInsets.symmetric(
                                    vertical: 16.h),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(14.r)),
                                elevation: 0,
                              ),
                              child: _c.isSubmitting.value
                                  ? SizedBox(
                                      height: 20.h,
                                      width: 20.h,
                                      child: const CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white),
                                    )
                                  : Text("Submit Leave Request",
                                      style: GoogleFonts.manrope(
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white)),
                            ),
                          )),
                    ],
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _prescriptionUploadBox(String prescription) {
    final hasFile = prescription.isNotEmpty;
    return GestureDetector(
      onTap: _pickPrescription,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: hasFile ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: hasFile
                ? Colors.green.shade400
                : const Color(0xFFB54A3A),
            width: 1.4,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: hasFile
                    ? Colors.green.shade100
                    : const Color(0xFFB54A3A).withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFile
                    ? Icons.check_circle_rounded
                    : Icons.upload_file_rounded,
                size: 20.sp,
                color: hasFile
                    ? Colors.green.shade700
                    : const Color(0xFFB54A3A),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasFile
                        ? "Prescription uploaded"
                        : "Tap to upload prescription",
                    style: GoogleFonts.manrope(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: hasFile
                          ? Colors.green.shade700
                          : const Color(0xFF241917),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    hasFile ? prescription : "Camera · Gallery · PDF",
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: hasFile
                          ? Colors.green.shade600
                          : const Color(0xFF8B7D77),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (hasFile)
              GestureDetector(
                onTap: () {
                  _c.prescriptionFileName.value = '';
                  _c.prescriptionFilePath.value = '';
                },
                child: Padding(
                  padding: EdgeInsets.only(left: 8.w),
                  child: Icon(Icons.close_rounded,
                      size: 18.sp, color: Colors.red.shade400),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _leaveTypeDropdown() {
    return Obx(() {
      final selected = _c.selectedLeaveType.value;
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: selected != null
                ? const Color(0xFFB54A3A)
                : const Color(0xFFE0D5D0),
            width: selected != null ? 1.5 : 1.0,
          ),
        ),
        child: _c.isLoadingTypes.value
            ? Padding(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                child: Row(children: [
                  SizedBox(
                      height: 16.h,
                      width: 16.h,
                      child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFB54A3A))),
                  SizedBox(width: 10.w),
                  Text("Loading types...",
                      style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          color: const Color(0xFF8B7D77))),
                ]),
              )
            : DropdownButtonHideUnderline(
                child: DropdownButton<LeaveTypeModel>(
                  value: selected,
                  isExpanded: true,
                  hint: Text("Select Type",
                      style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          color: const Color(0xFF8B7D77))),
                  icon: Icon(Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFF6A3027), size: 20.sp),
                  style: GoogleFonts.inter(
                      fontSize: 14.sp, color: const Color(0xFF241917)),
                  onChanged: (val) {
                    _c.selectedLeaveType.value = val;
                    if (val?.leaveType.toUpperCase().contains('SICK') ==
                        false) {
                      _c.prescriptionFileName.value = '';
                    }
                    // Fetch fresh balance for selected type
                    if (val != null) {
                      _c.fetchBalanceForType(val.leaveTypeId);
                    }
                  },
                  items: _c.leaveTypes
                      .map((t) => DropdownMenuItem<LeaveTypeModel>(
                            value: t,
                            child: Text(t.leaveType),
                          ))
                      .toList(),
                ),
              ),
      );
    });
  }

  Widget _readOnlyBox(
      {required IconData icon, required String value, Color? valueColor}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EAE6),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE0D5D0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17.sp, color: const Color(0xFF6A3027)),
          SizedBox(width: 10.w),
          Text(value,
              style: GoogleFonts.manrope(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? const Color(0xFF241917))),
        ],
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: GoogleFonts.manrope(
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF241917)));

  Widget _field(TextEditingController ctrl, String hint,
      {int maxLines = 1}) {
    return TextField(
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
            borderSide:
                const BorderSide(color: Color(0xFFE0D5D0))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide:
                const BorderSide(color: Color(0xFFE0D5D0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(
                color: Color(0xFFB54A3A), width: 1.5)),
      ),
    );
  }

  Widget _dateBox({
    required TextEditingController controller,
    required String hint,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: controller.text.isNotEmpty
                ? const Color(0xFFB54A3A)
                : const Color(0xFFE0D5D0),
            width: controller.text.isNotEmpty ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 17.sp, color: const Color(0xFF6A3027)),
            SizedBox(width: 10.w),
            Text(
              controller.text.isEmpty ? hint : controller.text,
              style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: controller.text.isEmpty
                      ? const Color(0xFF8B7D77)
                      : const Color(0xFF241917)),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final reason = _reasonCtrl.text.trim();
    final workHandover = _workHandoverCtrl.text.trim();
    final prescription = _c.prescriptionFileName.value;

    String? missingField;
    if (_c.selectedLeaveType.value == null) {
      missingField = "Please select a Type.";
    } else if (reason.isEmpty) {
      missingField = "Please enter a Reason.";
    } else if (_c.needsHandover && workHandover.isEmpty) {
      missingField = "Please enter the colleague who will handle your work.";
    } else if (_fromDateCtrl.text.isEmpty) {
      missingField = "Please select a From Date.";
    } else if (_toDateCtrl.text.isEmpty) {
      missingField = "Please select a To Date.";
    }

    if (missingField != null) {
      Get.snackbar("Missing Info", missingField,
          backgroundColor: Colors.orange.shade50,
          colorText: Colors.orange.shade800,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3));
      return;
    }

    if (_c.fromDate.value != null &&
        _c.toDate.value != null &&
        _c.toDate.value!.isBefore(_c.fromDate.value!)) {
      Get.snackbar("Invalid Dates", "To date cannot be before from date.",
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade800,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    if (_c.exceedsBalance) {
      Get.snackbar(
        "Insufficient Balance",
        "You only have ${_c.currentBalance} leave(s) remaining, but requested ${_c.numberOfDays} day(s).",
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade800,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    _c.submitLeave(
      reason: reason,
      workHandover: workHandover,
      prescriptionFile: prescription.isNotEmpty ? prescription : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BALANCE BANNER — shows per-type balance + monthly/yearly label
// ─────────────────────────────────────────────────────────────────────────────

class _BalanceBanner extends StatelessWidget {
  final String leaveType;
  final int balance;
  final int requestedDays;

  const _BalanceBanner({
    required this.leaveType,
    required this.balance,
    required this.requestedDays,
  });

  @override
  Widget build(BuildContext context) {
    final isMonthly = isMonthlyLeave(leaveType);
    final periodLabel = isMonthly ? "this month" : "this year";
    final isLow = balance <= 2;
    final isOver = requestedDays > 0 && requestedDays > balance;
    final color = isOver
        ? Colors.red
        : isLow
            ? Colors.orange
            : Colors.green;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(
            isOver
                ? Icons.warning_amber_rounded
                : Icons.account_balance_wallet_rounded,
            size: 18.sp,
            color: color,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: RichText(
              text: TextSpan(children: [
                TextSpan(
                  text: "$balance leave${balance != 1 ? 's' : ''} remaining ",
                  style: GoogleFonts.manrope(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: color),
                ),
                TextSpan(
                  text: "$periodLabel · $leaveType",
                  style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: color.withOpacity(0.8)),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

}