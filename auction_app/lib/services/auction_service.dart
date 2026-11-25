
import 'dart:convert';
import '../models/auction_details.dart';
import 'package:http/http.dart' as http;

import '../core/constants/api_config.dart';
import '../models/auction.dart';
import 'auth_service.dart';

class AuctionService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Please log in to view auctions.');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // FETCH ALL AUCTIONS
  Future<List<Auction>> getAuctions({
    String? status,
    String? search,
    String? category,
  }) async {
    final headers = await _headers();

    final queryParameters = <String, String>{};

    if (status != null && status != 'all') {
      queryParameters['status'] = status;
    }

    if (search != null && search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }

    if (category != null && category.isNotEmpty) {
      queryParameters['category'] = category;
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.assets}',
    ).replace(
      queryParameters: queryParameters.isEmpty
          ? null
          : queryParameters,
    );

    final response = await http.get(
      uri,
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data.map((item) {
        return Auction.fromJson(
          item as Map<String, dynamic>,
        );
      }).toList();
    }

    if (response.statusCode == 401) {
      throw Exception('Your session has expired. Please log in again.');
    }

    throw Exception('Unable to retrieve auction listings.');
  }

  // FETCH INDIVIDUAL AUCTION
  Future<AuctionDetails> getAuctionDetails(int assetId) async {
  final token = await _authService.getToken();

  if (token == null || token.isEmpty) {
    throw Exception('Please log in again.');
  }

  final uri = Uri.parse(
    '${ApiConfig.baseUrl}${ApiConfig.assets}$assetId',
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

    return AuctionDetails.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  if (response.statusCode == 401) {
    throw Exception('Your session has expired. Please log in again.');
  }

  if (response.statusCode == 404) {
    throw Exception('Auction not found.');
  }

  throw Exception(
    'Could not load auction details: ${response.statusCode}',
  );
}
}