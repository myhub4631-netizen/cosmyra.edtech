import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/supabase_service.dart';

class TermsOfServiceScreen extends StatefulWidget {
  const TermsOfServiceScreen({Key? key}) : super(key: key);

  @override
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen> {
  String _termsContent = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTerms();
  }

  Future<void> _loadTerms() async {
    setState(() => _isLoading = true);
    final text = await SupabaseService.fetchTermsOfService();
    if (mounted) {
      setState(() {
        _termsContent = text;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school_rounded, color: Color(0xFF0D7A53), size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'ExamPrep / Cosmyra',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/privacy-policy'),
            icon: const Icon(Icons.privacy_tip_outlined, size: 16, color: Color(0xFF475569)),
            label: const Text('Privacy', style: TextStyle(color: Color(0xFF475569))),
          ),
          TextButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.home_rounded, size: 18, color: Color(0xFF0D7A53)),
            label: const Text('Home', style: TextStyle(color: Color(0xFF0D7A53), fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 20 : 32,
                    vertical: 32,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(isMobile ? 20 : 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'LEGAL & TERMS',
                            style: TextStyle(
                              color: Color(0xFF0D7A53),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Terms of Service',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Effective Date: September 3, 2026',
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                        const Divider(height: 36, color: Color(0xFFE2E8F0)),

                        // Render Policy Sections
                        SelectableText(
                          _termsContent.isNotEmpty ? _termsContent : defaultTermsOfServiceText,
                          style: const TextStyle(
                            fontSize: 14.5,
                            height: 1.65,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

const String defaultTermsOfServiceText = '''Terms of Service — Cosmyra NEET JEE

Effective Date: September 3, 2026
Last Updated: September 3, 2026

Welcome to Cosmyra NEET JEE / ExamPrep, an educational platform operated by Cosmyra Technologies Pvt. Ltd. These Terms of Service ("Terms", "Terms of Service") govern your access to and use of our website, mobile applications, educational content, tests, practice tools, subscriptions and related services.

By accessing or using Cosmyra NEET JEE, you agree to these Terms. If you do not agree with these Terms, please do not use our services.

1. About Cosmyra NEET JEE
Cosmyra NEET JEE is an online examination-preparation platform designed to help students prepare for competitive examinations, including NEET and JEE. Our services include practice questions, custom practice, custom tests, PYQs, NTA questions, test series, performance analytics, leaderboards, and study tools.

2. Eligibility
You may use Cosmyra NEET JEE only if you are legally capable of entering into an agreement under applicable law. Minors should use the platform with parental or guardian involvement where required.

3. Account Registration
Certain features require an account. You may register using supported methods including Email and Google Sign-In. You are responsible for maintaining credential security and all activity on your account.

4. Google Sign-In
If you choose to sign in using Google, authentication is provided through Google's services and governed by Google's terms and our Privacy Policy. Cosmyra does not receive or store your Google account password.

5. Educational Content
Cosmyra provides practice sets, tests, explanations, and insights for study purposes. We make reasonable efforts to maintain accuracy, but users should independently verify critical academic information.

6. Examination Disclaimer
Cosmyra NEET JEE is an independent educational platform. Unless explicitly stated otherwise, Cosmyra is not affiliated with or endorsed by NTA, NEET, JEE, IITs, or government examination authorities. We do not guarantee admission, qualification marks, rank, or selection.

7. Practice, Tests and Scores
Calculated scores, marks, percentiles, accuracy, streaks, and ranks are educational metrics based on internal algorithms and do not represent official government examination results.

8. Leaderboards
Optional leaderboards encourage healthy competition. Cosmyra reserves the right to adjust or remove entries in case of technical errors, cheating, manipulation, or abuse.

9. Points System
Where point systems operate, scoring rules displayed within the platform apply and may be updated when necessary.

10. User Conduct
Users agree to use the platform for lawful educational purposes. Content redistribution, commercial resale, unauthorized scraping, bot manipulation, account sharing, and reverse engineering are strictly prohibited.

11. Intellectual Property
All content, designs, logos, question databases, solutions, software, and features are owned by or licensed to Cosmyra Technologies Pvt. Ltd.

12. Previous-Year Questions and Third-Party Content
Third-party examination questions and materials remain subject to the rights of their respective owners.

13. Subscriptions and Paid Services
Features, prices, validity, and terms for subscription plans are displayed before purchase.

14. Payments
Payments are processed via authorized third-party payment gateways.

15. Refunds and Cancellations
Refund eligibility depends on the specific product policy displayed at purchase. Contact support for billing concerns.

16. Account Suspension and Termination
We reserve the right to suspend or terminate accounts that violate terms, engage in cheating, or abuse infrastructure.

17. Account Deletion
You may request account and data deletion by contacting support.

18. Service Availability
We strive for continuous availability but do not guarantee uninterrupted operation during maintenance or unforeseen events.

19. Third-Party Services
Third-party providers (hosting, auth, analytics) operate under their respective terms and policies.

20. Privacy
Your platform use is also governed by our Privacy Policy available at neet-jee.in/privacy-policy.

21. Changes to the Platform
We may update features, question banks, or algorithms to improve learning outcomes.

22. Changes to These Terms
Updated terms will be posted with a revised Effective Date.

23. Disclaimer of Warranties
Services are provided on an "as is" and "as available" basis without guarantees of specific exam results.

24. Limitation of Liability
To the maximum extent permitted by law, Cosmyra Technologies Pvt. Ltd. is not liable for indirect or consequential damages.

25. Indemnification
Users agree to indemnify Cosmyra against claims arising from violation of terms or platform misuse.

26. Governing Law
These Terms are governed by the laws of India, subject to the jurisdiction of competent courts in India.

27. Contact Us
Cosmyra Technologies Pvt. Ltd.
Product: Cosmyra NEET JEE / ExamPrep
Website: neet-jee.in
Email: cosmyra.in@gmail.com
Subject: Terms of Service / Support''';
