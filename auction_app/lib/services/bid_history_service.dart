import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/constants/api_config.dart';
import '../models/bid.dart';
import 'auth_service.dart';

class BidHistoryService {
  final AuthService _authService = AuthService();

  Future<List<Bid>> getBidHistory(int assetId) async {
    final token = await _authService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Please log in again.');
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/assets/$assetId/bids',
    );

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final List<dynamic> bids = data is List
          ? data
          : data['bids'] ?? [];

      return bids
          .map((item) => Bid.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList();
    }

    if (response.statusCode == 401) {
      throw Exception('Session expired. Please log in again.');
    }

    throw Exception(
      'Unable to load bid history: ${response.statusCode}',
    );
  }
}
