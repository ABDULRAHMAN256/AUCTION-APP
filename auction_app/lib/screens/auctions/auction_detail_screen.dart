
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/auction.dart';
import '../../models/auction_details.dart';
import '../../services/auction_service.dart';
import '../../services/auth_service.dart';
import '../../services/bid_service.dart';

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

  AuctionDetails? _cachedDetails;

  final AuctionService _auctionService = AuctionService();
  final AuthService _authService = AuthService();
  final BidService _bidService = BidService();
  bool _isOwner = false;

  final TextEditingController _bidController =
      TextEditingController();

  Timer? _countdownTimer;
  Timer? _autoRefreshTimer;

  Duration _remainingTime = Duration.zero;

  late DateTime _auctionEndTime;

  bool _isPlacingBid = false;
  bool _isAutoRefreshing = false;

  bool get _auctionEnded =>
      _remainingTime <= Duration.zero;

  @override
  void initState() {
    super.initState();

    _auctionEndTime = widget.auction.endTime;

    _detailsFuture = _loadDetails();

    _checkOwnership();

    _startCountdown();
    _startAutoRefresh();
  }

  // =========================================================
  // LOAD AUCTION DETAILS
  // =========================================================

  Future<AuctionDetails> _loadDetails() async {
    final details = await _auctionService
        .getAuctionDetails(widget.auction.assetId);

    _cachedDetails = details;
    _auctionEndTime = details.auction.endTime;

    return details;
  }

  // =========================================================
  // LOAD BID HISTORY
  // =========================================================

  Future<void> _checkOwnership() async {
    final userId = await _authService.getCurrentUserId();

    if (!mounted) return;

    setState(() {
      _isOwner = userId != null &&
          userId == widget.auction.sellerId;
    });
  }

  // =========================================================
  // COUNTDOWN TIMER
  // =========================================================

  void _updateRemainingTime() {
    final difference =
        _auctionEndTime.difference(DateTime.now());

    if (difference.isNegative) {
      _remainingTime = Duration.zero;
    } else {
      _remainingTime = difference;
    }
  }

  void _startCountdown() {
    _updateRemainingTime();

    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        setState(() {
          _updateRemainingTime();
        });

        if (_auctionEnded) {
          timer.cancel();
        }
      },
    );
  }

  // =========================================================
  // AUTOMATIC REFRESH
  // =========================================================

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        _refreshAuctionData();
      },
    );
  }

  Future<void> _refreshAuctionData() async {
    if (!mounted || _isAutoRefreshing) {
      return;
    }

    _isAutoRefreshing = true;

    final newDetailsFuture = _loadDetails();

    setState(() {
      _detailsFuture = newDetailsFuture;
    });

    try {
      await newDetailsFuture;

      if (mounted) {
        setState(() {
          _updateRemainingTime();
        });
      }
    } catch (_) {
      // FutureBuilder handles errors.
    } finally {
      if (mounted) {
        setState(() {
          _isAutoRefreshing = false;
        });
      } else {
        _isAutoRefreshing = false;
      }
    }
  }

  // =========================================================
  // PRICE FORMATTING
  // =========================================================

  String formatPrice(num price) {
    return NumberFormat.currency(
      locale: 'en_US',
      symbol: 'UGX ',
      decimalDigits: 0,
    ).format(price);
  }

  // =========================================================
  // PLACE BID
  // =========================================================

  Future<void> _placeBid() async {
    if (_isPlacingBid) {
      return;
    }

    if (_auctionEnded) {
      _showMessage('This auction has ended.');
      return;
    }

    final enteredAmount =
        double.tryParse(_bidController.text.trim());

    if (enteredAmount == null || enteredAmount <= 0) {
      _showMessage('Enter a valid bid amount.');
      return;
    }

    final currentAuction =
        _cachedDetails?.auction ?? widget.auction;

    final minimumBid =
        currentAuction.currentPrice +
        currentAuction.minIncrement;

    if (enteredAmount < minimumBid) {
      _showMessage(
        'Your bid must be at least '
        '${formatPrice(minimumBid)}',
      );
      return;
    }

    setState(() {
      _isPlacingBid = true;
    });

    try {
      await _bidService.placeBid(
        assetId: widget.auction.assetId,
        bidAmount: enteredAmount,
      );

      _bidController.clear();

      await _refreshAuctionData();

      if (mounted) {
        _showMessage('Bid placed successfully!');
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Bid failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPlacingBid = false;
        });
      }
    }
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // =========================================================
  // COUNTDOWN WIDGET
  // =========================================================

  Widget _buildCountdown() {
    final days = _remainingTime.inDays;
    final hours = _remainingTime.inHours % 24;
    final minutes = _remainingTime.inMinutes % 60;
    final seconds = _remainingTime.inSeconds % 60;

    if (_auctionEnded) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.2),
          ),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.timer_off_outlined,
              color: Colors.red,
              size: 30,
            ),
            SizedBox(height: 8),
            Text(
              'Auction Ended',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.indigo.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.indigo.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'TIME REMAINING',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _timeBox(days, 'Days'),
              _timeSeparator(),
              _timeBox(hours, 'Hours'),
              _timeSeparator(),
              _timeBox(minutes, 'Minutes'),
              _timeSeparator(),
              _timeBox(seconds, 'Seconds'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeBox(int value, String label) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 5,
            ),
            decoration: BoxDecoration(
              color: Colors.indigo,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                value.toString().padLeft(2, '0'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeSeparator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        ':',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // =========================================================
  // AUCTION STATUS
  // =========================================================

  Widget _buildStatusBadge(String status) {
    final isLive = status.toLowerCase() == 'live';

    final color = isLive
        ? Colors.green
        : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // AUCTION IMAGE
  // =========================================================

  Widget _buildImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return _imagePlaceholder();
    }

    return Image.network(
      imagePath,
      fit: BoxFit.cover,
      width: double.infinity,
      height: 260,
      errorBuilder: (context, error, stackTrace) {
        return _imagePlaceholder();
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return Container(
          height: 260,
          color: Colors.grey.shade200,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 260,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 70,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildAuctionImages(AuctionDetails details) {
    if (details.images.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _imagePlaceholder(),
      );
    }

    final images = [...details.images];

    images.sort((a, b) {
      if (a.isPrimary && !b.isPrimary) return -1;
      if (!a.isPrimary && b.isPrimary) return 1;
      return 0;
    });

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 260,
        child: PageView.builder(
          itemCount: images.length,
          itemBuilder: (context, index) {
            return _buildImage(
              images[index].filePath,
            );
          },
        ),
      ),
    );
  }

  // =========================================================
  // PRICE ROW
  // =========================================================

  Widget _buildPriceRow(
    String label,
    String value, {
    bool highlighted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: highlighted ? 20 : 15,
              fontWeight: highlighted
                  ? FontWeight.bold
                  : FontWeight.w600,
              color: highlighted
                  ? Colors.indigo
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BID SECTION
  // =========================================================

  Widget _buildBidSection(Auction auction) {
    final minimumBid =
        auction.currentPrice + auction.minIncrement;

    final isLive =
        auction.status.toLowerCase() == 'live';

    final canBid = isLive && !_auctionEnded && !_isOwner;

    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Place Your Bid',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Minimum acceptable bid: '
              '${formatPrice(minimumBid)}',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _bidController,
              enabled: canBid && !_isPlacingBid,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Your bid amount',
                prefixText: 'UGX ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: canBid && !_isPlacingBid
                    ? _placeBid
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isPlacingBid
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isOwner
                            ? 'Your Listing'
                            : canBid
                                ? 'Place Bid'
                                : 'Bidding Unavailable',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // =========================================================
  // MAIN AUCTION CONTENT
  // =========================================================

  Widget _buildAuctionContent(
    AuctionDetails details,
  ) {
    final auction = details.auction;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // Auction images
          _buildAuctionImages(details),

          const SizedBox(height: 20),

          // Title
          Text(
            auction.title,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          // Status
          _buildStatusBadge(auction.status),

          const SizedBox(height: 20),

          // Countdown
          _buildCountdown(),

          const SizedBox(height: 20),

          // Pricing card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Colors.grey.shade200,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _buildPriceRow(
                    'Starting Price',
                    formatPrice(
                      auction.startingPrice,
                    ),
                  ),

                  Divider(
                    color: Colors.grey.shade200,
                  ),

                  _buildPriceRow(
                    'Current Price',
                    formatPrice(
                      auction.currentPrice,
                    ),
                    highlighted: true,
                  ),

                  Divider(
                    color: Colors.grey.shade200,
                  ),

                  _buildPriceRow(
                    'Minimum Increment',
                    formatPrice(
                      auction.minIncrement,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Description
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            auction.description?.isNotEmpty == true
                ? auction.description!
                : 'No description available.',
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.grey.shade700,
            ),
          ),

          const SizedBox(height: 24),

          // Bid form
          _buildBidSection(auction),

          const SizedBox(height: 28),
        ],
      ),
    );
  }

  // =========================================================
  // MAIN BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auction Details'),
        actions: [
          if (_isAutoRefreshing)
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: Center(
                child: SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh auction data',
              onPressed: _refreshAuctionData,
            ),
        ],
      ),

      body: FutureBuilder<AuctionDetails>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          // Show spinner only when no previous data exists.
          if (snapshot.connectionState ==
                  ConnectionState.waiting &&
              !snapshot.hasData &&
              _cachedDetails == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError &&
              _cachedDetails == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 50,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Unable to load auction details.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _refreshAuctionData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final details = snapshot.data ??
              _cachedDetails;

          if (details == null) {
            return const Center(
              child: Text(
                'Auction details unavailable.',
              ),
            );
          }

          return _buildAuctionContent(details);
        },
      ),
    );
  }

  // =========================================================
  // CLEANUP
  // =========================================================

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _autoRefreshTimer?.cancel();

    _bidController.dispose();

    super.dispose();
  }
}
