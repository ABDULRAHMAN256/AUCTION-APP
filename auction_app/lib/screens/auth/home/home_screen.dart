import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/auction.dart';
import '../../../services/auction_service.dart';
import '../../../widgets/auction_card.dart';
import '../../auctions/auction_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuctionService _auctionService = AuctionService();

  final TextEditingController _searchController =
      TextEditingController();

  List<Auction> _auctions = [];

  bool _isLoading = true;
  String? _error;

  String _selectedStatus = 'all';
  String _selectedCategory = 'All';
  String _searchQuery = '';

  Timer? _searchDebounce;

  int _requestNumber = 0;

  final List<String> _categories = [
    'All',
    'Vehicles',
    'Machinery',
    'Property',
    'Electronics',
    'Furniture',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadAuctions();
  }

  // --------------------------------------------------
  // LOAD AUCTIONS
  // --------------------------------------------------

  Future<void> _loadAuctions({
    bool showLoading = true,
  }) async {
    final currentRequest = ++_requestNumber;

    if (showLoading && _auctions.isEmpty) {
      setState(() {
        _isLoading = true;
      });
    }

    setState(() {
      _error = null;
    });

    try {
      final auctions = await _auctionService.getAuctions(
        status: _selectedStatus == 'all'
            ? null
            : _selectedStatus,
        search: _searchQuery.isEmpty
            ? null
            : _searchQuery,
      );

      if (!mounted || currentRequest != _requestNumber) {
        return;
      }

      setState(() {
        _auctions = auctions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || currentRequest != _requestNumber) {
        return;
      }

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // --------------------------------------------------
  // SEARCH
  // --------------------------------------------------

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.trim();
    });

    _searchDebounce?.cancel();

    _searchDebounce = Timer(
      const Duration(milliseconds: 450),
      () {
        _loadAuctions(showLoading: false);
      },
    );
  }

  // --------------------------------------------------
  // STATUS FILTER
  // --------------------------------------------------

  void _selectStatus(String status) {
    if (_selectedStatus == status) return;

    setState(() {
      _selectedStatus = status;
    });

    _loadAuctions();
  }

  // --------------------------------------------------
  // CATEGORY FILTER
  // --------------------------------------------------

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  // TEMPORARY CATEGORY DETECTION
  //
  // This uses title and description keywords.
  // Proper production filtering should use category_id
  // from your database.

  String _detectCategory(Auction auction) {
    final text = (
      '${auction.title} ${auction.description ?? ''}'
    ).toLowerCase();

    if (_containsAny(text, [
      'car',
      'toyota',
      'vehicle',
      'truck',
      'land cruiser',
      'pickup',
      'motorcycle',
      'motorbike',
      'bus',
    ])) {
      return 'Vehicles';
    }

    if (_containsAny(text, [
      'tractor',
      'excavator',
      'jcb',
      'bulldozer',
      'machinery',
      'machine',
      'backhoe',
      'loader',
      'crane',
    ])) {
      return 'Machinery';
    }

    if (_containsAny(text, [
      'land',
      'plot',
      'property',
      'house',
      'building',
      'estate',
      'acre',
      'apartment',
    ])) {
      return 'Property';
    }

    if (_containsAny(text, [
      'laptop',
      'computer',
      'phone',
      'television',
      'tv',
      'electronics',
      'printer',
      'monitor',
    ])) {
      return 'Electronics';
    }

    if (_containsAny(text, [
      'sofa',
      'chair',
      'table',
      'furniture',
      'bed',
      'cabinet',
      'desk',
    ])) {
      return 'Furniture';
    }

    return 'Other';
  }

  bool _containsAny(
    String text,
    List<String> keywords,
  ) {
    return keywords.any(
      (keyword) => text.contains(keyword),
    );
  }

  // --------------------------------------------------
  // FILTERED AUCTIONS
  // --------------------------------------------------

  List<Auction> get _filteredAuctions {
    if (_selectedCategory == 'All') {
      return _auctions;
    }

    return _auctions.where((auction) {
      return _detectCategory(auction) ==
          _selectedCategory;
    }).toList();
  }

  // --------------------------------------------------
  // CATEGORY ICONS
  // --------------------------------------------------

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'All':
        return Icons.grid_view_rounded;

      case 'Vehicles':
        return Icons.directions_car_rounded;

      case 'Machinery':
        return Icons.construction_rounded;

      case 'Property':
        return Icons.apartment_rounded;

      case 'Electronics':
        return Icons.devices_rounded;

      case 'Furniture':
        return Icons.chair_rounded;

      default:
        return Icons.category_rounded;
    }
  }

  // --------------------------------------------------
  // STATUS FILTER UI
  // --------------------------------------------------

  Widget _buildStatusFilters() {
    final statuses = [
      'all',
      'live',
      'upcoming',
      'sold',
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: statuses.length,
        separatorBuilder: (_, _) =>
            const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final status = statuses[index];

          final selected =
              _selectedStatus == status;

          final label = status == 'all'
              ? 'All auctions'
              : status[0].toUpperCase() +
                  status.substring(1);

          return ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) {
              _selectStatus(status);
            },
            selectedColor:
                Theme.of(context).colorScheme.primary,
            backgroundColor:
                Theme.of(context).colorScheme.surface,
            labelStyle: TextStyle(
              color: selected
                  ? Colors.white
                  : Theme.of(context)
                      .colorScheme
                      .onSurface,
              fontWeight: selected
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
            side: BorderSide(
              color: selected
                  ? Colors.transparent
                  : Colors.grey.withValues(alpha: 0.25),
            ),
          );
        },
      ),
    );
  }

  // --------------------------------------------------
  // CATEGORY UI
  // --------------------------------------------------

  Widget _buildCategories() {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, _) =>
            const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = _categories[index];

          final selected =
              category == _selectedCategory;

          return GestureDetector(
            onTap: () {
              _selectCategory(category);
            },
            child: AnimatedContainer(
              duration:
                  const Duration(milliseconds: 200),
              width: 82,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected
                    ? Theme.of(context)
                        .colorScheme
                        .primary
                    : Theme.of(context)
                        .colorScheme
                        .surface,
                borderRadius:
                    BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? Colors.transparent
                      : Colors.grey.withValues(
                          alpha: 0.2,
                        ),
                ),
              ),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    _categoryIcon(category),
                    size: 26,
                    color: selected
                        ? Colors.white
                        : Theme.of(context)
                            .colorScheme
                            .primary,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    category,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: selected
                          ? Colors.white
                          : Theme.of(context)
                              .colorScheme
                              .onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --------------------------------------------------
  // SEARCH UI
  // --------------------------------------------------

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search auctions...',
        prefixIcon: const Icon(
          Icons.search_rounded,
        ),
        suffixIcon:
            _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                    ),
                    onPressed: () {
                      _searchController.clear();

                      _onSearchChanged('');
                    },
                  )
                : null,
        filled: true,
        fillColor: Theme.of(context)
            .colorScheme
            .surface,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // --------------------------------------------------
  // AUCTION LIST
  // --------------------------------------------------

  Widget _buildAuctionList() {
    final auctions = _filteredAuctions;

    if (auctions.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      physics:
          const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: auctions.length,
      itemBuilder: (context, index) {
        final auction = auctions[index];

        return Padding(
          padding:
              const EdgeInsets.only(bottom: 16),
          child: AuctionCard(
            auction: auction,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AuctionDetailScreen(
                    auction: auction,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // --------------------------------------------------
  // EMPTY STATE
  // --------------------------------------------------

  Widget _buildEmptyState() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 50),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 55,
            color: Colors.grey.withValues(
              alpha: 0.6,
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'No auctions found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Try another category or search.',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 16),

          TextButton(
            onPressed: () {
              _searchController.clear();

              setState(() {
                _searchQuery = '';
                _selectedCategory = 'All';
                _selectedStatus = 'all';
              });

              _loadAuctions();
            },
            child: const Text(
              'Clear all filters',
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // ERROR STATE
  // --------------------------------------------------

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.red,
            ),

            const SizedBox(height: 12),

            const Text(
              'Unable to load auctions',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _error ?? 'An unexpected error occurred.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                _loadAuctions();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // MAIN SCREEN
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Auction Marketplace',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _loadAuctions(
                showLoading: false,
              );
            },
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: () => _loadAuctions(
          showLoading: false,
        ),

        child: ListView(
          padding:
              const EdgeInsets.all(16),
          children: [
            // SEARCH
            _buildSearchBar(),

            const SizedBox(height: 24),

            // CATEGORY HEADER
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Text(
                  'Browse assets',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // CATEGORY CARDS
            _buildCategories(),

            const SizedBox(height: 24),

            // STATUS HEADER
            const Text(
              'Auctions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            // STATUS FILTERS
            _buildStatusFilters(),

            const SizedBox(height: 18),

            // RESULTS COUNT
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_filteredAuctions.length} auctions found',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ),

                if (_selectedCategory != 'All')
                  Text(
                    _selectedCategory,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // CONTENT
            if (_isLoading &&
                _auctions.isEmpty)
              const Padding(
                padding:
                    EdgeInsets.symmetric(
                  vertical: 60,
                ),
                child: Center(
                  child:
                      CircularProgressIndicator(),
                ),
              )
            else if (_error != null &&
                _auctions.isEmpty)
              _buildErrorState()
            else
              _buildAuctionList(),
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
