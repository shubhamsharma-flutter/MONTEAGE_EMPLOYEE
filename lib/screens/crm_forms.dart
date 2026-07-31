import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../controllers/crm_controller.dart';
import '../controllers/task_controller.dart';
import '../models/crm_list_item_model.dart';
import '../models/empdropdownmode.dart' as empdrop;

// Shared bottom-sheet form pieces used across the CRM "add" flows
// (Opportunity, Customer, the Visit sub-forms in crm_add_visit_flow.dart,
// and the Schedule Meeting sheet in crm_home_screen.dart) so every form
// looks and behaves the same way.

// Reuses the same employee list the Task screen's "Assign" pickers use, so
// there's only one "get all employees" call in the whole app.
Future<List<empdrop.Data>> crmFetchEmployees() async {
  final taskController = Get.find<TaskController>();
  if (taskController.boundEmployees.isEmpty) {
    await taskController.fetchBindEmployees();
  }
  return taskController.boundEmployees;
}

// Checkbox-list multi-select picker (used for Supportive Sales Person(s) on
// a Visit, and Attendees on a Meeting). Returns the new selection, or null
// if the sheet was dismissed without tapping Done.
Future<List<empdrop.Data>?> showMultiSelectEmployees(
  BuildContext context,
  List<empdrop.Data> employees,
  List<empdrop.Data> initiallySelected, {
  String title = "Select Employees",
}) {
  final selected = List<empdrop.Data>.from(initiallySelected);
  return showModalBottomSheet<List<empdrop.Data>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFF6F1ED),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20.w,
              right: 20.w,
              top: 20.h,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.h,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                crmSheetTitle(title),
                SizedBox(height: 12.h),
                if (employees.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: Text(
                      "No employees found.",
                      style: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF8B7D77)),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 320.h),
                    child: ListView(
                      shrinkWrap: true,
                      children: employees.map((e) {
                        final checked = selected.any((s) => s.employeeId == e.employeeId);
                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          activeColor: const Color(0xFF6A3027),
                          title: Text(e.employeeName ?? '',
                              style: GoogleFonts.inter(fontSize: 13.5.sp)),
                          value: checked,
                          onChanged: (v) => setState(() {
                            if (v == true) {
                              selected.add(e);
                            } else {
                              selected.removeWhere((s) => s.employeeId == e.employeeId);
                            }
                          }),
                        );
                      }).toList(),
                    ),
                  ),
                SizedBox(height: 12.h),
                crmSaveButton("Done", () => Navigator.pop(ctx, selected)),
              ],
            ),
          );
        },
      );
    },
  );
}

// Tappable field that opens showMultiSelectEmployees and displays the
// selected names, comma-separated. Pass a setState callback so the caller's
// sheet redraws with the new selection.
Widget crmMultiSelectField({
  required BuildContext context,
  required List<empdrop.Data> employees,
  required List<empdrop.Data> selected,
  required String hint,
  required String pickerTitle,
  required ValueChanged<List<empdrop.Data>> onChanged,
}) {
  return InkWell(
    onTap: () async {
      final result = await showMultiSelectEmployees(context, employees, selected, title: pickerTitle);
      if (result != null) onChanged(result);
    },
    borderRadius: BorderRadius.circular(12.r),
    child: Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFEDE2DC)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              selected.isEmpty ? hint : selected.map((e) => e.employeeName ?? '').join(', '),
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: selected.isEmpty ? const Color(0xFFBDB0AB) : const Color(0xFF241917),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.keyboard_arrow_down_rounded, color: const Color(0xFF6A3027)),
        ],
      ),
    ),
  );
}

Widget crmField(
  TextEditingController ctrl,
  String hint, {
  int maxLines = 1,
  TextInputType? keyboardType,
}) {
  return TextField(
    controller: ctrl,
    maxLines: maxLines,
    keyboardType: keyboardType,
    style: GoogleFonts.inter(fontSize: 14.sp),
    decoration: InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
    ),
  );
}

Widget crmDropdown(
  String value,
  List<String> options,
  ValueChanged<String?> onChanged,
) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 12.w),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12.r),
      border: Border.all(color: const Color(0xFFEDE2DC)),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        style: GoogleFonts.inter(fontSize: 14.sp, color: const Color(0xFF241917)),
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: const Color(0xFF6A3027)),
        items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
        onChanged: onChanged,
      ),
    ),
  );
}

Widget crmSheetTitle(String text) => Text(
      text,
      style: GoogleFonts.manrope(
        fontSize: 17.sp,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF241917),
      ),
    );

Widget crmFieldLabel(String text) => Text(
      text,
      style: GoogleFonts.manrope(
        fontSize: 12.5.sp,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF241917),
      ),
    );

Widget crmSaveButton(String label, VoidCallback onPressed) => SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6A3027),
          padding: EdgeInsets.symmetric(vertical: 14.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
    );

void crmShowSheet(BuildContext context, WidgetBuilder builder) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFF6F1ED),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 20.h,
        bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.h,
      ),
      child: SingleChildScrollView(child: builder(ctx)),
    ),
  );
}

// Matches the reference "Add New Opportunity" form (add-opportunity.html):
// Opportunity Type, Start Date, Customer, Opportunity Name, Key Account
// Person are required there; the rest are optional detail fields.
// [onSaved] is called with the created item too, so callers like the Visit
// flow can log a matching visit entry alongside the opportunity.
void showAddOpportunitySheet(
  BuildContext context,
  CrmController controller, {
  String? prefillCustomer,
  ValueChanged<CrmListItem>? onSaved,
}) {
  final customerCtrl = TextEditingController(text: prefillCustomer ?? '');
  final opportunityNameCtrl = TextEditingController();
  final keyAccountPersonCtrl = TextEditingController();
  final industryCtrl = TextEditingController();
  final marketSegmentCtrl = TextEditingController();
  final supplierNameCtrl = TextEditingController();
  final supplierContactCtrl = TextEditingController();
  DateTime? pickedDate;

  crmShowSheet(context, (ctx) {
    return StatefulBuilder(
      builder: (ctx, setState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            crmSheetTitle("Add New Opportunity"),
            SizedBox(height: 16.h),
            OutlinedButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2101),
                );
                if (picked != null) setState(() => pickedDate = picked);
              },
              child: Text(pickedDate == null
                  ? "Start date *"
                  : DateFormat('dd MMM yyyy').format(pickedDate!)),
            ),
            SizedBox(height: 12.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: crmField(customerCtrl, "Customer *")),
                SizedBox(width: 8.w),
                InkWell(
                  onTap: () => showAddCustomerSheet(
                    context,
                    (name) => setState(() => customerCtrl.text = name),
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    height: 48.h,
                    width: 48.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A3027).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(Icons.person_add_alt_1_rounded,
                        color: const Color(0xFF6A3027), size: 20.sp),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            crmField(opportunityNameCtrl, "Opportunity name *"),
            SizedBox(height: 12.h),
            crmField(keyAccountPersonCtrl, "Key account person *"),
            SizedBox(height: 12.h),
            crmField(industryCtrl, "Industry (optional)"),
            SizedBox(height: 12.h),
            crmField(marketSegmentCtrl, "Market segment (optional)"),
            SizedBox(height: 12.h),
            crmField(supplierNameCtrl, "Supplier name (optional)"),
            SizedBox(height: 12.h),
            crmField(supplierContactCtrl, "Supplier contact person (optional)"),
            SizedBox(height: 20.h),
            crmSaveButton("Save", () {
              if (customerCtrl.text.trim().isEmpty ||
                  opportunityNameCtrl.text.trim().isEmpty ||
                  keyAccountPersonCtrl.text.trim().isEmpty ||
                  pickedDate == null) {
                Get.snackbar(
                  "Missing Info",
                  "Please fill in start date, customer, opportunity name and key account person.",
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }
              final lines = <CrmDetailLine>[
                CrmDetailLine(Icons.business_outlined, customerCtrl.text.trim()),
                CrmDetailLine(Icons.person_outline_rounded, keyAccountPersonCtrl.text.trim()),
                CrmDetailLine(Icons.calendar_today_outlined,
                    DateFormat('dd MMM yyyy').format(pickedDate!)),
                if (industryCtrl.text.trim().isNotEmpty)
                  CrmDetailLine(Icons.factory_outlined, industryCtrl.text.trim()),
              ];
              final item = CrmListItem(title: opportunityNameCtrl.text.trim(), lines: lines);
              controller.addOpportunity(item);
              Navigator.pop(ctx);
              onSaved?.call(item);
            }),
          ],
        );
      },
    );
  });
}

// Matches the reference "Add New Customer" form (add-customer.html).
// Photo upload from that form is skipped — no backend to store it yet.
// Calls [onSaved] with the new customer's full name so the caller can drop
// it straight into a Customer field.
void showAddCustomerSheet(BuildContext context, ValueChanged<String> onSaved) {
  const salutations = ["Mr", "Ms", "Dr", "Miss", "Mrs"];
  const entityStatuses = ["Active", "Inactive", "Dead"];
  String entityType = "Organisation";
  String salutation = salutations.first;
  String entityStatus = entityStatuses.first;
  final firstNameCtrl = TextEditingController();
  final middleNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final nickNameCtrl = TextEditingController();
  final contactNoCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final nricCtrl = TextEditingController();

  crmShowSheet(context, (ctx) {
    return StatefulBuilder(
      builder: (ctx, setState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            crmSheetTitle("Add New Customer"),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text("Organisation", style: GoogleFonts.inter(fontSize: 13.sp)),
                    value: "Organisation",
                    groupValue: entityType,
                    activeColor: const Color(0xFF6A3027),
                    onChanged: (v) => setState(() => entityType = v!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text("Individual", style: GoogleFonts.inter(fontSize: 13.sp)),
                    value: "Individual",
                    groupValue: entityType,
                    activeColor: const Color(0xFF6A3027),
                    onChanged: (v) => setState(() => entityType = v!),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                SizedBox(
                  width: 90.w,
                  child: crmDropdown(salutation, salutations, (v) => setState(() => salutation = v!)),
                ),
                SizedBox(width: 8.w),
                Expanded(child: crmField(firstNameCtrl, "First name *")),
              ],
            ),
            SizedBox(height: 12.h),
            crmField(middleNameCtrl, "Middle name (optional)"),
            SizedBox(height: 12.h),
            crmField(lastNameCtrl, "Last name (optional)"),
            SizedBox(height: 12.h),
            crmField(nickNameCtrl, "Nick name (optional)"),
            SizedBox(height: 12.h),
            crmField(contactNoCtrl, "Contact no (optional)"),
            SizedBox(height: 12.h),
            crmField(emailCtrl, "Email (optional)"),
            SizedBox(height: 12.h),
            crmField(nricCtrl, "NRIC no. (optional)"),
            SizedBox(height: 12.h),
            crmFieldLabel("Entity Status"),
            SizedBox(height: 6.h),
            crmDropdown(entityStatus, entityStatuses, (v) => setState(() => entityStatus = v!)),
            SizedBox(height: 20.h),
            crmSaveButton("Save", () {
              if (firstNameCtrl.text.trim().isEmpty) {
                Get.snackbar(
                  "Missing Info",
                  "Please enter a first name.",
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }
              final nameParts = [
                firstNameCtrl.text.trim(),
                middleNameCtrl.text.trim(),
                lastNameCtrl.text.trim(),
              ].where((p) => p.isNotEmpty).join(' ');
              onSaved(nameParts);
              Navigator.pop(ctx);
            }),
          ],
        );
      },
    );
  });
}
