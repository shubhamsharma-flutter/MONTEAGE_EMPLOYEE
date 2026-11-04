import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart' hide Data;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/myleavemodel.dart';
import '../services/push_notification_service.dart';
import 'leave_list_controller.dart';

class LeaveTypeModel {
  final int leaveTypeId;
  final String leaveType;

  LeaveTypeModel({required this.leaveTypeId, required this.leaveType});

  factory LeaveTypeModel.fromJson(Map<String, dynamic> json) => LeaveTypeModel(
    leaveTypeId: json['LeaveTypeId'] ?? 0,
    leaveType: (json['LeaveType'] ?? '').toString().trim(),
  );
}

class LeaveManagementController extends GetxController {
  static const String _baseUrl =
      'https://montempep.eduagentapp.com/api/MonteageEmpErp';
  static const String _leaveSubmitUrl = '$_baseUrl/MObAddEmployyeLeaveA';
  static const String _leaveSubmitImageUrl =
      '$_baseUrl/MObAddEmployyeLeaveimageA';

  final GetStorage box = GetStorage();

  final RxList<Data> leaves = <Data>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Apply leave form
  final RxList<LeaveTypeModel> leaveTypes = <LeaveTypeModel>[].obs;
  final RxBool isLoadingTypes = false.obs;
  final RxBool isSubmitting = false.obs;
  final Rxn<LeaveTypeModel> selectedLeaveType = Rxn<LeaveTypeModel>();
  final Rxn<DateTime> fromDate = Rxn<DateTime>();
  final Rxn<DateTime> toDate = Rxn<DateTime>();
  final RxString prescriptionFileName = ''.obs;
  final RxString prescriptionFilePath = ''.obs;

  String get _empId => (box.read('EmployeeId') ?? '').toString().trim();

  Map<String, String> get _headers {
    final token = (box.read('access_token') ?? '').toString().trim();
    return {
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Team Leaders, HR Managers, Project Managers and Admins have a team view.
  bool get canViewTeamLeave {
    final designation =
        (box.read('Designation') ?? box.read('designation') ?? '')
            .toString()
            .toLowerCase();
    return designation.contains('admin') || approverIndex(box) != null;
  }

  // Approvals the applicant's own role already covers when they apply:
  //   Team Leader → Team Leader
  //   Manager     → Team Leader, Manager
  //   HR          → Team Leader, HR
  Map<String, String> get _initialApprovals {
    final index = approverIndex(box);

    String status(bool approved) => approved ? 'Approved' : 'Pending';
    return {
      'ApproveStatus1': status(index != null),
      'ApproveStatus2': status(index == 1),
      'ApproveStatus3': status(index == 2),
    };
  }

  int get numberOfDays {
    if (fromDate.value == null || toDate.value == null) return 0;
    final diff = toDate.value!.difference(fromDate.value!).inDays + 1;
    return diff > 0 ? diff : 0;
  }

  /// The MobEmployeeLeave row for the selected leave type, if there is one.
  Data? get _selectedLeaveRow {
    Data? row;
    for (final leave in leaves) {
      if (leave.leaveTypeId == selectedLeaveType.value?.leaveTypeId) {
        row = leave;
      }
    }
    return row;
  }

  /// Balance for one leave type, or null if no row exists for it.
  int? balanceFor(int leaveTypeId) {
    int? balance;
    for (final leave in leaves) {
      if (leave.leaveTypeId == leaveTypeId) balance = leave.totalBalanceLeave;
    }
    return balance;
  }

  /// Null when the balance is unknown; the backend still enforces the limit.
  int? get currentBalance => _selectedLeaveRow?.totalBalanceLeave;

  bool get exceedsBalance {
    final balance = currentBalance;
    return balance != null && numberOfDays > balance;
  }

  bool get needsPrescription =>
      selectedLeaveType.value?.leaveType.toUpperCase().contains('SICK') ??
      false;

  @override
  void onInit() {
    super.onInit();
    fetchMyLeaves();
    fetchLeaveTypes();
  }

  Future<void> fetchMyLeaves() async {
    if (_empId.isEmpty) {
      errorMessage.value = 'Employee not found. Please log in again.';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/MobEmployeeLeave/$_empId'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        errorMessage.value = 'Could not load leaves (${response.statusCode})';
        return;
      }

      final body = myleave.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
      leaves.assignAll(body.data ?? []);
    } catch (e) {
      errorMessage.value = 'Could not load leaves. Please try again.';
      print('fetchMyLeaves error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchLeaveTypes() async {
    isLoadingTypes.value = true;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/MobLeaveTypeBind'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['statuscode'] == 200 && body['data'] != null) {
          leaveTypes.assignAll(
            (body['data'] as List).map((e) => LeaveTypeModel.fromJson(e)),
          );
        }
      } else {
        showError('Could not load leave types (${response.statusCode})');
      }
    } catch (e) {
      showError('Could not load leave types. Please try again.');
      print('fetchLeaveTypes error: $e');
    } finally {
      isLoadingTypes.value = false;
    }
  }

  void selectLeaveType(LeaveTypeModel? type) {
    selectedLeaveType.value = type;
    // The attachment row is hidden for other types, so don't send it silently.
    if (!needsPrescription) setPrescription('', '');
  }

  void setFromDate(DateTime date) {
    fromDate.value = date;
    if (toDate.value != null && toDate.value!.isBefore(date)) {
      toDate.value = null;
    }
  }

  void setPrescription(String name, String path) {
    prescriptionFileName.value = name;
    prescriptionFilePath.value = path;
  }

  void resetForm() {
    selectedLeaveType.value = null;
    fromDate.value = null;
    toDate.value = null;
    setPrescription('', '');
  }

  /// Returns true when the leave was accepted by the server.
  Future<bool> submitLeave({required String reason}) async {
    if (selectedLeaveType.value == null ||
        fromDate.value == null ||
        toDate.value == null) {
      return false;
    }

    final employeeId = int.tryParse(_empId);
    if (employeeId == null) {
      showError('Employee not found. Please log in again.');
      return false;
    }

    isSubmitting.value = true;
    try {
      final hasFile = prescriptionFilePath.value.isNotEmpty;
      String? fileBase64;
      if (hasFile) {
        final bytes = await File(prescriptionFilePath.value).readAsBytes();
        fileBase64 = base64Encode(bytes);
      }

      final fields = {
        "EmployeeLeaveId": _selectedLeaveRow?.employeeLeaveId ?? 0,
        "EmployeeId": employeeId,
        "LeaveTypeId": selectedLeaveType.value!.leaveTypeId,
        "LeaveReason": reason,
        "FromDate": DateFormat('yyyy-MM-dd').format(fromDate.value!),
        "ToDate": DateFormat('yyyy-MM-dd').format(toDate.value!),
        "LeaveNoofday": numberOfDays,
        "DescriptionImageFile": fileBase64,
        ..._initialApprovals,
      };
      final submitUrl = hasFile ? _leaveSubmitImageUrl : _leaveSubmitUrl;

      logLeaveApi(
        'designation="${box.read('Designation')}" '
        'approverIndex=${approverIndex(box)}',
      );
      logLeaveApi(
        'APPLY POST $submitUrl\n${jsonEncode({...fields, "DescriptionImageFile": fileBase64 == null ? null : '<base64 ${fileBase64.length} chars>'})}',
      );

      final response = await http.post(
        Uri.parse(submitUrl),
        headers: {..._headers, 'Content-Type': 'application/json'},
        body: jsonEncode(fields),
      );
      logLeaveApi('APPLY RESPONSE ${response.statusCode}\n${response.body}');

      if (response.statusCode != 200) {
        showError('Server error (${response.statusCode})');
        return false;
      }

      final body = jsonDecode(response.body);
      if (body['statuscode'] != 200) {
        showError((body['message'] ?? 'Submission failed.').toString());
        return false;
      }

      final approvalsSaved =
          approverIndex(box) == null ||
          await _saveInitialApprovals(
            leaveTypeId: selectedLeaveType.value!.leaveTypeId,
            from: fromDate.value!,
            to: toDate.value!,
          );

      // Runs in the background so a slow or failed push can't hold up the form.
      _notifyApprovers(
        leaveType: selectedLeaveType.value!.leaveType,
        from: fromDate.value!,
        to: toDate.value!,
        days: numberOfDays,
      );

      fetchMyLeaves();
      Get.snackbar(
        'Submitted',
        approvalsSaved
            ? 'Leave request submitted successfully.'
            : 'Leave submitted, but the automatic approval could not be saved.',
        backgroundColor: Colors.green.shade50,
        colorText: Colors.green.shade800,
        snackPosition: SnackPosition.TOP,
      );
      return true;
    } catch (e) {
      showError('Could not submit leave. Please try again.');
      print('submitLeave error: $e');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // The apply API returns no ELeaveAId and leaves new requests Pending, so find
  // the new leave in the list and set the role's approvals on MObeaveApprove.
  Future<bool> _saveInitialApprovals({
    required int leaveTypeId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final listResponse = await http.get(
        Uri.parse('$_baseUrl/MobEmployeeLeaveList/$_empId'),
        headers: _headers,
      );
      if (listResponse.statusCode != 200) return false;

      final list = myleave.fromJson(
        jsonDecode(listResponse.body) as Map<String, dynamic>,
      );

      // The highest ELeaveAId is the newest match if dates were applied twice.
      int? eLeaveAId;
      for (final leave in list.data ?? <Data>[]) {
        final leaveFrom = DateTime.tryParse(leave.fromDate ?? '');
        final leaveTo = DateTime.tryParse(leave.toDate ?? '');
        final id = leave.eLeaveAId ?? 0;
        if (leave.leaveTypeId == leaveTypeId &&
            DateUtils.isSameDay(leaveFrom, from) &&
            DateUtils.isSameDay(leaveTo, to) &&
            id > (eLeaveAId ?? 0)) {
          eLeaveAId = id;
        }
      }
      logLeaveApi(
        'LEAVE LIST ${listResponse.statusCode}: '
        '${list.data?.length ?? 0} rows, matched ELeaveAId=$eLeaveAId',
      );
      if (eLeaveAId == null) return false;

      final payload = jsonEncode({
        "ELeaveAId": eLeaveAId,
        ..._initialApprovals,
        "Approveby1": '',
        "Approveby2": '',
        "Approveby3": '',
      });
      logLeaveApi('AUTO APPROVE POST MObeaveApprove\n$payload');

      final response = await http.post(
        Uri.parse('$_baseUrl/MObeaveApprove'),
        headers: {..._headers, 'Content-Type': 'application/json'},
        body: payload,
      );
      logLeaveApi(
        'AUTO APPROVE RESPONSE ${response.statusCode}\n${response.body}',
      );
      if (response.statusCode != 200) return false;

      return jsonDecode(response.body)['statuscode'] == 200;
    } catch (e) {
      print('saveInitialApprovals error: $e');
      return false;
    }
  }

  Future<bool> _isInTeamOf(String teamLeaderId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/MObTeamLeaderTeamList/$teamLeaderId'),
        headers: _headers,
      );
      if (response.statusCode != 200) return false;

      final team = (jsonDecode(response.body)['data'] as List?) ?? [];
      return team.any((member) => member['EmployeeId']?.toString() == _empId);
    } catch (e) {
      logLeaveApi('NOTIFY team lookup failed for $teamLeaderId: $e');
      return false;
    }
  }

  // Notifies the approvers this leave still needs: the applicant's own Team
  // Leaders, plus everyone holding the Project Manager or HR Manager role.
  Future<void> _notifyApprovers({
    required String leaveType,
    required DateTime from,
    required DateTime to,
    required int days,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/MobEmployeelist'),
        headers: _headers,
      );
      if (response.statusCode != 200) {
        logLeaveApi('NOTIFY employee list failed: ${response.statusCode}');
        return;
      }

      final applicantIndex = approverIndex(box);
      final employees = (jsonDecode(response.body)['data'] as List?) ?? [];
      final recipients = <String>{};
      for (final employee in employees) {
        final id = (employee['EmployeeId'] ?? '').toString();
        final index = approverIndexFor(
          (employee['Designation'] ?? '').toString(),
        );
        if (id.isEmpty ||
            id == _empId ||
            index == null ||
            !waitsOnApprover(applicantIndex, index)) {
          continue;
        }
        // Team Leaders are only notified for people in their own team.
        if (index != 0 || await _isInTeamOf(id)) recipients.add(id);
      }

      final name = (box.read('EmployeeName') ?? 'An employee').toString();
      final dates = DateFormat('dd MMM yyyy');
      final body =
          '$name applied for $leaveType: ${dates.format(from)} to '
          '${dates.format(to)} ($days ${days == 1 ? 'day' : 'days'})';

      var sent = 0;
      for (final id in recipients) {
        final delivered = await PushNotificationService.instance.sendToEmployee(
          employeeId: id,
          title: 'New Leave Request',
          body: body,
          data: {'type': 'leave_applied'},
        );
        if (delivered) sent++;
      }
      logLeaveApi('NOTIFY sent $sent of ${recipients.length}: $recipients');
    } catch (e) {
      logLeaveApi('NOTIFY error: $e');
    }
  }

  void showError(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red.shade50,
      colorText: Colors.red.shade800,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
    );
  }
}
