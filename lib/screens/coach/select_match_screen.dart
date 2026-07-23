import 'package:flutter/material.dart';
import '../../api/services.dart';
import '../../api/ui_helpers.dart';
import '../../theme/app_theme.dart';
import 'select_players_screen.dart';

class SelectMatchScreen extends StatefulWidget {
  final String leagueId;
  final String leagueName;
  const SelectMatchScreen(
      {super.key, required this.leagueId, required this.leagueName});

  @override
  State<SelectMatchScreen> createState() => _SelectMatchScreenState();
}

class _SelectMatchScreenState extends State<SelectMatchScreen> {
  int _tabIndex = 0;

  List<Map<String, dynamic>> _matches = [];
  List<Map<String, dynamic>> _teams = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _fmtD(String? iso) {
    final d = iso == null ? null : DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '';
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _fmtT(String? iso) {
    final d = iso == null ? null : DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '';
    final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '${h12.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} ${d.hour >= 12 ? 'PM' : 'AM'}';
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        LeagueService.matches(widget.leagueId),
        LeagueService.detail(widget.leagueId),
      ]);
      final res = results[0];
      final detail = results[1];
      final items = (res['items'] as List<dynamic>).map((raw) {
        final m = raw as Map<String, dynamic>;
        final apiStatus = m['status'] as String? ?? 'scheduled';
        final starts = DateTime.tryParse(m['starts_at'] as String? ?? '');
        String status;
        if (apiStatus == 'completed') {
          status = 'Completed';
        } else if (starts != null &&
            starts.isBefore(DateTime.now().toUtc()) &&
            apiStatus == 'scheduled') {
          status = 'Live';
        } else {
          status = 'Upcoming';
        }
        return <String, dynamic>{
          'id': m['id'],
          'team1': m['team_a']?['name'] ?? '',
          'team2': m['team_b']?['name'] ?? '',
          'team1_id': m['team_a']?['id'],
          'team2_id': m['team_b']?['id'],
          'date': _fmtD(m['starts_at'] as String?),
          'time': _fmtT(m['starts_at'] as String?),
          'venue': m['venue'] ?? 'TBD',
          'status': status,
        };
      }).toList();
      if (!mounted) return;
      setState(() {
        _matches = items;
        _teams = (detail['teams'] as List<dynamic>)
            .map((t) => <String, dynamic>{'id': t['id'], 'name': t['name']})
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showApiError(context, e);
      }
    }
  }

  Future<void> _scheduleMatch() async {
    if (_teams.length < 2) return;
    String? teamAId = _teams[0]['id'] as String?;
    String? teamBId = _teams[1]['id'] as String?;
    DateTime when = DateTime.now().add(const Duration(days: 1));
    final venueCtrl = TextEditingController();

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Schedule Match',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: teamAId,
              dropdownColor: const Color(0xFF1A1A1A),
              decoration: const InputDecoration(labelText: 'Team A'),
              style: const TextStyle(color: Colors.white),
              items: _teams
                  .map((t) => DropdownMenuItem(
                  value: t['id'] as String,
                  child: Text(t['name'] as String)))
                  .toList(),
              onChanged: (v) => setSheet(() => teamAId = v),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: teamBId,
              dropdownColor: const Color(0xFF1A1A1A),
              decoration: const InputDecoration(labelText: 'Team B'),
              style: const TextStyle(color: Colors.white),
              items: _teams
                  .map((t) => DropdownMenuItem(
                  value: t['id'] as String,
                  child: Text(t['name'] as String)))
                  .toList(),
              onChanged: (v) => setSheet(() => teamBId = v),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: venueCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Venue'),
            ),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${_fmtD(when.toIso8601String())} • ${_fmtT(when.toIso8601String())}',
                  style: const TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.calendar_today,
                  color: Color(0xFF1A6BFF), size: 18),
              onTap: () async {
                final d = await showDatePicker(
                    context: ctx,
                    initialDate: when,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)));
                if (d == null) return;
                final t = await showTimePicker(
                    context: ctx, initialTime: TimeOfDay.fromDateTime(when));
                setSheet(() => when = DateTime(d.year, d.month, d.day,
                    t?.hour ?? 18, t?.minute ?? 0));
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A6BFF)),
                child: const Text('Schedule',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ]),
        );
      }),
    );
    if (ok != true) return;
    if (teamAId == null || teamBId == null || teamAId == teamBId) {
      if (mounted) showInfo(context, 'Pick two different teams.');
      return;
    }
    try {
      await LeagueService.createMatch(
        leagueId: widget.leagueId,
        teamAId: teamAId!,
        teamBId: teamBId!,
        startsAt: when,
        venue: venueCtrl.text.trim().isEmpty ? null : venueCtrl.text.trim(),
      );
      if (mounted) _load();
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_tabIndex == 0) return _matches;
    if (_tabIndex == 1) return _matches.where((m) => m['status'] == 'Live').toList();
    if (_tabIndex == 2) return _matches.where((m) => m['status'] == 'Upcoming').toList();
    return _matches.where((m) => m['status'] == 'Completed').toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Live': return Colors.red;
      case 'Upcoming': return const Color(0xFF1A6BFF);
      case 'Completed': return const Color(0xFF00C853);
      default: return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scheduleMatch,
        backgroundColor: const Color(0xFF1A6BFF),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Schedule',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(children: [
                GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Select Match', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                      Text(widget.leagueName, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 16),

            // Tabs
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _Tab(label: 'All', isActive: _tabIndex == 0, onTap: () => setState(() => _tabIndex = 0)),
                  const SizedBox(width: 10),
                  _Tab(label: 'Live', isActive: _tabIndex == 1, onTap: () => setState(() => _tabIndex = 1), color: Colors.red),
                  const SizedBox(width: 10),
                  _Tab(label: 'Upcoming', isActive: _tabIndex == 2, onTap: () => setState(() => _tabIndex = 2)),
                  const SizedBox(width: 10),
                  _Tab(label: 'Completed', isActive: _tabIndex == 3, onTap: () => setState(() => _tabIndex = 3), color: const Color(0xFF00C853)),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A6BFF)))
                  : _filtered.isEmpty
                  ? const Center(child: Text('No matches yet — schedule one below', style: TextStyle(color: Colors.white38)))
                  : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final m = _filtered[i];
                  return GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SelectPlayersScreen(
                            leagueId: widget.leagueId,
                            matchId: m['id'] as String?,
                            teamAId: m['team1_id'] as String?,
                            teamBId: m['team2_id'] as String?,
                            completed: m['status'] == 'Completed',
                            teamName: m['team1'] as String,
                            matchName: '${m['team1']} vs ${m['team2']}',
                          ),
                        ),
                      );
                      // Reload so scores just entered stay visible (fixes
                      // "player score vanishes" — was stale cache before).
                      if (mounted) _load();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(children: [
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A6BFF).withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(child: Text('🦅', style: TextStyle(fontSize: 22))),
                                ),
                                const SizedBox(height: 6),
                                Text(m['team1'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.center),
                              ]),
                            ),
                            Column(children: [
                              const Text('VS', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w800, fontSize: 16)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _statusColor(m['status'] as String).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(children: [
                                  if (m['status'] == 'Live')
                                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), margin: const EdgeInsets.only(right: 4)),
                                  Text(m['status'] as String, style: TextStyle(color: _statusColor(m['status'] as String), fontSize: 11, fontWeight: FontWeight.w700)),
                                ]),
                              ),
                            ]),
                            Expanded(
                              child: Column(children: [
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
                                  child: const Center(child: Text('⚡', style: TextStyle(fontSize: 22))),
                                ),
                                const SizedBox(height: 6),
                                Text(m['team2'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.center),
                              ]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white10, height: 1),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(children: [
                              const Icon(Icons.calendar_today_outlined, color: Colors.white38, size: 12),
                              const SizedBox(width: 4),
                              Text(m['date'] as String, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                            ]),
                            Row(children: [
                              const Icon(Icons.access_time, color: Colors.white38, size: 12),
                              const SizedBox(width: 4),
                              Text(m['time'] as String, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                            ]),
                            Row(children: [
                              const Icon(Icons.location_on_outlined, color: Colors.white38, size: 12),
                              const SizedBox(width: 4),
                              Text(m['venue'] as String, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                            ]),
                          ],
                        ),
                      ]),
                    ),
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

class _Tab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color color;
  const _Tab({required this.label, required this.isActive, required this.onTap, this.color = const Color(0xFF1A6BFF)});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isActive ? null : Border.all(color: Colors.white24),
        ),
        child: Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.white38, fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }
}