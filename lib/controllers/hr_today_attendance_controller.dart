import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../models/hr_today_attendance_model.dart';

class HrTodayAttendanceController extends GetxController {
  var attendanceData = <HrTodayAttendanceModel>[].obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var count = 0.obs;
  final String baseUrl = "http://att.monteage.co.in/";

  @override
  void onInit() {
    super.onInit();
    fetchAttendance();
  }

  Future<void> fetchAttendance() async {
    const url = "http://att.monteage.co.in/attendance/api/employees/";

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final parsed = HrTodayAttendanceResponse.fromJson(jsonData);

        attendanceData.value = parsed.results;
        count.value = parsed.count;
      } else {
        errorMessage.value =
            "Failed to load attendance. Status code: ${response.statusCode}";
      }
    } catch (e) {
      errorMessage.value = "Error fetching attendance data: $e";
    } finally {
      isLoading.value = false;
    }
  }

  /// ---------------- HELPERS ----------------
  String fullImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return "";
    if (path.startsWith("http://") || path.startsWith("https://")) return path;
    return "$baseUrl$path";
  }
}
