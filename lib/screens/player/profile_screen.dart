import 'package:flutter/material.dart';
import '../../api/api_config.dart';
import '../../api/services.dart';
import '../../theme/app_theme.dart';
import '../auth/choose_role_screen.dart';

/// The player's own profile — real data from GET /users/{me}/profile and
/// GET /players/dashboard (Qo points ledger). No more mock "Aarav Mehta".
class ProfileScreen extends StatefulWidget {
  final String? playerId;
  const ProfileScreen({super.key, this.playerId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _p;    // /users/{id}/profile
  Map<String, dynamic>? _dash; // /players/dashboard (recent_points)
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        UserService.profile(Session.userId),
        PlayerService.dashboard(),
      ]);
      if (!mounted) return;
      setState(() {
        _p = results[0];
        _dash = results[1];
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _name => (_p?['name'] as String?) ?? Session.fullName;
  String get _sqid =>
      (_p?['player_id'] as String?) ?? widget.playerId ?? Session.playerId ?? '';

  String _initials(String name) {
    final parts =
    name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '👤';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final recos = ((_p?['recommendations'] as List<dynamic>?) ?? const [])
        .cast<Map<String, dynamic>>();
    final recentPoints =
    ((_dash?['recent_points'] as List<dynamic>?) ?? const [])
        .cast<Map<String, dynamic>>();
    final breakdown =
        (_dash?['points_breakdown'] as Map<String, dynamic>?) ?? const {};
    final counts = (_p?['counts'] as Map<String, dynamic>?) ?? const {};

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: _loading
            ? const Center(
            child: CircularProgressIndicator(color: AppColors.primary))
            : Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // ── Profile Info ──
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.primary,
                                  width: 2),
                              color: const Color(0xFF1A1A3A),
                            ),
                            child: Center(
                                child: Text(_initials(_name),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight:
                                        FontWeight.w800))),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Flexible(
                                    child: Text(_name,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight:
                                            FontWeight.w800)),
                                  ),
                                  if (_p?['verified'] == true) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.verified,
                                        color: AppColors.primary,
                                        size: 16),
                                  ],
                                ]),
                                if (_sqid.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(_sqid,
                                      style: const TextStyle(
                                          color: Color(0xFF00C853),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5)),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                    (_p?['sport_line'] as String?) ??
                                        'Player',
                                    style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 13)),
                                if ((_p?['location'] as String?)
                                    ?.isNotEmpty ==
                                    true) ...[
                                  const SizedBox(height: 8),
                                  Row(children: [
                                    const Icon(
                                        Icons.location_on_outlined,
                                        color: Colors.white38,
                                        size: 13),
                                    const SizedBox(width: 4),
                                    Text(_p!['location'] as String,
                                        style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12)),
                                  ]),
                                ],
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showSettings(context),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius:
                                  BorderRadius.circular(10)),
                              child: const Icon(
                                  Icons.settings_outlined,
                                  color: Colors.white,
                                  size: 20),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Qo Points (real ledger) ──
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F0F2A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.bolt,
                                  color: AppColors.primary,
                                  size: 18),
                              const SizedBox(width: 8),
                              const Text('Qo Points',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                              const Spacer(),
                              Text('${_p?['qo_score'] ?? 0}',
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 20)),
                            ]),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceAround,
                              children: [
                                _MiniBreak(
                                    label: 'Bonus',
                                    value:
                                    '${breakdown['bonus'] ?? 0}'),
                                _sep(),
                                _MiniBreak(
                                    label: 'Match',
                                    value:
                                    '${breakdown['match'] ?? 0}'),
                                _sep(),
                                _MiniBreak(
                                    label: 'Coach',
                                    value:
                                    '${breakdown['coach'] ?? 0}'),
                                _sep(),
                                _MiniBreak(
                                    label: 'Community',
                                    value:
                                    '${breakdown['community'] ?? 0}'),
                              ],
                            ),
                            if (recentPoints.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Divider(
                                  color: Colors.white10, height: 1),
                              const SizedBox(height: 8),
                              ...recentPoints.take(3).map((e) {
                                final pts =
                                    (e['points'] as num?)?.toInt() ??
                                        0;
                                return Padding(
                                  padding: const EdgeInsets
                                      .symmetric(vertical: 6),
                                  child: Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                            (e['reason']
                                            as String?) ??
                                                '',
                                            style: const TextStyle(
                                                color:
                                                Colors.white70,
                                                fontSize: 12,
                                                height: 1.3)),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                          pts >= 0
                                              ? '+$pts'
                                              : '$pts',
                                          style: TextStyle(
                                              color: pts >= 0
                                                  ? const Color(
                                                  0xFF00C853)
                                                  : AppColors.error,
                                              fontSize: 13,
                                              fontWeight:
                                              FontWeight.w800)),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Community counts ──
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F0F2A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceAround,
                          children: [
                            _MiniBreak(
                                label: 'Posts',
                                value: '${counts['posts'] ?? 0}'),
                            _sep(),
                            _MiniBreak(
                                label: 'Followers',
                                value:
                                '${counts['followers'] ?? 0}'),
                            _sep(),
                            _MiniBreak(
                                label: 'Following',
                                value:
                                '${counts['following'] ?? 0}'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Recommendations (real) ──
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F0F2A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Row(children: const [
                              Icon(Icons.star,
                                  color: Colors.amber, size: 18),
                              SizedBox(width: 8),
                              Text('Recommendations',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                            ]),
                            const SizedBox(height: 14),
                            if (recos.isEmpty)
                              const Text(
                                  'No recommendations yet.\nCoaches can recommend you after matches.',
                                  style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 13,
                                      height: 1.5))
                            else
                              ...recos.asMap().entries.map((entry) {
                                final r = entry.value;
                                return Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    if (entry.key > 0)
                                      const Divider(
                                          color: Colors.white10,
                                          height: 20),
                                    _RecommendationTile(
                                      initials: _initials(
                                          (r['coach_name']
                                          as String?) ??
                                              'C'),
                                      color:
                                      const Color(0xFF7B2FFF),
                                      name: (r['coach_name']
                                      as String?) ??
                                          'Coach',
                                      role: (r['coach_role']
                                      as String?) ??
                                          'Coach',
                                      quote: (r['note']
                                      as String?) ??
                                          'Recommended you on SportyQo.',
                                    ),
                                  ],
                                );
                              }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sep() => Container(width: 1, height: 30, color: Colors.white10);

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F0F2A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Settings',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading:
              const Icon(Icons.logout, color: AppColors.error),
              title: const Text('Logout',
                  style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                _showLogout(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0F0F2A),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout',
            style:
            TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to logout?',
            style: TextStyle(color: Colors.white54)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () async {
              await AuthService.logout(); // revokes the refresh token
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (_) => const ChooseRoleScreen()),
                      (route) => false,
                );
              }
            },
            style:
            ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child:
            const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Mini breakdown stat ───────────────────────────────────────────────
class _MiniBreak extends StatelessWidget {
  final String label, value;
  const _MiniBreak({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(label,
          style: const TextStyle(color: Colors.white38, fontSize: 11)),
    ]);
  }
}

// ── Recommendation Tile ───────────────────────────────────────────────
class _RecommendationTile extends StatelessWidget {
  final String initials, name, role, quote;
  final Color color;

  const _RecommendationTile({
    required this.initials,
    required this.name,
    required this.role,
    required this.quote,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(
                child: Text(initials,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                Text(role,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Text('"$quote"',
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontStyle: FontStyle.italic,
                height: 1.4)),
      ],
    );
  }
}
