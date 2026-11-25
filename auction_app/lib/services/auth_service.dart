
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/api_config.dart';

class AuthService {
  // LOGIN
  Future<String> login({
    required String username,
    required String password,
  }) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.login}',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final token = data['token'] as String;

      await _saveToken(token);

      return token;
    }

    throw Exception(
      data['detail'] ?? 'Login failed',
    );
  }

  // REGISTER
  Future<String> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.register}',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'full_name': fullName,
        'phone': phone,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      final token = data['token'] as String;

      await _saveToken(token);

      return token;
    }

    throw Exception(
      data['detail'] ?? 'Registration failed',
    );
  }

  // SAVE JWT TOKEN
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('auth_token', token);
  }

  // RETRIEVE CURRENT USER ID
  Future<int?> getCurrentUserId() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      return null;
    }

    final parts = token.split('.');

    if (parts.length != 3) {
      return null;
    }

    try {
      final normalized = base64Url.normalize(parts[1]);
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(normalized)),
      );

      return int.tryParse(
        payload['sub']?.toString() ?? '',
      );
    } catch (_) {
      return null;
    }
  }
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('auth_token');
  }

  // LOGOUT
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('auth_token');
  }
}
