import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/asset.dart';
import '../models/bid.dart';
import '../providers/auth_provider.dart';
import '../utils.dart';
import '../widgets/error_view.dart';
import 'asset_detail_screen.dart';

class MyBidsScreen extends StatefulWidget {
  const MyBidsScreen({super.key});
  @override
  State<MyBidsScreen> createState() => _MyBidsScreenState();
}

class _MyBidsScreenState extends State<MyBidsScreen> {
  late Future<(List<Bid>, Map<int, Asset>)> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<(List<Bid>, Map<int, Asset>)> _fetch() async {
    final api = context.read<AuthProvider>().api;
    final results = await Future.wait([api.myBids(), api.fetchAssets()]);
    final bids = results[0] as List<Bid>;
    final assets = {for (final a in results[1] as List<Asset>) a.id: a};
    return (bids, assets);
  }

  void _reload() => setState(() => _future = _fetch());

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text('My Bids',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ),
          Expanded(
            child: FutureBuilder(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return ErrorView(
                      message: snap.error.toString(), onRetry: _reload);
                }
                final (bids, assets) = snap.data!;
                if (bids.isEmpty) {
                  return const Center(child: Text("You haven't placed any bids yet"));
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    _reload();
                    await _future;
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: bids.length,
                    itemBuilder: (_, i) {
                      final b = bids[i];
                      final asset = assets[b.assetId];
                      final leading =
                          asset != null && asset.currentPrice == b.amount;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14)),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          title: Text(asset?.title ?? 'Asset #${b.assetId}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(
                              '${ugx(b.amount)} • ${timeAgo(b.placedAt)}'),
                          trailing: leading
                              ? const Chip(
                                  label: Text('Leading'),
                                  visualDensity: VisualDensity.compact)
                              : const Icon(Icons.chevron_right),
                          onTap: () async {
                            await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        AssetDetailScreen(assetId: b.assetId)));
                            _reload();
                          },
                        ),
                      );
                    },
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