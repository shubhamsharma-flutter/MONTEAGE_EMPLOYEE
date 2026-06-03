import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../models/register_response_model.dart';
import '../screens/FaceRegisterScreen.dart';

class RegisterRepository {
  final http.Client client;

  RegisterRepository({required this.client});

  Future<RegisterResponseModel> registerUser({
    required String username,
    required String email,
    required String employeeId,
    required String password,
    required String confirmPassword,
    required String firstName,
    required String lastName,
    required String department,
  }) async {
    try {
      final uri = Uri.http(
        'att.monteage.co.in',
        '/attendance/api/auth/register/',
      );

      final response = await client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username,
              'email': email,
              'employee_id': employeeId,
              'password': password,
              'confirm_password': confirmPassword,
              'first_name': firstName,
              'last_name': lastName,
              'department': department,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return RegisterResponseModel.fromJson(data);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(_extractErrorMessage(errorBody) ??
            "Registration failed with status code: ${response.statusCode}");
      }
    } on TimeoutException {
      throw Exception("The request timed out. Please try again.");
    } on http.ClientException {
      throw Exception(
          "Failed to connect to the server. Please check your internet connection.");
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  String? _extractErrorMessage(dynamic body) {
    if (body == null) return null;

    if (body is Map) {
      final details = _collectFieldErrors(body);
      final detail = body["detail"]?.toString();
      final message = body["message"]?.toString();
      final error = body["error"]?.toString();

      if (details.isNotEmpty) {
        final generic = detail ?? message ?? error;
        if (generic != null && generic.isNotEmpty && generic != "Validation failed") {
          return "$generic\n${details.join("\n")}";
        }
        return details.join("\n");
      }

      if (detail != null && detail.isNotEmpty) return detail;
      if (message != null && message.isNotEmpty) return message;
      if (error != null && error.isNotEmpty) return error;
    }

    return body.toString();
  }

  List<String> _collectFieldErrors(Map body, [String prefix = '']) {
    final messages = <String>[];

    body.forEach((key, value) {
      final field = prefix.isEmpty ? key.toString() : '$prefix.${key.toString()}';

      if (value is String && value.isNotEmpty) {
        if (key != 'detail' && key != 'message' && key != 'error') {
          messages.add('$field: $value');
        }
      } else if (value is List) {
        for (final item in value) {
          if (item is String && item.isNotEmpty) {
            messages.add('$field: $item');
          } else if (item is Map) {
            messages.addAll(_collectFieldErrors(item, field));
          }
        }
      } else if (value is Map) {
        messages.addAll(_collectFieldErrors(value, field));
      }
    });

    return messages;
  }
}

class RegisterController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final departmentController = TextEditingController();
  final emailController = TextEditingController();
  final employeeIdController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final isLoading = false.obs;
  final repository = RegisterRepository(client: http.Client());

  Future<void> register() async {
    if (isLoading.value) return;
    if (formKey.currentState?.validate() != true) return;

    isLoading.value = true;
    try {
      final result = await repository.registerUser(
        username: emailController.text.trim(),
        email: emailController.text.trim(),
        employeeId: employeeIdController.text.trim(),
        password: passwordController.text.trim(),
        confirmPassword: confirmPasswordController.text.trim(),
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        department: departmentController.text.trim(),
      );

      Get.snackbar(
        'Success',
        result.message.isNotEmpty ? result.message : 'Employee registered successfully.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      Get.to(
  () => const FaceRegisterScreen(),
  arguments: {"employee_code": employeeIdController.text.trim()},
);
    } catch (error) {
      Get.snackbar(
        'Registration Failed',
        error.toString(),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    departmentController.dispose();
    emailController.dispose();
    employeeIdController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
 