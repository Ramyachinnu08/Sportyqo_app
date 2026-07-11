import 'package:flutter/material.dart';

/// Converters from backend JSON into the `Map<String, dynamic>` shapes the
/// existing screens already render — keeps widget-tree changes minimal.

const _iconByName = <String, IconData>{
  'emoji_events': Icons.emoji_events,
  'trending_up': Icons.trending_up,
  'military_tech': Icons.military_tech,
  'person_add': Icons.person_add,
  'favorite': Icons.favorite,
  'chat_bubble': Icons.chat_bubble,
  'thumb_up': Icons.thumb_up,
  'sports_cricket': Icons.sports_cricket,
  'scoreboard': Icons.scoreboard,
  'group_add': Icons.group_add,
  'verified': Icons.verified,
  'insights': Icons.insights,
  'mail': Icons.mail,
  'notifications': Icons.notifications,
  'people': Icons.people,
  'shield': Icons.shield,
  'star': Icons.star,
};

IconData iconFromName(String? name) =>
    _iconByName[name] ?? Icons.notifications;

Color colorFromHex(String? hex, {Color fallback = const Color(0xFF7B2FFF)}) {
  if (hex == null || hex.isEmpty) return fallback;
  var value = hex.replaceFirst('#', '');
  if (value.length == 6) value = 'FF$value';
  final parsed = int.tryParse(value, radix: 16);
  return parsed == null ? fallback : Color(parsed);
}

/// '2026-07-11T10:58:00Z' → '2m ago' / '3h ago' / '2d ago' / '12 May'
String relativeTime(String? iso) {
  if (iso == null) return '';
  final t = DateTime.tryParse(iso);
  if (t == null) return '';
  final diff = DateTime.now().toUtc().difference(t.toUtc());
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  final local = t.toLocal();
  return '${local.day} ${months[local.month - 1]}';
}

/// API notification → notification-tile map (keeps 'id' for mark-read calls).
Map<String, dynamic> notificationToTile(Map<String, dynamic> n) => {
      'id': n['id'],
      'icon': iconFromName(n['icon'] as String?),
      'color': colorFromHex(n['accent'] as String?),
      'title': n['title'] ?? '',
      'subtitle': n['body'] ?? '',
      'time': relativeTime(n['created_at'] as String?),
      'read': n['read'] == true,
    };
