import 'package:flutter/material.dart';
import 'dart:math' show pi;
import '../../api/services.dart';
import '../../api/ui_helpers.dart';
import 'player_id_ready_screen.dart';

class GeneratingIdScreen extends StatefulWidget {
  final String selectedSport;
  const GeneratingIdScreen(
      {super.key, required this.selectedSport});

  @override
  State<GeneratingIdScreen> createState() =>
      _GeneratingIdScreenState();
}

class _GeneratingIdScreenState
    extends State<GeneratingIdScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _allocateId();
  }

  /// The Player ID is minted SERVER-SIDE (unique, sequential per year).
  /// This screen just animates while the request is in flight.
  Future<void> _allocateId() async {
    try {
      final results = await Future.wait([
        UserService.selectSport(sport: widget.selectedSport),
        // keep the generating animation visible for a beat
        Future.delayed(const Duration(milliseconds: 1200)),
      ]);
      final res = results.first as Map<String, dynamic>;
      await UserService.me(); // refresh cached session with player_id
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PlayerIdReadyScreen(
            playerId: res['player_id'] as String,
            selectedSport: widget.selectedSport,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showApiError(context, e);
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [

              // ── Title ──
              const Text(
                'Generating\nPlayer ID...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 50),

              // ── Spinner ──
              SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    RotationTransition(
                      turns: _spinController,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              const Color(0xFF7B2FFF)
                                  .withOpacity(0.0),
                              const Color(0xFF7B2FFF)
                                  .withOpacity(0.9),
                            ],
                            startAngle: 0,
                            endAngle: 2 * pi,
                          ),
                        ),
                        child: Padding(
                          padding:
                          const EdgeInsets.all(6),
                          child: Container(
                            decoration:
                            const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF0A0A1A),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Center icon
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF7B2FFF)
                            .withOpacity(0.15),
                        border: Border.all(
                          color:
                          const Color(0xFF7B2FFF),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Color(0xFF7B2FFF),
                        size: 44,
                      ),
                    ),

                    // Check badge
                    Positioned(
                      bottom: 28,
                      right: 28,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration:
                        const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF00C853),
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 50),

              // ── Subtitle ──
              const Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: 50),
                child: Text(
                  'Please wait while we\ncreate your unique\nPlayer ID.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Loading dots ──
              Row(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: List.generate(
                  3,
                      (i) => Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B2FFF)
                          .withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}