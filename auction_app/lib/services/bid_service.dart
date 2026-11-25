import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/constants/api_config.dart';
import '../services/auth_service.dart';

class BidService {
  final AuthService _authService = AuthService();
  Future<Map<String, dynamic>> placeBid({
    required int assetId,
    required double bidAmount,
  }) async {
    final token = await _authService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Please log in again.');
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/',
    );

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'asset_id': assetId,
        'bid_amount': bidAmount,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data['detail']?.toString() ?? 'Bid could not be placed.',
    );
  }
}