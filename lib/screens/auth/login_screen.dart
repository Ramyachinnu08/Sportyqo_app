import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../api/services.dart';
import '../../api/ui_helpers.dart';
import '../player/home_screen.dart';
import '../coach/coach_home_screen.dart';
import 'choose_role_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _submitting = false;
  String _selectedRole = 'Player';

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      showInfo(context, 'Enter your email and password.');
      return;
    }
    setState(() => _submitting = true);
    try {
      await AuthService.login(
        email: email,
        password: password,
        role: _selectedRole == 'Player' ? 'player' : 'coach',
      );
      if (!mounted) return;
      final home = _selectedRole == 'Player'
          ? const HomeScreen() as Widget
          : const CoachHomeScreen() as Widget;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => home),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'ROLE_MISMATCH') {
        showInfo(context,
            '${e.message} Try switching the Player/Coach toggle.');
      } else {
        showApiError(context, e);
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Back ──
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios,
                    color: Colors.white, size: 20),
              ),

              const SizedBox(height: 32),

              // ── Title ──
              const Text('Welcome\nBack! 👋',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      height: 1.2)),

              const SizedBox(height: 8),

              const Text('Login to your SportyQo account',
                  style: TextStyle(
                      color: Colors.white54, fontSize: 14)),

              const SizedBox(height: 32),

              // ── Role Toggle ──
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(children: [
                  _RoleTab(
                    label: 'Player',
                    isActive: _selectedRole == 'Player',
                    color: const Color(0xFF7B2FFF),
                    onTap: () => setState(
                            () => _selectedRole = 'Player'),
                  ),
                  _RoleTab(
                    label: 'Coach',
                    isActive: _selectedRole == 'Coach',
                    color: const Color(0xFF00C853),
                    onTap: () => setState(
                            () => _selectedRole = 'Coach'),
                  ),
                ]),
              ),

              const SizedBox(height: 24),

              // ── Email ──
              _InputField(
                label: 'Email',
                hint: 'Enter your email',
                controller: _emailController,
                icon: Icons.email_outlined,
              ),

              const SizedBox(height: 16),

              // ── Password ──
              _InputField(
                label: 'Password',
                hint: 'Enter your password',
                controller: _passwordController,
                icon: Icons.lock_outline,
                obscure: _obscurePassword,
                suffixIcon: GestureDetector(
                  onTap: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                  child: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.white38,
                    size: 20,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Forgot Password ──
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {},
                  child: const Text('Forgot Password?',
                      style: TextStyle(
                          color: Color(0xFF00C853),
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
              ),

              const SizedBox(height: 32),

              // ── Login Button ──
              GestureDetector(
                onTap: _submitting ? null : _login,
                child: Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _selectedRole == 'Player'
                        ? const Color(0xFF7B2FFF)
                        : const Color(0xFF00C853),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: _submitting
                        ? const ButtonSpinner()
                        : const Text('Login',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Divider ──
              Row(children: [
                const Expanded(
                    child: Divider(color: Colors.white10)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or continue with',
                      style: TextStyle(
                          color: Colors.white38, fontSize: 12)),
                ),
                const Expanded(
                    child: Divider(color: Colors.white10)),
              ]),

              const SizedBox(height: 24),

              // ── Social Buttons ──
              Row(children: [
                Expanded(
                  child: _SocialButton(
                    label: 'Google',
                    emoji: '🌐',
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SocialButton(
                    label: 'Apple',
                    emoji: '🍎',
                    onTap: () {},
                  ),
                ),
              ]),

              const SizedBox(height: 32),

              // ── Register ──
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                        const ChooseRoleScreen()),
                  ),
                  child: RichText(
                    text: const TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'Sign Up',
                          style: TextStyle(
                              color: Color(0xFF00C853),
                              fontWeight: FontWeight.w700),
                        ),
                      ],
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

class _RoleTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;
  const _RoleTab(
      {required this.label,
        required this.isActive,
        required this.color,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color:
                    isActive ? Colors.white : Colors.white38,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label, emoji;
  final VoidCallback onTap;
  const _SocialButton(
      {required this.label,
        required this.emoji,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final IconData icon;
  final bool obscure;
  final Widget? suffixIcon;
  const _InputField(
      {required this.label,
        required this.hint,
        required this.controller,
        required this.icon,
        this.obscure = false,
        this.suffixIcon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: const TextStyle(
                color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                  color: Colors.white24, fontSize: 14),
              prefixIcon:
              Icon(icon, color: Colors.white38, size: 20),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}