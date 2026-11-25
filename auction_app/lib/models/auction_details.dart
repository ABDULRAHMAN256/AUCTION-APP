import 'auction.dart';

class AuctionImage {
  final int imageId;
  final int assetId;
  final String filePath;
  final bool isPrimary;

  AuctionImage({
    required this.imageId,
    required this.assetId,
    required this.filePath,
    required this.isPrimary,
  });

  factory AuctionImage.fromJson(Map<String, dynamic> json) {
    return AuctionImage(
      imageId: json['image_id'] ?? 0,
      assetId: json['asset_id'] ?? 0,
      filePath: json['file_path'] ?? '',
      isPrimary: json['is_primary'] ?? false,
    );
  }
}

class AuctionDetails {
  final Auction auction;
  final List<AuctionImage> images;

  AuctionDetails({
    required this.auction,
    required this.images,
  });

  factory AuctionDetails.fromJson(Map<String, dynamic> json) {
    final imageList = json['images'] as List? ?? [];

    return AuctionDetails(
      auction: Auction.fromJson(
        Map<String, dynamic>.from(json['asset']),
      ),
      images: imageList
          .map(
            (image) => AuctionImage.fromJson(
              Map<String, dynamic>.from(image),
            ),
          )
          .toList(),
    );
  }
}