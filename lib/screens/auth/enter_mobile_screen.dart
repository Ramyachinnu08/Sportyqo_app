import 'package:flutter/material.dart';
import '../../api/services.dart';
import '../../api/ui_helpers.dart';
import '../../theme/app_theme.dart';
import 'verification_sent_screen.dart';

class EnterMobileScreen extends StatefulWidget {
  const EnterMobileScreen({super.key});

  @override
  State<EnterMobileScreen> createState() => _EnterMobileScreenState();
}

class _EnterMobileScreenState extends State<EnterMobileScreen> {
  final _phoneCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final digits = _phoneCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 10) {
      showInfo(context, 'Enter a valid 10-digit mobile number.');
      return;
    }
    setState(() => _submitting = true);
    try {
      final res = await AuthService.sendOtp('+91$digits');
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerificationSentScreen(
            requestId: res['request_id'] as String,
            maskedPhone: res['masked_phone'] as String? ?? '+91 $digits',
            devCode: res['dev_code'] as String?,
          ),
        ),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.arrow_back_ios,
                    color: isDark ? AppColors.textWhite : AppColors.textDark),
              ),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  'Enter Mobile Number',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.textWhite : AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'We will send updates on SMS and WhatsApp',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.textGrey),
                ),
              ),
              const SizedBox(height: 40),
              // Phone input
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: isDark ? AppColors.darkBorder : Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : Colors.grey[300]!),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text('+91',
                              style: TextStyle(
                                  color: isDark
                                      ? AppColors.textWhite
                                      : AppColors.textDark,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down,
                              color: AppColors.textGrey, size: 18),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(
                            color: isDark
                                ? AppColors.textWhite
                                : AppColors.textDark),
                        decoration: const InputDecoration(
                          hintText: '98765 43210',
                          hintStyle: TextStyle(color: AppColors.textGrey),
                          border: InputBorder.none,
                          contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Phone illustration
              Center(
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C853).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone_android,
                      size: 80, color: Color(0xFF00C853)),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Your number is safe with us 🔒',
                  style: TextStyle(color: AppColors.textGrey, fontSize: 13),
                ),
              ),
              const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _sendCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _submitting
                      ? const ButtonSpinner()
                      : const Text('Continue',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
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