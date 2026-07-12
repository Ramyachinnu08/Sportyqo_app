import 'package:flutter/material.dart';

/// One section of a legal document: numbered heading, optional body
/// paragraph, optional bullet points.
class LegalSection {
  final String heading;
  final String body;
  final List<String> bullets;
  final String? afterBullets;
  const LegalSection(this.heading,
      {this.body = '', this.bullets = const [], this.afterBullets});
}

const String kLegalEffectiveDate = 'Effective date: 12 July 2026';

const List<LegalSection> kTermsSections = [
  LegalSection('1. Eligibility',
      body:
          'Users must be at least 13 years of age (or the minimum age permitted under applicable laws). Users under 18 must use SportyQo with the consent of a parent or legal guardian.'),
  LegalSection('2. Account Security',
      body:
          'Users are responsible for maintaining the confidentiality of their login credentials and for all activities conducted through their account.'),
  LegalSection('3. Verification Disclaimer',
      body:
          'Verification indicates that certain information has been reviewed by SportyQo. It does not guarantee the quality, conduct, qualifications, or future performance of any player, coach, academy, or organization.'),
  LegalSection('4. Medical & Sports Disclaimer',
      body:
          'Participation in sports carries inherent risks. SportyQo is not responsible for injuries, accidents, medical conditions, or losses arising from participation in sporting activities.'),
  LegalSection('5. Match & Statistics Disclaimer',
      body:
          'SportyQo relies on information entered by authorized users. While reasonable efforts are made to maintain accuracy, SportyQo does not guarantee that all statistics or records are error-free.'),
  LegalSection('6. Copyright Infringement',
      body:
          'Users should upload only content they own. If someone reports copyright infringement, SportyQo may remove the content.'),
  LegalSection('7. Account Suspension & Termination',
      body: 'SportyQo can suspend accounts if users:',
      bullets: [
        'Cheat',
        'Create fake profiles',
        'Abuse others',
        'Manipulate scores',
        'Violate laws',
        'Attempt to hack the platform',
      ]),
  LegalSection('8. Service Availability',
      body:
          'The service is provided on an "as available" basis. Interruptions may occur due to:',
      bullets: [
        'Maintenance',
        'Updates',
        'Server downtime',
        'Bugs',
      ]),
  LegalSection('9. Intellectual Property',
      body: 'The following are owned by BasicSports Ventures Pvt. Ltd.:',
      bullets: [
        'SportyQo name and logo',
        'UI design',
        'Features',
        'Qo Score system',
        'Software',
        'Branding',
      ],
      afterBullets:
          'They cannot be copied or reproduced without written permission.'),
];

const List<LegalSection> kPrivacySections = [
  LegalSection('1. Location Data',
      body:
          'Location information may be collected only with your permission and solely to provide location-based features, such as:',
      bullets: [
        'Nearby leagues',
        'City rankings',
      ]),
  LegalSection('2. Data Retention',
      body:
          'We retain personal information only for as long as necessary to provide our services, comply with legal obligations, resolve disputes, and enforce our agreements.'),
  LegalSection('3. Account Deletion',
      body:
          'Users may request deletion of their account. Certain information may be retained where required by law or for legitimate business purposes.'),
  LegalSection('4. Third-Party Services',
      body:
          'We may use trusted third-party services to operate SportyQo, including:',
      bullets: [
        'Cloud hosting',
        'Push notifications',
        'OTP verification',
        'Payment gateway',
        'Analytics',
        'Crash reporting',
      ]),
  LegalSection('5. User-Generated Content',
      body:
          'Information you choose to make public, including your profile, achievements, match statistics, certificates, photos, videos, and posts, may be visible to other users according to your privacy settings.'),
  LegalSection('6. Security Disclaimer',
      body:
          'While we implement reasonable safeguards to protect your information, no method of electronic transmission or storage is completely secure.'),
  LegalSection('7. Contact Information',
      body: 'For privacy-related questions, you can reach us at:',
      bullets: [
        'BasicSports Ventures Pvt. Ltd.',
        'Registered Office: [address]',
        'Support Email: [support email]',
        'Website: [website]',
      ]),
];

/// Renders a legal document (Terms & Conditions or Privacy Policy)
/// in the app's dark theme.
class LegalScreen extends StatelessWidget {
  final String title;
  final List<LegalSection> sections;
  const LegalScreen(
      {super.key, required this.title, required this.sections});

  static Route termsRoute() => MaterialPageRoute(
      builder: (_) => const LegalScreen(
          title: 'Terms & Conditions', sections: kTermsSections));

  static Route privacyRoute() => MaterialPageRoute(
      builder: (_) => const LegalScreen(
          title: 'Privacy Policy', sections: kPrivacySections));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
              ),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                const Text(kLegalEffectiveDate,
                    style: TextStyle(
                        color: Colors.white38, fontSize: 12)),
                const SizedBox(height: 20),
                for (final s in sections) ...[
                  Text(s.heading,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  if (s.body.isNotEmpty)
                    Text(s.body,
                        style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 13.5,
                            height: 1.55)),
                  if (s.bullets.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    for (final b in s.bullets)
                      Padding(
                        padding:
                            const EdgeInsets.only(left: 8, bottom: 4),
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text('•  ',
                                style: TextStyle(
                                    color: Color(0xFF7B2FFF),
                                    fontSize: 13.5,
                                    height: 1.55)),
                            Expanded(
                              child: Text(b,
                                  style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 13.5,
                                      height: 1.55)),
                            ),
                          ],
                        ),
                      ),
                  ],
                  if (s.afterBullets != null) ...[
                    const SizedBox(height: 4),
                    Text(s.afterBullets!,
                        style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 13.5,
                            height: 1.55)),
                  ],
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
