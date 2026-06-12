import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart'; // ✅ add this import
import '../models/totalattendanceview_model.dart';

class TotalAttendanceViewController extends GetxController {
  var attendanceData = <Results>[].obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var count = 0.obs;
  var selectedDate = ''.obs;
  final String baseUrl = "https://att.monteage.co.in/";

  // ✅ Create HTTP client that bypasses SSL
  http.Client _createClient() {
    final ioClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    return IOClient(ioClient);
  }

  @override
  void onInit() {
    super.onInit();
    fetchattendance();
  }

  Future<void> fetchattendance({String? startDate, String? endDate, String? search}) async {
    final url = Uri.parse("http://att.monteage.co.in/attendance/api/employees/history/");

    try {
      isLoading.value = true;
      errorMessage.value = '';

      Map<String, String> queryParams = {};
      if (startDate != null && endDate != null) {
        queryParams['start_date'] = startDate;
        queryParams['end_date'] = endDate;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final client = _createClient(); // ✅ use custom client
      try {
        final request = http.Request(
          'GET',
          url.replace(queryParameters: queryParams),
        );

        final streamedResponse = await client
            .send(request)
            .timeout(const Duration(seconds: 60));

        final response = await http.Response.fromStream(streamedResponse)
            .timeout(const Duration(seconds: 60));

        if (response.statusCode == 200) {
          final jsonData = json.decode(response.body);
          final attendanceResponse = totalattendance.fromJson(jsonData);
          attendanceData.value = attendanceResponse.results ?? [];
          count.value = attendanceResponse.count ?? 0;
        } else {
          errorMessage.value = "Failed to load attendance. Status code: ${response.statusCode}";
        }
      } finally {
        client.close();
      }

    } on TimeoutException {
      errorMessage.value = "Request timed out. Server is taking too long.";
    } on SocketException catch (e) {
      errorMessage.value = "No internet connection: $e";
    } catch (e) {
      errorMessage.value = "Error fetching attendance data: $e";
    } finally {
      isLoading.value = false;
    }
  }

  String fullImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return "";
    if (path.startsWith("http://") || path.startsWith("https://")) return path;
    return "$baseUrl$path";
  }

  void updateSelectedDate(String date) {
    selectedDate.value = date;
    fetchattendance(startDate: date, endDate: date);
  }
}