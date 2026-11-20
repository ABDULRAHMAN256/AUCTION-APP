import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/asset.dart';
import '../models/bid.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils.dart';
import '../widgets/error_view.dart';

class AssetDetailScreen extends StatefulWidget {
  const AssetDetailScreen({super.key, required this.assetId});
  final int assetId;
  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  Asset? _asset;
  List<Bid> _bids = [];
  String? _error;
  bool _loading = true;
  bool _submitting = false;
  final _bidCtrl = TextEditingController();
  Timer? _poll;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => _load(silent: true));
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {}); // updates the countdown
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _tick?.cancel();
    _bidCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    final api = context.read<AuthProvider>().api;
    try {
      final results = await Future.wait([
        api.fetchAsset(widget.assetId),
        api.fetchBids(widget.assetId),
      ]);
      if (!mounted) return;
      setState(() {
        _asset = results[0] as Asset;
        _bids = results[1] as List<Bid>;
        _error = null;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted || silent) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red.shade700 : null,
      ));
  }

  Future<void> _placeBid() async {
    final a = _asset!;
    final amount = double.tryParse(_bidCtrl.text.replaceAll(',', '').trim());
    if (amount == null || amount < a.minimumBid) {
      _snack('Enter at least ${ugx(a.minimumBid)}', error: true);
      return;
    }
    final api = context.read<AuthProvider>().api;
    setState(() => _submitting = true);
    try {
      await api.placeBid(a.id, amount);
      _bidCtrl.clear();
      FocusManager.instance.primaryFocus?.unfocus();
      _snack('Bid placed: ${ugx(amount)}');
      await _load(silent: true);
    } on ApiException catch (e) {
      _snack(e.message, error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = _asset;
    return Scaffold(
      appBar: AppBar(title: Text(a?.title ?? 'Auction')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null || a == null
              ? ErrorView(message: _error ?? 'Not found', onRetry: _load)
              : Column(
                  children: [
                    Expanded(child: _content(a)),
                    if (a.status == 'live') _bidBar(a),
                  ],
                ),
    );
  }

  Widget _content(Asset a) {
    final scheme = Theme.of(context).colorScheme;
    final myId = context.read<AuthProvider>().userId;
    final color = statusColor(a.status);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        // Images
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 220,
            child: a.images.isEmpty
                ? Container(
                    color: scheme.primaryContainer,
                    child: Icon(categoryIcon(a.categoryId),
                        size: 64, color: scheme.primary))
                : PageView(
                    children: a.images
                        .map((url) => Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.broken_image)),
                            ))
                        .toList(),
                  ),
          ),
        ),
        const SizedBox(height: 16),

        // Title + status
        Row(
          children: [
            Expanded(
              child: Text(a.title,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(a.status.toUpperCase(),
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ],
        ),
        if (a.description != null) ...[
          const SizedBox(height: 8),
          Text(a.description!, style: TextStyle(color: Colors.grey.shade700)),
        ],
        const SizedBox(height: 16),

        // Price card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current bid',
                          style: TextStyle(color: Colors.grey.shade600)),
                      Text(ugx(a.currentPrice),
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: scheme.primary)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Time left',
                          style: TextStyle(color: Colors.grey.shade600)),
                      Text(
                          a.status == 'live'
                              ? timeLeft(a.endTime)
                              : a.status == 'upcoming'
                                  ? 'Starts ${timeAgo(a.startTime)}'
                                  : 'Closed',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Starting price',
                      style: TextStyle(color: Colors.grey.shade600)),
                  Text(ugx(a.startingPrice)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Minimum increment',
                      style: TextStyle(color: Colors.grey.shade600)),
                  Text(ugx(a.minIncrement)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Bid history
        Text('Bid history (${_bids.length})',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        if (_bids.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('No bids yet. Be the first!',
                style: TextStyle(color: Colors.grey.shade600)),
          )
        else
          ..._bids.asMap().entries.map((e) {
            final b = e.value;
            final isMe = b.userId == myId;
            final isTop = e.key == 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isTop ? scheme.primaryContainer : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(isTop ? Icons.emoji_events_rounded : Icons.gavel,
                      size: 20,
                      color: isTop ? scheme.primary : Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ugx(b.amount),
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(isMe ? 'You' : 'Bidder #${b.userId}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  Text(timeAgo(b.placedAt),
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _bidBar(Asset a) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 12)],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _bidCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Min ${ugx(a.minimumBid)}',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 120,
              child: FilledButton(
                onPressed: _submitting ? null : _placeBid,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5))
                    : const Text('Bid'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}