import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/crm_meeting_model.dart';
import '../models/crm_list_item_model.dart';
import '../models/crm_event_model.dart';

// Holds meetings scheduled from the CRM home screen's FAB. There is no CRM
// backend yet, so this list only lives locally for the session — once a
// real CRM API exists, load/save through it here instead.
class CrmController extends GetxController {
  // Static sample meetings so the schedule views aren't empty — remove
  // once real CRM data is wired in.
  final meetings = <CrmMeeting>[
    CrmMeeting(
      title: "Product Demo Call",
      dateTime: DateTime.now().add(const Duration(hours: 3)),
      clientName: "Aarav Textiles Pvt Ltd",
      clientDetails: "+91 98765 43210 · aarav.textiles@example.com",
      notes: "Show the new packaging line features.",
    ),
    CrmMeeting(
      title: "Follow-up Meeting",
      dateTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
      clientName: "Meera Foods & Beverages",
      clientDetails: "+91 91234 56780 · meera.foods@example.com",
      notes: "Discuss pricing for shrink wrapping order.",
    ),
    CrmMeeting(
      title: "Quarterly Review",
      dateTime: DateTime.now().add(const Duration(days: 4)),
      clientName: "Kiran Pharma Packaging",
      clientDetails: "+91 99887 66554 · kiran.pharma@example.com",
      notes: "",
    ),
    CrmMeeting(
      title: "Contract Renewal Discussion",
      dateTime: DateTime.now().add(const Duration(days: 12)),
      clientName: "Sunrise Beverages",
      clientDetails: "+91 90000 11122 · sunrise.bev@example.com",
      notes: "Renewal due end of month.",
    ),
  ].obs;

  void addMeeting(CrmMeeting meeting) {
    meetings.add(meeting);
    meetings.sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  // Static sample opportunities — remove once real CRM data is wired in.
  final opportunities = <CrmListItem>[
    CrmListItem(title: "Aarav Textiles Pvt Ltd", lines: const [
      CrmDetailLine(Icons.call_outlined, "+91 98765 43210"),
      CrmDetailLine(Icons.email_outlined, "aarav.textiles@example.com"),
      CrmDetailLine(Icons.category_outlined, "Bottle Blow Moulding"),
    ]),
    CrmListItem(title: "Meera Foods & Beverages", lines: const [
      CrmDetailLine(Icons.call_outlined, "+91 91234 56780"),
      CrmDetailLine(Icons.email_outlined, "meera.foods@example.com"),
      CrmDetailLine(Icons.category_outlined, "Shrink Wrapping"),
    ]),
    CrmListItem(title: "Kiran Pharma Packaging", lines: const [
      CrmDetailLine(Icons.call_outlined, "+91 99887 66554"),
      CrmDetailLine(Icons.email_outlined, "kiran.pharma@example.com"),
      CrmDetailLine(Icons.category_outlined, "Case Packing & Palletizing"),
    ]),
  ].obs;

  void addOpportunity(CrmListItem item) {
    opportunities.insert(0, item);
  }

  // Static sample visits — remove once real CRM data is wired in.
  final visits = <CrmListItem>[
    CrmListItem(title: "Sunrise Beverages", lines: const [
      CrmDetailLine(Icons.calendar_today_outlined, "20 Jul 2026"),
      CrmDetailLine(Icons.call_outlined, "+91 90000 11122"),
      CrmDetailLine(Icons.email_outlined, "sunrise.bev@example.com"),
      CrmDetailLine(Icons.category_outlined, "Filling & Capping"),
    ]),
    CrmListItem(title: "Greenline Foods", lines: const [
      CrmDetailLine(Icons.calendar_today_outlined, "25 Jul 2026"),
      CrmDetailLine(Icons.call_outlined, "+91 90111 22334"),
      CrmDetailLine(Icons.email_outlined, "greenline.foods@example.com"),
      CrmDetailLine(Icons.category_outlined, "Labelling"),
    ]),
  ].obs;

  void addVisit(CrmListItem item) {
    visits.insert(0, item);
  }

  // Event contacts captured via the Event Details screen's "Add Event" tab.
  final events = <CrmEvent>[].obs;

  void addEvent(CrmEvent event) {
    events.insert(0, event);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<CrmMeeting> get todaysMeetings {
    final now = DateTime.now();
    return meetings.where((m) => _isSameDay(m.dateTime, now)).toList();
  }

  List<CrmMeeting> get tomorrowsMeetings {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return meetings.where((m) => _isSameDay(m.dateTime, tomorrow)).toList();
  }

  List<CrmMeeting> get thisWeeksMeetings {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    return meetings
        .where((m) =>
            m.dateTime.isAfter(startOfWeek) && m.dateTime.isBefore(endOfWeek))
        .toList();
  }

  List<CrmMeeting> get thisMonthsMeetings {
    final now = DateTime.now();
    return meetings
        .where((m) => m.dateTime.year == now.year && m.dateTime.month == now.month)
        .toList();
  }
}
