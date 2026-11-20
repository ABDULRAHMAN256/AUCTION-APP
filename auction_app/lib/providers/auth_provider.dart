import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  String? role;
  int? userId;
  String? username;
  bool loading = true;

  bool get isLoggedIn => _token != null;
  ApiService get api => ApiService(_token);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('token');
    if (saved != null && !JwtDecoder.isExpired(saved)) {
      _apply(saved);
      username = prefs.getString('username');
    }
    loading = false;
    notifyListeners();
  }

  void _apply(String token) {
    final payload = JwtDecoder.decode(token);
    _token = token;
    userId = int.parse(payload['sub'].toString());
    role = payload['role'];
  }

  Future<void> _save(String token, String name) async {
    _apply(token);
    username = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('username', name);
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    final token = await ApiService(null).login(username, password);
    await _save(token, username);
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    String? fullName,
    String? phone,
  }) async {
    final token = await ApiService(null).register(
      username: username,
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
    );
    await _save(token, username);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('username');
    _token = null;
    role = null;
    userId = null;
    username = null;
    notifyListeners();
  }
}