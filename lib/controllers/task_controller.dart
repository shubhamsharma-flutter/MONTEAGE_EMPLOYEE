import 'package:get/get.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'project_controller.dart';

// ─────────────────────────────────────────────────────────────────────────
// MODELS  (unchanged — do not edit)
// ─────────────────────────────────────────────────────────────────────────

class TaskStatus {
  static const pending    = 'Pending';
  static const submitted  = 'Submitted';
  static const awaitingTL = 'AwaitingLeadApproval';
  static const awaitingPM = 'AwaitingPMApproval';
  static const approved   = 'Approved';
  static const tlRejected = 'LeadRejected';
  static const pmRejected = 'PMRejected';

  static bool isApproved(String s) => s == approved || s == 'Done' || s == 'Complete';
  static bool isRejected(String s) => s == tlRejected || s == pmRejected || s == 'AssignerRejected';
  static bool isAwaiting(String s) =>
      s == submitted || s == awaitingTL || s == awaitingPM || s == 'AwaitingAssignerApproval';
}

bool taskIs3Way(Data t) {
  final hasJunior = (t.employeeId1 ?? 0) != 0;
  final hasTL     = (t.employeeId  ?? 0) != 0 && t.employeeId != t.createdby;
  return hasJunior && hasTL;
}

class EmployeeModel {
  final int employeeId;
  final String employeeName;
  final String employeeCode;
  String projectId;
  String projectName;
  final String name;
  final bool isTeamLead;
  final String? teamLeadId;
  final List<EmployeeModel> juniors;

  EmployeeModel({
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    required this.projectId,
    required this.projectName,
    required this.name,
    required this.isTeamLead,
    this.teamLeadId,
    this.juniors = const [],
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> j) => EmployeeModel(
    employeeId:   int.tryParse(j['EmployeeId']?.toString() ?? '0') ?? 0,
    employeeName: j['EmployeeName']?.toString() ?? '',
    employeeCode: j['EmployeeCode']?.toString() ?? '',
    projectId:    '',
    projectName:  '',
    name:         j['EmployeeName']?.toString() ?? '',
    isTeamLead:   false,
    teamLeadId:   null,
    juniors:      const [],
  );
}

class RemarkModel {
  final String rejectedBy;
  final String remark;
  final String rejectedAt;

  RemarkModel({
    required this.rejectedBy,
    required this.remark,
    required this.rejectedAt,
  });

  factory RemarkModel.fromJson(Map<String, dynamic> j) => RemarkModel(
    rejectedBy: j['rejected_by']?.toString() ?? '',
    remark:     j['remark']?.toString() ?? '',
    rejectedAt: j['rejected_at']?.toString() ?? '',
  );

  Map<String, dynamic> toJson() => {
    'rejected_by': rejectedBy,
    'remark':      remark,
    'rejected_at': rejectedAt,
  };
}

class TaskModel {
  String? message;
  List<Data>? data;
  int? statuscode;
  int? totalCount;

  TaskModel({this.message, this.data, this.statuscode, this.totalCount});

  TaskModel.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) { data!.add(Data.fromJson(v)); });
    }
    statuscode = json['statuscode'];
    totalCount = json['totalCount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['message']    = message;
    if (this.data != null) data['data'] = this.data!.map((v) => v.toJson()).toList();
    data['statuscode'] = statuscode;
    data['totalCount'] = totalCount;
    return data;
  }
}

class Data {
  int?    sProjectId;
  String? projectName;
  int?    employeeId;
  int?    employeeId1;
  String? employeeName;
  String? employeeName1;
  String? productService;
  String? subProductService;
  int?    progressId;
  String? progressImage;
  String? progress;
  int?    proAllocatId;
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
  bool?   isActive;
  String? createdDate;
  String? date;
  String? modifiedDate;
  int?    createdby;
  int?    updatedby;

  // ── Local-only overlay fields (not from API) ──────────────────────────
  String?      overrideStatus;
  RemarkModel? leadRemark;
  RemarkModel? assignerRemark;
  RemarkModel? pmRemark;

  Data({
    this.sProjectId,
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
    this.updatedby,
    this.overrideStatus,
    this.leadRemark,
    this.assignerRemark,
    this.pmRemark,
  });

  Data.fromJson(Map<String, dynamic> json) {
    sProjectId            = json['SProjectId'];
    projectName           = json['ProjectName'];
    employeeId            = json['EmployeeId'];
    employeeId1           = json['EmployeeId1'];
    employeeName          = json['EmployeeName'];
    employeeName1         = json['EmployeeName1'];
    productService        = json['ProductService'];
    subProductService     = json['SubProductService'];
    progressId            = json['ProgressId'];
    progressImage         = json['ProgressImage'];
    progress              = json['Progress'];
    proAllocatId          = json['ProAllocatId'];
    proDescription        = json['ProDescription'];
    deliveryEstimateDate  = json['DeliveryEstimateDate'];
    deliveryEstimateDate1 = json['DeliveryEstimateDate1'];
    tokenId               = json['TokenId'];
    empDescription        = json['EmpDescription'];
    updateByy             = json['UpdateByy'];
    progressUpdateDate    = json['ProgressUpdateDate'];
    progressUpdateBy      = json['ProgressUpdateBy'];
    allocateDate          = json['AllocateDate'];
    uploadAllotFile       = json['UploadAllotFile'];
    aStatus               = json['AStatus'];
    taskTittle            = json['TaskTittle'];
    endDeliveryEstimateDate  = json['EndDeliveryEstimateDate'];
    endDeliveryEstimateDate1 = json['EndDeliveryEstimateDate1'];
    recurrence            = json['Recurrence'];
    priority              = json['Priority'];
    isActive              = json['IsActive'];
    createdDate           = json['CreatedDate'];
    date                  = json['Date'];
    modifiedDate          = json['ModifiedDate'];
    createdby             = json['Createdby'];
    updatedby             = json['Updatedby'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['SProjectId']             = sProjectId;
    data['ProjectName']            = projectName;
    data['EmployeeId']             = employeeId;
    data['EmployeeId1']            = employeeId1;
    data['EmployeeName']           = employeeName;
    data['EmployeeName1']          = employeeName1;
    data['ProductService']         = productService;
    data['SubProductService']      = subProductService;
    data['ProgressId']             = progressId;
    data['ProgressImage']          = progressImage;
    data['Progress']               = progress;
    data['ProAllocatId']           = proAllocatId;
    data['ProDescription']         = proDescription;
    data['DeliveryEstimateDate']   = deliveryEstimateDate;
    data['DeliveryEstimateDate1']  = deliveryEstimateDate1;
    data['TokenId']                = tokenId;
    data['EmpDescription']         = empDescription;
    data['UpdateByy']              = updateByy;
    data['ProgressUpdateDate']     = progressUpdateDate;
    data['ProgressUpdateBy']       = progressUpdateBy;
    data['AllocateDate']           = allocateDate;
    data['UploadAllotFile']        = uploadAllotFile;
    data['AStatus']                = aStatus;
    data['TaskTittle']             = taskTittle;
    data['EndDeliveryEstimateDate']  = endDeliveryEstimateDate;
    data['EndDeliveryEstimateDate1'] = endDeliveryEstimateDate1;
    data['Recurrence']             = recurrence;
    data['Priority']               = priority;
    data['IsActive']               = isActive;
    data['CreatedDate']            = createdDate;
    data['Date']                   = date;
    data['ModifiedDate']           = modifiedDate;
    data['Createdby']              = createdby;
    data['Updatedby']              = updatedby;
    return data;
  }

  // ── Convenience getters used by the controller ────────────────────────

  /// Unique key: prefer proAllocatId, fall back to tokenId.
  String get uniqueId =>
      (proAllocatId != null && proAllocatId! > 0)
          ? proAllocatId.toString()
          : (tokenId ?? '').trim();

  /// The effective status: local override wins over API value.
  String get effectiveStatus => overrideStatus ?? aStatus ?? TaskStatus.pending;

  /// TL = EmployeeName / EmployeeId  (first assignee slot).
  String get teamLeadId   => employeeId?.toString() ?? '';
  String get teamLeadName => employeeName ?? '';

  /// Junior = EmployeeName1 / EmployeeId1 (second assignee slot).
  String? get juniorId   => (employeeId1 != null && employeeId1! > 0) ? employeeId1.toString() : null;
  String? get juniorName => (employeeName1 ?? '').trim().isNotEmpty ? employeeName1 : null;

  /// Assigner = Createdby (numeric id stored at creation time).
  String get assignedById   => createdby?.toString() ?? '';
  String get assignedByName => updateByy ?? '';

  String get title       => taskTittle ?? '';
  String get description => proDescription ?? '';
  String get dueDate     => deliveryEstimateDate1 ?? deliveryEstimateDate ?? '';
  String get startDate   => allocateDate ?? createdDate ?? '';

  bool get isOverdue {
    try {
      final due = DateFormat('yyyy-MM-dd').parse(dueDate);
      return due.isBefore(DateTime.now()) && !TaskStatus.isApproved(effectiveStatus);
    } catch (_) {
      return false;
    }
  }

  Data copyWith({
    String?      overrideStatus,
    RemarkModel? leadRemark,
    RemarkModel? assignerRemark,
    RemarkModel? pmRemark,
  }) =>
      Data(
        sProjectId:            sProjectId,
        projectName:           projectName,
        employeeId:            employeeId,
        employeeId1:           employeeId1,
        employeeName:          employeeName,
        employeeName1:         employeeName1,
        productService:        productService,
        subProductService:     subProductService,
        progressId:            progressId,
        progressImage:         progressImage,
        progress:              progress,
        proAllocatId:          proAllocatId,
        proDescription:        proDescription,
        deliveryEstimateDate:  deliveryEstimateDate,
        deliveryEstimateDate1: deliveryEstimateDate1,
        tokenId:               tokenId,
        empDescription:        empDescription,
        updateByy:             updateByy,
        progressUpdateDate:    progressUpdateDate,
        progressUpdateBy:      progressUpdateBy,
        allocateDate:          allocateDate,
        uploadAllotFile:       uploadAllotFile,
        aStatus:               aStatus,
        taskTittle:            taskTittle,
        endDeliveryEstimateDate:  endDeliveryEstimateDate,
        endDeliveryEstimateDate1: endDeliveryEstimateDate1,
        recurrence:            recurrence,
        priority:              priority,
        isActive:              isActive,
        createdDate:           createdDate,
        date:                  date,
        modifiedDate:          modifiedDate,
        createdby:             createdby,
        updatedby:             updatedby,
        overrideStatus:        overrideStatus ?? this.overrideStatus,
        leadRemark:            leadRemark     ?? this.leadRemark,
        assignerRemark:        assignerRemark ?? this.assignerRemark,
        pmRemark:              pmRemark       ?? this.pmRemark,
      );
}

// ─────────────────────────────────────────────────────────────────────────
// CONTROLLER
// ─────────────────────────────────────────────────────────────────────────

class TaskController extends GetxController {
  final _box            = GetStorage();
  /// key = Data.uniqueId  →  override payload
  final _localOverrides = <String, Map<String, dynamic>>{};

  final isLoading        = true.obs;
  final activeTab        = 0.obs;
  final searchQuery      = ''.obs;
  final selectedFilter   = 'All'.obs;
  final isSearchExpanded = false.obs;
  final isSubmitting     = false.obs;

  /// Flat list of every Data item across all fetched TaskModel responses.
  final allTasks  = <Data>[].obs;
  final employees = <EmployeeModel>[].obs;

  static const String _apiBase = 'https://montempep.eduagentapp.com/api/MonteageEmpErp';
  static const String _taskListUrl        = '$_apiBase/AppTaskListByEmployeeId';
  static const String _givenTasksUrl      = '$_apiBase/MObProjectGivenWorkTL';
  static const String _receivedTasksUrl   = '$_apiBase/MObProjectReciveWorkTL';
  static const String _progressUpdateUrl  = '$_apiBase/MObProjectProgressUpdate';
  static const String _taskSubmitUrl      = '$_apiBase/MobProjectAllocateTeam';
  static const String _taskUpdateUrl      = '$_apiBase/AppTaskUpdate';
  static const String _taskDeleteUrl      = '$_apiBase/AppTaskDelete';
  static const String _projectAllocateTeamUrl = '$_apiBase/MobProjectAllocateTeam';

  String get _accessToken =>
      (_box.read('access_token') ?? '').toString().trim();

  Map<String, String> get _authHeaders => {
    'Content-Type':  'application/json; charset=utf-8',
    'Authorization': 'Bearer $_accessToken',
    'Accept':        'application/json',
  };

  static const Map<String, String> _noAuthHeaders = {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept':       'application/json',
  };

  String get myId   => (_box.read('EmployeeId')   ?? _box.read('employeeId')   ?? '').toString().trim();
  String get myName => (_box.read('EmployeeName') ?? _box.read('employeeName') ?? '').toString().trim();

  // ── Role helpers ──────────────────────────────────────────────────────
  bool get _isManager {
    final raw = (_box.read('Designation') ?? _box.read('designation') ?? '')
        .toString().toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
    return raw == 'project manager' || raw == 'projectmanager' || raw == 'pm' ||
        raw == 'project_manager' || (raw.contains('project') && raw.contains('manager'));
  }

  bool get isTeamLeader {
    final raw = (_box.read('Designation') ?? _box.read('designation') ?? '')
        .toString().toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
    return raw == 'team leader'  || raw == 'teamleader' || raw == 'tl' ||
        raw == 'team_leader' || raw == 'team lead' ||
        (raw.contains('team') && raw.contains('lead'));
  }

  bool get isRegularEmployee => !_isManager && !isTeamLeader;
  bool get isProjectManager  => _isManager;

  int get _maxTabIndex {
    if (isProjectManager) return 1;
    if (isTeamLeader)     return 2;
    return 0;
  }

  int get effectiveTab => activeTab.value.clamp(0, _maxTabIndex).toInt();

  // ── Derived lists ─────────────────────────────────────────────────────

  List<Data> get givenTasks => allTasks.where((t) {
    if (isRegularEmployee) return false;
    // Standard: assigner fields (Createdby / UpdateByy)
    if (t.assignedById.isNotEmpty && t.assignedById != '0' && t.assignedById == myId) return true;
    if (myName.isNotEmpty &&
        t.assignedByName.trim().toLowerCase() == myName.trim().toLowerCase()) {
      return true;
    }
    // MObProjectGivenWorkTL stores the assigner in EmployeeName1 when EmployeeId1 == 0
    if ((t.employeeId1 == null || t.employeeId1 == 0) &&
        myName.isNotEmpty &&
        (t.employeeName1 ?? '').trim().toLowerCase() == myName.trim().toLowerCase()) {
      return true;
    }
    return false;
  }).toList();

  List<Data> get receivedTasks => allTasks.where((t) {
    if (t.assignedById == myId || t.assignedByName == myName) return false;
    return t.teamLeadId == myId || t.teamLeadName == myName ||
        t.juniorId == myId || t.juniorName == myName;
  }).toList();

  List<Data> get _activeTasks {
    if (isRegularEmployee) return receivedTasks;
    return effectiveTab == 0 ? givenTasks : receivedTasks;
  }

  // ── Stats ─────────────────────────────────────────────────────────────
  int get totalCount    => _activeTasks.length;
  int get activeCount   => _activeTasks.where((t) =>
      !t.isOverdue && !TaskStatus.isApproved(t.effectiveStatus)).length;
  int get pendingCount  => _activeTasks.where((t) =>
      t.effectiveStatus == TaskStatus.pending && !t.isOverdue).length;
  int get approvedCount => _activeTasks.where((t) =>
      TaskStatus.isApproved(t.effectiveStatus)).length;
  int get overdueCount  => _activeTasks.where((t) => t.isOverdue).length;

  // ── Approval guards ───────────────────────────────────────────────────

  bool canLeadApprove(Data t) {
    if (!isTeamLeader) return false;
    final hasJunior  = (t.juniorId ?? '').trim().isNotEmpty;
    final isTLOfTask = t.teamLeadId == myId ||
        t.teamLeadName.trim().toLowerCase() == myName.trim().toLowerCase() ||
        t.assignedById == myId;
    final awaitingLead = t.effectiveStatus == TaskStatus.awaitingTL ||
        (t.effectiveStatus == TaskStatus.submitted && hasJunior);
    return hasJunior && isTLOfTask && awaitingLead;
  }

  bool canPMApprove(Data t) {
    if (!isProjectManager) return false;
    final myNameLower = myName.trim().toLowerCase();
    final isPMTheAssigner = (t.assignedById == myId && myId.isNotEmpty && myId != '0') ||
        (myName.isNotEmpty && t.assignedByName.trim().toLowerCase() == myNameLower) ||
        // MObProjectGivenWorkTL: assigner is in EmployeeName1 when EmployeeId1 == 0
        ((t.employeeId1 == null || t.employeeId1 == 0) &&
            myName.isNotEmpty &&
            (t.employeeName1 ?? '').trim().toLowerCase() == myNameLower);
    final is3Way = taskIs3Way(t);
    return t.effectiveStatus == TaskStatus.awaitingPM ||
        (t.effectiveStatus == TaskStatus.submitted && isPMTheAssigner && !is3Way) ||
        (t.effectiveStatus == 'AwaitingAssignerApproval' && isPMTheAssigner) ||
        // API "Done" / "InProgress" = employee submitted, awaiting PM review
        (isPMTheAssigner &&
            (t.aStatus == 'Done' || t.aStatus == 'InProgress') &&
            t.overrideStatus == null);
  }

  bool _isWorker(Data t) {
    final hasJunior = (t.juniorId ?? '').trim().isNotEmpty;
    if (hasJunior) return t.juniorId == myId || t.juniorName == myName;
    return t.teamLeadId == myId || t.teamLeadName == myName;
  }

  bool canMarkDone(Data t) {
    final actionable = t.effectiveStatus == TaskStatus.pending ||
        t.effectiveStatus == TaskStatus.tlRejected ||
        t.effectiveStatus == 'AssignerRejected' ||
        t.effectiveStatus == TaskStatus.pmRejected;
    return _isWorker(t) && actionable;
  }

  bool isSubmittedAwaitingReview(Data t) =>
      t.effectiveStatus == TaskStatus.awaitingTL ||
      t.effectiveStatus == TaskStatus.awaitingPM ||
      t.effectiveStatus == TaskStatus.submitted;

  // ── Lifecycle ─────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    final stored = _box.read<Map>('task_overrides');
    if (stored != null) {
      stored.forEach((k, v) {
        _localOverrides[k.toString()] = Map<String, dynamic>.from(v as Map);
      });
    }
    fetchAll();
  }

  // ─────────────────────────────────────────────────────────────────────
  // FETCH ALL
  // ─────────────────────────────────────────────────────────────────────

  Future<void> fetchAll() async {
    try {
      isLoading(true);
      debugPrint('🔍 MyId: "$myId" | MyName: "$myName" | isManager: $_isManager');
      await Future.wait([_fetchEmployees(), _fetchTasks()]);
    } catch (e) {
      debugPrint('fetchAll error: $e');
      Get.snackbar('Error', 'Failed to load data: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // FETCH EMPLOYEES  (unchanged logic, same as before)
  // ─────────────────────────────────────────────────────────────────────

  Future<void> _fetchEmployees() async {
    try {
      if (isTeamLeader) await _fetchEmployeesForTL();
      else              await _fetchAllEmployeesFromBinding();
    } catch (e) {
      debugPrint('_fetchEmployees error: $e');
      employees.value = [];
    }
  }

  Future<void> _fetchEmployeesForTL() async {
    const String tlTeamUrl = '$_apiBase/MObTeamLeaderTeamList';
    final url = '$tlTeamUrl/$myId';
    for (final useAuth in [false, true]) {
      try {
        final res = await http
            .get(Uri.parse(url),
                headers: useAuth ? _authHeaders : _noAuthHeaders)
            .timeout(const Duration(seconds: 12));
        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body);
          List<dynamic>? raw;
          if (decoded is List) raw = decoded;
          else if (decoded is Map) {
            raw = decoded['data'] as List? ??
                decoded['Data'] as List? ??
                decoded['result'] as List?;
          }
          if (raw != null && raw.isNotEmpty) {
            employees.value = raw
                .whereType<Map<String, dynamic>>()
                .map((j) => EmployeeModel(
                      employeeId:   int.tryParse(j['EmployeeId']?.toString() ?? '') ?? 0,
                      employeeName: j['EmployeeName']?.toString().trim() ?? '',
                      employeeCode: '',
                      projectId:    '',
                      projectName:  '',
                      name:         j['EmployeeName']?.toString().trim() ?? '',
                      isTeamLead:   false,
                    ))
                .where((e) =>
                    e.employeeName.isNotEmpty &&
                    e.employeeName != 'null' &&
                    e.employeeName != myName)
                .toList()
              ..sort((a, b) => a.employeeName.compareTo(b.employeeName));
            return;
          }
        }
      } catch (e) { debugPrint('TL team list error: $e'); }
    }
    await _fetchEmployeesForNonPM();
  }

  Future<void> _fetchAllEmployeesFromBinding() async {
    const url = '$_apiBase/Appbindemployee';
    for (final useAuth in [false, true]) {
      try {
        final res = await http
            .get(Uri.parse(url),
                headers: useAuth ? _authHeaders : _noAuthHeaders)
            .timeout(const Duration(seconds: 12));
        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body);
          List<dynamic>? raw;
          if (decoded is List) raw = decoded;
          else if (decoded is Map) {
            for (final key in ['data', 'Data', 'result', 'Result', 'employees', 'Employees']) {
              if (decoded[key] is List) { raw = decoded[key] as List; break; }
            }
          }
          if (raw != null && raw.isNotEmpty) {
            final allEmps = raw.whereType<Map<String, dynamic>>().map((j) {
              final name = (j['EmployeeName'] ?? j['employeeName'] ?? j['Name'] ?? j['name'] ?? '').toString().trim();
              final id   = int.tryParse((j['EmployeeId'] ?? j['employeeId'] ?? j['Id'] ?? j['id'] ?? '0').toString()) ?? 0;
              final code = (j['EmployeeCode'] ?? j['employeeCode'] ?? j['Code'] ?? '').toString();
              return EmployeeModel(
                employeeId: id, employeeName: name, employeeCode: code,
                projectId: '', projectName: '', name: name, isTeamLead: false,
              );
            }).where((e) => e.employeeName.isNotEmpty && e.employeeName != 'null').toList();

            if (allEmps.isEmpty) continue;

            if (_isManager) {
              employees.value = allEmps.where((e) => e.employeeName != myName).toList()
                ..sort((a, b) => a.employeeName.compareTo(b.employeeName));
            } else {
              final underMe = await _getEmployeeNamesUnderMe();
              employees.value = underMe.isEmpty
                  ? []
                  : allEmps.where((e) => underMe.contains(e.employeeName)).toList()
                    ..sort((a, b) => a.employeeName.compareTo(b.employeeName));
            }
            return;
          }
        }
      } catch (e) { debugPrint('Appbindemployee error: $e'); }
    }
    if (_isManager) await _fetchEmployeesForPM();
    else            await _fetchEmployeesForNonPM();
  }

  Future<Set<String>> _getEmployeeNamesUnderMe() async {
    final nameSet = <String>{};
    try {
      final res = await http
          .get(Uri.parse('$_apiBase/MObProjectTaskWork/$myId'),
              headers: _noAuthHeaders)
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final list = decoded['data'] as List?;
        if (list != null) {
          for (final item in list) {
            final m     = item as Map<String, dynamic>;
            final above = m['EmployeeName1']?.toString().trim() ?? '';
            final below = m['EmployeeName']?.toString().trim()  ?? '';
            if (above == myName && below.isNotEmpty && below != myName) nameSet.add(below);
          }
        }
      }
    } catch (e) { debugPrint('_getEmployeeNamesUnderMe error: $e'); }
    return nameSet;
  }

  Future<void> _fetchEmployeesForPM() async {
    final allEmpUrls = [
      '$_apiBase/AppEmployeeList',
      '$_apiBase/AppAllEmployee',
      '$_apiBase/AppEmployeeBinding',
      '$_apiBase/AppEmployeeBinding/$myId',
    ];
    for (final url in allEmpUrls) {
      for (final useAuth in [true, false]) {
        try {
          final res = await http
              .get(Uri.parse(url),
                  headers: useAuth ? _authHeaders : _noAuthHeaders)
              .timeout(const Duration(seconds: 12));
          if (res.statusCode == 200) {
            final list = _parseEmployeeList(res.body);
            if (list != null && list.isNotEmpty) {
              employees.value = list.where((e) => e.employeeName != myName).toList()
                ..sort((a, b) => a.employeeName.compareTo(b.employeeName));
              return;
            }
          }
        } catch (e) { debugPrint('PM emp fetch error: $e'); }
      }
    }
    await _fetchEmployeesViaScraping();
  }

  Future<void> _fetchEmployeesViaScraping() async {
    final nameSet = <String>{};
    for (final id in [0, int.tryParse(myId) ?? 4]) {
      try {
        final res = await http
            .get(Uri.parse('$_apiBase/MObProjectTaskWork/$id'),
                headers: _noAuthHeaders)
            .timeout(const Duration(seconds: 12));
        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body);
          final list    = decoded['data'] as List?;
          if (list != null) {
            for (final item in list) {
              final m  = item as Map<String, dynamic>;
              final n1 = m['EmployeeName']?.toString().trim()  ?? '';
              final n2 = m['EmployeeName1']?.toString().trim() ?? '';
              if (n1.isNotEmpty) nameSet.add(n1);
              if (n2.isNotEmpty) nameSet.add(n2);
            }
          }
        }
      } catch (e) { debugPrint('Scrape error: $e'); }
    }
    nameSet.remove(myName);
    nameSet.removeWhere((n) => n.isEmpty || n == 'null');
    _buildEmployeesFromNames(nameSet);
  }

  Future<void> _fetchEmployeesForNonPM() async {
    final nameSet = <String>{};
    try {
      final res = await http
          .get(Uri.parse('$_apiBase/MObProjectTaskWork/$myId'),
              headers: _noAuthHeaders)
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final list    = decoded['data'] as List?;
        if (list != null) {
          for (final item in list) {
            final m     = item as Map<String, dynamic>;
            final above = m['EmployeeName1']?.toString().trim() ?? '';
            final below = m['EmployeeName']?.toString().trim()  ?? '';
            if (above == myName && below.isNotEmpty && below != myName) nameSet.add(below);
          }
        }
      }
    } catch (e) { debugPrint('Non-PM emp error: $e'); }
    _buildEmployeesFromNames(nameSet);
  }

  void _buildEmployeesFromNames(Set<String> nameSet) {
    final sorted = nameSet.toList()..sort();
    employees.value = sorted.asMap().entries.map((e) => EmployeeModel(
      employeeId: e.key + 1, employeeName: e.value, employeeCode: '',
      projectId: '', projectName: '', name: e.value, isTeamLead: false,
    )).toList();
  }

  List<EmployeeModel>? _parseEmployeeList(String body) {
    try {
      final decoded = jsonDecode(body);
      final raw     = _extractEmployeeArray(decoded);
      if (raw == null || raw.isEmpty) return null;
      return raw
          .whereType<Map<String, dynamic>>()
          .map(EmployeeModel.fromJson)
          .where((e) => e.employeeName.isNotEmpty)
          .toList();
    } catch (e) { return null; }
  }

  List<dynamic>? _extractEmployeeArray(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map) {
      for (final key in ['data', 'Data', 'employees', 'Employees', 'result', 'Result']) {
        final value  = decoded[key];
        if (value is List) return value;
        final nested = _extractEmployeeArray(value);
        if (nested != null) return nested;
      }
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────
  // FETCH TASKS  — now returns List<Data> from TaskModel.data
  // ─────────────────────────────────────────────────────────────────────

  Future<void> _fetchTasks() async {
    try {
      if (isRegularEmployee) { await _fetchRegularEmployeeTasks(); return; }

      final futures = [
        _fetchDataList('$_givenTasksUrl/$myId',    label: 'Given'),
        _fetchDataList('$_receivedTasksUrl/$myId', label: 'Received'),
      ];
      if (isProjectManager) {
        futures.add(_fetchDataList('$_taskListUrl/$myId', label: 'PMList'));
      }
      final results = await Future.wait(futures);

      final rawGiven    = results[0];
      final rawReceived = results[1];
      final rawPMList   = (isProjectManager && results.length > 2) ? results[2] : <Data>[];

      // PM-given tasks: items where createdby matches myId
      final myIdInt = int.tryParse(myId) ?? 0;
      final rawPMGiven = rawPMList.where((t) =>
          t.createdby == myIdInt ||
          (t.assignedByName.trim().toLowerCase() == myName.trim().toLowerCase())).toList();

      final seen   = <String>{};
      final merged = <Data>[];

      for (final t in [...rawGiven, ...rawPMGiven]) {
        final key = t.uniqueId;
        if (key.isNotEmpty && seen.add(key)) merged.add(t);
      }
      for (final t in rawReceived) {
        final key = t.uniqueId;
        if (key.isNotEmpty && seen.add(key)) merged.add(t);
      }

      if (merged.isNotEmpty) {
        allTasks.value = merged;
        _applyLocalOverrides();
        return;
      }

      // Fallback: generic task list
      for (final useAuth in [true, false]) {
        final res = await http
            .get(Uri.parse('$_taskListUrl/$myId'),
                headers: useAuth ? _authHeaders : _noAuthHeaders)
            .timeout(const Duration(seconds: 12));
        if (res.statusCode == 200) {
          final items = _parseDataList(res.body);
          if (items.isNotEmpty) {
            allTasks.value = items;
            _applyLocalOverrides();
            return;
          }
        }
      }

      // Final fallback
      final res = await http
          .get(Uri.parse('$_apiBase/MObProjectTaskWork/$myId'),
              headers: _noAuthHeaders)
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        allTasks.value = _parseDataList(res.body);
      }
    } catch (e) { debugPrint('_fetchTasks error: $e'); }
    _applyLocalOverrides();
  }

  Future<void> _fetchRegularEmployeeTasks() async {
    final received = await _fetchDataList('$_receivedTasksUrl/$myId', label: 'RegularReceived');
    if (received.isNotEmpty) {
      allTasks.value = received;
      _applyLocalOverrides();
      return;
    }
    try {
      final res = await http
          .get(Uri.parse('$_apiBase/MObProjectTaskWork/$myId'),
              headers: _noAuthHeaders)
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        allTasks.value = _parseDataList(res.body);
      }
    } catch (e) { debugPrint('Regular fallback error: $e'); }
    _applyLocalOverrides();
  }

  /// Fetches a URL and returns a flat List<Data> from the response.
  Future<List<Data>> _fetchDataList(String url, {required String label}) async {
    for (final useAuth in [false, true]) {
      try {
        final res = await http
            .get(Uri.parse(url),
                headers: useAuth ? _authHeaders : _noAuthHeaders)
            .timeout(const Duration(seconds: 12));
        debugPrint('📋 $label [$url] auth=$useAuth → ${res.statusCode}');
        if (res.statusCode == 200) {

          final items = _parseDataList(res.body);
              print(res.body);
          if (items.isNotEmpty) return items;

        }
      } catch (e) { debugPrint('$label fetch error: $e'); }
    }
    return [];
  }

  /// Parses a raw response body into List<Data>.
  List<Data> _parseDataList(String body) {
    try {
      final decoded = jsonDecode(body);
      List<dynamic>? raw;
      if (decoded is List) {
        raw = decoded;
      } else if (decoded is Map) {
        // Try TaskModel wrapper first (message/data/statuscode)
        if (decoded['data'] is List) raw = decoded['data'] as List;
        else raw = decoded['Data'] as List? ?? decoded['result'] as List?;
      }
      if (raw == null || raw.isEmpty) return [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map((j) => Data.fromJson(j))
          .toList();
    } catch (e) {
      debugPrint('_parseDataList error: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // FILTERED TASKS
  // ─────────────────────────────────────────────────────────────────────

  List<Data> get filteredTasks {
    var list = _activeTasks;
    switch (selectedFilter.value) {
      case 'Overdue':
        list = list.where((t) => t.isOverdue).toList();
        break;
      case 'Approved':
        list = list.where((t) => TaskStatus.isApproved(t.effectiveStatus)).toList();
        break;
      case 'Active':
        list = list.where((t) =>
            !t.isOverdue && !TaskStatus.isApproved(t.effectiveStatus)).toList();
        break;
      case 'Rejected':
        list = list.where((t) => TaskStatus.isRejected(t.effectiveStatus)).toList();
        break;
      case 'All':
        break;
      default:
        list = list.where((t) => t.effectiveStatus == selectedFilter.value).toList();
    }
    final q = searchQuery.value.toLowerCase().trim();
    if (q.isNotEmpty) {
      list = list.where((t) =>
          t.title.toLowerCase().contains(q) ||
          t.dueDate.contains(q)).toList();
    }
    return list;
  }

  // ─────────────────────────────────────────────────────────────────────
  // ASSIGN TASK
  // ─────────────────────────────────────────────────────────────────────

  Future<void> assignTask({
    required List<String> teamLeadId,
    required String? juniorId,
    required String title,
    required String description,
    required String startDate,
    required String dueDate,
    required String priority,
    required String recurrence,
    String? projectId,
    String? projectName,
    List<String>? attachments,
  }) async {
    try {
      isSubmitting(true);

      String empName1 = '', empName2 = '', empName3 = '';
      if (teamLeadId.isNotEmpty) {
        final idx1 = int.tryParse(teamLeadId[0]) ?? 0;
        empName1   = employees.firstWhereOrNull((e) => e.employeeId == idx1)?.employeeName ?? teamLeadId[0];
      }
      if (teamLeadId.length > 1) {
        final idx2 = int.tryParse(teamLeadId[1]) ?? 0;
        empName2   = employees.firstWhereOrNull((e) => e.employeeId == idx2)?.employeeName ?? teamLeadId[1];
      }
      if (teamLeadId.length > 2) {
        final idx3 = int.tryParse(teamLeadId[2]) ?? 0;
        empName3   = employees.firstWhereOrNull((e) => e.employeeId == idx3)?.employeeName ?? teamLeadId[2];
      }

      String toApiDate(String d) {
        try { return DateFormat('yyyy-MM-dd').format(DateFormat('dd-MM-yyyy').parse(d)); }
        catch (_) { return d; }
      }

      int selectedProjectId = int.tryParse(projectId?.trim() ?? '') ?? 0;
      if (selectedProjectId == 0 &&
          projectName?.trim().isNotEmpty == true &&
          Get.isRegistered<ProjectController>()) {
        selectedProjectId = _resolveProjectId(projectId, projectName);
      }

      final emp1Obj = employees.firstWhereOrNull((e) =>
          e.employeeName.trim().toLowerCase() == empName1.trim().toLowerCase());
      final emp2Obj = employees.firstWhereOrNull((e) =>
          e.employeeName.trim().toLowerCase() == empName2.trim().toLowerCase());
      final emp1Id  = emp1Obj?.employeeId ?? 0;
      final emp2Id  = emp2Obj?.employeeId ?? 0;

      final body = <String, dynamic>{
        'SProjectId':              selectedProjectId,
        'ProjectId':               selectedProjectId,
        'EmployeeId':              emp1Id,
        'EmployeeId1':             emp2Id,
        'TaskTittle':              title,
        'ProDescription':          description,
        'UploadAllotFile':         (attachments != null && attachments.length > 2) ? attachments[2] : '',
        'DeliveryEstimateDate1':   toApiDate(dueDate),
        'EndDeliveryEstimateDate1':toApiDate(dueDate),
        'Recurrence':              recurrence,
        'Priority':                priority,
        'TokenId':                 _generateToken(),
        'AssignBy':                myId,
        'ProjectName':             projectName ?? '',
        'AssignById':              int.tryParse(myId) ?? 0,
        'AssignDate':              toApiDate(startDate),
        'Description':             description,
        'IsActive':                true,
        'EmployeeName':            empName1,
        'EmployeeName1':           empName2,
        'EmployeeName2':           empName3,
        'UploadImage':             (attachments != null && attachments.isNotEmpty) ? attachments[0] : '',
        'UploadImage1':            (attachments != null && attachments.length > 1) ? attachments[1] : '',
        'CreatedDate':             DateTime.now().toIso8601String(),
        'ModifiedDate':            DateTime.now().toIso8601String(),
        'Createdby':               int.tryParse(myId) ?? 0,
        'Updatedby':               int.tryParse(myId) ?? 0,
      };

      final res = await http.post(Uri.parse(_taskSubmitUrl),
          headers: _noAuthHeaders, body: jsonEncode(body));
      debugPrint('assignTask [${res.statusCode}]: ${res.body}');

      if (res.statusCode == 200) {
        final decoded   = jsonDecode(res.body) as Map<String, dynamic>;
        final statusCode = decoded['statuscode'] as int? ?? 0;
        final message    = decoded['message']?.toString() ?? '';
        if (statusCode == 200) {
          // Build a Data stub to insert optimistically
          final newData = Data(
            sProjectId:            selectedProjectId,
            projectName:           projectName,
            employeeId:            emp1Id,
            employeeId1:           emp2Id > 0 ? emp2Id : null,
            employeeName:          empName1,
            employeeName1:         empName2.isNotEmpty ? empName2 : null,
            proDescription:        description,
            deliveryEstimateDate1: toApiDate(dueDate),
            endDeliveryEstimateDate1: toApiDate(dueDate),
            allocateDate:          toApiDate(startDate),
            recurrence:            recurrence,
            priority:              priority,
            aStatus:               TaskStatus.pending,
            taskTittle:            title,
            tokenId:               _generateToken(),
            isActive:              true,
            createdDate:           DateTime.now().toIso8601String(),
            modifiedDate:          DateTime.now().toIso8601String(),
            createdby:             int.tryParse(myId) ?? 0,
            updatedby:             int.tryParse(myId) ?? 0,
          );
          allTasks.insert(0, newData);
          allTasks.refresh();
          Get.back();
          Get.snackbar(
            'Success',
            message.isNotEmpty ? message : 'Task assigned successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF4CAF50),
            colorText: Colors.white,
          );
          _syncProjectTaskWorks();
        } else {
          Get.snackbar('Failed',
              message.isNotEmpty ? message : 'Could not assign task',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: const Color(0xFFE53935),
              colorText: Colors.white);
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to assign task: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSubmitting(false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // UPDATE / DELETE TASK
  // ─────────────────────────────────────────────────────────────────────

  Future<void> updateTask(String taskId, Map<String, dynamic> body) async {
    try {
      isSubmitting(true);

      final teamLeadIdStr = (body['team_lead_ids'] as String? ?? '').split(',').first.trim();
      final teamLeadIdx   = int.tryParse(teamLeadIdStr) ?? 0;
      final teamLeadName  = employees
          .firstWhereOrNull((e) => e.employeeId == teamLeadIdx)
          ?.employeeName ?? '';

      final selectedProjectId = int.tryParse(body['project_id']?.toString() ?? '') ?? 0;

      String toApiDate(String? d) {
        try { return DateFormat('yyyy-MM-dd').format(DateFormat('dd-MM-yyyy').parse(d ?? '')); }
        catch (_) { return d ?? ''; }
      }

      final apiBody = <String, dynamic>{
        'SProjectId':              selectedProjectId,
        'ProjectId':               selectedProjectId,
        'EmployeeId':              0,
        'TaskTittle':              body['title'],
        'ProDescription':          body['description'],
        'UploadAllotFile':         '',
        'DeliveryEstimateDate1':   toApiDate(body['due_date']?.toString()),
        'EndDeliveryEstimateDate1':toApiDate(body['due_date']?.toString()),
        'Recurrence':              body['recurrence'],
        'Priority':                body['priority'],
        'TokenId':                 _generateToken(),
        'AssignBy':                int.tryParse(myId) ?? 0,
        'ProjectName':             body['project_name'] ?? '',
        'AssignById':              int.tryParse(myId) ?? 0,
        'AssignDate':              toApiDate(body['start_date']?.toString()),
        'Description':             body['description'],
        'EmployeeName':            teamLeadName,
        'ModifiedDate':            DateTime.now().toIso8601String(),
        'Updatedby':               int.tryParse(myId) ?? 0,
      };

      final res = await http.post(Uri.parse(_taskSubmitUrl),
          headers: _noAuthHeaders, body: jsonEncode(apiBody));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        if ((decoded['statuscode'] as int? ?? 0) == 200) {
          Get.back();
          Get.snackbar('Updated', 'Task updated successfully',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: const Color(0xFF4CAF50),
              colorText: Colors.white);
          fetchAll();
        } else {
          Get.snackbar('Failed',
              decoded['message']?.toString() ?? 'Could not update task',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: const Color(0xFFE53935),
              colorText: Colors.white);
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update task: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSubmitting(false);
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      allTasks.removeWhere((t) => t.uniqueId == taskId);
      final res = await http.delete(
          Uri.parse('$_taskDeleteUrl/$taskId'),
          headers: _noAuthHeaders);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        if ((decoded['statuscode'] as int? ?? 0) == 200) {
          Get.snackbar('Deleted', 'Task removed successfully',
              snackPosition: SnackPosition.BOTTOM);
        } else {
          fetchAll();
          Get.snackbar('Failed',
              decoded['message']?.toString() ?? 'Could not delete task',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: const Color(0xFFE53935),
              colorText: Colors.white);
        }
      } else { fetchAll(); }
    } catch (e) { fetchAll(); }
  }

  // ─────────────────────────────────────────────────────────────────────
  // STATUS ACTIONS
  // ─────────────────────────────────────────────────────────────────────

  Future<void> markDone(String taskId, {String description = 'Task completed'}) async {
    final task = allTasks.firstWhereOrNull((t) => t.uniqueId == taskId);
    if (task == null) return;

    final hasJunior        = (task.juniorId ?? '').trim().isNotEmpty;
    final hasTLAboveWorker = hasJunior &&
        task.teamLeadId.trim().isNotEmpty &&
        task.teamLeadId != task.assignedById;

    final nextStatus = hasTLAboveWorker
        ? TaskStatus.awaitingTL
        : TaskStatus.awaitingPM;

    _patchLocal(taskId, nextStatus);
    final ok = await _pushProgressUpdate(
      taskId: taskId, status: nextStatus,
      description: description, progress: 100,
    );
    Get.snackbar(
      ok ? 'Submitted' : 'Submitted (offline)',
      hasTLAboveWorker
          ? 'Task submitted — awaiting team lead review'
          : 'Task submitted — awaiting PM approval',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF4CAF50),
      colorText: Colors.white,
    );
  }

  Future<void> leadApprove(String taskId) async {
    const nextStatus = TaskStatus.awaitingPM;
    _patchLocal(taskId, nextStatus);
    final ok = await _pushProgressUpdate(
      taskId: taskId, status: nextStatus,
      description: 'Approved by team lead — awaiting PM approval',
    );
    Get.snackbar(
      ok ? 'Approved' : 'Approved (offline)',
      'Team lead approved — awaiting project manager',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF4CAF50),
      colorText: Colors.white,
    );
  }

  Future<void> leadReject(String taskId, String remark) async {
    final remarkModel = RemarkModel(
      rejectedBy: myName.isNotEmpty ? myName : 'Team Lead',
      remark:     remark,
      rejectedAt: DateTime.now().toIso8601String(),
    );
    _patchLocal(taskId, TaskStatus.tlRejected, leadRemark: remarkModel);
    final ok = await _pushProgressUpdate(
        taskId: taskId, status: TaskStatus.tlRejected, description: remark);
    Get.snackbar(
      ok ? 'Rejected' : 'Rejected (offline)',
      'Task rejected by team lead',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFE53935),
      colorText: Colors.white,
    );
  }

  Future<void> pmApprove(String taskId) async {
    _localOverrides.remove(taskId);
    _patchLocal(taskId, TaskStatus.approved);
    final ok = await _pushProgressUpdate(
      taskId: taskId, status: TaskStatus.approved,
      description: 'Approved by project manager',
    );
    Get.snackbar(
      ok ? 'Approved' : 'Approved (offline)',
      'Task approved by project manager',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF4CAF50),
      colorText: Colors.white,
    );
  }

  Future<void> pmReject(String taskId, String remark) async {
    final remarkModel = RemarkModel(
      rejectedBy: myName.isNotEmpty ? myName : 'Project Manager',
      remark:     remark,
      rejectedAt: DateTime.now().toIso8601String(),
    );
    _patchLocal(taskId, TaskStatus.pmRejected, pmRemark: remarkModel);
    final ok = await _pushProgressUpdate(
        taskId: taskId, status: TaskStatus.pmRejected, description: remark);
    Get.snackbar(
      ok ? 'Rejected' : 'Rejected (offline)',
      'Task rejected by project manager',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFE53935),
      colorText: Colors.white,
    );
  }

  Future<void> assignerApprove(String taskId) async {
    final nextStatus = isProjectManager ? TaskStatus.approved : TaskStatus.awaitingPM;
    _patchLocal(taskId, nextStatus);
    final ok = await _pushProgressUpdate(
        taskId: taskId, status: nextStatus, description: 'Approved by assigner');
    Get.snackbar(
      ok ? 'Approved' : 'Approved (offline)',
      isProjectManager ? 'Task approved' : 'Approved — awaiting project manager',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF4CAF50),
      colorText: Colors.white,
    );
  }

  Future<void> assignerReject(String taskId, String remark) async {
    final remarkModel = RemarkModel(
      rejectedBy: myName.isNotEmpty ? myName : 'Assigner',
      remark:     remark,
      rejectedAt: DateTime.now().toIso8601String(),
    );
    _patchLocal(taskId, 'AssignerRejected', assignerRemark: remarkModel);
    final ok = await _pushProgressUpdate(
        taskId: taskId, status: 'AssignerRejected', description: remark);
    Get.snackbar(
      ok ? 'Rejected' : 'Rejected (offline)',
      'Task rejected',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFE53935),
      colorText: Colors.white,
    );
  }

  Future<bool> _pushProgressUpdate({
    required String taskId,
    required String status,
    String description = '',
    int    progress   = 100,
  }) async {
    final aStatus     = _mapToAStatus(status);
    final task        = allTasks.firstWhereOrNull((t) => t.uniqueId == taskId);
    var   proAllocatId = task?.proAllocatId ?? 0;
    if (proAllocatId == 0) proAllocatId = int.tryParse(taskId) ?? 0;

    debugPrint('⚙️ pushProgressUpdate taskId=$taskId proAllocatId=$proAllocatId status=$status aStatus=$aStatus');

    final body = <String, dynamic>{
      'ProAllocatId':       proAllocatId,
      'EmpDescription':     description.isNotEmpty ? description : 'Status updated to $status',
      'Progress':           progress,
      'AStatus':            aStatus,
      'ProgressUpdateBy':   myId,
      'ProgressUpdateByName': myName,
      'UpdatedStatus':      status,
      'Remark':             description,
      'RejectedBy':         myName,
      'RejectedAt':         DateTime.now().toIso8601String(),
    };

    debugPrint('Initial body: $body');

    if (task != null) {
      if (task.assignedById.isNotEmpty) {
        final assignById = int.tryParse(task.assignedById) ?? 0;
        if (assignById > 0) body['AssignById'] = assignById;
        body['AssignBy'] = task.assignedByName;
      }
      if (proAllocatId == 0) {
        final numId = int.tryParse(taskId) ?? 0;
        if (numId > 0) {
          body['TokenId'] = numId; body['AssignId'] = numId; body['id'] = numId;
        } else {
          body['TokenId'] = taskId; body['AssignId'] = taskId; body['id'] = taskId;
        }
      }
    }

    for (final useAuth in [false, true]) {
      try {
        final res = await http
            .post(Uri.parse(_progressUpdateUrl),
                headers: useAuth ? _authHeaders : _noAuthHeaders,
                body: jsonEncode(body))
            .timeout(const Duration(seconds: 12));
        debugPrint('_pushProgressUpdate auth=$useAuth [${res.statusCode}]: ${res.body}');
        if (res.statusCode == 200) {
          try {
            final decoded = jsonDecode(res.body) as Map<String, dynamic>;
            if ((decoded['statuscode'] as int? ?? 0) == 200) {
              await _notifyStatusChange(
                  taskId: taskId, proAllocatId: proAllocatId,
                  status: aStatus, description: description);
              return true;
            }
          } catch (_) {
            await _notifyStatusChange(
                taskId: taskId, proAllocatId: proAllocatId,
                status: aStatus, description: description);
            return true;
          }
        }
      } catch (e) { debugPrint('_pushProgressUpdate error: $e'); }
    }
    return false;
  }

  Future<void> _notifyStatusChange({
    required String taskId,
    required int    proAllocatId,
    required String status,
    String          description = '',
  }) async {
    try {
      final task = allTasks.firstWhereOrNull((t) => t.uniqueId == taskId);
      final body = <String, dynamic>{
        'ProAllocatId':    proAllocatId,
        'TokenId':         task?.tokenId ?? taskId,
        'AssignId':        taskId,
        'id':              taskId,
        'AStatus':         status,
        'overall_status':  status,
        'ProgressUpdateBy': myId,
        'UpdatedBy':       int.tryParse(myId) ?? 0,
        'Updatedby':       int.tryParse(myId) ?? 0,
        'updated_by_id':   myId,
        'updated_by_name': myName,
        'ModifiedDate':    DateTime.now().toIso8601String(),
        'EmpDescription':  description,
        if (task != null) ...{
          'SProjectId':    task.sProjectId ?? 0,
          'EmployeeId':    task.employeeId ?? 0,
          'TaskTittle':    task.taskTittle ?? '',
          'Priority':      task.priority   ?? '',
          'AssignById':    int.tryParse(task.assignedById) ?? 0,
          'AssignBy':      task.assignedByName,
        },
      };
      for (final useAuth in [false, true]) {
        try {
          final res = await http
              .post(Uri.parse(_taskUpdateUrl),
                  headers: useAuth ? _authHeaders : _noAuthHeaders,
                  body: jsonEncode(body))
              .timeout(const Duration(seconds: 10));
          if (res.statusCode == 200) return;
        } catch (e) { debugPrint('_notifyStatusChange error: $e'); }
      }
    } catch (e) { debugPrint('_notifyStatusChange outer error: $e'); }
  }

  String _mapToAStatus(String status) {
    switch (status) {
      case TaskStatus.awaitingTL:
      case 'AwaitingAssignerApproval':
      case TaskStatus.awaitingPM:
      case TaskStatus.submitted:  return 'Done';
      case TaskStatus.approved:   return 'Approved';
      case TaskStatus.tlRejected:
      case 'AssignerRejected':
      case TaskStatus.pmRejected: return 'Rejected';
      case TaskStatus.pending:    return 'Pending';
      default:                    return status;
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // ALLOCATE PROJECT TEAM
  // ─────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> allocateProjectTeam({
    required int    projectId,
    required int    employeeId,
    required String taskTitle,
    required String description,
    required String deliveryDate,
    required String endDeliveryDate,
    String recurrence    = 'None',
    String priority      = 'Medium',
    String tokenId       = '',
    String uploadAllotFile = '',
  }) async {
    try {
      isSubmitting(true);
      final body = <String, dynamic>{
        'SProjectId':              projectId,
        'EmployeeId':              employeeId,
        'TaskTittle':              taskTitle,
        'ProDescription':          description,
        'UploadAllotFile':         uploadAllotFile,
        'DeliveryEstimateDate1':   deliveryDate,
        'EndDeliveryEstimateDate1':endDeliveryDate,
        'Recurrence':              recurrence,
        'Priority':                priority,
        'TokenId':                 tokenId.isNotEmpty ? tokenId : _generateToken(),
        'AssignBy':                int.tryParse(myId) ?? 0,
      };
      final res = await http.post(Uri.parse(_projectAllocateTeamUrl),
          headers: _noAuthHeaders, body: jsonEncode(body));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        if ((decoded['statuscode'] as int? ?? 0) == 200) {
          Get.snackbar(
              'Success', decoded['message']?.toString() ?? 'Team allocated',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: const Color(0xFF4CAF50),
              colorText: Colors.white);
          fetchAll();
          _syncProjectTaskWorks();
          return decoded;
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to allocate team: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally { isSubmitting(false); }
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────
  // UI HELPERS
  // ─────────────────────────────────────────────────────────────────────

  void switchTab(int i) {
    final nextIndex = i.clamp(0, _maxTabIndex).toInt();
    activeTab.value = nextIndex;
    selectedFilter.value = 'All';
    searchQuery.value    = '';
    if (isTeamLeader && nextIndex == 2) {
      if (!Get.isRegistered<ProjectController>()) Get.put(ProjectController());
      final pc = Get.find<ProjectController>();
      if (pc.tlProjects.isEmpty) pc.fetchTLProjects();
    }
  }

  void setFilter(String f) => selectedFilter.value = f;
  void setSearch(String q) => searchQuery.value    = q;
  void toggleSearch()      => isSearchExpanded.toggle();

  // ─────────────────────────────────────────────────────────────────────
  // PRIVATE HELPERS
  // ─────────────────────────────────────────────────────────────────────

  void _patchLocal(String taskId, String status, {
    RemarkModel? leadRemark,
    RemarkModel? assignerRemark,
    RemarkModel? pmRemark,
  }) {
    final existing = _localOverrides[taskId] ?? {};
    _localOverrides[taskId] = {
      ...existing,
      'status': status,
      if (leadRemark     != null) 'leadRemark':     leadRemark.toJson(),
      if (assignerRemark != null) 'assignerRemark': assignerRemark.toJson(),
      if (pmRemark       != null) 'pmRemark':       pmRemark.toJson(),
    };
    _box.write('task_overrides', _localOverrides.map((k, v) => MapEntry(k, v)));

    final i = allTasks.indexWhere((t) => t.uniqueId == taskId);
    if (i != -1) {
      allTasks[i] = allTasks[i].copyWith(
        overrideStatus: status,
        leadRemark:     leadRemark     ?? allTasks[i].leadRemark,
        assignerRemark: assignerRemark ?? allTasks[i].assignerRemark,
        pmRemark:       pmRemark       ?? allTasks[i].pmRemark,
      );
      allTasks.refresh();
    }
  }

  void _applyLocalOverrides() {
    if (_localOverrides.isEmpty) return;
    bool changed = false;
    for (int i = 0; i < allTasks.length; i++) {
      final t        = allTasks[i];
      final override = _localOverrides[t.uniqueId];
      if (override == null) continue;

      final overrideStatus = override['status'] as String?;
      final apiStatus      = t.aStatus ?? TaskStatus.pending;
      final overrideRank   = _statusRank(overrideStatus ?? '');
      final apiRank        = _statusRank(apiStatus);
      final apiIsTerminal  = TaskStatus.isApproved(apiStatus);
      final shouldApply    = !apiIsTerminal && overrideRank >= apiRank;

      if (!shouldApply) {
        _localOverrides.remove(t.uniqueId);
        _box.write('task_overrides', _localOverrides);
        continue;
      }

      RemarkModel? safeRemark(String key, RemarkModel? fallback) {
        try {
          final raw = override[key];
          if (raw == null) return fallback;
          return RemarkModel.fromJson(Map<String, dynamic>.from(raw as Map));
        } catch (_) { return fallback; }
      }

      allTasks[i] = t.copyWith(
        overrideStatus: overrideStatus,
        leadRemark:     safeRemark('leadRemark',     t.leadRemark),
        assignerRemark: safeRemark('assignerRemark', t.assignerRemark),
        pmRemark:       safeRemark('pmRemark',       t.pmRemark),
      );
      changed = true;
    }
    if (changed) allTasks.refresh();
  }

  int _statusRank(String status) {
    switch (status) {
      case TaskStatus.pending:                 return 0;
      case TaskStatus.submitted:               return 0;
      case TaskStatus.awaitingTL:              return 2;
      case 'AwaitingAssignerApproval':         return 3;
      case TaskStatus.awaitingPM:              return 4;
      case TaskStatus.tlRejected:
      case 'AssignerRejected':
      case TaskStatus.pmRejected:              return 5;
      case TaskStatus.approved:
      case 'Complete':                         return 6;
      default:                                 return 0;
    }
  }

  String _generateToken() {
    final rand  = DateTime.now().millisecondsSinceEpoch;
    final extra = rand % 0xFF;
    final hex8  = (rand ^ (rand >> 16)).toRadixString(16).padLeft(8, '0').substring(0, 8);
    final hex2  = extra.toRadixString(16).padLeft(2, '0').substring(0, 2);
    return 'Mont-$hex8-$hex2';
  }

  void _syncProjectTaskWorks() {
    try {
      if (Get.isRegistered(tag: 'ProjectController') == true) {
        // ignore: avoid_dynamic_calls
        (Get.find(tag: 'ProjectController') as dynamic).fetchProjectTaskWorks();
      }
    } catch (_) {}
  }

  int _resolveProjectId(String? projectId, String? projectName) {
    final parsedId = int.tryParse(projectId?.trim() ?? '') ?? 0;
    if (parsedId > 0) return parsedId;
    if (projectName?.trim().isNotEmpty == true && Get.isRegistered<ProjectController>()) {
      final pc = Get.find<ProjectController>();
      final match = pc.allProjects.firstWhereOrNull((p) =>
          p.projectName.trim().toLowerCase() == projectName!.trim().toLowerCase());
      if (match != null && match.projectId > 0) return match.projectId;
      final tlMatch = pc.tlProjects.firstWhereOrNull((p) =>
          p.data!.firstWhereOrNull((d) =>
              d.projectName?.trim().toLowerCase() == projectName!.trim().toLowerCase()) != null);
      if (tlMatch != null) {
        final matchedData = tlMatch.data!.firstWhere((d) =>
            d.projectName?.trim().toLowerCase() == projectName!.trim().toLowerCase());
        return matchedData.sProjectId ?? 0;
      }
    }
    return 0;
  }
}