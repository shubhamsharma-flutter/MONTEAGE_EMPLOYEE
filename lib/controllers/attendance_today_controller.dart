import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart' as geo;

import '../models/attendance_today.dart';

class AttendanceTodayController extends GetxController {
  final box = GetStorage();

  final String baseUrl = "http://att.monteage.co.in/";
  final String todayApi = "http://att.monteage.co.in/attendance/api/attendance/today/";
  final String refreshApi = "http://att.monteage.co.in/attendance/api/auth/refresh/";

  final isLoading = false.obs;
  final Rxn<AttendanceToday> today = Rxn<AttendanceToday>();
  final resolvedAddress = "--".obs;

  String get _access => (box.read("access_token") ?? "").toString().trim();
  String get _refresh => (box.read("refresh_token") ?? "").toString().trim();
  String get _employeeId => (box.read("employee_id") ?? "").toString().trim();
  String get _employeeCode => (box.read("employee_code") ?? "").toString().trim();

  Uri get _todayUri {
    final identifier = _employeeCode.isNotEmpty ? _employeeCode : _employeeId;
    if (identifier.isEmpty) return Uri.parse(todayApi);
    return Uri.parse(todayApi).replace(
      queryParameters: {
        'employee_id': identifier,
      },
    );
  }

  @override
  void onInit() {
    super.onInit();
    fetchToday();
  }

  Future<void> fetchToday() async {
    isLoading.value = true;
    try {
      final res = await _authorizedGet(_todayUri);

      if (res.statusCode == 200) {
        final decoded = Map<String, dynamic>.from(jsonDecode(res.body));
        today.value = AttendanceToday.fromJson(decoded);

        if (today.value != null && today.value?.location != null) {
          final location = today.value!.location;
          if (location.latitude != null &&
              location.longitude != null &&
              location.latitude != 0.0 &&
              location.longitude != 0.0) {
            fetchLocationAndAddress(location);
          } else {
            resolvedAddress.value = "Invalid Location";
          }
        }
        return;
      }

      // ✅ 401 no longer forces logout
      if (res.statusCode == 401) {
        Get.snackbar(
          "Error",
          "Unable to load today's attendance. Please try again.",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      Get.snackbar(
        "Error",
        "Failed (HTTP ${res.statusCode})",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Attendance",
        "Please mark your attendance first",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchLocationAndAddress(Location location) async {
    if (location.latitude == null ||
        location.longitude == null ||
        location.latitude == 0.0 ||
        location.longitude == 0.0) {
      resolvedAddress.value = "Invalid Location";
      return;
    }

    try {
      final address = await _getAddressFromCoordinates(
          location.latitude!, location.longitude!);
      resolvedAddress.value = address;
    } catch (e) {
      resolvedAddress.value = "Address not found";
    }
  }

  Future<String> _getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      List<geo.Placemark> placemarks =
          await geo.placemarkFromCoordinates(latitude, longitude);
      geo.Placemark place = placemarks[0];
      return "${place.name}, ${place.locality}, ${place.country}";
    } catch (e) {
      return "Address not found";
    }
  }

  Future<http.Response> _authorizedGet(Uri uri) async {
    final res = await http.get(
      uri,
      headers: {
       
        "Accept": "application/json",
      },
    );

    if (res.statusCode != 401) return res;

   

    return http.get(
      uri,
      headers: {
       
        "Accept": "application/json",
      },
    );
  }

  Future<bool> _refreshToken() async {
    if (_refresh.isEmpty) return false;

    final res = await http.post(
      Uri.parse(refreshApi),
      headers: const {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({"refresh": _refresh}),
    );

    if (res.statusCode != 200) return false;

    final decoded = jsonDecode(res.body);
    final newAccess = decoded["access"]?.toString() ?? "";
    if (newAccess.isEmpty) return false;

    await box.write("access_token", newAccess);
    return true;
  }

  String cleanAddress(String? a) {
    final s = (a ?? "").trim();
    if (s.isEmpty) return "--";
    return s.replaceAll('\\"', '"').replaceAll('"', '').trim();
  }

  String fullImageUrl(String? path) {
    final p = (path ?? "").trim();
    if (p.isEmpty) return "";
    if (p.startsWith("http://") || p.startsWith("https://")) return p;
    return "$baseUrl$p";
  }
}