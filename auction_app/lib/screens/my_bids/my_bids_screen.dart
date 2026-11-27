import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../models/bid.dart';
import '../../services/bid_history_service.dart';

class MyBidsScreen extends StatefulWidget {
  const MyBidsScreen({super.key});

  @override
  State<MyBidsScreen> createState() => _MyBidsScreenState();
}

class _MyBidsScreenState extends State<MyBidsScreen> {
  final BidHistoryService _bidHistoryService = BidHistoryService();

  List<Bid> _bids = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBids();
  }

  Future<void> _loadBids() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final bids = await _bidHistoryService.getMyBids();

      if (!mounted) return;

      setState(() {
        _bids = bids;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _formatPrice(double price) {
    return NumberFormat.currency(
      locale: 'en_UG',
      symbol: 'UGX ',
      decimalDigits: 0,
    ).format(price);
  }

  String _formatDate(DateTime date) {
    return DateFormat(
      'dd MMM yyyy',
    ).format(date.toLocal());
  }

  String _formatTime(DateTime date) {
    return DateFormat(
      'HH:mm',
    ).format(date.toLocal());
  }

  // --------------------------------------------------
  // BID DETAILS DIALOG
  // --------------------------------------------------

  void _showBidDetails(Bid bid) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.navy.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.receipt_long,
                          color: AppTheme.navy,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Bid Details',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Bid amount
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.navy,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'YOUR BID AMOUNT',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatPrice(bid.bidAmount),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Auction title
                  _detailRow(
                    icon: Icons.directions_car_outlined,
                    label: 'Auction Item',
                    value: bid.assetTitle ?? 'Auction #${bid.assetId}',
                  ),

                  const Divider(height: 28),

                  // Auction ID
                  _detailRow(
                    icon: Icons.tag,
                    label: 'Auction ID',
                    value: bid.assetId.toString(),
                  ),

                  const Divider(height: 28),

                  // Bidder ID
                  _detailRow(
                    icon: Icons.person_outline,
                    label: 'Bidder ID',
                    value: bid.userId.toString(),
                  ),

                  const Divider(height: 28),

                  // Bid date
                  _detailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Bid Date',
                    value: _formatDate(bid.placedAt),
                  ),

                  const Divider(height: 28),

                  // Bid time
                  _detailRow(
                    icon: Icons.access_time,
                    label: 'Bid Time',
                    value: _formatTime(bid.placedAt),
                  ),

                  const SizedBox(height: 24),

                  // Close button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.navy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Close Details',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --------------------------------------------------
  // DETAIL ROW
  // --------------------------------------------------

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.navy,
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // BID LOG CARD
  // --------------------------------------------------

  Widget _buildBidCard(Bid bid) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),

          // Clicking the card opens bid details
          onTap: () => _showBidDetails(bid),

          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.navy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.gavel,
                    color: AppTheme.navy,
                    size: 25,
                  ),
                ),

                const SizedBox(width: 14),

                // Bid information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bid.assetTitle ??
                            'Auction #${bid.assetId}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 7),

                      Text(
                        _formatPrice(bid.bidAmount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.navy,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: Colors.grey.shade600,
                          ),

                          const SizedBox(width: 5),

                          Text(
                            _formatDate(bid.placedAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),

                          const SizedBox(width: 10),

                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: Colors.grey.shade600,
                          ),

                          const SizedBox(width: 5),

                          Text(
                            _formatTime(bid.placedAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 7),

                      Text(
                        'Tap to view bid details',
                        style: TextStyle(
                          color: AppTheme.navy,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Click indicator
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade500,
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // EMPTY STATE
  // --------------------------------------------------

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 130),

        Icon(
          Icons.gavel,
          size: 70,
          color: Colors.grey.shade300,
        ),

        const SizedBox(height: 20),

        const Center(
          child: Text(
            'No bids yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 8),

        Center(
          child: Text(
            'Your bidding activity will appear here.',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // ERROR STATE
  // --------------------------------------------------

  Widget _buildErrorState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 100),

        const Icon(
          Icons.error_outline,
          size: 60,
          color: Colors.redAccent,
        ),

        const SizedBox(height: 16),

        Center(
          child: Text(
            _error ?? 'Something went wrong',
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 20),

        Center(
          child: ElevatedButton.icon(
            onPressed: _loadBids,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // SCREEN
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Bids',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadBids,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh bids',
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _loadBids,

        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _error != null
                ? _buildErrorState()
                : _bids.isEmpty
                    ? _buildEmptyState()
                    : ListView(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Summary header
                          Container(
                            margin: const EdgeInsets.only(
                              bottom: 20,
                            ),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppTheme.navy,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Bidding Activity',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),

                                      SizedBox(height: 6),

                                      Text(
                                        'Your bid history',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '${_bids.length}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      const Text(
                                        'BIDS',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Bid logs
                          ..._bids.map(
                            (bid) => _buildBidCard(bid),
                          ),
                        ],
                      ),
      ),
    );
  }
}
