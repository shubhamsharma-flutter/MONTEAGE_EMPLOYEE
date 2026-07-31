import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/crm_controller.dart';
import '../models/crm_event_model.dart';
import 'crm_forms.dart';

// Two tabs: "Event Details" lists every contact captured so far, "Add Event"
// is the entry form. Saving on the form switches back to the list tab so
// the new entry is immediately visible.
class CrmEventDetailsScreen extends StatefulWidget {
  final CrmController controller;
  const CrmEventDetailsScreen({super.key, required this.controller});

  @override
  State<CrmEventDetailsScreen> createState() => _CrmEventDetailsScreenState();
}

class _CrmEventDetailsScreenState extends State<CrmEventDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1ED),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F1ED),
        elevation: 0,
        title: Text(
          "Event",
          style: GoogleFonts.manrope(
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF241917),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6A3027),
          unselectedLabelColor: const Color(0xFF8B7D77),
          indicatorColor: const Color(0xFF6A3027),
          labelStyle: GoogleFonts.manrope(fontSize: 13.sp, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: "Event Details"),
            Tab(text: "Add Event"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _EventDetailsTab(controller: widget.controller),
          _AddEventTab(
            controller: widget.controller,
            onSaved: () => _tabController.animateTo(0),
          ),
        ],
      ),
    );
  }
}

class _EventDetailsTab extends StatelessWidget {
  final CrmController controller;
  const _EventDetailsTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final events = controller.events;
      if (events.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_outlined, size: 52.sp, color: const Color(0xFF8B7D77)),
              SizedBox(height: 12.h),
              Text(
                "No events yet.",
                style: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF8B7D77)),
              ),
            ],
          ),
        );
      }
      return ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: events.length,
        itemBuilder: (_, i) => _EventCard(event: events[i]),
      );
    });
  }
}

class _EventCard extends StatelessWidget {
  final CrmEvent event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFEDE2DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.eventName.isEmpty ? event.contactName : event.eventName,
            style: GoogleFonts.manrope(
              fontSize: 14.5.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF241917),
            ),
          ),
          SizedBox(height: 8.h),
          _line(Icons.person_outline_rounded, event.contactName),
          if (event.companyName.isNotEmpty) _line(Icons.business_outlined, event.companyName),
          if (event.designation.isNotEmpty) _line(Icons.badge_outlined, event.designation),
          if (event.city.isNotEmpty) _line(Icons.location_on_outlined, event.city),
          _line(Icons.call_outlined, event.mobileNumber),
          if (event.email.isNotEmpty) _line(Icons.email_outlined, event.email),
          if (event.discussionNotes.isNotEmpty)
            _line(Icons.notes_outlined, event.discussionNotes),
          if (event.remarks.isNotEmpty) _line(Icons.comment_outlined, event.remarks),
        ],
      ),
    );
  }

  Widget _line(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13.sp, color: const Color(0xFF6A3027)),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF8B7D77)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddEventTab extends StatefulWidget {
  final CrmController controller;
  final VoidCallback onSaved;
  const _AddEventTab({required this.controller, required this.onSaved});

  @override
  State<_AddEventTab> createState() => _AddEventTabState();
}

class _AddEventTabState extends State<_AddEventTab> {
  final eventNameCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final contactNameCtrl = TextEditingController();
  final companyNameCtrl = TextEditingController();
  final designationCtrl = TextEditingController();
  final mobileNumberCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final discussionNotesCtrl = TextEditingController();
  final remarksCtrl = TextEditingController();

  @override
  void dispose() {
    eventNameCtrl.dispose();
    cityCtrl.dispose();
    contactNameCtrl.dispose();
    companyNameCtrl.dispose();
    designationCtrl.dispose();
    mobileNumberCtrl.dispose();
    emailCtrl.dispose();
    discussionNotesCtrl.dispose();
    remarksCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (contactNameCtrl.text.trim().isEmpty || mobileNumberCtrl.text.trim().isEmpty) {
      Get.snackbar(
        "Missing Info",
        "Please enter a contact name and mobile number.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    widget.controller.addEvent(CrmEvent(
      eventName: eventNameCtrl.text.trim(),
      city: cityCtrl.text.trim(),
      contactName: contactNameCtrl.text.trim(),
      companyName: companyNameCtrl.text.trim(),
      designation: designationCtrl.text.trim(),
      mobileNumber: mobileNumberCtrl.text.trim(),
      email: emailCtrl.text.trim(),
      discussionNotes: discussionNotesCtrl.text.trim(),
      remarks: remarksCtrl.text.trim(),
    ));
    eventNameCtrl.clear();
    cityCtrl.clear();
    contactNameCtrl.clear();
    companyNameCtrl.clear();
    designationCtrl.clear();
    mobileNumberCtrl.clear();
    emailCtrl.clear();
    discussionNotesCtrl.clear();
    remarksCtrl.clear();
    Get.snackbar(
      "Saved",
      "Event contact added.",
      backgroundColor: Colors.green.shade50,
      colorText: Colors.green.shade800,
      snackPosition: SnackPosition.BOTTOM,
    );
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        crmFieldLabel("Event Name"),
        SizedBox(height: 6.h),
        crmField(eventNameCtrl, "Enter event name"),
        SizedBox(height: 12.h),
        crmFieldLabel("City"),
        SizedBox(height: 6.h),
        crmField(cityCtrl, "Enter city"),
        SizedBox(height: 12.h),
        crmFieldLabel("Contact Name *"),
        SizedBox(height: 6.h),
        crmField(contactNameCtrl, "Enter contact name"),
        SizedBox(height: 12.h),
        crmFieldLabel("Company Name"),
        SizedBox(height: 6.h),
        crmField(companyNameCtrl, "Enter company name"),
        SizedBox(height: 12.h),
        crmFieldLabel("Designation"),
        SizedBox(height: 6.h),
        crmField(designationCtrl, "Enter designation"),
        SizedBox(height: 12.h),
        crmFieldLabel("Mobile Number *"),
        SizedBox(height: 6.h),
        crmField(mobileNumberCtrl, "Enter mobile number", keyboardType: TextInputType.phone),
        SizedBox(height: 12.h),
        crmFieldLabel("Email Address (optional)"),
        SizedBox(height: 6.h),
        crmField(emailCtrl, "Enter email address", keyboardType: TextInputType.emailAddress),
        SizedBox(height: 12.h),
        crmFieldLabel("Discussion Notes"),
        SizedBox(height: 6.h),
        crmField(discussionNotesCtrl, "Enter discussion notes", maxLines: 3),
        SizedBox(height: 12.h),
        crmFieldLabel("Remarks"),
        SizedBox(height: 6.h),
        crmField(remarksCtrl, "Enter remarks", maxLines: 3),
        SizedBox(height: 20.h),
        crmSaveButton("Save", _save),
      ],
    );
  }
}
