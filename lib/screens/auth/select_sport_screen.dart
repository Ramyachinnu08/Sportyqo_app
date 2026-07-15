import 'package:flutter/material.dart';
import 'generating_id_screen.dart';

class SelectSportScreen extends StatefulWidget {
  const SelectSportScreen({super.key});

  @override
  State<SelectSportScreen> createState() =>
      _SelectSportScreenState();
}

class _SelectSportScreenState
    extends State<SelectSportScreen> {
  String? _selectedSport;

  final List<Map<String, String>> _sports = [
    {
      'name': 'Cricket',
      'image': 'https://i.ibb.co/5g8XNRnC/296480.jpg',
    },
    {
      'name': 'Football',
      'image': 'https://i.ibb.co/vCBQG4Wn/IMG-20260715-WA0018.jpg',
    },
    {
      'name': 'Volleyball',
      'image': 'https://i.ibb.co/zHh6mvNv/296486.jpg',
    },
    {
      'name': 'Basketball',
      'image': 'https://i.ibb.co/3y3shwwB/296487.jpg',
    },
    {
      'name': 'Swimming',
      'image': 'https://i.ibb.co/9H4ZFMCM/296483.jpg',
    },
    {
      'name': 'Badminton',
      'image': 'https://i.ibb.co/5gFFcxtn/296482.jpg',
    },
    {
      'name': 'Tennis',
      'image': 'https://i.ibb.co/B5nvZTjc/296481.jpg',
    },
    {
      'name': 'Kabaddi',
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
              padding: const EdgeInsets.fromLTRB(
                  20, 16, 20, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios,
                      color: Colors.white, size: 20),
                ),
              ]),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: const [
                  Text('Select Your Sport',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800)),
                  SizedBox(height: 6),
                  Text('Choose the sport you play',
                      style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Sports Grid (image only) ──
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20),
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
                  final isSelected =
                      _selectedSport == sport['name'];

                  return GestureDetector(
                    onTap: () => setState(() =>
                    _selectedSport = sport['name']),
                    child: AnimatedContainer(
                      duration: const Duration(
                          milliseconds: 200),
                      decoration: BoxDecoration(
                        borderRadius:
                        BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF7B2FFF)
                              : Colors.white10,
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                          BoxShadow(
                            color: const Color(
                                0xFF7B2FFF)
                                .withOpacity(0.4),
                            blurRadius: 16,
                            spreadRadius: 1,
                          ),
                        ]
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius:
                        BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Sport image
                            Image.network(
                              sport['image']!,
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
                                          0xFF7B2FFF),
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

                            // Selected checkmark
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
                                        0xFF7B2FFF),
                                    shape:
                                    BoxShape.circle,
                                    border: Border.all(
                                        color:
                                        Colors.white,
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

            // ── Continue Button ──
            Padding(
              padding: const EdgeInsets.all(20),
              child: GestureDetector(
                onTap: _selectedSport == null
                    ? null
                    : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        GeneratingIdScreen(
                          selectedSport:
                          _selectedSport!,
                        ),
                  ),
                ),
                child: AnimatedContainer(
                  duration:
                  const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 16),
                  decoration: BoxDecoration(
                    color: _selectedSport == null
                        ? Colors.white10
                        : const Color(0xFF7B2FFF),
                    borderRadius:
                    BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      Text('Continue',
                          style: TextStyle(
                              color: _selectedSport ==
                                  null
                                  ? Colors.white38
                                  : Colors.white,
                              fontWeight:
                              FontWeight.w700,
                              fontSize: 16)),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward,
                          color: _selectedSport == null
                              ? Colors.white38
                              : Colors.white,
                          size: 18),
                    ],
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