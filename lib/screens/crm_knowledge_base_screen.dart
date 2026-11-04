import 'package:monteage_employee/utils/constants/color_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/crm_list_item_model.dart';

// Matches the shape of the reference knowledge-base.html page: a search box
// then filter dropdowns (Type, Sub Type) and a Search button. No FAB here —
// this screen is for finding existing documents, not adding new ones.
// Options are static sample data for now; wire to a real CRM API later.
class CrmKnowledgeBaseScreen extends StatefulWidget {
  const CrmKnowledgeBaseScreen({super.key});

  @override
  State<CrmKnowledgeBaseScreen> createState() => _CrmKnowledgeBaseScreenState();
}

class _CrmKnowledgeBaseScreenState extends State<CrmKnowledgeBaseScreen> {
  String? _kbType;
  String? _subType;
  bool _showResults = false;

  static const _kbTypeOptions = ["Technical Document", "Product Catalog", "Case Study"];
  static const _subTypeOptions = ["General", "Technical", "Marketing"];

  static final _sampleResults = [
    CrmListItem(title: "Bottle Blow Moulding — Setup Guide", lines: const [
      CrmDetailLine(Icons.category_outlined, "Primary Packaging"),
      CrmDetailLine(Icons.description_outlined, "Brochure"),
    ]),
    CrmListItem(title: "Shrink Wrapping — Maintenance Manual", lines: const [
      CrmDetailLine(Icons.category_outlined, "Secondary Packaging"),
      CrmDetailLine(Icons.description_outlined, "Manual"),
    ]),
    CrmListItem(title: "Robotics Solution — Case Study", lines: const [
      CrmDetailLine(Icons.category_outlined, "Robotics Solution"),
      CrmDetailLine(Icons.description_outlined, "Case History"),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          "Knowledge Base",
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColor.border),
            ),
            child: Column(
              children: [
                _FilterDropdown(
                  label: "Knowledge Base Type",
                  value: _kbType,
                  options: _kbTypeOptions,
                  onChanged: (v) => setState(() => _kbType = v),
                ),
                _FilterDropdown(
                  label: "Sub Type",
                  value: _subType,
                  options: _subTypeOptions,
                  onChanged: (v) => setState(() => _subType = v),
                  isLast: true,
                ),
                SizedBox(height: 4.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _showResults = true),
                    icon: Icon(Icons.search_rounded, size: 18.sp, color: Colors.white),
                    label: Text(
                      "Search",
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_showResults) ...[
            SizedBox(height: 20.h),
            Text(
              "Results",
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: AppColor.textPrimary,
              ),
            ),
            SizedBox(height: 10.h),
            for (final item in _sampleResults) _KnowledgeBaseCard(item: item),
          ],
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final bool isLast;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 14.h : 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w700,
              color: AppColor.textPrimary,
            ),
          ),
          SizedBox(height: 6.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              color: AppColor.background,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: AppColor.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                hint: Text("--Select--",
                    style: GoogleFonts.inter(fontSize: 13.sp, color: AppColor.textDisabled)),
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColor.primary),
                style: GoogleFonts.inter(fontSize: 13.sp, color: AppColor.textPrimary),
                items: options
                    .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KnowledgeBaseCard extends StatelessWidget {
  final CrmListItem item;
  const _KnowledgeBaseCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColor.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: GoogleFonts.inter(
              fontSize: 14.5.sp,
              fontWeight: FontWeight.w700,
              color: AppColor.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          for (final line in item.lines)
            Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: Row(
                children: [
                  Icon(line.icon, size: 13.sp, color: AppColor.primary),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      line.text,
                      style: GoogleFonts.inter(fontSize: 12.sp, color: AppColor.textMuted),
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
