
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../models/auction.dart';

class AuctionCard extends StatefulWidget {
  final Auction auction;
  final VoidCallback onTap;

  const AuctionCard({
    super.key,
    required this.auction,
    required this.onTap,
  });

  @override
  State<AuctionCard> createState() => _AuctionCardState();
}

class _AuctionCardState extends State<AuctionCard> {
  Timer? _timer;

  Duration _remainingTime = Duration.zero;

  String get _status {
    final originalStatus = widget.auction.status.toLowerCase();

    if (originalStatus == 'live' &&
        widget.auction.endTime.isBefore(DateTime.now())) {
      return 'ended';
    }

    return originalStatus;
  }

  bool get _isLive => _status == 'live';

  bool get _isUpcoming => _status == 'upcoming';

  @override
  void initState() {
    super.initState();

    _updateRemainingTime();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;

        setState(() {
          _updateRemainingTime();
        });
      },
    );
  }

  void _updateRemainingTime() {
    final difference =
        widget.auction.endTime.difference(DateTime.now());

    _remainingTime = difference.isNegative
        ? Duration.zero
        : difference;
  }

  String get _countdownText {
    if (_remainingTime <= Duration.zero) {
      return 'Auction ended';
    }

    final days = _remainingTime.inDays;
    final hours = _remainingTime.inHours % 24;
    final minutes = _remainingTime.inMinutes % 60;
    final seconds = _remainingTime.inSeconds % 60;

    if (days > 0) {
      return '${days}d ${hours}h remaining';
    }

    if (hours > 0) {
      return '${hours}h ${minutes}m remaining';
    }

    if (minutes > 0) {
      return '${minutes}m ${seconds}s remaining';
    }

    return '${seconds}s remaining';
  }

  String formatPrice(double price) {
    return NumberFormat.currency(
      locale: 'en_UG',
      symbol: 'UGX ',
      decimalDigits: 0,
    ).format(price);
  }

  Color get _statusColor {
    switch (_status) {
      case 'live':
        return Colors.green.shade700;
      case 'upcoming':
        return Colors.orange.shade800;
      case 'sold':
        return Colors.blue.shade700;
      case 'ended':
        return Colors.grey.shade700;
      default:
        return AppTheme.navy;
    }
  }

  Color get _statusBackground {
    switch (_status) {
      case 'live':
        return const Color(0xFFE4F4E9);
      case 'upcoming':
        return const Color(0xFFFFF2DC);
      case 'sold':
        return const Color(0xFFE5EEFF);
      case 'ended':
        return const Color(0xFFE8EBF0);
      default:
        return Colors.grey.shade100;
    }
  }

  String get _statusLabel {
    switch (_status) {
      case 'live':
        return 'LIVE';
      case 'upcoming':
        return 'UPCOMING';
      case 'sold':
        return 'SOLD';
      case 'ended':
        return 'ENDED';
      default:
        return _status.toUpperCase();
    }
  }

  IconData get _statusIcon {
    switch (_status) {
      case 'live':
        return Icons.circle;
      case 'upcoming':
        return Icons.schedule;
      case 'sold':
        return Icons.check_circle_outline;
      case 'ended':
        return Icons.timer_off_outlined;
      default:
        return Icons.info_outline;
    }
  }

  // =========================================================
  // IMAGE
  // =========================================================

  Widget _buildImage() {
    final imageUrl = widget.auction.imageUrl;

    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return _buildImagePlaceholder();
    }

    return Image.network(
      imageUrl,
      height: 190,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return child;
        }

        return Container(
          height: 190,
          color: const Color(0xFFE8EBF0),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.gold,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildImagePlaceholder();
      },
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 190,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFE8EBF0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 55,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 8),
          Text(
            'Image unavailable',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // STATUS BADGE
  // =========================================================

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: _statusBackground,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _statusIcon,
            size: 11,
            color: _statusColor,
          ),
          const SizedBox(width: 6),
          Text(
            _statusLabel,
            style: TextStyle(
              color: _statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // COUNTDOWN
  // =========================================================

  Widget _buildCountdown() {
    IconData icon;
    Color color;
    String text;

    if (_isLive) {
      icon = Icons.timer_outlined;
      color = _remainingTime.inHours < 1
          ? Colors.red.shade700
          : AppTheme.gold;

      text = _countdownText;
    } else if (_isUpcoming) {
      icon = Icons.event_outlined;
      color = Colors.orange.shade800;

      text =
          'Starts ${DateFormat('dd MMM yyyy').format(widget.auction.startTime.toLocal())}';
    } else {
      icon = Icons.event_busy_outlined;
      color = Colors.grey.shade600;

      text = 'Auction closed';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // PRICE SECTION
  // =========================================================

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isLive ? 'CURRENT BID' : 'PRICE',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),

        const SizedBox(height: 6),

        FittedBox(
          alignment: Alignment.centerLeft,
          fit: BoxFit.scaleDown,
          child: Text(
            formatPrice(widget.auction.currentPrice),
            style: const TextStyle(
              color: AppTheme.navy,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'Starting at ${formatPrice(widget.auction.startingPrice)}',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // CARD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      margin: EdgeInsets.zero,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: Color(0xFFE8EBF0),
        ),
      ),

      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE
            Stack(
              children: [
                _buildImage(),

                Positioned(
                  top: 12,
                  left: 12,
                  child: _buildStatusBadge(),
                ),

                if (_isLive)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.navy.withValues(
                          alpha: 0.9,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.gavel,
                            color: Colors.white,
                            size: 13,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'BIDDING OPEN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // CONTENT
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TITLE
                  Text(
                    widget.auction.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      height: 1.3,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.navy,
                    ),
                  ),

                  const SizedBox(height: 9),

                  // DESCRIPTION
                  Text(
                    widget.auction.description?.isNotEmpty == true
                        ? widget.auction.description!
                        : 'No description provided.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // PRICE
                  _buildPriceSection(),

                  const SizedBox(height: 16),

                  // DIVIDER
                  Divider(
                    height: 1,
                    color: Colors.grey.shade200,
                  ),

                  const SizedBox(height: 14),

                  // FOOTER
                  Row(
                    children: [
                      Expanded(
                        child: _buildCountdown(),
                      ),

                      const SizedBox(width: 8),

                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: AppTheme.navy,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // CLEANUP
  // =========================================================

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
