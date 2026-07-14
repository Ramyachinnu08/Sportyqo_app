import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../../api/services.dart';
import '../../api/ui_helpers.dart';
import 'package:flutter/services.dart';
import 'share_league_code_screen.dart';

class CreateLeagueScreen extends StatefulWidget {
  const CreateLeagueScreen({super.key});

  @override
  State<CreateLeagueScreen> createState() =>
      _CreateLeagueScreenState();
}

class _CreateLeagueScreenState
    extends State<CreateLeagueScreen> {
  XFile? _logoFile;
  Uint8List? _logoBytes;

  Future<void> _pickLogo() async {
    final x = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    if (!mounted) return;
    setState(() {
      _logoFile = x;
      _logoBytes = bytes;
    });
  }

  http.MultipartFile? get _logoMultipart {
    if (_logoFile == null || _logoBytes == null) return null;
    final n = _logoFile!.name.toLowerCase();
    final mime = _logoFile!.mimeType ??
        (n.endsWith('.png')
            ? 'image/png'
            : n.endsWith('.webp')
                ? 'image/webp'
                : 'image/jpeg');
    final parts = mime.split('/');
    return http.MultipartFile.fromBytes('logo', _logoBytes!,
        filename: _logoFile!.name.isNotEmpty
            ? _logoFile!.name
            : 'league_logo.jpg',
        contentType: MediaType(parts[0], parts[1]));
  }

  int _step = 1;
  bool _busy = false;
  Map<String, dynamic>? _created; // POST /leagues response (server code)
  final _leagueNameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  String _gender = 'Men\'s';
  int _teamsCount = 8;
  String _leagueType = 'Professional Cricket';
  final List<TextEditingController> _teamControllers = [];

  final List<String> _leagueTypes = [
    'Gully Cricket',
    'Professional Cricket',
    'Box Cricket',
    'Tennis Ball Cricket',
    'Hard Ball Cricket',
    'Corporate Cricket',
    'Beach Cricket',
  ];

  @override
  void initState() {
    super.initState();
    // Empty editable slots — real names come from the coach.
    for (var i = 0; i < _teamsCount; i++) {
      _teamControllers
          .add(TextEditingController(text: 'Team ${i + 1}'));
    }
  }

  @override
  void dispose() {
    _leagueNameCtrl.dispose();
    _locationCtrl.dispose();
    for (final c in _teamControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addTeam() {
    setState(() {
      _teamsCount++;
      _teamControllers.add(TextEditingController(
          text: 'Team $_teamsCount'));
    });
  }

  void _removeTeam(int index) {
    if (_teamsCount <= 2) return;
    setState(() {
      _teamsCount--;
      _teamControllers[index].dispose();
      _teamControllers.removeAt(index);
    });
  }

  String _getTypeEmoji(String type) {
    switch (type) {
      case 'Gully Cricket': return '🏠';
      case 'Professional Cricket': return '🏆';
      case 'Box Cricket': return '📦';
      case 'Tennis Ball Cricket': return '🎾';
      case 'Hard Ball Cricket': return '🏏';
      case 'Corporate Cricket': return '💼';
      case 'Beach Cricket': return '🏖️';
      default: return '🏏';
    }
  }

  String _getTypeDescription(String type) {
    switch (type) {
      case 'Gully Cricket':
        return 'Casual street cricket played in neighborhoods. Fun format with flexible rules.';
      case 'Professional Cricket':
        return 'Competitive cricket with official rules, proper gear and umpires.';
      case 'Box Cricket':
        return 'Cricket played in an enclosed box court. Fast-paced and exciting format.';
      case 'Tennis Ball Cricket':
        return 'Cricket played with a tennis ball. Great for beginners and casual players.';
      case 'Hard Ball Cricket':
        return 'Traditional cricket with a hard leather ball. Full match format.';
      case 'Corporate Cricket':
        return 'Cricket tournament organized for corporate teams and office leagues.';
      case 'Beach Cricket':
        return 'Cricket played on a beach. Relaxed format with fun rules.';
      default:
        return 'Select a cricket type for your league.';
    }
  }

  /// The league code is minted SERVER-side on create (unique per league).
  Future<void> _submitLeague() async {
    final name = _leagueNameCtrl.text.trim();
    final teamNames = _teamControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (name.isEmpty) {
      showInfo(context, 'Give your league a name.');
      return;
    }
    if (teamNames.length < 2) {
      showInfo(context, 'A league needs at least 2 team names.');
      return;
    }
    if (teamNames.toSet().length != teamNames.length) {
      showInfo(context, 'Team names must be unique.');
      return;
    }
    setState(() => _busy = true);
    try {
      final created = await LeagueService.create(
        name: name,
        cricketType: _leagueType,
        gender: _gender,
        location: _locationCtrl.text.trim().isEmpty
            ? null
            : _locationCtrl.text.trim(),
        teamNames: teamNames,
        logo: _logoMultipart,
      );
      if (!mounted) return;
      setState(() {
        _created = created;
        _step = 2;
      });
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
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
            padding: const EdgeInsets.fromLTRB(
                20, 16, 20, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Create League',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
            ]),
          ),

          const SizedBox(height: 20),

          // ── Step Indicator ──
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 20),
            child: Row(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A6BFF),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: _step > 1
                      ? const Icon(Icons.check,
                      color: Colors.white, size: 16)
                      : const Text('1',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ),
              ),
              const SizedBox(width: 6),
              Text('League Details',
                  style: TextStyle(
                      color: _step >= 1
                          ? const Color(0xFF1A6BFF)
                          : Colors.white38,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8),
                  color: _step >= 2
                      ? const Color(0xFF1A6BFF)
                      : Colors.white12,
                ),
              ),
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: _step >= 2
                      ? const Color(0xFF1A6BFF)
                      : Colors.white12,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('2',
                      style: TextStyle(
                          color: _step >= 2
                              ? Colors.white
                              : Colors.white38,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ),
              ),
              const SizedBox(width: 6),
              Text('Generate Code',
                  style: TextStyle(
                      color: _step >= 2
                          ? const Color(0xFF1A6BFF)
                          : Colors.white38,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ]),
          ),

          const SizedBox(height: 20),

          // ── Content ──
          Expanded(
            child: _step == 1
                ? _buildStep1()
                : _buildStep2(),
          ),

          // ── Bottom Button ──
          if (_step == 1)
            Padding(
              padding: const EdgeInsets.all(20),
              child: GestureDetector(
                onTap: _busy ? null : _submitLeague,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A6BFF),
                    borderRadius:
                    BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: const [
                      Text('Continue',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward,
                          color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  // ── Step 1 ────────────────────────────────────────

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Let\'s build your league',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text(
              'Fill in the details below to create your league.',
              style: TextStyle(
                  color: Colors.white54, fontSize: 13)),

          const SizedBox(height: 24),

          // ── League Logo ──
          Center(
            child: GestureDetector(
              onTap: _pickLogo,
              child: Stack(children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF15251A),
                    border: Border.all(
                        color: const Color(0xFF00C853),
                        width: 2),
                  ),
                  child: ClipOval(
                    child: _logoBytes != null
                        ? Image.memory(_logoBytes!,
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover)
                        : const Icon(Icons.shield_outlined,
                            color: Colors.white38, size: 36),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                        color: Color(0xFF00C853),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.add_a_photo,
                        color: Colors.white, size: 14),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text('League logo (optional)',
                style: TextStyle(
                    color: Colors.white38, fontSize: 11)),
          ),

          const SizedBox(height: 20),

          // ── League Name ──
          _FieldLabel(
              icon: Icons.shield_outlined,
              label: 'League Name'),
          const SizedBox(height: 8),
          _InputField(controller: _leagueNameCtrl),

          const SizedBox(height: 16),

          // ── Cricket Type ──
          _FieldLabel(
              icon: Icons.sports_cricket,
              label: 'Cricket Type'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _leagueType,
                isExpanded: true,
                dropdownColor: const Color(0xFF111111),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Poppins'),
                icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white38),
                items: _leagueTypes
                    .map((type) => DropdownMenuItem(
                  value: type,
                  child: Row(children: [
                    Text(_getTypeEmoji(type),
                        style: const TextStyle(
                            fontSize: 18)),
                    const SizedBox(width: 10),
                    Text(type),
                  ]),
                ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _leagueType = v!),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A6BFF)
                  .withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFF1A6BFF)
                      .withOpacity(0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline,
                  color: Color(0xFF1A6BFF), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getTypeDescription(_leagueType),
                  style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      height: 1.4),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 16),

          // ── Location ──
          _FieldLabel(
              icon: Icons.location_on_outlined,
              label: 'League Location'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _locationCtrl,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                        vertical: 14),
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down,
                  color: Colors.white38),
            ]),
          ),

          const SizedBox(height: 16),

          // ── Gender ──
          _FieldLabel(
              icon: Icons.people_outline,
              label: 'Gender'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _gender = 'Men\'s'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14),
                    decoration: BoxDecoration(
                      color: _gender == 'Men\'s'
                          ? const Color(0xFF1A6BFF)
                          : Colors.transparent,
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text('Men\'s',
                          style: TextStyle(
                              color: _gender == 'Men\'s'
                                  ? Colors.white
                                  : Colors.white38,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(
                          () => _gender = 'Women\'s'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14),
                    decoration: BoxDecoration(
                      color: _gender == 'Women\'s'
                          ? const Color(0xFF1A6BFF)
                          : Colors.transparent,
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text('Women\'s',
                          style: TextStyle(
                              color: _gender == 'Women\'s'
                                  ? Colors.white
                                  : Colors.white38,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ),
                  ),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 16),

          // ── Teams Count ──
          _FieldLabel(
              icon: Icons.people_alt_outlined,
              label: 'Teams Count'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(children: [
              GestureDetector(
                onTap: () {
                  if (_teamsCount > 2) {
                    _removeTeam(
                        _teamControllers.length - 1);
                  }
                },
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius:
                    BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.remove,
                      color: Colors.white, size: 20),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text('$_teamsCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                ),
              ),
              GestureDetector(
                onTap: _addTeam,
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A6BFF),
                    borderRadius:
                    BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add,
                      color: Colors.white, size: 20),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 16),

          // ── Team Names ──
          _FieldLabel(
              icon: Icons.list_alt_outlined,
              label: 'Team Names'),
          const SizedBox(height: 6),
          const Text(
              'Enter the names of all teams in your league.',
              style: TextStyle(
                  color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 10),

          ..._teamControllers.asMap().entries.map(
                (entry) {
              final i = entry.key;
              final ctrl = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(12),
                  border:
                  Border.all(color: Colors.white10),
                ),
                child: Row(children: [
                  const SizedBox(width: 12),
                  const Icon(Icons.drag_handle,
                      color: Colors.white24, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding:
                        EdgeInsets.symmetric(
                            vertical: 14),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _removeTeam(i),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.delete_outline,
                          color: Colors.white24,
                          size: 20),
                    ),
                  ),
                ]),
              );
            },
          ),

          const SizedBox(height: 8),

          // ── Add Team ──
          GestureDetector(
            onTap: _addTeam,
            child: Row(
              mainAxisAlignment:
              MainAxisAlignment.center,
              children: const [
                Icon(Icons.add,
                    color: Color(0xFF1A6BFF), size: 18),
                SizedBox(width: 6),
                Text('Add Team',
                    style: TextStyle(
                        color: Color(0xFF1A6BFF),
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Step 2 ────────────────────────────────────────

  Widget _buildStep2() {
    final code = (_created?['league_code'] as String?) ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          // ── Success Animation ──
          SizedBox(
            width: 160, height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow rings
                Container(
                  width: 160, height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1A6BFF)
                        .withOpacity(0.05),
                  ),
                ),
                Container(
                  width: 130, height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1A6BFF)
                        .withOpacity(0.08),
                  ),
                ),
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1A6BFF)
                        .withOpacity(0.15),
                  ),
                ),
                // Shield icon
                Container(
                  width: 72, height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A6BFF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check,
                      color: Colors.white, size: 38),
                ),
                // Sparkles
                Positioned(
                  top: 10, right: 20,
                  child: Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A6BFF),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  top: 20, left: 15,
                  child: Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A6BFF),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 15, right: 15,
                  child: Container(
                    width: 10, height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A6BFF),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20, left: 20,
                  child: Container(
                    width: 7, height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A6BFF),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text('League Created!',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900)),

          const SizedBox(height: 8),

          const Text(
              'Your league has been created successfully.\nShare the code below with players\nto invite them to join.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  height: 1.5)),

          const SizedBox(height: 28),

          // ── League Code Box ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.white24,
                  style: BorderStyle.solid),
            ),
            child: Column(children: [
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  const Text('LEAGUE CODE',
                      style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600)),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: code));
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(
                          content: Text(
                              'Code copied! 📋'),
                          backgroundColor:
                          Color(0xFF1A6BFF)));
                    },
                    child: Row(children: const [
                      Icon(Icons.copy_outlined,
                          color: Color(0xFF1A6BFF),
                          size: 16),
                      SizedBox(width: 4),
                      Text('Copy',
                          style: TextStyle(
                              color: Color(0xFF1A6BFF),
                              fontSize: 13,
                              fontWeight:
                              FontWeight.w600)),
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Dashed border code box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.white24,
                      width: 1.5),
                ),
                child: Center(
                  child: Text(code,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3)),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 16),

          // ── Info ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A6BFF)
                  .withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF1A6BFF)
                      .withOpacity(0.2)),
            ),
            child: Row(children: const [
              Icon(Icons.info_outline,
                  color: Color(0xFF1A6BFF), size: 16),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                    'Players can use this code to join your league in the SportyQo app.',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        height: 1.4)),
              ),
            ]),
          ),

          const SizedBox(height: 24),

          // ── Share Via ──
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Share via',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ),

          const SizedBox(height: 14),

          Row(children: [
            // WhatsApp
            Expanded(
              child: GestureDetector(
                onTap: () =>
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(
                        content: Text(
                            'Opening WhatsApp...'),
                        backgroundColor:
                        Color(0xFF25D366))),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius:
                    BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white10),
                  ),
                  child: Column(children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.message,
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(height: 8),
                    const Text('WhatsApp',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight:
                            FontWeight.w600)),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Text Message
            Expanded(
              child: GestureDetector(
                onTap: () =>
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(
                        content:
                        Text('Opening Messages...'),
                        backgroundColor:
                        Color(0xFF1A6BFF))),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius:
                    BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white10),
                  ),
                  child: Column(children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A6BFF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                          Icons.sms_outlined,
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(height: 8),
                    const Text('Text Message',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight:
                            FontWeight.w600)),
                  ]),
                ),
              ),
            ),
          ]),

          const SizedBox(height: 24),

          // ── View League Dashboard ──
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  vertical: 16),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Colors.white24),
              ),
              child: Row(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: const [
                  Text('View League Dashboard',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward,
                      color: Colors.white, size: 18),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── Create Another League ──
          GestureDetector(
            onTap: () => setState(() {
              _step = 1;
              _leagueNameCtrl.text =
              'Falcons U16 Premier League';
              _locationCtrl.text =
              'Bangalore, Karnataka';
              _gender = 'Men\'s';
              _leagueType = 'Professional Cricket';
            }),
            child: const Text('Create Another League',
                style: TextStyle(
                    color: Color(0xFF1A6BFF),
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Field Label ───────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FieldLabel({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: Colors.white38, size: 16),
      const SizedBox(width: 8),
      Text(label,
          style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w500)),
    ]);
  }
}

// ── Input Field ───────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  const _InputField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(
            color: Colors.white, fontSize: 14),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}