import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:splitease_test/core/config/app_config.dart';
import 'package:splitease_test/core/services/auth_service.dart';

class AdminResult {
  final bool success;
  final String message;
  final dynamic data;
  final int? statusCode;

  AdminResult({
    required this.success,
    required this.message,
    this.data,
    this.statusCode,
  });
}

class AdminService {
  static String get _baseUrl => AppConfig.adminUrl;

  static Future<AdminResult> _get(String path) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http
          .get(Uri.parse('$_baseUrl$path'), headers: headers)
          .timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body);
      return AdminResult(
        success: decoded['success'] == true,
        message:
            decoded['message'] ??
            (decoded['success'] == true ? 'Success' : 'Failed'),
        data: decoded['data'],
        statusCode: response.statusCode,
      );
    } catch (e) {
      return AdminResult(
        success: false,
        message: 'Network error. Please try again.',
      );
    }
  }

  static Future<AdminResult> _put(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http
          .put(
            Uri.parse('$_baseUrl$path'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body);
      return AdminResult(
        success: decoded['success'] == true,
        message:
            decoded['message'] ??
            (decoded['success'] == true ? 'Success' : 'Failed'),
        data: decoded['data'],
        statusCode: response.statusCode,
      );
    } catch (e) {
      return AdminResult(
        success: false,
        message: 'Network error. Please try again.',
      );
    }
  }

  static Future<AdminResult> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body);
      return AdminResult(
        success: decoded['success'] == true,
        message:
            decoded['message'] ??
            (decoded['success'] == true ? 'Success' : 'Failed'),
        data: decoded['data'],
        statusCode: response.statusCode,
      );
    } catch (e) {
      return AdminResult(
        success: false,
        message: 'Network error. Please try again.',
      );
    }
  }

  static Future<AdminResult> _delete(String path) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http
          .delete(Uri.parse('$_baseUrl$path'), headers: headers)
          .timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body);
      return AdminResult(
        success: decoded['success'] == true,
        message:
            decoded['message'] ??
            (decoded['success'] == true ? 'Success' : 'Failed'),
        data: decoded['data'],
        statusCode: response.statusCode,
      );
    } catch (e) {
      return AdminResult(
        success: false,
        message: 'Network error. Please try again.',
      );
    }
  }

  static Future<AdminResult> fetchUsers({int page = 1, int limit = 20}) async {
    return _get('/users?page=$page&limit=$limit');
  }

  static Future<AdminResult> fetchUserById(String id) async {
    return _get('/users/$id');
  }

  static Future<AdminResult> updateUser(
    String id,
    Map<String, dynamic> body,
  ) async {
    return _put('/users/$id', body);
  }

  static Future<AdminResult> updateUserRole(String id, String role) async {
    return _put('/users/$id/role', {'role': role});
  }

  static Future<AdminResult> resetUserPassword(
    String id,
    String newPassword,
  ) async {
    return _put('/users/$id/reset-password', {'new_password': newPassword});
  }

  static Future<AdminResult> deleteUser(String id) async {
    return _delete('/users/$id');
  }

  // Notification Methods
  static Future<AdminResult> fetchAllNotifications() async {
    return _get('/notifications');
  }

  static Future<AdminResult> fetchUserNotifications(String userId) async {
    return _get('/notifications/user/$userId');
  }

  static Future<AdminResult> sendBulkNotifications({
    required List<String> userIds,
    required String title,
    required String message,
    DateTime? scheduledAt,
  }) async {
    return _post('/notifications/bulk', {
      'userIds': userIds,
      'title': title,
      'message': message,
      if (scheduledAt != null) 'scheduled_at': scheduledAt.toIso8601String(),
    });
  }

  // WhatsApp Session Methods
  static Future<AdminResult> fetchWhatsappSessions() async {
    return _get('/whatsapp/sessions');
  }
}
