import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart' hide Data;
import 'package:http/http.dart' as http;

import '../models/myleavelistmode.dart';

class LeaveApproval {
  final String approver;
  final String status;
  final String approvedBy;

  LeaveApproval({
    required this.approver,
    required this.status,
    required this.approvedBy,
  });

  factory LeaveApproval.fromApi(String approver, String? status, String? by) {
    final trimmed = (status ?? '').trim();
    return LeaveApproval(
      approver: approver,
      status: trimmed.isEmpty ? 'Pending' : trimmed,
      approvedBy: (by ?? '').trim(),
    );
  }
}

const List<String> leaveStatusFilters = [
  'Total',
  'Pending',
  'Approved',
  'Rejected',
];

void logLeaveApi(String message) {
  if (kDebugMode) debugPrint('[LeaveAPI] $message');
}

/// Index of the approval a designation signs: 0 = Team Leader, 1 = Project
/// Manager, 2 = HR Manager. Null when it doesn't approve leaves.
int? approverIndexFor(String rawDesignation) {
  final designation = rawDesignation.toLowerCase();
  if (RegExp(r'\bhr\b').hasMatch(designation) ||
      designation.contains('human resource')) {
    return 2;
  }
  if (designation.contains('project') && designation.contains('manager')) {
    return 1;
  }
  if (designation.contains('team') && designation.contains('lead')) return 0;
  return null;
}

int? approverIndex(GetStorage box) => approverIndexFor(
  (box.read('Designation') ?? box.read('designation') ?? '').toString(),
);

/// Whether an applicant's leave still needs this approver; an applicant's own
/// role and the roles below it are approved automatically:
///   Employee        → Team Leader, Project Manager, HR Manager
///   Team Leader     → Project Manager, HR Manager
///   Project Manager → HR Manager
///   HR Manager      → Project Manager
bool waitsOnApprover(int? applicantIndex, int approver) =>
    approver == 0 ? applicantIndex == null : applicantIndex != approver;

String overallLeaveStatus(List<LeaveApproval> approvals) {
  if (approvals.any((a) => a.status == 'Rejected')) return 'Rejected';
  if (approvals.every((a) => a.status == 'Approved')) return 'Approved';
  return 'Pending';
}

/// The API sends 0001-01-01 when a date is not set.
DateTime? parseLeaveDate(String? raw) {
  final date = DateTime.tryParse(raw ?? '');
  if (date == null || date.year <= 1) return null;
  return date;
}

class LeaveListController extends GetxController {
  static const String _baseUrl =
      'https://montempep.eduagentapp.com/api/MonteageEmpErp';

  final GetStorage box = GetStorage();

  final RxList<Data> leaves = <Data>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString selectedFilter = 'Total'.obs;

  List<Data> get filteredLeaves {
    if (selectedFilter.value == 'Total') return leaves;
    return leaves.where((l) => statusOf(l) == selectedFilter.value).toList();
  }

  int countFor(String filter) {
    if (filter == 'Total') return leaves.length;
    return leaves.where((l) => statusOf(l) == filter).length;
  }

  // Approvers the applicant still waits on; their own role's approvals are
  // automatic, so they are left out:
  //   Employee        → Team Leader, Project Manager, HR Manager
  //   Team Leader     → Project Manager, HR Manager
  //   Project Manager → HR Manager
  //   HR Manager      → Project Manager
  List<LeaveApproval> approvalsOf(Data leave) {
    final index = approverIndex(box);
    return [
      if (waitsOnApprover(index, 0))
        LeaveApproval.fromApi(
          'Team Leader',
          leave.approveStatus1,
          leave.approveby1,
        ),
      if (waitsOnApprover(index, 1))
        LeaveApproval.fromApi(
          'Project Manager',
          leave.approveStatus2,
          leave.approveby2,
        ),
      if (waitsOnApprover(index, 2))
        LeaveApproval.fromApi(
          'HR Manager',
          leave.approveStatus3,
          leave.approveby3,
        ),
    ];
  }

  String statusOf(Data leave) => overallLeaveStatus(approvalsOf(leave));

  @override
  void onInit() {
    super.onInit();
    fetchLeaveList();
  }

  Future<void> fetchLeaveList() async {
    final empId = (box.read('EmployeeId') ?? '').toString().trim();
    if (empId.isEmpty) {
      errorMessage.value = 'Employee not found. Please log in again.';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';
    try {
      final token = (box.read('access_token') ?? '').toString().trim();
      final response = await http.get(
        Uri.parse('$_baseUrl/MobEmployeeLeaveList/$empId'),
        headers: {
          'Accept': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        errorMessage.value =
            'Could not load leave list (${response.statusCode})';
        return;
      }

      final body = myleavelist.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );

      // Rows without real dates are not applied leaves.
      final applied = (body.data ?? [])
          .where(
            (l) =>
                parseLeaveDate(l.fromDate) != null &&
                parseLeaveDate(l.toDate) != null,
          )
          .toList();
      applied.sort(
        (a, b) =>
            parseLeaveDate(b.fromDate)!.compareTo(parseLeaveDate(a.fromDate)!),
      );
      leaves.assignAll(applied);
    } catch (e) {
      errorMessage.value = 'Could not load leave list. Please try again.';
      print('fetchLeaveList error: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
