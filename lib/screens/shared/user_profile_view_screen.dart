import 'package:flutter/material.dart';
import '../../api/services.dart';
import '../../api/ui_helpers.dart';
import '../../theme/app_theme.dart';

/// Read-only profile of any user, loaded from GET /users/{id}/profile.
/// Opened when a coach taps a player's name in Performance, and reusable
/// anywhere else a profile needs to be shown.
class UserProfileViewScreen extends StatefulWidget {
  final String userId;
  final String? fallbackName;
  const UserProfileViewScreen(
      {super.key, required this.userId, this.fallbackName});

  @override
  State<UserProfileViewScreen> createState() => _UserProfileViewScreenState();
}

class _UserProfileViewScreenState extends State<UserProfileViewScreen> {
  Map<String, dynamic>? _p;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await UserService.profile(widget.userId);
      if (!mounted) return;
      setState(() {
        _p = res;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  String get _name =>
      (_p?['name'] as String?) ?? widget.fallbackName ?? 'Player';

  String _initials(String name) {
    final parts =
    name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final counts = (_p?['counts'] as Map<String, dynamic>?) ?? const {};
    final recos =
    ((_p?['recommendations'] as List<dynamic>?) ?? const [])
        .cast<Map<String, dynamic>>();
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
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
              const Text('Player Profile',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
            ]),
          ),
          Expanded(
            child: _loading
                ? const Center(
                child:
                CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                ? Center(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Couldn\'t load this profile.',
                          style: TextStyle(color: Colors.white54)),
                      const SizedBox(height: 12),
                      TextButton(
                          onPressed: _load,
                          child: const Text('Retry')),
                    ]))
                : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary
                                .withOpacity(0.15),
                            border: Border.all(
                                color: AppColors.primary
                                    .withOpacity(0.5),
                                width: 2),
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
                                            FontWeight.w800))),
                                if (_p?['verified'] == true) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.verified,
                                      color: AppColors.primary,
                                      size: 16),
                                ],
                              ]),
                              if ((_p?['player_id'] as String?)
                                  ?.isNotEmpty ==
                                  true) ...[
                                const SizedBox(height: 3),
                                Text(_p!['player_id'] as String,
                                    style: const TextStyle(
                                        color: Color(0xFF00C853),
                                        fontSize: 13,
                                        fontWeight:
                                        FontWeight.w600,
                                        letterSpacing: 0.5)),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                  (_p?['sport_line'] as String?) ??
                                      '',
                                  style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 13)),
                              if ((_p?['location'] as String?)
                                  ?.isNotEmpty ==
                                  true) ...[
                                const SizedBox(height: 6),
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
                      ]),
                  const SizedBox(height: 20),

                  // Qo Score + counts
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
                        _Stat(
                            label: 'Qo Score',
                            value: '${_p?['qo_score'] ?? 0}',
                            highlight: true),
                        _div(),
                        _Stat(
                            label: 'Posts',
                            value: '${counts['posts'] ?? 0}'),
                        _div(),
                        _Stat(
                            label: 'Followers',
                            value: '${counts['followers'] ?? 0}'),
                        _div(),
                        _Stat(
                            label: 'Following',
                            value: '${counts['following'] ?? 0}'),
                      ],
                    ),
                  ),

                  if ((_p?['bio'] as String?)?.isNotEmpty ==
                      true) ...[
                    const SizedBox(height: 16),
                    Text(_p!['bio'] as String,
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.5)),
                  ],

                  const SizedBox(height: 16),

                  // Recommendations (real, from coaches)
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
                        const SizedBox(height: 12),
                        if (recos.isEmpty)
                          const Text('No recommendations yet.',
                              style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 13))
                        else
                          ...recos.map((r) => Padding(
                            padding: const EdgeInsets.only(
                                bottom: 12),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                    (r['coach_name']
                                    as String?) ??
                                        'Coach',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight:
                                        FontWeight.w700,
                                        fontSize: 13)),
                                if ((r['coach_role']
                                as String?)
                                    ?.isNotEmpty ==
                                    true)
                                  Text(
                                      r['coach_role']
                                      as String,
                                      style: const TextStyle(
                                          color:
                                          Colors.white38,
                                          fontSize: 11)),
                                if ((r['note'] as String?)
                                    ?.isNotEmpty ==
                                    true) ...[
                                  const SizedBox(height: 4),
                                  Text(r['note'] as String,
                                      style: const TextStyle(
                                          color:
                                          Colors.white70,
                                          fontSize: 12,
                                          height: 1.4)),
                                ],
                              ],
                            ),
                          )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _div() => Container(width: 1, height: 34, color: Colors.white10);
}

class _Stat extends StatelessWidget {
  final String label, value;
  final bool highlight;
  const _Stat(
      {required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: TextStyle(
              color: highlight ? AppColors.primary : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800)),
      const SizedBox(height: 3),
      Text(label,
          style: const TextStyle(color: Colors.white38, fontSize: 11)),
    ]);
  }
}
