import 'package:flutter/material.dart';
import '../../api/mappers.dart';
import '../../api/services.dart';
import '../../api/ui_helpers.dart';

class QoScoreCardScreen extends StatefulWidget {
  const QoScoreCardScreen({super.key});

  @override
  State<QoScoreCardScreen> createState() => _QoScoreCardScreenState();
}

class _QoScoreCardScreenState extends State<QoScoreCardScreen> {
  Map<String, dynamic>? _data; // GET /players/me/qo-score
  List<dynamic> _tiers = []; // GET /config/card-tiers (server-owned)

  static const Map<String, String> _tierEmoji = {
    'purple': '🟣', 'green': '🟢', 'yellow': '🟡', 'orange': '🟠',
    'red': '🔴', 'bronze_pro': '🥉', 'silver_pro': '🥈', 'golden_pro': '🥇',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        PlayerService.qoScore(),
        ConfigService.cardTiers(),
      ]);
      if (!mounted) return;
      setState(() {
        _data = results[0] as Map<String, dynamic>;
        _tiers = results[1] as List<dynamic>;
      });
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  Color _hex(String? hex, Color fallback) =>
      hex == null ? fallback : colorFromHex(hex, fallback: fallback);

  String _fmtPoints(int n) {
    if (n >= 100000) return '${n ~/ 100000} Lakh Points';
    if (n >= 1000) {
      final k = n / 1000;
      return '${k == k.roundToDouble() ? k.toInt() : k} K Points';
    }
    return '$n Points';
  }

  // ── Get current card based on score ──
  Map<String, dynamic> _getCurrentCard(int score) {
    if (score >= 100000) {
      return {
        'emoji': '🥇',
        'label': 'Gold Card',
        'level': 'Golden Pro',
        'color': const Color(0xFFFFB300),
      };
    } else if (score >= 75000) {
      return {
        'emoji': '🥈',
        'label': 'Silver Card',
        'level': 'Silver Pro',
        'color': const Color(0xFF9E9E9E),
      };
    } else if (score >= 50000) {
      return {
        'emoji': '🥉',
        'label': 'Bronze Card',
        'level': 'Bronze Pro',
        'color': const Color(0xFFCD7F32),
      };
    } else if (score >= 30000) {
      return {
        'emoji': '🔴',
        'label': 'Red Card',
        'level': 'Level 5',
        'color': const Color(0xFFFF3B30),
      };
    } else if (score >= 15000) {
      return {
        'emoji': '🟠',
        'label': 'Orange Card',
        'level': 'Level 4',
        'color': const Color(0xFFFF9800),
      };
    } else if (score >= 5000) {
      return {
        'emoji': '🟡',
        'label': 'Yellow Card',
        'level': 'Level 3',
        'color': const Color(0xFFFFEB3B),
      };
    } else if (score >= 2500) {
      return {
        'emoji': '🟢',
        'label': 'Green Card',
        'level': 'Level 2',
        'color': const Color(0xFF00C853),
      };
    } else {
      return {
        'emoji': '🟣',
        'label': 'Purple Card',
        'level': 'Level 1',
        'color': const Color(0xFF7B2FFF),
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final int currentScore = (_data?['score'] as int?) ?? 0;
    final serverCard = _data?['card'] as Map<String, dynamic>?;
    final card = _getCurrentCard(currentScore);
    if (serverCard != null) {
      card['label'] = serverCard['label'] ?? card['label'];
      card['level'] = 'Level ${serverCard['level'] ?? ''}';
      card['emoji'] =
          _tierEmoji[serverCard['tier']] ?? card['emoji'];
      card['color'] =
          _hex(serverCard['hex'] as String?, card['color'] as Color);
    }
    final Color cardColor = card['color'] as Color;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Header ──
              Padding(
                padding:
                const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('Qo Score Card',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                ]),
              ),

              const SizedBox(height: 24),

              // ── Score Display with card theme ──
              Container(
                margin: const EdgeInsets.symmetric(
                    horizontal: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cardColor,
                      cardColor.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: cardColor.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(children: [
                  // ── Card badge ──
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius:
                      BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(card['emoji'],
                            style: const TextStyle(
                                fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          '${card['label']} • ${card['level']}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text('Your Qo Score',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14)),
                  const SizedBox(height: 8),
                  const Text('242',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 72,
                          fontWeight: FontWeight.w900,
                          height: 1.1)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius:
                      BorderRadius.circular(20),
                    ),
                    child: const Text('Top 15% Players',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceAround,
                    children: [
                      _ScoreStat(
                          label: 'Level',
                          value:
                          '${serverCard?['level'] ?? 1}'),
                      _ScoreStat(
                          label: 'Next Card',
                          value: (serverCard?['next_tier']
                          ?['label'] as String?) ??
                              'Max'),
                      _ScoreStat(
                          label: 'Points Needed',
                          value:
                          '${serverCard?['next_tier']?['points_needed'] ?? 0}'),
                    ],
                  ),
                ]),
              ),

              const SizedBox(height: 20),

              // ── Card Levels ──
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: cardColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(card['emoji'],
                            style: const TextStyle(
                                fontSize: 20)),
                        const SizedBox(width: 8),
                        const Text('Card Levels',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16)),
                      ]),
                      const SizedBox(height: 4),
                      const Text(
                          'Earn points to unlock higher cards',
                          style: TextStyle(
                              color: Colors.white38,
                              fontSize: 12)),
                      const SizedBox(height: 16),

                      if (_tiers.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFF7B2FFF))),
                        )
                      else
                        for (var i = 0; i < _tiers.length; i++) ...[
                          if (i > 0) const SizedBox(height: 12),
                          _CardProgress(
                            emoji: _tierEmoji[
                            (_tiers[i] as Map)['tier']] ??
                                '🏏',
                            label: (_tiers[i]
                            as Map)['label'] as String,
                            level:
                            'Level ${(_tiers[i] as Map)['level']}',
                            points: _fmtPoints((_tiers[i]
                            as Map)['threshold'] as int),
                            value: currentScore,
                            max: (_tiers[i]
                            as Map)['threshold'] as int,
                            color: _hex(
                                (_tiers[i] as Map)['hex'] as String?,
                                const Color(0xFF7B2FFF)),
                            isActive: (serverCard?['level'] ??
                                0) ==
                                (_tiers[i] as Map)['level'],
                          ),
                        ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Score Breakdown ──
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(16),
                    border:
                    Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const Text('Score Breakdown',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                      const SizedBox(height: 16),
                      for (final raw
                      in (_data?['breakdown'] as List<dynamic>? ??
                          const [])) ...[
                        _ScoreBar(
                            label: (raw as Map)['category'] as String,
                            value: ((raw['max'] as num) == 0)
                                ? 0
                                : ((raw['points'] as num) /
                                (raw['max'] as num))
                                .clamp(0.0, 1.0)
                                .toDouble(),
                            score: (raw['points'] as num).toInt(),
                            color: cardColor),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Score History ──
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(16),
                    border:
                    Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const Text('Improve Your Score',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                      const SizedBox(height: 16),
                      ...((_data?['improve_tips']
                      as List<dynamic>?) ??
                          const [])
                          .map((tip) => Padding(
                        padding: const EdgeInsets
                            .only(bottom: 12),
                        child: Row(children: [
                          Icon(Icons.bolt,
                              color: cardColor, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(tip as String,
                                style: const TextStyle(
                                    color:
                                    Colors.white70,
                                    fontSize: 13)),
                          ),
                        ]),
                      )),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── How to improve ──
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color:
                        cardColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.lightbulb_outline,
                            color: cardColor, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                            'How to improve your score',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight:
                                FontWeight.w700,
                                fontSize: 14)),
                      ]),
                      const SizedBox(height: 12),
                      ...[
                        '🏏 Play more matches in your leagues',
                        '📊 Maintain consistent batting average',
                        '🏆 Join and perform in tournaments',
                        '👥 Contribute to team wins',
                      ].map((tip) => Padding(
                        padding: const EdgeInsets
                            .only(bottom: 8),
                        child: Text(tip,
                            style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                                height: 1.4)),
                      )),
                    ],
                  ),
                ),
              ),


              const SizedBox(height: 16),

              // ── How Qo Points Work ──
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius:
                    BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.menu_book_outlined,
                            color: cardColor, size: 20),
                        const SizedBox(width: 8),
                        const Text('How Qo Points Work',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight:
                                FontWeight.w700,
                                fontSize: 14)),
                      ]),
                      const SizedBox(height: 4),
                      const Text(
                          'Official SportyQo scoring structure',
                          style: TextStyle(
                              color: Colors.white38,
                              fontSize: 11)),
                      const SizedBox(height: 14),
                      _PointsGroup(
                          color: cardColor,
                          title: '🎁 Getting Started',
                          rows: const [
                            ['Welcome bonus on joining', '+50'],
                          ]),
                      _PointsGroup(
                          color: cardColor,
                          title: '📤 Uploads',
                          rows: const [
                            ['Photo post', '+1'],
                            ['Video post', '+2'],
                            ['Certificate', '+5'],
                          ]),
                      _PointsGroup(
                          color: cardColor,
                          title: '🏏 Batting (per match)',
                          rows: const [
                            ['0 – 10 runs', '+5'],
                            ['11 – 25 runs', '+8'],
                            ['26 – 45 runs', '+12'],
                            ['46 – 99 runs', '+20'],
                            ['100+ runs', '+50'],
                          ]),
                      _PointsGroup(
                          color: cardColor,
                          title: '🎯 Bowling',
                          rows: const [
                            ['1 – 2 wickets', '+5'],
                            ['3+ wickets', '+20'],
                          ]),
                      _PointsGroup(
                          color: cardColor,
                          title: '🧤 Fielding',
                          rows: const [
                            ['2 catches / assists', '+2'],
                            ['3+ catches / assists', '+5'],
                          ]),
                      _PointsGroup(
                          color: cardColor,
                          title: '🏅 Achievement Bonuses',
                          rows: const [
                            ['Player of the Match', '+20'],
                            ['Man of the Match', '+20'],
                            ['Best Bowler', '+20'],
                            ['Best Batsman', '+20'],
                            ['MVP Performance', '+25'],
                          ]),
                      _PointsGroup(
                          color: cardColor,
                          title: '🏆 Team Achievements',
                          rows: const [
                            ['Match win (team bonus)', '+20'],
                            ['Tournament Finalist', '+50'],
                            ['Championship Runner Up', '+50'],
                            ['Championship Winner', '+100'],
                          ]),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────

class _CardProgress extends StatelessWidget {
  final String emoji, label, level, points;
  final int value, max;
  final Color color;
  final bool isActive;

  const _CardProgress({
    required this.emoji,
    required this.label,
    required this.level,
    required this.points,
    required this.value,
    required this.max,
    required this.color,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (value / max).clamp(0.0, 1.0);
    final percent =
    (progress * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive
            ? color.withOpacity(0.08)
            : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? color.withOpacity(0.4)
              : Colors.white10,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(emoji,
                style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(label,
                        style: TextStyle(
                            color: isActive
                                ? Colors.white
                                : Colors.white54,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    const SizedBox(width: 8),
                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius:
                        BorderRadius.circular(20),
                      ),
                      child: Text(level,
                          style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight:
                              FontWeight.w700)),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding:
                        const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius:
                          BorderRadius.circular(20),
                        ),
                        child: const Text('Active',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight:
                                FontWeight.w700)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 2),
                  Text(points,
                      style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11)),
                ],
              ),
            ),
            Text('$percent%',
                style: TextStyle(
                    color: isActive
                        ? color
                        : Colors.white38,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white10,
              valueColor:
              AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [
              Text('$value pts',
                  style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 10)),
              Text('$max pts',
                  style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreStat extends StatelessWidget {
  final String label, value;
  const _ScoreStat(
      {required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800)),
      Text(label,
          style: const TextStyle(
              color: Colors.white70, fontSize: 11)),
    ]);
  }
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final double value;
  final int score;
  final Color color;
  const _ScoreBar(
      {required this.label,
        required this.value,
        required this.score,
        required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12))),
          Text('$score/100',
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.white10,
            valueColor:
            AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}


class _PointsGroup extends StatelessWidget {
  final String title;
  final List<List<String>> rows;
  final Color color;
  const _PointsGroup(
      {required this.title,
        required this.rows,
        required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5)),
          const SizedBox(height: 6),
          ...rows.map((r) => Padding(
            padding:
            const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              Expanded(
                child: Text(r[0],
                    style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12.5)),
              ),
              Text(r[1],
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5)),
            ]),
          )),
        ],
      ),
    );
  }
}