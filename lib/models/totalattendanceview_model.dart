class totalattendance {
  int? count;
  Filters? filters;
  List<Results>? results;
 
  totalattendance({this.count, this.filters, this.results});
 
  totalattendance.fromJson(Map<String, dynamic> json) {
    count = json['count'];
    filters =
        json['filters'] != null ? new Filters.fromJson(json['filters']) : null;
    if (json['results'] != null) {
      results = <Results>[];
      json['results'].forEach((v) {
        results!.add(new Results.fromJson(v));
      });
    }
  }
 
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['count'] = this.count;
    if (this.filters != null) {
      data['filters'] = this.filters!.toJson();
    }
    if (this.results != null) {
      data['results'] = this.results!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
 
class Filters {
  String? department;
  String? search;
  String? startDate;
  String? endDate;
  String? month;
  String? year;
 
  Filters(
      {this.department,
      this.search,
      this.startDate,
      this.endDate,
      this.month,
      this.year});
 
  Filters.fromJson(Map<String, dynamic> json) {
    department = json['department'];
    search = json['search'];
    startDate = json['start_date'];
    endDate = json['end_date'];
    month = json['month'];
    year = json['year'];
  }
 
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['department'] = this.department;
    data['search'] = this.search;
    data['start_date'] = this.startDate;
    data['end_date'] = this.endDate;
    data['month'] = this.month;
    data['year'] = this.year;
    return data;
  }
}
 
class Results {
  int? id;
  String? employeeId;
  String? username;
  String? fullName;
  String? email;
  String? department;
  String? profileImage;
  Summary? summary;
  List<AttendanceHistory>? attendanceHistory;
 
  Results(
      {this.id,
      this.employeeId,
      this.username,
      this.fullName,
      this.email,
      this.department,
      this.profileImage,
      this.summary,
      this.attendanceHistory});
 
  Results.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    employeeId = json['employee_id'];
    username = json['username'];
    fullName = json['full_name'];
    email = json['email'];
    department = json['department'];
    profileImage = json['profile_image'];
    summary =
        json['summary'] != null ? new Summary.fromJson(json['summary']) : null;
    if (json['attendance_history'] != null) {
      attendanceHistory = <AttendanceHistory>[];
      json['attendance_history'].forEach((v) {
        attendanceHistory!.add(new AttendanceHistory.fromJson(v));
      });
    }
  }
 
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['employee_id'] = this.employeeId;
    data['username'] = this.username;
    data['full_name'] = this.fullName;
    data['email'] = this.email;
    data['department'] = this.department;
    data['profile_image'] = this.profileImage;
    if (this.summary != null) {
      data['summary'] = this.summary!.toJson();
    }
    if (this.attendanceHistory != null) {
      data['attendance_history'] =
          this.attendanceHistory!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
 
class Summary {
  int? totalDays;
  int? verified;
  int? pending;
  int? rejected;
  int? checkedOut;
  int? notCheckedOut;
 
  Summary(
      {this.totalDays,
      this.verified,
      this.pending,
      this.rejected,
      this.checkedOut,
      this.notCheckedOut});
 
  Summary.fromJson(Map<String, dynamic> json) {
    totalDays = json['total_days'];
    verified = json['verified'];
    pending = json['pending'];
    rejected = json['rejected'];
    checkedOut = json['checked_out'];
    notCheckedOut = json['not_checked_out'];
  }
 
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['total_days'] = this.totalDays;
    data['verified'] = this.verified;
    data['pending'] = this.pending;
    data['rejected'] = this.rejected;
    data['checked_out'] = this.checkedOut;
    data['not_checked_out'] = this.notCheckedOut;
    return data;
  }
}
 
class AttendanceHistory {
  String? date;
  String? checkInTime;
  String? checkOutTime;
  String? totalTime;
  String? status;
  String? checkoutStatus;
  double? confidenceScore;
  double? checkoutConfidenceScore;
  String? imageUrl;
  String? checkoutImageUrl;
  String? locationAddress;
  String? checkoutLocationAddress;
  double? latitude;
  double? longitude;
  double? checkoutLatitude;
  double? checkoutLongitude;
  bool? isSuspicious;
  String? suspiciousReason;
 
  AttendanceHistory(
      {this.date,
      this.checkInTime,
      this.checkOutTime,
      this.totalTime,
      this.status,
      this.checkoutStatus,
      this.confidenceScore,
      this.checkoutConfidenceScore,
      this.imageUrl,
      this.checkoutImageUrl,
      this.locationAddress,
      this.checkoutLocationAddress,
      this.latitude,
      this.longitude,
      this.checkoutLatitude,
      this.checkoutLongitude,
      this.isSuspicious,
      this.suspiciousReason});
 
  AttendanceHistory.fromJson(Map<String, dynamic> json) {
    date = json['date'];
    checkInTime = json['check_in_time'];
    checkOutTime = json['check_out_time'];
    totalTime = json['total_time'];
    status = json['status'];
    checkoutStatus = json['checkout_status'];
    confidenceScore = json['confidence_score'];
    checkoutConfidenceScore = json['checkout_confidence_score'];
    imageUrl = json['image_url'];
    checkoutImageUrl = json['checkout_image_url'];
    locationAddress = json['location_address'];
    checkoutLocationAddress = json['checkout_location_address'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    checkoutLatitude = json['checkout_latitude'];
    checkoutLongitude = json['checkout_longitude'];
    isSuspicious = json['is_suspicious'];
    suspiciousReason = json['suspicious_reason'];
  }
 
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['date'] = this.date;
    data['check_in_time'] = this.checkInTime;
    data['check_out_time'] = this.checkOutTime;
    data['total_time'] = this.totalTime;
    data['status'] = this.status;
    data['checkout_status'] = this.checkoutStatus;
    data['confidence_score'] = this.confidenceScore;
    data['checkout_confidence_score'] = this.checkoutConfidenceScore;
    data['image_url'] = this.imageUrl;
    data['checkout_image_url'] = this.checkoutImageUrl;
    data['location_address'] = this.locationAddress;
    data['checkout_location_address'] = this.checkoutLocationAddress;
    data['latitude'] = this.latitude;
    data['longitude'] = this.longitude;
    data['checkout_latitude'] = this.checkoutLatitude;
    data['checkout_longitude'] = this.checkoutLongitude;
    data['is_suspicious'] = this.isSuspicious;
    data['suspicious_reason'] = this.suspiciousReason;
    return data;
  }
}
 