import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/asset.dart';
import '../models/bid.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  ApiService(this.token);
  final String? token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    http.Response r;
    try {
      r = await request().timeout(const Duration(seconds: 10));
    } catch (_) {
      throw ApiException('Cannot reach the server. Is the backend running?');
    }
    final body = r.body.isEmpty ? null : jsonDecode(r.body);
    if (r.statusCode >= 200 && r.statusCode < 300) return body;

    var msg = 'Something went wrong (${r.statusCode})';
    if (body is Map && body['detail'] != null) {
      final d = body['detail'];
      if (d is String) {
        msg = d;
      } else if (d is List && d.isNotEmpty && d.first is Map) {
        msg = d.first['msg'].toString(); // FastAPI validation errors
      }
    }
    throw ApiException(msg);
  }

  // ---------- Auth ----------
  Future<String> login(String username, String password) async {
    final data = await _send(() => http.post(_uri('/api/auth/login'),
        headers: _headers,
        body: jsonEncode({'username': username, 'password': password})));
    return data['token'];
  }

  Future<String> register({
    required String username,
    required String email,
    required String password,
    String? fullName,
    String? phone,
  }) async {
    final data = await _send(() => http.post(_uri('/api/auth/register'),
        headers: _headers,
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'full_name': fullName,
          'phone': phone,
        })));
    return data['token'];
  }

  // ---------- Assets ----------
  Future<List<Asset>> fetchAssets({String? status, String? search}) async {
    final query = <String, String>{
      'status': ?status,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    // Trailing slash matters: FastAPI routes are defined as "/api/assets/"
    final data = await _send(
        () => http.get(_uri('/api/assets/', query), headers: _headers));
    return (data as List).map((j) => Asset.fromJson(j)).toList();
  }

  Future<Asset> fetchAsset(int id) async {
    final data =
        await _send(() => http.get(_uri('/api/assets/$id'), headers: _headers));
    final images = (data['images'] as List)
        .map<String>((i) => i['file_path'] as String)
        .toList();
    return Asset.fromJson(data['asset'], images: images);
  }

  // ---------- Bids ----------
  Future<List<Bid>> fetchBids(int assetId) async {
    final data = await _send(
        () => http.get(_uri('/api/assets/$assetId/bids'), headers: _headers));
    return (data as List).map((j) => Bid.fromJson(j)).toList();
  }

  Future<void> placeBid(int assetId, double amount) async {
    // In your backend the bids router is mounted at "/api" with route "/",
    // so placing a bid is POST /api/
    await _send(() => http.post(_uri('/api/'),
        headers: _headers,
        body: jsonEncode({'asset_id': assetId, 'bid_amount': amount})));
  }

  Future<List<Bid>> myBids() async {
    final data = await _send(
        () => http.get(_uri('/api/users/me/bids'), headers: _headers));
    return (data as List).map((j) => Bid.fromJson(j)).toList();
  }
}