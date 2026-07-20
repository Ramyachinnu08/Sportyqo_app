import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../api/api_config.dart';
import 'package:flutter/material.dart';
import '../../api/mappers.dart';
import '../../api/services.dart';
import '../../theme/app_theme.dart';
import 'coach_dugout_screen.dart';
import 'coach_playbook_screen.dart';
import 'coach_performance_screen.dart';
import 'create_league_screen.dart';
import 'coach_leagues_screen.dart';
import 'coach_certification_screen.dart';

class CoachHomeScreen extends StatefulWidget {
  const CoachHomeScreen({super.key});

  @override
  State<CoachHomeScreen> createState() =>
      _CoachHomeScreenState();
}

class _CoachHomeScreenState
    extends State<CoachHomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    const _CoachHomeTab(),
    const CoachDugoutScreen(),
    const CoachPerformanceScreen(),
    const CoachPlaybookScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F0F0F),
          border: Border(
              top: BorderSide(color: Colors.white10)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) =>
              setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFF00C853),
          unselectedItemColor: Colors.white38,
          selectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins'),
          unselectedLabelStyle: const TextStyle(
              fontSize: 11, fontFamily: 'Poppins'),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: 'Dugout'),
            BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_outlined),
                activeIcon: Icon(Icons.bar_chart),
                label: 'Performance'),
            BottomNavigationBarItem(
                icon: Icon(Icons.menu_book_outlined),
                activeIcon: Icon(Icons.menu_book),
                label: 'Playbook'),
          ],
        ),
      ),
    );
  }
}

// ── Coach Home Tab ────────────────────────────────────────────────────

class _CoachHomeTab extends StatefulWidget {
  const _CoachHomeTab();

  @override
  State<_CoachHomeTab> createState() => _CoachHomeTabState();
}

class _CoachHomeTabState extends State<_CoachHomeTab> {
  Map<String, dynamic>? _dash;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dash = await CoachService.dashboard();
      if (mounted) setState(() => _dash = dash);
    } catch (_) {}
  }

  Map<String, dynamic> get _coach =>
      (_dash?['coach'] as Map<String, dynamic>?) ?? const {};
  Map<String, dynamic> get _stats =>
      (_dash?['quick_stats'] as Map<String, dynamic>?) ?? const {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [

              // ── Top Bar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    20, 16, 20, 0),
                child: Row(children: [
                  ClipRRect(
                    borderRadius:
                    BorderRadius.circular(8),
                    child: Image.network(
                      'https://i.ibb.co/pjLXfmH4/29.png',
                      width: 36, height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C853),
                              borderRadius:
                              BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.bolt,
                                color: Colors.white,
                                size: 20),
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: const [
                      Text('SportyQo',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight:
                              FontWeight.w800)),
                      Text('Every Player Counts.',
                          style: TextStyle(
                              color: Colors.white38,
                              fontSize: 9)),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const
                            _CoachNotificationScreen())),
                    child: Stack(children: [
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                            color: Colors.white10,
                            shape: BoxShape.circle),
                        child: const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                            size: 22),
                      ),
                      Positioned(
                        top: 6, right: 6,
                        child: Container(
                          width: 9, height: 9,
                          decoration: BoxDecoration(
                              color:
                              const Color(0xFF00C853),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(
                                      0xFF0A0A0A),
                                  width: 1.5)),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                              const _CoachProfileImageScreen()));
                      if (mounted) setState(() {});
                    },
                    child: Builder(builder: (context) {
                      final resolved =
                      ApiConfig.resolveMediaUrl(
                          Session.avatarUrl);
                      final initial = Text(
                          Session.firstName.isNotEmpty
                              ? Session.firstName[0]
                              .toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight:
                              FontWeight.w800));
                      return Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                          const Color(0xFF13132B),
                          border: Border.all(
                              color: const Color(
                                  0xFF00C853),
                              width: 2),
                        ),
                        child: ClipOval(
                          child: resolved != null &&
                              resolved.isNotEmpty
                              ? Image.network(resolved,
                              fit: BoxFit.cover,
                              width: 44,
                              height: 44,
                              errorBuilder:
                                  (_, __, ___) =>
                                  Center(
                                      child:
                                      initial))
                              : Center(child: initial),
                        ),
                      );
                    }),
                  ),
                ]),
              ),

              const SizedBox(height: 20),

              // ── Coach Name ──
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text((_coach['full_name'] as String?) ?? 'Coach',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight:
                              FontWeight.w800)),
                      const SizedBox(width: 8),
                      Container(
                        width: 24, height: 24,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00C853),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check,
                            color: Colors.white,
                            size: 14),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      Text((_coach['role_title'] as String?) ?? 'Coach',
                          style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 14)),
                      const Text(' • ',
                          style: TextStyle(
                              color: Colors.white24,
                              fontSize: 14)),
                      Flexible(
                        child: Text((_coach['academy'] as String?) ?? '',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 14)),
                      ),
                    ]),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Card 1: Create League ──
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                          const CreateLeagueScreen())),
                  child: ClipRRect(
                    borderRadius:
                    BorderRadius.circular(20),
                    child: Stack(children: [
                      Positioned.fill(
                        child: Image.network(
                          'https://i.ibb.co/W4FHNPtR/1ab.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(
                                  color: const Color(
                                      0xFF0A0A1A)),
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                const Color(0xFF0A0A1A)
                                    .withOpacity(0.92),
                                const Color(0xFF0A0A1A)
                                    .withOpacity(0.5),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: const Color(0xFF00C853)
                                  .withOpacity(0.5),
                              width: 1.5),
                          borderRadius:
                          BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: const Color(
                                    0xFF00C853)
                                    .withOpacity(0.15),
                                borderRadius:
                                BorderRadius.circular(
                                    12),
                                border: Border.all(
                                    color: const Color(
                                        0xFF00C853)
                                        .withOpacity(0.3)),
                              ),
                              child: const Icon(
                                  Icons.add_circle_outline,
                                  color: Color(0xFF00C853),
                                  size: 24),
                            ),
                            const SizedBox(height: 16),
                            const Text('Create League',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight:
                                    FontWeight.w800)),
                            const SizedBox(height: 6),
                            const Text(
                                'Create your first league and\nstart tracking player performance.',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    height: 1.5)),
                            const SizedBox(height: 16),
                            Row(children: [
                              const Text('+ Create League',
                                  style: TextStyle(
                                      color:
                                      Color(0xFF00C853),
                                      fontSize: 14,
                                      fontWeight:
                                      FontWeight.w700)),
                              const SizedBox(width: 12),
                              Container(
                                width: 36, height: 36,
                                decoration:
                                const BoxDecoration(
                                  color: Color(0xFF00C853),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white,
                                    size: 18),
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Card 2: View Leagues ──
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                          const CoachLeaguesScreen())),
                  child: ClipRRect(
                    borderRadius:
                    BorderRadius.circular(20),
                    child: Stack(children: [
                      Positioned.fill(
                        child: Image.network(
                          'https://i.ibb.co/9mWLqgf2/1ac.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(
                                  color:
                                  const Color(0xFF111111)),
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                const Color(0xFF111111)
                                    .withOpacity(0.92),
                                const Color(0xFF111111)
                                    .withOpacity(0.5),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.white12),
                          borderRadius:
                          BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius:
                                BorderRadius.circular(
                                    12),
                                border: Border.all(
                                    color: Colors.white12),
                              ),
                              child: const Icon(
                                  Icons.people_outline,
                                  color: Colors.white60,
                                  size: 24),
                            ),
                            const SizedBox(height: 16),
                            const Text('View Leagues',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight:
                                    FontWeight.w800)),
                            const SizedBox(height: 6),
                            const Text(
                                'View and manage\nyour existing leagues.',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    height: 1.5)),
                            const SizedBox(height: 16),
                            Row(children: [
                              const Text('View Leagues',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight:
                                      FontWeight.w700)),
                              const SizedBox(width: 12),
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white24),
                                ),
                                child: const Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white60,
                                    size: 18),
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Card 3: Get Certified ──
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                          const CoachCertificationScreen())),
                  child: ClipRRect(
                    borderRadius:
                    BorderRadius.circular(20),
                    child: Stack(children: [
                      Positioned.fill(
                        child: Image.network(
                          'https://i.ibb.co/cXMzhM7N/1ad.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(
                                  color:
                                  const Color(0xFF0D0900)),
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                const Color(0xFF0D0900)
                                    .withOpacity(0.92),
                                const Color(0xFF0D0900)
                                    .withOpacity(0.5),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: const Color(0xFFFFB300)
                                  .withOpacity(0.5),
                              width: 1.5),
                          borderRadius:
                          BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: const Color(
                                    0xFFFFB300)
                                    .withOpacity(0.15),
                                borderRadius:
                                BorderRadius.circular(
                                    12),
                                border: Border.all(
                                    color: const Color(
                                        0xFFFFB300)
                                        .withOpacity(0.3)),
                              ),
                              child: const Icon(
                                  Icons.star_outline,
                                  color: Color(0xFFFFB300),
                                  size: 24),
                            ),
                            const SizedBox(height: 16),
                            const Text('Get Certified',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight:
                                    FontWeight.w800)),
                            const SizedBox(height: 6),
                            const Text(
                                'Become a verified SportyQo Coach\nand build player trust.',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    height: 1.5)),
                            const SizedBox(height: 16),
                            Row(children: [
                              const Text('Get Certified',
                                  style: TextStyle(
                                      color:
                                      Color(0xFFFFB300),
                                      fontSize: 14,
                                      fontWeight:
                                      FontWeight.w700)),
                              const SizedBox(width: 12),
                              Container(
                                width: 36, height: 36,
                                decoration:
                                const BoxDecoration(
                                  color: Color(0xFFFFB300),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                    Icons.arrow_forward,
                                    color: Colors.black,
                                    size: 18),
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ]),
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

  void _showProfileQuick(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70, height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFF00C853),
                    width: 2),
                color: const Color(0xFF1A1A1A),
              ),
              child: const Icon(Icons.person,
                  size: 36, color: Colors.white38),
            ),
            const SizedBox(height: 12),
            Text((_coach['full_name'] as String?) ?? 'Coach',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            Text(
                '${_coach['role_title'] ?? 'Coach'} • ${_coach['academy'] ?? ''}',
                style: const TextStyle(
                    color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceAround,
              children: [
                _StatChip(
                    label: 'Players',
                    value: '${_stats['players'] ?? 0}'),
                _StatChip(
                    label: 'Matches',
                    value: '${_stats['matches'] ?? 0}'),
                _StatChip(
                    label: 'Win Rate',
                    value:
                    '${(((_stats['win_rate'] as num?) ?? 0) * 100).round()}%'),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Coach Notification Screen ─────────────────────────────────────────

class _CoachNotificationScreen extends StatefulWidget {
  const _CoachNotificationScreen();

  @override
  State<_CoachNotificationScreen> createState() =>
      _CoachNotificationScreenState();
}

class _CoachNotificationScreenState
    extends State<_CoachNotificationScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await NotificationService.list();
      final items = (res['items'] as List<dynamic>)
          .map((n) => notificationToTile(n as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() {
        _notifications = items;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications
        .where((n) => !(n['read'] as bool))
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                20, 16, 20, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(children: [
                  const Text('Notifications',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                  if (unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: const Color(0xFF00C853),
                          borderRadius:
                          BorderRadius.circular(20)),
                      child: Text('$unreadCount',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight:
                              FontWeight.w700)),
                    ),
                  ],
                ]),
              ),
              GestureDetector(
                onTap: () {
                  NotificationService.markAllRead();
                  setState(() {
                    _notifications = _notifications
                        .map((n) =>
                    {...n, 'read': true})
                        .toList();
                  });
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(
                    content:
                    Text('All marked as read ✅'),
                    backgroundColor: Color(0xFF00C853),
                    duration: Duration(seconds: 2),
                  ));
                },
                child: const Text('Mark all read',
                    style: TextStyle(
                        color: Color(0xFF00C853),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(
                child: CircularProgressIndicator())
                : _notifications.isEmpty
                ? const Center(
                child: Text('No notifications yet',
                    style: TextStyle(
                        color: Colors.white38)))
                : ListView.separated(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20),
              itemCount: _notifications.length,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final n = _notifications[i];
                return GestureDetector(
                  onTap: () {
                    final id = _notifications[i]['id'] as String?;
                    if (id != null &&
                        _notifications[i]['read'] != true) {
                      NotificationService.markRead(id);
                    }
                    setState(() {
                      _notifications[i] = {
                        ..._notifications[i],
                        'read': true,
                      };
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: n['read'] as bool
                          ? const Color(0xFF111111)
                          : const Color(0xFF00C853)
                          .withOpacity(0.08),
                      borderRadius:
                      BorderRadius.circular(14),
                      border: Border.all(
                        color: n['read'] as bool
                            ? Colors.white10
                            : const Color(0xFF00C853)
                            .withOpacity(0.3),
                      ),
                    ),
                    child: Row(children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: (n['color'] as Color)
                              .withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                            n['icon'] as IconData,
                            color: n['color'] as Color,
                            size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                  child: Text(
                                      n['title']
                                      as String,
                                      style: const TextStyle(
                                          color:
                                          Colors.white,
                                          fontWeight:
                                          FontWeight
                                              .w700,
                                          fontSize: 14))),
                              if (!(n['read'] as bool))
                                Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                        color: Color(
                                            0xFF00C853),
                                        shape: BoxShape
                                            .circle)),
                            ]),
                            const SizedBox(height: 3),
                            Text(
                                n['subtitle'] as String,
                                style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                    height: 1.4)),
                            const SizedBox(height: 4),
                            Text(n['time'] as String,
                                style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                    ]),
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

// ── Widgets ───────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label, value;
  const _StatChip(
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
              color: Colors.white38, fontSize: 12)),
    ]);
  }
}

// ── Coach Profile Photo (full screen, like player) ────────────────────

class _CoachProfileImageScreen extends StatefulWidget {
  const _CoachProfileImageScreen();

  @override
  State<_CoachProfileImageScreen> createState() =>
      _CoachProfileImageScreenState();
}

class _CoachProfileImageScreenState
    extends State<_CoachProfileImageScreen> {
  final _picker = ImagePicker();
  String? _avatarUrl = Session.avatarUrl;
  bool _uploading = false;

  String _mimeFor(XFile x) {
    if (x.mimeType != null && x.mimeType!.isNotEmpty) {
      return x.mimeType!;
    }
    final n = x.name.toLowerCase();
    if (n.endsWith('.png')) return 'image/png';
    if (n.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _pick(ImageSource source) async {
    if (_uploading) return;
    try {
      final x = await _picker.pickImage(
          source: source,
          maxWidth: 1080,
          maxHeight: 1080,
          imageQuality: 85);
      if (x == null) return;
      setState(() => _uploading = true);
      final bytes = await x.readAsBytes();
      final mime = _mimeFor(x).split('/');
      final res = await CoachService.updateProfile(
        avatar: http.MultipartFile.fromBytes(
          'avatar',
          bytes,
          filename:
          x.name.isNotEmpty ? x.name : 'avatar.jpg',
          contentType: MediaType(mime[0], mime[1]),
        ),
      );
      await UserService.me();
      if (!mounted) return;
      setState(() {
        _avatarUrl = (res['avatar_url'] as String?) ??
            Session.avatarUrl;
        _uploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Profile photo updated'),
              backgroundColor: Color(0xFF00C853)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not update photo: $e'),
          backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding:
            const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              const Text('Profile Photo',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
            ]),
          ),
          const Spacer(),
          Stack(
              alignment: Alignment.center,
              children: [
                Builder(builder: (context) {
                  final resolved =
                  ApiConfig.resolveMediaUrl(
                      _avatarUrl);
                  final initial = Text(
                      Session.firstName.isNotEmpty
                          ? Session.firstName[0]
                          .toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 56,
                          fontWeight: FontWeight.w800));
                  return Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF13132B),
                      border: Border.all(
                          color:
                          const Color(0xFF00C853),
                          width: 3),
                    ),
                    child: ClipOval(
                      child: resolved != null &&
                          resolved.isNotEmpty
                          ? Image.network(resolved,
                          fit: BoxFit.cover,
                          width: 160,
                          height: 160,
                          errorBuilder:
                              (_, __, ___) => Center(
                              child: initial))
                          : Center(child: initial),
                    ),
                  );
                }),
                if (_uploading)
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black
                            .withOpacity(0.55)),
                    child: const Center(
                        child:
                        CircularProgressIndicator(
                            color:
                            Color(0xFF00C853))),
                  ),
              ]),
          const SizedBox(height: 24),
          Text(Session.fullName,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const Text('Coach',
              style: TextStyle(
                  color: Color(0xFF00C853),
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const Spacer(),
          Padding(
            padding:
            const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _uploading
                      ? null
                      : () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt,
                      color: Colors.white, size: 20),
                  label: const Text('Take Photo',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xFF00C853),
                    padding: const EdgeInsets.symmetric(
                        vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _uploading
                      ? null
                      : () =>
                      _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library,
                      color: Colors.white, size: 20),
                  label: const Text(
                      'Choose from Gallery',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xFF00C853),
                    padding: const EdgeInsets.symmetric(
                        vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(14)),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}