import '../utils.dart';

class Asset {
  final int id;
  final int categoryId;
  final String title;
  final String? description;
  final double startingPrice;
  final double currentPrice;
  final double minIncrement;
  final String status;
  final DateTime startTime;
  final DateTime endTime;
  final List<String> images;

  Asset({
    required this.id,
    required this.categoryId,
    required this.title,
    this.description,
    required this.startingPrice,
    required this.currentPrice,
    required this.minIncrement,
    required this.status,
    required this.startTime,
    required this.endTime,
    this.images = const [],
  });

  factory Asset.fromJson(Map<String, dynamic> j, {List<String> images = const []}) {
    return Asset(
      id: j['asset_id'],
      categoryId: j['category_id'],
      title: j['title'],
      description: j['description'],
      startingPrice: (j['starting_price'] as num).toDouble(),
      currentPrice: (j['current_price'] as num).toDouble(),
      minIncrement: (j['min_increment'] as num).toDouble(),
      status: j['status'],
      startTime: parseUtc(j['start_time']),
      endTime: parseUtc(j['end_time']),
      images: images,
    );
  }

  double get minimumBid => currentPrice + minIncrement;
}