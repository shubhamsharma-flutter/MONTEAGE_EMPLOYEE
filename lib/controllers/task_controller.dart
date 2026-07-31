import 'dart:convert';
import 'dart:math' show Random;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

import '../models/empdropdownmode.dart' as empdrop;
import '../models/givenmodelpm.dart' as given;
import '../models/project_model.dart';
import '../models/recevedmodel.dart' as received;
import '../services/push_notification_service.dart';

class TaskController extends GetxController {
  final _box = GetStorage();

  static const String _apiBase =
      'https://montempep.eduagentapp.com/api/MonteageEmpErp';

  // ── State ──────────────────────────────────────────────────────────────────
  var empid = ''.obs;

  final projects = <ProjectModel>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  final taskWorks = <given.Data>[].obs;
  final isTaskWorksLoading = false.obs;
  final taskWorksError = ''.obs;

  final receivedWorks = <received.RData>[].obs;
  final isReceivedLoading = false.obs;
  final receivedError = ''.obs;

  final boundEmployees = <empdrop.Data>[].obs;
  final isEmpLoading = false.obs;

  final teamLeaders = <empdrop.Data>[].obs;
  final isTlLoading = false.obs;

  // ── Auth ───────────────────────────────────────────────────────────────────
  Map<String, String> get _headers => {
    'Authorization':
        'Bearer ${(_box.read('access_token') ?? '').toString().trim()}',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  // ── Designation ────────────────────────────────────────────────────────────
  // Normalized by stripping everything but letters so stray casing/spacing/
  // punctuation from the API ("Team Leader", "TeamLeader", "team_leader", ...)
  // still matches.
  String get _normalizedDesignation {
    final raw = (_box.read('Designation') ?? _box.read('designation') ?? '')
        .toString();
    final normalized = raw.toLowerCase().replaceAll(RegExp('[^a-z]'), '');
    debugPrint(
      'TaskController designation raw="$raw" normalized="$normalized"',
    );
    return normalized;
  }

  bool get _isTeamLeader => _normalizedDesignation == 'teamleader';
  bool get _isProjectManager => _normalizedDesignation == 'projectmanager';

  // ── API URLs ───────────────────────────────────────────────────────────────
  String get _projectsUrl => _isTeamLeader
      ? '$_apiBase/MobProjectAllocateTL/${empid.value}'
      : '$_apiBase/AppPMAssignProjectList/${empid.value}';

  String get _taskWorksUrl => (_isTeamLeader || _isProjectManager)
      ? '$_apiBase/MObProjectGivenWorkTL/${empid.value}'
      : '$_apiBase/MObProjectTaskWork/${empid.value}';

  String get _receivedUrl => '$_apiBase/MObProjectReciveWorkTL/${empid.value}';

  @override
  void onInit() {
    super.onInit();
    empid.value = (_box.read('EmployeeId') ?? '').toString();
    fetchProjects();
    fetchTaskWorks();
    fetchReceivedWorks();
  }

  Future<void> fetchProjects() async {
    try {
      isLoading(true);
      errorMessage('');
      final res = await http
          .get(Uri.parse(_projectsUrl), headers: _headers)
          .timeout(const Duration(seconds: 12));

      debugPrint('fetchProjects [${res.statusCode}]');

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final list = decoded['data'] as List?;
        if (list != null) {
          projects.value = list
              .map<ProjectModel>((e) => ProjectModel.fromJson(e))
              .toList();
        }
      } else {
        errorMessage('Server error: ${res.statusCode}');
      }
    } catch (e) {
      errorMessage('Failed to load projects: $e');
      debugPrint('fetchProjects error: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchTaskWorks() async {
    try {
      isTaskWorksLoading(true);
      taskWorksError('');
      final res = await http
          .get(Uri.parse(_taskWorksUrl), headers: _headers)
          .timeout(const Duration(seconds: 12));

      debugPrint('fetchTaskWorks [${res.statusCode}]');

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final parsed = given.givemprojectpm.fromJson(decoded);
        taskWorks.value = parsed.data ?? [];
      } else {
        taskWorksError('Server error: ${res.statusCode}');
      }
    } catch (e) {
      taskWorksError('Failed to load tasks: $e');
      debugPrint('fetchTaskWorks error: $e');
    } finally {
      isTaskWorksLoading(false);
    }
  }

  Future<void> fetchReceivedWorks() async {
    try {
      isReceivedLoading(true);
      receivedError('');
      final res = await http
          .get(Uri.parse(_receivedUrl), headers: _headers)
          .timeout(const Duration(seconds: 12));

      debugPrint('fetchReceivedWorks [${res.statusCode}]');

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final parsed = received.receivedmodel.fromJson(decoded);
        receivedWorks.value = parsed.data ?? [];
      } else {
        receivedError('Server error: ${res.statusCode}');
      }
    } catch (e) {
      receivedError('Failed to load received projects: $e');
      debugPrint('fetchReceivedWorks error: $e');
    } finally {
      isReceivedLoading(false);
    }
  }

  // ── Bound Employees ────────────────────────────────────────────────────────
  Future<void> fetchBindEmployees() async {
    try {
      isEmpLoading(true);
      boundEmployees.clear();
      final url = _isTeamLeader
          ? '$_apiBase/MObTeamLeaderTeamList/${empid.value}'
          : '$_apiBase/AppBindEmployee';
      debugPrint(
        'fetchBindEmployees url: $url (isTeamLeader=$_isTeamLeader, empid=${empid.value})',
      );
      final res = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 12));
      debugPrint('fetchBindEmployees [${res.statusCode}]: ${res.body}');
      if (res.statusCode == 200) {
        final parsed = empdrop.empdropdown.fromJson(jsonDecode(res.body));
        boundEmployees.value = parsed.data ?? [];
      }
    } catch (e) {
      debugPrint('fetchBindEmployees error: $e');
    } finally {
      isEmpLoading(false);
    }
  }

  // ── Project Manager's Team Leaders ────────────────────────────────────────
  Future<void> fetchProjectManagerTeamList() async {
    try {
      isTlLoading(true);
      teamLeaders.clear();
      final url = '$_apiBase/ProjectManagerTeamList/${empid.value}';
      debugPrint('fetchProjectManagerTeamList url: $url');
      final res = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 12));
      debugPrint(
        'fetchProjectManagerTeamList [${res.statusCode}]: ${res.body}',
      );
      if (res.statusCode == 200) {
        final parsed = empdrop.empdropdown.fromJson(jsonDecode(res.body));
        teamLeaders.value = parsed.data ?? [];
      }
    } catch (e) {
      debugPrint('fetchProjectManagerTeamList error: $e');
    } finally {
      isTlLoading(false);
    }
  }

  // ── Assign Project To Team Leader ─────────────────────────────────────────
  final isAssigningToTl = false.obs;

  static const String _assignToTlUrl = '$_apiBase/AddAssignProjectTeam';

  Future<bool> assignProjectToTeamLead({
    required int sProjectId,
    required int employeeId,
  }) async {
    try {
      isAssigningToTl(true);
      final body = {
        'employeeId': employeeId,
        'sProjectId': sProjectId,
        'assignBy': empid.value,
      };

      debugPrint('assignProjectToTeamLead body: ${jsonEncode(body)}');

      final res = await http
          .post(
            Uri.parse(_assignToTlUrl),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 12));

      debugPrint('assignProjectToTeamLead [${res.statusCode}]: ${res.body}');

      if (res.statusCode == 200) {
        fetchProjects();
        final assignedBy = (_box.read('EmployeeName') ?? 'Your manager')
            .toString();
        PushNotificationService.instance.sendToEmployee(
          employeeId: employeeId.toString(),
          title: 'New Project Assigned',
          body: '$assignedBy assigned you a project',
          data: {
            'type': 'project_assigned',
            'sProjectId': sProjectId.toString(),
          },
        );
        return true;
      } else {
        Get.snackbar(
          'Failed',
          'Server error: ${res.statusCode}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFB54A3A),
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not assign project: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFB54A3A),
        colorText: Colors.white,
      );
      debugPrint('assignProjectToTeamLead error: $e');
      return false;
    } finally {
      isAssigningToTl(false);
    }
  }

  // ── Assign Task ────────────────────────────────────────────────────────────
  final isAssigning = false.obs;

  static const String _assignUrl = '$_apiBase/MobProjectAllocateTeam';

  String _generateToken() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random();
    final suffix = List.generate(
      6,
      (_) => chars[rng.nextInt(chars.length)],
    ).join();
    return 'TKN$suffix';
  }

  Future<bool> assignTask({
    required int sProjectId,
    required int employeeId,
    required String taskTitle,
    required String description,
    required String deliveryDate,
    required String endDeliveryDate,
    required String priority,
    required String recurrence,
  }) async {
    try {
      isAssigning(true);
      final body = {
        'SProjectId': sProjectId,
        'EmployeeId': employeeId,
        'TaskTittle': taskTitle,
        'ProDescription': description,
        'UploadAllotFile': '',
        'DeliveryEstimateDate1': deliveryDate,
        'EndDeliveryEstimateDate1': endDeliveryDate,
        'Recurrence': recurrence,
        'Priority': priority,
        'TokenId': _generateToken(),
        'AssignBy': empid.value,
      };

      debugPrint('assignTask body: ${jsonEncode(body)}');

      final res = await http
          .post(
            Uri.parse(_assignUrl),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 12));

      debugPrint('assignTask [${res.statusCode}]: ${res.body}');

      if (res.statusCode == 200) {
        fetchTaskWorks();
        final assignedBy = (_box.read('EmployeeName') ?? 'Your manager')
            .toString();
        PushNotificationService.instance.sendToEmployee(
          employeeId: employeeId.toString(),
          title: 'New Task Assigned',
          body: '$assignedBy assigned you: $taskTitle',
          data: {'type': 'task_assigned', 'sProjectId': sProjectId.toString()},
        );
        return true;
      } else {
        Get.snackbar(
          'Failed',
          'Server error: ${res.statusCode}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFB54A3A),
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not assign task: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFB54A3A),
        colorText: Colors.white,
      );
      debugPrint('assignTask error: $e');
      return false;
    } finally {
      isAssigning(false);
    }
  }

  // ── Progress Update ────────────────────────────────────────────────────────
  final isUpdatingProgress = false.obs;

  static const String _progressUpdateUrl = '$_apiBase/MObProjectProgressUpdate';

  Future<bool> updateProgress({
    required int proAllocatId,
    required String empDescription,
    required int progress,
    required String status,
    String? taskTitle,
    int? notifyEmployeeId,
    String? notifyEmployeeName,
  }) async {
    try {
      isUpdatingProgress(true);
      final body = {
        'ProAllocatId': proAllocatId,
        'EmpDescription': empDescription,
        'Progress': progress,
        'AStatus': status,
        'ProgressUpdateBy': empid.value,
      };

      debugPrint('updateProgress body: ${jsonEncode(body)}');

      final res = await http
          .post(
            Uri.parse(_progressUpdateUrl),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 12));

      debugPrint('updateProgress [${res.statusCode}]: ${res.body}');

      if (res.statusCode == 200) {
        fetchReceivedWorks();
        fetchTaskWorks();
        if (notifyEmployeeId != null && notifyEmployeeId > 0) {
          final updatedBy = (_box.read('EmployeeName') ?? 'A team member')
              .toString();
          final recipientName = (notifyEmployeeName ?? '').trim();
          final greeting = recipientName.isEmpty ? '' : 'Hi $recipientName, ';
          PushNotificationService.instance.sendToEmployee(
            employeeId: notifyEmployeeId.toString(),
            title: 'Progress Updated',
            body:
                '$greeting$updatedBy updated progress on ${taskTitle ?? 'a task'} to $progress%',
            data: {
              'type': 'progress_updated',
              'proAllocatId': proAllocatId.toString(),
            },
          );
        }
        return true;
      } else {
        Get.snackbar(
          'Failed',
          'Server error: ${res.statusCode}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFB54A3A),
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not update progress: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFB54A3A),
        colorText: Colors.white,
      );
      debugPrint('updateProgress error: $e');
      return false;
    } finally {
      isUpdatingProgress(false);
    }
  }

  // ── Project Status Update (PM) ────────────────────────────────────────────
  final isUpdatingStatus = false.obs;

  static const String _statusUpdateUrl = '$_apiBase/MObProjectStatusUpdate';

  Future<bool> updateProjectStatus({
    required int sProjectId,
    required String status,
  }) async {
    try {
      isUpdatingStatus(true);
      final body = {
        'SProjectId': sProjectId,
        'AStatus': status,
        'StatusUpdateBy': empid.value,
      };

      debugPrint('updateProjectStatus body: ${jsonEncode(body)}');
      debugPrint('updateProjectStatus url: $_statusUpdateUrl');

      final res = await http
          .post(
            Uri.parse(_statusUpdateUrl),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 12));

      debugPrint('updateProjectStatus [${res.statusCode}]: ${res.body}');

      if (res.statusCode == 200) {
        fetchProjects();
        return true;
      } else {
        Get.snackbar(
          'Failed',
          'Server error: ${res.statusCode}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFB54A3A),
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not update status: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFB54A3A),
        colorText: Colors.white,
      );
      debugPrint('updateProjectStatus error: $e');
      return false;
    } finally {
      isUpdatingStatus(false);
    }
  }
}
