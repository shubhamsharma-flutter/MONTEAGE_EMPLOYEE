// Model for the HR "Today's Attendance" tab.
// Backed by http://att.monteage.co.in/attendance/api/employees/
// which returns one row per employee with today's check-in/out snapshot
// (null fields mean that employee hasn't checked in yet today).

class HrTodayAttendanceModel {
  final String? employeeId;
  final String? fullName;
  final String? email;
  final String? department;
  final String? checkInDate;
  final String? checkInTime;
  final String? checkOutTime;
  final String? totalTime;
  final String? status;
  final String? imageUrl;
  final String? checkoutImageUrl;

  HrTodayAttendanceModel({
    this.employeeId,
    this.fullName,
    this.email,
    this.department,
    this.checkInDate,
    this.checkInTime,
    this.checkOutTime,
    this.totalTime,
    this.status,
    this.imageUrl,
    this.checkoutImageUrl,
  });

  factory HrTodayAttendanceModel.fromJson(Map<String, dynamic> json) {
    return HrTodayAttendanceModel(
      employeeId: json['employee_id']?.toString(),
      fullName: json['full_name']?.toString(),
      email: json['email']?.toString(),
      department: json['department']?.toString(),
      checkInDate: json['check_in_date']?.toString(),
      checkInTime: json['check_in_time']?.toString(),
      checkOutTime: json['check_out_time']?.toString(),
      totalTime: json['total_time']?.toString(),
      status: json['status']?.toString(),
      imageUrl: json['image_url']?.toString(),
      checkoutImageUrl: json['checkout_image_url']?.toString(),
    );
  }
}

class HrTodayAttendanceResponse {
  final int count;
  final List<HrTodayAttendanceModel> results;

  HrTodayAttendanceResponse({required this.count, required this.results});

  factory HrTodayAttendanceResponse.fromJson(Map<String, dynamic> json) {
    return HrTodayAttendanceResponse(
      count: json['count'] ?? 0,
      results: json['results'] == null
          ? <HrTodayAttendanceModel>[]
          : List<HrTodayAttendanceModel>.from(
              (json['results'] as List)
                  .map((x) => HrTodayAttendanceModel.fromJson(x)),
            ),
    );
  }
}
