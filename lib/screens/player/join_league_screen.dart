import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../api/api_client.dart';
import '../../api/services.dart';
import '../../api/ui_helpers.dart';
import '../../theme/app_theme.dart';

class JoinLeagueScreen extends StatefulWidget {
  final Function(String teamName, String leagueName)? onJoined;
  const JoinLeagueScreen({super.key, this.onJoined});

  @override
  State<JoinLeagueScreen> createState() => _JoinLeagueScreenState();
}

class _JoinLeagueScreenState extends State<JoinLeagueScreen> {
  int _step = 0;
  final _codeCtrl = TextEditingController();
  bool _busy = false;
  String? _selectedTeam;
  String? _selectedTeamId;
  Map<String, dynamic>? _league; // from GET /leagues/by-code/{code}
  List<Map<String, dynamic>> _teams = [];

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  String get _leagueName =>
      (_league?['name'] as String?) ?? 'this league';

  Future<void> _lookupLeague() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length < 6) {
      showInfo(context, 'Enter the full league code (e.g. FALC-16-24).');
      return;
    }
    setState(() => _busy = true);
    try {
      final league = await LeagueService.findByCode(code);
      if (!mounted) return;
      if (league == null) {
        showInfo(context, "That league code doesn't exist.");
        return;
      }
      setState(() {
        _league = league;
        _teams = (league['teams'] as List<dynamic>)
            .map((t) => <String, dynamic>{
                  'id': t['id'],
                  'name': t['name'],
                  'division': league['cricket_type'] ?? '',
                  'players': t['player_count'] ?? 0,
                  'emoji': '🏏',
                })
            .toList();
        _selectedTeam = null;
        _selectedTeamId = null;
        _step = 1;
      });
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _joinLeague() async {
    if (_selectedTeamId == null || _league == null) return;
    setState(() => _busy = true);
    try {
      await LeagueService.join(
        leagueCode: (_league!['league_code'] ?? _codeCtrl.text.trim())
            .toString()
            .toUpperCase(),
        teamId: _selectedTeamId!,
      );
      if (!mounted) return;
      setState(() => _step = 2);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'ALREADY_MEMBER') {
        setState(() => _step = 2); // treat as success — they're in
      } else {
        showApiError(context, e);
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: _step == 0
            ? _buildEnterCode()
            : _step == 1
            ? _buildSelectTeam()
            : _buildSuccess(),
      ),
    );
  }

  // ── STEP 1: Enter League Code ──
  Widget _buildEnterCode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                                text: 'Join League',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800)),
                            TextSpan(
                                text: '.',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                          'Enter the league code shared\nby your coach or organizer.',
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                              height: 1.5)),
                    ],
                  ),
                ),
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      AppColors.primary.withOpacity(0.3),
                      Colors.transparent
                    ]),
                  ),
                  child: const Center(
                      child: Text('🏆', style: TextStyle(fontSize: 36))),
                ),
              ]),
            ],
          ),
        ),
        const Spacer(),
        Center(
          child: Column(children: [
            const Icon(Icons.grid_view_rounded,
                color: AppColors.primary, size: 32),
            const SizedBox(height: 16),
            const Text('Enter League Code',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text(
                'Ask your coach or organizer for the\nleague code (e.g. FALC-16-24)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 13)),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: TextField(
                controller: _codeCtrl,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[A-Za-z0-9\-]')),
                  LengthLimitingTextInputFormatter(16),
                ],
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: 'FALC-16-24',
                  hintStyle: const TextStyle(
                      color: Colors.white24, letterSpacing: 3),
                  filled: true,
                  fillColor: const Color(0xFF0F0F2A),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Colors.white12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.lock_outline, color: AppColors.primary, size: 14),
                SizedBox(width: 6),
                Text('Secure & Private',
                    style: TextStyle(color: AppColors.primary, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Your league code is safe with us.',
                style: TextStyle(color: Colors.white38, fontSize: 11)),
          ]),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_codeCtrl.text.trim().length >= 6 && !_busy)
                  ? _lookupLeague
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withOpacity(0.3),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Continue',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
        ),

      ],
    );
  }

  // ── STEP 2: Choose Your Team ──
  Widget _buildSelectTeam() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () => setState(() => _step = 0),
            child: const Icon(Icons.arrow_back_ios,
                color: Colors.white, size: 20),
          ),
        ),
      ),
      const SizedBox(height: 12),
      _StepIndicator(currentStep: 1),
      const SizedBox(height: 20),
      const Icon(Icons.people_alt_outlined,
          color: AppColors.primary, size: 36),
      const SizedBox(height: 12),
      const Text('Choose Your Team',
          style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      RichText(
        textAlign: TextAlign.center,
        text: TextSpan(children: [
          const TextSpan(
              text: 'Select the team you want to join in\n',
              style: TextStyle(color: Colors.white54, fontSize: 13)),
          TextSpan(
              text: '$_leagueName.',
              style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F2A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  shape: BoxShape.circle),
              child: const Center(
                  child: Text('🏆', style: TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('LEAGUE',
                    style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        letterSpacing: 1)),
                Text(_leagueName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                Text((_league?['location'] as String?) ?? '',
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ]),
        ),
      ),
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Align(
          alignment: Alignment.centerLeft,
          child: const Text('AVAILABLE TEAMS',
              style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600)),
        ),
      ),
      const SizedBox(height: 10),
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _teams.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final t = _teams[i];
            final isSelected = _selectedTeam == t['name'];
            return GestureDetector(
              onTap: () => setState(() {
                _selectedTeam = t['name'] as String;
                _selectedTeamId = t['id'] as String?;
              }),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0F2A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.white12,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                        child: Text(t['emoji'] as String,
                            style: const TextStyle(fontSize: 24))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t['name'] as String,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                        Text(t['division'] as String,
                            style: const TextStyle(
                                color: AppColors.primary, fontSize: 12)),
                        Row(children: [
                          const Icon(Icons.people_outline,
                              color: Colors.white38, size: 13),
                          const SizedBox(width: 4),
                          Text('${t['players']} Players',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 12)),
                        ]),
                      ],
                    ),
                  ),
                  // ── View Players button ──
                  GestureDetector(
                    onTap: () {
                      showInfo(context,
                          'Roster is visible after you join the team.');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(Icons.visibility_outlined,
                          color: Colors.white60, size: 16),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                      border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.white24,
                          width: 2),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check,
                        color: Colors.white, size: 14)
                        : null,
                  ),
                ]),
              ),
            );
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (_selectedTeam == null || _busy)
                ? null
                : _joinLeague,
            icon: const Icon(Icons.arrow_forward,
                color: Colors.white, size: 18),
            label: const Text('Continue',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withOpacity(0.3),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.lock_outline, color: Colors.white38, size: 12),
            SizedBox(width: 4),
            Text('Your data is safe and secure with us.',
                style: TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
      ),
    ]);
  }

  // ── STEP 3: League Joined! ──
  Widget _buildSuccess() {
    return SingleChildScrollView(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => setState(() => _step = 1),
              child: const Icon(Icons.arrow_back_ios,
                  color: Colors.white, size: 20),
            ),
          ),
        ),
        const SizedBox(height: 30),
        Stack(alignment: Alignment.center, children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppColors.primary.withOpacity(0.4),
                Colors.transparent
              ]),
            ),
          ),
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 48),
          ),
        ]),
        const SizedBox(height: 24),
        const Text('League Joined!',
            style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('You have successfully joined the league.',
            style: TextStyle(color: Colors.white54, fontSize: 14)),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F2A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _teams.firstWhere(
                          (t) => t['name'] == _selectedTeam,
                      orElse: () => {'emoji': '🦅'},
                    )['emoji'] as String,
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(_selectedTeam ?? '',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('U16 Division',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white10),
              const SizedBox(height: 12),
              Row(children: [
                const Text('🏆', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_leagueName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    const Text('',
                        style: TextStyle(
                            color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
              'Your matches, stats and Qo Points\nwill now be tracked.',
              textAlign: TextAlign.center,
              style:
              TextStyle(color: Colors.white38, fontSize: 13, height: 1.5)),
        ),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (widget.onJoined != null && _selectedTeam != null) {
                    widget.onJoined!(
                      _selectedTeam!,
                      _leagueName,
                    );
                  }
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_forward,
                    color: Colors.white, size: 18),
                label: const Text('Go to League',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Back Home',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70)),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }
}

// ── Step Indicator ────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final steps = ['Code Entered', 'Select Team', 'Joined'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(steps.length, (i) {
        final isDone = i < currentStep;
        final isActive = i == currentStep;
        return Row(children: [
          Column(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone || isActive
                    ? AppColors.primary
                    : Colors.white10,
                border: Border.all(
                    color: isDone || isActive
                        ? AppColors.primary
                        : Colors.white24,
                    width: 2),
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check,
                    color: Colors.white, size: 16)
                    : Text('${i + 1}',
                    style: TextStyle(
                        color:
                        isActive ? Colors.white : Colors.white38,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 4),
            Text(steps[i],
                style: TextStyle(
                    color: isActive ? Colors.white : Colors.white38,
                    fontSize: 10)),
          ]),
          if (i < steps.length - 1)
            Container(
              width: 40,
              height: 2,
              margin: const EdgeInsets.only(bottom: 16),
              color: i < currentStep ? AppColors.primary : Colors.white12,
            ),
        ]);
      }),
    );
  }
}

// ── Team Roster Screen ──────────────────────────────────────────────────
