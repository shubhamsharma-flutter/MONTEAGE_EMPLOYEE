/*// controllers/login_controller.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:monteage_employee/infrastructure/routes/admin_routes.dart';
import 'package:monteage_employee/infrastructure/utils/pref_const.dart';
import 'package:monteage_employee/infrastructure/utils/pref_manager.dart';

class LoginController extends GetxController {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  final isLoading = false.obs;
  final isPasswordHidden = true.obs;
  final isregistered = false.obs;

  final box = GetStorage();

  final String loginApi = "http://103.251.143.196/attendance/api/auth/login/";

  void togglePassword() => isPasswordHidden.value = !isPasswordHidden.value;

  void onForgotPassword() {
    Get.snackbar(
      "Info",
      "Forgot password flow not connected yet.",
      snackPosition: SnackPosition.TOP,
    );
  }
@override
  void onInit() async{
    super.onInit();
   isregistered.value = await PrefManager().readValue(key: PrefConst.isregistered) == "false";
  }

  /// ✅ Auto-skip login if tokens already exist
  bool get isLoggedIn {
    final access = (box.read("access_token") ?? "").toString().trim();
    final refresh = (box.read("refresh_token") ?? "").toString().trim();
    return access.isNotEmpty && refresh.isNotEmpty;
  }

  Future<void> loginUser() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      Get.snackbar(
        "Error",
        "Username and Password are required",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;

    try {
      final res = await http
          .post(
        Uri.parse(loginApi),
        headers: const {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({"email": username, "password": password}),
      )
          .timeout(const Duration(seconds: 20));

      if (kDebugMode) {
        debugPrint("LOGIN STATUS: ${res.statusCode}");
        debugPrint("LOGIN BODY: ${res.body}");
        debugPrint("LOGIN HEADERS: ${res.headers}");
      }

      dynamic body;
      try {
        body = jsonDecode(res.body);
      } catch (_) {
        body = null;
      }

      if (res.statusCode != 200) {
        final msg = _extractErrorMessage(body) ?? "Login failed (HTTP ${res.statusCode})";
        Get.snackbar(
          "Login Failed",
          msg,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
        return;
      }

      if (body is! Map) {
        Get.snackbar(
          "Login Failed",
          "Unexpected response: ${res.body}",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final access = body["tokens"]?["access"]?.toString() ?? "";
      final refresh = body["tokens"]?["refresh"]?.toString() ?? "";

      if (access.isEmpty || refresh.isEmpty) {
        Get.snackbar(
          "Login Failed",
          "Access/Refresh token missing from server.",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // ✅ Save tokens only (single source of truth)
      await box.write("access_token", access);
      await box.write("refresh_token", refresh);

      Get.snackbar(
        "Success",
        "Login Successfully",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      if(isregistered.value == true){
        Get.offAllNamed(AdminRoutes.HOME);
      }else{
        Get.offAllNamed(AdminRoutes.faceRegister);
      }

      
    } catch (e) {
      Get.snackbar(
        "Error",
        "Network/Server issue: $e",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 6),
      );
    } finally {
      isLoading.value = false;
    }
  }

  String? _extractErrorMessage(dynamic body) {
    if (body == null) return null;

    if (body is Map) {
      if (body["detail"] != null) return body["detail"].toString();
      if (body["message"] != null) return body["message"].toString();
      if (body["error"] != null) return body["error"].toString();

      final buf = <String>[];
      body.forEach((k, v) {
        if (v is List && v.isNotEmpty) buf.add("$k: ${v.first}");
        if (v is String) buf.add("$k: $v");
      });
      if (buf.isNotEmpty) return buf.join("\n");
    }
    return body.toString();
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}*/
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:monteage_employee/models/login_response_model.dart';

class LoginController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool isPasswordHidden = true.obs;

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  final GetStorage box = GetStorage();

  final TextEditingController userIdController = TextEditingController(text: "");
  final TextEditingController passwordController = TextEditingController(text: "");

  Future<void> login() async {
    final userId = userIdController.text.trim();
    final password = passwordController.text.trim();

    if (userId.isEmpty || password.isEmpty) {
      Get.snackbar("Error", "Enter Employee Code & Password");
      return;
    }

    if (isLoading.value) return;
    isLoading.value = true;

    try {
      final response = await http
          .post(
            Uri.parse(
                "https://montempep.eduagentapp.com/api/MonteageEmpErp/AppEmpLogins/"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "EmployeeCode": userId,
              "Password": password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint("STATUS: ${response.statusCode}");
      debugPrint("BODY: ${response.body}");

      Map<String, dynamic> jsonData;
      try {
        jsonData = jsonDecode(response.body);
      } catch (_) {
        throw Exception("Invalid server response");
      }

      final result = LoginResponseModel.fromJson(jsonData);
      debugPrint("PARSED DATA: ${result.data}");

      if (response.statusCode == 200 && result.statuscode == 200) {
        final emp = result.data;

        if (emp == null) {
          debugPrint("FULL RESPONSE: $jsonData");
          Get.snackbar("Error", "User data missing from API");
          return;
        }

        // Save data
        box.write("EmployeeName", emp.employeeName);
        box.write("employeeName", emp.employeeName);
        box.write("employee_data", jsonEncode(emp.toJson()));
        box.write("EmployeeId", emp.employeeId);
        box.write("employeeId", emp.employeeId);
        box.write("employee_id", emp.employeeId);
        box.write("employee_code", emp.employeeCode);
        box.write("employee_email", emp.email);
        box.write("Designation", emp.designation);
        box.write("designation", emp.designation);
        box.write("contact_no", emp.contactNo);
        box.write("photo", emp.photo);
        box.write("is_logged_in", true);
        

        Get.offAllNamed("/main");
      } else {
        throw Exception(result.message);
      }
    } catch (e, stack) {
      debugPrint("ERROR: $e");
      debugPrint("STACK TRACE: $stack");

      Get.snackbar(
        "Login Failed",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false; // ✅ Always resets no matter what
    }
  }
  void logout() {
  box.erase(); 
  Get.offAllNamed("/login");
}
}