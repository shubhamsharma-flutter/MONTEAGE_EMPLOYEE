import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:monteage_employee/models/login_employee_model.dart';

class EmployeeDataController extends GetxController {
  final box = GetStorage();
  final Rxn<LoginEmployeeModel> employee = Rxn<LoginEmployeeModel>();

  @override
  void onInit() {
    super.onInit();
    loadEmployee();
  }

  void loadEmployee() {
    final raw = box.read("employee_data");
    if (raw != null) {
      employee.value = LoginEmployeeModel.fromJson(jsonDecode(raw));
    }
  }

  String get employeeName => employee.value?.employeeName ?? "--";
  String get employeeCode => employee.value?.employeeCode ?? "--";
  String get employeeEmail => employee.value?.email ?? "--";
  String get designation => employee.value?.designation ?? "--";
  String get employeeId => employee.value?.employeeId.toString() ?? "--";
  String get contactNo => employee.value?.contactNo ?? "--";
  String get photo => employee.value?.photo ?? "";
  bool get isHrManager => designation.toLowerCase() == "hr manager";
}