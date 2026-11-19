class LoginEmployeeModel {
  String? message;
  Data? data;
  int? statuscode;
  int? totalCount;

  LoginEmployeeModel({
    this.message,
    this.data,
    this.statuscode,
    this.totalCount,
  });

  LoginEmployeeModel.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
    statuscode = _toInt(json['statuscode']);
    totalCount = _toInt(json['totalCount']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['statuscode'] = this.statuscode;
    data['totalCount'] = this.totalCount;
    return data;
  }
}

class Data {
  int? employeeId;
  String? employeeId1;
  String? employeeName;
  String? employeeName1;
  String? createBy;
  String? updateBy;
  String? fatherName;
  String? contactNo;
  String? dateOfBirth;
  String? joinDate;
  String? dateOfBirth1;
  String? joinDate1;
  String? gender;
  String? maritalStatus;
  String? bloodGroup;
  String? email;
  String? presentAddress;
  String? permanentAddress;
  String? aadhaarNo;
  String? aadhaarPic;
  String? resume;
  String? photo;
  String? employeeCode;
  String? employeeCode1;
  String? password;
  String? newPassword;
  String? confirmPassword;
  String? oldPassword;
  String? createDate;
  String? updateDate;
  String? action;
  int? designationId;
  String? designation;
  int? roleId;
  String? roleType;
  String? assignBy;
  int? assignedStatus;
  int? assignedId;
  int? assignById;
  int? totalProjects;
  int? totalPending;
  int? totalComplete;
  int? totalHold;
  int? totalRunning;
  int? cId;
  bool? isActive;
  String? createdDate;
  String? date;
  String? modifiedDate;
  int? createdby;
  int? updatedby;

  Data({
    this.employeeId,
    this.employeeId1,
    this.employeeName,
    this.employeeName1,
    this.createBy,
    this.updateBy,
    this.fatherName,
    this.contactNo,
    this.dateOfBirth,
    this.joinDate,
    this.dateOfBirth1,
    this.joinDate1,
    this.gender,
    this.maritalStatus,
    this.bloodGroup,
    this.email,
    this.presentAddress,
    this.permanentAddress,
    this.aadhaarNo,
    this.aadhaarPic,
    this.resume,
    this.photo,
    this.employeeCode,
    this.employeeCode1,
    this.password,
    this.newPassword,
    this.confirmPassword,
    this.oldPassword,
    this.createDate,
    this.updateDate,
    this.action,
    this.designationId,
    this.designation,
    this.roleId,
    this.roleType,
    this.assignBy,
    this.assignedStatus,
    this.assignedId,
    this.assignById,
    this.totalProjects,
    this.totalPending,
    this.totalComplete,
    this.totalHold,
    this.totalRunning,
    this.cId,
    this.isActive,
    this.createdDate,
    this.date,
    this.modifiedDate,
    this.createdby,
    this.updatedby,
  });

  Data.fromJson(Map<String, dynamic> json) {
    employeeId = _toInt(json['EmployeeId']);
    employeeId1 = _toStr(json['EmployeeId1']);
    employeeName = _toStr(json['EmployeeName']);
    employeeName1 = _toStr(json['EmployeeName1']);
    createBy = _toStr(json['CreateBy']);
    updateBy = _toStr(json['UpdateBy']);
    fatherName = _toStr(json['FatherName']);
    contactNo = _toStr(json['ContactNo']);
    dateOfBirth = _toStr(json['DateOfBirth']);
    joinDate = _toStr(json['JoinDate']);
    dateOfBirth1 = _toStr(json['DateOfBirth1']);
    joinDate1 = _toStr(json['JoinDate1']);
    gender = _toStr(json['Gender']);
    maritalStatus = _toStr(json['MaritalStatus']);
    bloodGroup = _toStr(json['BloodGroup']);
    email = _toStr(json['Email']);
    presentAddress = _toStr(json['PresentAddress']);
    permanentAddress = _toStr(json['PermanentAddress']);
    aadhaarNo = _toStr(json['AadhaarNo']);
    aadhaarPic = _toStr(json['AadhaarPic']);
    resume = _toStr(json['Resume']);
    photo = _toStr(json['Photo']);
    employeeCode = _toStr(json['EmployeeCode']);
    employeeCode1 = _toStr(json['EmployeeCode1']);
    password = _toStr(json['Password']);
    newPassword = _toStr(json['NewPassword']);
    confirmPassword = _toStr(json['ConfirmPassword']);
    oldPassword = _toStr(json['OldPassword']);
    createDate = _toStr(json['CreateDate']);
    updateDate = _toStr(json['UpdateDate']);
    action = _toStr(json['Action']);
    designationId = _toInt(json['DesignationId']);
    designation = _toStr(json['Designation']);
    roleId = _toInt(json['RoleId']);
    roleType = _toStr(json['RoleType']);
    assignBy = _toStr(json['AssignBy']);
    assignedStatus = _toInt(json['AssignedStatus']);
    assignedId = _toInt(json['AssignedId']);
    assignById = _toInt(json['AssignById']);
    totalProjects = _toInt(json['TotalProjects']);
    totalPending = _toInt(json['TotalPending']);
    totalComplete = _toInt(json['TotalComplete']);
    totalHold = _toInt(json['TotalHold']);
    totalRunning = _toInt(json['TotalRunning']);
    cId = _toInt(json['CId']);
    isActive = _toBool(json['IsActive']);
    createdDate = _toStr(json['CreatedDate']);
    date = _toStr(json['Date']);
    modifiedDate = _toStr(json['ModifiedDate']);
    createdby = _toInt(json['Createdby']);
    updatedby = _toInt(json['Updatedby']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['EmployeeId'] = this.employeeId;
    data['EmployeeId1'] = this.employeeId1;
    data['EmployeeName'] = this.employeeName;
    data['EmployeeName1'] = this.employeeName1;
    data['CreateBy'] = this.createBy;
    data['UpdateBy'] = this.updateBy;
    data['FatherName'] = this.fatherName;
    data['ContactNo'] = this.contactNo;
    data['DateOfBirth'] = this.dateOfBirth;
    data['JoinDate'] = this.joinDate;
    data['DateOfBirth1'] = this.dateOfBirth1;
    data['JoinDate1'] = this.joinDate1;
    data['Gender'] = this.gender;
    data['MaritalStatus'] = this.maritalStatus;
    data['BloodGroup'] = this.bloodGroup;
    data['Email'] = this.email;
    data['PresentAddress'] = this.presentAddress;
    data['PermanentAddress'] = this.permanentAddress;
    data['AadhaarNo'] = this.aadhaarNo;
    data['AadhaarPic'] = this.aadhaarPic;
    data['Resume'] = this.resume;
    data['Photo'] = this.photo;
    data['EmployeeCode'] = this.employeeCode;
    data['EmployeeCode1'] = this.employeeCode1;
    data['Password'] = this.password;
    data['NewPassword'] = this.newPassword;
    data['ConfirmPassword'] = this.confirmPassword;
    data['OldPassword'] = this.oldPassword;
    data['CreateDate'] = this.createDate;
    data['UpdateDate'] = this.updateDate;
    data['Action'] = this.action;
    data['DesignationId'] = this.designationId;
    data['Designation'] = this.designation;
    data['RoleId'] = this.roleId;
    data['RoleType'] = this.roleType;
    data['AssignBy'] = this.assignBy;
    data['AssignedStatus'] = this.assignedStatus;
    data['AssignedId'] = this.assignedId;
    data['AssignById'] = this.assignById;
    data['TotalProjects'] = this.totalProjects;
    data['TotalPending'] = this.totalPending;
    data['TotalComplete'] = this.totalComplete;
    data['TotalHold'] = this.totalHold;
    data['TotalRunning'] = this.totalRunning;
    data['CId'] = this.cId;
    data['IsActive'] = this.isActive;
    data['CreatedDate'] = this.createdDate;
    data['Date'] = this.date;
    data['ModifiedDate'] = this.modifiedDate;
    data['Createdby'] = this.createdby;
    data['Updatedby'] = this.updatedby;
    return data;
  }
}

// The API is inconsistent about types (e.g. EmployeeId can arrive as "12"),
// so coerce instead of assigning directly.
int? _toInt(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '');

String? _toStr(dynamic v) => v?.toString();

bool? _toBool(dynamic v) {
  if (v is bool) return v;
  final s = v?.toString().toLowerCase();
  if (s == 'true' || s == '1') return true;
  if (s == 'false' || s == '0') return false;
  return null;
}
