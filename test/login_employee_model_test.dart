import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:monteage_employee/models/login_employee_model.dart';

void main() {
  test('parses numeric fields sent as strings', () {
    final model = LoginEmployeeModel.fromJson({
      'message': 'ok',
      'statuscode': '200',
      'data': {
        'EmployeeId': '12',
        'EmployeeName': 'Test',
        'ContactNo': 9876543210,
        'DesignationId': '3',
        'CId': '7',
        'IsActive': 'true',
      },
    });

    expect(model.statuscode, 200);
    expect(model.data!.employeeId, 12);
    expect(model.data!.contactNo, '9876543210');
    expect(model.data!.designationId, 3);
    expect(model.data!.cId, 7);
    expect(model.data!.isActive, true);
  });

  test('still parses correctly typed fields', () {
    final model = LoginEmployeeModel.fromJson({
      'statuscode': 200,
      'data': {'EmployeeId': 12, 'IsActive': false, 'Email': 'a@b.com'},
    });

    expect(model.data!.employeeId, 12);
    expect(model.data!.isActive, false);
    expect(model.data!.email, 'a@b.com');
  });

  test('survives the stored employee_data round trip', () {
    final original = LoginEmployeeModel.fromJson({
      'data': {'EmployeeId': '12', 'EmployeeName': 'Test'},
    });
    final restored = LoginEmployeeModel.fromJson(
      jsonDecode(jsonEncode(original.toJson())),
    );

    expect(restored.data!.employeeId, 12);
    expect(restored.data!.employeeName, 'Test');
  });

  test('bad values become null instead of throwing', () {
    final model = LoginEmployeeModel.fromJson({
      'data': {'EmployeeId': 'abc', 'IsActive': 'maybe'},
    });

    expect(model.data!.employeeId, isNull);
    expect(model.data!.isActive, isNull);
  });
}
