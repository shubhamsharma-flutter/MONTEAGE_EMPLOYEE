import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:monteage_employee/models/sales_lead_model.dart';

/// Error with a message that can be shown to the user as-is.
class SalesApiException implements Exception {
  final String message;
  const SalesApiException(this.message);

  @override
  String toString() => message;
}

/// The lead lists the Sales module can show, each backed by its own endpoint.
enum SalesListType {
  todayVisits('Today\'s Visits', 'ViewSalesLeadToday'),
  allVisits('All Visits', 'ViewSalesLead'),
  todayFollowups('Today\'s Follow-ups', 'TodayGetFollowSalesleads'),
  completedToday('Completed Today', 'TodayFollowSelesLeads'),
  nextDay('Next Day Follow-ups', 'NextdayFollowSelesLeads'),
  nextWeek('Next Week Follow-ups', 'NextweekFollowSelesLeads');

  const SalesListType(this.title, this.endpoint);

  final String title;
  final String endpoint;
}

/// Client for the sales CRM backend. It is a separate system from the
/// employee ERP: it identifies the salesperson by the `CId` returned from
/// SalesLogins, which is stored under [cIdKey] when the employee logs in.
class SalesApi {
  static const String _baseUrl =
      'https://montcrm.eduagentapp.com/api/EducationCRM';
  static const Duration _timeout = Duration(seconds: 20);

  static const String cIdKey = 'sales_cid';
  static const String nameKey = 'sales_name';

  static String storedCId() =>
      (GetStorage().read(cIdKey) ?? '').toString().trim();

  /// Signs in to the sales CRM with the employee's mobile number and the
  /// password they just used for the employee app, and stores the sales
  /// CId. Returns false (and stores nothing) if no matching sales account
  /// exists, so callers can ignore failures.
  static Future<bool> linkAccount({
    required String mobile,
    required String password,
  }) async {
    // ContactNo may carry a +91 prefix or spaces; sales logins use 10 digits.
    var digits = mobile.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) digits = digits.substring(digits.length - 10);
    if (digits.isEmpty || password.isEmpty) return false;
    try {
      final body = await _post('SalesLogins', {
        'Mobile': digits,
        'Password': password,
      });
      final data = body['data'];
      final cId = data is Map ? (data['CId'] ?? '').toString().trim() : '';
      if (cId.isEmpty || cId == '0') return false;

      final box = GetStorage();
      await box.write(cIdKey, cId);
      await box.write(
        nameKey,
        '${data['FirstName'] ?? ''} ${data['LastName'] ?? ''}'.trim(),
      );
      return true;
    } catch (e) {
      debugPrint('Sales account link failed: $e');
      return false;
    }
  }

  static Future<List<SalesLead>> fetchLeads(
    SalesListType type,
    String cId,
  ) async {
    final body = await _get('${type.endpoint}/$cId');
    return _list(body).map(SalesLead.fromJson).toList();
  }

  static Future<List<SalesFollowupEntry>> fetchFollowupHistory(
    String leadId,
  ) async {
    final body = await _get('GetCommunicateSales/$leadId');
    return _list(body).map(SalesFollowupEntry.fromJson).toList();
  }

  static Future<List<SalesVisitType>> fetchVisitTypes(String cId) async {
    final body = await _get('SalesCourse/$cId');
    return _list(body)
        .map(SalesVisitType.fromJson)
        .where((t) => t.id.isNotEmpty && t.name.isNotEmpty)
        .toList();
  }

  static Future<void> addVisit(Map<String, dynamic> payload) async {
    final body = await _post('AddSalesLead', payload);
    if (body['data'] == null) {
      throw SalesApiException(_message(body, 'Could not add the visit.'));
    }
  }

  static Future<void> updateFollowup(Map<String, dynamic> payload) async {
    final body = await _post('UpdateSalesLead', payload);
    if (body['data'] == null) {
      throw SalesApiException(_message(body, 'Could not update follow-up.'));
    }
  }

  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> _get(String path) {
    return _send(() => http.get(
          Uri.parse('$_baseUrl/$path'),
          headers: const {'Accept': 'application/json'},
        ));
  }

  static Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> payload,
  ) {
    return _send(() => http.post(
          Uri.parse('$_baseUrl/$path'),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(payload),
        ));
  }

  static Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request,
  ) async {
    final http.Response response;
    try {
      response = await request().timeout(_timeout);
    } on SocketException {
      throw const SalesApiException(
        'No internet connection. Check your network and try again.',
      );
    } on TimeoutException {
      throw const SalesApiException(
        'The server took too long to respond. Please try again.',
      );
    }

    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {}

    if (response.statusCode == 200 && body != null) return body;

    // "No records" comes back as 404 with an empty data field.
    if (response.statusCode == 404 && body != null && body['data'] == null) {
      return body;
    }

    debugPrint('Sales API ${response.statusCode}: ${response.body}');
    throw SalesApiException(
      _message(body, 'Server error (${response.statusCode}). Please try again.'),
    );
  }

  static List<Map<String, dynamic>> _list(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is! List) return const [];
    return data.whereType<Map<String, dynamic>>().toList();
  }

  static String _message(Map<String, dynamic>? body, String fallback) {
    final msg = (body?['message'] ?? '').toString().trim();
    return msg.isEmpty ? fallback : msg;
  }
}
