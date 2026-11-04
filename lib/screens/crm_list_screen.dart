import 'package:monteage_employee/utils/constants/color_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/crm_list_item_model.dart';

// Shared screen for Opportunities / Visits — both reference pages
// (opportunity.html, visit.html) share the same shape: a title bar, a
// search box, a list of cards, and a "+" to add one. [items] is static
// sample data unless the caller passes a live list (see Opportunities in
// crm_home_screen.dart) — swap in real CRM data once an API exists.
class CrmListScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String searchHint;
  final String emptyMessage;
  final RxList<CrmListItem> items;
  final VoidCallback? onAdd;

  CrmListScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.searchHint,
    required this.emptyMessage,
    List<CrmListItem> items = const [],
    this.onAdd,
  }) : items = items is RxList<CrmListItem> ? items : items.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            TextField(
              style: GoogleFonts.inter(fontSize: 13.5.sp, color: AppColor.textPrimary),
              decoration: InputDecoration(
                hintText: searchHint,
                hintStyle: GoogleFonts.inter(fontSize: 13.sp, color: AppColor.textDisabled),
                prefixIcon: Icon(Icons.search_rounded, size: 20.sp, color: AppColor.textMuted),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: AppColor.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: AppColor.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: AppColor.primary, width: 1.5),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Expanded(
              child: Obx(() {
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 52.sp, color: AppColor.textMuted),
                        SizedBox(height: 12.h),
                        Text(
                          emptyMessage,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 13.sp, color: AppColor.textMuted),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) => _CrmCard(item: items[i]),
                );
              }),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColor.primary,
        shape: const CircleBorder(),
        onPressed: onAdd ??
            () => Get.snackbar(
                  "Coming Soon",
                  "Adding a new ${title.toLowerCase()} isn't available yet.",
                  snackPosition: SnackPosition.BOTTOM,
                ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _CrmCard extends StatelessWidget {
  final CrmListItem item;
  const _CrmCard({required this.item});

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
