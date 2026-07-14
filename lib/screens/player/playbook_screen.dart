import 'dart:typed_data';

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

class PlaybookScreen extends StatefulWidget {
  const PlaybookScreen({super.key});

  @override
  State<PlaybookScreen> createState() =>
      _PlaybookScreenState();
}

class _PlaybookScreenState extends State<PlaybookScreen> {
  int _tabIndex = 0;
  bool _isFollowing = false;

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

              // ── Stats + Follow ──
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20),
                child: Row(children: [
                  _StatItem(
                      value: '${_stats['followers'] ?? 0}',
                      label: 'Followers'),
                  _Divider(),
                  _StatItem(
                      value: '${_stats['following'] ?? 0}',
                      label: 'Following'),
                  _Divider(),
                  _StatItem(
                      value: '${_stats['teams'] ?? 0}',
                      label: 'Teams'),
                  _Divider(),
                  _StatItem(
                      value: '${_stats['tournaments'] ?? 0}',
                      label: 'Tournaments'),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => setState(() =>
                    _isFollowing = !_isFollowing),
                    child: AnimatedContainer(
                      duration: const Duration(
                          milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: _isFollowing
                            ? Colors.white10
                            : const Color(0xFF7B2FFF),
                        borderRadius:
                        BorderRadius.circular(24),
                        border: _isFollowing
                            ? Border.all(
                            color: Colors.white24)
                            : null,
                      ),
                      child: Text(
                        _isFollowing
                            ? 'Tracking'
                            : 'Track',
                        style: TextStyle(
                            color: _isFollowing
                                ? Colors.white70
                                : Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14),
                      ),
                    ),
                  ),
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

// ── Settings Screen ───────────────────────────────────────────────────

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
              const Text('Settings',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
            ]),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [

                  // ── Profile Section ──
                  _SectionTitle(title: 'Profile'),
                  const SizedBox(height: 10),

                  _SettingsTile(
                    icon: Icons.edit_outlined,
                    color: const Color(0xFF7B2FFF),
                    title: 'Edit Profile',
                    subtitle:
                    'Update your name, photo and details',
                    trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.white24),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                            const _EditProfileScreen())),
                  ),

                  _SettingsTile(
                    icon: Icons.share_outlined,
                    color: const Color(0xFF1A6BFF),
                    title: 'Share Profile',
                    subtitle:
                    'Share your player profile link',
                    trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.white24),
                    onTap: () =>
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                            content:
                            Text('Profile link copied! 📋'),
                            backgroundColor:
                            Color(0xFF1A6BFF))),
                  ),

                  _SettingsTile(
                    icon: Icons.badge_outlined,
                    color: const Color(0xFF00C853),
                    title: 'Player ID',
                    subtitle: 'SQ784512',
                    trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.white24),
                    onTap: () =>
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                            content: Text(
                                'Player ID copied! 📋'),
                            backgroundColor:
                            Color(0xFF00C853))),
                  ),

                  const SizedBox(height: 20),

                  // ── Preferences ──
                  _SectionTitle(title: 'Preferences'),
                  const SizedBox(height: 10),

                  _SettingsTile(
                    icon: Icons.notifications_outlined,
                    color: const Color(0xFF7B2FFF),
                    title: 'Notifications',
                    subtitle: 'Get match & league alerts',
                    trailing: Switch(
                      value: _notificationsOn,
                      onChanged: (v) {
                        setState(() => _notificationsOn = v);
                        _push('notifications_enabled', v);
                      },
                      activeColor: const Color(0xFF7B2FFF),
                    ),
                    onTap: () => setState(() =>
                    _notificationsOn =
                    !_notificationsOn),
                  ),

                  _SettingsTile(
                    icon: Icons.dark_mode_outlined,
                    color: const Color(0xFF7B2FFF),
                    title: 'Dark Mode',
                    subtitle: 'Switch app appearance',
                    trailing: Switch(
                      value: _darkMode,
                      onChanged: (v) {
                        setState(() => _darkMode = v);
                        _push('dark_mode', v);
                      },
                      activeColor: const Color(0xFF7B2FFF),
                    ),
                    onTap: () => setState(
                            () => _darkMode = !_darkMode),
                  ),

                  _SettingsTile(
                    icon: Icons.email_outlined,
                    color: const Color(0xFF7B2FFF),
                    title: 'Email Alerts',
                    subtitle:
                    'Receive updates via email',
                    trailing: Switch(
                      value: _emailAlerts,
                      onChanged: (v) {
                        setState(() => _emailAlerts = v);
                        _push('email_alerts', v);
                      },
                      activeColor: const Color(0xFF7B2FFF),
                    ),
                    onTap: () => setState(() =>
                    _emailAlerts = !_emailAlerts),
                  ),

                  const SizedBox(height: 20),

                  // ── Privacy ──
                  _SectionTitle(title: 'Privacy'),
                  const SizedBox(height: 10),

                  _SettingsTile(
                    icon: Icons.lock_outline,
                    color: const Color(0xFF7B2FFF),
                    title: 'Private Profile',
                    subtitle:
                    'Only followers can see your profile',
                    trailing: Switch(
                      value: _privateProfile,
                      onChanged: (v) {
                        setState(() => _privateProfile = v);
                        _push('private_profile', v);
                      },
                      activeColor: const Color(0xFF7B2FFF),
                    ),
                    onTap: () => setState(() =>
                    _privateProfile = !_privateProfile),
                  ),

                  _SettingsTile(
                    icon: Icons.location_on_outlined,
                    color: const Color(0xFF7B2FFF),
                    title: 'Location Access',
                    subtitle: 'Share your location',
                    trailing: Switch(
                      value: _locationOn,
                      onChanged: (v) {
                        setState(() => _locationOn = v);
                        _push('location_access', v);
                      },
                      activeColor: const Color(0xFF7B2FFF),
                    ),
                    onTap: () => setState(
                            () => _locationOn = !_locationOn),
                  ),

                  _SettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    color: const Color(0xFF7B2FFF),
                    title: 'Privacy Policy',
                    subtitle: 'Read our privacy policy',
                    trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.white24),
                    onTap: () => Navigator.push(
                        context, LegalScreen.privacyRoute()),
                  ),

                  _SettingsTile(
                    icon: Icons.description_outlined,
                    color: const Color(0xFF7B2FFF),
                    title: 'Terms of Service',
                    subtitle: 'Read our terms',
                    trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.white24),
                    onTap: () => Navigator.push(
                        context, LegalScreen.termsRoute()),
                  ),

                  const SizedBox(height: 20),

                  // ── Support ──
                  _SectionTitle(title: 'Support'),
                  const SizedBox(height: 10),

                  _SettingsTile(
                    icon: Icons.help_outline,
                    color: const Color(0xFF1A6BFF),
                    title: 'Help & Support',
                    subtitle: 'Get help or contact us',
                    trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.white24),
                    onTap: () =>
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                            content: Text(
                                'Opening Help & Support...'),
                            backgroundColor:
                            Color(0xFF1A6BFF))),
                  ),

                  _SettingsTile(
                    icon: Icons.info_outline,
                    color: const Color(0xFF1A6BFF),
                    title: 'About SportyQo',
                    subtitle: 'Version 1.0.0',
                    trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.white24),
                    onTap: () =>
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                            content:
                            Text('SportyQo v1.0.0'),
                            backgroundColor:
                            Color(0xFF1A6BFF))),
                  ),

                  _SettingsTile(
                    icon: Icons.star_outline,
                    color: const Color(0xFFFFB300),
                    title: 'Rate Us',
                    subtitle:
                    'Rate SportyQo on the store',
                    trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.white24),
                    onTap: () =>
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                            content:
                            Text('Thank you! ⭐⭐⭐⭐⭐'),
                            backgroundColor:
                            Color(0xFFFFB300))),
                  ),

                  const SizedBox(height: 24),

                  // ── Logout ──
                  GestureDetector(
                    onTap: () => _showLogout(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius:
                        BorderRadius.circular(14),
                        border: Border.all(
                            color:
                            Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.logout,
                              color: Colors.red, size: 20),
                          SizedBox(width: 10),
                          Text('Logout',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight:
                                  FontWeight.w700,
                                  fontSize: 16)),
                        ],
                      ),
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

// ── Section Title ─────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1));
  }
}

// ── Settings Tile ─────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle;
  final Widget trailing;
  final VoidCallback onTap;
  const _SettingsTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15)),
        subtitle: Text(subtitle,
            style: const TextStyle(
                color: Colors.white38, fontSize: 12)),
        trailing: trailing,
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
  const _StatItem(
      {required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16)),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label,
              maxLines: 1,
              style: const TextStyle(
                  color: Colors.white38, fontSize: 10)),
        ),
      ]),
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

