import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/pending_attendance_model.dart';

class AttendanceSyncService {
  static const String boxName = 'pending_attendance';

  static const String checkInUrl =
      'http://att.monteage.co.in/attendance/api/attendance/mark/';
  static const String checkOutUrl =
      'http://att.monteage.co.in/attendance/api/attendance/checkout/';

  // ── Initialize Hive ───────────────────────────────────────────────────
  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(PendingAttendanceModelAdapter().typeId)) {
      Hive.registerAdapter(PendingAttendanceModelAdapter());
    }

    try {
      await Hive.openBox<PendingAttendanceModel>(boxName);
    } catch (e) {
      await Hive.deleteBoxFromDisk(boxName);
      await Hive.openBox<PendingAttendanceModel>(boxName);
      debugPrint('Recovered corrupted Hive box "$boxName": $e');
    }
  }

  // ── Save to Hive when offline ─────────────────────────────────────────
  static Future<void> savePending({
    required String type,
    required String latitude,
    required String longitude,
    required String imagePath,
  }) async {
    final box = Hive.box<PendingAttendanceModel>(boxName);
    await box.add(
      PendingAttendanceModel(
        type: type,
        latitude: latitude,
        longitude: longitude,
        imagePath: imagePath,

        savedAt: DateTime.now(),
      ),
    );
  }

  // ── Check internet ────────────────────────────────────────────────────
  static Future<bool> isConnected() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // ── Count pending records ─────────────────────────────────────────────
  static int pendingCount() {
    final box = Hive.box<PendingAttendanceModel>(boxName);
    return box.length;
  }

  // ── Sync all pending to API ───────────────────────────────────────────
  static Future<void> syncPending() async {
    final box = Hive.box<PendingAttendanceModel>(boxName);
    if (box.isEmpty) return;

    final connected = await isConnected();
    if (!connected) return;

    final List<int> successKeys = [];

    for (final key in box.keys) {
      final record = box.get(key);
      if (record == null) continue;

      final url = record.type == 'checkin' ? checkInUrl : checkOutUrl;
      final imageFile = File(record.imagePath);

      // Skip if image no longer exists
      if (!imageFile.existsSync()) {
        successKeys.add(key as int);
        continue;
      }

      try {
        final req = http.MultipartRequest('POST', Uri.parse(url));

        req.headers['Accept'] = 'application/json';
        req.fields['latitude'] = record.latitude;
        req.fields['longitude'] = record.longitude;
        req.files.add(
          await http.MultipartFile.fromPath('image', record.imagePath),
        );

        final res = await req.send();

        if (res.statusCode == 200 || res.statusCode == 201) {
          successKeys.add(key as int);
        }
      } catch (_) {
        // Skip failed — will retry next time
        continue;
      }
    }

    // Remove successfully synced records
    for (final key in successKeys) {
      await box.delete(key);
    }

    if (successKeys.isNotEmpty) {
      Get.snackbar(
        'Synced',
        '${successKeys.length} pending attendance record(s) synced successfully!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF16A34A),
        colorText: Colors.white,
      );
    }
  }

  // ── Listen for connectivity and auto sync ─────────────────────────────
  static void startAutoSync() {
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        syncPending();
      }
    });
  }
}
