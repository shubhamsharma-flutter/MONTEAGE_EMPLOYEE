/*// controllers/mark_face_attendance_controller.dart
import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
class MarkFaceAttendanceController extends GetxController {
  final ImagePicker _picker = ImagePicker();
  final box = GetStorage();

  // Image
  final Rx<File?> selectedImage = Rx<File?>(null);

  // Lat/Lng + Address
  final RxString latText = "--".obs;
  final RxString lngText = "--".obs;
  final RxString addressText = "Fetching current location...".obs;

  // Loading
  final RxBool isLocLoading = false.obs;
  final RxBool isSubmittingAttendance = false.obs;

  // API URLs
  final String attendanceUrl =
      "http://103.251.143.196/attendance/api/attendance/mark/";

  String _tokenOrThrow() {
    final token = (box.read("access_token") ?? "").toString().trim();
    if (token.isEmpty) {
      throw Exception(
        "Access token missing. Save token in GetStorage as 'access_token' at login.",
      );
    }
    return token;
  }

  bool _isValidLatLng(String v) => double.tryParse(v) != null;

  // -----------------------------
  // Auto fetch safe method (call this from screen)
  // -----------------------------
  Future<void> ensureLocationFetched() async {
    if (isLocLoading.value) return; // don't spam
    await fetchLocationAll();
  }

Future<void> fetchLocationAll() async {
  try {
    isLocLoading.value = true;
    addressText.value = "Fetching current location...";

    // 1️⃣ Check GPS service
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      latText.value = "GPS OFF";
      lngText.value = "GPS OFF";
      addressText.value = "Location service is OFF. Please enable GPS.";
      return;
    }

    // 2️⃣ Check permission
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      latText.value = "DENIED";
      lngText.value = "DENIED";
      addressText.value = "Location permission denied.";
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      latText.value = "SETTINGS";
      lngText.value = "SETTINGS";
      addressText.value =
          "Location permission permanently denied. Enable from Settings.";
      return;
    }

    // 3️⃣ Fetch position
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    latText.value = pos.latitude.toStringAsFixed(6);
    lngText.value = pos.longitude.toStringAsFixed(6);

    // 4️⃣ Reverse geocode
    final placemarks = await placemarkFromCoordinates(
      pos.latitude,
      pos.longitude,
    );

    if (placemarks.isEmpty) {
      addressText.value = "Address not found (Lat/Lng available).";
      return;
    }

    final p = placemarks.first;
    final parts = <String>[
      if ((p.name ?? "").trim().isNotEmpty) p.name!.trim(),
      if ((p.street ?? "").trim().isNotEmpty) p.street!.trim(),
      if ((p.subLocality ?? "").trim().isNotEmpty) p.subLocality!.trim(),
      if ((p.locality ?? "").trim().isNotEmpty) p.locality!.trim(),
      if ((p.administrativeArea ?? "").trim().isNotEmpty)
        p.administrativeArea!.trim(),
      if ((p.postalCode ?? "").trim().isNotEmpty) p.postalCode!.trim(),
      if ((p.country ?? "").trim().isNotEmpty) p.country!.trim(),
    ];

    addressText.value = parts.join(", ");
  } catch (e) {
    latText.value = "ERROR";
    lngText.value = "ERROR";
    addressText.value = "Failed to fetch location.";
    Get.snackbar(
      "Error",
      "Location failed: $e",
      snackPosition: SnackPosition.TOP,
    );
  } finally {
    isLocLoading.value = false;
  }
}

  // -----------------------------
  // Take Photo using Camera
  // -----------------------------
  Future<void> takePhoto() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );
      if (picked == null) return;

      selectedImage.value = File(picked.path);

      // refresh location after photo (optional)
      await fetchLocationAll();
    } catch (e) {
      Get.snackbar("Error", "Camera failed: $e",
          snackPosition: SnackPosition.TOP);
    }
  }

  void clearPhoto() => selectedImage.value = null;

  // -----------------------------
  // COMMON MULTIPART SENDER
  // -----------------------------
  Future<_ApiResult> _postMultipart({
    required String url,
    required Map<String, String> fields,
    required File imageFile,
  }) async {
    final token = _tokenOrThrow();

    final req = http.MultipartRequest("POST", Uri.parse(url));
    req.headers["Authorization"] = "Bearer $token";
    req.headers["Accept"] = "application/json";
    req.fields.addAll(fields);

    req.files.add(await http.MultipartFile.fromPath("image", imageFile.path));

    final res = await req.send();
    final body = await res.stream.bytesToString();

    Map<String, dynamic>? jsonBody;
    try {
      jsonBody = body.isNotEmpty ? jsonDecode(body) : null;
    } catch (_) {
      jsonBody = null;
    }

    return _ApiResult(
      statusCode: res.statusCode,
      rawBody: body,
      json: jsonBody,
    );
  }

  // -----------------------------
  // TODAY'S ATTENDANCE SUBMIT
  // -----------------------------
  Future<void> submitAttendance() async {
    final img = selectedImage.value;

    if (img == null) {
      Get.snackbar("Missing Photo", "Please take/upload a photo first.",
          snackPosition: SnackPosition.TOP);
      return;
    }

    final lat = latText.value.trim();
    final lng = lngText.value.trim();

    if (!_isValidLatLng(lat) || !_isValidLatLng(lng)) {
      Get.snackbar("Location Required", "Please enable location and refresh.",
          snackPosition: SnackPosition.TOP);
      return;
    }

    try {
      isSubmittingAttendance.value = true;

      final result = await _postMultipart(
        url: _attendanceUri.toString(),
        fields: {
          "latitude": lat,
          "longitude": lng,
          "employee_id": _employeeCode.isNotEmpty ? _employeeCode : _employeeId,
        },
        imageFile: img,
      );
debugPrint(result.rawBody);
debugPrint(_attendanceUri.toString());
debugPrint(img.path);
      if (result.statusCode == 200 || result.statusCode == 201) {
        Get.snackbar("Success", "Today's attendance saved successfully!",
            snackPosition: SnackPosition.TOP);
      } else {
        final msg = result.json?["message"] ?? result.rawBody;
        Get.snackbar("Failed", "(${result.statusCode}) $msg",
            snackPosition: SnackPosition.TOP);
            debugPrint("Attendance submit failed: ${result.rawBody}");
      }
    } catch (e) {
      Get.snackbar("Error", "Submit failed: $e",
          snackPosition: SnackPosition.TOP);
    } finally {
      isSubmittingAttendance.value = false;
    }
  }
}

class _ApiResult {
  final int statusCode;
  final String rawBody;
  final Map<String, dynamic>? json;

  _ApiResult({
    required this.statusCode,
    required this.rawBody,
    required this.json,
  });
}
*/

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../services/attendance_sync_service.dart';

class MarkFaceAttendanceController extends GetxController {
  final ImagePicker _picker = ImagePicker();
  final box = GetStorage();

  // Image
  final Rx<File?> selectedImage = Rx<File?>(null);

  // Lat/Lng + Address
  final RxString latText = "--".obs;
  final RxString lngText = "--".obs;
  final RxString addressText = "Fetching current location...".obs;

  // Loading
  final RxBool isLocLoading = false.obs;
  final RxBool isSubmittingAttendance = false.obs;

  // API URLs
  final String attendanceUrl =
      "http://att.monteage.co.in/attendance/api/attendance/mark/";
  final String profileApi =
      "http://att.monteage.co.in/attendance/api/auth/profile/";

  // Employee Identifiers
  String get _employeeId => (box.read("employee_id") ?? "").toString().trim();
  String get _employeeCode =>
      (box.read("employee_code") ?? "").toString().trim();

  Uri get _attendanceUri {
    if (_employeeCode.isEmpty) return Uri.parse(attendanceUrl);
    return Uri.parse(
      attendanceUrl,
    ).replace(queryParameters: {'employee_code': _employeeCode});
  }

  Uri get _profileUri {
    final identifier = _employeeCode.isNotEmpty ? _employeeCode : _employeeId;
    if (identifier.isEmpty) return Uri.parse(profileApi);
    return Uri.parse(
      profileApi,
    ).replace(queryParameters: {'employee_id': identifier});
  }

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

  void _snackError(String title, String msg) {
    Get.snackbar(
      title,
      msg,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  bool _isValidLatLng(String v) => double.tryParse(v) != null;

  // -----------------------------
  // Auto fetch safe method
  // -----------------------------
  Future<void> ensureLocationFetched() async {
    if (isLocLoading.value) return;
    await fetchLocationAll();
  }

  Future<void> fetchLocationAll() async {
    try {
      isLocLoading.value = true;
      addressText.value = "Fetching current location...";

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        latText.value = "GPS OFF";
        lngText.value = "GPS OFF";
        addressText.value = "Location service is OFF. Please enable GPS.";
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        latText.value = "DENIED";
        lngText.value = "DENIED";
        addressText.value = "Location permission denied.";
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        latText.value = "SETTINGS";
        lngText.value = "SETTINGS";
        addressText.value =
            "Location permission permanently denied. Enable from Settings.";
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      latText.value = pos.latitude.toStringAsFixed(6);
      lngText.value = pos.longitude.toStringAsFixed(6);

      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );

      if (placemarks.isEmpty) {
        addressText.value = "Address not found (Lat/Lng available).";
        return;
      }

      final p = placemarks.first;
      final parts = <String>[
        if ((p.name ?? "").trim().isNotEmpty) p.name!.trim(),
        if ((p.street ?? "").trim().isNotEmpty) p.street!.trim(),
        if ((p.subLocality ?? "").trim().isNotEmpty) p.subLocality!.trim(),
        if ((p.locality ?? "").trim().isNotEmpty) p.locality!.trim(),
        if ((p.administrativeArea ?? "").trim().isNotEmpty)
          p.administrativeArea!.trim(),
        if ((p.postalCode ?? "").trim().isNotEmpty) p.postalCode!.trim(),
        if ((p.country ?? "").trim().isNotEmpty) p.country!.trim(),
      ];

      addressText.value = parts.join(", ");
    } catch (e) {
      latText.value = "ERROR";
      lngText.value = "ERROR";
      addressText.value = "Failed to fetch location.";
      _snackError("Error", "Location failed: $e");
    } finally {
      isLocLoading.value = false;
    }
  }

  // -----------------------------
  // Take Photo
  // -----------------------------
  Future<void> takePhoto() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );
      if (picked == null) return;

      selectedImage.value = File(picked.path);
      await fetchLocationAll();
    } catch (e) {
      _snackError("Error", "Camera failed: $e");
    }
  }

  void clearPhoto() => selectedImage.value = null;

  // -----------------------------
  // Face registered guard (MANDATORY)
  // -----------------------------
  Future<bool> _ensureFaceRegistered() async {
    try {
      final res = await http.get(
        _profileUri,
        headers: {"Accept": "application/json"},
      );
      debugPrint(_profileUri.toString());
      if (res.statusCode != 200) {
        _snackError("Error", "Profile check failed (HTTP ${res.statusCode})");
        return false;
      }

      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      final user = decoded["user"] as Map<String, dynamic>?;

      final bool isFaceRegistered =
          (user?["is_face_registered"] == true) ||
          (user?["isFaceRegistered"] == true);

      if (!isFaceRegistered) {
        _snackError(
          "Face Not Registered",
          "Register face first, then mark attendance.",
        );
        Get.toNamed("/face-register"); // ✅ route must exist
        return false;
      }

      return true;
    } catch (e) {
      _snackError("Error", "Face check failed: $e");
      return false;
    }
  }

  // -----------------------------
  // Multipart helper
  // -----------------------------
  Future<_ApiResult> _postMultipart({
    required String url,
    required Map<String, String> fields,
    required File imageFile,
  }) async {
    final req = http.MultipartRequest("POST", Uri.parse(url));
    req.headers["Accept"] = "application/json";
    req.fields.addAll(fields);
    req.files.add(await http.MultipartFile.fromPath("image", imageFile.path));

    final res = await req.send();
    final body = await res.stream.bytesToString();

    Map<String, dynamic>? jsonBody;
    try {
      jsonBody = body.isNotEmpty ? jsonDecode(body) : null;
    } catch (_) {
      jsonBody = null;
    }

    return _ApiResult(
      statusCode: res.statusCode,
      rawBody: body,
      json: jsonBody,
    );
  }

  // -----------------------------
  // Submit Attendance (face match must happen on backend)
  // -----------------------------
  Future<void> submitAttendance() async {
    final img = selectedImage.value;
    if (img == null) {
      _snackError("Missing Photo", "Please take/upload a photo first.");
      return;
    }

    final lat = latText.value.trim();
    final lng = lngText.value.trim();

    if (!_isValidLatLng(lat) || !_isValidLatLng(lng)) {
      _snackError("Location Required", "Please enable location and refresh.");
      return;
    }

    try {
      isSubmittingAttendance.value = true;

      final ok = await _ensureFaceRegistered();
      if (!ok) return;

      final url = _attendanceUri.toString();
      final fields = {
        "latitude": lat,
        "longitude": lng,
        "employee_id ": _employeeCode,
      };

      debugPrint("── ATTENDANCE SUBMIT ──────────────────");
      debugPrint("URL       : $url");
      debugPrint("Fields    : $fields");
      debugPrint("Image     : ${img.path}");
      debugPrint("────────────────────────────────────────");

      final result = await _postMultipart(
        url: url,
        fields: fields,
        imageFile: img,
      );

      debugPrint("STATUS    : ${result.statusCode}");
      debugPrint("RESPONSE  : ${result.rawBody}");

      if (result.statusCode == 200 || result.statusCode == 201) {
        _snackSuccess("Attendance marked successfully!");
      } else {
        final msg =
            (result.json?["message"] ??
                    result.json?["detail"] ??
                    result.json?["error"] ??
                    result.rawBody)
                .toString();
        _snackError("Failed", "(${result.statusCode}) $msg");
      }
    } catch (e) {
      debugPrint("EXCEPTION : $e");
      _snackError("Error", "Submit failed: $e");
    } finally {
      isSubmittingAttendance.value = false;
    }
  }
}

class _ApiResult {
  final int statusCode;
  final String rawBody;
  final Map<String, dynamic>? json;

  _ApiResult({
    required this.statusCode,
    required this.rawBody,
    required this.json,
  });
}
