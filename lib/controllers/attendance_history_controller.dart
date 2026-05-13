import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';

import '../models/attendance_history_model.dart';

class AttendanceHistoryController extends GetxController {
  final box = GetStorage();

  final String baseUrl = "http://att.monteage.co.in/";
  final String historyApi =
      "http://att.monteage.co.in/attendance/api/attendance/history/";
  final String refreshApi =
      "http://att.monteage.co.in/attendance/api/auth/refresh/";

  final isLoading = false.obs;
  final Rxn<Statistics> statistics = Rxn<Statistics>();

  final RxList<Result> records = <Result>[].obs;
  final TextEditingController searchDateController = TextEditingController();
  final selectedMonth = ''.obs;
  final selectedStatusFilter = 'All'.obs;
  final RxMap<String, int> remarkCounts = <String, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    selectedMonth.value =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    fetchHistory();
  }

  @override
  void onClose() {
    searchDateController.dispose();
    super.onClose();
  }

  String get _accessToken =>
      (box.read("access_token") ?? "").toString().trim();
  String get _refreshToken =>
      (box.read("refresh_token") ?? "").toString().trim();
  String get _employeeId =>
      (box.read("employee_id") ?? "").toString().trim();
  String get _employeeCode =>
      (box.read("employee_code") ?? "").toString().trim();

  Uri get _historyUri {
    final identifier = _employeeCode.isNotEmpty ? _employeeCode : _employeeId;
    if (identifier.isEmpty) return Uri.parse(historyApi);
    return Uri.parse(historyApi).replace(
      queryParameters: {
        'employee_id': identifier,
      },
    );
  }

  void setMonth(String monthKey) {
    selectedMonth.value = monthKey;
    selectedStatusFilter.value = 'All';
  }

  void setStatusFilter(String filter) {
    selectedStatusFilter.value = filter;
  }

  List<Result> get filteredRecords {
    final all = records.toList();
    final month = selectedMonth.value;
    if (month.isEmpty) return all;
    return all.where((r) => (r.date ?? '').startsWith(month)).toList();
  }

  List<Result> get displayRecords {
    final all = records.toList();
    final month = selectedMonth.value;
    final filter = selectedStatusFilter.value;

    var list = month.isEmpty
        ? all
        : all.where((r) => (r.date ?? '').startsWith(month)).toList();

    if (filter == 'All') return list;
    return list
        .where((r) => combinedStatus(r) == filter.toUpperCase())
        .toList();
  }

  Future<void> fetchHistory() async {
    isLoading.value = true;
    try {
      final res = await _authorizedGet(_historyUri);
      print(res);
      print(_historyUri.toString());

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        final data = AttendanceResponse.fromJson(decoded);
        print(data);

        statistics.value = data.statistics;

        for (var record in data.results) {
          if (record.latitude != null && record.longitude != null) {
            record.address = await _getAddressFromCoordinates(
                record.latitude!, record.longitude!);
          }
        }

        records.assignAll(data.results);
        _computeRemarkCounts(data.results);
        return;
      }

      // ✅ 401 no longer forces logout — just shows error
      if (res.statusCode == 401) {
        Get.snackbar(
          "Error",
          "Unable to load attendance history. Please try again.",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      Get.snackbar(
        "Error",
        "Failed to load attendance history (HTTP ${res.statusCode})",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString(),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _computeRemarkCounts(List<Result> results) {
    final Map<String, int> counts = {
      "On Time": 0,
      "Late": 0,
      "Short Leave (AM)": 0,
      "Short Leave (PM)": 0,
      "Half Day": 0,
      "Over Time": 0,
    };
    for (final r in results) {
      final remark = getAttendanceRemark(r);
      counts[remark] = (counts[remark] ?? 0) + 1;
    }
    remarkCounts.assignAll(counts);
  }

  Future<String> _getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      final place = placemarks[0];
      return "${place.name}, ${place.locality}, ${place.country}";
    } catch (_) {
      return "Address not found";
    }
  }

  String getAttendanceRemark(Result record) {
    String checkInRemark = "On Time";
    if (record.timestamp != null && record.timestamp!.trim().isNotEmpty) {
      try {
        final dt = DateTime.parse(record.timestamp!).toLocal();
        final checkInMinutes = dt.hour * 60 + dt.minute;

        if (checkInMinutes >= 720) {
          checkInRemark = "Half Day";
        } else if (checkInMinutes >= 630) {
          checkInRemark = "Short Leave (AM)";
        } else if (checkInMinutes >= 610) {
          checkInRemark = "Late";
        }
      } catch (_) {}
    }

    String checkOutRemark = "On Time";
    if (record.checkoutTimestamp != null &&
        record.checkoutTimestamp!.trim().isNotEmpty) {
      try {
        final dt = DateTime.parse(record.checkoutTimestamp!).toLocal();
        final checkOutMinutes = dt.hour * 60 + dt.minute;

        if (checkOutMinutes < 810) {
          checkOutRemark = "Half Day";
        } else if (checkOutMinutes >= 960 && checkOutMinutes <= 1090) {
          checkOutRemark = "Short Leave (PM)";
        }
      } catch (_) {}
    }

    int totalMinutes = 0;
    if (record.timestamp != null &&
        record.checkoutTimestamp != null &&
        record.timestamp!.isNotEmpty &&
        record.checkoutTimestamp!.isNotEmpty) {
      try {
        final checkIn = DateTime.parse(record.timestamp!).toLocal();
        final checkOut = DateTime.parse(record.checkoutTimestamp!).toLocal();
        totalMinutes = checkOut.difference(checkIn).inMinutes;
      } catch (_) {}
    }

    const priority = {
      "Half Day": 5,
      "Short Leave (AM)": 4,
      "Short Leave (PM)": 3,
      "Late": 2,
      "Over Time": 1,
      "On Time": 0,
    };

    final ciP = priority[checkInRemark] ?? 0;
    final coP = priority[checkOutRemark] ?? 0;
    final finalRemark = ciP >= coP ? checkInRemark : checkOutRemark;

    const int overtimeThreshold = 8 * 60 + 35;
    if (totalMinutes >= overtimeThreshold &&
        checkInRemark == "On Time" &&
        checkOutRemark == "On Time") {
      return "Over Time";
    }

    return finalRemark;
  }

  Color remarkColor(String remark) {
    switch (remark) {
      case "Half Day":
        return const Color(0xFF9B6CF9);
      case "Short Leave (AM)":
      case "Short Leave (PM)":
        return const Color(0xFFF0A43C);
      case "Late":
        return const Color(0xFFD85E5E);
      case "Over Time":
        return const Color(0xFF1E88E5);
      case "On Time":
      default:
        return const Color(0xFF2AB673);
    }
  }

  void applyDateFilter(String ddMMyyyy) {
    final q = ddMMyyyy.trim();
    if (q.isEmpty) {
      clearFilter();
      return;
    }
    final monthRecords = filteredRecords;
    final matched =
        monthRecords.where((r) => formatToDdMmYyyy(r.date) == q).toList();

    selectedStatusFilter.value = 'All';
    _dateSearchResults.assignAll(matched);
    _isDateSearchActive.value = true;
  }

  final RxList<Result> _dateSearchResults = <Result>[].obs;
  final RxBool _isDateSearchActive = false.obs;

  void clearFilter() {
    searchDateController.clear();
    _dateSearchResults.clear();
    _isDateSearchActive.value = false;
    selectedStatusFilter.value = 'All';
  }

  List<Result> get effectiveDisplayRecords {
    records.toList();
    if (_isDateSearchActive.value) return _dateSearchResults.toList();
    return displayRecords;
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
    if (path == null || path.trim().isEmpty) return "";
    if (path.startsWith("http://") || path.startsWith("https://")) return path;
    return "$baseUrl$path";
  }

  String titleCase(String? input) {
    final s = (input ?? "").trim();
    if (s.isEmpty) return "--";
    return s
        .split(RegExp(r"\s+"))
        .where((w) => w.isNotEmpty)
        .map((w) =>
            w[0].toUpperCase() +
            (w.length > 1 ? w.substring(1).toLowerCase() : ""))
        .join(" ");
  }

  String formatToDdMmYyyy(String? isoOrDate) {
    if (isoOrDate == null || isoOrDate.trim().isEmpty) return "--";
    try {
      DateTime d;
      if (isoOrDate.length == 10 && isoOrDate.contains("-")) {
        d = DateTime.parse(isoOrDate);
      } else {
        d = DateTime.parse(isoOrDate).toLocal();
      }
      return DateFormat("dd-MM-yyyy").format(d.toLocal());
    } catch (_) {
      return "--";
    }
  }

  String formatIsoTime(String? iso) {
    if (iso == null || iso.trim().isEmpty) return "--";
    try {
      final d = DateTime.parse(iso).toLocal();
      return DateFormat("hh:mm a").format(d);
    } catch (_) {
      return "--";
    }
  }

  String formatIsoDateTime(String? iso) {
    if (iso == null || iso.trim().isEmpty) return "--";
    try {
      final d = DateTime.parse(iso).toLocal();
      return DateFormat("dd-MM-yyyy hh:mm a").format(d);
    } catch (_) {
      return "--";
    }
  }

  String combinedStatus(Result r) {
    final checkIn = (r.status ?? '').toUpperCase();
    final checkOut = (r.checkoutStatus ?? '').toUpperCase();

    if (checkIn == 'REJECTED' || checkOut == 'REJECTED') return 'REJECTED';
    if (checkIn == 'PENDING' || checkOut == 'PENDING') return 'PENDING';
    if (checkIn == 'VERIFIED' && checkOut == 'VERIFIED') return 'VERIFIED';

    return checkIn;
  }
}