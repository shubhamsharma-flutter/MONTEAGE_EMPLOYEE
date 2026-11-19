import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:monteage_employee/models/login_employee_model.dart';
import 'package:monteage_employee/services/sales_api.dart';

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
      final Map<String, dynamic> json = jsonDecode(raw);
      // Older app versions stored the flat employee object; wrap it.
      employee.value = LoginEmployeeModel.fromJson(
        json.containsKey("data") ? json : {"data": json},
      );
    }
  }

  String get employeeName => employee.value?.data?.employeeName ?? "--";
  String get employeeCode => employee.value?.data?.employeeCode ?? "--";
  String get employeeEmail => employee.value?.data?.email ?? "--";
  String get designation => employee.value?.data?.designation ?? "--";
  String get employeeId => employee.value?.data?.employeeId?.toString() ?? "--";
  String get contactNo => employee.value?.data?.contactNo ?? "--";
  String get photo => employee.value?.data?.photo ?? "";
  bool get isHrManager => designation.toLowerCase() == "hr manager";
  bool get isSales => designation.toLowerCase().contains("sales");
  bool get hasSalesAccount => SalesApi.storedCId().isNotEmpty;

  /// Sales staff get the Sales module instead of Tasks.
  bool get isSalesUser => isSales || hasSalesAccount;
}
