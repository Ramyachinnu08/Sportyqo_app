import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../../api/api_config.dart';
import '../../api/mappers.dart';
import '../../api/services.dart';
import '../../widgets/app_video_player.dart';
import '../../widgets/create_post_screen.dart';
import '../legal/legal_screen.dart';
import '../auth/choose_role_screen.dart';
import 'package:flutter/services.dart';

class PlaybookScreen extends StatefulWidget {
  const PlaybookScreen({super.key});

  @override
  State<PlaybookScreen> createState() =>
      _PlaybookScreenState();
}

class _PlaybookScreenState extends State<PlaybookScreen> {
  int _tabIndex = 0;

  Map<String, dynamic>? _playbook;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _deleteTabItem(
      Map<String, dynamic> item) async {
    final pid = item['post_id'] as String?;
    if (pid == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete this post?',
            style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800)),
        content: const Text(
            'This removes it from your Playbook and the Dugout feed. This cannot be undone.',
            style: TextStyle(
                color: Colors.white54, fontSize: 13, height: 1.4)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent),
            child: const Text('Delete',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await FeedService.deletePost(pid);
      if (!mounted) return;
      _load();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Post deleted'),
          backgroundColor: Color(0xFF7B2FFF)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Could not delete: $e'),
            backgroundColor: Colors.redAccent));
      }
    }
  }

  Future<void> _load() async {
    try {
      final pb = await PlayerService.playbook();
      if (mounted) setState(() => _playbook = pb);
    } catch (_) {}
  }

  Map<String, dynamic> get _profile =>
      (_playbook?['profile'] as Map<String, dynamic>?) ?? const {};
  Map<String, dynamic> get _stats =>
      (_playbook?['stats'] as Map<String, dynamic>?) ?? const {};
  Map<String, dynamic> get _qo =>
      (_playbook?['qo_score'] as Map<String, dynamic>?) ?? const {};

  List<Map<String, dynamic>> get _recos =>
      ((_playbook?['coach_recommendations'] as List<dynamic>?) ??
          const [])
          .cast<Map<String, dynamic>>();

  List<Map<String, dynamic>> _tab(String key) =>
      ((_playbook?['tabs'] as Map<String, dynamic>?)?[key]
      as List<dynamic>? ??
          const [])
          .map((raw) {
        final m = raw as Map<String, dynamic>;
        return <String, dynamic>{
          'title': m['title'] ?? '',
          'subtitle': m['subtitle'] ?? '',
          'date': m['date'] ?? '',
          'type': m['type'] ?? 'image',
          'post_id': m['post_id'],
          'image': ApiConfig.resolveMediaUrl(m['url'] as String?),
          'thumbnail': ApiConfig.resolveMediaUrl(
              m['thumbnail_url'] as String?),
        };
      }).toList();

  List<Map<String, dynamic>> get _currentContent {
    switch (_tabIndex) {
      case 0: return _tab('playing');
      case 1: return _tab('certificates');
      case 2: return _tab('team');
      case 3: return _tab('trophies');
      default: return _tab('playing');
    }
  }

  // ── Settings ──
  void _showSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => const _SettingsScreen()),
    );
  }

  // ── Edit Profile ──
  void _showEditProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => const _EditProfileScreen()),
    );
  }

  // ── Upload Dialog ──
  String get _activeTabCategory {
    switch (_tabIndex) {
      case 1: return 'certificates';
      case 2: return 'team';
      case 3: return 'trophies';
      default: return 'playing';
    }
  }

  Future<void> _startPost(XFile? file,
      {required bool isVideo}) async {
    if (file == null || !mounted) return;
    final posted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => CreatePostScreen(
              file: file,
              isVideo: isVideo,
              initialCategory: _activeTabCategory)),
    );
    if (posted == true && mounted) {
      _load(); // refresh grids so the new post appears
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Posted! It now shows in your Playbook and in the Dugout feed.'),
          backgroundColor: Color(0xFF7B2FFF)));
    }
  }

  void _showUploadDialog(BuildContext context) {
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
            const Text('Add New Content',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                  child: _UploadOption(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: () async {
                        Navigator.pop(context);
                        final x = await ImagePicker()
                            .pickImage(
                            source: ImageSource.camera,
                            maxWidth: 1920,
                            imageQuality: 88);
                        _startPost(x, isVideo: false);
                      })),
              const SizedBox(width: 12),
              Expanded(
                  child: _UploadOption(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: () async {
                        Navigator.pop(context);
                        final x = await ImagePicker()
                            .pickMedia(
                            maxWidth: 1920,
                            imageQuality: 88);
                        if (x == null) return;
                        final n = x.name.toLowerCase();
                        final vid = (x.mimeType ?? '')
                            .startsWith('video/') ||
                            n.endsWith('.mp4') ||
                            n.endsWith('.mov') ||
                            n.endsWith('.mkv') ||
                            n.endsWith('.webm');
                        _startPost(x, isVideo: vid);
                      })),
              const SizedBox(width: 12),
              Expanded(
                  child: _UploadOption(
                      icon: Icons.videocam,
                      label: 'Video',
                      onTap: () async {
                        Navigator.pop(context);
                        final x = await ImagePicker()
                            .pickVideo(
                            source: ImageSource.camera,
                            maxDuration: const Duration(
                                minutes: 3));
                        _startPost(x, isVideo: true);
                      })),
            ]),
            const SizedBox(height: 8),
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel',
                    style:
                    TextStyle(color: Colors.white38))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    20, 16, 20, 0),
                child: Row(children: [
                  const Text('Playbook',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                            const _NotificationScreen())),
                    child: Stack(children: [
                      const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 26),
                      Positioned(
                        top: 0, right: 0,
                        child: Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF7B2FFF),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => _showSettings(context),
                    child: const Icon(
                        Icons.settings_outlined,
                        color: Colors.white,
                        size: 26),
                  ),
                ]),
              ),

              const SizedBox(height: 20),

              // ── Profile Card ──
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20),
                child: Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Stack(children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color:
                              const Color(0xFF7B2FFF),
                              width: 2.5),
                        ),
                        child: ClipOval(
                          child: Builder(builder: (context) {
                            final u = ApiConfig.resolveMediaUrl(
                                _profile['avatar_url']
                                as String?);
                            final initial = Container(
                              color:
                              const Color(0xFF1A1A1A),
                              child: Center(
                                  child: Text(
                                      ((_profile['full_name']
                                      as String?) ??
                                          '')
                                          .isNotEmpty
                                          ? (_profile['full_name']
                                      as String)[0]
                                          .toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 34,
                                          fontWeight:
                                          FontWeight
                                              .w800))),
                            );
                            return u != null && u.isNotEmpty
                                ? Image.network(
                              u,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) =>
                              initial,
                            )
                                : initial;
                          }),
                        ),
                      ),
                      Positioned(
                        top: 0, left: 0,
                        child: Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7B2FFF),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color:
                                const Color(0xFF0A0A0A),
                                width: 1.5),
                          ),
                          child: const Icon(Icons.check,
                              color: Colors.white,
                              size: 14),
                        ),
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: GestureDetector(
                          onTap: () =>
                              _showEditProfile(context),
                          child: Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color:
                              const Color(0xFF7B2FFF),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white,
                                  width: 1.5),
                            ),
                            child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 14),
                          ),
                        ),
                      ),
                    ]),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                              (_profile['full_name'] as String?) ??
                                  Session.fullName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight:
                                  FontWeight.w800)),
                          Text(
                              [
                                _profile['sport'],
                                _profile['sub_role'],
                              ]
                                  .whereType<String>()
                                  .where((e) => e.isNotEmpty)
                                  .join(' • '),
                              style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13)),
                          const SizedBox(height: 8),
                          Row(children: [
                            const Icon(
                                Icons.badge_outlined,
                                color: Colors.white38,
                                size: 13),
                            const SizedBox(width: 6),
                            Text(
                                (_profile['player_id'] as String?) ??
                                    (Session.playerId ?? ''),
                                style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12)),
                          ]),
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(
                                Icons.location_on_outlined,
                                color: Colors.white38,
                                size: 13),
                            SizedBox(width: 6),
                            Text(
                                (_profile['location'] as String?) ?? '—',
                                style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12)),
                          ]),
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.shield_outlined,
                                color: Colors.white38,
                                size: 13),
                            SizedBox(width: 6),
                            Text(
                                (_profile['age_group'] as String?) ?? '',
                                style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12)),
                          ]),
                        ],
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius:
                        BorderRadius.circular(12),
                        border: Border.all(
                            color:
                            const Color(0xFF7B2FFF)
                                .withOpacity(0.5)),
                      ),
                      child: Column(children: [
                        Text('Qo Score',
                            style: TextStyle(
                                color: Color(0xFF7B2FFF),
                                fontSize: 10,
                                fontWeight:
                                FontWeight.w600)),
                        Text('${_qo['current'] ?? 0}',
                            style: TextStyle(
                                color: Color(0xFF7B2FFF),
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                height: 1.1)),
                        Text('Rank',
                            style: TextStyle(
                                color: Colors.white38,
                                fontSize: 10)),
                        Text(_qo['rank'] == null ? '—' : '#${_qo['rank']}',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight:
                                FontWeight.w800)),
                        Text('in ${_qo['category'] ?? 'Cricket'}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white38,
                                fontSize: 9)),
                      ]),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── About (real bio; hidden when empty) ──
              if (((_profile['about'] as String?) ?? '')
                  .trim()
                  .isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(12),
                      border:
                      Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        const Text('About',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        const SizedBox(height: 6),
                        Text(
                            (_profile['about'] as String).trim(),
                            style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                                height: 1.5)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],

              // ── Stats (tap to open lists) ──
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20),
                child: Row(children: [
                  _StatItem(
                      value: '${_stats['followers'] ?? 0}',
                      label: 'Fans',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                              const _ConnectionsScreen(
                                  initialTab: 0)))),
                  _Divider(),
                  _StatItem(
                      value: '${_stats['following'] ?? 0}',
                      label: 'Tracking',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                              const _ConnectionsScreen(
                                  initialTab: 1)))),
                  _Divider(),
                  _StatItem(
                      value: '${_stats['teams'] ?? 0}',
                      label: 'Teams',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                              const _TeamsListScreen()))),
                  _Divider(),
                  _StatItem(
                      value: '${_stats['tournaments'] ?? 0}',
                      label: 'Tournaments'),
                ]),
              ),

              const SizedBox(height: 20),

              Container(
                  height: 1, color: Colors.white10),

              // ── Tabs ──
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20),
                child: Row(children: [
                  _Tab(
                      icon: Icons.directions_run,
                      label: 'Playing',
                      isActive: _tabIndex == 0,
                      onTap: () => setState(
                              () => _tabIndex = 0)),
                  _Tab(
                      icon: Icons
                          .workspace_premium_outlined,
                      label: 'Certificates',
                      isActive: _tabIndex == 1,
                      onTap: () => setState(
                              () => _tabIndex = 1)),
                  _Tab(
                      icon: Icons.people_outline,
                      label: 'Team',
                      isActive: _tabIndex == 2,
                      onTap: () => setState(
                              () => _tabIndex = 2)),
                  _Tab(
                      icon: Icons.emoji_events_outlined,
                      label: 'Trophies',
                      isActive: _tabIndex == 3,
                      onTap: () => setState(
                              () => _tabIndex = 3)),
                ]),
              ),

              Container(
                  height: 1, color: Colors.white10),

              const SizedBox(height: 16),

              // ── Coach Recommendations (from backend;
              //    hidden until a coach writes one) ──
              if (_recos.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const Text('Coach Recommendations',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                      const SizedBox(height: 12),
                      ..._recos.map((r) => Padding(
                        padding: const EdgeInsets.only(
                            bottom: 12),
                        child: _RecommendationCard(
                            reco: r),
                      )),
                    ],
                  ),
                ),

                const SizedBox(height: 4),
              ],

              // ── Content Grid ──
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics:
                  const NeverScrollableScrollPhysics(),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _currentContent.length,
                  itemBuilder: (context, i) {
                    final item = _currentContent[i];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              _VideoPlayerScreen(
                                  item: item),
                        ),
                      ),
                      onLongPress: () =>
                          _deleteTabItem(item),
                      child: _VideoCard(item: item),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // ── Add New ──
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20),
                child: GestureDetector(
                  onTap: () =>
                      _showUploadDialog(context),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius:
                      BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.white10),
                    ),
                    child: Row(children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius:
                          BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.white12),
                        ),
                        child: const Icon(Icons.add,
                            color: Colors.white,
                            size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: const [
                            Text('Add New',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight:
                                    FontWeight.w700,
                                    fontSize: 14)),
                            Text(
                                'Add match videos, highlights and performances',
                                maxLines: 2,
                                overflow:
                                TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: Colors.white38),
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
}

// ── Settings Screen (Instagram-style, continuous) ─────────────────────

class _SettingsScreen extends StatefulWidget {
  const _SettingsScreen();

  @override
  State<_SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState extends State<_SettingsScreen> {
  bool _notificationsOn = true;
  bool _darkMode = true;
  bool _privateProfile = false;
  bool _locationOn = true;
  bool _emailAlerts = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final st = await UserService.settings();
      if (!mounted) return;
      setState(() {
        _notificationsOn =
            st['notifications_enabled'] as bool? ?? _notificationsOn;
        _darkMode = st['dark_mode'] as bool? ?? _darkMode;
        _privateProfile =
            st['private_profile'] as bool? ?? _privateProfile;
        _locationOn =
            st['location_access'] as bool? ?? _locationOn;
        _emailAlerts = st['email_alerts'] as bool? ?? _emailAlerts;
      });
    } catch (_) {}
  }

  void _push(String key, bool value) {
    UserService.updateSettings({key: value});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding:
            const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              const Text('Settings',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const _SectionHeader(title: 'Profile'),
                  _SettingsRow(
                    icon: Icons.edit_outlined,
                    title: 'Edit Profile',
                    subtitle:
                    'Update your name, photo and details',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                            const _EditProfileScreen())),
                  ),
                  _SettingsRow(
                    icon: Icons.share_outlined,
                    title: 'Share Profile',
                    subtitle:
                    'Share your player profile link',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                            const _ShareProfileScreen())),
                  ),
                  _SettingsRow(
                    icon: Icons.badge_outlined,
                    title: 'Player ID',
                    subtitle: Session.playerId ?? '—',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                            const _PlayerIdScreen())),
                  ),
                  const _SectionDivider(),
                  const _SectionHeader(
                      title: 'Preferences'),
                  _SettingsRow(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle: 'Get match & league alerts',
                    trailing: Switch(
                      value: _notificationsOn,
                      onChanged: (v) {
                        setState(
                                () => _notificationsOn = v);
                        _push('notifications_enabled', v);
                      },
                      activeColor:
                      const Color(0xFF7B2FFF),
                    ),
                  ),
                  _SettingsRow(
                    icon: Icons.dark_mode_outlined,
                    title: 'Dark Mode',
                    subtitle: 'Switch app appearance',
                    trailing: Switch(
                      value: _darkMode,
                      onChanged: (v) {
                        setState(() => _darkMode = v);
                        _push('dark_mode', v);
                      },
                      activeColor:
                      const Color(0xFF7B2FFF),
                    ),
                  ),
                  _SettingsRow(
                    icon: Icons.email_outlined,
                    title: 'Email Alerts',
                    subtitle: 'Receive updates via email',
                    trailing: Switch(
                      value: _emailAlerts,
                      onChanged: (v) {
                        setState(() => _emailAlerts = v);
                        _push('email_alerts', v);
                      },
                      activeColor:
                      const Color(0xFF7B2FFF),
                    ),
                  ),
                  const _SectionDivider(),
                  const _SectionHeader(title: 'Privacy'),
                  _SettingsRow(
                    icon: Icons.lock_outline,
                    title: 'Private Profile',
                    subtitle:
                    'Only followers can see your profile',
                    trailing: Switch(
                      value: _privateProfile,
                      onChanged: (v) {
                        setState(
                                () => _privateProfile = v);
                        _push('private_profile', v);
                      },
                      activeColor:
                      const Color(0xFF7B2FFF),
                    ),
                  ),
                  _SettingsRow(
                    icon: Icons.location_on_outlined,
                    title: 'Location Access',
                    subtitle: 'Share your location',
                    trailing: Switch(
                      value: _locationOn,
                      onChanged: (v) {
                        setState(() => _locationOn = v);
                        _push('location_access', v);
                      },
                      activeColor:
                      const Color(0xFF7B2FFF),
                    ),
                  ),
                  _SettingsRow(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () => Navigator.push(context,
                        LegalScreen.privacyRoute()),
                  ),
                  _SettingsRow(
                    icon: Icons.description_outlined,
                    title: 'Terms of Service',
                    onTap: () => Navigator.push(
                        context, LegalScreen.termsRoute()),
                  ),
                  const _SectionDivider(),
                  const _SectionHeader(title: 'Support'),
                  _SettingsRow(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                            const _HelpSupportScreen())),
                  ),
                  _SettingsRow(
                    icon: Icons.info_outline,
                    title: 'About SportyQo',
                    subtitle: 'Version 1.0.0',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                            const _AboutScreen())),
                  ),
                  _SettingsRow(
                    icon: Icons.star_outline,
                    title: 'Rate Us',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                            const _RateUsScreen())),
                  ),
                  const _SectionDivider(),
                  const _SectionHeader(title: 'Account'),
                  _SettingsRow(
                    icon: Icons.logout,
                    title: 'Logout',
                    titleColor: Colors.redAccent,
                    iconColor: Colors.redAccent,
                    onTap: () => _showLogout(context),
                  ),
                  _SettingsRow(
                    icon: Icons.delete_forever_outlined,
                    title: 'Delete Account',
                    subtitle:
                    'Permanently delete your account and data',
                    titleColor: Colors.redAccent,
                    iconColor: Colors.redAccent,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                            const _DeleteAccountScreen())),
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

  void _showLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800)),
        content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Colors.white54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Future.microtask(() =>
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (_) =>
                        const ChooseRoleScreen()),
                        (route) => false,
                  ));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red),
            child: const Text('Logout',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Instagram-style flat row widgets ──────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: Text(title,
          style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3)),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 8,
        margin: const EdgeInsets.only(top: 8),
        color: const Color(0xFF111111));
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color iconColor;
  final Color titleColor;
  const _SettingsRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor = Colors.white70,
    this.titleColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 12),
        child: Row(children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: titleColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w500)),
                if (subtitle != null &&
                    subtitle!.isNotEmpty)
                  Text(subtitle!,
                      style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12)),
              ],
            ),
          ),
          trailing ??
              const Icon(Icons.chevron_right,
                  color: Colors.white24, size: 20),
        ]),
      ),
    );
  }
}

// ── Delete Account Screen ─────────────────────────────────────────────

class _DeleteAccountScreen extends StatefulWidget {
  const _DeleteAccountScreen();

  @override
  State<_DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState
    extends State<_DeleteAccountScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _deleting = false;

  Future<void> _confirmDelete() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _phoneCtrl.text.trim().isEmpty ||
        _passwordCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please fill all fields'),
              backgroundColor: Colors.redAccent));
      return;
    }

    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account?',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800)),
        content: const Text(
            'Your account, Qo Score, posts and all data will be permanently deleted. This cannot be undone.',
            style: TextStyle(
                color: Colors.white54,
                fontSize: 13,
                height: 1.5)),
        actions: [
          TextButton(
              onPressed: () =>
                  Navigator.pop(context, false),
              child: const Text('Cancel',
                  style:
                  TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red),
            child: const Text('Delete Forever',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      final res = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/users/me'),
        headers: {
          'Authorization':
          'Bearer ${TokenStore.accessToken}',
        },
      );
      if (res.statusCode != 200 &&
          res.statusCode != 202) {
        throw Exception(
            'Delete failed (${res.statusCode})');
      }
      await TokenStore.clear();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (_) => const ChooseRoleScreen()),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not delete: $e'),
          backgroundColor: Colors.redAccent));
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
            const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              const Text('Delete Account',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color:
                      Colors.red.withOpacity(0.08),
                      borderRadius:
                      BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.red
                              .withOpacity(0.3)),
                    ),
                    child: Row(children: const [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.redAccent,
                          size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                            'This permanently deletes your account, Qo Score, posts and league history.',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                height: 1.5)),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                      'Confirm your details to continue',
                      style: TextStyle(
                          color: Colors.white54,
                          fontSize: 13)),
                  const SizedBox(height: 16),
                  _EditField(
                      label: 'Full Name',
                      controller: _nameCtrl),
                  const SizedBox(height: 14),
                  _EditField(
                      label: 'Phone Number',
                      controller: _phoneCtrl),
                  const SizedBox(height: 14),
                  const Text('Password',
                      style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor:
                      const Color(0xFF1A1A1A),
                      border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(10),
                          borderSide: BorderSide.none),
                      contentPadding:
                      const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _deleting
                          ? null
                          : _confirmDelete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets
                            .symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                                14)),
                      ),
                      child: _deleting
                          ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                          CircularProgressIndicator(
                              color:
                              Colors.white,
                              strokeWidth: 2))
                          : const Text(
                          'Delete My Account',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight:
                              FontWeight.w700,
                              fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Share Profile Screen ──────────────────────────────────────────────

class _ShareProfileScreen extends StatelessWidget {
  const _ShareProfileScreen();

  String get _link =>
      'https://sportyqo.app/player/${Session.playerId ?? ''}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
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
              const Text('Share Profile',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
            ]),
          ),
          const SizedBox(height: 32),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xFF7B2FFF),
                  width: 2.5),
            ),
            child: ClipOval(
              child: Builder(builder: (context) {
                final u = ApiConfig.resolveMediaUrl(
                    Session.avatarUrl);
                final fallback = Container(
                    color: const Color(0xFF1A1A1A),
                    child: const Icon(Icons.person,
                        color: Colors.white, size: 48));
                return u != null && u.isNotEmpty
                    ? Image.network(u,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                    fallback)
                    : fallback;
              }),
            ),
          ),
          const SizedBox(height: 12),
          Text(Session.fullName,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          Text(Session.playerId ?? '',
              style: const TextStyle(
                  color: Color(0xFF7B2FFF),
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(12),
                border:
                Border.all(color: Colors.white10),
              ),
              child: Row(children: [
                const Icon(Icons.link,
                    color: Colors.white38, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_link,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(
                      ClipboardData(text: _link));
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(
                      content: Text(
                          'Profile link copied! 📋'),
                      backgroundColor:
                      Color(0xFF7B2FFF)));
                },
                icon: const Icon(Icons.copy,
                    color: Colors.white, size: 18),
                label: const Text('Copy Link',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  const Color(0xFF7B2FFF),
                  padding: const EdgeInsets.symmetric(
                      vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Player ID Screen ──────────────────────────────────────────────────

class _PlayerIdScreen extends StatelessWidget {
  const _PlayerIdScreen();

  @override
  Widget build(BuildContext context) {
    final id = Session.playerId ?? '—';
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
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
              const Text('Player ID',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
            ]),
          ),
          const Spacer(),
          Container(
            margin: const EdgeInsets.symmetric(
                horizontal: 32),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [
                Color(0xFF7B2FFF),
                Color(0xFF9B4FFF)
              ]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(children: [
              const Icon(Icons.badge_outlined,
                  color: Colors.white70, size: 36),
              const SizedBox(height: 12),
              const Text('Your SportyQo Player ID',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13)),
              const SizedBox(height: 8),
              Text(id,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2)),
            ]),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding:
            EdgeInsets.symmetric(horizontal: 40),
            child: Text(
                'Share this ID with coaches so they can add you to their roster and leagues.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    height: 1.5)),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 32),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(
                      ClipboardData(text: id));
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(
                      content: Text(
                          'Player ID copied! 📋'),
                      backgroundColor:
                      Color(0xFF00C853)));
                },
                icon: const Icon(Icons.copy,
                    color: Colors.white, size: 18),
                label: const Text('Copy Player ID',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  const Color(0xFF7B2FFF),
                  padding: const EdgeInsets.symmetric(
                      vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
          const Spacer(flex: 2),
        ]),
      ),
    );
  }
}

// ── Help & Support Screen ─────────────────────────────────────────────

class _HelpSupportScreen extends StatelessWidget {
  const _HelpSupportScreen();

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {
        'q': 'What is a Qo Score?',
        'a':
        'Your Qo Score measures your overall performance. You earn points from matches, coach recommendations and activity. Higher scores unlock better cards — from Purple all the way to Golden Pro.'
      },
      {
        'q': 'How do I join a league?',
        'a':
        'Ask your coach for the league code (like FALC-16-24), then go to Home, tap Join League, enter the code and pick your team.'
      },
      {
        'q': 'How do I get recommended by a coach?',
        'a':
        'Share your Player ID with your coach. Once they add you to their roster, they can send a recommendation which appears on your Playbook and adds Qo points.'
      },
      {
        'q': 'My uploaded photo is not showing',
        'a':
        'Check your internet connection and try again. If the problem continues, contact our support email below.'
      },
      {
        'q': 'How do I delete my account?',
        'a':
        'Go to Settings, tap Delete Account. Your data is removed permanently after a 30-day grace period.'
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding:
            const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              const Text('Help & Support',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
            ]),
          ),
          Expanded(
            child: ListView(
              children: [
                const _SectionHeader(
                    title:
                    'Frequently Asked Questions'),
                ...faqs.map((f) => Theme(
                  data: Theme.of(context).copyWith(
                      dividerColor:
                      Colors.transparent),
                  child: ExpansionTile(
                    tilePadding:
                    const EdgeInsets.symmetric(
                        horizontal: 20),
                    iconColor:
                    const Color(0xFF7B2FFF),
                    collapsedIconColor:
                    Colors.white38,
                    title: Text(f['q']!,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight:
                            FontWeight.w600)),
                    children: [
                      Padding(
                        padding:
                        const EdgeInsets.fromLTRB(
                            20, 0, 20, 14),
                        child: Text(f['a']!,
                            style: const TextStyle(
                                color:
                                Colors.white54,
                                fontSize: 13,
                                height: 1.5)),
                      ),
                    ],
                  ),
                )),
                const _SectionDivider(),
                const _SectionHeader(
                    title: 'Contact Us'),
                _SettingsRow(
                  icon: Icons.email_outlined,
                  title: 'Email Support',
                  subtitle: 'support@sportyqo.app',
                  onTap: () {
                    Clipboard.setData(const ClipboardData(
                        text: 'support@sportyqo.app'));
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(
                        content: Text(
                            'Email copied! 📋'),
                        backgroundColor:
                        Color(0xFF7B2FFF)));
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ── About Screen ──────────────────────────────────────────────────────

class _AboutScreen extends StatelessWidget {
  const _AboutScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
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
              const Text('About SportyQo',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
            ]),
          ),
          const SizedBox(height: 32),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              'https://i.ibb.co/cXgJptfk/29.png',
              width: 90,
              height: 90,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF7B2FFF),
                  borderRadius:
                  BorderRadius.circular(20),
                ),
                child: const Icon(Icons.bolt,
                    color: Colors.white, size: 44),
              ),
            ),
          ),
          const SizedBox(height: 14),
          RichText(
            text: const TextSpan(children: [
              TextSpan(
                  text: 'Sporty',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800)),
              TextSpan(
                  text: 'Qo',
                  style: TextStyle(
                      color: Color(0xFF7B2FFF),
                      fontSize: 26,
                      fontWeight: FontWeight.w800)),
            ]),
          ),
          const Text('Every Player Counts.',
              style: TextStyle(
                  color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 6),
          const Text('Version 1.0.0',
              style: TextStyle(
                  color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 24),
          const Padding(
            padding:
            EdgeInsets.symmetric(horizontal: 32),
            child: Text(
                'SportyQo is a sports networking platform where players build verified profiles, earn Qo Scores, join leagues and get discovered by coaches. Track your performance, share your highlights and rise through the card tiers.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    height: 1.6)),
          ),
          const SizedBox(height: 24),
          _SettingsRow(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => Navigator.push(
                context, LegalScreen.privacyRoute()),
          ),
          _SettingsRow(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () => Navigator.push(
                context, LegalScreen.termsRoute()),
          ),
          const Spacer(),
          const Text('Made with ❤️ in India',
              style: TextStyle(
                  color: Colors.white24, fontSize: 12)),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

// ── Rate Us Screen ────────────────────────────────────────────────────

class _RateUsScreen extends StatefulWidget {
  const _RateUsScreen();

  @override
  State<_RateUsScreen> createState() =>
      _RateUsScreenState();
}

class _RateUsScreenState extends State<_RateUsScreen> {
  int _stars = 0;
  final _feedbackCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
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
              const Text('Rate Us',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
            ]),
          ),
          const Spacer(),
          const Icon(Icons.sports_cricket,
              color: Color(0xFF7B2FFF), size: 52),
          const SizedBox(height: 14),
          const Text('Enjoying SportyQo?',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Tap a star to rate the app',
              style: TextStyle(
                  color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              return GestureDetector(
                onTap: () =>
                    setState(() => _stars = i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6),
                  child: Icon(
                    i < _stars
                        ? Icons.star
                        : Icons.star_border,
                    color: const Color(0xFFFFB300),
                    size: 40,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 32),
            child: TextField(
              controller: _feedbackCtrl,
              maxLines: 3,
              style: const TextStyle(
                  color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText:
                'Tell us what you think (optional)',
                hintStyle: const TextStyle(
                    color: Colors.white24,
                    fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                contentPadding:
                const EdgeInsets.all(14),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 32),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _stars == 0
                    ? null
                    : () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(
                      content: Text(
                          'Thanks for the $_stars star rating! 🎉'),
                      backgroundColor:
                      const Color(
                          0xFF7B2FFF)));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  const Color(0xFF7B2FFF),
                  disabledBackgroundColor:
                  Colors.white10,
                  padding: const EdgeInsets.symmetric(
                      vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(14)),
                ),
                child: Text('Submit Rating',
                    style: TextStyle(
                        color: _stars == 0
                            ? Colors.white38
                            : Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
              ),
            ),
          ),
          const Spacer(flex: 2),
        ]),
      ),
    );
  }
}

// ── Edit Profile Screen ───────────────────────────────────────────────

class _EditProfileScreen extends StatefulWidget {
  const _EditProfileScreen();

  @override
  State<_EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState
    extends State<_EditProfileScreen> {
  final _picker = ImagePicker();
  String? _avatarUrl = Session.avatarUrl;
  bool _uploadingPhoto = false;
  final _nameCtrl =
  TextEditingController(text: Session.fullName);
  final _roleCtrl = TextEditingController();
  final _teamCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  bool _saving = false;

  Future<void> _save(BuildContext context) async {
    if (_saving) return;
    _saving = true;
    try {
      await UserService.updateProfile(
        fullName: _nameCtrl.text.trim().isEmpty
            ? null
            : _nameCtrl.text.trim(),
        rolePosition: _roleCtrl.text.trim().isEmpty
            ? null
            : _roleCtrl.text.trim(),
        team: _teamCtrl.text.trim().isEmpty
            ? null
            : _teamCtrl.text.trim(),
        location: _locationCtrl.text.trim().isEmpty
            ? null
            : _locationCtrl.text.trim(),
        school: _schoolCtrl.text.trim().isEmpty
            ? null
            : _schoolCtrl.text.trim(),
        bio: _bioCtrl.text.trim().isEmpty
            ? null
            : _bioCtrl.text.trim(),
      );
      await UserService.me();
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile updated! ✅'),
          backgroundColor: Color(0xFF7B2FFF)));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent));
      }
    } finally {
      _saving = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(children: [
          // ── Header ──
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
              const Text('Edit Profile',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              GestureDetector(
                onTap: () => _save(context),
                child: const Text('Save',
                    style: TextStyle(
                        color: Color(0xFF7B2FFF),
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ),
            ]),
          ),

          const SizedBox(height: 24),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20),
              child: Column(children: [

                // ── Profile Photo ──
                Center(
                  child: Stack(children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF7B2FFF),
                            width: 3),
                      ),
                      child: ClipOval(
                        child: Builder(builder: (context) {
                          if (_uploadingPhoto) {
                            return Container(
                                color: const Color(0xFF1A1A1A),
                                child: const Center(
                                    child:
                                    CircularProgressIndicator(
                                        color: Color(
                                            0xFF7B2FFF))));
                          }
                          final u = ApiConfig.resolveMediaUrl(
                              _avatarUrl);
                          final fallback = Container(
                              color: const Color(0xFF1A1A1A),
                              child: const Icon(Icons.person,
                                  color: Colors.white,
                                  size: 52));
                          return u != null && u.isNotEmpty
                              ? Image.network(u,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => fallback)
                              : fallback;
                        }),
                      ),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: GestureDetector(
                        onTap: () => _showPhotoOptions(
                            context),
                        child: Container(
                          width: 34, height: 34,
                          decoration: const BoxDecoration(
                            color: Color(0xFF7B2FFF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18),
                        ),
                      ),
                    ),
                  ]),
                ),

                const SizedBox(height: 8),

                GestureDetector(
                  onTap: () =>
                      _showPhotoOptions(context),
                  child: const Text(
                      'Change Profile Photo',
                      style: TextStyle(
                          color: Color(0xFF7B2FFF),
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),

                const SizedBox(height: 24),

                _EditField(
                    label: 'Full Name',
                    controller: _nameCtrl),
                const SizedBox(height: 14),
                _EditField(
                    label: 'Role / Position',
                    controller: _roleCtrl),
                const SizedBox(height: 14),
                _EditField(
                    label: 'Team',
                    controller: _teamCtrl),
                const SizedBox(height: 14),
                _EditField(
                    label: 'Location',
                    controller: _locationCtrl),
                const SizedBox(height: 14),
                _EditField(
                    label: 'School / Academy',
                    controller: _schoolCtrl),
                const SizedBox(height: 14),
                _EditField(
                    label: 'Bio',
                    controller: _bioCtrl,
                    maxLines: 4),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _save(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(0xFF7B2FFF),
                      padding: const EdgeInsets.symmetric(
                          vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(14)),
                    ),
                    child: const Text('Save Changes',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                  ),
                ),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (_uploadingPhoto) return;
    try {
      final x = await _picker.pickImage(
          source: source,
          maxWidth: 1080,
          maxHeight: 1080,
          imageQuality: 85);
      if (x == null) return;
      setState(() => _uploadingPhoto = true);
      final bytes = await x.readAsBytes();
      var mime = x.mimeType ?? '';
      if (mime.isEmpty) {
        final n = x.name.toLowerCase();
        mime = n.endsWith('.png')
            ? 'image/png'
            : n.endsWith('.webp')
            ? 'image/webp'
            : 'image/jpeg';
      }
      final parts = mime.split('/');
      final res = await UserService.updateProfile(
        avatar: http.MultipartFile.fromBytes('avatar', bytes,
            filename:
            x.name.isNotEmpty ? x.name : 'avatar.jpg',
            contentType: MediaType(parts[0], parts[1])),
      );
      await UserService.me(); // refresh cached session
      if (!mounted) return;
      setState(() {
        _avatarUrl = res['avatar_url'] as String?;
        _uploadingPhoto = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile photo updated'),
          backgroundColor: Color(0xFF7B2FFF)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not update photo: $e'),
          backgroundColor: Colors.redAccent));
    }
  }

  void _showPhotoOptions(BuildContext context) {
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
            const Text('Update Profile Photo',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _pickPhoto(ImageSource.camera);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B2FFF)
                          .withOpacity(0.15),
                      borderRadius:
                      BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFF7B2FFF)
                              .withOpacity(0.4)),
                    ),
                    child: Column(children: const [
                      Icon(Icons.camera_alt,
                          color: Color(0xFF7B2FFF),
                          size: 28),
                      SizedBox(height: 8),
                      Text('Camera',
                          style: TextStyle(
                              color: Color(0xFF7B2FFF),
                              fontSize: 13)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _pickPhoto(ImageSource.gallery);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B2FFF)
                          .withOpacity(0.15),
                      borderRadius:
                      BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFF7B2FFF)
                              .withOpacity(0.4)),
                    ),
                    child: Column(children: const [
                      Icon(Icons.photo_library,
                          color: Color(0xFF7B2FFF),
                          size: 28),
                      SizedBox(height: 8),
                      Text('Gallery',
                          style: TextStyle(
                              color: Color(0xFF7B2FFF),
                              fontSize: 13)),
                    ]),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel',
                    style: TextStyle(
                        color: Colors.white38))),
          ],
        ),
      ),
    );
  }
}

// ── Notification Screen ───────────────────────────────────────────────

class _NotificationScreen extends StatefulWidget {
  const _NotificationScreen();

  @override
  State<_NotificationScreen> createState() =>
      _NotificationScreenState();
}

class _NotificationScreenState
    extends State<_NotificationScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _deleteTabItem(
      Map<String, dynamic> item) async {
    final pid = item['post_id'] as String?;
    if (pid == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete this post?',
            style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800)),
        content: const Text(
            'This removes it from your Playbook and the Dugout feed. This cannot be undone.',
            style: TextStyle(
                color: Colors.white54, fontSize: 13, height: 1.4)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent),
            child: const Text('Delete',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await FeedService.deletePost(pid);
      if (!mounted) return;
      _load();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Post deleted'),
          backgroundColor: Color(0xFF7B2FFF)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Could not delete: $e'),
            backgroundColor: Colors.redAccent));
      }
    }
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
            padding:
            const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                          color: const Color(0xFF7B2FFF),
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
                        .map((n) => {...n, 'read': true})
                        .toList();
                  });
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(
                    content:
                    Text('All marked as read ✅'),
                    backgroundColor: Color(0xFF7B2FFF),
                    duration: Duration(seconds: 2),
                  ));
                },
                child: const Text('Mark all read',
                    style: TextStyle(
                        color: Color(0xFF7B2FFF),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: _loading
                ? const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF7B2FFF)))
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
                          : const Color(0xFF7B2FFF)
                          .withOpacity(0.08),
                      borderRadius:
                      BorderRadius.circular(14),
                      border: Border.all(
                        color: n['read'] as bool
                            ? Colors.white10
                            : const Color(0xFF7B2FFF)
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
                                    width: 8, height: 8,
                                    decoration:
                                    const BoxDecoration(
                                        color: Color(
                                            0xFF7B2FFF),
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

// ── Video Card ────────────────────────────────────────────────────────

class _VideoCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _VideoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(children: [
        Positioned.fill(
          child: item['type'] == 'video'
              ? Container(
              color: const Color(0xFF15152A),
              child: const Center(
                  child: Icon(Icons.movie_outlined,
                      color: Colors.white24, size: 40)))
              : Image.network(
            item['image'] ?? '',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(
                    color: const Color(0xFF1A1A1A)),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
          ),
        ),
        if (item['type'] == 'video')
          Positioned(
            top: 10, left: 10,
            child: Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow,
                  color: Colors.white, size: 20),
            ),
          ),
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(item['title'],
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(children: [
                  Expanded(
                    child: Text(item['subtitle'],
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11)),
                  ),
                  Text(item['date'],
                      style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10)),
                ]),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Video Player Screen ───────────────────────────────────────────────

class _VideoPlayerScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  const _VideoPlayerScreen({required this.item});

  @override
  State<_VideoPlayerScreen> createState() =>
      _VideoPlayerScreenState();
}

class _VideoPlayerScreenState
    extends State<_VideoPlayerScreen> {
  bool get _isVideo => widget.item['type'] == 'video';

  @override
  Widget build(BuildContext context) {
    final url = widget.item['image'] as String?;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(children: [
          Stack(children: [
            SizedBox(
              width: double.infinity,
              child: url == null
                  ? Container(
                  height: 260,
                  color: const Color(0xFF1A1A1A))
                  : _isVideo
                  ? AppVideoPlayer.network(url,
                  autoPlay: true)
                  : InteractiveViewer(
                child: Image.network(url,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        Container(
                            height: 260,
                            color: const Color(
                                0xFF1A1A1A))),
              ),
            ),
            Positioned(
              top: 12, left: 12,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36, height: 36,
                  decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back_ios,
                      color: Colors.white, size: 18),
                ),
              ),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (((widget.item['title'] as String?) ?? '')
                    .isNotEmpty)
                  Text(widget.item['title'],
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Row(children: [
                  if (((widget.item['subtitle'] as String?) ??
                      '')
                      .isNotEmpty) ...[
                    Text(widget.item['subtitle'],
                        style: const TextStyle(
                            color: Color(0xFF7B2FFF),
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const Text(' • ',
                        style:
                        TextStyle(color: Colors.white38)),
                  ],
                  Text((widget.item['date'] as String?) ?? '',
                      style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 13)),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;
  const _EditField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(
              color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value, label;
  final VoidCallback? onTap;
  const _StatItem(
      {required this.value,
        required this.label,
        this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800)),
          Text(label,
              style: const TextStyle(
                  color: Colors.white38, fontSize: 10)),
        ]),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        height: 30, width: 1, color: Colors.white10);
  }
}

class _Tab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _Tab({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(children: [
          Padding(
            padding:
            const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment:
              MainAxisAlignment.center,
              children: [
                Icon(icon,
                    color: isActive
                        ? const Color(0xFF7B2FFF)
                        : Colors.white38,
                    size: 14),
                const SizedBox(width: 4),
                Text(label,
                    style: TextStyle(
                        color: isActive
                            ? const Color(0xFF7B2FFF)
                            : Colors.white38,
                        fontSize: 11,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w400)),
              ],
            ),
          ),
          Container(
            height: 2,
            color: isActive
                ? const Color(0xFF7B2FFF)
                : Colors.transparent,
          ),
        ]),
      ),
    );
  }
}

class _UploadOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _UploadOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color:
          const Color(0xFF7B2FFF).withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFF7B2FFF)
                  .withOpacity(0.3)),
        ),
        child: Column(children: [
          Icon(icon,
              color: const Color(0xFF7B2FFF), size: 28),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF7B2FFF),
                  fontSize: 12)),
        ]),
      ),
    );
  }
}
/// One coach recommendation, rendered from backend data.
class _RecommendationCard extends StatelessWidget {
  final Map<String, dynamic> reco;
  const _RecommendationCard({required this.reco});

  @override
  Widget build(BuildContext context) {
    final name = (reco['name'] as String?) ?? 'Coach';
    final title = (reco['title'] as String?) ?? '';
    final quote = (reco['quote'] as String?) ?? '';
    final rating = reco['rating'];
    final date = (reco['recommended_at'] as String?) ?? '';
    final verified = reco['verified'] == true;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                shape: BoxShape.circle),
            child: Center(
                child: Text(
                    name.isNotEmpty
                        ? name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(
                    child: Text(name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                  ),
                  if (verified) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.verified,
                        color: Color(0xFF7B2FFF), size: 14),
                  ],
                ]),
                if (title.isNotEmpty)
                  Text(title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11)),
                if (quote.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('"$quote"',
                      style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          height: 1.4,
                          fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (rating != null) ...[
                Text('$rating',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18)),
                const Icon(Icons.star,
                    color: Color(0xFF7B2FFF), size: 16),
                const SizedBox(height: 4),
              ],
              Text(date,
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}


// ── Connections (Followers / Following) — Instagram style ─────────────

class _ConnectionsScreen extends StatefulWidget {
  final int initialTab;
  const _ConnectionsScreen({this.initialTab = 0});

  @override
  State<_ConnectionsScreen> createState() =>
      _ConnectionsScreenState();
}

class _ConnectionsScreenState
    extends State<_ConnectionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Map<String, dynamic>>? _followers;
  List<Map<String, dynamic>>? _following;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
        length: 2,
        vsync: this,
        initialIndex: widget.initialTab);
    _loadKind('followers');
    _loadKind('following');
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadKind(String kind) async {
    try {
      final res = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/users/me/connections?kind=$kind'),
        headers: {
          'Authorization':
          'Bearer ${TokenStore.accessToken}',
        },
      );
      List<Map<String, dynamic>> items = [];
      if (res.statusCode == 200) {
        items = ((jsonDecode(res.body)
        as Map<String, dynamic>)['items']
        as List<dynamic>)
            .cast<Map<String, dynamic>>();
      }
      if (!mounted) return;
      setState(() {
        if (kind == 'followers') {
          _followers = items;
        } else {
          _following = items;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (kind == 'followers') {
          _followers = [];
        } else {
          _following = [];
        }
      });
    }
  }

  Future<void> _toggleTrack(
      Map<String, dynamic> u) async {
    final id = u['id'] as String?;
    if (id == null) return;
    final wasFollowing =
        u['viewer_following'] == true;
    setState(
            () => u['viewer_following'] = !wasFollowing);
    try {
      final uri = Uri.parse(
          '${ApiConfig.baseUrl}/users/$id/track');
      final headers = {
        'Authorization':
        'Bearer ${TokenStore.accessToken}',
      };
      final res = wasFollowing
          ? await http.delete(uri, headers: headers)
          : await http.post(uri, headers: headers);
      if (res.statusCode >= 400) {
        throw Exception('failed');
      }
    } catch (_) {
      if (mounted) {
        setState(() =>
        u['viewer_following'] = wasFollowing);
      }
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
            const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Text(Session.fullName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
            ]),
          ),
          TabBar(
            controller: _tabs,
            indicatorColor: const Color(0xFF7B2FFF),
            indicatorWeight: 2,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white38,
            labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700),
            tabs: [
              Tab(
                  text:
                  '${_followers?.length ?? ''} Fans'),
              Tab(
                  text:
                  '${_following?.length ?? ''} Tracking'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _buildList(_followers,
                    'No fans yet'),
                _buildList(_following,
                    'Not tracking anyone yet'),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildList(
      List<Map<String, dynamic>>? items,
      String emptyText) {
    if (items == null) {
      return const Center(
          child: CircularProgressIndicator(
              color: Color(0xFF7B2FFF)));
    }
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline,
                color: Colors.white24, size: 48),
            const SizedBox(height: 12),
            Text(emptyText,
                style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 14)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, i) =>
          _UserListTile(
              user: items[i],
              onToggle: () =>
                  _toggleTrack(items[i])),
    );
  }
}

class _UserListTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onToggle;
  const _UserListTile(
      {required this.user, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final name =
        (user['full_name'] as String?) ?? 'Player';
    final verified = user['verified'] == true;
    final role = (user['role'] as String?) ?? 'player';
    final sub = (user['player_id'] as String?) ??
        (role == 'coach' ? 'Coach' : 'Player');
    final following =
        user['viewer_following'] == true;
    final avatar = ApiConfig.resolveMediaUrl(
        user['avatar_url'] as String?);

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 20, vertical: 8),
      child: Row(children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: role == 'coach'
                    ? const Color(0xFF00C853)
                    : const Color(0xFF7B2FFF),
                width: 1.5),
          ),
          child: ClipOval(
            child: avatar != null && avatar.isNotEmpty
                ? Image.network(avatar,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _initialBox(name))
                : _initialBox(name),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(children: [
                Flexible(
                  child: Text(name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight:
                          FontWeight.w700),
                      overflow:
                      TextOverflow.ellipsis),
                ),
                if (verified) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.verified,
                      color: Color(0xFF7B2FFF),
                      size: 14),
                ],
              ]),
              Text(sub,
                  style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12)),
            ],
          ),
        ),
        GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 18, vertical: 7),
            decoration: BoxDecoration(
              color: following
                  ? Colors.white10
                  : const Color(0xFF7B2FFF),
              borderRadius: BorderRadius.circular(8),
              border: following
                  ? Border.all(color: Colors.white24)
                  : null,
            ),
            child: Text(
                following ? 'Tracking' : 'Track',
                style: TextStyle(
                    color: following
                        ? Colors.white70
                        : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }

  Widget _initialBox(String name) => Container(
    color: const Color(0xFF1A1A1A),
    child: Center(
        child: Text(
            name.isNotEmpty
                ? name[0].toUpperCase()
                : '?',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800))),
  );
}

// ── Teams List Screen ─────────────────────────────────────────────────

class _TeamsListScreen extends StatefulWidget {
  const _TeamsListScreen();

  @override
  State<_TeamsListScreen> createState() =>
      _TeamsListScreenState();
}

class _TeamsListScreenState
    extends State<_TeamsListScreen> {
  List<Map<String, dynamic>>? _teams;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/users/me/connections?kind=teams'),
        headers: {
          'Authorization':
          'Bearer ${TokenStore.accessToken}',
        },
      );
      List<Map<String, dynamic>> items = [];
      if (res.statusCode == 200) {
        items = ((jsonDecode(res.body)
        as Map<String, dynamic>)['items']
        as List<dynamic>)
            .cast<Map<String, dynamic>>();
      }
      if (mounted) setState(() => _teams = items);
    } catch (_) {
      if (mounted) setState(() => _teams = []);
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
            const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              const Text('My Teams',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
            ]),
          ),
          Expanded(
            child: _teams == null
                ? const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF7B2FFF)))
                : _teams!.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: const [
                  Icon(Icons.shield_outlined,
                      color: Colors.white24,
                      size: 48),
                  SizedBox(height: 12),
                  Text(
                      'No teams yet.\nJoin a league to get started!',
                      textAlign:
                      TextAlign.center,
                      style: TextStyle(
                          color:
                          Colors.white38,
                          fontSize: 14,
                          height: 1.5)),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets
                  .symmetric(vertical: 8),
              itemCount: _teams!.length,
              itemBuilder: (context, i) {
                final t = _teams![i];
                return Padding(
                  padding: const EdgeInsets
                      .symmetric(
                      horizontal: 20,
                      vertical: 8),
                  child: Row(children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration:
                      BoxDecoration(
                        color: const Color(
                            0xFF7B2FFF)
                            .withOpacity(
                            0.15),
                        shape:
                        BoxShape.circle,
                        border: Border.all(
                            color: const Color(
                                0xFF7B2FFF)
                                .withOpacity(
                                0.4)),
                      ),
                      child: const Icon(
                          Icons.shield,
                          color: Color(
                              0xFF7B2FFF),
                          size: 24),
                    ),
                    const SizedBox(
                        width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          Text(
                              (t['name'] as String?) ??
                                  'Team',
                              style: const TextStyle(
                                  color: Colors
                                      .white,
                                  fontSize:
                                  14,
                                  fontWeight:
                                  FontWeight
                                      .w700)),
                          Text(
                              [
                                t['league_name'],
                                t['league_code'],
                              ]
                                  .whereType<
                                  String>()
                                  .join(' • '),
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
                        color:
                        Colors.white24,
                        size: 20),
                  ]),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}