import 'package:monteage_employee/utils/constants/color_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../controllers/crm_controller.dart';
import '../models/crm_list_item_model.dart';
import '../models/empdropdownmode.dart' as empdrop;
import 'crm_forms.dart';

// The "Add Visit" flow, matching the reference pages:
//  add-visit-main.html  → visit date/time/mode/agenda, then pick a type
//  add-visit.html       → "Existing Opportunity"
//  no-opportunity.html  → "No Opportunity" (has the same add-customer icon)
// "New Opportunity" and "Service Quotation" branches were dropped on
// request. Each branch ends by adding one entry to CrmController.visits.

const _kAgendaOptions = [
  "Introductory Visit",
  "Technical discussion",
  "Detailed Technical discussion",
  "Sampling/Demo",
  "Cold call",
  "Project management meeting",
  "Commercial discussion/Negotiation",
  "Courtesy Visit",
  "Payment Follow-up",
];

const _kModeOptions = ["Online", "Offline"];

class _VisitDetails {
  final DateTime meetingDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String mode;
  final String mainSalesPerson;
  final List<String> supportiveSalesPersons;
  final String agenda;

  _VisitDetails({
    required this.meetingDate,
    required this.startTime,
    required this.endTime,
    required this.mode,
    required this.mainSalesPerson,
    required this.supportiveSalesPersons,
    required this.agenda,
  });

  CrmDetailLine get dateLine => CrmDetailLine(
        Icons.calendar_today_outlined,
        "${DateFormat('dd MMM yyyy').format(meetingDate)} · "
        "${_formatTime(startTime)} - ${_formatTime(endTime)}",
      );
  CrmDetailLine get modeLine => CrmDetailLine(
        mode == "Online" ? Icons.videocam_outlined : Icons.location_on_outlined,
        mode,
      );
  CrmDetailLine get agendaLine => CrmDetailLine(Icons.event_note_outlined, agenda);
  CrmDetailLine get salesPersonLine =>
      CrmDetailLine(Icons.person_outline_rounded, mainSalesPerson);
}

String _formatTime(TimeOfDay t) {
  final hour12 = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
  final minute = t.minute.toString().padLeft(2, '0');
  final period = t.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour12:$minute $period';
}

Future<void> showAddVisitFlow(BuildContext context, CrmController controller) async {
  final employees = await crmFetchEmployees();
  if (!context.mounted) return;

  final mainSalesPersonCtrl = TextEditingController();
  DateTime? meetingDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  String mode = _kModeOptions.first;
  String agenda = _kAgendaOptions.first;
  final selectedSupportive = <empdrop.Data>[];

  crmShowSheet(context, (ctx) {
    return StatefulBuilder(
      builder: (ctx, setState) {
        Future<void> pickMeetingDate() async {
          final picked = await showDatePicker(
            context: ctx,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime(2101),
          );
          if (picked != null) setState(() => meetingDate = picked);
        }

        Future<void> pickTime(bool isStart) async {
          final picked = await showTimePicker(context: ctx, initialTime: TimeOfDay.now());
          if (picked != null) {
            setState(() => isStart ? startTime = picked : endTime = picked);
          }
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            crmSheetTitle("Add Visit"),
            SizedBox(height: 16.h),
            OutlinedButton(
              onPressed: pickMeetingDate,
              child: Text(meetingDate == null
                  ? "Meeting date *"
                  : DateFormat('dd MMM yyyy').format(meetingDate!)),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => pickTime(true),
                    child: Text(startTime == null ? "Start time *" : startTime!.format(ctx)),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => pickTime(false),
                    child: Text(endTime == null ? "End time *" : endTime!.format(ctx)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            crmFieldLabel("Mode *"),
            SizedBox(height: 6.h),
            crmDropdown(mode, _kModeOptions, (v) => setState(() => mode = v!)),
            SizedBox(height: 12.h),
            crmField(mainSalesPersonCtrl, "Main sales person *"),
            SizedBox(height: 12.h),
            crmFieldLabel("Supportive Sales Person(s) (optional)"),
            SizedBox(height: 6.h),
            crmMultiSelectField(
              context: context,
              employees: employees,
              selected: selectedSupportive,
              hint: "Select employees",
              pickerTitle: "Supportive Sales Person(s)",
              onChanged: (result) => setState(() {
                selectedSupportive
                  ..clear()
                  ..addAll(result);
              }),
            ),
            SizedBox(height: 12.h),
            crmFieldLabel("Agenda *"),
            SizedBox(height: 6.h),
            crmDropdown(agenda, _kAgendaOptions, (v) => setState(() => agenda = v!)),
            SizedBox(height: 20.h),
            Text(
              "Continue as",
              style: GoogleFonts.inter(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w700,
                color: AppColor.textPrimary,
              ),
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Expanded(
                  child: _VisitTypeButton(
                    icon: Icons.handshake_outlined,
                    label: "Existing Opportunity",
                    onTap: () {
                      if (mainSalesPersonCtrl.text.trim().isEmpty ||
                          meetingDate == null ||
                          startTime == null ||
                          endTime == null) {
                        Get.snackbar("Missing Info", "Please fill in the visit details first.",
                            snackPosition: SnackPosition.BOTTOM);
                        return;
                      }
                      final details = _VisitDetails(
                        meetingDate: meetingDate!,
                        startTime: startTime!,
                        endTime: endTime!,
                        mode: mode,
                        mainSalesPerson: mainSalesPersonCtrl.text.trim(),
                        supportiveSalesPersons:
                            selectedSupportive.map((e) => e.employeeName ?? '').toList(),
                        agenda: agenda,
                      );
                      Navigator.pop(ctx);
                      _showExistingOpportunitySheet(context, controller, details);
                    },
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _VisitTypeButton(
                    icon: Icons.person_off_outlined,
                    label: "No Opportunity",
                    onTap: () {
                      if (mainSalesPersonCtrl.text.trim().isEmpty ||
                          meetingDate == null ||
                          startTime == null ||
                          endTime == null) {
                        Get.snackbar("Missing Info", "Please fill in the visit details first.",
                            snackPosition: SnackPosition.BOTTOM);
                        return;
                      }
                      final details = _VisitDetails(
                        meetingDate: meetingDate!,
                        startTime: startTime!,
                        endTime: endTime!,
                        mode: mode,
                        mainSalesPerson: mainSalesPersonCtrl.text.trim(),
                        supportiveSalesPersons:
                            selectedSupportive.map((e) => e.employeeName ?? '').toList(),
                        agenda: agenda,
                      );
                      Navigator.pop(ctx);
                      _showNoOpportunitySheet(context, controller, details);
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  });
}

class _VisitTypeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _VisitTypeButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColor.border),
        backgroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 12.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
      icon: Icon(icon, size: 16.sp, color: AppColor.primary),
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11.5.sp,
          fontWeight: FontWeight.w700,
          color: AppColor.textPrimary,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// Matches add-visit.html — a visit against an opportunity that already
// exists. Opportunity choices are pulled straight from the app's own
// Opportunities list instead of a fixed dropdown.
void _showExistingOpportunitySheet(
    BuildContext context, CrmController controller, _VisitDetails details) {
  final opportunityNoCtrl = TextEditingController();
  String? selectedOpportunity =
      controller.opportunities.isNotEmpty ? controller.opportunities.first.title : null;

  crmShowSheet(context, (ctx) {
    return StatefulBuilder(
      builder: (ctx, setState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            crmSheetTitle("Visit — Existing Opportunity"),
            SizedBox(height: 16.h),
            if (controller.opportunities.isEmpty)
              Text(
                "No opportunities yet — add one first from the Opportunities screen.",
                style: GoogleFonts.inter(fontSize: 12.5.sp, color: AppColor.textMuted),
              )
            else ...[
              crmFieldLabel("Opportunity *"),
              SizedBox(height: 6.h),
              crmDropdown(
                selectedOpportunity!,
                controller.opportunities.map((o) => o.title).toList(),
                (v) => setState(() => selectedOpportunity = v),
              ),
            ],
            SizedBox(height: 12.h),
            crmField(opportunityNoCtrl, "Opportunity no (optional)"),
            SizedBox(height: 20.h),
            crmSaveButton("Save", () {
              if (selectedOpportunity == null) {
                Get.snackbar("Missing Info", "Please select an opportunity.",
                    snackPosition: SnackPosition.BOTTOM);
                return;
              }
              final lines = <CrmDetailLine>[
                details.dateLine,
                details.modeLine,
                details.agendaLine,
                details.salesPersonLine,
                if (opportunityNoCtrl.text.trim().isNotEmpty)
                  CrmDetailLine(Icons.tag_outlined, opportunityNoCtrl.text.trim()),
              ];
              controller.addVisit(CrmListItem(title: selectedOpportunity!, lines: lines));
              Navigator.pop(ctx);
            }),
          ],
        );
      },
    );
  });
}

// Matches no-opportunity.html — has the same "add customer" icon as the
// New Opportunity form.
void _showNoOpportunitySheet(
    BuildContext context, CrmController controller, _VisitDetails details) {
  final customerCtrl = TextEditingController();
  final keyAccountPersonCtrl = TextEditingController();
  final industryCtrl = TextEditingController();
  final marketSegmentCtrl = TextEditingController();
  final supplierNameCtrl = TextEditingController();
  final supplierContactCtrl = TextEditingController();
  final remarksCtrl = TextEditingController();
  const reasons = [
    "The right contact person is not available",
    "Company performance is going down",
    "Not Suitable solution with us",
  ];
  String reason = reasons.first;

  crmShowSheet(context, (ctx) {
    return StatefulBuilder(
      builder: (ctx, setState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            crmSheetTitle("No Opportunity"),
            SizedBox(height: 16.h),
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
                      color: AppColor.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(Icons.person_add_alt_1_rounded,
                        color: AppColor.primary, size: 20.sp),
                  ),
                ),
              ],
            ),
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
            SizedBox(height: 12.h),
            crmFieldLabel("Reason for No Opportunity"),
            SizedBox(height: 6.h),
            crmDropdown(reason, reasons, (v) => setState(() => reason = v!)),
            SizedBox(height: 12.h),
            crmField(remarksCtrl, "Remarks (optional)", maxLines: 3),
            SizedBox(height: 20.h),
            crmSaveButton("Save", () {
              if (customerCtrl.text.trim().isEmpty || keyAccountPersonCtrl.text.trim().isEmpty) {
                Get.snackbar("Missing Info", "Please enter a customer and key account person.",
                    snackPosition: SnackPosition.BOTTOM);
                return;
              }
              final lines = <CrmDetailLine>[
                details.dateLine,
                details.modeLine,
                details.agendaLine,
                CrmDetailLine(Icons.info_outline_rounded, reason),
                if (industryCtrl.text.trim().isNotEmpty)
                  CrmDetailLine(Icons.factory_outlined, industryCtrl.text.trim()),
              ];
              controller.addVisit(CrmListItem(title: customerCtrl.text.trim(), lines: lines));
              Navigator.pop(ctx);
            }),
          ],
        );
      },
    );
  });
}
