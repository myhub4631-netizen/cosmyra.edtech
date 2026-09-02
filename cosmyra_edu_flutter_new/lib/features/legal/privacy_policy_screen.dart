import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/supabase_service.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  String _policyContent = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPolicy();
  }

  Future<void> _loadPolicy() async {
    setState(() => _isLoading = true);
    final text = await SupabaseService.fetchPrivacyPolicy();
    if (mounted) {
      setState(() {
        _policyContent = text;
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
                            'LEGAL & COMPLIANCE',
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
                          'Privacy Policy',
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
                          _policyContent.isNotEmpty ? _policyContent : defaultPrivacyPolicyText,
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

const String defaultPrivacyPolicyText = '''Privacy Policy

Effective Date: September 3, 2026

Privacy Policy for Cosmyra NEET JEE

Cosmyra Technologies Pvt. Ltd. ("Cosmyra", "we", "our", or "us") operates Cosmyra NEET JEE / ExamPrep, an educational platform designed to help students prepare for NEET, JEE and other competitive examinations through practice questions, tests, previous-year questions, performance analytics, study tools and related educational services.

This Privacy Policy explains how we collect, use, store, protect and disclose information when you use our website, mobile application and related services.

By using Cosmyra NEET JEE, you agree to the practices described in this Privacy Policy.

1. Information We Collect

We may collect the following categories of information.

A. Account Information
When you create an account, we may collect:
• Name
• Email address
• Password or authentication credentials
• Profile picture, if provided
• Phone number, if provided
• Date of birth or age, if required for our services
• Class, examination preference and educational information
• Other information you voluntarily provide in your profile

B. Information Received Through Google Sign-In
If you choose "Sign in with Google", we use Google's authentication service to authenticate your account.

Depending on the permissions granted and the Google authentication configuration, we may receive basic account information such as:
• Your name
• Email address
• Google profile picture
• Google account identifier associated with the authentication

We use this information to:
• Create or identify your Cosmyra account
• Authenticate you securely
• Maintain your user profile
• Provide access to your account and educational services
• Associate your learning activity with your account

We do not receive or store your Google Account password.
We do not request access to your Gmail messages, Google Drive files, contacts or other Google services unless such access is explicitly requested and separately disclosed.

2. Educational and Activity Information
When you use our platform, we may collect information about your learning activity, including questions attempted, test results, scores, rankings, time spent, study streaks, and saved questions. This information is used to provide personalized learning, performance analysis, rankings, and educational statistics.

3. Device and Technical Information
We may automatically collect limited technical information necessary to operate, secure and improve our services, such as device type, operating system, browser information, IP address, and diagnostic logs.

4. How We Use Your Information
We use collected information to authenticate users, deliver NEET and JEE educational content, calculate scores, maintain practice history, provide analytics, detect abuse, and comply with legal obligations.

5. How We Use Google User Data
If you use Google Sign-In, Google user information received by Cosmyra is used only for purposes related to providing and operating the requested authentication and account features.
• We do not sell Google user data.
• We do not use Google user data for advertising or sell it to advertising networks or data brokers.
• We do not use Google user data for creditworthiness, lending or similar purposes.
• We only request Google permissions that are necessary for the functionality we provide.
Our handling of Google user data follows the applicable Google API Services User Data Policy and Limited Use requirements.

6. Data Sharing and Disclosure
We do not sell your personal information. We may share limited information with trusted service providers when necessary to operate our platform (such as cloud hosting, databases, authentication, error monitoring).

7. Leaderboards and Public Information
Cosmyra may provide optional leaderboard and ranking features displaying scores, percentiles, and ranks to participating students.

8. Data Storage and Security
We take reasonable technical and organizational measures to protect personal information using HTTPS/TLS encryption and secure cloud infrastructure.

9. Data Retention
We retain information for as long as reasonably necessary to provide our services and preserve educational history.

10. Account and Data Deletion
You may request deletion of your Cosmyra account and associated personal information by contacting us at cosmyra.in@gmail.com.

11. Children's Privacy
We do not knowingly request unnecessary personal information from children. Parents or guardians should assist minors in using educational services.

12. Cookies and Similar Technologies
Our website may use cookies and local storage for authentication sessions and website functionality.

13. Third-Party Services
Third-party services process information according to their own privacy policies.

14. Changes to This Privacy Policy
Material changes will be published with a revised "Effective Date."

15. Your Rights
You may request access, correction, or deletion of your personal data at any time.

16. Contact Us
Cosmyra Technologies Pvt. Ltd.
Product: Cosmyra NEET JEE / ExamPrep
Website: neet-jee.in
Email: cosmyra.in@gmail.com
Subject: Privacy / Data Deletion Request

Google User Data Disclosure
Cosmyra does not sell Google user data and does not use Google user data for advertising.

Last Updated: September 3, 2026
Effective: September 3, 2026''';
