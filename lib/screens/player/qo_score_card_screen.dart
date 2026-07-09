import 'package:flutter/material.dart';

class QoScoreCardScreen extends StatelessWidget {
  const QoScoreCardScreen({super.key});

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
    const int currentScore = 242;
    final card = _getCurrentCard(currentScore);
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
                          label: 'Rank', value: '#12'),
                      _ScoreStat(
                          label: 'Sport',
                          value: 'Cricket'),
                      _ScoreStat(
                          label: 'This Week',
                          value: '+12'),
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

                      _CardProgress(
                        emoji: '🟣',
                        label: 'Purple Card',
                        level: 'Level 1',
                        points: '1K Points',
                        value: currentScore,
                        max: 1000,
                        color: const Color(0xFF7B2FFF),
                        isActive: currentScore < 1000,
                      ),
                      const SizedBox(height: 12),
                      _CardProgress(
                        emoji: '🟢',
                        label: 'Green Card',
                        level: 'Level 2',
                        points: '2.5K Points',
                        value: currentScore,
                        max: 2500,
                        color: const Color(0xFF00C853),
                        isActive: currentScore >= 1000 &&
                            currentScore < 2500,
                      ),
                      const SizedBox(height: 12),
                      _CardProgress(
                        emoji: '🟡',
                        label: 'Yellow Card',
                        level: 'Level 3',
                        points: '5K Points',
                        value: currentScore,
                        max: 5000,
                        color: const Color(0xFFFFEB3B),
                        isActive: currentScore >= 2500 &&
                            currentScore < 5000,
                      ),
                      const SizedBox(height: 12),
                      _CardProgress(
                        emoji: '🟠',
                        label: 'Orange Card',
                        level: 'Level 4',
                        points: '15K Points',
                        value: currentScore,
                        max: 15000,
                        color: const Color(0xFFFF9800),
                        isActive: currentScore >= 5000 &&
                            currentScore < 15000,
                      ),
                      const SizedBox(height: 12),
                      _CardProgress(
                        emoji: '🔴',
                        label: 'Red Card',
                        level: 'Level 5',
                        points: '30K Points',
                        value: currentScore,
                        max: 30000,
                        color: const Color(0xFFFF3B30),
                        isActive: currentScore >= 15000 &&
                            currentScore < 30000,
                      ),
                      const SizedBox(height: 12),
                      _CardProgress(
                        emoji: '🥉',
                        label: 'Bronze Card',
                        level: 'Bronze Pro',
                        points: '50K Points',
                        value: currentScore,
                        max: 50000,
                        color: const Color(0xFFCD7F32),
                        isActive: currentScore >= 30000 &&
                            currentScore < 50000,
                      ),
                      const SizedBox(height: 12),
                      _CardProgress(
                        emoji: '🥈',
                        label: 'Silver Card',
                        level: 'Silver Pro',
                        points: '75K Points',
                        value: currentScore,
                        max: 75000,
                        color: const Color(0xFF9E9E9E),
                        isActive: currentScore >= 50000 &&
                            currentScore < 75000,
                      ),
                      const SizedBox(height: 12),
                      _CardProgress(
                        emoji: '🥇',
                        label: 'Gold Card',
                        level: 'Golden Pro',
                        points: '1 Lakh Points',
                        value: currentScore,
                        max: 100000,
                        color: const Color(0xFFFFB300),
                        isActive:
                        currentScore >= 75000,
                      ),
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
                      _ScoreBar(
                          label: 'Batting Performance',
                          value: 0.85,
                          score: 85,
                          color: cardColor),
                      const SizedBox(height: 12),
                      _ScoreBar(
                          label: 'Match Consistency',
                          value: 0.72,
                          score: 72,
                          color: cardColor),
                      const SizedBox(height: 12),
                      _ScoreBar(
                          label: 'League Performance',
                          value: 0.68,
                          score: 68,
                          color: cardColor),
                      const SizedBox(height: 12),
                      _ScoreBar(
                          label: 'Team Contribution',
                          value: 0.78,
                          score: 78,
                          color: cardColor),
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
                      const Text('Score History',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                      const SizedBox(height: 16),
                      ...[
                        {
                          'week': 'This Week',
                          'score': '+12',
                          'total': '242',
                          'color':
                          const Color(0xFF00C853)
                        },
                        {
                          'week': 'Last Week',
                          'score': '+8',
                          'total': '230',
                          'color':
                          const Color(0xFF00C853)
                        },
                        {
                          'week': '2 Weeks Ago',
                          'score': '-3',
                          'total': '222',
                          'color': Colors.red
                        },
                        {
                          'week': '3 Weeks Ago',
                          'score': '+15',
                          'total': '225',
                          'color':
                          const Color(0xFF00C853)
                        },
                      ].map((h) => Padding(
                        padding: const EdgeInsets
                            .only(bottom: 12),
                        child: Row(children: [
                          Expanded(
                            child: Text(
                                h['week'] as String,
                                style: const TextStyle(
                                    color:
                                    Colors.white54,
                                    fontSize: 13)),
                          ),
                          Text(h['score'] as String,
                              style: TextStyle(
                                  color: h['color']
                                  as Color,
                                  fontWeight:
                                  FontWeight.w700,
                                  fontSize: 14)),
                          const SizedBox(width: 16),
                          Text(h['total'] as String,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight:
                                  FontWeight.w700,
                                  fontSize: 14)),
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