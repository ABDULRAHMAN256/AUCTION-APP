class Bid {
  final int bidId;
  final int assetId;
  final int userId;
  final double bidAmount;
  final DateTime placedAt;
  final String? assetTitle;

  Bid({
    required this.bidId,
    required this.assetId,
    required this.userId,
    required this.bidAmount,
    required this.placedAt,
    this.assetTitle,
  });

  factory Bid.fromJson(Map<String, dynamic> json) {
    return Bid(
      bidId: json['bid_id'] ?? 0,
      assetId: json['asset_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      bidAmount: (json['bid_amount'] as num).toDouble(),
      placedAt: DateTime.parse(json['placed_at']),
      assetTitle: json['asset_title'] as String?,
    );
  }
}