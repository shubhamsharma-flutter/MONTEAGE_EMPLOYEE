class RegisterResponseModel {
  final String message;
  final String? accessToken;
  final String? refreshToken;
  final String? employeeId;
 
  RegisterResponseModel({
    required this.message,
    this.accessToken,
    this.refreshToken,
    this.employeeId,
  });
 
  factory RegisterResponseModel.fromJson(Map<String, dynamic> json) {
    return RegisterResponseModel(
      message: json['message']?.toString() ?? '',
      accessToken: json['tokens']?['access']?.toString(),
      refreshToken: json['tokens']?['refresh']?.toString(),
      employeeId: json['user']?['employee_id']?.toString(),
    );
  }
}
 