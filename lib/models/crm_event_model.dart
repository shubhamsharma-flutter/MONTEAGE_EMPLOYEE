// One event contact captured from the "Add Event" tab. There is no CRM
// backend yet, so these only live in CrmController for the session.

class CrmEvent {
  final String eventName;
  final String city;
  final String contactName;
  final String companyName;
  final String designation;
  final String mobileNumber;
  final String email;
  final String discussionNotes;
  final String remarks;

  CrmEvent({
    required this.eventName,
    required this.city,
    required this.contactName,
    required this.companyName,
    required this.designation,
    required this.mobileNumber,
    required this.email,
    required this.discussionNotes,
    required this.remarks,
  });
}
