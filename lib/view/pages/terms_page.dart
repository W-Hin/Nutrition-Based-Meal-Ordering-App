import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  static const _cream  = Color(0xFFF5F0E8);
  static const _green  = Color(0xFF1E4620);
  static const _dark   = Color(0xFF2D2D2D);
  static const _orange = Color(0xFFD95B2B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        foregroundColor: _dark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _green,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.gavel_rounded, color: Colors.white, size: 36),
                  const SizedBox(height: 10),
                  const Text(
                    'NuBurn Terms & Conditions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Effective Date: 1 January 2025',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _section('1. Acceptance of Terms',
              'By accessing and using the NuBurn mobile application ("App"), you agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use the App.'),

            _section('2. Use of the App',
              'NuBurn is designed to assist users in tracking nutritional intake, ordering healthy meals, and achieving personal wellness goals. You must be at least 13 years old to use the App. You are responsible for maintaining the confidentiality of your account credentials.'),

            _section('3. Health Disclaimer',
              'The nutritional information, BMI calculations, and calorie recommendations provided by NuBurn are for informational purposes only. They do not constitute medical advice. Always consult a qualified healthcare professional before making significant changes to your diet or lifestyle.\n\nNuBurn is aligned with UN Sustainable Development Goals SDG #2 (Zero Hunger) and SDG #3 (Good Health & Well-Being).'),

            _section('4. User Account',
              'You are responsible for all activities that occur under your account. You must provide accurate and complete information during registration. NuBurn reserves the right to suspend or terminate accounts that violate these Terms.'),

            _section('5. Orders & Payments',
              'All meal orders placed through the App are subject to availability. Prices are displayed in Malaysian Ringgit (MYR) and are inclusive of applicable taxes. Refund requests are subject to review by the merchant and will be processed within 5–7 business days if approved.'),

            _section('6. Privacy Policy',
              'NuBurn collects and processes personal data including name, email, phone number, location, and health metrics (height, weight, BMI) for the purpose of providing personalised meal recommendations and nutrition tracking.\n\nYour data is stored securely via Supabase and is not shared with third parties without your consent, except as required by law.'),

            _section('7. Intellectual Property',
              'All content within the App, including the NuBurn logo, branding, interfaces, and nutritional content, is the intellectual property of the NuBurn development team. Unauthorised reproduction or distribution is strictly prohibited.'),

            _section('8. Limitation of Liability',
              'To the maximum extent permitted by applicable law, NuBurn shall not be liable for any indirect, incidental, or consequential damages arising from your use of the App, including but not limited to health outcomes, financial losses, or data loss.'),

            _section('9. Changes to Terms',
              'NuBurn reserves the right to update these Terms at any time. Continued use of the App after changes constitutes acceptance of the revised Terms. We will notify registered users of significant changes via email.'),

            _section('10. Contact Us',
              'For any questions regarding these Terms & Conditions, please contact us at:\n\nsupport@nuburn.app\n\nTunku Abdul Rahman University of Management and Technology (TAR UMT)\nKuala Lumpur, Malaysia'),

            const SizedBox(height: 20),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _orange.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: _orange, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'By registering, you confirm that you have read and agree to these Terms & Conditions.',
                      style: TextStyle(color: _orange, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('I Understand', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _dark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              fontSize: 13,
              color: _dark.withOpacity(0.7),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 4),
          Divider(color: _dark.withOpacity(0.08)),
        ],
      ),
    );
  }
}
