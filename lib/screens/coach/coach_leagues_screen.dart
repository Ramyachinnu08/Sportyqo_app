import 'package:flutter/material.dart';
import '../../api/services.dart';
import '../../api/ui_helpers.dart';
import '../../theme/app_theme.dart';
import 'select_match_screen.dart';

class CoachLeaguesScreen extends StatefulWidget {
  const CoachLeaguesScreen({super.key});

  @override
  State<CoachLeaguesScreen> createState() => _CoachLeaguesScreenState();
}

class _CoachLeaguesScreenState extends State<CoachLeaguesScreen> {
  Map<String, dynamic>? _league; // most recent league
  Map<String, dynamic>? _detail; // GET /leagues/{id}
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final leagues = await LeagueService.myLeagues();
      if (leagues.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final league = leagues.first as Map<String, dynamic>;
      final detail = await LeagueService.detail(league['id'] as String);
      if (!mounted) return;
      setState(() {
        _league = league;
        _detail = detail;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showApiError(context, e);
      }
    }
  }

  int get _playersCount => (_league?['players_count'] as int?) ?? 0;
  int get _teamsCount =>
      ((_detail?['teams'] as List<dynamic>?) ?? const []).length;
  int get _matchesCount =>
      (_detail?['stats']?['matches'] as int?) ?? 0;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(
            child: CircularProgressIndicator(color: Color(0xFF1A6BFF))),
      );
    }
    if (_league == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                const Text('View League',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
              ]),
            ),
            const Expanded(
              child: Center(
                child: Text('No leagues yet.\nCreate one from the home screen.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, height: 1.6)),
              ),
            ),
          ]),
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  16, 16, 16, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: () =>
                      Navigator.pop(context),
                  child: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 20),
                ),
                const SizedBox(width: 16),
                const Text('View League',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight:
                        FontWeight.w800)),
              ]),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: SingleChildScrollView(
                padding:
                const EdgeInsets.symmetric(
                    horizontal: 16),
                child: Column(
                  children: [

                    // ── League Card ──
                    Container(
                      padding:
                      const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(
                            0xFF111111),
                        borderRadius:
                        BorderRadius.circular(
                            16),
                        border: Border.all(
                            color: Colors.white10),
                      ),
                      child: Row(children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(
                                0xFF0A1A3A),
                            borderRadius:
                            BorderRadius
                                .circular(12),
                            border: Border.all(
                                color: const Color(
                                    0xFF1A6BFF)
                                    .withOpacity(
                                    0.3)),
                          ),
                          child: const Center(
                              child: Text('🦅',
                                  style: TextStyle(
                                      fontSize:
                                      32))),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                            children: [
                              Row(children: [
                                Expanded(
                                  child: Text(
                                      (_league?['name'] as String?) ?? '',
                                      style: const TextStyle(
                                          color: Colors
                                              .white,
                                          fontWeight:
                                          FontWeight
                                              .w800,
                                          fontSize:
                                          15)),
                                ),
                                Container(
                                  padding: const EdgeInsets
                                      .symmetric(
                                      horizontal:
                                      10,
                                      vertical: 4),
                                  decoration:
                                  BoxDecoration(
                                    color: const Color(
                                        0xFF00C853)
                                        .withOpacity(
                                        0.15),
                                    borderRadius:
                                    BorderRadius
                                        .circular(
                                        20),
                                    border: Border.all(
                                        color: const Color(
                                            0xFF00C853)
                                            .withOpacity(
                                            0.3)),
                                  ),
                                  child: const Text(
                                      'Active',
                                      style: TextStyle(
                                          color: Color(
                                              0xFF00C853),
                                          fontSize:
                                          11,
                                          fontWeight:
                                          FontWeight
                                              .w700)),
                                ),
                              ]),
                              const SizedBox(
                                  height: 4),
                              Text(
                                  'Code: ${_league?['league_code'] ?? ''}  •  ${_league?['cricket_type'] ?? ''}',
                                  style: const TextStyle(
                                      color: Colors
                                          .white54,
                                      fontSize:
                                      13)),
                              const SizedBox(
                                  height: 2),
                              Text(
                                  '$_teamsCount Teams  •  ${_detail?['location'] ?? ''}',
                                  style: const TextStyle(
                                      color: Colors
                                          .white38,
                                      fontSize:
                                      12)),
                            ],
                          ),
                        ),
                      ]),
                    ),

                    const SizedBox(height: 12),

                    // ── Menu Items ──
                    _LeagueMenuItem(
                      icon: Icons.people_outline,
                      title: 'Teams',
                      subtitle: '$_teamsCount Teams',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => _TeamsScreen(
                                  standings: (_detail?['standings']
                                          as List<dynamic>?) ??
                                      const []))),
                    ),
                    const SizedBox(height: 10),
                    _LeagueMenuItem(
                      icon: Icons
                          .calendar_today_outlined,
                      title: 'Matches',
                      subtitle: '$_matchesCount Matches',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => SelectMatchScreen(
                                  leagueId: _league!['id'] as String,
                                  leagueName:
                                      _league!['name'] as String))),
                    ),
                    const SizedBox(height: 10),
                    _LeagueMenuItem(
                      icon:
                      Icons.bar_chart_outlined,
                      title: 'Standings',
                      subtitle: 'View points table',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                              _StandingsScreen(
                                  standings: (_detail?['standings']
                                          as List<dynamic>?) ??
                                      const []))),
                    ),
                    const SizedBox(height: 10),
                    _LeagueMenuItem(
                      icon: Icons.person_outline,
                      title: 'Players & Points',
                      subtitle: '$_playersCount Players',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => SelectMatchScreen(
                                  leagueId: _league!['id'] as String,
                                  leagueName:
                                      _league!['name'] as String))),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── League Menu Item ──────────────────────────────────────────────────

class _LeagueMenuItem extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _LeagueMenuItem(
      {required this.icon,
        required this.title,
        required this.subtitle,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(16),
          border:
          Border.all(color: Colors.white10),
        ),
        child: Row(children: [
          Icon(icon,
              color: Colors.white60, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 13)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward,
              color: Colors.white38, size: 20),
        ]),
      ),
    );
  }
}

// ── Teams Screen ──────────────────────────────────────────────────────

class _TeamsScreen extends StatelessWidget {
  final List<dynamic> standings;
  const _TeamsScreen({required this.standings});

  List<Map<String, dynamic>> get _teams => standings
      .map((raw) {
        final row = raw as Map<String, dynamic>;
        return <String, dynamic>{
          'name': row['team_name'] ?? '',
          'players': row['played'] ?? 0,
          'wins': row['won'] ?? 0,
          'emoji': '🏏',
        };
      })
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  16, 16, 16, 0),
              child: Row(children: [
                GestureDetector(
                    onTap: () =>
                        Navigator.pop(context),
                    child: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 20)),
                const SizedBox(width: 16),
                const Text('Teams',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight:
                        FontWeight.w800)),
                const Spacer(),
                Container(
                  padding:
                  const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C853)
                        .withOpacity(0.15),
                    borderRadius:
                    BorderRadius.circular(20),
                  ),
                  child: const Text('8 Teams',
                      style: TextStyle(
                          color:
                          Color(0xFF00C853),
                          fontSize: 12,
                          fontWeight:
                          FontWeight.w600)),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                padding:
                const EdgeInsets.symmetric(
                    horizontal: 16),
                itemCount: _teams.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final t = _teams[i];
                  return Container(
                    padding:
                    const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                      const Color(0xFF111111),
                      borderRadius:
                      BorderRadius.circular(
                          14),
                      border: Border.all(
                          color: Colors.white10),
                    ),
                    child: Row(children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(
                              0xFF1A6BFF)
                              .withOpacity(0.1),
                          borderRadius:
                          BorderRadius
                              .circular(12),
                        ),
                        child: Center(
                            child: Text(
                                t['emoji']
                                as String,
                                style: const TextStyle(
                                    fontSize:
                                    26))),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                          children: [
                            Text(
                                t['name']
                                as String,
                                style: const TextStyle(
                                    color:
                                    Colors.white,
                                    fontWeight:
                                    FontWeight
                                        .w700,
                                    fontSize:
                                    14)),
                            Text(
                                '${t['players']} Players  •  ${t['wins']} Wins',
                                style: const TextStyle(
                                    color: Colors
                                        .white38,
                                    fontSize:
                                    12)),
                          ],
                        ),
                      ),
                      const Icon(
                          Icons.chevron_right,
                          color: Colors.white24),
                    ]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StandingsScreen extends StatelessWidget {
  final List<dynamic> standings;
  const _StandingsScreen({required this.standings});

  List<Map<String, dynamic>> get _standings => standings
      .map((raw) {
        final row = raw as Map<String, dynamic>;
        return <String, dynamic>{
          'pos': row['position'] ?? 0,
          'team': row['team_name'] ?? '',
          'p': row['played'] ?? 0,
          'w': row['won'] ?? 0,
          'l': row['lost'] ?? 0,
          'pts': row['points'] ?? 0,
          'emoji': '🏏',
        };
      })
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  16, 16, 16, 0),
              child: Row(children: [
                GestureDetector(
                    onTap: () =>
                        Navigator.pop(context),
                    child: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 20)),
                const SizedBox(width: 16),
                const Text('Standings',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight:
                        FontWeight.w800)),
              ]),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A6BFF)
                      .withOpacity(0.15),
                  borderRadius:
                  BorderRadius.circular(10),
                ),
                child: const Row(children: [
                  SizedBox(
                      width: 30,
                      child: Text('#',
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight:
                              FontWeight.w700))),
                  Expanded(
                      child: Text('Team',
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight:
                              FontWeight.w700))),
                  SizedBox(
                      width: 30,
                      child: Text('P',
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight:
                              FontWeight.w700),
                          textAlign:
                          TextAlign.center)),
                  SizedBox(
                      width: 30,
                      child: Text('W',
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight:
                              FontWeight.w700),
                          textAlign:
                          TextAlign.center)),
                  SizedBox(
                      width: 30,
                      child: Text('L',
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight:
                              FontWeight.w700),
                          textAlign:
                          TextAlign.center)),
                  SizedBox(
                      width: 40,
                      child: Text('PTS',
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight:
                              FontWeight.w700),
                          textAlign:
                          TextAlign.center)),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                padding:
                const EdgeInsets.symmetric(
                    horizontal: 16),
                itemCount: _standings.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 6),
                itemBuilder: (context, i) {
                  final s = _standings[i];
                  final isTop =
                      (s['pos'] as int) <= 3;
                  return Container(
                    padding:
                    const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12),
                    decoration: BoxDecoration(
                      color: isTop
                          ? const Color(0xFF1A6BFF)
                          .withOpacity(0.08)
                          : const Color(0xFF111111),
                      borderRadius:
                      BorderRadius.circular(12),
                      border: Border.all(
                          color: isTop
                              ? const Color(
                              0xFF1A6BFF)
                              .withOpacity(0.2)
                              : Colors.white10),
                    ),
                    child: Row(children: [
                      SizedBox(
                        width: 30,
                        child: Text(
                            '${s['pos']}',
                            style: TextStyle(
                                color: isTop
                                    ? const Color(
                                    0xFF1A6BFF)
                                    : Colors.white38,
                                fontWeight:
                                FontWeight.w700,
                                fontSize: 13)),
                      ),
                      Expanded(
                        child: Row(children: [
                          Text(
                              s['emoji'] as String,
                              style: const TextStyle(
                                  fontSize: 16)),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(
                                  s['team']
                                  as String,
                                  style: const TextStyle(
                                      color:
                                      Colors.white,
                                      fontWeight:
                                      FontWeight
                                          .w600,
                                      fontSize: 13),
                                  overflow:
                                  TextOverflow
                                      .ellipsis)),
                        ]),
                      ),
                      SizedBox(
                          width: 30,
                          child: Text('${s['p']}',
                              style: const TextStyle(
                                  color:
                                  Colors.white54,
                                  fontSize: 13),
                              textAlign:
                              TextAlign.center)),
                      SizedBox(
                          width: 30,
                          child: Text('${s['w']}',
                              style: const TextStyle(
                                  color:
                                  Colors.white54,
                                  fontSize: 13),
                              textAlign:
                              TextAlign.center)),
                      SizedBox(
                          width: 30,
                          child: Text('${s['l']}',
                              style: const TextStyle(
                                  color:
                                  Colors.white54,
                                  fontSize: 13),
                              textAlign:
                              TextAlign.center)),
                      SizedBox(
                        width: 40,
                        child: Text('${s['pts']}',
                            style: TextStyle(
                                color: isTop
                                    ? const Color(
                                    0xFF1A6BFF)
                                    : Colors.white,
                                fontWeight:
                                FontWeight.w800,
                                fontSize: 14),
                            textAlign:
                            TextAlign.center),
                      ),
                    ]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}