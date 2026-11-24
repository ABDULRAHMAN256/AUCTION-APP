
class Auction {
  final int assetId;
  final int sellerId;
  final int categoryId;
  final String title;
  final String? description;
  final double startingPrice;
  final double reservePrice;
  final double minIncrement;
  final double currentPrice;
  final String status;
  final DateTime startTime;
  final DateTime endTime;

  final String? imageUrl;

  Auction({
    required this.assetId,
    required this.sellerId,
    required this.categoryId,
    required this.title,
    this.description,
    required this.startingPrice,
    required this.reservePrice,
    required this.minIncrement,
    required this.currentPrice,
    required this.status,
    required this.startTime,
    required this.endTime,
    this.imageUrl,
  });

  factory Auction.fromJson(Map<String, dynamic> json) {
    return Auction(
      assetId: json['asset_id'] as int,
      sellerId: json['seller_id'] as int,
      categoryId: json['category_id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      startingPrice: (json['starting_price'] as num).toDouble(),
      reservePrice: (json['reserve_price'] as num).toDouble(),
      minIncrement: (json['min_increment'] as num).toDouble(),
      currentPrice: (json['current_price'] as num).toDouble(),
      status: json['status'] as String,
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      imageUrl: json['image_url'] as String?,
    );
  }

  factory Auction.fromDetailJson(Map<String, dynamic> json) {
    final assetJson = Map<String, dynamic>.from(
      json['asset'] as Map<String, dynamic>,
    );

    final images = json['images'] as List<dynamic>?;
    if (images != null && images.isNotEmpty) {
      assetJson['image_url'] =
          (images.first as Map<String, dynamic>)['file_path'] as String?;
    }

    return Auction.fromJson(assetJson);
  }
}
