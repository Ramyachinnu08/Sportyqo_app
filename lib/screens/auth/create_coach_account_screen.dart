import 'package:flutter/material.dart';
import '../../api/services.dart';
import '../../api/ui_helpers.dart';
import '../../theme/app_theme.dart';
import 'enter_mobile_screen.dart';
import 'login_screen.dart';

class CreateCoachAccountScreen extends StatefulWidget {
  const CreateCoachAccountScreen({super.key});

  @override
  State<CreateCoachAccountScreen> createState() =>
      _CreateCoachAccountScreenState();
}

class _CreateCoachAccountScreenState extends State<CreateCoachAccountScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreeToTerms = false;
  bool _submitting = false;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  /// Capitalize the first letter of every word: "suneeth kumar" → "Suneeth Kumar".
  String _titleCase(String s) => s
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');

  Future<void> _signUp() async {
    final name = _titleCase(_nameCtrl.text.trim());
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      showInfo(context, 'Please fill in your name, email and password.');
      return;
    }
    if (password != _confirmCtrl.text) {
      showInfo(context, 'Passwords do not match.');
      return;
    }
    if (!_agreeToTerms) {
      showInfo(context, 'Please agree to the Terms to continue.');
      return;
    }
    setState(() => _submitting = true);
    try {
      await AuthService.register(
        fullName: name,
        email: email,
        password: password,
        role: 'coach',
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EnterMobileScreen()),
      );
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.arrow_back_ios,
                    color: isDark ? AppColors.textWhite : AppColors.textDark),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Create Coach Account',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.textWhite : AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  "Let's get you started",
                  style: TextStyle(fontSize: 14, color: AppColors.textGrey),
                ),
              ),
              const SizedBox(height: 32),
              _buildTextField(
                hint: 'Full Name',
                icon: Icons.person_outline,
                isDark: isDark,
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 14),
              _buildTextField(
                hint: 'Email Address',
                icon: Icons.email_outlined,
                isDark: isDark,
                keyboardType: TextInputType.emailAddress,
                controller: _emailCtrl,
              ),
              const SizedBox(height: 14),
              _buildTextField(
                hint: 'Phone Number',
                icon: Icons.phone_outlined,
                isDark: isDark,
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              _buildTextField(
                hint: 'Password',
                controller: _passwordCtrl,
                icon: Icons.lock_outline,
                isDark: isDark,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textGrey,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 14),
              _buildTextField(
                hint: 'Confirm Password',
                controller: _confirmCtrl,
                icon: Icons.lock_outline,
                isDark: isDark,
                obscureText: _obscureConfirm,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textGrey,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _agreeToTerms,
                    onChanged: (v) =>
                        setState(() => _agreeToTerms = v ?? false),
                    activeColor: const Color(0xFF00C853),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'I agree to the ',
                            style: TextStyle(
                                color: AppColors.textGrey, fontSize: 13),
                          ),
                          TextSpan(
                            text: 'Terms of Service',
                            style: TextStyle(
                                color: Color(0xFF00C853), fontSize: 13),
                          ),
                          TextSpan(
                            text: ' and ',
                            style: TextStyle(
                                color: AppColors.textGrey, fontSize: 13),
                          ),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                                color: Color(0xFF00C853), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _submitting
                      ? const ButtonSpinner()
                      : const Text('Sign Up',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                          const LoginScreen())),
                  child: RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Already have an account? ',
                          style:
                          TextStyle(color: AppColors.textGrey, fontSize: 14),
                        ),
                        TextSpan(
                          text: 'Login',
                          style: TextStyle(
                              color: Color(0xFF00C853),
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
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

  Widget _buildTextField({
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    TextEditingController? controller,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textCapitalization: textCapitalization,
      style: TextStyle(
          color: isDark ? AppColors.textWhite : AppColors.textDark),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.textGrey, size: 20),
        suffixIcon: suffixIcon,
        contentPadding:
        const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }
}

