import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String ugx(num v) => 'UGX ${NumberFormat('#,##0').format(v)}';

/// SQLite returns times without a timezone; treat them as UTC.
DateTime parseUtc(String s) {
  final hasZone = s.endsWith('Z') || RegExp(r'[+-]\d\d:\d\d$').hasMatch(s);
  return DateTime.parse(hasZone ? s : '${s}Z').toLocal();
}

String timeLeft(DateTime end) {
  final d = end.difference(DateTime.now());
  if (d.isNegative) return 'Ended';
  if (d.inDays > 0) return '${d.inDays}d ${d.inHours % 24}h left';
  if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m left';
  return '${d.inMinutes}m ${d.inSeconds % 60}s left';
}

String timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inSeconds < 60) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  return DateFormat('d MMM, HH:mm').format(t);
}

Color statusColor(String status) {
  switch (status) {
    case 'live':
      return const Color(0xFF16A34A);
    case 'upcoming':
      return const Color(0xFFD97706);
    case 'cancelled':
      return const Color(0xFFDC2626);
    default:
      return const Color(0xFF6B7280);
  }
}

// Matches the seeded categories: 1 Vehicles, 2 Real Estate, 3 Equipment.
IconData categoryIcon(int id) {
  switch (id) {
    case 1:
      return Icons.directions_car_rounded;
    case 2:
      return Icons.landscape_rounded;
    case 3:
      return Icons.construction_rounded;
    default:
      return Icons.inventory_2_rounded;
  }
}