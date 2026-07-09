import 'package:flutter/material.dart';
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

  final List<Map<String, dynamic>> _playingVideos = [
    {
      'title': 'Century vs DSO Academy',
      'subtitle': '125 Runs',
      'date': '12 May 2025',
      'image':
      'https://images.unsplash.com/photo-1531415074968-036ba1b575da?w=800',
    },
    {
      'title': 'Match Winning Knock',
      'subtitle': '78 Runs',
      'date': '5 May 2025',
      'image':
      'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=800',
    },
    {
      'title': 'Bowling Spell',
      'subtitle': '4/18',
      'date': '28 Apr 2025',
      'image':
      'https://images.unsplash.com/photo-1594470117722-de4b9a02ebed?w=800',
    },
    {
      'title': 'Brilliant Catch',
      'subtitle': 'vs Mumbai Colts',
      'date': '20 Apr 2025',
      'image':
      'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800',
    },
  ];

  final List<Map<String, dynamic>> _certificatesVideos = [
    {
      'title': 'BCCI Level 2 Certificate',
      'subtitle': 'Certified',
      'date': '10 Jan 2025',
      'image':
      'https://images.unsplash.com/photo-1549060279-7e168fcee0c2?w=800',
    },
    {
      'title': 'Sports Excellence Award',
      'subtitle': 'State Level',
      'date': '15 Dec 2024',
      'image':
      'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800',
    },
    {
      'title': 'District Championship',
      'subtitle': 'Gold Medal',
      'date': '20 Nov 2024',
      'image':
      'https://images.unsplash.com/photo-1531415074968-036ba1b575da?w=800',
    },
    {
      'title': 'Academy Certificate',
      'subtitle': 'Falcons FC',
      'date': '01 Oct 2024',
      'image':
      'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=800',
    },
  ];

  final List<Map<String, dynamic>> _teamVideos = [
    {
      'title': 'Falcons FC Team',
      'subtitle': 'U16 Division',
      'date': '2024-25',
      'image':
      'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800',
    },
    {
      'title': 'Alpha Warriors',
      'subtitle': 'U16 Division',
      'date': '2023-24',
      'image':
      'https://images.unsplash.com/photo-1531415074968-036ba1b575da?w=800',
    },
    {
      'title': 'Team Practice',
      'subtitle': 'Morning Session',
      'date': '15 May 2025',
      'image':
      'https://images.unsplash.com/photo-1594470117722-de4b9a02ebed?w=800',
    },
    {
      'title': 'Match Day Prep',
      'subtitle': 'vs Royal Strikers',
      'date': '10 May 2025',
      'image':
      'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=800',
    },
  ];

  final List<Map<String, dynamic>> _trophiesVideos = [
    {
      'title': 'Best Batsman Trophy',
      'subtitle': 'DSO Academy',
      'date': '12 May 2025',
      'image':
      'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800',
    },
    {
      'title': 'MVP Award',
      'subtitle': 'Inter School',
      'date': '5 May 2025',
      'image':
      'https://images.unsplash.com/photo-1531415074968-036ba1b575da?w=800',
    },
    {
      'title': 'Tournament Winners',
      'subtitle': 'U16 League',
      'date': '28 Apr 2025',
      'image':
      'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800',
    },
    {
      'title': 'Player of the Year',
      'subtitle': '2024 Season',
      'date': '01 Jan 2025',
      'image':
      'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=800',
    },
  ];

  List<Map<String, dynamic>> get _currentContent {
    switch (_tabIndex) {
      case 0: return _playingVideos;
      case 1: return _certificatesVideos;
      case 2: return _teamVideos;
      case 3: return _trophiesVideos;
      default: return _playingVideos;
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
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                            content:
                            Text('Camera opened 📷'),
                            backgroundColor:
                            Color(0xFF7B2FFF)));
                      })),
              const SizedBox(width: 12),
              Expanded(
                  child: _UploadOption(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                            content:
                            Text('Gallery opened 🖼️'),
                            backgroundColor:
                            Color(0xFF7B2FFF)));
                      })),
              const SizedBox(width: 12),
              Expanded(
                  child: _UploadOption(
                      icon: Icons.videocam,
                      label: 'Video',
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                            content: Text(
                                'Video recorder opened 🎥'),
                            backgroundColor:
                            Color(0xFF7B2FFF)));
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
                          child: Image.network(
                            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(
                                  color:
                                  const Color(0xFF1A1A1A),
                                  child: const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 48),
                                ),
                          ),
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
                          const Text('Aarav Mehta',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight:
                                  FontWeight.w800)),
                          const Text('Cricket • Batter',
                              style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13)),
                          const SizedBox(height: 8),
                          Row(children: const [
                            Icon(
                                Icons
                                    .calendar_today_outlined,
                                color: Colors.white38,
                                size: 13),
                            SizedBox(width: 6),
                            Text('16 May 2008',
                                style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12)),
                          ]),
                          const SizedBox(height: 4),
                          Row(children: const [
                            Icon(
                                Icons.location_on_outlined,
                                color: Colors.white38,
                                size: 13),
                            SizedBox(width: 6),
                            Text('Mumbai, India',
                                style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12)),
                          ]),
                          const SizedBox(height: 4),
                          Row(children: const [
                            Icon(Icons.shield_outlined,
                                color: Colors.white38,
                                size: 13),
                            SizedBox(width: 6),
                            Text('St. Xavier\'s School',
                                style: TextStyle(
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
                      child: Column(children: const [
                        Text('Qo Score',
                            style: TextStyle(
                                color: Color(0xFF7B2FFF),
                                fontSize: 10,
                                fontWeight:
                                FontWeight.w600)),
                        Text('92',
                            style: TextStyle(
                                color: Color(0xFF7B2FFF),
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                height: 1.1)),
                        Text('Rank',
                            style: TextStyle(
                                color: Colors.white38,
                                fontSize: 10)),
                        Text('#1',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight:
                                FontWeight.w800)),
                        Text('in U16 Cricket',
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

              // ── About ──
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
                    children: const [
                      Text('About',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      SizedBox(height: 6),
                      Text(
                          'Right-handed batter with a love for the game.\nAlways working to get better and help my team win. 🏏',
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                              height: 1.5)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Stats + Follow ──
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20),
                child: Row(children: [
                  _StatItem(
                      value: '156',
                      label: 'Followers'),
                  _Divider(),
                  _StatItem(
                      value: '89', label: 'Following'),
                  _Divider(),
                  _StatItem(
                      value: '24', label: 'Teams'),
                  _Divider(),
                  _StatItem(
                      value: '18',
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

              // ── Coach Recommendation ──
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(children: const [
                      Text('Coach Recommendations',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                      Spacer(),
                      Text('View All',
                          style: TextStyle(
                              color: Color(0xFF7B2FFF),
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ]),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius:
                        BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white10),
                      ),
                      child: Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Stack(children: [
                            ClipOval(
                              child: Image.network(
                                'https://images.unsplash.com/photo-1568602471122-7832951cc4c5?w=100',
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) =>
                                    Container(
                                      width: 52,
                                      height: 52,
                                      color: const Color(
                                          0xFF1A1A1A),
                                      child: const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 28),
                                    ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration:
                                const BoxDecoration(
                                  color:
                                  Color(0xFF7B2FFF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                    Icons.star,
                                    color: Colors.white,
                                    size: 10),
                              ),
                            ),
                          ]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  const Text(
                                      'Rahul Dravid',
                                      style: TextStyle(
                                          color:
                                          Colors.white,
                                          fontWeight:
                                          FontWeight
                                              .w700,
                                          fontSize: 14)),
                                  const SizedBox(
                                      width: 6),
                                  Container(
                                    padding: const EdgeInsets
                                        .symmetric(
                                        horizontal: 8,
                                        vertical: 3),
                                    decoration:
                                    BoxDecoration(
                                      color: const Color(
                                          0xFF7B2FFF)
                                          .withOpacity(
                                          0.2),
                                      borderRadius:
                                      BorderRadius
                                          .circular(
                                          20),
                                    ),
                                    child: Row(
                                        children: const [
                                          Icon(Icons.verified,
                                              color: Color(
                                                  0xFF7B2FFF),
                                              size: 10),
                                          SizedBox(width: 3),
                                          Text(
                                              'Verified Coach',
                                              style: TextStyle(
                                                  color: Color(
                                                      0xFF7B2FFF),
                                                  fontSize: 9,
                                                  fontWeight:
                                                  FontWeight
                                                      .w600)),
                                        ]),
                                  ),
                                ]),
                                const Text(
                                    'Head Coach • India U19',
                                    style: TextStyle(
                                        color:
                                        Colors.white38,
                                        fontSize: 11)),
                                const SizedBox(height: 6),
                                const Text(
                                    '"Aarav is a dedicated and hard-working player with great technique and a strong cricketing mindset."',
                                    style: TextStyle(
                                        color:
                                        Colors.white60,
                                        fontSize: 12,
                                        height: 1.4,
                                        fontStyle: FontStyle
                                            .italic)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.end,
                            children: const [
                              Text('5.0',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight:
                                      FontWeight.w800,
                                      fontSize: 18)),
                              Icon(Icons.star,
                                  color:
                                  Color(0xFF7B2FFF),
                                  size: 16),
                              SizedBox(height: 4),
                              Text('12 May 2025',
                                  style: TextStyle(
                                      color:
                                      Colors.white38,
                                      fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
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
                              'Add match videos, highlights and performances',
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
                      onChanged: (v) => setState(
                              () => _notificationsOn = v),
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
                      onChanged: (v) =>
                          setState(() => _darkMode = v),
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
                      onChanged: (v) => setState(
                              () => _emailAlerts = v),
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
                      onChanged: (v) => setState(
                              () => _privateProfile = v),
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
                      onChanged: (v) =>
                          setState(() => _locationOn = v),
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
                    onTap: () =>
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                            content: Text(
                                'Opening Privacy Policy...'),
                            backgroundColor:
                            Color(0xFF7B2FFF))),
                  ),

                  _SettingsTile(
                    icon: Icons.description_outlined,
                    color: const Color(0xFF7B2FFF),
                    title: 'Terms of Service',
                    subtitle: 'Read our terms',
                    trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.white24),
                    onTap: () =>
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                            content: Text(
                                'Opening Terms of Service...'),
                            backgroundColor:
                            Color(0xFF7B2FFF))),
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
  final _nameCtrl =
  TextEditingController(text: 'Aarav Mehta');
  final _roleCtrl =
  TextEditingController(text: 'Batsman');
  final _teamCtrl =
  TextEditingController(text: 'Alpha Warriors');
  final _locationCtrl =
  TextEditingController(text: 'Mumbai, India');
  final _schoolCtrl =
  TextEditingController(text: 'St. Xavier\'s School');
  final _bioCtrl = TextEditingController(
      text:
      'Right-handed batter with a love for the game.\nAlways working to get better and help my team win. 🏏');

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
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(
                      content:
                      Text('Profile updated! ✅'),
                      backgroundColor:
                      Color(0xFF7B2FFF)));
                },
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
                        child: Image.network(
                          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(
                                color: const Color(0xFF1A1A1A),
                                child: const Icon(Icons.person,
                                    color: Colors.white,
                                    size: 52),
                              ),
                        ),
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
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(
                          content:
                          Text('Profile updated! ✅'),
                          backgroundColor:
                          Color(0xFF7B2FFF)));
                    },
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
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(
                        content:
                        Text('Camera opened 📷'),
                        backgroundColor:
                        Color(0xFF7B2FFF)));
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
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(
                        content:
                        Text('Gallery opened 🖼️'),
                        backgroundColor:
                        Color(0xFF7B2FFF)));
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
  late List<Map<String, dynamic>> _notifications = [
    {
      'icon': Icons.emoji_events,
      'color': const Color(0xFFFFB300),
      'title': 'Points Added!',
      'subtitle': '+52 Qo points added to your profile',
      'time': '2m ago',
      'read': false,
    },
    {
      'icon': Icons.people,
      'color': const Color(0xFF7B2FFF),
      'title': 'New Follower',
      'subtitle': 'Rahul Sharma started following you',
      'time': '15m ago',
      'read': false,
    },
    {
      'icon': Icons.sports_cricket,
      'color': const Color(0xFF00C853),
      'title': 'League Update',
      'subtitle': 'Summer League 2024 is now live!',
      'time': '1h ago',
      'read': false,
    },
    {
      'icon': Icons.favorite,
      'color': Colors.red,
      'title': 'Post Liked',
      'subtitle': 'Jason liked your match highlight',
      'time': '2h ago',
      'read': true,
    },
    {
      'icon': Icons.shield,
      'color': const Color(0xFF7B2FFF),
      'title': 'Match Scheduled',
      'subtitle': 'Alpha Warriors vs Thunder on 24 May',
      'time': '3h ago',
      'read': true,
    },
    {
      'icon': Icons.star,
      'color': const Color(0xFFFFB300),
      'title': 'Achievement Unlocked!',
      'subtitle':
      'You scored 100+ in a single match 🎉',
      'time': '1d ago',
      'read': true,
    },
    {
      'icon': Icons.person_add,
      'color': const Color(0xFF7B2FFF),
      'title': 'Coach Recommended You',
      'subtitle':
      'Coach Rahul recommended you to a club',
      'time': '1d ago',
      'read': true,
    },
    {
      'icon': Icons.emoji_events,
      'color': const Color(0xFF00C853),
      'title': 'Rank Improved!',
      'subtitle': 'You moved from #16 to #14',
      'time': '2d ago',
      'read': true,
    },
  ];

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
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20),
              itemCount: _notifications.length,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final n = _notifications[i];
                return GestureDetector(
                  onTap: () => setState(() {
                    _notifications[i] = {
                      ..._notifications[i],
                      'read': true,
                    };
                  }),
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
          child: Image.network(
            item['image'],
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(color: const Color(0xFF1A1A1A)),
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
  bool _isPlaying = false;
  double _progress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(children: [
          GestureDetector(
            onTap: () =>
                setState(() => _isPlaying = !_isPlaying),
            child: SizedBox(
              width: double.infinity,
              height: MediaQuery.of(context).size.height *
                  0.4,
              child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.network(
                      widget.item['image'],
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(
                              color:
                              const Color(0xFF1A1A1A)),
                    ),
                    Container(
                        color:
                        Colors.black.withOpacity(0.3)),
                    Container(
                      width: 64, height: 64,
                      decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle),
                      child: Icon(
                          _isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.white,
                          size: 36),
                    ),
                    Positioned(
                      top: 16, left: 16,
                      child: GestureDetector(
                        onTap: () =>
                            Navigator.pop(context),
                        child: Container(
                          width: 36, height: 36,
                          decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle),
                          child: const Icon(
                              Icons.arrow_back_ios,
                              color: Colors.white,
                              size: 18),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: Colors.white24,
                        color: const Color(0xFF7B2FFF),
                        minHeight: 3,
                      ),
                    ),
                  ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(widget.item['title'],
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Row(children: [
                  Text(widget.item['subtitle'],
                      style: const TextStyle(
                          color: Color(0xFF7B2FFF),
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const Text(' • ',
                      style: TextStyle(
                          color: Colors.white38)),
                  Text(widget.item['date'],
                      style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 13)),
                ]),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceAround,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() =>
                      _progress = (_progress - 0.1)
                          .clamp(0.0, 1.0)),
                      child: const Icon(Icons.replay_10,
                          color: Colors.white, size: 32),
                    ),
                    GestureDetector(
                      onTap: () => setState(() =>
                      _isPlaying = !_isPlaying),
                      child: Container(
                        width: 60, height: 60,
                        decoration: const BoxDecoration(
                            color: Color(0xFF7B2FFF),
                            shape: BoxShape.circle),
                        child: Icon(
                            _isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                            size: 32),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() =>
                      _progress = (_progress + 0.1)
                          .clamp(0.0, 1.0)),
                      child: const Icon(Icons.forward_10,
                          color: Colors.white, size: 32),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────

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