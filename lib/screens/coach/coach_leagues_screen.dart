import 'package:flutter/material.dart';
import '../../api/services.dart';
import '../../api/ui_helpers.dart';
import '../../theme/app_theme.dart';
import '../../api/api_config.dart';
import 'coach_dugout_screen.dart' show ProfileDetailScreen;
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

  List<Map<String, dynamic>> _leagues = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final leagues = await LeagueService.myLeagues();
      if (!mounted) return;
      final list = leagues.cast<Map<String, dynamic>>();
      if (list.isEmpty) {
        setState(() {
          _leagues = [];
          _league = null;
          _detail = null;
          _loading = false;
        });
        return;
      }
      // Keep the currently selected league if the coach has one in view;
      // otherwise show the newest one. This way creating a new league
      // doesn't wipe the coach's context on an existing tournament.
      Map<String, dynamic> selected = list.first;
      if (_league != null) {
        final currentId = _league!['id'];
        final match = list.firstWhere(
                (l) => l['id'] == currentId,
            orElse: () => list.first);
        selected = match;
      }
      final detail =
      await LeagueService.detail(selected['id'] as String);
      if (!mounted) return;
      setState(() {
        _leagues = list;
        _league = selected;
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

  Future<void> _switchLeague(Map<String, dynamic> lg) async {
    setState(() => _loading = true);
    try {
      final detail = await LeagueService.detail(lg['id'] as String);
      if (!mounted) return;
      setState(() {
        _league = lg;
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

  void _showLeaguePicker() {
    if (_leagues.length <= 1) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Text('Your Leagues',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
          ),
          ..._leagues.map((lg) {
            final selected = _league?['id'] == lg['id'];
            final status = (lg['status'] as String?) ?? 'active';
            return ListTile(
              leading: const Text('🏏',
                  style: TextStyle(fontSize: 22)),
              title: Text((lg['name'] as String?) ?? '',
                  style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                  '${lg['cricket_type'] ?? ''} • ${lg['teams_count'] ?? 0} teams • $status',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 12)),
              trailing: selected
                  ? const Icon(Icons.check_circle,
                  color: Color(0xFF00C853))
                  : const Icon(Icons.chevron_right,
                  color: Colors.white38),
              onTap: () {
                Navigator.pop(ctx);
                _switchLeague(lg);
              },
            );
          }),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  int get _playersCount => (_league?['players_count'] as int?) ?? 0;
  int get _teamsCount =>
      ((_detail?['teams'] as List<dynamic>?) ?? const []).length;
  int get _matchesCount =>
      (_detail?['stats']?['matches'] as int?) ?? 0;

  Future<void> _finishTournament() async {
    if (_league?['status'] == 'completed' ||
        _detail?['status'] == 'completed') {
      showInfo(context, 'This tournament was already completed.');
      return;
    }
    final teams = ((_detail?['teams'] as List<dynamic>?) ?? const [])
        .cast<Map<String, dynamic>>();
    if (teams.length < 2) {
      showInfo(context, 'Need at least 2 teams to finish a tournament.');
      return;
    }

    Future<Map<String, dynamic>?> pickTeam(String title,
        {String? excludeId, bool allowSkip = false}) {
      return showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        backgroundColor: const Color(0xFF111111),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
            ),
            ...teams
                .where((t) => t['id'] != excludeId)
                .map((t) => ListTile(
              leading: const Text('🏏',
                  style: TextStyle(fontSize: 22)),
              title: Text(t['name'] as String? ?? '',
                  style:
                  const TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx, t),
            )),
            if (allowSkip)
              ListTile(
                title: const Text('Skip — no runner-up',
                    style: TextStyle(color: Colors.white54)),
                onTap: () =>
                    Navigator.pop(ctx, <String, dynamic>{'skip': true}),
              ),
            const SizedBox(height: 8),
          ]),
        ),
      );
    }

    final winner =
    await pickTeam('Who won the tournament? 🏆');
    if (winner == null || !mounted) return;
    final runnerUp = await pickTeam('Runner-Up team',
        excludeId: winner['id'] as String?, allowSkip: true);
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Finish Tournament?',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800)),
        content: Text(
            'Winner: ${winner['name']} (+100 Qo each)\n'
                '${runnerUp != null && runnerUp['skip'] != true ? 'Runner-Up: ${runnerUp['name']} (+50 Qo each)\n' : ''}'
                'This closes the league and can\'t be undone.',
            style: const TextStyle(color: Colors.white54, height: 1.5)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A6BFF)),
            child: const Text('Finish 🏆',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final res = await LeagueService.completeTournament(
        leagueId: _league!['id'] as String,
        winnerTeamId: winner['id'] as String,
        runnerUpTeamId: (runnerUp != null && runnerUp['skip'] != true)
            ? runnerUp['id'] as String?
            : null,
      );
      if (!mounted) return;
      final count =
          (res['qo_points_awarded'] as Map<String, dynamic>? ?? {}).length;
      showInfo(context,
          '${res['winner_team']} crowned champions — bonuses sent to $count players 🏆');
      _load();
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

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

                    // ── League Card (tap to switch when there are multiple) ──
                    GestureDetector(
                      onTap: _leagues.length > 1
                          ? _showLeaguePicker
                          : null,
                      child: Container(
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
                          if (_leagues.length > 1)
                            const Padding(
                              padding: EdgeInsets.only(
                                  left: 6),
                              child: Icon(
                                  Icons.swap_horiz,
                                  color: Colors.white38,
                                  size: 20),
                            ),
                        ]),
                      ),
                    ),
                    if (_leagues.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 6, left: 4),
                        child: Text(
                            'Tap the card to switch between your ${_leagues.length} leagues',
                            style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11)),
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
                                  leagueId:
                                  _league!['id'] as String,
                                  teams: ((_detail?['teams']
                                  as List<dynamic>?) ??
                                      const [])
                                      .cast<
                                      Map<String,
                                          dynamic>>()))),
                    ),
                    const SizedBox(height: 10),
                    _LeagueMenuItem(
                      icon: Icons
                          .calendar_today_outlined,
                      title: 'Matches',
                      subtitle: '$_matchesCount Matches',
                      onTap: () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => SelectMatchScreen(
                                    leagueId: _league!['id'] as String,
                                    leagueName:
                                    _league!['name'] as String)));
                        _load(); // standings/points may have changed
                      },
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
                      onTap: () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    _PlayersLeaderboardScreen(
                                        leagueId:
                                        _league!['id']
                                        as String,
                                        leagueName:
                                        _league!['name']
                                        as String)));
                        _load();
                      },
                    ),
                    const SizedBox(height: 10),
                    _LeagueMenuItem(
                      icon: Icons.emoji_events_outlined,
                      title: 'Finish Tournament',
                      subtitle: (_league?['status'] == 'completed' ||
                          _detail?['status'] == 'completed')
                          ? 'Tournament completed 🏆'
                          : 'Award Winner +100 / Runner-Up +50',
                      onTap: _finishTournament,
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

class _TeamsScreen extends StatefulWidget {
  final String leagueId;
  final List<Map<String, dynamic>> teams;
  const _TeamsScreen(
      {required this.leagueId, required this.teams});

  @override
  State<_TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<_TeamsScreen> {
  // members grouped by team — one fetch for the whole league
  Map<String, List<Map<String, dynamic>>> _byTeam = {};
  bool _loading = true;
  String? _expandedTeamId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items =
      await LeagueService.players(widget.leagueId);
      if (!mounted) return;
      final grouped =
      <String, List<Map<String, dynamic>>>{};
      for (final raw in items) {
        final m = raw as Map<String, dynamic>;
        final tid = (m['team_id'] as String?) ?? '';
        grouped.putIfAbsent(tid, () => []).add(m);
      }
      setState(() {
        _byTeam = grouped;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openProfile(Map<String, dynamic> pl) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProfileDetailScreen(
                person: <String, dynamic>{
                  'author_id': pl['id'] as String,
                  'name': (pl['name'] as String?) ?? '',
                  'avatar': ApiConfig.resolveMediaUrl(
                      pl['avatar_url'] as String?) ??
                      '',
                  'verified': false,
                  'sport':
                  (pl['sub_role'] as String?) ?? 'Player',
                  'location': '',
                  'bio': '',
                })));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
              const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(children: [
                GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios,
                        color: Colors.white, size: 20)),
                const SizedBox(width: 16),
                const Text('Teams',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C853)
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${widget.teams.length} Teams',
                      style: const TextStyle(
                          color: Color(0xFF00C853),
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                    'Tap a team to see who joined. Tap a player to open their playbook.',
                    style: TextStyle(
                        color: Colors.white38, fontSize: 12)),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF1A6BFF)))
                  : RefreshIndicator(
                color: const Color(0xFF1A6BFF),
                onRefresh: _load,
                child: ListView.separated(
                  physics:
                  const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16),
                  itemCount: widget.teams.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final t = widget.teams[i];
                    final tid =
                        (t['id'] as String?) ?? '';
                    final members =
                        _byTeam[tid] ?? const [];
                    final expanded =
                        _expandedTeamId == tid;
                    final logo =
                    ApiConfig.resolveMediaUrl(
                        t['logo_url'] as String?);
                    return Container(
                      decoration: BoxDecoration(
                        color:
                        const Color(0xFF111111),
                        borderRadius:
                        BorderRadius.circular(14),
                        border: Border.all(
                            color: expanded
                                ? const Color(
                                0xFF1A6BFF)
                                .withOpacity(0.5)
                                : Colors.white10),
                      ),
                      child: Column(children: [
                        // ── team header row ──
                        GestureDetector(
                          behavior: HitTestBehavior
                              .opaque,
                          onTap: () => setState(() =>
                          _expandedTeamId =
                          expanded
                              ? null
                              : tid),
                          child: Padding(
                            padding:
                            const EdgeInsets.all(
                                16),
                            child: Row(children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration:
                                BoxDecoration(
                                  color: const Color(
                                      0xFF1A6BFF)
                                      .withOpacity(
                                      0.1),
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                      12),
                                ),
                                child: logo != null &&
                                    logo.isNotEmpty
                                    ? ClipRRect(
                                    borderRadius:
                                    BorderRadius
                                        .circular(
                                        12),
                                    child: Image.network(
                                        logo,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit
                                            .cover,
                                        errorBuilder: (_,
                                            __,
                                            ___) =>
                                        const Center(
                                            child: Text('🏏',
                                                style: TextStyle(fontSize: 26)))))
                                    : const Center(
                                    child: Text(
                                        '🏏',
                                        style: TextStyle(
                                            fontSize:
                                            26))),
                              ),
                              const SizedBox(
                                  width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                                  children: [
                                    Text(
                                        (t['name'] as String?) ??
                                            '',
                                        style: const TextStyle(
                                            color: Colors
                                                .white,
                                            fontWeight:
                                            FontWeight
                                                .w700,
                                            fontSize:
                                            15)),
                                    const SizedBox(
                                        height: 2),
                                    Text(
                                        '${members.length} player${members.length == 1 ? '' : 's'} joined',
                                        style: const TextStyle(
                                            color: Colors
                                                .white38,
                                            fontSize:
                                            12)),
                                  ],
                                ),
                              ),
                              Icon(
                                  expanded
                                      ? Icons
                                      .keyboard_arrow_up
                                      : Icons
                                      .keyboard_arrow_down,
                                  color:
                                  Colors.white38,
                                  size: 22),
                            ]),
                          ),
                        ),
                        // ── members (who joined) ──
                        if (expanded) ...[
                          const Divider(
                              color: Colors.white10,
                              height: 1),
                          if (members.isEmpty)
                            const Padding(
                              padding:
                              EdgeInsets.all(16),
                              child: Text(
                                  'No players have joined this team yet.',
                                  style: TextStyle(
                                      color: Colors
                                          .white38,
                                      fontSize: 12)),
                            )
                          else
                            ...members.map((pl) {
                              final name =
                                  (pl['name']
                                  as String?) ??
                                      '';
                              final avatar = ApiConfig
                                  .resolveMediaUrl(
                                  pl['avatar_url']
                                  as String?);
                              return GestureDetector(
                                behavior:
                                HitTestBehavior
                                    .opaque,
                                onTap: () =>
                                    _openProfile(pl),
                                child: Padding(
                                  padding:
                                  const EdgeInsets
                                      .fromLTRB(16,
                                      10, 16, 10),
                                  child:
                                  Row(children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration:
                                      const BoxDecoration(
                                        color: Color(
                                            0xFF1E2E1E),
                                        shape: BoxShape
                                            .circle,
                                      ),
                                      child: ClipOval(
                                        child: avatar !=
                                            null &&
                                            avatar
                                                .isNotEmpty
                                            ? Image.network(
                                            avatar,
                                            fit: BoxFit
                                                .cover,
                                            errorBuilder: (_, __, ___) => Center(
                                                child: Text(
                                                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13))))
                                            : Center(
                                            child: Text(
                                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                                style: const TextStyle(
                                                    color:
                                                    Colors.white,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 13))),
                                      ),
                                    ),
                                    const SizedBox(
                                        width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          Text(name,
                                              overflow:
                                              TextOverflow
                                                  .ellipsis,
                                              style: const TextStyle(
                                                  color:
                                                  Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13)),
                                          Text(
                                              '${pl['player_id'] ?? ''} • ${pl['sub_role'] ?? 'Player'} • Qo ${pl['qo_score'] ?? 0}',
                                              overflow:
                                              TextOverflow
                                                  .ellipsis,
                                              style: const TextStyle(
                                                  color:
                                                  Colors.white38,
                                                  fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                        Icons
                                            .chevron_right,
                                        color: Colors
                                            .white24,
                                        size: 18),
                                  ]),
                                ),
                              );
                            }),
                          const SizedBox(height: 6),
                        ],
                      ]),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Players Leaderboard ────────────────────────────────────────────────
// IPL-style aggregated stats for every player in the league: total runs,
// wickets, catches, matches played, points earned. Tap a row → open the
// player's Instagram-style profile.

class _PlayersLeaderboardScreen extends StatefulWidget {
  final String leagueId;
  final String leagueName;
  const _PlayersLeaderboardScreen(
      {required this.leagueId, required this.leagueName});

  @override
  State<_PlayersLeaderboardScreen> createState() =>
      _PlayersLeaderboardScreenState();
}

class _PlayersLeaderboardScreenState
    extends State<_PlayersLeaderboardScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _players = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items =
      await LeagueService.players(widget.leagueId);
      if (!mounted) return;
      setState(() {
        _players = items.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding:
            const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(children: [
              GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios,
                      color: Colors.white, size: 20)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Text('Players & Points',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    Text(widget.leagueName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12)),
                  ],
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF1A6BFF)))
                : _players.isEmpty
                ? const Center(
                child: Text(
                    'No players have joined this league yet.',
                    style: TextStyle(
                        color: Colors.white38,
                        fontSize: 13)))
                : RefreshIndicator(
              color: const Color(0xFF1A6BFF),
              onRefresh: _load,
              child: ListView.separated(
                padding:
                const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4),
                itemCount: _players.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final p = _players[i];
                  return _LeaderboardRow(
                    index: i + 1,
                    player: p,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                _PlayerMatchHistoryScreen(
                                  leagueId:
                                  widget.leagueId,
                                  player: p,
                                ))),
                  );
                },
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final int index;
  final Map<String, dynamic> player;
  final VoidCallback onTap;
  const _LeaderboardRow(
      {required this.index,
        required this.player,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    final avatar = ApiConfig.resolveMediaUrl(
        player['avatar_url'] as String?);
    final name = (player['name'] as String?) ?? '';
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(children: [
          // ── Top row: rank + avatar + name/team + Qo pill ──
          Row(children: [
            SizedBox(
              width: 22,
              child: Text('$index',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: index <= 3
                          ? const Color(0xFF00C853)
                          : Colors.white38,
                      fontWeight: FontWeight.w800,
                      fontSize: 13)),
            ),
            const SizedBox(width: 6),
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  shape: BoxShape.circle),
              child: ClipOval(
                child: avatar != null && avatar.isNotEmpty
                    ? Image.network(avatar,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                        child: Text(
                            name.isNotEmpty
                                ? name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight:
                                FontWeight.w800))))
                    : Center(
                    child: Text(
                        name.isNotEmpty
                            ? name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight:
                            FontWeight.w800))),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  Text(
                      '${player['team_name'] ?? ''} • ${player['sub_role'] ?? 'Player'}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF7B2FFF)
                    .withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFF7B2FFF)
                        .withOpacity(0.4)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.bolt,
                    color: Color(0xFF7B2FFF), size: 12),
                const SizedBox(width: 3),
                Text('${player['qo_score'] ?? 0}',
                    style: const TextStyle(
                        color: Color(0xFF7B2FFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w800)),
              ]),
            ),
          ]),
          const SizedBox(height: 10),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 8),
          // ── Bottom row: match stats ──
          Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceAround,
              children: [
                _StatMini(
                    value: '${player['matches'] ?? 0}',
                    label: 'M'),
                _StatMini(
                    value: '${player['runs'] ?? 0}',
                    label: 'Runs'),
                _StatMini(
                    value: '${player['wickets'] ?? 0}',
                    label: 'Wkts'),
                _StatMini(
                    value: '${player['catches'] ?? 0}',
                    label: 'Ct'),
                _StatMini(
                    value:
                    '+${player['points_this_league'] ?? 0}',
                    label: 'Pts',
                    highlight: true),
              ]),
        ]),
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  final String value;
  final String label;
  final bool highlight;
  const _StatMini(
      {required this.value,
        required this.label,
        this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: TextStyle(
              color: highlight
                  ? const Color(0xFF00C853)
                  : Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14)),
      const SizedBox(height: 2),
      Text(label,
          style: const TextStyle(
              color: Colors.white38, fontSize: 10)),
    ]);
  }
}

// ── Per-Player Match History ───────────────────────────────────────────
// Shows every match this player played in this league, one row per
// match with runs / wickets / catches / points. Tapped from the
// Players & Points leaderboard so coaches can drill down instead of
// only seeing aggregate totals.

class _PlayerMatchHistoryScreen extends StatefulWidget {
  final String leagueId;
  final Map<String, dynamic> player;
  const _PlayerMatchHistoryScreen(
      {required this.leagueId, required this.player});

  @override
  State<_PlayerMatchHistoryScreen> createState() =>
      _PlayerMatchHistoryScreenState();
}

class _PlayerMatchHistoryScreenState
    extends State<_PlayerMatchHistoryScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _matches = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await LeagueService.playerMatchHistory(
          widget.leagueId, widget.player['id'] as String);
      if (!mounted) return;
      setState(() {
        _matches = items.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Live-calculated Qo points from stats — used until Submit finalizes.
  int _calcPts(Map<String, dynamic> m) {
    final stored = (m['qo_points_awarded'] as num?)?.toInt() ?? 0;
    if (stored > 0) return stored;
    final r = (m['runs'] as num?)?.toInt() ?? 0;
    final w = (m['wickets'] as num?)?.toInt() ?? 0;
    final c = (m['catches'] as num?)?.toInt() ?? 0;
    int batting;
    if (r >= 100) {
      batting = 50;
    } else if (r >= 46) {
      batting = 20;
    } else if (r >= 26) {
      batting = 12;
    } else if (r >= 11) {
      batting = 8;
    } else if (r > 0) {
      batting = 5;
    } else {
      batting = 0;
    }
    final bowling = w >= 3 ? 20 : (w >= 1 ? 5 : 0);
    final fielding = c >= 3 ? 5 : (c == 2 ? 2 : 0);
    int bonus = 0;
    if (m['is_mom'] == true) bonus += 20;
    if (m['is_player_of_match'] == true) bonus += 20;
    if (m['is_best_bowler'] == true) bonus += 20;
    if (m['is_best_batsman'] == true) bonus += 20;
    if (m['is_mvp'] == true) bonus += 25;
    return batting + bowling + fielding + bonus;
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final d = DateTime.parse(iso).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.player;
    final avatar =
    ApiConfig.resolveMediaUrl(p['avatar_url'] as String?);
    final name = (p['name'] as String?) ?? '';
    final totalPts =
    _matches.fold<int>(0, (sum, m) => sum + _calcPts(m));
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(children: [
          // ── Player header ──
          Padding(
            padding:
            const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(children: [
              GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios,
                      color: Colors.white, size: 20)),
              const SizedBox(width: 12),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                    color: Color(0xFF1A1A1A),
                    shape: BoxShape.circle),
                child: ClipOval(
                  child: avatar != null && avatar.isNotEmpty
                      ? Image.network(avatar,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                          child: Text(
                              name.isNotEmpty
                                  ? name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight:
                                  FontWeight.w800))))
                      : Center(
                      child: Text(
                          name.isNotEmpty
                              ? name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight:
                              FontWeight.w800))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800)),
                    Text(
                        '${p['team_name'] ?? ''} • Match history',
                        style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B2FFF)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFF7B2FFF)
                          .withOpacity(0.4)),
                ),
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt,
                          color: Color(0xFF7B2FFF),
                          size: 14),
                      const SizedBox(width: 4),
                      Text('$totalPts',
                          style: const TextStyle(
                              color: Color(0xFF7B2FFF),
                              fontSize: 13,
                              fontWeight: FontWeight.w800)),
                    ]),
              ),
            ]),
          ),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF1A6BFF)))
                : _matches.isEmpty
                ? const Center(
                child: Text(
                    'No matches played yet.',
                    style: TextStyle(
                        color: Colors.white38,
                        fontSize: 13)))
                : ListView.separated(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              itemCount: _matches.length,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final m = _matches[i];
                final pts = _calcPts(m);
                return Container(
                  padding:
                  const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius:
                    BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      Row(children: [
                        Text(
                            'Match ${i + 1}',
                            style:
                            const TextStyle(
                                color: Color(
                                    0xFF00C853),
                                fontSize: 12,
                                fontWeight:
                                FontWeight
                                    .w700)),
                        const Spacer(),
                        Text(
                            _formatDate(m[
                            'played_at']
                            as String?),
                            style:
                            const TextStyle(
                                color: Colors
                                    .white54,
                                fontSize: 11)),
                      ]),
                      const SizedBox(height: 4),
                      Text(
                          '${m['team_a'] ?? '-'} vs ${m['team_b'] ?? '-'}',
                          overflow: TextOverflow
                              .ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight:
                              FontWeight
                                  .w600)),
                      const SizedBox(height: 10),
                      const Divider(
                          color: Colors.white10,
                          height: 1),
                      const SizedBox(height: 10),
                      Row(
                          mainAxisAlignment:
                          MainAxisAlignment
                              .spaceAround,
                          children: [
                            _StatMini(
                                value:
                                '${m['runs'] ?? 0}',
                                label: 'Runs'),
                            _StatMini(
                                value:
                                '${m['wickets'] ?? 0}',
                                label: 'Wkts'),
                            _StatMini(
                                value:
                                '${m['catches'] ?? 0}',
                                label: 'Ct'),
                            _StatMini(
                                value: '+$pts',
                                label: 'Pts',
                                highlight: true),
                          ]),
                      // Bonus badges if any
                      if (m['is_mom'] == true ||
                          m['is_mvp'] == true ||
                          m['is_best_bowler'] ==
                              true ||
                          m['is_best_batsman'] ==
                              true ||
                          m['is_player_of_match'] ==
                              true) ...[
                        const SizedBox(height: 10),
                        Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              if (m['is_mom'] ==
                                  true)
                                const _BonusChip(
                                    label:
                                    'MoM',
                                    icon: Icons
                                        .military_tech),
                              if (m['is_mvp'] ==
                                  true)
                                const _BonusChip(
                                    label:
                                    'MVP',
                                    icon: Icons
                                        .workspace_premium),
                              if (m['is_player_of_match'] ==
                                  true)
                                const _BonusChip(
                                    label: 'PoM',
                                    icon: Icons
                                        .star),
                              if (m['is_best_bowler'] ==
                                  true)
                                const _BonusChip(
                                    label:
                                    'Best Bowler',
                                    icon: Icons
                                        .sports_cricket),
                              if (m['is_best_batsman'] ==
                                  true)
                                const _BonusChip(
                                    label:
                                    'Best Batsman',
                                    icon: Icons
                                        .sports_baseball),
                            ]),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _BonusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _BonusChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.amber.withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.amber, size: 12),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                color: Colors.amber,
                fontSize: 10,
                fontWeight: FontWeight.w700)),
      ]),
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