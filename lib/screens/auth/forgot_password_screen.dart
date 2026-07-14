import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/services.dart';
import '../../api/ui_helpers.dart';
import '../../theme/app_theme.dart';

/// Step 1: ask for the account email; the backend emails a reset token.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _submitting = false;

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      showInfo(context, 'Please enter a valid email.');
      return;
    }
    setState(() => _submitting = true);
    try {
      await AuthService.forgotPassword(email);
      if (!mounted) return;
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => ResetPasswordScreen(email: email)));
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        showApiError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios,
                    color: Colors.white, size: 20),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                      const Text('Forgot\nPassword? 🔑',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              height: 1.2)),
                      const SizedBox(height: 10),
                      const Text(
                          'Enter your account email and we will send you a reset code.',
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                              height: 1.4)),
                      const SizedBox(height: 32),
                      const Text('Email',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'you@example.com',
                          hintStyle:
                              const TextStyle(color: Colors.white24),
                          prefixIcon: const Icon(Icons.mail_outline,
                              color: Colors.white38, size: 20),
                          filled: true,
                          fillColor: const Color(0xFF15152E),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none),
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Send Reset Code',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Step 2: enter the token from the email plus a new password.
class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _tokenCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _submitting = false;
  bool _obscure = true;

  Future<void> _submit() async {
    final token = _tokenCtrl.text.trim();
    final pass = _passCtrl.text;
    if (token.isEmpty) {
      showInfo(context, 'Paste the reset code from your email.');
      return;
    }
    if (pass.length < 8) {
      showInfo(context,
          'Password must be at least 8 characters with a letter and a number.');
      return;
    }
    setState(() => _submitting = true);
    try {
      await AuthService.resetPassword(
          token: token, newPassword: pass);
      if (!mounted) return;
      showInfo(context,
          'Password reset! Log in with your new password.');
      Navigator.popUntil(context, (r) => r.isFirst);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showApiError(context, e);
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        showApiError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios,
                    color: Colors.white, size: 20),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                      const Text('Reset\nPassword 🔒',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              height: 1.2)),
                      const SizedBox(height: 10),
                      Text(
                          'We sent a reset code to ${widget.email}. Paste it below and choose a new password.',
                          style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                              height: 1.4)),
                      const SizedBox(height: 32),
                      const Text('Reset code',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _tokenCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Paste the code from the email',
                          hintStyle:
                              const TextStyle(color: Colors.white24),
                          prefixIcon: const Icon(Icons.vpn_key_outlined,
                              color: Colors.white38, size: 20),
                          filled: true,
                          fillColor: const Color(0xFF15152E),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('New password',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'At least 8 chars, letter + number',
                          hintStyle:
                              const TextStyle(color: Colors.white24),
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: Colors.white38, size: 20),
                          suffixIcon: GestureDetector(
                            onTap: () =>
                                setState(() => _obscure = !_obscure),
                            child: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.white38,
                                size: 20),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF15152E),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none),
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Reset Password',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
