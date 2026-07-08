import 'dart:convert';
import 'dart:math' show Random;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '../models/project_model.dart';
import '../models/givenmodelpm.dart' as given;
import '../models/recevedmodel.dart' as received;
import '../models/empdropdownmode.dart' as empdrop;

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

  // ── Auth ───────────────────────────────────────────────────────────────────
  Map<String, String> get _headers => {
        'Authorization': 'Bearer ${(_box.read('access_token') ?? '').toString().trim()}',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  // ── API URLs ───────────────────────────────────────────────────────────────
  String get _projectsUrl =>
      '$_apiBase/AppPMAssignProjectList/${empid.value}';

  String get _taskWorksUrl =>
      '$_apiBase/MObProjectTaskWork/${empid.value}';

  String get _receivedUrl =>
      '$_apiBase/MObProjectReciveWorkTL/${empid.value}';

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
          projects.value =
              list.map<ProjectModel>((e) => ProjectModel.fromJson(e)).toList();
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
      final res = await http
          .get(Uri.parse('$_apiBase/AppBindEmployee'), headers: _headers)
          .timeout(const Duration(seconds: 12));
      debugPrint('fetchBindEmployees [${res.statusCode}]');
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

  // ── Assign Task ────────────────────────────────────────────────────────────
  final isAssigning = false.obs;

  static const String _assignUrl =
      '$_apiBase/MobProjectAllocateTeam';

  String _generateToken() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random();
    final suffix =
        List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
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
          .post(Uri.parse(_assignUrl),
              headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 12));

      debugPrint('assignTask [${res.statusCode}]: ${res.body}');

      if (res.statusCode == 200) {
        Get.snackbar('Success', 'Task assigned successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF4CAF50),
            colorText: Colors.white);
        fetchTaskWorks();
        return true;
      } else {
        Get.snackbar('Failed', 'Server error: ${res.statusCode}',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFFB54A3A),
            colorText: Colors.white);
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not assign task: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFB54A3A),
          colorText: Colors.white);
      debugPrint('assignTask error: $e');
      return false;
    } finally {
      isAssigning(false);
    }
  }
}

