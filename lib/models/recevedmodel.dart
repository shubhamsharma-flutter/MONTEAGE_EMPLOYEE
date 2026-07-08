class receivedmodel {
  String? message;
  List<RData>? data;
  int? statuscode;
  int? totalCount;

  receivedmodel({this.message, this.data, this.statuscode, this.totalCount});

  receivedmodel.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    if (json['data'] != null) {
      data = <RData>[];
      json['data'].forEach((v) {
        data!.add(new RData.fromJson(v));
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

class RData {
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

  RData(
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

  RData.fromJson(Map<String, dynamic> json) {
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