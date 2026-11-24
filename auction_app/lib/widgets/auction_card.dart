
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../models/auction.dart';

class AuctionCard extends StatelessWidget {
  final Auction auction;
  final VoidCallback onTap;

  const AuctionCard({
    super.key,
    required this.auction,
    required this.onTap,
  });

  String formatPrice(double price) {
    return NumberFormat.currency(
      locale: 'en_UG',
      symbol: 'UGX ',
      decimalDigits: 0,
    ).format(price);
  }

  @override
  Widget build(BuildContext context) {
    final isLive = auction.status == 'live';

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: Color(0xFFE8EBF0),
        ),
      ),

      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),

        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (auction.imageUrl != null && auction.imageUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      auction.imageUrl!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        height: 150,
                        color: const Color(0xFFE8EBF0),
                        child: const Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
                  ),
                ),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      auction.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.navy,
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isLive
                          ? const Color(0xFFE4F4E9)
                          : const Color(0xFFFFF2DC),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      auction.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isLive
                            ? Colors.green.shade800
                            : Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                auction.description?.isNotEmpty == true
                    ? auction.description!
                    : 'No description provided.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textGrey,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'CURRENT BID',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textGrey,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                formatPrice(auction.currentPrice),
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.navy,
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 15,
                    color: AppTheme.gold,
                  ),

                  const SizedBox(width: 5),

                  Expanded(
                    child: Text(
                      'Ends ${DateFormat('dd MMM yyyy').format(auction.endTime.toLocal())}',
                      style: const TextStyle(
                        color: AppTheme.textGrey,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 15,
                    color: AppTheme.navy,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
