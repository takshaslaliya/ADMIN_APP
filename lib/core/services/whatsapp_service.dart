import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:splitease_test/core/config/app_config.dart';
import 'package:splitease_test/core/services/auth_service.dart';

class WhatsAppResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  WhatsAppResult({required this.success, required this.message, this.data});
}

class WhatsAppService {
  static Future<WhatsAppResult> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final url = Uri.parse('${AppConfig.whatsappUrl}$path');

      http.Response response;
      if (method == 'POST') {
        response = await http.post(
          url,
          headers: headers,
          body: jsonEncode(body),
        );
      } else if (method == 'GET') {
        response = await http.get(url, headers: headers);
      } else {
        throw Exception('Unsupported method');
      }

      final decoded = jsonDecode(response.body);
      return WhatsAppResult(
        success: decoded['success'] ?? false,
        message:
            decoded['message'] ??
            (decoded['success'] == true ? 'Success' : 'Failed'),
        data: decoded['data'],
      );
    } catch (e) {
      return WhatsAppResult(success: false, message: 'Network error: $e');
    }
  }

  /// 1. Connect WhatsApp (type: 'otp' or 'qr')
  static Future<WhatsAppResult> connect({
    required String phoneNumber,
    required String type,
  }) async {
    return _request(
      'POST',
      '/connect',
      body: {'phone_number': phoneNumber, 'type': type},
    );
  }

  /// 2. Check connection status
  static Future<WhatsAppResult> getStatus() async {
    return _request('GET', '/status');
  }

  /// 3. Disconnect WhatsApp
  static Future<WhatsAppResult> disconnect() async {
    return _request('POST', '/disconnect');
  }
}
