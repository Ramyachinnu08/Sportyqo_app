import 'package:flutter/material.dart';

class CoachDugoutScreen extends StatefulWidget {
  const CoachDugoutScreen({super.key});

  @override
  State<CoachDugoutScreen> createState() =>
      _CoachDugoutScreenState();
}

class _CoachDugoutScreenState
    extends State<CoachDugoutScreen> {
  String _selectedTab = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController =
  TextEditingController();

  final List<Map<String, dynamic>> _posts = [
    {
      'name': 'Rahul Sharma',
      'verified': true,
      'role': 'Cricket • Batsman • U16',
      'time': '2h ago',
      'avatar':
      'https://images.unsplash.com/photo-1531415074968-036ba1b575da?w=200',
      'content':
      'Great training session today! 💪 Worked on my footwork and timing.\n#CricketLife #NeverStopImproving',
      'image':
      'https://images.unsplash.com/photo-1531415074968-036ba1b575da?w=800',
      'qoScore': 87,
      'qoEarned': '+12',
      'type': 'player',
      'liked': false,
      'likes': 98,
      'comments': 14,
      'posts': 67,
      'followers': '1,245',
      'following': 234,
      'location': 'Bengaluru, India',
      'sport': 'Cricket Player',
      'bio':
      'Cricket Player | Batsman 🏏\nAlways giving 100% on the field.\n#Cricket #Batsman #NeverGiveUp',
      'images': [
        'https://images.unsplash.com/photo-1531415074968-036ba1b575da?w=400',
        'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=400',
        'https://images.unsplash.com/photo-1594470117722-de4b9a02ebed?w=400',
        'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=400',
        'https://images.unsplash.com/photo-1549060279-7e168fcee0c2?w=400',
        'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400',
      ],
    },
    {
      'name': 'Coach Vikram',
      'verified': true,
      'role': 'Head Coach • Mumbai Academy',
      'time': '4h ago',
      'avatar':
      'https://images.unsplash.com/photo-1568602471122-7832951cc4c5?w=200',
      'content':
      'Proud of my team today. Every player gave 100%.\nKeep pushing champions! 🏆\n#CoachLife #TeamWork',
      'image':
      'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=800',
      'qoScore': 95,
      'qoEarned': '+8',
      'type': 'coach',
      'liked': false,
      'likes': 156,
      'comments': 22,
      'posts': 145,
      'followers': '8,920',
      'following': 312,
      'location': 'Mumbai, India',
      'sport': 'Head Coach',
      'bio':
      'Head Coach | Mumbai Cricket Academy 🏏\nBuilding champions every day.\n#Coaching #Cricket #Excellence',
      'images': [
        'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=400',
        'https://images.unsplash.com/photo-1531415074968-036ba1b575da?w=400',
        'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=400',
        'https://images.unsplash.com/photo-1594470117722-de4b9a02ebed?w=400',
        'https://images.unsplash.com/photo-1549060279-7e168fcee0c2?w=400',
        'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400',
      ],
    },
    {
      'name': 'Falcons FC',
      'verified': true,
      'role': 'Cricket Team • Under16',
      'time': '6h ago',
      'avatar':
      'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=200',
      'content':
      'Match tomorrow! 🔥 The squad is ready.\n#FalconsFC #Cricket #GameDay',
      'image':
      'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800',
      'qoScore': 88,
      'qoEarned': '+6',
      'type': 'team',
      'liked': false,
      'likes': 203,
      'comments': 31,
      'posts': 89,
      'followers': '4,560',
      'following': 145,
      'location': 'Delhi, India',
      'sport': 'Cricket Team',
      'bio':
      'Falcons FC Cricket Club 🏏\nU16 Champions League Team\n#FalconsFC #Cricket',
      'images': [
        'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=400',
        'https://images.unsplash.com/photo-1531415074968-036ba1b575da?w=400',
        'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=400',
        'https://images.unsplash.com/photo-1594470117722-de4b9a02ebed?w=400',
      ],
    },
    {
      'name': 'Arjun Mehta',
      'verified': false,
      'role': 'Cricket • Bowler • U19',
      'time': '1d ago',
      'avatar':
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
      'content':
      'My first 5-wicket haul! 🎯 Hard work pays off.\n#Bowling #Cricket #Milestone',
      'image':
      'https://images.unsplash.com/photo-1594470117722-de4b9a02ebed?w=800',
      'qoScore': 74,
      'qoEarned': '+10',
      'type': 'player',
      'liked': false,
      'likes': 67,
      'comments': 9,
      'posts': 23,
      'followers': '890',
      'following': 456,
      'location': 'Hyderabad, India',
      'sport': 'Cricket Player',
      'bio':
      'Fast Bowler 🎯 | U19 Cricket\nOn the road to becoming the best.\n#Cricket #Bowling',
      'images': [
        'https://images.unsplash.com/photo-1594470117722-de4b9a02ebed?w=400',
        'https://images.unsplash.com/photo-1531415074968-036ba1b575da?w=400',
        'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=400',
      ],
    },
  ];

  final List<String> _tabs = [
    'All',
    'Players',
    'Coaches',
    'Teams',
    'Following',
  ];

  List<Map<String, dynamic>> get _filteredPosts {
    List<Map<String, dynamic>> list = _posts;
    if (_selectedTab == 'Players') {
      list =
          list.where((p) => p['type'] == 'player').toList();
    } else if (_selectedTab == 'Coaches') {
      list =
          list.where((p) => p['type'] == 'coach').toList();
    } else if (_selectedTab == 'Teams') {
      list =
          list.where((p) => p['type'] == 'team').toList();
    } else if (_selectedTab == 'Following') {
      list =
          list.where((p) => p['liked'] == true).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((p) => p['name']
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return list;
  }

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
                  onChanged: (v) =>
                      setState(() => _searchQuery = v),
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
                        setState(
                                () => _searchQuery = '');
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
                    onTap: () =>
                        setState(() => _selectedTab = tab),
                    child: Container(
                      margin:
                      const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF00C853)
                            : Colors.transparent,
                        borderRadius:
                        BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive
                              ? const Color(0xFF00C853)
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
                    onLike: () {
                      setState(() {
                        final index =
                        _posts.indexOf(post);
                        if (index != -1) {
                          _posts[index]['liked'] =
                          !_posts[index]['liked'];
                          if (_posts[index]['liked']) {
                            _posts[index]['likes']++;
                          } else {
                            _posts[index]['likes']--;
                          }
                        }
                      });
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
                            color: const Color(0xFF00C853)
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
                                color: Color(0xFF00C853),
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
                        color: const Color(0xFF00C853)
                            .withOpacity(0.15),
                        borderRadius:
                        BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFF00C853)
                                .withOpacity(0.4)),
                      ),
                      child: Column(children: [
                        const Text('Qo Score',
                            style: TextStyle(
                                color: Color(0xFF00C853),
                                fontSize: 9,
                                fontWeight:
                                FontWeight.w600)),
                        Text('${post['qoScore']}',
                            style: const TextStyle(
                                color: Color(0xFF00C853),
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
                      color: Color(0xFF00C853),
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
                  color: const Color(0xFF00C853)
                      .withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star,
                    color: Color(0xFF00C853), size: 14),
              ),
              const SizedBox(width: 8),
              const Text('Qo Score Earned',
                  style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12)),
              const Spacer(),
              Text(post['qoEarned'],
                  style: const TextStyle(
                      color: Color(0xFF00C853),
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
                  color: Color(0xFF00C853),
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
    const themeColor = Color(0xFF00C853);

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

              // ── Profile Info ──
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16),
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
                              const Icon(Icons.verified,
                                  color: themeColor,
                                  size: 18),
                            ],
                          ]),
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(
                                Icons.person_outline,
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
                            const Icon(
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
                          Row(children: [
                            _StatCol(
                                value: '${p['posts']}',
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
                  children:
                  _tabs.asMap().entries.map((entry) {
                    final i = entry.key;
                    final tab = entry.value;
                    final isActive = _tabIndex == i;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _tabIndex = i),
                        child: Column(children: [
                          Padding(
                            padding:
                            const EdgeInsets.symmetric(
                                vertical: 12),
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
                  }).toList(),
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
                  color: Color(0xFF00C853),
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