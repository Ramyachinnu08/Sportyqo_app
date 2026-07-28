import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../api/api_config.dart';
import '../../api/services.dart';
import '../../api/ui_helpers.dart';
import '../../theme/app_theme.dart';

class SelectPlayersScreen extends StatefulWidget {
  final String? leagueId;
  final String? matchId;
  final String? teamAId;
  final String? teamBId;
  final bool completed;
  final String teamName;
  final String matchName;
  const SelectPlayersScreen({
    super.key,
    this.leagueId,
    this.matchId,
    this.teamAId,
    this.teamBId,
    this.completed = false,
    required this.teamName,
    required this.matchName,
  });

  @override
  State<SelectPlayersScreen> createState() =>
      _SelectPlayersScreenState();
}

class _SelectPlayersScreenState
    extends State<SelectPlayersScreen> {
  int _tabIndex = 0;

  List<Map<String, dynamic>> _players = [];
  bool _loading = true;
  bool _submitting = false;

  static final List<Color> _avatarColors = [const Color(0xFF1A3A5C), const Color(0xFF1A5C3A), const Color(0xFF3A1A5C), const Color(0xFF5C3A1A), const Color(0xFF1A5C5C), const Color(0xFF5C1A3A), const Color(0xFF3A5C1A), const Color(0xFF5C5C1A)];

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  /// Returns a network image widget when `url` is a real avatar,
  /// falls back to colored initials otherwise. Used everywhere players
  /// are listed on this screen.
  Widget _buildAvatar(String url, String initials, double fontSize) {
    final resolved = ApiConfig.resolveMediaUrl(url);
    if (resolved != null && resolved.isNotEmpty) {
      return Image.network(
        resolved,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Center(
            child: Text(initials,
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: fontSize))),
      );
    }
    return Center(
        child: Text(initials,
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: fontSize)));
  }

  Future<void> _load() async {
    if (widget.leagueId == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final futures = <Future<List<dynamic>>>[];
      if (widget.teamAId != null) {
        futures.add(LeagueService.players(widget.leagueId!,
            teamId: widget.teamAId));
      }
      if (widget.teamBId != null) {
        futures.add(LeagueService.players(widget.leagueId!,
            teamId: widget.teamBId));
      }
      if (futures.isEmpty) {
        futures.add(LeagueService.players(widget.leagueId!));
      }
      // Also fetch previously-saved scores for this match so we can
      // pre-fill instead of showing 0s ("score vanishes" fix).
      final savedByUserId = <String, Map<String, dynamic>>{};
      if (widget.matchId != null) {
        try {
          final res = await LeagueService.matchParticipants(widget.matchId!);
          for (final it in (res['items'] as List<dynamic>? ?? const [])) {
            final m = it as Map<String, dynamic>;
            savedByUserId[m['user_id'] as String] = m;
          }
        } catch (_) {
          // No saved data yet — that's fine, we'll show 0s as before.
        }
      }
      final lists = await Future.wait(futures);
      final all = lists.expand((l) => l).toList();
      final items = <Map<String, dynamic>>[];
      for (var i = 0; i < all.length; i++) {
        final raw = all[i] as Map<String, dynamic>;
        final userId = raw['id'] as String;
        final prior = savedByUserId[userId];
        items.add(<String, dynamic>{
          'user_id': raw['id'],
          'team_id': raw['team_id'],
          'team_name': raw['team_name'] ?? '',
          'avatar_url': raw['avatar_url'] ?? '',
          'name': raw['name'] ?? '',
          'initials': _initials(raw['name'] as String? ?? ''),
          'role': raw['sub_role'] ?? 'Player',
          'runs': (prior?['runs'] as num?)?.toInt() ?? 0,
          'wkts': (prior?['wickets'] as num?)?.toInt() ?? 0,
          'catches': (prior?['catches'] as num?)?.toInt() ?? 0,
          'is_mom': prior?['is_mom'] == true,
          'is_player_of_match': prior?['is_player_of_match'] == true,
          'is_best_bowler': prior?['is_best_bowler'] == true,
          'is_best_batsman': prior?['is_best_batsman'] == true,
          'is_mvp': prior?['is_mvp'] == true,
          'pts': (prior?['qo_points_awarded'] as num?)?.toDouble() ?? 0.0,
          'color': _avatarColors[i % _avatarColors.length],
        });
      }
      if (!mounted) return;
      // Sort so all players from the same team stay together (Team 1
      // group first, then Team 2 group). This makes the section headers
      // work correctly.
      items.sort((a, b) =>
          (a['team_id'] as String).compareTo(b['team_id'] as String));
      setState(() {
        _players = items;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showApiError(context, e);
      }
    }
  }

  /// Submit match points. The server computes Qo points from the stats and
  /// the result; the Idempotency-Key guarantees no double-award on retry.
  Future<void> _submitPoints() async {
    if (widget.matchId == null) {
      showInfo(context, 'Open this match from the matches list to submit points.');
      return;
    }
    if (widget.completed) {
      showInfo(context, 'Points were already submitted for this match.');
      return;
    }
    final withStats = _players
        .where((p) =>
    (p['runs'] as int) > 0 ||
        (p['wkts'] as int) > 0 ||
        (p['catches'] as int) > 0 ||
        p['is_mom'] == true ||
        p['is_player_of_match'] == true ||
        p['is_best_bowler'] == true ||
        p['is_best_batsman'] == true ||
        p['is_mvp'] == true)
        .toList();
    if (withStats.isEmpty) {
      showInfo(context, 'Edit at least one player\'s stats first.');
      return;
    }

    // pick the result
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Match Result',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
          ),
          ListTile(
              title: Text('${widget.matchName.split(' vs ').first} won',
                  style: const TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx, 'team_a_won')),
          ListTile(
              title: Text('${widget.matchName.split(' vs ').last} won',
                  style: const TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx, 'team_b_won')),
          ListTile(
              title: const Text('Draw',
                  style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx, 'draw')),
          ListTile(
              title: const Text('Abandoned',
                  style: TextStyle(color: Colors.white54)),
              onTap: () => Navigator.pop(ctx, 'abandoned')),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (result == null) return;

    setState(() => _submitting = true);
    final idempotencyKey =
        'sub-${widget.matchId}-${DateTime.now().millisecondsSinceEpoch}';
    try {
      final res = await LeagueService.submitPoints(
        matchId: widget.matchId!,
        result: result,
        idempotencyKey: idempotencyKey,
        playerStats: withStats
            .map((p) => <String, dynamic>{
          'user_id': p['user_id'],
          'runs': p['runs'],
          'wickets': p['wkts'],
          'catches': p['catches'],
          'is_mom': p['is_mom'] == true,
          'is_player_of_match': p['is_player_of_match'] == true,
          'is_best_bowler': p['is_best_bowler'] == true,
          'is_best_batsman': p['is_best_batsman'] == true,
          'is_mvp': p['is_mvp'] == true,
        })
            .toList(),
      );
      if (!mounted) return;
      final awarded =
          res['qo_points_awarded'] as Map<String, dynamic>? ?? {};
      setState(() {
        for (final p in _players) {
          final pts = awarded[p['user_id']];
          if (pts != null) p['pts'] = (pts as num).toDouble();
        }
      });
      showInfo(context,
          'Points submitted — Qo scores updated for ${awarded.length} players ✅');
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'ALREADY_SUBMITTED') {
        showInfo(context, 'Points were already submitted for this match.');
      } else {
        showApiError(context, e);
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A6BFF).withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF1A6BFF).withOpacity(0.4)),
                  ),
                  child: const Center(child: Text('🦅', style: TextStyle(fontSize: 16))),
                ),
                const SizedBox(width: 10),
                Text(widget.matchName ?? widget.teamName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              ]),
            ),

            const SizedBox(height: 12),

            // ── Tabs ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tabIndex = 0),
                    child: Column(children: [
                      Text('Players', style: TextStyle(color: _tabIndex == 0 ? const Color(0xFF1A6BFF) : Colors.white38, fontWeight: _tabIndex == 0 ? FontWeight.w700 : FontWeight.w400, fontSize: 15)),
                      const SizedBox(height: 6),
                      Container(height: 2, color: _tabIndex == 0 ? const Color(0xFF1A6BFF) : Colors.transparent),
                    ]),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tabIndex = 1),
                    child: Column(children: [
                      Text('Team Summary', style: TextStyle(color: _tabIndex == 1 ? const Color(0xFF1A6BFF) : Colors.white38, fontWeight: _tabIndex == 1 ? FontWeight.w700 : FontWeight.w400, fontSize: 15)),
                      const SizedBox(height: 6),
                      Container(height: 2, color: _tabIndex == 1 ? const Color(0xFF1A6BFF) : Colors.transparent),
                    ]),
                  ),
                ),
              ]),
            ),

            Container(height: 1, color: Colors.white10),

            Expanded(
              child: _tabIndex == 0
                  ? _buildPlayersList()
                  : _buildTeamSummary(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayersList() {
    return Column(
      children: [
        // Table Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(children: const [
            Expanded(child: Text('Player', style: TextStyle(color: Colors.white38, fontSize: 12))),
            SizedBox(width: 50, child: Text('Runs', style: TextStyle(color: Colors.white38, fontSize: 12), textAlign: TextAlign.center)),
            SizedBox(width: 50, child: Text('Wkts', style: TextStyle(color: Colors.white38, fontSize: 12), textAlign: TextAlign.center)),
            SizedBox(width: 50, child: Text('Pts', style: TextStyle(color: Colors.white38, fontSize: 12), textAlign: TextAlign.center)),
            SizedBox(width: 50),
          ]),
        ),

        const Divider(color: Colors.white10, height: 1),

        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A6BFF)))
              : _players.isEmpty
              ? const Center(child: Text('No players have joined these teams yet', style: TextStyle(color: Colors.white38)))
              : ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _players.length,
            separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 16),
            itemBuilder: (context, i) {
              final p = _players[i];
              // Show team-name header before the first player of each team
              // so aquil (Team 1) and Sudeep (Team 2) are visually separated.
              final showTeamHeader = i == 0 ||
                  _players[i - 1]['team_id'] != p['team_id'];
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showTeamHeader && (p['team_name'] as String?)?.isNotEmpty == true)
                      Padding(
                        padding: EdgeInsets.only(bottom: 8, top: i == 0 ? 0 : 6),
                        child: Row(children: [
                          Container(
                            width: 4, height: 14,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A6BFF),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            (p['team_name'] as String?) ?? '',
                            style: const TextStyle(
                                color: Color(0xFF1A6BFF),
                                fontSize: 13,
                                fontWeight: FontWeight.w800),
                          ),
                        ]),
                      ),
                    Row(children: [
                      // Avatar (photo if available, else colored initials)
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: (p['color'] as Color).withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: _buildAvatar(
                              p['avatar_url'] as String? ?? '',
                              p['initials'] as String, 13),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Name + role
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p['name'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                            Text(p['role'] as String, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                          ],
                        ),
                      ),
                      // Runs
                      SizedBox(width: 50, child: Text('${p['runs']}', style: const TextStyle(color: Colors.white, fontSize: 13), textAlign: TextAlign.center)),
                      // Wkts
                      SizedBox(width: 50, child: Text('${p['wkts']}', style: const TextStyle(color: Colors.white, fontSize: 13), textAlign: TextAlign.center)),
                      // Pts (live-calculated from current stats)
                      SizedBox(width: 50, child: Text('${_effPts(p).toInt()}', style: const TextStyle(color: Colors.white, fontSize: 13), textAlign: TextAlign.center)),
                      // Edit button
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _EditPlayerStatsScreen(player: p, onSave: (updated) {
                          setState(() => _players[i] = updated);
                          // Auto-save to backend so scores persist across visits.
                          // Fire-and-forget — the UI already reflects the change.
                          final mid = widget.matchId;
                          if (mid != null && !widget.completed) {
                            LeagueService.draftPoints(matchId: mid, playerStats: [
                              {
                                'user_id': updated['user_id'],
                                'runs': updated['runs'] ?? 0,
                                'balls': updated['balls'] ?? 0,
                                'fours': updated['fours'] ?? 0,
                                'sixes': updated['sixes'] ?? 0,
                                'wickets': updated['wkts'] ?? 0,
                                'catches': updated['catches'] ?? 0,
                                'is_mom': updated['is_mom'] == true,
                                'is_player_of_match': updated['is_player_of_match'] == true,
                                'is_best_bowler': updated['is_best_bowler'] == true,
                                'is_best_batsman': updated['is_best_batsman'] == true,
                                'is_mvp': updated['is_mvp'] == true,
                              }
                            ]).catchError((e) {
                              if (mounted) showApiError(context, e);
                              return <String, dynamic>{};
                            });
                          }
                        }))),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A6BFF).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF1A6BFF).withOpacity(0.3)),
                          ),
                          child: const Text('Edit', style: TextStyle(color: Color(0xFF1A6BFF), fontWeight: FontWeight.w700, fontSize: 12)),
                        ),
                      ),
                    ]),
                  ]);
            },
          ),
        ),
      ],
    );
  }

  /// Official Qo Points calculation (participation + strike rate removed
  /// per owner request). Batting rewards runs, boundaries, and milestone
  /// bonuses; bowling rewards wickets with milestone bonuses; fielding
  /// rewards assists.
  double _calcPtsFor(Map<String, dynamic> p) {
    final r = p['runs'] as int;
    final fours = p['fours'] as int? ?? 0;
    final sixes = p['sixes'] as int? ?? 0;
    final w = p['wkts'] as int;
    final c = p['catches'] as int? ?? 0;
    final ro = p['run_outs'] as int? ?? 0;

    // ── BATTING ──
    // Every run scored — 0.5 pts per run.
    double pts = r * 0.5;
    // Milestone bonuses — not cumulative (only the higher one applies).
    if (r >= 50) {
      pts += 15;
    } else if (r >= 30) {
      pts += 10;
    }
    // Boundary bonuses.
    pts += fours * 2;
    pts += sixes * 4;

    // ── BOWLING ──
    // Every wicket — 15 pts each.
    pts += w * 15;
    // Milestone bonuses — take the highest tier only.
    if (w >= 5) {
      pts += 20;
    } else if (w >= 3) {
      pts += 10;
    } else if (w >= 2) {
      pts += 5;
    }

    // ── FIELDING ──
    // Every assist (catch, run-out, stumping) — 5 pts each.
    pts += (c + ro) * 5;

    // ── TEAM / MATCH BONUSES ──
    if (p['is_mom'] == true) pts += 20;
    if (p['is_best_batsman'] == true) pts += 20;
    if (p['is_best_bowler'] == true) pts += 20;
    if (p['is_player_of_match'] == true) pts += 50;
    if (p['is_mvp'] == true) pts += 100;

    return pts;
  }

  double _effPts(Map<String, dynamic> p) {
    final stored = p['pts'] as double;
    return stored > 0 ? stored : _calcPtsFor(p);
  }

  Widget _buildTeamSummary() {
    final totalRuns = _players.fold<int>(0, (sum, p) => sum + (p['runs'] as int));
    final totalWkts = _players.fold<int>(0, (sum, p) => sum + (p['wkts'] as int));
    final totalPts = _players.fold<double>(0, (sum, p) => sum + _effPts(p));
    // Build a list with effective points so sort + display show correct values.
    final withPts = _players
        .map((p) => <String, dynamic>{...p, '__eff_pts': _effPts(p)})
        .toList();
    final sorted = List<Map<String, dynamic>>.from(withPts)
      ..sort((a, b) =>
          (b['__eff_pts'] as double).compareTo(a['__eff_pts'] as double));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Score card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Total Runs', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  Text('$totalRuns/$totalWkts', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  Text('$totalWkts Wickets', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                ]),
                Container(height: 50, width: 1, color: Colors.white10),
                Column(children: [
                  const Text('Total Qo Points', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  Text(totalPts.toStringAsFixed(1), style: const TextStyle(color: Color(0xFF1A6BFF), fontSize: 22, fontWeight: FontWeight.w800)),
                ]),
                Container(height: 50, width: 1, color: Colors.white10),
                Column(children: [
                  const Text('Result', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  const Text('–', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                ]),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Top Performers
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Top Performers', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 12),
                Row(children: const [
                  SizedBox(width: 30),
                  Text('Player', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  Spacer(),
                  Text('Qo Points', style: TextStyle(color: Colors.white38, fontSize: 12)),
                ]),
                const SizedBox(height: 8),
                ...sorted.take(3).toList().asMap().entries.map((entry) {
                  final i = entry.key;
                  final p = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      SizedBox(width: 30, child: Text('${i + 1}', style: const TextStyle(color: Colors.white38, fontSize: 13))),
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(color: (p['color'] as Color).withOpacity(0.6), shape: BoxShape.circle),
                        child: ClipOval(
                          child: _buildAvatar(
                              p['avatar_url'] as String? ?? '',
                              p['initials'] as String, 11),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(p['name'] as String, style: const TextStyle(color: Colors.white, fontSize: 13))),
                      Text('${(p['__eff_pts'] as double).toInt()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                    ]),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submitPoints,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A6BFF),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _submitting
                  ? const ButtonSpinner()
                  : const Text('Submit Points', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF1A6BFF)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Mark as Completed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A6BFF))),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Edit Player Stats Screen ──────────────────────────────────────────

class _EditPlayerStatsScreen extends StatefulWidget {
  final Map<String, dynamic> player;
  final Function(Map<String, dynamic>) onSave;
  const _EditPlayerStatsScreen({required this.player, required this.onSave});

  @override
  State<_EditPlayerStatsScreen> createState() => _EditPlayerStatsScreenState();
}

class _EditPlayerStatsScreenState extends State<_EditPlayerStatsScreen> {
  late int _runs;
  late int _fours;
  late int _sixes;
  late int _balls;
  late int _wickets;
  late int _catches;
  late int _runOuts;
  late bool _isMom;
  late bool _isPlayerOfMatch;
  late bool _isBestBowler;
  late bool _isBestBatsman;
  late bool _isMvp;

  @override
  void initState() {
    super.initState();
    _runs = widget.player['runs'] as int;
    _fours = 0;
    _sixes = 0;
    _balls = (widget.player['balls'] as int?) ?? 0;
    _wickets = widget.player['wkts'] as int;
    _catches = (widget.player['catches'] as int?) ?? 0;
    _runOuts = 0;
    _isMom = widget.player['is_mom'] == true;
    _isPlayerOfMatch = widget.player['is_player_of_match'] == true;
    _isBestBowler = widget.player['is_best_bowler'] == true;
    _isBestBatsman = widget.player['is_best_batsman'] == true;
    _isMvp = widget.player['is_mvp'] == true;
  }

  /// Preview using the official SportyQo Qo Points chart. The server
  /// recomputes the final number on submit — this is display only.
  double _calculatePts() {
    // ── BATTING ──
    double pts = _runs * 0.5; // Every run scored
    if (_runs >= 50) {
      pts += 15; // 50+ Runs Bonus
    } else if (_runs >= 30) {
      pts += 10; // 30-49 Runs Bonus
    }
    pts += _fours * 2;
    pts += _sixes * 4;

    // ── BOWLING ──
    pts += _wickets * 15;
    if (_wickets >= 5) {
      pts += 20;
    } else if (_wickets >= 3) {
      pts += 10;
    } else if (_wickets >= 2) {
      pts += 5;
    }

    // ── FIELDING ──
    pts += (_catches + _runOuts) * 5;

    // ── BONUSES ──
    if (_isMom) pts += 20;
    if (_isBestBatsman) pts += 20;
    if (_isBestBowler) pts += 20;
    if (_isPlayerOfMatch) pts += 50;
    if (_isMvp) pts += 100;
    return pts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                const Text('Edit Player Stats', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              ]),
            ),

            const SizedBox(height: 16),

            // Player info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: (widget.player['color'] as Color).withOpacity(0.6), shape: BoxShape.circle),
                  child: Center(child: Text(widget.player['initials'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16))),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.player['name'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                    Text(widget.player['role'] as String, style: const TextStyle(color: Colors.white38, fontSize: 13)),
                  ],
                ),
              ]),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Batting
                      const Text('Batting', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 6),
                      const Text('Runs already includes all boundary runs. 4s and 6s are extra info.',
                          style: TextStyle(color: Colors.white54, fontSize: 11)),
                      const SizedBox(height: 12),
                      _StatRow(label: 'Runs Scored', value: _runs, max: 999,
                          helpText: 'Total runs scored by the batter, including boundaries (4s and 6s). Each run = +0.5 pts. Bonuses: 30-49 runs = +10 pts, 50+ runs = +15 pts (not cumulative).',
                          onDec: () => setState(() => _runs = (_runs - 1).clamp(0, 999)),
                          onInc: () => setState(() => _runs = (_runs + 1).clamp(0, 999)),
                          onSet: (v) => setState(() => _runs = v.clamp(0, 999))),
                      _StatRow(label: '4s', value: _fours, max: 99,
                          helpText: 'Number of boundary 4s scored. Each 4 = +2 pts bonus (in addition to the 4 runs already counted).',
                          onDec: () => setState(() => _fours = (_fours - 1).clamp(0, 99)),
                          onInc: () => setState(() => _fours = (_fours + 1).clamp(0, 99)),
                          onSet: (v) => setState(() => _fours = v.clamp(0, 99))),
                      _StatRow(label: '6s', value: _sixes, max: 99,
                          helpText: 'Number of sixes hit. Each 6 = +4 pts bonus (in addition to the 6 runs already counted).',
                          onDec: () => setState(() => _sixes = (_sixes - 1).clamp(0, 99)),
                          onInc: () => setState(() => _sixes = (_sixes + 1).clamp(0, 99)),
                          onSet: (v) => setState(() => _sixes = v.clamp(0, 99))),
                      _StatRow(label: 'Balls Faced', value: _balls, max: 999,
                          helpText: 'Total balls faced by the batter. For your records only — does not affect Qo Points.',
                          onDec: () => setState(() => _balls = (_balls - 1).clamp(0, 999)),
                          onInc: () => setState(() => _balls = (_balls + 1).clamp(0, 999)),
                          onSet: (v) => setState(() => _balls = v.clamp(0, 999))),

                      const SizedBox(height: 16),
                      // Bowling
                      const Text('Bowling', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 12),
                      _StatRow(label: 'Wickets Taken', value: _wickets, max: 10,
                          helpText: 'Wickets taken by the bowler. Every wicket = +15 pts. Milestone bonuses: 2 wkts = +5, 3 wkts = +10, 5 wkts = +20 (highest tier only, not cumulative).',
                          onDec: () => setState(() => _wickets = (_wickets - 1).clamp(0, 10)),
                          onInc: () => setState(() => _wickets = (_wickets + 1).clamp(0, 10)),
                          onSet: (v) => setState(() => _wickets = v.clamp(0, 10))),

                      const SizedBox(height: 16),
                      // Fielding
                      const Text('Fielding', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 12),
                      _StatRow(label: 'Catches', value: _catches, max: 10,
                          helpText: 'Catches taken while fielding. Each catch = +5 pts.',
                          onDec: () => setState(() => _catches = (_catches - 1).clamp(0, 10)),
                          onInc: () => setState(() => _catches = (_catches + 1).clamp(0, 10)),
                          onSet: (v) => setState(() => _catches = v.clamp(0, 10))),
                      _StatRow(label: 'Run Outs / Assists', value: _runOuts, max: 10,
                          helpText: 'Run outs and stumpings the fielder executed or assisted in. Each = +5 pts.',
                          onDec: () => setState(() => _runOuts = (_runOuts - 1).clamp(0, 10)),
                          onInc: () => setState(() => _runOuts = (_runOuts + 1).clamp(0, 10)),
                          onSet: (v) => setState(() => _runOuts = v.clamp(0, 10))),

                      const SizedBox(height: 16),
                      // Achievement Awards (official SportyQo card)
                      const Text('Achievement Awards', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 8),
                      _AwardCheck(
                          label: 'Man of the Match  (+20)',
                          value: _isMom,
                          onChanged: (v) => setState(() => _isMom = v)),
                      _AwardCheck(
                          label: 'Best Bowler  (+20)',
                          value: _isBestBowler,
                          onChanged: (v) =>
                              setState(() => _isBestBowler = v)),
                      _AwardCheck(
                          label: 'Best Batsman  (+20)',
                          value: _isBestBatsman,
                          onChanged: (v) =>
                              setState(() => _isBestBatsman = v)),
                      _AwardCheck(
                          label: 'MVP Performance  (+25)',
                          value: _isMvp,
                          onChanged: (v) => setState(() => _isMvp = v)),
                    ],
                  ),
                ),
              ),
            ),

            // Save button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final updated = Map<String, dynamic>.from(widget.player);
                    updated['runs'] = _runs;
                    updated['balls'] = _balls;
                    updated['fours'] = _fours;
                    updated['sixes'] = _sixes;
                    updated['wkts'] = _wickets;
                    updated['catches'] = _catches;
                    updated['run_outs'] = _runOuts;
                    updated['is_mom'] = _isMom;
                    updated['is_player_of_match'] = _isPlayerOfMatch;
                    updated['is_best_bowler'] = _isBestBowler;
                    updated['is_best_batsman'] = _isBestBatsman;
                    updated['is_mvp'] = _isMvp;
                    updated['pts'] = _calculatePts();
                    widget.onSave(updated);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _StatsUpdatedScreen(
                          playerName: widget.player['name'] as String,
                          runs: _runs,
                          fours: _fours,
                          sixes: _sixes,
                          catches: _catches,
                          wickets: _wickets,
                          totalPts: _calculatePts(),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A6BFF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Save & Update', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final VoidCallback onDec, onInc;
  final ValueChanged<int> onSet;
  final String? helpText;
  const _StatRow({
    required this.label,
    required this.value,
    required this.onDec,
    required this.onInc,
    required this.onSet,
    this.max = 999,
    this.helpText,
  });

  Future<void> _showHelp(BuildContext context) async {
    if (helpText == null) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        title: Row(children: [
          const Icon(Icons.help_outline,
              color: Color(0xFF1A6BFF), size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 16))),
        ]),
        content: Text(helpText!,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Got it',
                  style: TextStyle(
                      color: Color(0xFF1A6BFF),
                      fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  Future<void> _promptForValue(BuildContext context) async {
    final ctrl = TextEditingController(text: '$value');
    final entered = await showDialog<int>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        title: Text(label,
            style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            hintText: '0',
            hintStyle:
            const TextStyle(color: Colors.white24),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white54))),
          TextButton(
              onPressed: () {
                final n = int.tryParse(ctrl.text.trim());
                if (n == null) return;
                Navigator.pop(dialogCtx, n.clamp(0, max));
              },
              child: const Text('Save',
                  style: TextStyle(
                      color: Color(0xFF1A6BFF),
                      fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (entered != null) onSet(entered);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Expanded(
            child: Row(children: [
              Flexible(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 13))),
              if (helpText != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _showHelp(context),
                  child: const Icon(Icons.help_outline,
                      color: Colors.white38, size: 15),
                ),
              ],
            ])),
        GestureDetector(
          onTap: onDec,
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.remove, color: Colors.white60, size: 16),
          ),
        ),
        // Tap the number to type it directly — much faster for scores like 87.
        GestureDetector(
          onTap: () => _promptForValue(context),
          child: Container(
            width: 56,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: const Color(0xFF1A6BFF)
                        .withOpacity(0.5),
                    width: 1),
              ),
            ),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$value',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                  const SizedBox(width: 4),
                  const Icon(Icons.edit,
                      color: Color(0xFF1A6BFF), size: 12),
                ]),
          ),
        ),
        GestureDetector(
          onTap: onInc,
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: const Color(0xFF1A6BFF).withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF1A6BFF).withOpacity(0.4))),
            child: const Icon(Icons.add, color: Color(0xFF1A6BFF), size: 16),
          ),
        ),
      ]),
    );
  }
}

// ── Stats Updated Screen ──────────────────────────────────────────────

class _StatsUpdatedScreen extends StatelessWidget {
  final String playerName;
  final int runs, fours, sixes, catches, wickets;
  final double totalPts;

  const _StatsUpdatedScreen({
    required this.playerName,
    required this.runs,
    required this.fours,
    required this.sixes,
    required this.catches,
    required this.wickets,
    required this.totalPts,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text('$playerName Updated', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              ]),
            ),

            const Spacer(),

            // Success animation
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [const Color(0xFF00C853).withOpacity(0.3), Colors.transparent]),
                  ),
                ),
                Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF00C853), width: 3),
                    color: const Color(0xFF00C853).withOpacity(0.1),
                  ),
                  child: const Icon(Icons.check, color: Color(0xFF00C853), size: 50),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text('Stats updated successfully!', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Qo Points generated', style: TextStyle(color: Colors.white38, fontSize: 13)),

            const SizedBox(height: 28),

            // Stats row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatDisplay(label: 'Runs', value: '$runs'),
                    _StatDisplay(label: '4s', value: '$fours'),
                    _StatDisplay(label: '6s', value: '$sixes'),
                    _StatDisplay(label: 'Catches', value: '$catches'),
                    _StatDisplay(label: 'Wickets', value: '$wickets'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Total Qo Points
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(children: [
                  const Text('Total Qo Points', style: TextStyle(color: Colors.white60, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text('$totalPts', style: const TextStyle(color: Color(0xFF00C853), fontSize: 36, fontWeight: FontWeight.w800)),
                ]),
              ),
            ),

            const Spacer(),

            // Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A6BFF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('View Player', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('Back to Team', style: TextStyle(color: Color(0xFF1A6BFF), fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatDisplay extends StatelessWidget {
  final String label, value;
  const _StatDisplay({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
    ]);
  }
}
// ── Award checkbox row ────────────────────────────────────────────────
class _AwardCheck extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _AwardCheck(
      {required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: Row(children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: value ? const Color(0xFF1A6BFF) : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF1A6BFF)),
            ),
            child: value
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : null,
          ),
          const SizedBox(width: 10),
          Text(label,
              style:
              const TextStyle(color: Colors.white70, fontSize: 13)),
        ]),
      ),
    );
  }
}