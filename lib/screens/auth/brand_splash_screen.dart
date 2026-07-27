import 'package:flutter/material.dart';
import '../../api/services.dart';
import '../coach/coach_home_screen.dart';
import '../player/home_screen.dart';
import 'choose_role_screen.dart';
import 'login_screen.dart';

/// First and only splash screen: pure black background with the SportyQo
/// logo pushed toward the top third of the viewport and Get Started + Log In
/// buttons at the bottom. When the user is already signed in, we skip the
/// buttons entirely and route them to their home page.
class BrandSplashScreen extends StatefulWidget {
  const BrandSplashScreen({super.key});

  @override
  State<BrandSplashScreen> createState() => _BrandSplashScreenState();
}

class _BrandSplashScreenState extends State<BrandSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool _checkingSession = true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    _boot();
  }

  /// Restore a saved session (rotating refresh token). If the user has an
  /// active session we auto-route to their home page; otherwise we stay
  /// here and show the Get Started / Log In buttons.
  Future<void> _boot() async {
    final results = await Future.wait([
      AuthService.tryRestore(),
      Future.delayed(const Duration(milliseconds: 1400)),
    ]);
    if (!mounted) return;
    final user = results.first as Map<String, dynamic>?;

    if (user != null && user['onboarding_stage'] == 'complete') {
      final next = user['role'] == 'coach'
          ? const CoachHomeScreen()
          : const HomeScreen();
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, animation, __) => FadeTransition(
            opacity: animation,
            child: next,
          ),
        ),
      );
    } else {
      // No active session — reveal the auth buttons.
      setState(() => _checkingSession = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final logoSize = screenWidth * 0.85;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Push logo into the upper third of the screen.
            const Spacer(flex: 2),
            FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Image.network(
                  'https://i.ibb.co/hFXzg4m3/304161.jpg',
                  width: logoSize,
                  height: logoSize,
                  fit: BoxFit.contain,
                  loadingBuilder:
                      (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      width: logoSize,
                      height: logoSize,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white24,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Text(
                      'SportyQo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
            ),
            const Spacer(flex: 1),
            // Buttons appear after the session check finishes (so users
            // with a saved session are never briefly shown Get Started
            // before being routed to their home page).
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _checkingSession ? 0.0 : 1.0,
              child: IgnorePointer(
                ignoring: _checkingSession,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  child: Column(children: [
                    // Get Started — primary CTA.
                    SizedBox(
                      width: double.infinity,
                      height: 68,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          const Color(0xFF00C853),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(36),
                          ),
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                              const ChooseRoleScreen()),
                        ),
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: const [
                            Text('Get Started',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight:
                                    FontWeight.w800)),
                            SizedBox(width: 10),
                            Icon(Icons.arrow_forward,
                                size: 24),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Log In — secondary.
                    SizedBox(
                      width: double.infinity,
                      height: 68,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(
                              color: Colors.white24),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(36),
                          ),
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                              const LoginScreen()),
                        ),
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.person_outline,
                                size: 22),
                            SizedBox(width: 10),
                            Text('Log In',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight:
                                    FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    // Trusted-by tagline.
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.verified,
                            color: Colors.white38,
                            size: 16),
                        SizedBox(width: 6),
                        Text(
                            'Trusted by athletes & coaches worldwide',
                            style: TextStyle(
                                color: Colors.white54,
                                fontSize: 13)),
                      ],
                    ),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}