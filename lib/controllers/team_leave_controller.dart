import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart' hide Data;
import 'package:http/http.dart' as http;

import '../models/teameleavemodel.dart';
import 'leave_list_controller.dart';

class TeamLeaveController extends GetxController {
  static const String _baseUrl =
      'https://montempep.eduagentapp.com/api/MonteageEmpErp';

  final GetStorage box = GetStorage();

  final RxList<Data> leaves = <Data>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString selectedFilter = 'Total'.obs;

  /// ELeaveAId of the leave being approved or rejected right now.
  final RxnInt decidingLeaveId = RxnInt();

  String get _empId => (box.read('EmployeeId') ?? '').toString().trim();

  Map<String, String> get _headers {
    final token = (box.read('access_token') ?? '').toString().trim();
    return {
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  List<Data> get filteredLeaves {
    if (selectedFilter.value == 'Total') return leaves;
    return leaves.where((l) => statusOf(l) == selectedFilter.value).toList();
  }

  int countFor(String filter) {
    if (filter == 'Total') return leaves.length;
    return leaves.where((l) => statusOf(l) == filter).length;
  }

  List<LeaveApproval> approvalsOf(Data leave) => [
    LeaveApproval.fromApi(
      'Team Leader',
      leave.approveStatus1,
      leave.approveby1,
    ),
    LeaveApproval.fromApi(
      'Project Manager',
      leave.approveStatus2,
      leave.approveby2,
    ),
    LeaveApproval.fromApi('HR Manager', leave.approveStatus3, leave.approveby3),
  ];

  String statusOf(Data leave) => overallLeaveStatus(approvalsOf(leave));

  /// A Team Leader, HR Manager or Project Manager can decide on someone else's
  /// leave while their own approval and the overall status are still pending.
  bool canDecide(Data leave) {
    final index = approverIndex(box);
    return index != null &&
        (leave.eLeaveAId ?? 0) > 0 &&
        leave.employeeId?.toString() != _empId &&
        statusOf(leave) == 'Pending' &&
        approvalsOf(leave)[index].status == 'Pending';
  }

  int get awaitingDecisionCount => leaves.where(canDecide).length;

  /// [decision] is 'Approved' or 'Rejected'.
  Future<void> decideLeave(Data leave, String decision) async {
    if (decidingLeaveId.value != null) return;

    final leaveId = leave.eLeaveAId;
    decidingLeaveId.value = leaveId;
    try {
      // The API overwrites all three approval slots, so reload first to avoid
      // wiping a decision HR or the Project Manager made after this list loaded.
      if (!await fetchTeamLeaves()) return;

      final latest = leaves.firstWhereOrNull((l) => l.eLeaveAId == leaveId);
      if (latest == null || !canDecide(latest)) {
        _showError('This leave has already been updated.');
        return;
      }

      // Only this person's approval changes; the other two are sent back as is.
      final index = approverIndex(box)!;
      final approvals = approvalsOf(latest);
      final name = (box.read('EmployeeName') ?? '').toString().trim();
      String statusAt(int i) => i == index ? decision : approvals[i].status;
      String approverAt(int i) => i == index
          ? (name.isEmpty ? approvals[i].approver : name)
          : approvals[i].approvedBy;

      final payload = jsonEncode({
        "ELeaveAId": leaveId,
        "ApproveStatus1": statusAt(0),
        "ApproveStatus2": statusAt(1),
        "ApproveStatus3": statusAt(2),
        "Approveby1": approverAt(0),
        "Approveby2": approverAt(1),
        "Approveby3": approverAt(2),
      });
      logLeaveApi('DECISION POST MObeaveApprove\n$payload');

      final response = await http.post(
        Uri.parse('$_baseUrl/MObeaveApprove'),
        headers: {..._headers, 'Content-Type': 'application/json'},
        body: payload,
      );
      logLeaveApi('DECISION RESPONSE ${response.statusCode}\n${response.body}');

      if (response.statusCode != 200) {
        _showError('Server error (${response.statusCode})');
        return;
      }

      final body = jsonDecode(response.body);
      if (body['statuscode'] != 200) {
        _showError((body['message'] ?? 'Action failed.').toString());
        return;
      }

      final approved = decision == 'Approved';
      Get.snackbar(
        decision,
        'Leave has been ${decision.toLowerCase()}.',
        backgroundColor: approved ? Colors.green.shade50 : Colors.red.shade50,
        colorText: approved ? Colors.green.shade800 : Colors.red.shade800,
        snackPosition: SnackPosition.TOP,
      );

      // Show the decision straight away; the background reload confirms it.
      latest
        ..approveStatus1 = statusAt(0)
        ..approveStatus2 = statusAt(1)
        ..approveStatus3 = statusAt(2)
        ..approveby1 = approverAt(0)
        ..approveby2 = approverAt(1)
        ..approveby3 = approverAt(2);
      leaves.refresh();
      fetchTeamLeaves();
    } catch (e) {
      _showError('Could not update leave. Please try again.');
      print('decideLeave error: $e');
    } finally {
      decidingLeaveId.value = null;
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red.shade50,
      colorText: Colors.red.shade800,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void onInit() {
    super.onInit();
    _loadCachedLeaves();
    fetchTeamLeaves();
  }

  String get _cacheKey => 'team_leaves_$_empId';

  // Shows the last loaded list instantly while the fresh one loads.
  void _loadCachedLeaves() {
    final cached = box.read<List>(_cacheKey);
    if (cached == null) return;
    leaves.assignAll(
      cached.map((e) => Data.fromJson(Map<String, dynamic>.from(e as Map))),
    );
  }

  // Keeps showing the last loaded list when a refresh fails.
  void _setLoadError(String message) {
    if (leaves.isEmpty) {
      errorMessage.value = message;
    } else {
      _showError(message);
    }
  }

  /// Returns false when the list couldn't be refreshed.
  Future<bool> fetchTeamLeaves() async {
    if (_empId.isEmpty) {
      errorMessage.value = 'Employee not found. Please log in again.';
      return false;
    }

    isLoading.value = true;
    errorMessage.value = '';
    final stopwatch = Stopwatch()..start();
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/MobTeamEmployeeLeaveList/$_empId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 20));
      final requestMs = stopwatch.elapsedMilliseconds;

      if (response.statusCode != 200) {
        _setLoadError('Could not load team leaves (${response.statusCode})');
        return false;
      }

      final body = await compute(_parseTeamLeaves, response.body);

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
      logLeaveApi(
        'TEAM LEAVES for $_empId: statuscode=${body.statuscode} '
        'message=${body.message} rows=${body.data?.length ?? 0} '
        'kept=${applied.length} bytes=${response.bodyBytes.length} '
        'request=${requestMs}ms total=${stopwatch.elapsedMilliseconds}ms '
        'sampleDates=${body.data?.take(3).map((l) => '${l.fromDate}|${l.toDate}').toList()}',
      );
      leaves.assignAll(applied);
      box.write(_cacheKey, applied.map((l) => l.toJson()).toList());
      return true;
    } catch (e) {
      _setLoadError('Could not load team leaves. Please try again.');
      print('fetchTeamLeaves error: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}

// Top-level so compute() can decode large responses off the UI thread.
teameleave _parseTeamLeaves(String body) =>
    teameleave.fromJson(jsonDecode(body) as Map<String, dynamic>);
