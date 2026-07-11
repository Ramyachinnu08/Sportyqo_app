import 'package:flutter/material.dart';
import '../../api/mappers.dart';
import '../../api/services.dart';

class DugoutScreen extends StatefulWidget {
  const DugoutScreen({super.key});

  @override
  State<DugoutScreen> createState() => _DugoutScreenState();
}

class _DugoutScreenState extends State<DugoutScreen> {
  String _selectedTab = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController =
  TextEditingController();

  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  String get _apiTab {
    switch (_selectedTab) {
      case 'Players':
        return 'players';
      case 'Coaches':
        return 'coaches';
      case 'Teams':
        return 'teams';
      case 'Following':
        return 'following';
      default:
        return 'all';
    }
  }

  Future<void> _loadFeed() async {
    setState(() => _loading = true);
    try {
      final res = await FeedService.feed(
          tab: _apiTab,
          q: _searchQuery.isEmpty ? null : _searchQuery);
      final items = (res['items'] as List<dynamic>).map((raw) {
        final post = raw as Map<String, dynamic>;
        final author = post['author'] as Map<String, dynamic>? ?? {};
        final media = (post['media'] as List<dynamic>? ?? [])
            .map((m) => (m as Map<String, dynamic>)['url'] as String?)
            .whereType<String>()
            .toList();
        return <String, dynamic>{
          'id': post['id'],
          'author_id': author['id'],
          'name': author['name'] ?? '',
          'verified': author['verified'] == true,
          'role': author['role_line'] ?? '',
          'time': relativeTime(post['created_at'] as String?),
          'avatar': author['avatar_url'],
          'content': post['content'] ?? '',
          'image': media.isNotEmpty ? media.first : null,
          'qoScore': author['qo_score'] ?? 0,
          'qoEarned': '+${post['qo_points_earned'] ?? 0}',
          'type': author['type'] ?? 'player',
          'liked': post['viewer']?['liked'] == true,
          'likes': post['counts']?['likes'] ?? 0,
          'comments': post['counts']?['comments'] ?? 0,
          'posts': 0,
          'followers': '0',
          'following': 0,
          'location': '',
          'sport': author['role_line'] ?? '',
          'bio': '',
          'images': media,
        };
      }).toList();
      if (!mounted) return;
      setState(() {
        _posts = items;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredPosts => _posts;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // ── Search ──
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(22),
                  border:
                  Border.all(color: Colors.white10),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) {
                    setState(() => _searchQuery = v);
                    _loadFeed();
                  },
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText:
                    'Search player, team or coach',
                    hintStyle: const TextStyle(
                        color: Colors.white38,
                        fontSize: 14),
                    prefixIcon: const Icon(Icons.search,
                        color: Colors.white38, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() =>
                        _searchQuery = '');
                      },
                      child: const Icon(Icons.close,
                          color: Colors.white38,
                          size: 18),
                    )
                        : null,
                    border: InputBorder.none,
                    contentPadding:
                    const EdgeInsets.symmetric(
                        vertical: 12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ── Tabs ──
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20),
                children: _tabs.map((tab) {
                  final isActive = _selectedTab == tab;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedTab = tab);
                      _loadFeed();
                    },
                    child: Container(
                      margin:
                      const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF7B2FFF)
                            : Colors.transparent,
                        borderRadius:
                        BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive
                              ? const Color(0xFF7B2FFF)
                              : Colors.white24,
                        ),
                      ),
                      child: Text(tab,
                          style: TextStyle(
                              color: isActive
                                  ? Colors.white
                                  : Colors.white60,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              fontSize: 13)),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 14),

            // ── Latest + Filter ──
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20),
              child: Row(children: [
                Row(children: const [
                  Text('Latest',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down,
                      color: Colors.white, size: 18),
                ]),
                const Spacer(),
                Row(children: const [
                  Text('Filter',
                      style: TextStyle(
                          color: Colors.white60,
                          fontSize: 13)),
                  SizedBox(width: 6),
                  Icon(Icons.tune,
                      color: Colors.white60, size: 18),
                ]),
              ]),
            ),

            const SizedBox(height: 12),

            // ── Posts ──
            Expanded(
              child: _filteredPosts.isEmpty
                  ? const Center(
                child: Text('No posts found',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14)),
              )
                  : ListView.separated(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20),
                itemCount: _filteredPosts.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 16),
                itemBuilder: (context, i) {
                  final post = _filteredPosts[i];
                  return _PostCard(
                    post: post,
                    onLike: () async {
                      final index = _posts.indexOf(post);
                      if (index == -1) return;
                      final id = _posts[index]['id'] as String?;
                      final wasLiked =
                          _posts[index]['liked'] == true;
                      setState(() {
                        _posts[index]['liked'] = !wasLiked;
                        _posts[index]['likes'] += wasLiked ? -1 : 1;
                      });
                      if (id == null) return;
                      try {
                        final res = wasLiked
                            ? await FeedService.unlike(id)
                            : await FeedService.like(id);
                        if (!mounted) return;
                        setState(() => _posts[index]['likes'] =
                            res['like_count'] ?? _posts[index]['likes']);
                      } catch (_) {
                        if (!mounted) return;
                        setState(() {
                          _posts[index]['liked'] = wasLiked;
                          _posts[index]['likes'] += wasLiked ? 1 : -1;
                        });
                      }
                    },
                    onTapProfile: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              _ProfileDetailScreen(
                                  person: post),
                        ),
                      );
                    },
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

// ── Post Card ─────────────────────────────────────────────────────────

class _PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback onLike;
  final VoidCallback onTapProfile;
  const _PostCard({
    required this.post,
    required this.onLike,
    required this.onTapProfile,
  });

  @override
  Widget build(BuildContext context) {
    final bool liked = post['liked'] as bool;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Post Header ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onTapProfile,
                  child: ClipOval(
                    child: Image.network(
                      post['avatar'],
                      width: 46,
                      height: 46,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(
                            width: 46,
                            height: 46,
                            color: const Color(0xFF7B2FFF)
                                .withOpacity(0.3),
                            child: const Icon(Icons.person,
                                color: Colors.white,
                                size: 24),
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: onTapProfile,
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(post['name'],
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight:
                                  FontWeight.w700,
                                  fontSize: 15)),
                          if (post['verified'] as bool) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified,
                                color: Color(0xFF7B2FFF),
                                size: 16),
                          ],
                        ]),
                        Text(post['role'],
                            style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12)),
                        Text(post['time'],
                            style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11)),
                      ],
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7B2FFF)
                            .withOpacity(0.15),
                        borderRadius:
                        BorderRadius.circular(10),
                        border: Border.all(
                            color:
                            const Color(0xFF7B2FFF)
                                .withOpacity(0.4)),
                      ),
                      child: Column(children: [
                        const Text('Qo Score',
                            style: TextStyle(
                                color: Color(0xFF7B2FFF),
                                fontSize: 9,
                                fontWeight:
                                FontWeight.w600)),
                        Text('${post['qoScore']}',
                            style: const TextStyle(
                                color: Color(0xFF7B2FFF),
                                fontSize: 22,
                                fontWeight:
                                FontWeight.w900,
                                height: 1.1)),
                      ]),
                    ),
                    const SizedBox(height: 8),
                    const Icon(Icons.more_horiz,
                        color: Colors.white38, size: 20),
                  ],
                ),
              ],
            ),
          ),

          // ── Content ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
                14, 0, 14, 12),
            child: _buildContent(post['content']),
          ),

          // ── Image ──
          GestureDetector(
            onTap: onTapProfile,
            child: Image.network(
              post['image'],
              width: double.infinity,
              height: 240,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  height: 240,
                  color: const Color(0xFF1A1A1A),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF7B2FFF),
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                height: 240,
                color: const Color(0xFF1A1A1A),
                child: const Center(
                  child: Icon(Icons.image_outlined,
                      color: Colors.white24, size: 48),
                ),
              ),
            ),
          ),

          // ── Qo Score Earned ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
                14, 10, 14, 4),
            child: Row(children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF7B2FFF)
                      .withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star,
                    color: Color(0xFF7B2FFF), size: 14),
              ),
              const SizedBox(width: 8),
              const Text('Qo Score Earned',
                  style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12)),
              const Spacer(),
              Text(post['qoEarned'],
                  style: const TextStyle(
                      color: Color(0xFF7B2FFF),
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ]),
          ),

          // ── Actions ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
                14, 4, 14, 14),
            child: Row(children: [
              GestureDetector(
                onTap: onLike,
                child: Row(children: [
                  Icon(
                    liked
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: liked
                        ? Colors.red
                        : Colors.white38,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text('${post['likes']}',
                      style: TextStyle(
                          color: liked
                              ? Colors.red
                              : Colors.white38,
                          fontSize: 13)),
                ]),
              ),
              const SizedBox(width: 20),
              Row(children: [
                const Icon(Icons.chat_bubble_outline,
                    color: Colors.white38, size: 20),
                const SizedBox(width: 4),
                Text('${post['comments']}',
                    style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 13)),
              ]),
              const SizedBox(width: 20),
              const Icon(Icons.ios_share_outlined,
                  color: Colors.white38, size: 20),
              const Spacer(),
              const Icon(Icons.bookmark_border,
                  color: Colors.white38, size: 20),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(String content) {
    final lines = content.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.startsWith('#')) {
          return Text(line,
              style: const TextStyle(
                  color: Color(0xFF7B2FFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w600));
        }
        return Text(line,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.5));
      }).toList(),
    );
  }
}

// ── Profile Detail Screen ─────────────────────────────────────────────

class _ProfileDetailScreen extends StatefulWidget {
  final Map<String, dynamic> person;
  const _ProfileDetailScreen({required this.person});

  @override
  State<_ProfileDetailScreen> createState() =>
      _ProfileDetailScreenState();
}

class _ProfileDetailScreenState
    extends State<_ProfileDetailScreen> {
  bool _isFollowing = false;
  int _tabIndex = 0;

  final List<Map<String, String>> _tabs = [
    {'icon': 'playing', 'label': 'Playing'},
    {'icon': 'certificate', 'label': 'Certificate'},
    {'icon': 'teams', 'label': 'Teams'},
    {'icon': 'trophies', 'label': 'Trophies'},
    {'icon': 'update', 'label': 'Update'},
  ];

  IconData _getTabIcon(String icon) {
    switch (icon) {
      case 'playing':
        return Icons.sports_cricket;
      case 'certificate':
        return Icons.workspace_premium_outlined;
      case 'teams':
        return Icons.people_outline;
      case 'trophies':
        return Icons.emoji_events_outlined;
      case 'update':
        return Icons.campaign_outlined;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.person;
    final images = p['images'] as List<String>;
    final isPlayer = p['type'] == 'player';
    final themeColor = isPlayer
        ? const Color(0xFF1A6BFF)
        : const Color(0xFF00C853);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [

              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    16, 16, 16, 0),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 22),
                  ),
                  const Spacer(),
                  const Icon(Icons.more_vert,
                      color: Colors.white, size: 24),
                ]),
              ),

              const SizedBox(height: 20),

              // ── Profile Info Row ──
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16),
                child: Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Stack(children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: themeColor,
                              width: 3),
                        ),
                        child: ClipOval(
                          child: Image.network(
                            p['avatar'],
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) =>
                                Container(
                                  color: const Color(
                                      0xFF1A1A1A),
                                  child: const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 48),
                                ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: themeColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(
                                    0xFF0A0A0A),
                                width: 2),
                          ),
                          child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 14),
                        ),
                      ),
                    ]),

                    const SizedBox(width: 16),

                    // Name + Stats
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(p['name'],
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight:
                                    FontWeight.w800)),
                            if (p['verified'] as bool) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.verified,
                                  color: themeColor,
                                  size: 18),
                            ],
                          ]),
                          const SizedBox(height: 4),
                          Row(children: [
                            Icon(Icons.person_outline,
                                color: Colors.white38,
                                size: 13),
                            const SizedBox(width: 4),
                            Text(p['sport'],
                                style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12)),
                            const SizedBox(width: 8),
                            Container(
                                height: 12,
                                width: 1,
                                color: Colors.white24),
                            const SizedBox(width: 8),
                            Icon(
                                Icons
                                    .location_on_outlined,
                                color: Colors.white38,
                                size: 13),
                            const SizedBox(width: 4),
                            Text(p['location'],
                                style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12)),
                          ]),
                          const SizedBox(height: 12),
                          // Stats
                          Row(children: [
                            _StatCol(
                                value:
                                '${p['posts']}',
                                label: 'Posts'),
                            const SizedBox(width: 20),
                            _StatCol(
                                value: p['followers'],
                                label: 'Followers'),
                            const SizedBox(width: 20),
                            _StatCol(
                                value:
                                '${p['following']}',
                                label: 'Following'),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Bio ──
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16),
                child: _buildBio(p['bio']),
              ),

              const SizedBox(height: 16),

              // ── Action Buttons ──
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16),
                child: Row(children: [
                  // Follow Button
                  Expanded(
                    flex: 3,
                    child: GestureDetector(
                      onTap: () => setState(() =>
                      _isFollowing = !_isFollowing),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12),
                        decoration: BoxDecoration(
                          color: _isFollowing
                              ? Colors.transparent
                              : themeColor,
                          borderRadius:
                          BorderRadius.circular(12),
                          border: _isFollowing
                              ? Border.all(
                              color: Colors.white24)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            _isFollowing
                                ? 'Following'
                                : 'Follow',
                            style: TextStyle(
                                color: _isFollowing
                                    ? Colors.white70
                                    : Colors.white,
                                fontWeight:
                                FontWeight.w700,
                                fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Message Button
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius:
                        BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white24),
                      ),
                      child: const Center(
                        child: Text('Message',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Add Friend Button
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius:
                      BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white24),
                    ),
                    child: const Icon(
                        Icons.person_add_outlined,
                        color: Colors.white,
                        size: 20),
                  ),
                ]),
              ),

              const SizedBox(height: 16),

              // ── Tabs ──
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  border: Border.symmetric(
                      horizontal: BorderSide(
                          color: Colors.white10)),
                ),
                child: Row(
                  children: _tabs.asMap().entries.map(
                        (entry) {
                      final i = entry.key;
                      final tab = entry.value;
                      final isActive = _tabIndex == i;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(
                                  () => _tabIndex = i),
                          child: Column(children: [
                            Padding(
                              padding: const EdgeInsets
                                  .symmetric(vertical: 12),
                              child: Column(children: [
                                Icon(
                                    _getTabIcon(
                                        tab['icon']!),
                                    color: isActive
                                        ? themeColor
                                        : Colors.white38,
                                    size: 22),
                                const SizedBox(height: 4),
                                Text(tab['label']!,
                                    style: TextStyle(
                                        color: isActive
                                            ? themeColor
                                            : Colors.white38,
                                        fontSize: 10,
                                        fontWeight: isActive
                                            ? FontWeight.w700
                                            : FontWeight
                                            .w400)),
                              ]),
                            ),
                            Container(
                              height: 2,
                              color: isActive
                                  ? themeColor
                                  : Colors.transparent,
                            ),
                          ]),
                        ),
                      );
                    },
                  ).toList(),
                ),
              ),

              const SizedBox(height: 2),

              // ── Image Grid ──
              GridView.builder(
                shrinkWrap: true,
                physics:
                const NeverScrollableScrollPhysics(),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                  childAspectRatio: 1,
                ),
                itemCount: images.length,
                itemBuilder: (context, i) {
                  return Stack(children: [
                    Positioned.fill(
                      child: Image.network(
                        images[i],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(
                                color: const Color(
                                    0xFF1A1A1A)),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius:
                          BorderRadius.circular(6),
                        ),
                        child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 16),
                      ),
                    ),
                  ]);
                },
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBio(String bio) {
    final lines = bio.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.startsWith('#')) {
          return Text(line,
              style: const TextStyle(
                  color: Color(0xFF1A6BFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w600));
        }
        return Text(line,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.5));
      }).toList(),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String value, label;
  const _StatCol(
      {required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800)),
        Text(label,
            style: const TextStyle(
                color: Colors.white38, fontSize: 11)),
      ],
    );
  }
}