class Bid {
  final int bidId;
  final int assetId;
  final int userId;
  final double bidAmount;
  final DateTime placedAt;

  Bid({
    required this.bidId,
    required this.assetId,
    required this.userId,
    required this.bidAmount,
    required this.placedAt,
  });

  factory Bid.fromJson(Map<String, dynamic> json) {
    return Bid(
      bidId: json['bid_id'] ?? 0,
      assetId: json['asset_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      bidAmount: (json['bid_amount'] as num).toDouble(),
      placedAt: DateTime.parse(json['placed_at']),
    );
  }
}