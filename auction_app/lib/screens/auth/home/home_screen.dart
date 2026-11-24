
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
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

  List<Auction> _auctions = [];

  bool _isLoading = true;
  String? _error;
  String _selectedStatus = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAuctions();
  }

  Future<void> _loadAuctions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _auctionService.getAuctions(
        status: _selectedStatus,
        search: _searchQuery,
      );

      if (!mounted) return;

      setState(() {
        _auctions = results;
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

  void _openAuction(Auction auction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AuctionDetailScreen(
          auction: auction,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'UGANDA AUCTIONS',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _loadAuctions,

        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [

            const Text(
              'Discover',
              style: TextStyle(
                color: AppTheme.textGrey,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Find Your Next Opportunity',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.navy,
              ),
            ),

            const SizedBox(height: 22),

            // FEATURED BANNER
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppTheme.navy,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PUBLIC ASSET AUCTIONS',
                    style: TextStyle(
                      color: AppTheme.gold,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Bid with confidence.\nOwn new opportunities.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // SEARCH
            TextField(
              decoration: InputDecoration(
                hintText: 'Search auctions...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchQuery = '';
                    _loadAuctions();
                  },
                ),
              ),
              onSubmitted: (value) {
                _searchQuery = value;
                _loadAuctions();
              },
            ),

            const SizedBox(height: 22),

            const Text(
              'Auction Listings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.navy,
              ),
            ),

            const SizedBox(height: 14),

            // STATUS FILTERS
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('All', 'all'),
                  _filterChip('Live', 'live'),
                  _filterChip('Upcoming', 'upcoming'),
                  _filterChip('Sold', 'sold'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // LOADING STATE
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(35),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.gold,
                  ),
                ),
              )

            // ERROR STATE
            else if (_error != null)
              Column(
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    size: 45,
                    color: AppTheme.textGrey,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loadAuctions,
                    child: const Text('Try Again'),
                  ),
                ],
              )

            // EMPTY STATE
            else if (_auctions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(25),
                child: Center(
                  child: Text(
                    'No auctions found.',
                    style: TextStyle(
                      color: AppTheme.textGrey,
                    ),
                  ),
                ),
              )

            // AUCTION LIST
            else
              ..._auctions.map(
                (auction) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: AuctionCard(
                    auction: auction,
                    onTap: () => _openAuction(auction),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _selectedStatus == value;

    return Padding(
      padding: const EdgeInsets.only(right: 9),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: AppTheme.navy,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppTheme.navy,
          fontWeight: FontWeight.w600,
        ),
        onSelected: (_) {
          setState(() {
            _selectedStatus = value;
          });
          _loadAuctions();
        },
      ),
    );
  }
}
