import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../api/api_config.dart';
import '../../api/mappers.dart';
import '../../api/services.dart';
import '../../api/ui_helpers.dart';
import '../../widgets/app_video_player.dart';
import '../../widgets/avatar_picker.dart';
import '../../widgets/create_post_screen.dart';
import '../auth/choose_role_screen.dart';

class CoachPlaybookScreen extends StatefulWidget {
  const CoachPlaybookScreen({super.key});

  @override
  State<CoachPlaybookScreen> createState() =>
      _CoachPlaybookScreenState();
}

class _CoachPlaybookScreenState
    extends State<CoachPlaybookScreen> {
  int _tabIndex = 0;
  bool _isFollowing = false;

  Map<String, dynamic>? _playbook;
  List<Map<String, dynamic>> _directory = [];
  String? _avatarUrl;

  Map<String, dynamic> get _profile =>
      (_playbook?['profile'] as Map<String, dynamic>?) ?? const {};
  Map<String, dynamic> get _score =>
      (_playbook?['coach_score'] as Map<String, dynamic>?) ?? const {};
  Map<String, dynamic> get _stats =>
      (_playbook?['stats'] as Map<String, dynamic>?) ?? const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        CoachService.playbook(),
        CoachService.playerDirectory(),
      ]);
      if (!mounted) return;
      setState(() {
        _playbook = results[0] as Map<String, dynamic>;
        _avatarUrl = (_playbook?['profile']
            as Map<String, dynamic>?)?['avatar_url'] as String?;
        _directory = ((results[1]
                    as Map<String, dynamic>)['items'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
      });
    } catch (_) {}
  }

  void _onAvatarPicked(String url) {
    if (mounted) setState(() => _avatarUrl = url);
  }

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
          'image': ApiConfig.resolveMediaUrl(m['url'] as String?),
        };
      }).toList();

  List<Map<String, dynamic>> get _currentContent {
    switch (_tabIndex) {
      case 0: return _tab('coaching');
      case 1: return _tab('certificates');
      case 2: return _tab('teams');
      case 3: return _tab('trophies');
      default: return _tab('coaching');
    }
  }

  // ── Settings ──
  void _showSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => const _CoachSettingsScreen()),
    );
  }

  // ── Recommend Players ──
  void _showRecommendPlayers(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Recommend Players',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text(
                'Select players to recommend to clubs & leagues.',
                style: TextStyle(
                    color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 20),
            ..._directory.map((p) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C853)
                        .withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                      child: Text(
                          ((p['name'] as String?) ?? '?')
                                  .isNotEmpty
                              ? (p['name'] as String)[0]
                                  .toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontSize: 24))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(p['name'],
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      Text(
                          '${p['sub_role'] ?? 'Player'} • ${p['player_id'] ?? ''}',
                          style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 12)),
                    ],
                  ),
                ),
                Text('Qo ${p['qo_score'] ?? 0}',
                    style: const TextStyle(
                        color: Color(0xFF00C853),
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      await CoachService.recommend(
                          playerUserIds: [
                            p['user_id'] as String
                          ]);
                      if (!mounted) return;
                      showInfo(context,
                          '${p['name']} recommended — +25 Qo points ✅');
                    } on ApiException catch (e) {
                      if (!mounted) return;
                      if (e.code ==
                          'ALREADY_RECOMMENDED') {
                        showInfo(context,
                            'You already recommended ${p['name']} recently.');
                      } else {
                        showApiError(context, e);
                      }
                    } catch (e) {
                      if (mounted) {
                        showApiError(context, e);
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C853),
                      borderRadius:
                      BorderRadius.circular(20),
                    ),
                    child: const Text('Send',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  ),
                ),
              ]),
            )),
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

  // ── Upload Dialog ──
  static const _coachCategories = <String, String>{
    'playing': 'Coaching',
    'certificates': 'Certificates',
    'team': 'Teams',
    'trophies': 'Trophies',
  };

  Future<void> _startPost(XFile? file,
      {required bool isVideo}) async {
    if (file == null || !mounted) return;
    final posted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => CreatePostScreen(
              file: file,
              isVideo: isVideo,
              categories: _coachCategories)),
    );
    if (posted == true && mounted) {
      _load();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Posted! It now shows in your Playbook and in the Dugout feed.'),
          backgroundColor: Color(0xFF00C853)));
    }
  }

  void _showAvatarSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.camera_alt,
                color: Color(0xFF00C853)),
            title: const Text('Take Photo',
                style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(context);
              final url = await pickAndUploadAvatar(
                  context, ImageSource.camera);
              if (url != null) _onAvatarPicked(url);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library,
                color: Color(0xFF00C853)),
            title: const Text('Choose from Gallery',
                style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(context);
              final url = await pickAndUploadAvatar(
                  context, ImageSource.gallery);
              if (url != null) _onAvatarPicked(url);
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
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
                                maxDuration:
                                    const Duration(
                                        minutes: 3));
                        _startPost(x, isVideo: true);
                      })),
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
                            builder: (_) => const
                            _CoachNotificationScreen())),
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
                            color: Color(0xFF00C853),
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
                        width: 90, height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color:
                              const Color(0xFF00C853),
                              width: 2.5),
                        ),
                        child: ClipOval(
                          child: Builder(builder: (context) {
                            final u = ApiConfig
                                .resolveMediaUrl(_avatarUrl);
                            final fb = Container(
                                  color:
                                  const Color(0xFF1A1A1A),
                                  child: const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 48),
                                );
                            return u != null && u.isNotEmpty
                                ? Image.network(u,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) => fb)
                                : fb;
                          }),
                        ),
                      ),
                      Positioned(
                        top: 0, left: 0,
                        child: Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C853),
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
                              _showAvatarSheet(context),
                          child: Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color:
                              const Color(0xFF00C853),
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
                          Row(children: [
                            Flexible(
                              child: Text(
                                  (_profile['full_name']
                                          as String?) ??
                                      Session.fullName ??
                                      '',
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight:
                                      FontWeight.w800)),
                            ),
                            if (_profile['verified'] ==
                                true) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified,
                                color: Color(0xFF00C853),
                                size: 18),
                            ],
                          ]),
                          Text(
                              (_profile['role_title']
                                      as String?) ??
                                  'Coach',
                              style: const TextStyle(
                                  color: Color(0xFF00C853),
                                  fontSize: 13,
                                  fontWeight:
                                  FontWeight.w600)),
                          const SizedBox(height: 8),
                          if (((_profile['certification']
                                      as String?) ??
                                  '')
                              .isNotEmpty)
                          Row(children: [
                            const Icon(
                                Icons
                                    .workspace_premium_outlined,
                                color: Colors.white38,
                                size: 13),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                  _profile['certification'],
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12)),
                            ),
                          ]),
                          const SizedBox(height: 4),
                          if (((_profile['location']
                                      as String?) ??
                                  '')
                              .isNotEmpty)
                          Row(children: [
                            const Icon(
                                Icons.location_on_outlined,
                                color: Colors.white38,
                                size: 13),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                  _profile['location'],
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12)),
                            ),
                          ]),
                          const SizedBox(height: 4),
                          if (((_profile['academy']
                                      as String?) ??
                                  '')
                              .isNotEmpty)
                          Row(children: [
                            const Icon(Icons.shield_outlined,
                                color: Colors.white38,
                                size: 13),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                  _profile['academy'],
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12)),
                            ),
                          ]),
                          const SizedBox(height: 4),
                          if (_stats['experience_years'] !=
                              null)
                          Row(children: [
                            const Icon(Icons.access_time,
                                color: Colors.white38,
                                size: 13),
                            const SizedBox(width: 6),
                            Text(
                                '${_stats['experience_years']}+ Years Experience',
                                style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12)),
                          ]),
                        ],
                      ),
                    ),

                    // Coach Score Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius:
                        BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF00C853)
                                .withOpacity(0.5)),
                      ),
                      child: Column(children: [
                        const Text('Coach Score',
                            style: TextStyle(
                                color: Color(0xFF00C853),
                                fontSize: 9,
                                fontWeight:
                                FontWeight.w600)),
                        Text('${_score['current'] ?? 0}',
                            style: const TextStyle(
                                color: Color(0xFF00C853),
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                height: 1.1)),
                        const Text('Rank',
                            style: TextStyle(
                                color: Colors.white38,
                                fontSize: 10)),
                        Text(
                            _score['rank'] != null
                                ? '#${_score['rank']}'
                                : '—',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight:
                                FontWeight.w800)),
                        Text(
                            (_score['rank_scope']
                                    as String?) ??
                                'Coaches',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
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
                          (_profile['about'] as String)
                              .trim(),
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
                      value:
                          '${_stats['players_trained'] ?? 0}',
                      label: 'Players'),
                  _Divider(),
                  _StatItem(
                      value:
                          '${_stats['tournaments'] ?? 0}',
                      label: 'Tournaments'),
                  _Divider(),
                  _StatItem(
                      value: '${_stats['followers'] ?? 0}',
                      label: 'Followers'),
                  _Divider(),
                  _StatItem(
                      value: _stats['experience_years'] !=
                              null
                          ? '${_stats['experience_years']}+'
                          : '—',
                      label: 'Years'),
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
                            : const Color(0xFF00C853),
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

              Container(height: 1, color: Colors.white10),

              // ── Tabs ──
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20),
                child: Row(children: [
                  _Tab(
                      icon: Icons.directions_run,
                      label: 'Coaching',
                      isActive: _tabIndex == 0,
                      onTap: () =>
                          setState(() => _tabIndex = 0)),
                  _Tab(
                      icon: Icons
                          .workspace_premium_outlined,
                      label: 'Certificates',
                      isActive: _tabIndex == 1,
                      onTap: () =>
                          setState(() => _tabIndex = 1)),
                  _Tab(
                      icon: Icons.people_outline,
                      label: 'Teams',
                      isActive: _tabIndex == 2,
                      onTap: () =>
                          setState(() => _tabIndex = 2)),
                  _Tab(
                      icon: Icons.emoji_events_outlined,
                      label: 'Trophies',
                      isActive: _tabIndex == 3,
                      onTap: () =>
                          setState(() => _tabIndex = 3)),
                ]),
              ),

              Container(height: 1, color: Colors.white10),

              const SizedBox(height: 16),

              // ── Recommend Players Button ──
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20),
                child: GestureDetector(
                  onTap: () =>
                      _showRecommendPlayers(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C853),
                      borderRadius:
                      BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.people_alt_outlined,
                            color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Text('Recommend Players',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16)),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward,
                            color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

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
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius:
                          BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.white12),
                        ),
                        child: const Icon(Icons.add,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Column(
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
                              'Add coaching videos and highlights',
                              style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11)),
                        ],
                      ),
                      const Spacer(),
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

// ── Coach Settings Screen ─────────────────────────────────────────────

class _CoachSettingsScreen extends StatefulWidget {
  const _CoachSettingsScreen();

  @override
  State<_CoachSettingsScreen> createState() =>
      _CoachSettingsScreenState();
}

class _CoachSettingsScreenState
    extends State<_CoachSettingsScreen> {
  bool _notificationsOn = true;
  bool _darkMode = true;
  bool _privateProfile = false;
  bool _locationOn = true;
  bool _emailAlerts = true;

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

                  _SectionTitle(title: 'Profile'),
                  const SizedBox(height: 10),

                  _SettingsTile(
                    icon: Icons.edit_outlined,
                    color: const Color(0xFF00C853),
                    title: 'Edit Profile',
                    subtitle:
                    'Update your coaching details',
                    trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.white24),
                    onTap: () async {
                      Map<String, dynamic> prof = const {};
                      Map<String, dynamic> st = const {};
                      try {
                        final pb =
                            await CoachService.playbook();
                        prof = (pb['profile']
                                as Map<String, dynamic>?) ??
                            const {};
                        st = (pb['stats']
                                as Map<String, dynamic>?) ??
                            const {};
                      } catch (_) {}
                      if (!mounted) return;
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  _CoachEditProfileScreen(
                                      profile: prof,
                                      stats: st)));
                    },
                  ),

                  _SettingsTile(
                    icon: Icons.share_outlined,
                    color: const Color(0xFF1A6BFF),
                    title: 'Share Profile',
                    subtitle: 'Share your coach profile',
                    trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.white24),
                    onTap: () =>
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                            content: Text(
                                'Profile link copied! 📋'),
                            backgroundColor:
                            Color(0xFF1A6BFF))),
                  ),

                  _SettingsTile(
                    icon: Icons.workspace_premium_outlined,
                    color: const Color(0xFFFFB300),
                    title: 'Get Certified',
                    subtitle:
                    'Apply for coach verification',
                    trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.white24),
                    onTap: () =>
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                            content: Text(
                                'Certification page opening...'),
                            backgroundColor:
                            Color(0xFFFFB300))),
                  ),

                  const SizedBox(height: 20),

                  _SectionTitle(title: 'Preferences'),
                  const SizedBox(height: 10),

                  _SettingsTile(
                    icon: Icons.notifications_outlined,
                    color: const Color(0xFF00C853),
                    title: 'Notifications',
                    subtitle: 'Get player & match alerts',
                    trailing: Switch(
                      value: _notificationsOn,
                      onChanged: (v) => setState(
                              () => _notificationsOn = v),
                      activeColor: const Color(0xFF00C853),
                    ),
                    onTap: () => setState(() =>
                    _notificationsOn =
                    !_notificationsOn),
                  ),

                  _SettingsTile(
                    icon: Icons.dark_mode_outlined,
                    color: const Color(0xFF00C853),
                    title: 'Dark Mode',
                    subtitle: 'Switch app appearance',
                    trailing: Switch(
                      value: _darkMode,
                      onChanged: (v) =>
                          setState(() => _darkMode = v),
                      activeColor: const Color(0xFF00C853),
                    ),
                    onTap: () => setState(
                            () => _darkMode = !_darkMode),
                  ),

                  _SettingsTile(
                    icon: Icons.email_outlined,
                    color: const Color(0xFF00C853),
                    title: 'Email Alerts',
                    subtitle:
                    'Receive updates via email',
                    trailing: Switch(
                      value: _emailAlerts,
                      onChanged: (v) => setState(
                              () => _emailAlerts = v),
                      activeColor: const Color(0xFF00C853),
                    ),
                    onTap: () => setState(() =>
                    _emailAlerts = !_emailAlerts),
                  ),

                  const SizedBox(height: 20),

                  _SectionTitle(title: 'Privacy'),
                  const SizedBox(height: 10),

                  _SettingsTile(
                    icon: Icons.lock_outline,
                    color: const Color(0xFF00C853),
                    title: 'Private Profile',
                    subtitle:
                    'Only followers can see your profile',
                    trailing: Switch(
                      value: _privateProfile,
                      onChanged: (v) => setState(
                              () => _privateProfile = v),
                      activeColor: const Color(0xFF00C853),
                    ),
                    onTap: () => setState(() =>
                    _privateProfile = !_privateProfile),
                  ),

                  _SettingsTile(
                    icon: Icons.location_on_outlined,
                    color: const Color(0xFF00C853),
                    title: 'Location Access',
                    subtitle: 'Share your location',
                    trailing: Switch(
                      value: _locationOn,
                      onChanged: (v) =>
                          setState(() => _locationOn = v),
                      activeColor: const Color(0xFF00C853),
                    ),
                    onTap: () => setState(
                            () => _locationOn = !_locationOn),
                  ),

                  _SettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    color: const Color(0xFF00C853),
                    title: 'Privacy Policy',
                    subtitle: 'Read our privacy policy',
                    trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.white24),
                    onTap: () =>
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                            content: Text(
                                'Opening Privacy Policy...'),
                            backgroundColor:
                            Color(0xFF00C853))),
                  ),

                  _SettingsTile(
                    icon: Icons.description_outlined,
                    color: const Color(0xFF00C853),
                    title: 'Terms of Service',
                    subtitle: 'Read our terms',
                    trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.white24),
                    onTap: () =>
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                            content: Text(
                                'Opening Terms...'),
                            backgroundColor:
                            Color(0xFF00C853))),
                  ),

                  const SizedBox(height: 20),

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
                                'Opening Help...'),
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
                            content: Text(
                                'SportyQo v1.0.0'),
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
                            content: Text(
                                'Thank you! ⭐⭐⭐⭐⭐'),
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
                            color: Colors.red
                                .withOpacity(0.3)),
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

// ── Coach Edit Profile Screen ─────────────────────────────────────────

class _CoachEditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile;
  final Map<String, dynamic> stats;
  const _CoachEditProfileScreen(
      {this.profile = const {}, this.stats = const {}});

  @override
  State<_CoachEditProfileScreen> createState() =>
      _CoachEditProfileScreenState();
}

class _CoachEditProfileScreenState
    extends State<_CoachEditProfileScreen> {
  String? _avatarUrl = Session.avatarUrl;

  void _onAvatarPicked(String url) {
    if (mounted) setState(() => _avatarUrl = url);
  }

  late final _nameCtrl = TextEditingController(
      text: (widget.profile['full_name'] as String?) ?? '');
  late final _roleCtrl = TextEditingController(
      text: (widget.profile['role_title'] as String?) ?? '');
  late final _academyCtrl = TextEditingController(
      text: (widget.profile['academy'] as String?) ?? '');
  late final _locationCtrl = TextEditingController(
      text: (widget.profile['location'] as String?) ?? '');
  late final _certCtrl = TextEditingController(
      text:
          (widget.profile['certification'] as String?) ?? '');
  late final _expCtrl = TextEditingController(
      text: widget.stats['experience_years']?.toString() ?? '');
  late final _bioCtrl = TextEditingController(
      text: (widget.profile['about'] as String?) ?? '');
  bool _saving = false;

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
              const Text('Edit Profile',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(
                      content:
                      Text('Profile updated! ✅'),
                      backgroundColor:
                      Color(0xFF00C853)));
                },
                child: const Text('Save',
                    style: TextStyle(
                        color: Color(0xFF00C853),
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
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color:
                            const Color(0xFF00C853),
                            width: 3),
                      ),
                      child: ClipOval(
                        child: Builder(builder: (context) {
                          final u = ApiConfig
                              .resolveMediaUrl(_avatarUrl);
                          final fb = Container(
                              color:
                                  const Color(0xFF1A1A1A),
                              child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 52));
                          return u != null && u.isNotEmpty
                              ? Image.network(u,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (_, __, ___) => fb)
                              : fb;
                        }),
                      ),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: GestureDetector(
                        onTap: () async {
                          final source =
                              await showModalBottomSheet<
                                  ImageSource>(
                            context: context,
                            backgroundColor:
                                const Color(0xFF111111),
                            builder: (_) => SafeArea(
                              child: Column(
                                  mainAxisSize:
                                      MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(
                                          Icons.camera_alt,
                                          color: Color(
                                              0xFF00C853)),
                                      title: const Text(
                                          'Take Photo',
                                          style: TextStyle(
                                              color: Colors
                                                  .white)),
                                      onTap: () =>
                                          Navigator.pop(
                                              context,
                                              ImageSource
                                                  .camera),
                                    ),
                                    ListTile(
                                      leading: const Icon(
                                          Icons
                                              .photo_library,
                                          color: Color(
                                              0xFF00C853)),
                                      title: const Text(
                                          'Choose from Gallery',
                                          style: TextStyle(
                                              color: Colors
                                                  .white)),
                                      onTap: () =>
                                          Navigator.pop(
                                              context,
                                              ImageSource
                                                  .gallery),
                                    ),
                                  ]),
                            ),
                          );
                          if (source == null) return;
                          final url =
                              await pickAndUploadAvatar(
                                  context, source);
                          if (url != null) {
                            _onAvatarPicked(url);
                          }
                        },
                        child: Container(
                          width: 34, height: 34,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00C853),
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

                const Text('Change Profile Photo',
                    style: TextStyle(
                        color: Color(0xFF00C853),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),

                const SizedBox(height: 24),

                _EditField(
                    label: 'Full Name',
                    controller: _nameCtrl),
                const SizedBox(height: 14),
                _EditField(
                    label: 'Role',
                    controller: _roleCtrl),
                const SizedBox(height: 14),
                _EditField(
                    label: 'Academy / Club',
                    controller: _academyCtrl),
                const SizedBox(height: 14),
                _EditField(
                    label: 'Location',
                    controller: _locationCtrl),
                const SizedBox(height: 14),
                _EditField(
                    label: 'Certification',
                    controller: _certCtrl),
                const SizedBox(height: 14),
                _EditField(
                    label: 'Experience',
                    controller: _expCtrl),
                const SizedBox(height: 14),
                _EditField(
                    label: 'Bio',
                    controller: _bioCtrl,
                    maxLines: 4),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving
                        ? null
                        : () async {
                            setState(() => _saving = true);
                            try {
                              await CoachService
                                  .updateProfile(
                                fullName: _nameCtrl.text
                                    .trim(),
                                roleTitle: _roleCtrl.text
                                    .trim(),
                                academy: _academyCtrl.text
                                    .trim(),
                                location: _locationCtrl
                                    .text
                                    .trim(),
                                certification: _certCtrl
                                    .text
                                    .trim(),
                                experienceYears: int
                                    .tryParse(_expCtrl
                                        .text
                                        .replaceAll(
                                            RegExp(
                                                r'[^0-9]'),
                                            '')),
                                bio:
                                    _bioCtrl.text.trim(),
                              );
                              if (!mounted) return;
                              Navigator.pop(context);
                              showInfo(context,
                                  'Profile updated ✅');
                            } catch (e) {
                              if (mounted) {
                                setState(() =>
                                    _saving = false);
                                showApiError(context, e);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(0xFF00C853),
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
  bool _loadingNotifs = true;

  @override
  void initState() {
    super.initState();
    _loadNotifs();
  }

  Future<void> _loadNotifs() async {
    try {
      final res = await NotificationService.list();
      final items = (res['items'] as List<dynamic>)
          .map((n) =>
              notificationToTile(n as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() {
        _notifications = items;
        _loadingNotifs = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loadingNotifs = false);
      }
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
                  setState(() {
                    _notifications = _notifications
                        .map((n) => {...n, 'read': true})
                        .toList();
                  });
                  NotificationService.markAllRead();
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
            child: _loadingNotifs
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF00C853)))
                : _notifications.isEmpty
                    ? const Center(
                        child: Text('No notifications yet',
                            style: TextStyle(
                                color: Colors.white38,
                                fontSize: 13)))
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
                    final id =
                        _notifications[i]['id'] as String?;
                    setState(() {
                      _notifications[i] = {
                        ..._notifications[i],
                        'read': true,
                      };
                    });
                    if (id != null) {
                      NotificationService.markRead(id);
                    }
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
                                    width: 8, height: 8,
                                    decoration:
                                    const BoxDecoration(
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
                  color: const Color(0xFF15251A),
                  child: const Center(
                      child: Icon(Icons.movie_outlined,
                          color: Colors.white24, size: 40)))
              : Image.network(
                  item['image'] ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
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

class _VideoPlayerScreen extends StatelessWidget {
  final Map<String, dynamic> item;
  const _VideoPlayerScreen({required this.item});

  @override
  Widget build(BuildContext context) {
    final url = item['image'] as String?;
    final isVideo = item['type'] == 'video';
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
                  : isVideo
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
                if (((item['title'] as String?) ?? '')
                    .isNotEmpty)
                  Text(item['title'],
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text((item['date'] as String?) ?? '',
                    style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 13)),
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
        Text(label,
            style: const TextStyle(
                color: Colors.white38, fontSize: 10)),
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
            padding: const EdgeInsets.symmetric(
                vertical: 12),
            child: Row(
              mainAxisAlignment:
              MainAxisAlignment.center,
              children: [
                Icon(icon,
                    color: isActive
                        ? const Color(0xFF00C853)
                        : Colors.white38,
                    size: 14),
                const SizedBox(width: 4),
                Text(label,
                    style: TextStyle(
                        color: isActive
                            ? const Color(0xFF00C853)
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
                ? const Color(0xFF00C853)
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
          color: const Color(0xFF00C853).withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFF00C853)
                  .withOpacity(0.3)),
        ),
        child: Column(children: [
          Icon(icon,
              color: const Color(0xFF00C853), size: 28),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF00C853), fontSize: 12)),
        ]),
      ),
    );
  }
}