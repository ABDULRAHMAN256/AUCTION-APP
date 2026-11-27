
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

  // CREATE LISTING
  Future<void> createAsset({
    required String title,
    required String description,
    required String category,
    required double startingPrice,
    required double reservePrice,
    required double minIncrement,
    required DateTime startTime,
    required DateTime endTime,
    required List<String> images,
  }) async {
    final headers = await _headersForCreate();

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/assets/',
    );

    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode({
        'category_id': _categoryId(category),
        'title': title,
        'description': description,
        'starting_price': startingPrice,
        'reserve_price': reservePrice,
        'min_increment': minIncrement,
        'start_time': startTime.toUtc().toIso8601String(),
        'end_time': endTime.toUtc().toIso8601String(),
        'images': images,
      }),
    );

    if (response.statusCode == 201) {
      return;
    }

    String message = 'Unable to create listing.';

    try {
      final data = jsonDecode(response.body);
      message = data['detail']?.toString() ?? message;
    } catch (_) {}

    throw Exception(message);
  }

  Future<Map<String, String>> _headersForCreate() async {
    final token = await _authService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Please log in to create a listing.');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  int _categoryId(String category) {
    switch (category) {
      case 'Vehicles':
        return 1;
      case 'Land & Property':
        return 2;
      case 'Heavy Machinery':
        return 3;
      default:
        return 3;
    }
  }
  Future<List<Auction>> getMyListings() async {
    final headers = await _headersForCreate();

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/assets/mine',
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
      throw Exception('Please log in to view your listings.');
    }

    throw Exception('Unable to retrieve your listings.');
  }

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