class LoginEmployeeModel {
  final String employeeId;
  final String employeeName;
  final String employeeCode;
  final String email;
  final String contactNo;
  final String designation;
  final String photo;

  LoginEmployeeModel({
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    required this.email,
    required this.contactNo,
    required this.designation,
    required this.photo,
  });

  factory LoginEmployeeModel.fromJson(Map<String, dynamic> json) {
    return LoginEmployeeModel(
      employeeId: json['EmployeeId']?.toString() ?? '',
      employeeName: json['EmployeeName'] ?? '',
      employeeCode: json['EmployeeCode'] ?? '',
      email: json['Email'] ?? '',
      contactNo: json['ContactNo'] ?? '',
      designation: json['Designation'] ?? '',
      photo: json['Photo'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'EmployeeId': employeeId,
      'EmployeeName': employeeName,
      'EmployeeCode': employeeCode,
      'Email': email,
      'ContactNo': contactNo,
      'Designation': designation,
      'Photo': photo,
      
    };
  }
}