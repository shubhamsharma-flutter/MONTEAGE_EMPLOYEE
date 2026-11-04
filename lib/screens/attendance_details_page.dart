import 'package:monteage_employee/utils/constants/color_constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/attendance_controller.dart';

class AttendanceDetailsPage extends GetView<AttendanceController> {
  const AttendanceDetailsPage({super.key});

  Future<void> _pickFromDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.fromDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) controller.updateFromDate(picked);
  }

  Future<void> _pickToDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.toDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) controller.updateToDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;

    // Responsive scales
    final bool isVerySmall = w < 340;
    final bool isSmall = w < 380;

    final double titleFont = isVerySmall ? 16 : isSmall ? 17 : 18;
    final double baseFont = isVerySmall ? 11 : isSmall ? 12 : 13;
    final double headerFont = isVerySmall ? 11 : 12;
    final double valueBigFont = isVerySmall ? 16 : 18;
    final double paddingH = isSmall ? 12 : 16;
    final double chipFont = isSmall ? 13 : 14;

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: isSmall ? 18 : 20),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Attendance Details",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: titleFont,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.ios_share_rounded, size: isSmall ? 20 : 22),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: paddingH),
          child: Obx(
                () => Column(
              children: [
                SizedBox(height: isSmall ? 6 : 8),

                // FILTER CARD
                _buildFilterCard(context, baseFont),

                SizedBox(height: isSmall ? 12 : 16),

                // TABS
                Row(
                  children: [
                    _TabChip(
                      label: "List Details",
                      isActive:
                      controller.selectedTab.value == AttendanceTab.list,
                      onTap: () => controller.changeTab(AttendanceTab.list),
                      fontSize: chipFont,
                    ),
                    const SizedBox(width: 16),
                    _TabChip(
                      label: "Statistical",
                      isActive: controller.selectedTab.value ==
                          AttendanceTab.statistical,
                      onTap: () =>
                          controller.changeTab(AttendanceTab.statistical),
                      fontSize: chipFont,
                    ),
                  ],
                ),

                SizedBox(height: isSmall ? 6 : 10),

                // MAIN BODY
                Expanded(
                  child: controller.selectedTab.value == AttendanceTab.list
                      ? _buildListView(baseFont, headerFont)
                      : _buildStatisticalView(
                    baseFont: baseFont,
                    headerFont: headerFont,
                    valueBigFont: valueBigFont,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= FILTER CARD =================

  Widget _buildFilterCard(BuildContext context, double baseFont) {
    final bool isSmall = MediaQuery.of(context).size.width < 380;

    return Container(
      padding: EdgeInsets.all(isSmall ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadow.card,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: "From Date",
                  value: controller.formatDate(controller.fromDate.value),
                  onTap: () => _pickFromDate(context),
                  baseFont: baseFont,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateField(
                  label: "To Date",
                  value: controller.formatDate(controller.toDate.value),
                  onTap: () => _pickToDate(context),
                  baseFont: baseFont,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmall ? 10 : 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<Employee>(
                  value: controller.selectedEmployee.value,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: "Employee Name",
                    labelStyle: TextStyle(
                      fontSize: baseFont,
                      color: Colors.grey[700],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: isSmall ? 8 : 10,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: baseFont,
                    color: Colors.black,
                  ),
                  items: controller.employees
                      .map(
                        (e) => DropdownMenuItem<Employee>(
                      value: e,
                      child: Text(
                        e.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                      .toList(),
                  onChanged: controller.updateEmployee,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: isSmall ? 42 : 46,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : () => controller.loadAttendance(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.danger,
                    padding:
                    EdgeInsets.symmetric(horizontal: isSmall ? 14 : 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Text(
                    "View",
                    style: TextStyle(
                      fontSize: baseFont,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= LIST TAB =================

  Widget _buildListView(double baseFont, double headerFont) {
    final bool isSmall = Get.width < 380;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header row
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 8 : 12,
              vertical: isSmall ? 8 : 10,
            ),
            decoration: const BoxDecoration(
              color: AppColor.danger,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                    flex: 3,
                    child: _HeaderText("Date", fontSize: headerFont)),
                Expanded(
                    flex: 2,
                    child: _HeaderText("In", fontSize: headerFont)),
                Expanded(
                    flex: 2,
                    child: _HeaderText("Out", fontSize: headerFont)),
                Expanded(
                    flex: 2,
                    child: _HeaderText("Late", fontSize: headerFont)),
                Expanded(
                    flex: 2,
                    child: _HeaderText("Work", fontSize: headerFont)),
                Expanded(
                    flex: 1,
                    child: _HeaderText("Status", fontSize: headerFont)),
              ],
            ),
          ),

          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.records.isEmpty) {
                return Center(
                  child: Text(
                    "No records found",
                    style:
                    TextStyle(fontSize: baseFont, color: Colors.grey[700]),
                  ),
                );
              }

              return ListView.separated(
                padding: EdgeInsets.symmetric(
                    horizontal: isSmall ? 8 : 12, vertical: 8),
                itemCount: controller.records.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final r = controller.records[i];

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            controller.formatDate(r.date),
                            style: TextStyle(fontSize: baseFont),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Text(
                              r.inTime,
                              style: TextStyle(fontSize: baseFont),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Text(
                              r.outTime,
                              style: TextStyle(fontSize: baseFont),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Text(
                              r.late,
                              style: TextStyle(fontSize: baseFont),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Text(
                              r.work,
                              style: TextStyle(fontSize: baseFont),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Center(
                            child: Text(
                              r.status,
                              style: TextStyle(
                                fontSize: baseFont,
                                fontWeight: FontWeight.w700,
                                color: _statusColor(r.status),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case "P":
        return Colors.green;
      case "A":
        return Colors.red;
      case "WO":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // ================= STATISTICAL TAB =================

  Widget _buildStatisticalView({
    required double baseFont,
    required double headerFont,
    required double valueBigFont,
  }) {
    final bool isSmall = Get.width < 380;

    return Obx(() {
      if (controller.records.isEmpty) {
        return Center(
          child: Text(
            "No data available",
            style: TextStyle(fontSize: baseFont, color: Colors.grey[700]),
          ),
        );
      }

      final total = controller.totalDays == 0 ? 1 : controller.totalDays;
      double pct(int v) => (v / total).clamp(0, 1);

      return SingleChildScrollView(
        padding: EdgeInsets.only(bottom: isSmall ? 12 : 16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: "Total Days",
                    value: controller.totalDays.toString(),
                    labelFont: baseFont,
                    valueFont: valueBigFont,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: "Present",
                    value: controller.presentDays.toString(),
                    labelFont: baseFont,
                    valueFont: valueBigFont,
                    valueColor: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: "Absent",
                    value: controller.absentDays.toString(),
                    labelFont: baseFont,
                    valueFont: valueBigFont,
                    valueColor: Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: "Weekly Off",
                    value: controller.weeklyOffDays.toString(),
                    labelFont: baseFont,
                    valueFont: valueBigFont,
                    valueColor: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: "Total Work (Hrs)",
                    value: controller.totalWorkHrsStr,
                    labelFont: baseFont,
                    valueFont: valueBigFont,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: "Total Late (Hrs)",
                    value: controller.totalLateHrsStr,
                    labelFont: baseFont,
                    valueFont: valueBigFont,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(isSmall ? 10 : 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppShadow.card,
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Attendance Distribution",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: headerFont,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _BarRow(
                    label: "Present",
                    value: controller.presentDays,
                    fraction: pct(controller.presentDays),
                    color: Colors.green,
                    fontSize: baseFont,
                  ),
                  const SizedBox(height: 8),
                  _BarRow(
                    label: "Absent",
                    value: controller.absentDays,
                    fraction: pct(controller.absentDays),
                    color: Colors.red,
                    fontSize: baseFont,
                  ),
                  const SizedBox(height: 8),
                  _BarRow(
                    label: "Weekly Off",
                    value: controller.weeklyOffDays,
                    fraction: pct(controller.weeklyOffDays),
                    color: Colors.orange,
                    fontSize: baseFont,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ================= SMALL WIDGETS =================

class _HeaderText extends StatelessWidget {
  final String text;
  final double fontSize;

  const _HeaderText(this.text, {required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: fontSize,
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final double baseFont;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.baseFont,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSmall = MediaQuery.of(context).size.width < 380;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: baseFont - 1, color: Colors.grey[700]),
          ),
          const SizedBox(height: 4),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 10,
              vertical: isSmall ? 8 : 10,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: AppColor.border),
              borderRadius: BorderRadius.circular(12),
              color: AppColor.dangerTint,
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: isSmall ? 14 : 16, color: Colors.grey[700]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(fontSize: baseFont),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final double fontSize;

  const _TabChip({
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSmall = MediaQuery.of(context).size.width < 380;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color:
                isActive ? AppColor.danger : Colors.grey.shade700,
              ),
            ),
            SizedBox(height: isSmall ? 3 : 4),
            Container(
              height: 2,
              width: 60,
              decoration: BoxDecoration(
                color: isActive ? AppColor.danger : Colors.transparent,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final double labelFont;
  final double valueFont;
  final Color? valueColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.labelFont,
    required this.valueFont,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSmall = MediaQuery.of(context).size.width < 380;

    return Container(
      padding: EdgeInsets.all(isSmall ? 10 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: labelFont, color: Colors.grey[700]),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: valueFont,
              fontWeight: FontWeight.w700,
              color: valueColor ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final int value;
  final double fraction;
  final Color color;
  final double fontSize;

  const _BarRow({
    required this.label,
    required this.value,
    required this.fraction,
    required this.color,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSmall = MediaQuery.of(context).size.width < 380;

    return Row(
      children: [
        SizedBox(
          width: isSmall ? 70 : 80,
          child: Text(
            label,
            style: TextStyle(fontSize: fontSize),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              FractionallySizedBox(
                widthFactor: fraction == 0 ? 0.05 : fraction,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
