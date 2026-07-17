import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

class LeaveTypeModel {
  final int leaveTypeId;
  final String leaveType;

  LeaveTypeModel({required this.leaveTypeId, required this.leaveType});

  factory LeaveTypeModel.fromJson(Map<String, dynamic> json) => LeaveTypeModel(
        leaveTypeId: json['LeaveTypeId'] ?? 0,
        leaveType: (json['LeaveType'] ?? '').toString().trim(),
      );
}

class EmployeeLeaveModel {
 final int employeeLeaveId;
  final int eLeaveAId;
  final int employeeId;
  final String employeeCode;
  final String employeeName;
  final int leaveTypeId;
  final String leaveType;
  final String years;
  final int totalLeave;
  final int totalBalanceLeave;
  final String? leaveReason;
  final int leaveNoDays;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? descriptionImageFile;
  final String approveStatus1;
  final String approveStatus2;
  final String approveStatus3;
  final String approveby1;
  final String approveby2;
  final String approveby3;
  final DateTime? createdDate;
  final bool isActive;

 EmployeeLeaveModel({
    required this.employeeLeaveId,
    required this.eLeaveAId,
    required this.employeeId,
    required this.employeeCode,
    required this.employeeName,
    required this.leaveTypeId,
    required this.leaveType,
    required this.years,
    required this.totalLeave,
    required this.totalBalanceLeave,
    this.leaveReason,
    required this.leaveNoDays,
    this.fromDate,
    this.toDate,
    this.descriptionImageFile,
    required this.approveStatus1,
    required this.approveStatus2,
    required this.approveStatus3,
    required this.approveby1,
    required this.approveby2,
    required this.approveby3,
    this.createdDate,
    required this.isActive,
  });

  factory EmployeeLeaveModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      final dt = DateTime.tryParse(val.toString());
      if (dt == null || dt.year <= 1) return null;
      return dt;
    }

    return EmployeeLeaveModel(
      employeeLeaveId: json['EmployeeLeaveId'] ?? 0,
      eLeaveAId: json['ELeaveAId'] ?? 0,
      employeeId: json['EmployeeId'] ?? 0,
      employeeCode: json['EmployeeCode']?.toString() ?? '',
      employeeName: json['EmployeeName']?.toString() ?? '',
      leaveTypeId: json['LeaveTypeId'] ?? 0,
      leaveType: (json['LeaveType'] ?? '').toString().trim(),
      years: json['Years']?.toString() ?? '',
      totalLeave: json['TotalLeave'] ?? 0,
      totalBalanceLeave: json['TotalBalanceLeave'] ?? 0,
      leaveReason: json['LeaveReason']?.toString(),
      leaveNoDays: json['LeaveNoofday'] ?? 0,
      fromDate: parseDate(json['FromDate']),
      toDate: parseDate(json['ToDate']),
      descriptionImageFile: json['DescriptionImageFile']?.toString(),
      approveStatus1: json['ApproveStatus1']?.toString() ?? 'Pending',
      approveStatus2: json['ApproveStatus2']?.toString() ?? 'Pending',
      approveStatus3: json['ApproveStatus3']?.toString() ?? 'Pending',
      approveby1: json['Approveby1']?.toString() ?? '',
      approveby2: json['Approveby2']?.toString() ?? '',
      approveby3: json['Approveby3']?.toString() ?? '',
      createdDate: parseDate(json['CreatedDate']),
      isActive: json['IsActive'] ?? false,
    );
  }
}

// Model for MobEmployeeLeaveId — balance per leave type (the correct balance API)
class EmployeeLeaveBalanceModel {
  final int employeeLeaveId;
  final int employeeId;
  final int leaveTypeId;
  final String leaveType;
  final int totalLeave;
  final int totalTakenLeave;
  final int totalBalanceLeave;

  EmployeeLeaveBalanceModel({
    required this.employeeLeaveId,
    required this.employeeId,
    required this.leaveTypeId,
    required this.leaveType,
    required this.totalLeave,
    required this.totalTakenLeave,
    required this.totalBalanceLeave,
  });

  factory EmployeeLeaveBalanceModel.fromJson(Map<String, dynamic> json) =>
      EmployeeLeaveBalanceModel(
        employeeLeaveId: json['EmployeeLeaveId'] ?? 0,
        employeeId: json['EmployeeId'] ?? 0,
        leaveTypeId: json['LeaveTypeId'] ?? 0,
        leaveType: (json['LeaveType'] ?? '').toString().trim(),
        totalLeave: json['TotalLeave'] ?? 0,
        totalTakenLeave: json['TotalTakenLeave'] ?? 0,
        totalBalanceLeave: json['TotalBalanceLeave'] ?? 0,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// LEAVE BALANCE RULES (for display label only — backend enforces actual)
//   PAID LEAVE   → 12 / year  (carry-forward)
//   SICK LEAVE   → 6  / year  (carry-forward)
//   SHORT LEAVE  → 2  / month (no carry-forward)
//   HALF DAY     → 2  / month (no carry-forward)
//   WFH          → 3  / month (no carry-forward)
// ─────────────────────────────────────────────────────────────────────────────

bool isMonthlyLeave(String leaveType) {
  final lt = leaveType.toUpperCase().trim();
  return lt.contains('SHORT') ||
      lt.contains('HALF') ||
      lt.contains('WORK FROM HOME');
}

// ─────────────────────────────────────────────────────────────────────────────
// ROLE-BASED APPROVAL
//   Employee    → Team Leader, HR Manager, Project Manager
//   Team Leader → HR Manager, Project Manager
// ─────────────────────────────────────────────────────────────────────────────

enum EmployeeRole { employee, teamLeader, hrManager, projectManager, admin }

List<String> approversForRole(EmployeeRole role) {
  switch (role) {
    case EmployeeRole.employee:
      return ['Team Leader', 'HR Manager', 'Project Manager'];
    case EmployeeRole.teamLeader:
      return ['HR Manager', 'Project Manager'];
    case EmployeeRole.hrManager:
    case EmployeeRole.projectManager:
    case EmployeeRole.admin:
      return ['HR Manager'];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LEAVE CONTROLLER
// ─────────────────────────────────────────────────────────────────────────────

class LeaveController extends GetxController {
  // ── Config ────────────────────────────────────────────────────────────────
  static const String _baseUrl =
      'https://montempep.eduagentapp.com/api/MonteageEmpErp';
  static const String _leaveSubmitUrl = '$_baseUrl/MObAddEmployyeLeaveA';
  static const String _leaveSubmitImageUrl = '$_baseUrl/MObAddEmployyeLeaveimageA';

  // Read from the same GetStorage session box used across the app (see
  // login_controller.dart / project_controller.dart) — no manual wiring needed.
  final GetStorage box = GetStorage();
  String authToken = '';
  int employeeId = 0;
  EmployeeRole employeeRole = EmployeeRole.employee;

  // ── Observables ───────────────────────────────────────────────────────────
  final RxList<LeaveTypeModel> leaveTypes = <LeaveTypeModel>[].obs;
  final RxList<EmployeeLeaveModel> employeeLeaves = <EmployeeLeaveModel>[].obs;

  /// Leave/WFH history cards shown in list.
  final RxList<Map<String, dynamic>> leaveHistory =
      <Map<String, dynamic>>[].obs;

      /// Team member leaves shown to approver (TL/HR/PM view).
  final RxList<Map<String, dynamic>> teamLeaveHistory =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoadingTeamLeaves = false.obs;

  /// Balance per LeaveTypeId — from MobEmployeeLeaveId API (TotalBalanceLeave).
  final RxMap<int, int> leaveBalanceMap = <int, int>{}.obs;

  // UI state
  final RxBool isLoadingTypes = false.obs;
  final RxBool isLoadingLeaves = false.obs;
  final RxBool isLoadingBalance = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxString selectedFilter = 'Total'.obs;
  final RxString searchQuery = ''.obs;

  // ── Form state ────────────────────────────────────────────────────────────
  final Rx<LeaveTypeModel?> selectedLeaveType = Rx<LeaveTypeModel?>(null);
  final Rx<DateTime?> fromDate = Rx<DateTime?>(null);
  final Rx<DateTime?> toDate = Rx<DateTime?>(null);
  final RxString prescriptionFileName = ''.obs;
  final RxString prescriptionFilePath = ''.obs;

  // ── Shortcut ──────────────────────────────────────────────────────────────
  static LeaveController get to => Get.find<LeaveController>();

  // ── Derived getters ───────────────────────────────────────────────────────

  List<String> get approvers => approversForRole(employeeRole);

  int get numberOfDays {
    if (fromDate.value != null && toDate.value != null) {
      final diff = toDate.value!.difference(fromDate.value!).inDays + 1;
      return diff > 0 ? diff : 0;
    }
    return 0;
  }

  /// Balance for currently selected leave type — from MobEmployeeLeaveId API.
  int get currentBalance {
    if (selectedLeaveType.value == null) return 0;
    return leaveBalanceMap[selectedLeaveType.value!.leaveTypeId] ?? 0;
  }

  bool get exceedsBalance => numberOfDays > 0 && numberOfDays > currentBalance;

  bool get needsHandover {
    final lt = selectedLeaveType.value?.leaveType.toUpperCase() ?? '';
    return lt.contains('PAID') ||
        lt.contains('SICK') ||
        lt.contains('SHORT') ||
        lt.contains('HALF');
  }

  bool get needsPrescription {
    final lt = selectedLeaveType.value?.leaveType.toUpperCase() ?? '';
    return lt.contains('SICK');
  }

  List<Map<String, dynamic>> get filteredLeaves {
    final query = searchQuery.value.trim().toLowerCase();
    List<Map<String, dynamic>> list;

    if (selectedFilter.value == 'Total') {
      list = List.from(leaveHistory);
    } else {
      list = leaveHistory
          .where((l) => l['status'] == selectedFilter.value)
          .toList();
    }

    if (query.isEmpty) return list;
    return list.where((leave) {
      final type = (leave['leave_type'] ?? '').toString().toLowerCase();
      final fromRaw = (leave['from_date'] ?? '').toString().toLowerCase();
      final toRaw = (leave['to_date'] ?? '').toString().toLowerCase();
      final fromFmt = _fmtDate(leave['from_date']).toLowerCase();
      final toFmt = _fmtDate(leave['to_date']).toLowerCase();
      return type.contains(query) ||
          fromRaw.contains(query) ||
          toRaw.contains(query) ||
          fromFmt.contains(query) ||
          toFmt.contains(query);
    }).toList();
  }

  int get totalCount => leaveHistory.length;
  int get pendingCount =>
      leaveHistory.where((l) => l['status'] == 'Pending').length;
  int get approvedCount =>
      leaveHistory.where((l) => l['status'] == 'Approved').length;
  int get rejectedCount =>
      leaveHistory.where((l) => l['status'] == 'Rejected').length;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _loadSession();
    _initData();
  }

  // Pulls the logged-in employee's id, token and designation from local
  // storage, same keys used by project_controller.dart / task_controller.dart.
  void _loadSession() {
    authToken = (box.read('access_token') ?? '').toString().trim();
    employeeId = int.tryParse((box.read('EmployeeId') ??
                box.read('employeeId') ??
                box.read('employee_id') ??
                '0')
            .toString()
            .trim()) ??
        0;
    final designation = (box.read('Designation') ?? box.read('designation') ?? '')
        .toString()
        .toLowerCase()
        .trim();
    employeeRole = _resolveRole(designation);
  }

  EmployeeRole _resolveRole(String designation) {
    if (designation.contains('hr')) return EmployeeRole.hrManager;
    if (designation.contains('admin')) return EmployeeRole.admin;
    if (designation.contains('project') && designation.contains('manager')) {
      return EmployeeRole.projectManager;
    }
    if (designation.contains('team') && designation.contains('lead')) {
      return EmployeeRole.teamLeader;
    }
    return EmployeeRole.employee;
  }

  Future<void> _initData() async {
    await fetchLeaveTypes();
    if (employeeId != 0) {
      await Future.wait([
        fetchEmployeeLeaves(),
        fetchEmployeeLeaveList(),
        if (employeeRole != EmployeeRole.employee) fetchTeamLeaveList(),
      ]);
    }
  }
  // ── API 1: Fetch Leave Types ───────────────────────────────────────────────

  Future<void> fetchLeaveTypes() async {
    isLoadingTypes.value = true;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/MobLeaveTypeBind'),
        headers: _headers(),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['statuscode'] == 200 && body['data'] != null) {
          leaveTypes.value = (body['data'] as List)
              .map((e) => LeaveTypeModel.fromJson(e))
              .toList();
        }
      } else {
        _showError('Could not load leave types (${response.statusCode})');
      }
    } catch (e) {
      _showError('Network error: $e');
    } finally {
      isLoadingTypes.value = false;
    }
  }

  // ── API 2: Fetch Employee Leave Balances ──────────────────────────────────
  // MobEmployeeLeave(EmployeeId) — one row per leave type with its running
  // balance (TotalBalanceLeave). Rows here never carry a real applied From/To
  // date, so this is a BALANCE source only — actual applied leaves/history
  // come from fetchEmployeeLeaveList() below. Do not write leaveHistory here,
  // it previously raced with fetchEmployeeLeaveList() and wiped it out.

  Future<void> fetchEmployeeLeaves() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/MobEmployeeLeave/$employeeId'),
        headers: _headers(),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['statuscode'] == 200 && body['data'] != null) {
          final records = (body['data'] as List)
              .map((e) => EmployeeLeaveModel.fromJson(e))
              .toList();

          employeeLeaves.value = records;

          final Map<int, int> balances = {};
          for (final r in records) {
            balances[r.leaveTypeId] = r.totalBalanceLeave;
          }
          leaveBalanceMap.value = balances;
        }
      } else {
        _showError('Could not load leave balances (${response.statusCode})');
      }
    } catch (e) {
      _showError('Network error: $e');
    }
  }

  // ── API 3: Fetch Balance per Leave Type ───────────────────────────────────
  // MobEmployeeLeaveId(EmployeeId, LeaveTypeId) — called for each leave type
  // This is the CORRECT API for balance — has TotalTakenLeave + TotalBalanceLeave

  Future<void> fetchAllLeaveBalances() async {
    if (leaveTypes.isEmpty) return;
    isLoadingBalance.value = true;
    try {
      final Map<int, int> balances = {};
      // Fetch balance for each leave type in parallel
      await Future.wait(leaveTypes.map((type) async {
        try {
          final response = await http.get(
            Uri.parse(
                '$_baseUrl/MobEmployeeLeaveId/$employeeId/${type.leaveTypeId}'),
            headers: _headers(),
          );
          if (response.statusCode == 200) {
            final body = jsonDecode(response.body);
            if (body['statuscode'] == 200 &&
                body['data'] != null &&
                (body['data'] as List).isNotEmpty) {
              final balance = EmployeeLeaveBalanceModel.fromJson(
                  (body['data'] as List).first);
              balances[balance.leaveTypeId] = balance.totalBalanceLeave;
            }
          }
        } catch (_) {
          // Skip failed individual type — don't fail entire balance fetch
        }
      }));
      leaveBalanceMap.value = balances;
    } catch (e) {
      _showError('Could not load leave balances: $e');
    } finally {
      isLoadingBalance.value = false;
    }
  }

  /// Call this when leave type changes in form to fetch fresh balance for that type.
  Future<void> fetchBalanceForType(int leaveTypeId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/MobEmployeeLeaveId/$employeeId/$leaveTypeId'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['statuscode'] == 200 &&
            body['data'] != null &&
            (body['data'] as List).isNotEmpty) {
          final balance =
              EmployeeLeaveBalanceModel.fromJson((body['data'] as List).first);
          final updated = Map<int, int>.from(leaveBalanceMap);
          updated[leaveTypeId] = balance.totalBalanceLeave;
          leaveBalanceMap.value = updated;
        }
      }
    } catch (_) {
      // Silently fail — use cached value
    }
  }

  // ── API: Fetch Team Leave List (for approvers) ────────────────────────────
  // MobTeamEmployeeLeaveList(EmployeeId) — returns team members' leave requests

  Future<void> fetchTeamLeaveList() async {
    isLoadingTeamLeaves.value = true;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/MobTeamEmployeeLeaveList/$employeeId'),
        headers: _headers(),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['statuscode'] == 200 && body['data'] != null) {
          final records = (body['data'] as List)
              .map((e) => EmployeeLeaveModel.fromJson(e))
              .toList();

          teamLeaveHistory.value = records
              .where((r) => r.fromDate != null && r.toDate != null)
              .map((r) => _buildTeamHistoryEntry(r))
              .toList();
        }
      } else {
        _showError('Could not load team leaves (${response.statusCode})');
      }
    } catch (e) {
      _showError('Network error: $e');
    } finally {
      isLoadingTeamLeaves.value = false;
    }
  }
// ── API: Fetch Leave History List ─────────────────────────────────────────
  // MobEmployeeLeaveList(EmployeeId) — returns actual applied leaves with dates

  Future<void> fetchEmployeeLeaveList() async {
    isLoadingLeaves.value = true;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/MobEmployeeLeaveList/$employeeId'),
        headers: _headers(),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['statuscode'] == 200 && body['data'] != null) {
          final records = (body['data'] as List)
              .map((e) => EmployeeLeaveModel.fromJson(e))
              .toList();

          final List<Map<String, dynamic>> history = [];
          for (final r in records) {
            if (r.fromDate != null && r.toDate != null) {
              history.add(_buildHistoryEntry(r));
            }
          }
          leaveHistory.value = history;
        }
      } else {
        _showError('Could not load leave history (${response.statusCode})');
      }
    } catch (e) {
      _showError('Network error: $e');
    } finally {
      isLoadingLeaves.value = false;
    }
  }

  Map<String, dynamic> _buildTeamHistoryEntry(EmployeeLeaveModel r) => {
        'id': '${r.eLeaveAId}',
        'employee_leave_id': r.employeeLeaveId,
        'e_leave_a_id': r.eLeaveAId,
        'employee_name': r.employeeName,
        'employee_code': r.employeeCode,
        'leave_type': r.leaveType,
        'leave_type_id': r.leaveTypeId,
        'reason': r.leaveReason ?? '',
        'from_date': DateFormat('yyyy-MM-dd').format(r.fromDate!),
        'to_date': DateFormat('yyyy-MM-dd').format(r.toDate!),
        'no_of_days': r.leaveNoDays,
        'approve_status1': r.approveStatus1,
        'approve_status2': r.approveStatus2,
        'approve_status3': r.approveStatus3,
        'approveby1': r.approveby1,
        'approveby2': r.approveby2,
        'approveby3': r.approveby3,
        // Overall status: Approved if all 3 approved, Rejected if any rejected, else Pending
        'status': _resolveOverallStatus(r.approveStatus1, r.approveStatus2, r.approveStatus3),
        'applied_on': DateFormat('yyyy-MM-dd').format(r.createdDate ?? r.fromDate!),
        'remarks': '',
      };

  // Which of the 3 approval slots (1=Team Leader, 2=HR Manager,
  // 3=Project Manager) someone with [applicantRole] actually needs signed
  // off — mirrors approversForRole(): an Employee needs all three, a Team
  // Leader only needs HR + PM (skips their own level), and HR/PM/Admin only
  // need HR.
  List<bool> _requiredSlots(EmployeeRole applicantRole) {
    final required = approversForRole(applicantRole);
    return [
      required.contains('Team Leader'),
      required.contains('HR Manager'),
      required.contains('Project Manager'),
    ];
  }

  String _resolveStatusForApplicant(
      EmployeeRole applicantRole, String s1, String s2, String s3) {
    final slots = _requiredSlots(applicantRole);
    final statuses = [s1, s2, s3];
    final needed = [
      for (var i = 0; i < 3; i++)
        if (slots[i]) statuses[i],
    ];
    if (needed.any((s) => s == 'Rejected')) return 'Rejected';
    if (needed.isNotEmpty && needed.every((s) => s == 'Approved')) {
      return 'Approved';
    }
    return 'Pending';
  }

  // Team Leaves can't yet tell which role each applicant holds — the leave
  // APIs don't return the applicant's designation — so this conservatively
  // assumes the strictest case (Employee: needs TL + HR + PM all three).
  // Once the backend exposes a designation per leave row, resolve team
  // entries through _resolveStatusForApplicant with the real role instead.
  String _resolveOverallStatus(String s1, String s2, String s3) =>
      _resolveStatusForApplicant(EmployeeRole.employee, s1, s2, s3);
  Map<String, dynamic> _buildHistoryEntry(EmployeeLeaveModel r) => {
        'id': r.employeeLeaveId > 0
            ? '${r.employeeLeaveId}'
            : '${r.employeeId}_${r.leaveTypeId}_${r.fromDate?.millisecondsSinceEpoch ?? 0}',
        'e_leave_a_id': r.eLeaveAId,
        'leave_type': r.leaveType,
        'leave_type_id': r.leaveTypeId,
        'reason': r.leaveReason ?? '',
        'work_handover_to': '',
        'from_date': r.fromDate != null
            ? DateFormat('yyyy-MM-dd').format(r.fromDate!)
            : '',
        'to_date':
            r.toDate != null ? DateFormat('yyyy-MM-dd').format(r.toDate!) : '',
        // This is always the logged-in user's own leave, so we know exactly
        // which slots they need (approversForRole(employeeRole)) — a Team
        // Leader's own leave only needs HR + PM, a PM's only needs HR, etc.
        'approve_status1': r.approveStatus1,
        'approve_status2': r.approveStatus2,
        'approve_status3': r.approveStatus3,
        'status': _resolveStatusForApplicant(
            employeeRole, r.approveStatus1, r.approveStatus2, r.approveStatus3),
        'approved_to': approvers.join(', '),
        'applied_on': r.fromDate != null
            ? DateFormat('dd-MM-yyyy').format(r.fromDate!)
            : '',
        'remarks': '',
        'no_of_days': r.leaveNoDays,
        'prescription': r.descriptionImageFile,
      };

  // ── API 4: Submit Leave — MObAddEmployyeLeaveA ────────────────────────────

  Future<void> submitLeave({
    required String reason,
    required String workHandover,
    String? prescriptionFile,
    bool useImageEndpoint = false,
  }) async {
    if (selectedLeaveType.value == null ||
        fromDate.value == null ||
        toDate.value == null) {
      return;
    }

    isSubmitting.value = true;
    try {
      // Convert file to base64 if path exists
      String? fileBase64;
      if (prescriptionFilePath.value.isNotEmpty) {
        try {
          final file = File(prescriptionFilePath.value);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            fileBase64 = base64Encode(bytes);
          }
        } catch (e) {
          debugPrint('Error reading prescription file: $e');
        }
      }

      final payload = jsonEncode({
        "EmployeeLeaveId": 0,
        "EmployeeId": employeeId,
        "LeaveTypeId": selectedLeaveType.value!.leaveTypeId,
        "LeaveReason": reason,
        "FromDate": DateFormat('yyyy-MM-dd').format(fromDate.value!),
        "ToDate": DateFormat('yyyy-MM-dd').format(toDate.value!),
        "LeaveNoofday": numberOfDays,
        "DescriptionImageFile": fileBase64,
      });

      final response = await http.post(
        Uri.parse(useImageEndpoint ? _leaveSubmitImageUrl : _leaveSubmitUrl),
        headers: {
          ..._headers(),
          'Content-Type': 'application/json',
        },
        body: payload,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['statuscode'] == 200) {
          _addOptimisticLeave(reason, workHandover, prescriptionFile);
          // Refresh balance from API after successful submit
          await fetchBalanceForType(selectedLeaveType.value!.leaveTypeId);
          _resetForm();
          Get.back();
          Future.delayed(const Duration(milliseconds: 300), () {
            Get.snackbar(
              "Submitted",
              "Leave request submitted successfully.",
              backgroundColor: Colors.green.shade50,
              colorText: Colors.green.shade800,
              snackPosition: SnackPosition.BOTTOM,
            );
          });
        } else {
          _showError(body['message'] ?? 'Submission failed.');
        }
      } else {
        _showError('Server error (${response.statusCode})');
      }
    } catch (e) {
      _showError('Submit error: $e');
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> submitLeaveWithImage({
    required String reason,
    required String workHandover,
    required String prescriptionFile,
  }) async {
    await submitLeave(
      reason: reason,
      workHandover: workHandover,
      prescriptionFile: prescriptionFile,
      useImageEndpoint: true,
    );
  }

  // ── API 5: Approve Leave — MObeaveApprove ─────────────────────────────────

  Future<void> approveLeave(String leaveId) async {
    final leave = teamLeaveHistory.firstWhereOrNull((l) => l['id'] == leaveId)
        ?? leaveHistory.firstWhereOrNull((l) => l['id'] == leaveId);
    if (leave == null) return;

    final eLeaveAId = leave['e_leave_a_id'] ?? int.tryParse(leaveId) ?? 0;
    await _callApproveApi(
      eLeaveAId: eLeaveAId,
      leaveId: leaveId,
      newStatus: 'Approved',
      approverName: _approverNameForRole(),
    );
  }

  // ── API 6: Reject Leave — MObeaveApprove ──────────────────────────────────

  Future<void> rejectLeave(String leaveId, String remarks) async {
    final leave = teamLeaveHistory.firstWhereOrNull((l) => l['id'] == leaveId)
        ?? leaveHistory.firstWhereOrNull((l) => l['id'] == leaveId);
    if (leave == null) return;

    final eLeaveAId = leave['e_leave_a_id'] ?? int.tryParse(leaveId) ?? 0;
    await _callApproveApi(
      eLeaveAId: eLeaveAId,
      leaveId: leaveId,
      newStatus: 'Rejected',
      approverName: _approverNameForRole(),
      remarks: remarks,
    );
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  String _approverNameForRole() {
    switch (employeeRole) {
      case EmployeeRole.teamLeader: return 'Team Leader';
      case EmployeeRole.hrManager: return 'HR Manager';
      case EmployeeRole.projectManager: return 'Project Manager';
      default: return 'Admin';
    }
  }

  // Builds the 3-slot approve payload based on caller's role.
  // Role maps: TL → slot 1, HR → slot 2, PM → slot 3
  Future<void> _callApproveApi({
    required int eLeaveAId,
    required String leaveId,
    required String newStatus,
    required String approverName,
    String remarks = '',
  }) async {
    // Read current statuses from team list (or default Pending)
    final leave = teamLeaveHistory.firstWhereOrNull((l) => l['id'] == leaveId)
        ?? leaveHistory.firstWhereOrNull((l) => l['id'] == leaveId);

    String s1 = leave?['approve_status1'] ?? 'Pending';
    String s2 = leave?['approve_status2'] ?? 'Pending';
    String s3 = leave?['approve_status3'] ?? 'Pending';
    String b1 = leave?['approveby1'] ?? '';
    String b2 = leave?['approveby2'] ?? '';
    String b3 = leave?['approveby3'] ?? '';

    // Update the slot matching this approver's role
    switch (employeeRole) {
      case EmployeeRole.teamLeader:
        s1 = newStatus; b1 = approverName; break;
      case EmployeeRole.hrManager:
        s2 = newStatus; b2 = approverName; break;
      case EmployeeRole.projectManager:
        s3 = newStatus; b3 = approverName; break;
      default:
        s1 = newStatus; b1 = approverName;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/MObeaveApprove'),
        headers: {
          ..._headers(),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "ELeaveAId": eLeaveAId,
          "ApproveStatus1": s1,
          "ApproveStatus2": s2,
          "ApproveStatus3": s3,
          "Approveby1": b1,
          "Approveby2": b2,
          "Approveby3": b3,
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['statuscode'] == 200) {
          final overall = _resolveOverallStatus(s1, s2, s3);
          _updateLocalStatus(leaveId, overall, remarks);
          _updateTeamLocalStatus(leaveId, s1, s2, s3, b1, b2, b3);
          Get.snackbar(
            newStatus == 'Approved' ? "Approved" : "Rejected",
            "Leave has been ${newStatus.toLowerCase()}.",
            backgroundColor: newStatus == 'Approved'
                ? Colors.green.shade50
                : Colors.red.shade50,
            colorText: newStatus == 'Approved'
                ? Colors.green.shade800
                : Colors.red.shade800,
            snackPosition: SnackPosition.BOTTOM,
          );
        } else {
          _showError(body['message'] ?? 'Action failed.');
        }
      } else {
        _showError('Server error (${response.statusCode})');
      }
    } catch (e) {
      _showError('Network error: $e');
    }
  }

  void _updateTeamLocalStatus(String id, String s1, String s2, String s3,
      String b1, String b2, String b3) {
    final idx = teamLeaveHistory.indexWhere((l) => l['id'] == id);
    if (idx != -1) {
      final updated = Map<String, dynamic>.from(teamLeaveHistory[idx]);
      updated['approve_status1'] = s1;
      updated['approve_status2'] = s2;
      updated['approve_status3'] = s3;
      updated['approveby1'] = b1;
      updated['approveby2'] = b2;
      updated['approveby3'] = b3;
      updated['status'] = _resolveOverallStatus(s1, s2, s3);
      teamLeaveHistory[idx] = updated;
      teamLeaveHistory.refresh();
    }
  }

  Map<String, String> _headers() => {
        'Accept': 'application/json',
        if (authToken.isNotEmpty) 'Authorization': 'Bearer $authToken',
      };

  void _updateLocalStatus(String id, String status, String remarks) {
    final idx = leaveHistory.indexWhere((l) => l['id'] == id);
    if (idx != -1) {
      final updated = Map<String, dynamic>.from(leaveHistory[idx]);
      updated['status'] = status;
      updated['remarks'] = remarks;
      leaveHistory[idx] = updated;
      leaveHistory.refresh();
    }
  }

  void _addOptimisticLeave(
      String reason, String workHandover, String? prescription) {
    leaveHistory.insert(0, {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'leave_type': selectedLeaveType.value!.leaveType,
      'leave_type_id': selectedLeaveType.value!.leaveTypeId,
      'reason': reason,
      'work_handover_to': workHandover,
      'from_date': DateFormat('yyyy-MM-dd').format(fromDate.value!),
      'to_date': DateFormat('yyyy-MM-dd').format(toDate.value!),
      'status': 'Pending',
      'approved_to': approvers.join(', '),
      'applied_on': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'remarks': '',
      'no_of_days': numberOfDays,
      if (prescription != null && prescription.isNotEmpty)
        'prescription': prescription,
    });
  }

  void _resetForm() {
    selectedLeaveType.value = null;
    fromDate.value = null;
    toDate.value = null;
    prescriptionFileName.value = '';
    prescriptionFilePath.value = '';
  }

  void _showError(String message) {
    Get.snackbar(
      "Error",
      message,
      backgroundColor: Colors.red.shade50,
      colorText: Colors.red.shade800,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );
  }

void refreshAll() {
    fetchLeaveTypes();
    fetchEmployeeLeaves();
    fetchEmployeeLeaveList();
    if (employeeRole != EmployeeRole.employee) fetchTeamLeaveList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATE FORMAT HELPER
// ─────────────────────────────────────────────────────────────────────────────

String _fmtDate(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  final dt = DateTime.tryParse(raw);
  if (dt == null) return raw;
  return DateFormat('dd-MM-yyyy').format(dt);
}