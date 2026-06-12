class ProjectModel {
  final int projectId;
  final String projectName;
  final String clientName;
  final String mobileNo;
  final String email;
  final String description;
  final String projectDetails;
  final String projectStatus;
  final String productService;
  final String subProductService;
  final String projectDate;
  final String deliveryDate;
  final String assignDate;
  final String? referenceUrl;
  final String? uploadProjectImg;
  final String assignedTo; // ProAssName
  final double completeProgress;
  final List<String> modules;

  ProjectModel({
    required this.projectId,
    required this.projectName,
    required this.clientName,
    required this.mobileNo,
    required this.email,
    required this.description,
    required this.projectDetails,
    required this.projectStatus,
    required this.productService,
    required this.subProductService,
    required this.projectDate,
    required this.deliveryDate,
    required this.assignDate,
    this.referenceUrl,
    this.uploadProjectImg,
    required this.assignedTo,
    required this.completeProgress,
    required this.modules,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> j) {
    final modules = <String>[];
    for (int i = 1; i <= 10; i++) {
      final m = j['Module$i'];
      if (m != null && m.toString().trim().isNotEmpty) {
        modules.add(m.toString().trim());
      }
    }

    String _safeDate(dynamic val) {
      if (val == null) return '';
      final s = val.toString();
      if (s.startsWith('0001')) return '';
      return s.split('T').first;
    }

    return ProjectModel(
      projectId: int.tryParse(j['SProjectId']?.toString() ?? '') ?? 0,
      projectName: j['ProjectName']?.toString() ?? '',
      clientName: j['ClientName']?.toString() ?? '',
      mobileNo: j['MobileNo'] ?? '',
      email: j['Email'] ?? '',
      description: j['Description'] ?? '',
      projectDetails: j['ProjectDetails'] ?? '',
      projectStatus: j['ProjectStatus'] ?? '',
      productService: j['ProductService'] ?? '',
      subProductService: j['SubProductService'] ?? '',
      projectDate: _safeDate(j['ProjectDate']),
      deliveryDate: _safeDate(j['DeliveryDate']),
      assignDate: _safeDate(j['AssignDate']),
      referenceUrl: j['ReferenceURL'],
      uploadProjectImg: j['UploadProjectImg'],
      assignedTo: j['ProAssName'] ?? '',
      completeProgress: (j['CompleteProgress'] ?? 0).toDouble(),
      modules: modules,
    );
  }

  String get dropdownLabel => projectName;
}

extension ProjectModelCopyWith on ProjectModel {
  ProjectModel copyWith({
    int? projectId,
    String? projectName,
    String? clientName,
    String? mobileNo,
    String? email,
    String? description,
    String? projectDetails,
    String? projectStatus,
    String? productService,
    String? subProductService,
    String? projectDate,
    String? deliveryDate,
    String? assignDate,
    String? referenceUrl,
    String? uploadProjectImg,
    String? assignedTo,
    double? completeProgress,
    List<String>? modules,
  }) {
    return ProjectModel(
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      clientName: clientName ?? this.clientName,
      mobileNo: mobileNo ?? this.mobileNo,
      email: email ?? this.email,
      description: description ?? this.description,
      projectDetails: projectDetails ?? this.projectDetails,
      projectStatus: projectStatus ?? this.projectStatus,
      productService: productService ?? this.productService,
      subProductService: subProductService ?? this.subProductService,
      projectDate: projectDate ?? this.projectDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      assignDate: assignDate ?? this.assignDate,
      referenceUrl: referenceUrl ?? this.referenceUrl,
      uploadProjectImg: uploadProjectImg ?? this.uploadProjectImg,
      assignedTo: assignedTo ?? this.assignedTo,
      completeProgress: completeProgress ?? this.completeProgress,
      modules: modules ?? this.modules,
    );
  }
}
