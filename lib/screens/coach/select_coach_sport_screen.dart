import 'package:flutter/material.dart';
import '../../api/services.dart';
import '../../api/ui_helpers.dart';
import 'coach_home_screen.dart';

class SelectCoachSportScreen extends StatefulWidget {
  const SelectCoachSportScreen({super.key});

  @override
  State<SelectCoachSportScreen> createState() =>
      _SelectCoachSportScreenState();
}

class _SelectCoachSportScreenState extends State<SelectCoachSportScreen> {
  String? _selectedSport;
  bool _submitting = false;

  Future<void> _continueAsCoach() async {
    setState(() => _submitting = true);
    try {
      await CoachService.updateProfile(sport: _selectedSport);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const CoachHomeScreen()),
            (route) => false,
      );
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  final List<Map<String, dynamic>> _sports = [
    {
      'name': 'Cricket',
      'emoji': '🏏',
      'image': 'https://i.ibb.co/5g8XNRnC/296480.jpg',
    },
    {
      'name': 'Football',
      'emoji': '⚽',
      'image': 'https://i.ibb.co/vCBQG4Wn/IMG-20260715-WA0018.jpg',
    },
    {
      'name': 'Volleyball',
      'emoji': '🏐',
      'image': 'https://i.ibb.co/zHh6mvNv/296486.jpg',
    },
    {
      'name': 'Basketball',
      'emoji': '🏀',
      'image': 'https://i.ibb.co/3y3shwwB/296487.jpg',
    },
    {
      'name': 'Swimming',
      'emoji': '🏊',
      'image': 'https://i.ibb.co/9H4ZFMCM/296483.jpg',
    },
    {
      'name': 'Badminton',
      'emoji': '🏸',
      'image': 'https://i.ibb.co/5gFFcxtn/296482.jpg',
    },
    {
      'name': 'Tennis',
      'emoji': '🎾',
      'image': 'https://i.ibb.co/B5nvZTjc/296481.jpg',
    },
    {
      'name': 'Kabaddi',
      'emoji': '🤼',
      'image': 'https://i.ibb.co/KTPKmR1/296484.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(height: 24),
                  RichText(
                    text: const TextSpan(children: [
                      TextSpan(
                        text: 'Select Your Sport',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800),
                      ),
                      TextSpan(
                        text: '.',
                        style: TextStyle(
                            color: Color(0xFF00C853),
                            fontSize: 26,
                            fontWeight: FontWeight.w800),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Choose the sport you coach.',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Sports Grid ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.builder(
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: _sports.length,
                  itemBuilder: (context, i) {
                    final sport = _sports[i];
                    final isSelected = _selectedSport == sport['name'];
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedSport = sport['name']),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF00C853)
                                : Colors.white12,
                            width: isSelected ? 2.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                            BoxShadow(
                              color: const Color(0xFF00C853)
                                  .withOpacity(0.25),
                              blurRadius: 12,
                              spreadRadius: 1,
                            )
                          ]
                              : [],
                        ),
                        child: ClipRRect(
                          borderRadius:
                          BorderRadius.circular(16),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                sport['image'] as String,
                                fit: BoxFit.cover,
                                alignment: Alignment
                                    .bottomCenter,
                                loadingBuilder: (context,
                                    child, progress) {
                                  if (progress == null) {
                                    return child;
                                  }
                                  return Container(
                                    color: const Color(
                                        0xFF13132B),
                                    child: const Center(
                                      child:
                                      CircularProgressIndicator(
                                        color: Color(
                                            0xFF00C853),
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder:
                                    (_, __, ___) =>
                                    Container(
                                      color: const Color(
                                          0xFF13132B),
                                      child: const Icon(
                                          Icons
                                              .image_outlined,
                                          color:
                                          Colors.white24,
                                          size: 40),
                                    ),
                              ),
                              if (isSelected)
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration:
                                    BoxDecoration(
                                      color: const Color(
                                          0xFF00C853),
                                      shape:
                                      BoxShape.circle,
                                      border: Border.all(
                                          color: Colors
                                              .white,
                                          width: 2),
                                    ),
                                    child: const Icon(
                                        Icons.check,
                                        color:
                                        Colors.white,
                                        size: 16),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ── Continue Button ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_selectedSport == null || _submitting)
                      ? null
                      : _continueAsCoach,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    disabledBackgroundColor:
                    const Color(0xFF00C853).withOpacity(0.3),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    _selectedSport == null
                        ? 'Select a Sport'
                        : 'Continue as $_selectedSport Coach',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}