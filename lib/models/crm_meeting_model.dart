// A locally-stored meeting/schedule entry. There is no CRM backend yet,
// so meetings only live in memory for this session — once a real CRM API
// exists, swap CrmController's local list for real fetch/save calls.

class CrmMeeting {
  final String title;
  final DateTime dateTime;
  final String clientName;
  final String clientDetails;
  final String notes;
  final List<String> attendees;

  CrmMeeting({
    required this.title,
    required this.dateTime,
    required this.clientName,
    required this.clientDetails,
    required this.notes,
    this.attendees = const [],
  });
}
