import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/auction.dart';
import '../../models/auction_details.dart';
import '../../models/bid.dart';
import '../../services/auction_service.dart';
import '../../services/bid_service.dart';
import '../../services/bid_history_service.dart';

class AuctionDetailScreen extends StatefulWidget {
  final Auction auction;

  const AuctionDetailScreen({
    super.key,
    required this.auction,
  });

  @override
  State<AuctionDetailScreen> createState() =>
      _AuctionDetailScreenState();
}

class _AuctionDetailScreenState
    extends State<AuctionDetailScreen> {
  late Future<AuctionDetails> _detailsFuture;
  late Future<List<Bid>> _bidHistoryFuture;

  final AuctionService _auctionService = AuctionService();
  final BidService _bidService = BidService();
  final BidHistoryService _bidHistoryService =
      BidHistoryService();

  final TextEditingController _bidController =
      TextEditingController();

  bool _isPlacingBid = false;

  @override
  void initState() {
    super.initState();

    _loadDetails();
    _loadBidHistory();
  }

  // Load auction details
  void _loadDetails() {
    _detailsFuture = _auctionService.getAuctionDetails(
      widget.auction.assetId,
    );
  }

  // Load bid history
  void _loadBidHistory() {
    _bidHistoryFuture = _bidHistoryService.getBidHistory(
      widget.auction.assetId,
    );
  }

  // Format prices in Ugandan shillings
  String formatPrice(double amount) {
    return NumberFormat.currency(
      locale: 'en_UG',
      symbol: 'UGX ',
      decimalDigits: 0,
    ).format(amount);
  }

  // Place a bid
  Future<void> _placeBid(Auction auction) async {
    final amount = double.tryParse(
      _bidController.text.trim(),
    );

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid bid amount.'),
        ),
      );
      return;
    }

    final minimumBid =
        auction.currentPrice + auction.minIncrement;

    if (amount < minimumBid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Minimum bid is ${formatPrice(minimumBid)}',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isPlacingBid = true;
    });

    try {
      await _bidService.placeBid(
        assetId: auction.assetId,
        bidAmount: amount,
      );

      if (!mounted) return;

      _bidController.clear();

      setState(() {
        _loadDetails();
        _loadBidHistory();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bid placed successfully!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPlacingBid = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auction Details'),
      ),

      body: FutureBuilder<AuctionDetails>(
        future: _detailsFuture,

        builder: (context, snapshot) {
          // Loading auction details
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Auction details error
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Unable to load auction details.\n'
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _loadDetails();
                          _loadBidHistory();
                        });
                      },
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          // No auction details
          if (!snapshot.hasData) {
            return const Center(
              child: Text(
                'No auction details available.',
              ),
            );
          }

          final details = snapshot.data!;
          final auction = details.auction;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // Auction image
                _buildImage(details.images),

                const SizedBox(height: 20),

                // Auction title
                Text(
                  auction.title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),

                const SizedBox(height: 10),

                // Description
                Text(
                  auction.description ??
                      'No description provided.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge,
                ),

                const SizedBox(height: 24),

                // Starting price
                _buildPriceRow(
                  'Starting Price',
                  formatPrice(auction.startingPrice),
                ),

                // Current price
                _buildPriceRow(
                  'Current Price',
                  formatPrice(auction.currentPrice),
                ),

                // Minimum increment
                _buildPriceRow(
                  'Minimum Increment',
                  formatPrice(auction.minIncrement),
                ),

                // Auction status
                _buildPriceRow(
                  'Auction Status',
                  auction.status.toUpperCase(),
                ),

                // Auction end time
                _buildPriceRow(
                  'Auction Ends',
                  DateFormat('dd MMM yyyy, hh:mm a')
                      .format(auction.endTime.toLocal()),
                ),

                const SizedBox(height: 28),

                // Bidding interface
                if (auction.status == 'live') ...[
                  Text(
                    'Minimum next bid: '
                    '${formatPrice(auction.currentPrice + auction.minIncrement)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: _bidController,

                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),

                    decoration: const InputDecoration(
                      labelText: 'Enter your bid',
                      prefixText: 'UGX ',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,

                    child: ElevatedButton(
                      onPressed: _isPlacingBid
                          ? null
                          : () => _placeBid(auction),

                      child: _isPlacingBid
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Place Bid'),
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Bid history heading
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,

                  children: [
                    Text(
                      'Bid History',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),

                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh bid history',

                      onPressed: () {
                        setState(() {
                          _loadBidHistory();
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Bid history list
                _buildBidHistory(),
              ],
            ),
          );
        },
      ),
    );
  }

  // Bid history widget
  Widget _buildBidHistory() {
    return FutureBuilder<List<Bid>>(
      future: _bidHistoryFuture,

      builder: (context, bidSnapshot) {
        // Loading history
        if (bidSnapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        // History error
        if (bidSnapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),

              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Unable to load bid history.\n'
                    '${bidSnapshot.error}',
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: () {
                      setState(() {
                        _loadBidHistory();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final bids = bidSnapshot.data ?? [];

        // Empty history
        if (bids.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),

              child: Center(
                child: Text(
                  'No bids have been placed yet.',
                ),
              ),
            ),
          );
        }

        // Display bids
        return Column(
          children: bids.map((bid) {
            return Card(
              margin: const EdgeInsets.only(
                bottom: 10,
              ),

              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.gavel),
                ),

                title: Text(
                  formatPrice(bid.bidAmount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                subtitle: Text(
                  'Bidder ID: ${bid.userId}\n'
                  '${DateFormat('dd MMM yyyy, hh:mm a').format(bid.placedAt.toLocal())}',
                ),

                isThreeLine: true,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // Auction image widget
  Widget _buildImage(List<AuctionImage> images) {
    final primaryImage =
        images.where((image) => image.isPrimary);

    final imagePath = primaryImage.isNotEmpty
        ? primaryImage.first.filePath
        : images.isNotEmpty
            ? images.first.filePath
            : '';

    final uri = Uri.tryParse(imagePath);

    final isNetworkImage = uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;

    if (!isNetworkImage) {
      return Container(
        height: 220,
        width: double.infinity,

        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),

        child: const Icon(
          Icons.image_outlined,
          size: 70,
          color: Colors.grey,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),

      child: Image.network(
        imagePath,
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,

        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 220,
            color: Colors.grey.shade200,

            child: const Center(
              child: Icon(
                Icons.broken_image_outlined,
                size: 60,
              ),
            ),
          );
        },
      ),
    );
  }

  // Price row widget
  Widget _buildPriceRow(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
      ),

      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,

        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,

              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Dispose controller
  @override
  void dispose() {
    _bidController.dispose();
    super.dispose();
  }
}