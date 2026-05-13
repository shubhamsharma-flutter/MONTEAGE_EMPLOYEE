import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/profile_model.dart';
import '../screens/FaceRegisterScreen.dart';

class EmployeeProfileController extends GetxController {
  final box = GetStorage();

  final String baseUrl = "http://att.monteage.co.in/";
  final String profileApi =
      "http://att.monteage.co.in/attendance/api/auth/profile/";
  final String refreshApi =
      "http://att.monteage.co.in/attendance/api/auth/refresh/";

  final isLoading = false.obs;
  final Rxn<ProfileModel> profile = Rxn<ProfileModel>();

  String get _accessToken => (box.read("access_token") ?? "").toString().trim();
  String get _refreshToken =>
      (box.read("refresh_token") ?? "").toString().trim();
  String get _employeeId => (box.read("employee_id") ?? "").toString().trim();
  String get _employeeCode =>
      (box.read("employee_code") ?? "").toString().trim();

  Uri get _profileUri {
    final identifier = _employeeCode.isNotEmpty ? _employeeCode : _employeeId;
    if (identifier.isEmpty) return Uri.parse(profileApi);
    return Uri.parse(
      profileApi,
    ).replace(queryParameters: {'employee_id': identifier});
  }

  @override
  void onInit() {
    super.onInit();

    fetchProfile();
  }

  void resetProfileState() {
    profile.value = null;
    isLoading.value = false;
  }

  Future<void> goToFaceRegister() async {
    final result = await Get.to(() => const FaceRegisterScreen());
    if (result == true) {
      await fetchProfile(showSuccess: true);
    }
  }

  void _snackSuccess(String title, String msg) {
    Get.snackbar(
      title,
      msg,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  void _snackError(String title, String msg) {
    Get.snackbar(
      title,
      msg,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  Future<void> fetchProfile({bool showSuccess = false}) async {
    profile.value = null;
    isLoading.value = true;
    try {
      final res = await _authorizedGet(_profileUri);

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        final p = ProfileModel.fromJson(decoded);
        profile.value = p;

        if (p.user.isFaceRegistered == false) {
          _snackError(
            "Face Not Registered",
            "Register face first, then profile will be shown.",
          );
        } else {
          if (showSuccess)
            _snackSuccess("Success", "Profile loaded successfully.");
        }
        return;
      }

      if (res.statusCode == 401) {
        _snackError("Error", "Unable to load profile. Please try again later.");
        return;
      }

      _snackError("Error", "Profile load failed (HTTP ${res.statusCode})");
    } catch (e) {
      _snackError("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<http.Response> _authorizedGet(Uri uri) async {
    final res = await http.get(uri, headers: {"Accept": "application/json"});

    if (res.statusCode != 401) return res;

    final refreshed = await _refreshAccessToken();
    if (!refreshed) return res;

    return http.get(uri, headers: {"Accept": "application/json"});
  }

  Future<bool> _refreshAccessToken() async {
    if (_refreshToken.isEmpty) return false;

    final res = await http.post(
      Uri.parse(refreshApi),
      headers: const {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({"refresh": _refreshToken}),
    );

    if (res.statusCode != 200) return false;

    final decoded = jsonDecode(res.body);
    final newAccess = decoded['access']?.toString() ?? "";
    if (newAccess.isEmpty) return false;

    await box.write("access_token", newAccess);
    return true;
  }

  String fullImageUrl(String? path) {
    final p = (path ?? "").trim();
    if (p.isEmpty) return "";
    if (p.startsWith("http://") || p.startsWith("https://")) return p;
    return "$baseUrl$p";
  }

  String titleCase(String? input) {
    final s = (input ?? "").trim();
    if (s.isEmpty) return "--";
    return s
        .split(RegExp(r"\s+"))
        .where((w) => w.isNotEmpty)
        .map(
          (w) =>
              w[0].toUpperCase() +
              (w.length > 1 ? w.substring(1).toLowerCase() : ""),
        )
        .join(" ");
  }

  String formatDateTimeIndian(DateTime? dt) {
    if (dt == null) return "--";
    return DateFormat("dd-MM-yyyy hh:mm a").format(dt.toLocal());
  }

  String formatDateOnlyIndian(DateTime? dt) {
    if (dt == null) return "--";
    return DateFormat("dd-MM-yyyy").format(dt.toLocal());
  }
}
