
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../models/auction.dart';

class AuctionDetailScreen extends StatelessWidget {
  final Auction auction;

  const AuctionDetailScreen({
    super.key,
    required this.auction,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auction Details'),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            if (auction.imageUrl != null && auction.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  auction.imageUrl!,
                  height: 210,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 210,
                    color: AppTheme.navy,
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: AppTheme.gold,
                      size: 85,
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 210,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.navy,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppTheme.gold,
                  size: 85,
                ),
              ),

            const SizedBox(height: 22),

            Text(
              auction.title,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: AppTheme.navy,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              auction.description?.isNotEmpty == true
                  ? auction.description!
                  : 'No description available.',
              style: const TextStyle(
                fontSize: 15,
                color: AppTheme.textGrey,
              ),
            ),

            const SizedBox(height: 25),

            _detailItem(
              'Current Price',
              formatPrice(auction.currentPrice),
            ),

            _detailItem(
              'Starting Price',
              formatPrice(auction.startingPrice),
            ),

            _detailItem(
              'Minimum Increment',
              formatPrice(auction.minIncrement),
            ),

            _detailItem(
              'Auction Status',
              auction.status.toUpperCase(),
            ),

            _detailItem(
              'Closing Date',
              DateFormat('dd MMM yyyy, HH:mm').format(
                auction.endTime.toLocal(),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 54,

              child: ElevatedButton(
                onPressed: auction.status == 'live'
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Bidding functionality is our next step.',
                            ),
                          ),
                        );
                      }
                    : null,

                child: const Text(
                  'Place a Bid',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE8EBF0),
          ),
        ),
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textGrey,
            ),
          ),

          const SizedBox(width: 12),

          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
