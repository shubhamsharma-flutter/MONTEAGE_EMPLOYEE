import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart' as auth;

/// Sends targeted FCM v1 push notifications directly from the app using a
/// service account restricted to the "Firebase Cloud Messaging API".
///
/// Each employee's device subscribes to a per-user topic (`emp_<EmployeeId>`)
/// on login, so sending to that topic reaches only that one person instead
/// of broadcasting to everyone.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  static const String _serviceAccountAsset ='assets/secrets/fcm_service_account.json';
  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/firebase.messaging',
  ];

  String? _projectId;
  auth.AutoRefreshingAuthClient? _client;

  static String topicForEmployee(String employeeId) => 'emp_$employeeId';

  Future<auth.AutoRefreshingAuthClient> _getClient() async {
    if (_client != null) return _client!;

    final raw = await rootBundle.loadString(_serviceAccountAsset);
    final credentialsJson = jsonDecode(raw) as Map<String, dynamic>;
    _projectId = credentialsJson['project_id'] as String;

    final credentials = auth.ServiceAccountCredentials.fromJson(credentialsJson);
    _client = await auth.clientViaServiceAccount(credentials, _scopes);
    return _client!;
  }

  /// Sends a push notification to a single employee via their per-user topic.
  Future<bool> sendToEmployee({
    required String employeeId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final client = await _getClient();
      final url = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send',
      );

      final message = {
        'message': {
          'topic': topicForEmployee(employeeId),
          'notification': {'title': title, 'body': body},
          if (data != null) 'data': data,
        },
      };

      final res = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(message),
      );

      debugPrint('FCM send [${res.statusCode}]: ${res.body}');
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('FCM send error: $e');
      return false;
    }
  }
}
