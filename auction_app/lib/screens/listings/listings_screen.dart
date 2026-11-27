
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/auction.dart';
import '../../services/auction_service.dart';
import '../auctions/auction_detail_screen.dart';

class ListingsScreen extends StatefulWidget {
  const ListingsScreen({super.key});

  @override
  State<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends State<ListingsScreen> {
  final AuctionService _auctionService = AuctionService();
  final TextEditingController _searchController =
      TextEditingController();

  List<Auction> _auctions = [];

  bool _isLoading = true;
  String? _error;

  String _selectedStatus = 'all';

  Timer? _searchDebounce;
  int _requestNumber = 0;

  final List<String> _statuses = [
    'all',
    'live',
    'upcoming',
    'ended',
    'sold',
  ];

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  // ==================================================
  // LOAD LISTINGS
  // ==================================================

  Future<void> _loadListings({
    bool showLoading = true,
  }) async {
    final request = ++_requestNumber;

    if (showLoading && _auctions.isEmpty) {
      setState(() {
        _isLoading = true;
      });
    }

    setState(() {
      _error = null;
    });

    try {
      final result = await _auctionService.getMyListings();

      if (!mounted || request != _requestNumber) {
        return;
      }

      setState(() {
        _auctions = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || request != _requestNumber) {
        return;
      }

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ==================================================
  // SEARCH
  // ==================================================

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(
      const Duration(milliseconds: 450),
      () {
        _loadListings(showLoading: false);
      },
    );
  }

  // ==================================================
  // FILTER
  // ==================================================

  void _selectStatus(String status) {
    setState(() {
      _selectedStatus = status;
    });

    _loadListings();
  }

  // ==================================================
  // STATUS
  // ==================================================

  String _effectiveStatus(Auction auction) {
    final status = auction.status.toLowerCase();

    if (status == 'live' &&
        auction.endTime.isBefore(DateTime.now())) {
      return 'ended';
    }

    return status;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'live':
        return Colors.green;

      case 'upcoming':
        return Colors.orange;

      case 'sold':
        return Colors.blue;

      case 'ended':
        return Colors.grey;

      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'live':
        return 'LIVE';

      case 'upcoming':
        return 'UPCOMING';

      case 'sold':
        return 'SOLD';

      case 'ended':
        return 'ENDED';

      default:
        return status.toUpperCase();
    }
  }

  // ==================================================
  // FORMAT PRICE
  // ==================================================

  String _formatPrice(double amount) {
    return NumberFormat.currency(
      locale: 'en_UG',
      symbol: 'UGX ',
      decimalDigits: 0,
    ).format(amount);
  }

  // ==================================================
  // OPEN DETAILS
  // ==================================================

  void _viewDetails(Auction auction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AuctionDetailScreen(
          auction: auction,
        ),
      ),
    );
  }

  // ==================================================
  // EDIT
  // ==================================================

  void _editListing(Auction auction) {
    // Editing UI will be connected to the backend
    // update endpoint in the next implementation.

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit listing'),
          content: Text(
            'You selected "${auction.title}". '
            'The editing form and API update will be connected next.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);

                _showMessage(
                  'Selected listing: ${auction.title}',
                );
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  // ==================================================
  // MESSAGE
  // ==================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ==================================================
  // SEARCH BAR
  // ==================================================

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search your listings...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
                icon: const Icon(Icons.close),
              )
            : null,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ==================================================
  // STATUS FILTER
  // ==================================================

  Widget _buildStatusFilters() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _statuses.length,
        separatorBuilder: (_, _) =>
            const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final status = _statuses[index];
          final selected = status == _selectedStatus;

          final label = status == 'all'
              ? 'All'
              : status[0].toUpperCase() +
                  status.substring(1);

          return ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => _selectStatus(status),
            selectedColor:
                Theme.of(context).colorScheme.primary,
            labelStyle: TextStyle(
              color: selected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
            ),
          );
        },
      ),
    );
  }

  // ==================================================
  // LISTING CARD
  // ==================================================

  Widget _buildListingCard(Auction auction) {
    final status = _effectiveStatus(auction);
    final color = _statusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGE
          SizedBox(
            height: 180,
            width: double.infinity,
            child: auction.imageUrl != null &&
                    auction.imageUrl!.isNotEmpty
                ? Image.network(
                    auction.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) {
                      return _imagePlaceholder();
                    },
                  )
                : _imagePlaceholder(),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // STATUS
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusLabel(status),
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const Spacer(),

                    Text(
                      'ID: ${auction.assetId}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // TITLE
                Text(
                  auction.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                if (auction.description != null)
                  Text(
                    auction.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),

                const SizedBox(height: 14),

                // PRICE
                Text(
                  'Current price',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  _formatPrice(auction.currentPrice),
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),

                const SizedBox(height: 10),

                // END TIME
                Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Ends: ${auction.endTime.toLocal()}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ACTIONS
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewDetails(auction),
                        icon: const Icon(
                          Icons.visibility_outlined,
                        ),
                        label: const Text('View details'),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _editListing(auction),
                        icon: const Icon(
                          Icons.edit_outlined,
                        ),
                        label: const Text('Edit'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: Colors.grey.withValues(alpha: 0.12),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 55,
          color: Colors.grey,
        ),
      ),
    );
  }

  // ==================================================
  // EMPTY STATE
  // ==================================================

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 60,
            color: Colors.grey,
          ),

          const SizedBox(height: 16),

          const Text(
            'No listings found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Your listings will appear here.',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================
  // ERROR
  // ==================================================

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 50,
            color: Colors.red,
          ),

          const SizedBox(height: 12),

          const Text(
            'Unable to load listings',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            _error ?? '',
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: _loadListings,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ==================================================
  // BUILD
  // ==================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Listings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _loadListings(showLoading: false);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: () => _loadListings(
          showLoading: false,
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // HEADER
            const Text(
              'Manage your auctions',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Track, review and manage your assets.',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 20),

            // SEARCH
            _buildSearchBar(),

            const SizedBox(height: 20),

            // FILTERS
            _buildStatusFilters(),

            const SizedBox(height: 20),

            // COUNT
            Text(
              '${_auctions.length} listings',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 14),

            // CONTENT
            if (_isLoading && _auctions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null && _auctions.isEmpty)
              _buildError()
            else if (_auctions.isEmpty)
              _buildEmptyState()
            else
              ..._auctions.map(_buildListingCard),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}
