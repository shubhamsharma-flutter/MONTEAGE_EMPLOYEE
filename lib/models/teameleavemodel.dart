class teameleave {
  String? message;
  List<Data>? data;
  int? statuscode;
  int? totalCount;

  teameleave({this.message, this.data, this.statuscode, this.totalCount});

  teameleave.fromJson(Map<String, dynamic> json) {
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
  int? employeeLeaveId;
  int? employeeId;
  String? employeeCode;
  String? employeeName;
  int? leaveTypeId;
  String? leaveType;
  String? years;
  int? totalLeave;
  int? totalTakenLeave;
  int? totalBalanceLeave;
  String? createBy;
  String? createDate;
  int? eLeaveAId;
  String? leaveReason;
  int? leaveNoofday;
  String? fromDate;
  String? toDate;
  String? descriptionImageFile;
  String? descriptionImage;
  String? approveStatus1;
  String? approveStatus2;
  String? approveStatus3;
  String? approveby1;
  String? approveby2;
  String? approveby3;
  bool? isActive;
  String? createdDate;
  String? date;
  String? modifiedDate;
  int? createdby;
  int? updatedby;

  Data({
    this.employeeLeaveId,
    this.employeeId,
    this.employeeCode,
    this.employeeName,
    this.leaveTypeId,
    this.leaveType,
    this.years,
    this.totalLeave,
    this.totalTakenLeave,
    this.totalBalanceLeave,
    this.createBy,
    this.createDate,
    this.eLeaveAId,
    this.leaveReason,
    this.leaveNoofday,
    this.fromDate,
    this.toDate,
    this.descriptionImageFile,
    this.descriptionImage,
    this.approveStatus1,
    this.approveStatus2,
    this.approveStatus3,
    this.approveby1,
    this.approveby2,
    this.approveby3,
    this.isActive,
    this.createdDate,
    this.date,
    this.modifiedDate,
    this.createdby,
    this.updatedby,
  });

  Data.fromJson(Map<String, dynamic> json) {
    employeeLeaveId = json['EmployeeLeaveId'];
    employeeId = json['EmployeeId'];
    employeeCode = json['EmployeeCode'];
    employeeName = json['EmployeeName'];
    leaveTypeId = json['LeaveTypeId'];
    leaveType = json['LeaveType'];
    years = json['Years'];
    totalLeave = json['TotalLeave'];
    totalTakenLeave = json['TotalTakenLeave'];
    totalBalanceLeave = json['TotalBalanceLeave'];
    createBy = json['CreateBy'];
    createDate = json['CreateDate'];
    eLeaveAId = json['ELeaveAId'];
    leaveReason = json['LeaveReason'];
    leaveNoofday = json['LeaveNoofday'];
    fromDate = json['FromDate'];
    toDate = json['ToDate'];
    descriptionImageFile = json['DescriptionImageFile'];
    descriptionImage = json['DescriptionImage'];
    approveStatus1 = json['ApproveStatus1'];
    approveStatus2 = json['ApproveStatus2'];
    approveStatus3 = json['ApproveStatus3'];
    approveby1 = json['Approveby1'];
    approveby2 = json['Approveby2'];
    approveby3 = json['Approveby3'];
    isActive = json['IsActive'];
    createdDate = json['CreatedDate'];
    date = json['Date'];
    modifiedDate = json['ModifiedDate'];
    createdby = json['Createdby'];
    updatedby = json['Updatedby'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['EmployeeLeaveId'] = this.employeeLeaveId;
    data['EmployeeId'] = this.employeeId;
    data['EmployeeCode'] = this.employeeCode;
    data['EmployeeName'] = this.employeeName;
    data['LeaveTypeId'] = this.leaveTypeId;
    data['LeaveType'] = this.leaveType;
    data['Years'] = this.years;
    data['TotalLeave'] = this.totalLeave;
    data['TotalTakenLeave'] = this.totalTakenLeave;
    data['TotalBalanceLeave'] = this.totalBalanceLeave;
    data['CreateBy'] = this.createBy;
    data['CreateDate'] = this.createDate;
    data['ELeaveAId'] = this.eLeaveAId;
    data['LeaveReason'] = this.leaveReason;
    data['LeaveNoofday'] = this.leaveNoofday;
    data['FromDate'] = this.fromDate;
    data['ToDate'] = this.toDate;
    data['DescriptionImageFile'] = this.descriptionImageFile;
    data['DescriptionImage'] = this.descriptionImage;
    data['ApproveStatus1'] = this.approveStatus1;
    data['ApproveStatus2'] = this.approveStatus2;
    data['ApproveStatus3'] = this.approveStatus3;
    data['Approveby1'] = this.approveby1;
    data['Approveby2'] = this.approveby2;
    data['Approveby3'] = this.approveby3;
    data['IsActive'] = this.isActive;
    data['CreatedDate'] = this.createdDate;
    data['Date'] = this.date;
    data['ModifiedDate'] = this.modifiedDate;
    data['Createdby'] = this.createdby;
    data['Updatedby'] = this.updatedby;
    return data;
  }
}
