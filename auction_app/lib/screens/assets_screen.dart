import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/asset.dart';
import '../providers/auth_provider.dart';
import '../widgets/asset_card.dart';
import '../widgets/error_view.dart';
import 'asset_detail_screen.dart';

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key});
  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  String? _status; // null = all
  String _search = '';
  late Future<List<Asset>> _future;

  static const _filters = <String, String?>{
    'All': null,
    'Live': 'live',
    'Upcoming': 'upcoming',
    'Sold': 'sold',
  };

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<List<Asset>> _fetch() => context
      .read<AuthProvider>()
      .api
      .fetchAssets(status: _status, search: _search);

  void _reload() => setState(() => _future = _fetch());

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text('Auctions',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search vehicles, land, equipment…',
                prefixIcon: Icon(Icons.search),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (v) {
                _search = v.trim();
                _reload();
              },
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: _filters.entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(e.key),
                    selected: _status == e.value,
                    onSelected: (_) {
                      _status = e.value;
                      _reload();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Asset>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return ErrorView(
                      message: snap.error.toString(), onRetry: _reload);
                }
                final items = snap.data!;
                if (items.isEmpty) {
                  return const Center(child: Text('No auctions found'));
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    _reload();
                    await _future;
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    itemCount: items.length,
                    itemBuilder: (_, i) => AssetCard(
                      asset: items[i],
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  AssetDetailScreen(assetId: items[i].id)),
                        );
                        _reload(); // refresh prices when coming back
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}