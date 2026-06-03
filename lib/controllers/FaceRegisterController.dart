import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:monteage_employee/infrastructure/routes/admin_routes.dart';
import 'package:monteage_employee/infrastructure/utils/pref_const.dart';
import 'package:monteage_employee/infrastructure/utils/pref_manager.dart';

class FaceRegisterController extends GetxController {
  final box = GetStorage();
  final ImagePicker _picker = ImagePicker();

  final Rx<File?> selectedImage = Rx<File?>(null);
  final RxBool isSubmitting = false.obs;

  // ✅ Text controller for employee code input
  String get _employeeCode =>
    (Get.arguments?["employee_code"] ?? "").toString().trim();

  final String faceRegisterUrl =
      "http://att.monteage.co.in/attendance/api/face/register/";
  final String refreshApi =
      "http://att.monteage.co.in/attendance/api/auth/refresh/";

  

  // ---------- Snackbars ----------
  void _snackSuccess(String msg) {
    Get.snackbar(
      "Success",
      msg,
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFF16A34A),
      colorText: Colors.white,
    );
  }

  void _snackError(String msg) {
    Get.snackbar(
      "Error",
      msg,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  // ---------- Token ----------
  String get _accessToken =>
      (box.read("access_token") ?? "").toString().trim();
  String get _refreshToken =>
      (box.read("refresh_token") ?? "").toString().trim();

  // ---------- Pick/Clear ----------
  Future<void> takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );
      if (image == null) return;
      selectedImage.value = File(image.path);
    } catch (e) {
      _snackError("Camera failed: $e");
    }
  }

  void clearPhoto() => selectedImage.value = null;

  // ---------- Refresh Access Token ----------
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
    final newAccess = decoded["access"]?.toString() ?? "";
    if (newAccess.isEmpty) return false;

    await box.write("access_token", newAccess);
    return true;
  }

  // ---------- Submit ----------
  Future<void> submitRegistration() async {
    final img = selectedImage.value;
    if (img == null) {
      _snackError("Please capture your face image first.");
      return;
    }

    // ✅ Validate employee code entered by HR
    final empCode = _employeeCode;
if (empCode.isEmpty) {
  _snackError("Employee code not found. Please go back and try again.");
  return;
}

    isSubmitting.value = true;

    try {
      // 1st attempt
      final first = await _uploadFace(img, empCode);
      print("First attempt: ${first.statusCode} - ${first.message}");

      if (first.statusCode == 200 || first.statusCode == 201) {
        _snackSuccess("Face registered successfully!");
        await PrefManager()
            .writeValue(key: PrefConst.isregistered, value: "true");
        Get.offAllNamed(AdminRoutes.mainScreen);
        return;
      }

      // If unauthorized -> refresh token -> retry once
      if (first.statusCode == 401) {
        final refreshed = await _refreshAccessToken();
        if (!refreshed) {
          _snackError("Session expired. Please login again.");
          Get.back(result: false);
          return;
        }

        final second = await _uploadFace(img, empCode);
        print("Retry attempt: ${second.statusCode} - ${second.message}");

        if (second.statusCode == 200 || second.statusCode == 201) {
          _snackSuccess("Face registered successfully!");
          await PrefManager()
              .writeValue(key: PrefConst.isregistered, value: "true");
          Get.offAllNamed(AdminRoutes.mainScreen);
          return;
        }

        _snackError(
            "Failed to register face: (${second.statusCode}) ${second.message}");
        return;
      }

      _snackError(
          "Failed to register face: (${first.statusCode}) ${first.message}");
    } catch (e) {
      _snackError("Face registration failed: $e");
    } finally {
      isSubmitting.value = false;
    }
  }

  // ---------- Actual Multipart Upload ----------
  Future<_UploadResult> _uploadFace(File img, String empCode) async {
    final req = http.MultipartRequest("POST", Uri.parse(faceRegisterUrl));

    
    req.headers["Accept"] = "application/json";

    // ✅ Send employee_code as form field
    req.fields["employee_id"] = empCode;

    req.files.add(await http.MultipartFile.fromPath("image", img.path));

    print("===== UPLOAD DEBUG =====");
    print("Token: $_accessToken");
    print("Employee Code: '$empCode'");
    print("Fields: ${req.fields}");
    print("========================");

    final res = await req.send();
    final body = await res.stream.bytesToString();

    print("Response: ${res.statusCode} - $body");

    String msgFromServer = body;
    try {
      final decoded = body.isNotEmpty ? jsonDecode(body) : null;
      if (decoded is Map<String, dynamic>) {
        msgFromServer =
            (decoded["message"] ?? decoded["detail"] ?? decoded["error"] ?? body)
                .toString();
      }
    } catch (_) {}

    return _UploadResult(statusCode: res.statusCode, message: msgFromServer);
  }
}

class _UploadResult {
  final int statusCode;
  final String message;
  _UploadResult({required this.statusCode, required this.message});
}