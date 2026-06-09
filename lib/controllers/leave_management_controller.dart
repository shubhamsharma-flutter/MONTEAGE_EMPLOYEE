import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
  final bool isActive;

 EmployeeLeaveModel({
    required this.employeeLeaveId,
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

  // Set from your AuthController / session before using this controller.
  String authToken = '';
  int employeeId = 0;
  EmployeeRole employeeRole = EmployeeRole.employee;

  // ── Observables ───────────────────────────────────────────────────────────
  final RxList<LeaveTypeModel> leaveTypes = <LeaveTypeModel>[].obs;
  final RxList<EmployeeLeaveModel> employeeLeaves = <EmployeeLeaveModel>[].obs;

  /// Leave/WFH history cards shown in list.
  final RxList<Map<String, dynamic>> leaveHistory =
      <Map<String, dynamic>>[].obs;

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
    return leaveBalanceMap.value[selectedLeaveType.value!.leaveTypeId] ?? 0;
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
    _initData();
  }

  Future<void> _initData() async {
    await fetchLeaveTypes();
    if (employeeId != 0) {
      await Future.wait([
        fetchEmployeeLeaves(),      // populates leaveBalanceMap (balance rows)
        fetchEmployeeLeaveList(),   // populates leaveHistory (applied leaves)
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

  // ── API 2: Fetch Employee Leave History ───────────────────────────────────
  // MobEmployeeLeave(EmployeeId) — returns applied leave history rows

  Future<void> fetchEmployeeLeaves() async {
    isLoadingLeaves.value = true;
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

          final List<Map<String, dynamic>> history = [];
          final Map<int, int> balances = {};
          for (final r in records) {
            // Always read balance — every row has TotalBalanceLeave
            balances[r.leaveTypeId] = r.totalBalanceLeave;
            // Only add to history if it has a valid applied date range
            if (r.fromDate != null && r.toDate != null) {
              history.add(_buildHistoryEntry(r));
            }
          }
          leaveHistory.value = history;
          leaveBalanceMap.value = balances;
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
  Map<String, dynamic> _buildHistoryEntry(EmployeeLeaveModel r) => {
        'id': r.employeeLeaveId > 0
            ? '${r.employeeLeaveId}'
            : '${r.employeeId}_${r.leaveTypeId}_${r.fromDate?.millisecondsSinceEpoch ?? 0}',
        'leave_type': r.leaveType,
        'leave_type_id': r.leaveTypeId,
        'reason': r.leaveReason ?? '',
        'work_handover_to': '',
        'from_date': r.fromDate != null
            ? DateFormat('yyyy-MM-dd').format(r.fromDate!)
            : '',
        'to_date':
            r.toDate != null ? DateFormat('yyyy-MM-dd').format(r.toDate!) : '',
        'status': r.isActive ? 'Approved' : 'Pending',
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
  }) async {
    if (selectedLeaveType.value == null ||
        fromDate.value == null ||
        toDate.value == null) return;

    isSubmitting.value = true;
    try {
      final payload = jsonEncode({
        "EmployeeLeaveId": 0,
        "EmployeeId": employeeId,
        "LeaveTypeId": selectedLeaveType.value!.leaveTypeId,
        "LeaveReason": reason,
        "FromDate": DateFormat('dd-MM-yyyy').format(fromDate.value!),
        "ToDate": DateFormat('dd-MM-yyyy').format(toDate.value!),
        "LeaveNoofday": numberOfDays,
        "DescriptionImageFile":
            (prescriptionFile != null && prescriptionFile.isNotEmpty)
                ? prescriptionFile
                : null,
      });

      final response = await http.post(
        Uri.parse('$_baseUrl/MObAddEmployyeLeaveA'),
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

  // ── API 5: Approve Leave ───────────────────────────────────────────────────
  // TODO: Replace 'MobApproveLeave' with actual endpoint when received.

  Future<void> approveLeave(String leaveId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/MobApproveLeave'),
        headers: {
          ..._headers(),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "LeaveId": leaveId,
          "ApprovedBy": employeeId,
          "Status": "Approved",
          "Remarks": "",
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['statuscode'] == 200) {
          _updateLocalStatus(leaveId, 'Approved', '');
        } else {
          _showError(body['message'] ?? 'Approval failed.');
          return;
        }
      } else {
        _updateLocalStatus(leaveId, 'Approved', '');
      }
    } catch (_) {
      _updateLocalStatus(leaveId, 'Approved', '');
    }

    Get.snackbar(
      "Approved",
      "Leave request has been approved.",
      backgroundColor: Colors.green.shade50,
      colorText: Colors.green.shade800,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // ── API 6: Reject Leave ────────────────────────────────────────────────────
  // TODO: Replace 'MobRejectLeave' with actual endpoint when received.

  Future<void> rejectLeave(String leaveId, String remarks) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/MobRejectLeave'),
        headers: {
          ..._headers(),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "LeaveId": leaveId,
          "RejectedBy": employeeId,
          "Status": "Rejected",
          "Remarks": remarks,
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['statuscode'] == 200) {
          _updateLocalStatus(leaveId, 'Rejected', remarks);
        } else {
          _showError(body['message'] ?? 'Rejection failed.');
          return;
        }
      } else {
        _updateLocalStatus(leaveId, 'Rejected', remarks);
      }
    } catch (_) {
      _updateLocalStatus(leaveId, 'Rejected', remarks);
    }

    Get.snackbar(
      "Rejected",
      "Leave request has been rejected.",
      backgroundColor: Colors.red.shade50,
      colorText: Colors.red.shade800,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

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