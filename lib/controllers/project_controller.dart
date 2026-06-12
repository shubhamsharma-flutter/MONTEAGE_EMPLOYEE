import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '../models/project_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODEL  –  MObProjectTaskWork response item
// ─────────────────────────────────────────────────────────────────────────────

class ProjectTaskWork {
  final int sProjectId;
  final String projectName;
  final int employeeId;
  final int employeeId1;
  final String employeeName; // team lead / assigned employee
  final String employeeName1; // junior / second employee
  final String? productService;
  final String? subProductService;
  final int progressId;
  final String? progressImage;
  final String? progress;
  final int proAllocatId;
  final String? proDescription;
  final DateTime? deliveryEstimateDate;
  final DateTime? deliveryEstimateDate1;
  final String tokenId;
  final String? empDescription;
  final String? updateByy;
  final DateTime? progressUpdateDate;
  final String? progressUpdateBy;
  final DateTime? allocateDate;
  final String? uploadAllotFile;
  final String aStatus; // "Pending", "Active", "Done", etc.
  final String? taskTittle;
  final DateTime? endDeliveryEstimateDate;
  final DateTime? endDeliveryEstimateDate1;
  final String? recurrence;
  final String? priority;
  final bool isActive;
  final DateTime? createdDate;
  final DateTime? modifiedDate;
  final int createdby;
  final int updatedby;

  const ProjectTaskWork({
    required this.sProjectId,
    required this.projectName,
    required this.employeeId,
    required this.employeeId1,
    required this.employeeName,
    required this.employeeName1,
    this.productService,
    this.subProductService,
    required this.progressId,
    this.progressImage,
    this.progress,
    required this.proAllocatId,
    this.proDescription,
    this.deliveryEstimateDate,
    this.deliveryEstimateDate1,
    required this.tokenId,
    this.empDescription,
    this.updateByy,
    this.progressUpdateDate,
    this.progressUpdateBy,
    this.allocateDate,
    this.uploadAllotFile,
    required this.aStatus,
    this.taskTittle,
    this.endDeliveryEstimateDate,
    this.endDeliveryEstimateDate1,
    this.recurrence,
    this.priority,
    required this.isActive,
    this.createdDate,
    this.modifiedDate,
    required this.createdby,
    required this.updatedby,
  });

  factory ProjectTaskWork.fromJson(Map<String, dynamic> j) {
    DateTime? _parseDate(dynamic val) {
      if (val == null) return null;
      try {
        final dt = DateTime.parse(val.toString());
        // Treat year 0001 sentinel as null
        return dt.year <= 1 ? null : dt;
      } catch (_) {
        return null;
      }
    }

    return ProjectTaskWork(
      sProjectId: int.tryParse(j['SProjectId']?.toString() ?? '') ?? 0,
      projectName: j['ProjectName']?.toString() ?? '',
      employeeId: int.tryParse(j['EmployeeId']?.toString() ?? '') ?? 0,
      employeeId1: (j['EmployeeId1'] as num?)?.toInt() ?? 0,
      employeeName: j['EmployeeName']?.toString() ?? '',
      employeeName1: j['EmployeeName1']?.toString() ?? '',
      productService: j['ProductService']?.toString(),
      subProductService: j['SubProductService']?.toString(),
      progressId: (j['ProgressId'] as num?)?.toInt() ?? 0,
      progressImage: j['ProgressImage']?.toString(),
      progress: j['Progress']?.toString(),
      proAllocatId: (j['ProAllocatId'] as num?)?.toInt() ?? 0,
      proDescription: j['ProDescription']?.toString(),
      deliveryEstimateDate: _parseDate(j['DeliveryEstimateDate']),
      deliveryEstimateDate1: _parseDate(j['DeliveryEstimateDate1']),
      tokenId: j['TokenId']?.toString() ?? '',
      empDescription: j['EmpDescription']?.toString(),
      updateByy: j['UpdateByy']?.toString(),
      progressUpdateDate: _parseDate(j['ProgressUpdateDate']),
      progressUpdateBy: j['ProgressUpdateBy']?.toString(),
      allocateDate: _parseDate(j['AllocateDate']),
      uploadAllotFile: j['UploadAllotFile']?.toString(),
      aStatus: j['AStatus']?.toString() ?? 'Pending',
      taskTittle: j['TaskTittle']?.toString(),
      endDeliveryEstimateDate: _parseDate(j['EndDeliveryEstimateDate']),
      endDeliveryEstimateDate1: _parseDate(j['EndDeliveryEstimateDate1']),
      recurrence: j['Recurrence']?.toString(),
      priority: j['Priority']?.toString(),
      isActive: j['IsActive'] as bool? ?? false,
      createdDate: _parseDate(j['CreatedDate']),
      modifiedDate: _parseDate(j['ModifiedDate']),
      createdby: (j['Createdby'] as num?)?.toInt() ?? 0,
      updatedby: (j['Updatedby'] as num?)?.toInt() ?? 0,
    );
  }

  /// Whether the delivery deadline has passed and work is not yet done.
  bool get isOverdue {
    if (aStatus == 'Done' || aStatus == 'Complete') return false;
    return deliveryEstimateDate != null &&
        DateTime.now().isAfter(deliveryEstimateDate!);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TL PROJECT MODEL
// ─────────────────────────────────────────────────────────────────────────────
class TLProjectItem {
  String? message;
  List<Data>? data;
  int? statuscode;
  int? totalCount;

  TLProjectItem({this.message, this.data, this.statuscode, this.totalCount});

  TLProjectItem.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
      });
    }
    statuscode = json['statuscode'];
    totalCount = json['totalCount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['statuscode'] = this.statuscode;
    data['totalCount'] = this.totalCount;
    return data;
  }
}

class Data {
  int? sProjectId;
  String? projectName;
  int? employeeId;
  int? employeeId1;
  String? employeeName;
  String? employeeName1;
  String? productService;
  String? subProductService;
  int? progressId;
  String? progressImage;
  String? progress;
  int? proAllocatId;
  String? proDescription;
  String? deliveryEstimateDate;
  String? deliveryEstimateDate1;
  String? tokenId;
  String? empDescription;
  String? updateByy;
  String? progressUpdateDate;
  String? progressUpdateBy;
  String? allocateDate;
  String? uploadAllotFile;
  String? aStatus;
  String? taskTittle;
  String? endDeliveryEstimateDate;
  String? endDeliveryEstimateDate1;
  String? recurrence;
  String? priority;
  bool? isActive;
  String? createdDate;
  String? date;
  String? modifiedDate;
  int? createdby;
  int? updatedby;

  Data(
      {this.sProjectId,
      this.projectName,
      this.employeeId,
      this.employeeId1,
      this.employeeName,
      this.employeeName1,
      this.productService,
      this.subProductService,
      this.progressId,
      this.progressImage,
      this.progress,
      this.proAllocatId,
      this.proDescription,
      this.deliveryEstimateDate,
      this.deliveryEstimateDate1,
      this.tokenId,
      this.empDescription,
      this.updateByy,
      this.progressUpdateDate,
      this.progressUpdateBy,
      this.allocateDate,
      this.uploadAllotFile,
      this.aStatus,
      this.taskTittle,
      this.endDeliveryEstimateDate,
      this.endDeliveryEstimateDate1,
      this.recurrence,
      this.priority,
      this.isActive,
      this.createdDate,
      this.date,
      this.modifiedDate,
      this.createdby,
      this.updatedby});

  Data.fromJson(Map<String, dynamic> json) {
    sProjectId = json['SProjectId'];
    projectName = json['ProjectName'];
    employeeId = json['EmployeeId'];
    employeeId1 = json['EmployeeId1'];
    employeeName = json['EmployeeName'];
    employeeName1 = json['EmployeeName1'];
    productService = json['ProductService'];
    subProductService = json['SubProductService'];
    progressId = json['ProgressId'];
    progressImage = json['ProgressImage'];
    progress = json['Progress'];
    proAllocatId = json['ProAllocatId'];
    proDescription = json['ProDescription'];
    deliveryEstimateDate = json['DeliveryEstimateDate'];
    deliveryEstimateDate1 = json['DeliveryEstimateDate1'];
    tokenId = json['TokenId'];
    empDescription = json['EmpDescription'];
    updateByy = json['UpdateByy'];
    progressUpdateDate = json['ProgressUpdateDate'];
    progressUpdateBy = json['ProgressUpdateBy'];
    allocateDate = json['AllocateDate'];
    uploadAllotFile = json['UploadAllotFile'];
    aStatus = json['AStatus'];
    taskTittle = json['TaskTittle'];
    endDeliveryEstimateDate = json['EndDeliveryEstimateDate'];
    endDeliveryEstimateDate1 = json['EndDeliveryEstimateDate1'];
    recurrence = json['Recurrence'];
    priority = json['Priority'];
    isActive = json['IsActive'];
    createdDate = json['CreatedDate'];
    date = json['Date'];
    modifiedDate = json['ModifiedDate'];
    createdby = json['Createdby'];
    updatedby = json['Updatedby'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['SProjectId'] = this.sProjectId;
    data['ProjectName'] = this.projectName;
    data['EmployeeId'] = this.employeeId;
    data['EmployeeId1'] = this.employeeId1;
    data['EmployeeName'] = this.employeeName;
    data['EmployeeName1'] = this.employeeName1;
    data['ProductService'] = this.productService;
    data['SubProductService'] = this.subProductService;
    data['ProgressId'] = this.progressId;
    data['ProgressImage'] = this.progressImage;
    data['Progress'] = this.progress;
    data['ProAllocatId'] = this.proAllocatId;
    data['ProDescription'] = this.proDescription;
    data['DeliveryEstimateDate'] = this.deliveryEstimateDate;
    data['DeliveryEstimateDate1'] = this.deliveryEstimateDate1;
    data['TokenId'] = this.tokenId;
    data['EmpDescription'] = this.empDescription;
    data['UpdateByy'] = this.updateByy;
    data['ProgressUpdateDate'] = this.progressUpdateDate;
    data['ProgressUpdateBy'] = this.progressUpdateBy;
    data['AllocateDate'] = this.allocateDate;
    data['UploadAllotFile'] = this.uploadAllotFile;
    data['AStatus'] = this.aStatus;
    data['TaskTittle'] = this.taskTittle;
    data['EndDeliveryEstimateDate'] = this.endDeliveryEstimateDate;
    data['EndDeliveryEstimateDate1'] = this.endDeliveryEstimateDate1;
    data['Recurrence'] = this.recurrence;
    data['Priority'] = this.priority;
    data['IsActive'] = this.isActive;
    data['CreatedDate'] = this.createdDate;
    data['Date'] = this.date;
    data['ModifiedDate'] = this.modifiedDate;
    data['Createdby'] = this.createdby;
    data['Updatedby'] = this.updatedby;
    return data;
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// TL TEAM MEMBER MODEL  (MObTeamLeaderTeamList response)
// ─────────────────────────────────────────────────────────────────────────────

class TLTeamMember {
  final int employeeId;
  final String employeeName;
  final String employeeName1; // TL name
  final String contactNo;
  final String email;
  final String photo;
  final String designation;
  final String roleType;
  final int assignedStatus;
  final bool isActive;

  TLTeamMember({
    required this.employeeId,
    required this.employeeName,
    required this.employeeName1,
    required this.contactNo,
    required this.email,
    required this.photo,
    required this.designation,
    required this.roleType,
    required this.assignedStatus,
    required this.isActive,
  });

  factory TLTeamMember.fromJson(Map<String, dynamic> j) => TLTeamMember(
    employeeId:     int.tryParse(j['EmployeeId']?.toString() ?? '') ?? 0,
    employeeName:   j['EmployeeName']?.toString()  ?? '',
    employeeName1:  j['EmployeeName1']?.toString() ?? '',
    contactNo:      j['ContactNo']?.toString()     ?? '',
    email:          j['Email']?.toString()         ?? '',
    photo:          j['Photo']?.toString()         ?? '',
    designation:    j['Designation']?.toString()   ?? '',
    roleType:       j['RoleType']?.toString()      ?? '',
    assignedStatus: int.tryParse(j['AssignedStatus']?.toString() ?? '') ?? 0,
    isActive:       j['IsActive'] as bool?         ?? false,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TL ALLOCATE PROJECT MODEL  (MobProjectAllocateTL response item)
// ─────────────────────────────────────────────────────────────────────────────

class TLAllocateProject {
  final int sProjectId;
  final String projectName;
  final int employeeId;
  final String employeeName;
  final String assignBy;
  final int assignById;
  final DateTime? assignDate;

  TLAllocateProject({
    required this.sProjectId,
    required this.projectName,
    required this.employeeId,
    required this.employeeName,
    required this.assignBy,
    required this.assignById,
    this.assignDate,
  });

  factory TLAllocateProject.fromJson(Map<String, dynamic> j) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        final dt = DateTime.parse(v.toString());
        return dt.year <= 1 ? null : dt;
      } catch (_) {
        return null;
      }
    }

    return TLAllocateProject(
      sProjectId:   int.tryParse(j['SProjectId']?.toString() ?? '') ?? 0,
      projectName:  j['ProjectName']?.toString() ?? '',
      employeeId:   int.tryParse(j['EmployeeId']?.toString() ?? '') ?? 0,
      employeeName: j['EmployeeName']?.toString() ?? '',
      assignBy:     j['AssignBy']?.toString() ?? '',
      assignById:   int.tryParse(j['AssignById']?.toString() ?? '') ?? 0,
      assignDate:   parseDate(j['AssignDate']),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTROLLER
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// CONTROLLER
// ─────────────────────────────────────────────────────────────────────────────

class ProjectController extends GetxController {
  final box = GetStorage();

  // ── Loading flags ─────────────────────────────────────────────────────────
  final isLoading = true.obs;
  final isTaskWorksLoading = false.obs;

  // ── Data ──────────────────────────────────────────────────────────────────
 // ── Data ──────────────────────────────────────────────────────────────────
  final allProjects = <ProjectModel>[].obs;
  final projectTaskWorks = <ProjectTaskWork>[].obs;
  final tlProjects = <TLProjectItem>[].obs;
  final tlGivenProjects = <TLProjectItem>[].obs;
  final tlTeamMembers = <TLTeamMember>[].obs;
  final tlAllocateProjects = <TLAllocateProject>[].obs;

  // ── UI state ──────────────────────────────────────────────────────────────
  final selectedFilter = 'All'.obs;
  final tlSelectedFilter = 'All'.obs;
  final searchQuery = ''.obs;
  final tlSearchQuery = ''.obs;
  final isSearchExpanded = false.obs;
  final statusToggle = ''.obs;

  // ── Role ──────────────────────────────────────────────────────────────────
  String get userRole {
    final raw = (box.read('Designation') ?? box.read('designation') ?? '')
        .toString();
    return raw.toLowerCase();
  }

  bool get isManager {
    final raw = userRole.trim().replaceAll(RegExp(r'\s+'), ' ');
    return raw == 'project manager' ||
        raw == 'projectmanager' ||
        raw == 'pm' ||
        raw == 'project_manager' ||
        (raw.contains('project') && raw.contains('manager'));
  }

  bool get isTeamLeader {
    final raw = userRole.trim().replaceAll(RegExp(r'\s+'), ' ');
    return raw == 'team leader' ||
        raw == 'teamleader' ||
        raw == 'tl' ||
        raw == 'team_leader' ||
        raw == 'team lead' ||
        (raw.contains('team') && raw.contains('lead'));
  }

  // ── API endpoints ─────────────────────────────────────────────────────────
  static const String _apiBase =
      'https://montempep.eduagentapp.com/api/MonteageEmpErp';

  String get _employeeId =>
      (box.read('EmployeeId') ??
              box.read('employeeId') ??
              box.read('employee_id') ??
              '')
          .toString()
          .trim();

  String get projectsApi =>
      '$_apiBase/AppPMAssignProjectList/${_employeeId.isNotEmpty ? _employeeId : '4'}';

  String get projectTaskWorkApi =>
      '$_apiBase/MObProjectTaskWork/${_employeeId.isNotEmpty ? _employeeId : '4'}';

 String get tlProjectsApi =>
      '$_apiBase/MObProjectReciveWorkTL/$_employeeId';

  String get tlGivenProjectsApi =>
      '$_apiBase/MObProjectGivenWorkTL/$_employeeId';

  String get tlTeamListApi =>
      '$_apiBase/MObTeamLeaderTeamList/$_employeeId';

  String get tlAllocateProjectsApi =>
      '$_apiBase/MobProjectAllocateTL/$_employeeId';

  // ── Auth ──────────────────────────────────────────────────────────────────
  String get _accessToken => (box.read('access_token') ?? '').toString().trim();

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_accessToken',
    'Accept': 'application/json',
  };

  // ── Lifecycle ─────────────────────────────────────────────────────────────
 @override
  void onInit() {
    super.onInit();
    debugPrint('🔧 ProjectController.onInit | role: "$userRole" | isManager: $isManager | isTeamLeader: $isTeamLeader | employeeId: "$_employeeId"');
    if (isManager) fetchProjects();
    if (isTeamLeader) {
      fetchTLProjects();           // received projects
      fetchTLGivenProjects();      // given projects
      fetchTLTeamMembers();        // team members for employee selector
      fetchTLAllocateProjects();   // all allocated projects (MobProjectAllocateTL)
    }
    fetchProjectTaskWorks();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FETCH  –  projects  (unchanged logic, kept as-is)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> fetchProjects() async {
    if (!isManager) return;
    try {
      isLoading(true);
      final res = await http
          .get(Uri.parse(projectsApi), headers: _headers)
          .timeout(const Duration(seconds: 12));

      debugPrint('Projects API [${res.statusCode}]');

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final list = decoded['data'] as List?;
        if (list != null) {
          allProjects.value = list
              .map<ProjectModel>((e) => ProjectModel.fromJson(e))
              .toList();
          debugPrint('✅ Loaded ${allProjects.length} PM projects');
        }
      }
    } catch (e) {
      debugPrint('fetchProjects error: $e');
    } finally {
      isLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FETCH  –  TL projects
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> fetchTLProjects() async {
    if (!isTeamLeader) return;
    try {
      isLoading(true);
      debugPrint('📡 fetchTLProjects → $tlProjectsApi');
      debugPrint('   employeeId: "$_employeeId"');

      bool loaded = false;

      // Try no-auth first (matches pattern of other working endpoints),
      // then with auth token as fallback
      for (final useAuth in [false, true]) {
        try {
          final res = await http
              .get(
                Uri.parse(tlProjectsApi),
                headers: useAuth
                    ? _headers
                    : {'Accept': 'application/json'},
              )
              .timeout(const Duration(seconds: 12));

          debugPrint('   TL Projects auth=$useAuth → ${res.statusCode}');
          debugPrint('   body: ${res.body.length > 300 ? res.body.substring(0, 300) : res.body}');

          if (res.statusCode == 200) {
            final decoded = jsonDecode(res.body);

            // Support { "data": [...] } and bare [...]
            List<dynamic>? raw;
            if (decoded is List) {
              raw = decoded;
            } else if (decoded is Map) {
              raw = decoded['data'] as List? ??
                  decoded['Data'] as List? ??
                  decoded['result'] as List? ??
                  decoded['Result'] as List?;
            }

            debugPrint('   raw list length: ${raw?.length ?? 'null'}');

            if (raw != null && raw.isNotEmpty) {
              tlProjects.value = raw
                  .whereType<Map<String, dynamic>>()
                  .map(TLProjectItem.fromJson)
                  .toList();
              debugPrint('✅ Loaded ${tlProjects.length} TL projects');
              if (tlProjects.isNotEmpty) {
                debugPrint('   First: ${jsonEncode(raw.first)}');
              }
              loaded = true;
              break; // success — stop trying
            } else {
              debugPrint('   ⚠️ raw is null or empty');
            }
          }
        } catch (e) {
          debugPrint('   ⚠️ TL Projects auth=$useAuth error: $e');
        }
      }

      if (!loaded) {
        debugPrint('⚠️ fetchTLProjects: both auth attempts failed or returned empty');
        tlProjects.clear();
      }
    } finally {
      isLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FETCH  –  project task works  ← NEW
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> fetchProjectTaskWorks() async {
    try {
      isTaskWorksLoading(true);

      final res = await http.get(
        Uri.parse(projectTaskWorkApi),
        headers: _headers,
      );

      debugPrint('ProjectTaskWork API [${res.statusCode}]: ${res.body}');

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        // The API wraps the array in a "data" key
        final list = decoded['data'] as List?;

        if (list != null) {
          projectTaskWorks.value = list
              .map<ProjectTaskWork>(
                (e) => ProjectTaskWork.fromJson(e as Map<String, dynamic>),
              )
              .toList();
          debugPrint('Loaded ${projectTaskWorks.length} project task-works');
        } else {
          // "data" key missing — still a success but nothing to show
          debugPrint('ProjectTaskWork: no data key in response');
          projectTaskWorks.clear();
        }
      } else {
        Get.snackbar(
          'Error',
          'Failed to load project task works: ${res.statusCode}',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('fetchProjectTaskWorks error: $e');
      Get.snackbar(
        'Error',
        'Failed to load project task works: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isTaskWorksLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CONVENIENCE GETTERS  –  project task works  ← NEW
  // ─────────────────────────────────────────────────────────────────────────

  /// All task-works for a specific project id.
  List<ProjectTaskWork> taskWorksByProject(String projectId) => projectTaskWorks
      .where((tw) => tw.sProjectId.toString() == projectId)
      .toList();

  /// Task-works whose status is "Pending".
  List<ProjectTaskWork> get pendingTaskWorks =>
      projectTaskWorks.where((tw) => tw.aStatus == 'Pending').toList();

  /// Task-works that are currently active (not pending, not done).
  List<ProjectTaskWork> get activeTaskWorks => projectTaskWorks
      .where(
        (tw) =>
            tw.aStatus != 'Pending' &&
            tw.aStatus != 'Done' &&
            tw.aStatus != 'Complete',
      )
      .toList();

  /// Task-works that are overdue.
  List<ProjectTaskWork> get overdueTaskWorks =>
      projectTaskWorks.where((tw) => tw.isOverdue).toList();

  // ─────────────────────────────────────────────────────────────────────────
  // FILTERED PROJECTS  (unchanged)
  // ─────────────────────────────────────────────────────────────────────────
// ── TL filtered projects ──────────────────────────────────────────────────

  List<TLProjectItem> get filteredTLProjects {
    final filter = tlSelectedFilter.value;
    final q = tlSearchQuery.value.toLowerCase().trim();

    List<TLProjectItem> list;

    switch (filter) {
      case 'Received':
        list = tlProjects.toList();
        break;
      case 'Given':
        list = tlGivenProjects.toList();
        break;
      case 'Pending':
        list = [...tlProjects, ...tlGivenProjects]
            .where((p) => p.data?.firstWhereOrNull((d) => d.aStatus?.toLowerCase() == 'pending') != null)
            .toList();
        break;
      case 'Done':
        list = [...tlProjects, ...tlGivenProjects]
            .where((p) =>
                p.data?.firstWhereOrNull((d) => d.aStatus?.toLowerCase() == 'done') != null ||
                p.data?.firstWhereOrNull((d) => d.aStatus?.toLowerCase() == 'complete') != null ||
                p.data?.firstWhereOrNull((d) => d.aStatus?.toLowerCase() == 'approved') != null)
            .toList();
        break;
      default: // All
        list = [...tlProjects, ...tlGivenProjects];
    }

    if (q.isNotEmpty) {
      list = list
          .where((p) =>
              p.data?.firstWhereOrNull((d) => d.projectName?.toLowerCase().contains(q) == true) != null ||
          //    p.data?.firstWhereOrNull((d) => d.assignBy?.toLowerCase().contains(q) == true) != null ||
              p.data?.firstWhereOrNull((d) => d.employeeName?.toLowerCase().contains(q) == true) != null)
          .toList();
    }

    return list;
  }
  List<ProjectModel> get filteredProjects {
    var list = allProjects.toList();

    if (selectedFilter.value != 'All') {
      list = list
          .where((p) => p.projectStatus == selectedFilter.value)
          .toList();
      debugPrint('   After filter: ${list.length}');
    }

    final q = searchQuery.value.toLowerCase().trim();
    if (q.isNotEmpty) {
      list = list
          .where(
            (p) =>
                p.projectName.toLowerCase().contains(q) ||
                p.clientName.toLowerCase().contains(q),
          )
          .toList();
    }

    return list;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PROJECT STATS  (unchanged)
  // ─────────────────────────────────────────────────────────────────────────

  int get totalCount => allProjects.length;
  int get runningCount =>
      allProjects.where((p) => p.projectStatus == 'Running').length;
  int get completedCount =>
      allProjects.where((p) => p.projectStatus == 'Complete').length;
  int get onHoldCount =>
      allProjects.where((p) => p.projectStatus == 'On Hold').length;

  // ─────────────────────────────────────────────────────────────────────────
  // LOCAL STATUS UPDATE  (unchanged)
  // ─────────────────────────────────────────────────────────────────────────

  void updateProjectStatus(String projectId, String newStatus) {
    final idx = allProjects.indexWhere(
      (p) => p.projectId.toString() == projectId,
    );
    if (idx == -1) return;
    allProjects[idx] = allProjects[idx].copyWith(projectStatus: newStatus);
    allProjects.refresh();
    // TODO: call your API to persist the status change
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UI SETTERS  (unchanged)
  // ─────────────────────────────────────────────────────────────────────────

  void setFilter(String f) => selectedFilter.value =
      (selectedFilter.value == f && f != 'All') ? 'All' : f;

  void setTLFilter(String f) => tlSelectedFilter.value =
      (tlSelectedFilter.value == f && f != 'All') ? 'All' : f;

  void setSearch(String q) => searchQuery.value = q;
  void setTLSearch(String q) => tlSearchQuery.value = q;
  void toggleSearch() => isSearchExpanded.toggle();

  void setStatusToggle(String val) => statusToggle.value = val;

  // ─────────────────────────────────────────────────────────────────────────
  // REFRESH ALL
  // ─────────────────────────────────────────────────────────────────────────

 Future<void> refreshAll() async {
    await Future.wait([
      if (isManager) fetchProjects(),
      if (isTeamLeader) fetchTLProjects(),
      if (isTeamLeader) fetchTLGivenProjects(),
      if (isTeamLeader) fetchTLTeamMembers(),
      if (isTeamLeader) fetchTLAllocateProjects(),
      fetchProjectTaskWorks(),
    ]);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FETCH  –  TL given projects (MObProjectGivenWorkTL)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> fetchTLGivenProjects() async {
    if (!isTeamLeader) return;
    try {
      debugPrint('📡 fetchTLGivenProjects → $tlGivenProjectsApi');
      for (final useAuth in [false, true]) {
        try {
          final res = await http
              .get(
                Uri.parse(tlGivenProjectsApi),
                headers: useAuth ? _headers : {'Accept': 'application/json'},
              )
              .timeout(const Duration(seconds: 12));

          debugPrint('   TL Given Projects auth=$useAuth → ${res.statusCode}');
          debugPrint('   body: ${res.body.length > 300 ? res.body.substring(0, 300) : res.body}');

          if (res.statusCode == 200) {
            final decoded = jsonDecode(res.body);
            List<dynamic>? raw;
            if (decoded is List) {
              raw = decoded;
            } else if (decoded is Map) {
              raw = decoded['data'] as List? ??
                  decoded['Data'] as List? ??
                  decoded['result'] as List?;
            }
            if (raw != null && raw.isNotEmpty) {
              tlGivenProjects.value = raw
                  .whereType<Map<String, dynamic>>()
                  .map(TLProjectItem.fromJson)
                  .toList();
              debugPrint('✅ Loaded ${tlGivenProjects.length} TL given projects');
              return;
            }
          }
        } catch (e) {
          debugPrint('   ⚠️ TL Given Projects error: $e');
        }
      }
      tlGivenProjects.clear();
    } catch (e) {
      debugPrint('fetchTLGivenProjects error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FETCH  –  TL team members (MObTeamLeaderTeamList)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> fetchTLTeamMembers() async {
    if (!isTeamLeader) return;
    try {
      debugPrint('📡 fetchTLTeamMembers → $tlTeamListApi');
      for (final useAuth in [false, true]) {
        try {
          final res = await http
              .get(
                Uri.parse(tlTeamListApi),
                headers: useAuth ? _headers : {'Accept': 'application/json'},
              )
              .timeout(const Duration(seconds: 12));

          debugPrint('   TL Team Members auth=$useAuth → ${res.statusCode}');

          if (res.statusCode == 200) {
            final decoded = jsonDecode(res.body);
            List<dynamic>? raw;
            if (decoded is List) {
              raw = decoded;
            } else if (decoded is Map) {
              raw = decoded['data'] as List? ??
                  decoded['Data'] as List?;
            }
            if (raw != null && raw.isNotEmpty) {
              tlTeamMembers.value = raw
                  .whereType<Map<String, dynamic>>()
                  .map(TLTeamMember.fromJson)
                  .toList();
              debugPrint('✅ Loaded ${tlTeamMembers.length} TL team members');
              return;
            }
          }
        } catch (e) {
          debugPrint('   ⚠️ TL Team Members error: $e');
        }
      }
      tlTeamMembers.clear();
    } catch (e) {
      debugPrint('fetchTLTeamMembers error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FETCH  –  TL allocate projects (MobProjectAllocateTL)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> fetchTLAllocateProjects() async {
    if (!isTeamLeader) return;
    try {
      debugPrint('📡 fetchTLAllocateProjects → $tlAllocateProjectsApi');
      for (final useAuth in [false, true]) {
        try {
          final res = await http
              .get(
                Uri.parse(tlAllocateProjectsApi),
                headers: useAuth ? _headers : {'Accept': 'application/json'},
              )
              .timeout(const Duration(seconds: 12));
          debugPrint('   TL Allocate Projects auth=$useAuth → ${res.statusCode}');
          if (res.statusCode == 200) {
            final decoded = jsonDecode(res.body);
            List<dynamic>? raw;
            if (decoded is List) {
              raw = decoded;
            } else if (decoded is Map) {
              raw = decoded['data'] as List? ?? decoded['Data'] as List?;
            }
            if (raw != null && raw.isNotEmpty) {
              tlAllocateProjects.value = raw
                  .whereType<Map<String, dynamic>>()
                  .map(TLAllocateProject.fromJson)
                  .toList();
              debugPrint('✅ Loaded ${tlAllocateProjects.length} TL allocate projects');
              return;
            }
          }
        } catch (e) {
          debugPrint('   ⚠️ TL Allocate Projects auth=$useAuth error: $e');
        }
      }
      tlAllocateProjects.clear();
    } catch (e) {
      debugPrint('fetchTLAllocateProjects error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FILTERED  –  TL allocate projects
  // ─────────────────────────────────────────────────────────────────────────

  List<TLAllocateProject> get filteredTLAllocateProjects {
    final q = tlSearchQuery.value.toLowerCase().trim();
    if (q.isEmpty) return tlAllocateProjects.toList();
    return tlAllocateProjects
        .where((p) =>
            p.projectName.toLowerCase().contains(q) ||
            p.employeeName.toLowerCase().contains(q) ||
            p.assignBy.toLowerCase().contains(q))
        .toList();
  }
}
