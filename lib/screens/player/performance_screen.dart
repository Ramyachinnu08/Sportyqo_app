import 'package:flutter/material.dart';
import '../../api/services.dart';
import '../../theme/app_theme.dart';
import 'qo_score_card_screen.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() =>
      _PerformanceScreenState();
}

class _PerformanceScreenState
    extends State<PerformanceScreen> {
  Map<String, dynamic>? _perf;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _period = 'this_season';
  static const _periodLabels = <String, String>{
    'this_season': 'This Season',
    'last_season': 'Last Season',
    'all_time': 'All Time',
  };

  Future<void> _load() async {
    try {
      final perf =
      await PlayerService.performance(period: _period);
      if (mounted) setState(() => _perf = perf);
    } catch (_) {}
  }

  List<String> get _graphLabels =>
      ((_perf?['journey_graph']?['labels'] as List<dynamic>?) ??
          const [])
          .cast<String>();
  List<num> get _graphValues =>
      ((_perf?['journey_graph']?['values'] as List<dynamic>?) ??
          const [])
          .cast<num>();

  Map<String, dynamic> get _qo =>
      (_perf?['qo_score'] as Map<String, dynamic>?) ?? const {};
  Map<String, dynamic> get _progress =>
      (_perf?['card_progress'] as Map<String, dynamic>?) ?? const {};
  Map<String, dynamic> get _ranking =>
      (_perf?['ranking'] as Map<String, dynamic>?) ?? const {};

  String _tierLabel() {
    final slug = _qo['card_tier'] as String? ?? 'purple';
    final words = slug.split('_').map((w) =>
    w.isEmpty ? w : w[0].toUpperCase() + w.substring(1));
    return '${words.join(' ')} Card';
  }

  /// Real tier color matching the 8 tiers seeded on the server —
  /// Purple → Green → Yellow → Orange → Red → Bronze → Silver → Gold.
  Color _tierColor() {
    final slug = (_qo['card_tier'] as String? ?? 'purple').toLowerCase();
    switch (slug) {
      case 'green':
        return const Color(0xFF00C853);
      case 'yellow':
        return const Color(0xFFFFEB3B);
      case 'orange':
        return const Color(0xFFFF9800);
      case 'red':
        return const Color(0xFFFF3B30);
      case 'bronze':
      case 'bronze_pro':
        return const Color(0xFFCD7F32);
      case 'silver':
      case 'silver_pro':
        return const Color(0xFF9E9E9E);
      case 'gold':
      case 'golden':
      case 'golden_pro':
        return const Color(0xFFFFB300);
      case 'purple':
      default:
        return const Color(0xFF7B2FFF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding:
            const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // ── Qo Score Card ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0F2A),
                    borderRadius: BorderRadius.circular(20),
                    border:
                    Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            const Text('Qo Score',
                                style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 13)),
                            Text('${_qo['current'] ?? 0}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 52,
                                    fontWeight:
                                    FontWeight.w800,
                                    height: 1)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets
                                  .symmetric(
                                  horizontal: 10,
                                  vertical: 4),
                              decoration: BoxDecoration(
                                color: _tierColor()
                                    .withOpacity(0.2),
                                borderRadius:
                                BorderRadius.circular(
                                    20),
                                border: Border.all(
                                    color: _tierColor()
                                        .withOpacity(0.4)),
                              ),
                              child: Row(children: [
                                Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                        color: AppColors
                                            .primary,
                                        shape:
                                        BoxShape.circle)),
                                const SizedBox(width: 6),
                                Text(_tierLabel(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight:
                                        FontWeight.w600)),
                              ]),
                            ),
                            const SizedBox(height: 6),
                            Text((_qo['label'] as String?) ?? '',
                                style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12)),
                            const SizedBox(height: 6),
                            Row(children: [
                              Icon(Icons.arrow_upward,
                                  color: _tierColor(),
                                  size: 14),
                              Text('+${_qo['delta_week'] ?? 0} points this week',
                                  style: TextStyle(
                                      color:
                                      _tierColor(),
                                      fontSize: 12,
                                      fontWeight:
                                      FontWeight.w500)),
                            ]),
                          ],
                        ),
                      ),
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _tierColor()
                              .withOpacity(0.15),
                          border: Border.all(
                              color: _tierColor()
                                  .withOpacity(0.3),
                              width: 2),
                        ),
                        child: Icon(Icons.shield,
                            color: _tierColor(),
                            size: 36),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Card Progress (tap to open the full Qo Score Card) ──
                GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                          const QoScoreCardScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F0F2A),
                      borderRadius: BorderRadius.circular(16),
                      border:
                      Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Row(children: const [
                          Text('Card Progress',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                          Spacer(),
                          Icon(Icons.chevron_right,
                              color: Colors.white38, size: 20),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.primary
                                        .withOpacity(0.4))),
                            child: const Icon(Icons.bolt,
                                color: AppColors.primary,
                                size: 16),
                          ),
                          const SizedBox(width: 10),
                          Text(_tierLabel(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                          const Spacer(),
                          RichText(
                            text: TextSpan(children: [
                              TextSpan(
                                  text: '${_progress['current'] ?? 0}',
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight:
                                      FontWeight.w800,
                                      fontSize: 14)),
                              TextSpan(
                                  text: ' / ${_progress['target'] ?? 1000}',
                                  style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 13)),
                            ]),
                          ),
                        ]),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius:
                          BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                              value: ((_progress['current'] as num?) ?? 0) /
                                  (((_progress['target'] as num?) ?? 1000) == 0
                                      ? 1
                                      : ((_progress['target'] as num?) ?? 1000)),
                              backgroundColor: Colors.white10,
                              color: AppColors.primary,
                              minHeight: 8),
                        ),
                        const SizedBox(height: 8),
                        if (_progress['next_tier'] != null)
                          RichText(
                            text: TextSpan(children: [
                              TextSpan(
                                  text:
                                  '${_progress['points_needed'] ?? 0} points to ',
                                  style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 12)),
                              TextSpan(
                                  text:
                                  '${_progress['next_tier']}',
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight:
                                      FontWeight.w600)),
                            ]),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ── Ranking (MOVED UP) ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0F2A),
                    borderRadius: BorderRadius.circular(16),
                    border:
                    Border.all(color: Colors.white10),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const Text('Ranking',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight:
                                  FontWeight.w700,
                                  fontSize: 14)),
                          const SizedBox(height: 8),
                          Text(
                              _ranking['rank'] == null
                                  ? '—'
                                  : '#${_ranking['rank']}',
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 36,
                                  fontWeight:
                                  FontWeight.w800)),
                          Text((_ranking['category'] as String?) ?? '',
                              style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    Column(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary
                              .withOpacity(0.15),
                          borderRadius:
                          BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.primary
                                  .withOpacity(0.3)),
                        ),
                        child: Text(
                            (_ranking['percentile'] as String?) ?? '—',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                            color: AppColors.primary
                                .withOpacity(0.1),
                            shape: BoxShape.circle),
                        child: const Icon(
                            Icons.people_outline,
                            color: AppColors.primary,
                            size: 26),
                      ),
                      const SizedBox(height: 4),
                      Text(
                          'Out of ${_ranking['total_players'] ?? '—'}',
                          style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 10)),
                      const Text('players',
                          style: TextStyle(
                              color: Colors.white38,
                              fontSize: 10)),
                    ]),
                  ]),
                ),

                const SizedBox(height: 8),

                // ── Qo Journey Graph ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0F2A),
                    borderRadius: BorderRadius.circular(16),
                    border:
                    Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Text('Qo Journey',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        const Spacer(),
                        PopupMenuButton<String>(
                          color: const Color(0xFF15152E),
                          onSelected: (v) {
                            setState(() => _period = v);
                            _load();
                          },
                          itemBuilder: (_) => _periodLabels
                              .entries
                              .map((e) => PopupMenuItem(
                              value: e.key,
                              child: Text(e.value,
                                  style: const TextStyle(
                                      color:
                                      Colors.white))))
                              .toList(),
                          child: Container(
                            padding:
                            const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4),
                            decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius:
                                BorderRadius.circular(
                                    20)),
                            child: Row(
                                mainAxisSize:
                                MainAxisSize.min,
                                children: [
                                  Text(
                                      _periodLabels[
                                      _period]!,
                                      style: const TextStyle(
                                          color: Colors
                                              .white60,
                                          fontSize: 12)),
                                  const Icon(
                                      Icons
                                          .keyboard_arrow_down,
                                      color: Colors.white38,
                                      size: 16),
                                ]),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 140,
                        child: CustomPaint(
                            painter:
                            _PerformanceGraphPainter(
                                values: _graphValues,
                                labels: _graphLabels),
                            size: const Size(
                                double.infinity, 140)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: _graphLabels
                            .map((l) => Text(l,
                            style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 10)))
                            .toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Recent Matches ──
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Recent Matches',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                    Text('View All',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),

                const SizedBox(height: 10),

                if ((_perf?['recent_matches']
                as List<dynamic>?)
                    ?.isEmpty ??
                    true)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                        child: Text('No matches yet',
                            style: TextStyle(
                                color: Colors.white38))),
                  )
                else
                  for (final raw in (_perf!['recent_matches']
                  as List<dynamic>)) ...[
                    Builder(builder: (context) {
                      final m = raw as Map<String, dynamic>;
                      final stats =
                          (m['stats'] as Map<String, dynamic>?) ?? {};
                      final badges =
                          (m['badges'] as List<dynamic>?) ?? [];
                      final won = m['result'] == 'won';
                      return _MatchTile(
                        teamLetter: won ? 'W' : 'L',
                        opponent: 'vs ${m['opponent'] ?? ''}',
                        date: (m['played_at'] as String?) ?? '',
                        stat1: '${stats['runs'] ?? 0} Runs',
                        stat2: '${stats['wickets'] ?? 0} Wkts • ${stats['catches'] ?? 0} Ct',
                        badge: won
                            ? 'Won Match'
                            : (m['result'] == 'draw' ? 'Draw' : 'Lost'),
                        extraBadge:
                        badges.contains('MOM') ? 'MOM ⭐' : null,
                        extraBadgeColor: badges.contains('MOM')
                            ? const Color(0xFFFFB300)
                            : null,
                        points: '+${m['qo_points'] ?? 0}',
                        badgeColor: won
                            ? const Color(0xFF00C853)
                            : (m['result'] == 'draw'
                            ? const Color(0xFF7B2FFF)
                            : Colors.redAccent),
                      );
                    }),
                    const SizedBox(height: 10),
                  ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Match Tile ────────────────────────────────────────────────────────

class _MatchTile extends StatelessWidget {
  final String teamLetter,
      opponent,
      date,
      stat1,
      stat2,
      badge,
      points;
  final Color badgeColor;
  final String? extraBadge;
  final Color? extraBadgeColor;

  const _MatchTile({
    required this.teamLetter,
    required this.opponent,
    required this.date,
    required this.stat1,
    required this.stat2,
    required this.badge,
    required this.points,
    required this.badgeColor,
    this.extraBadge,
    this.extraBadgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F2A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
                color:
                AppColors.primary.withOpacity(0.4)),
          ),
          child: Center(
              child: Text(teamLetter,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16))),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(opponent,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              Text(date,
                  style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11)),
              const SizedBox(height: 4),
              Row(children: [
                if (stat1.isNotEmpty) ...[
                  Text(stat1,
                      style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11)),
                  const SizedBox(width: 8),
                ],
                Text(stat2,
                    style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color:
                      badgeColor.withOpacity(0.2),
                      borderRadius:
                      BorderRadius.circular(20)),
                  child: Text(badge,
                      style: TextStyle(
                          color: badgeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ),
                if (extraBadge != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: extraBadgeColor!
                            .withOpacity(0.2),
                        borderRadius:
                        BorderRadius.circular(20)),
                    child: Text(extraBadge!,
                        style: TextStyle(
                            color: extraBadgeColor,
                            fontSize: 10,
                            fontWeight:
                            FontWeight.w600)),
                  ),
                ],
              ]),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(points,
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
            const Text('Qo Points',
                style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10)),
            const SizedBox(height: 4),
            const Icon(Icons.chevron_right,
                color: Colors.white24, size: 18),
          ],
        ),
      ]),
    );
  }
}

// ── Graph Painter ─────────────────────────────────────────────────────

class _PerformanceGraphPainter extends CustomPainter {
  final List<num> values;
  final List<String> labels;
  _PerformanceGraphPainter(
      {required this.values, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 0.5;
    for (int i = 0; i < 4; i++) {
      final y = size.height * (1 - i / 3);
      canvas.drawLine(
          Offset(0, y), Offset(size.width, y), gridPaint);
    }
    if (values.isEmpty) return;

    // normalise the real cumulative scores into 0–1 canvas space
    final maxV = values
        .fold<num>(0, (a, b) => b > a ? b : a)
        .toDouble();
    final top = maxV <= 0 ? 1.0 : maxV;
    // 0.9 = bottom padding, 0.12 = top padding
    List<double> points = values
        .map((v) => 0.9 - (v.toDouble() / top) * 0.78)
        .toList();
    if (points.length == 1) {
      points = [points.first, points.first];
    }

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withOpacity(0.3),
          AppColors.primary.withOpacity(0.0)
        ],
      ).createShader(
          Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    final fillPath = Path();
    const xOffset = 20.0;
    final usableWidth = size.width - xOffset * 2;

    final xs = <double>[];
    final ys = <double>[];
    for (int i = 0; i < points.length; i++) {
      final x = xOffset +
          i * usableWidth / (points.length - 1);
      final y = points[i] * size.height;
      xs.add(x);
      ys.add(y);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        final cx = (xs[i - 1] + x) / 2;
        path.cubicTo(cx, ys[i - 1], cx, y, x, y);
        fillPath.cubicTo(cx, ys[i - 1], cx, y, x, y);
      }
    }
    fillPath.lineTo(xs.last, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    for (int i = 0; i < xs.length; i++) {
      canvas.drawCircle(
          Offset(xs[i], ys[i]),
          5,
          Paint()
            ..color = AppColors.primary
            ..style = PaintingStyle.fill);
      canvas.drawCircle(
          Offset(xs[i], ys[i]),
          5,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }

    // label the latest real value
    final lastLabel =
    labels.isNotEmpty ? labels.last : '';
    final tp = TextPainter(
      text: TextSpan(children: [
        TextSpan(
            text: '${values.last}\n',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700)),
        TextSpan(
            text: lastLabel,
            style: const TextStyle(
                color: Colors.white38, fontSize: 9)),
      ]),
      textDirection: TextDirection.ltr,
    )..layout();
    final lx =
    (xs.last - 20).clamp(0.0, size.width - tp.width);
    final ly = (ys.last - 36).clamp(0.0, size.height);
    tp.paint(canvas, Offset(lx, ly));
  }

  @override
  bool shouldRepaint(
      covariant _PerformanceGraphPainter old) =>
      old.values != values || old.labels != labels;
}