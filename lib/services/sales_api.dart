import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:monteage_employee/infrastructure/routes/admin_routes.dart';
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

/// Client for the sales CRM backend. It identifies the salesperson by the
/// `CId` from the employee login response, stored under [cIdKey].
class SalesApi {
  static const String _baseUrl =
      'https://montcrm.eduagentapp.com/api/EducationCRM';
  static const Duration _timeout = Duration(seconds: 20);

  static const String cIdKey = 'empidcrm';

  /// The employee's CRM id, or '' if they have none (null or 0).
  static String storedCId() {
    final box = GetStorage();
    var cId = box.read(cIdKey);

    // Sessions from before cIdKey was stored still have it in employee_data.
    if (cId == null) {
      try {
        final raw = box.read('employee_data');
        final Map<String, dynamic> json = raw is String ? jsonDecode(raw) : {};
        final data = json['data'];
        cId = data is Map ? data['CId'] : json['CId'];
      } catch (_) {}
    }

    final value = (cId ?? '').toString().trim();
    return value == '0' ? '' : value;
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
    final url = '$_baseUrl/$path';
    return _send('GET', url, null, () => http.get(
          Uri.parse(url),
          headers: const {'Accept': 'application/json'},
        ));
  }

  static Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> payload,
  ) {
    final url = '$_baseUrl/$path';
    return _send('POST', url, payload, () => http.post(
          Uri.parse(url),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(payload),
        ));
  }

  static Future<Map<String, dynamic>> _send(
    String method,
    String url,
    Map<String, dynamic>? payload,
    Future<http.Response> Function() request,
  ) async {
    final stopwatch = Stopwatch()..start();

    final http.Response response;
    try {
      response = await request().timeout(_timeout);
    } on SocketException catch (e) {
      _logCall(method, url, payload, '❌ no connection: $e');
      throw const SalesApiException(
        'No internet connection. Check your network and try again.',
      );
    } on TimeoutException {
      _logCall(method, url, payload,
          '❌ timed out after ${_timeout.inSeconds}s');
      throw const SalesApiException(
        'The server took too long to respond. Please try again.',
      );
    }

    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {}

    final count = body?['data'] is List ? ' (${body!['data'].length} items)' : '';
    _logCall(
      method,
      url,
      payload,
      '⬅️ ${response.statusCode} [${stopwatch.elapsedMilliseconds} ms]$count',
      body ?? response.body,
    );

    if (response.statusCode == 200 && body != null) return body;

    // "No records" comes back as 404 with an empty data field.
    if (response.statusCode == 404 && body != null && body['data'] == null) {
      return body;
    }

    throw SalesApiException(
      _message(body, 'Server error (${response.statusCode}). Please try again.'),
    );
  }

  /// Prints a request and its result to the debug console (debug builds
  /// only), but only when the API belongs to the screen currently open.
  static void _logCall(
    String method,
    String url,
    Map<String, dynamic>? payload,
    String result, [
    Object? response,
  ]) {
    if (!kDebugMode) return;
    final endpoint = url.substring(_baseUrl.length + 1).split('/').first;
    if (!_isCurrentScreenApi(endpoint)) return;

    _log('━━━━ ${Get.currentRoute} ━━━━');
    _log('➡️ $method $url', payload);
    _log(result, response);
  }

  /// The endpoints each Sales screen calls for itself.
  static bool _isCurrentScreenApi(String endpoint) {
    switch (Get.currentRoute) {
      case AdminRoutes.salesHome:
        return SalesListType.values.any((t) => t.endpoint == endpoint);
      case AdminRoutes.salesLeads:
        final type = Get.arguments;
        return type is SalesListType && type.endpoint == endpoint;
      case AdminRoutes.salesLeadDetail:
        return endpoint == 'GetCommunicateSales' ||
            endpoint == 'UpdateSalesLead';
      case AdminRoutes.salesAddVisit:
        return endpoint == 'SalesCourse' || endpoint == 'AddSalesLead';
      default:
        return false;
    }
  }

  /// Long JSON is printed line by line so logcat does not cut it off.
  static void _log(String title, [Object? data]) {
    debugPrint('[SalesApi] $title');
    if (data == null) return;

    final text = data is String
        ? data
        : const JsonEncoder.withIndent('  ').convert(data);
    for (final line in const LineSplitter().convert(text)) {
      debugPrint(line, wrapWidth: 800);
    }
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
