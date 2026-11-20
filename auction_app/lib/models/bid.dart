import '../utils.dart';

class Bid {
  final int id;
  final int assetId;
  final int userId;
  final double amount;
  final DateTime placedAt;

  Bid({
    required this.id,
    required this.assetId,
    required this.userId,
    required this.amount,
    required this.placedAt,
  });

  factory Bid.fromJson(Map<String, dynamic> j) => Bid(
        id: j['bid_id'],
        assetId: j['asset_id'],
        userId: j['user_id'],
        amount: (j['bid_amount'] as num).toDouble(),
        placedAt: parseUtc(j['placed_at']),
      );
}