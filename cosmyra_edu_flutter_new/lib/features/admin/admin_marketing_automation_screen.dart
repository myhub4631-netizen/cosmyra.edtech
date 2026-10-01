import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/brevo_email_service.dart';
import '../../core/services/whatsapp_service.dart';
import '../../core/services/ecommerce_automation_service.dart';
import '../../core/services/cart_service.dart';

class AdminMarketingAutomationScreen extends StatefulWidget {
  const AdminMarketingAutomationScreen({Key? key}) : super(key: key);

  @override
  State<AdminMarketingAutomationScreen> createState() => _AdminMarketingAutomationScreenState();
}

class _AdminMarketingAutomationScreenState extends State<AdminMarketingAutomationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Brevo Controllers
  final TextEditingController _brevoApiKeyCtrl = TextEditingController();
  final TextEditingController _brevoSenderEmailCtrl = TextEditingController();
  final TextEditingController _brevoSenderNameCtrl = TextEditingController();
  final TextEditingController _testEmailRecipientCtrl = TextEditingController();

  // WhatsApp Controllers
  final TextEditingController _waTokenCtrl = TextEditingController();
  final TextEditingController _waPhoneIdCtrl = TextEditingController();
  final TextEditingController _waBusinessIdCtrl = TextEditingController();
  final TextEditingController _testPhoneCtrl = TextEditingController();

  // Marketing Campaign Controllers
  final TextEditingController _campTitleCtrl = TextEditingController(text: 'NEET 2026 Ultimate Test Series Launch');
  final TextEditingController _campBannerCtrl = TextEditingController(text: '⚡ Exclusive 40% OFF for Early Birds!');
  final TextEditingController _campBodyCtrl = TextEditingController(text: 'Master NEET & JEE with NTA-pattern full length mock tests, instant AI analytics, and chapterwise PYQs. Boost your rank now!');
  final TextEditingController _campCtaTextCtrl = TextEditingController(text: 'Claim Discount & Start Test');
  final TextEditingController _campCtaLinkCtrl = TextEditingController(text: 'https://cosmyra.edu/test-series');
  final TextEditingController _campTestEmailCtrl = TextEditingController(text: 'info@neet-jee.in');
  final TextEditingController _campTestPhoneCtrl = TextEditingController(text: '9876543210');

  String _selectedTargetGroup = 'All Registered Students';
  bool _isSavingConfig = false;
  bool _isTestingFlow = false;
  bool _isDispatchingCampaign = false;
  Map<String, dynamic>? _lastCheckResult;
  Map<String, dynamic>? _lastCampaignReport;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInitialConfigs();
  }

  void _loadInitialConfigs() {
    _brevoApiKeyCtrl.text = BrevoEmailService.instance.apiKey;
    _brevoSenderEmailCtrl.text = BrevoEmailService.instance.senderEmail;
    _brevoSenderNameCtrl.text = BrevoEmailService.instance.senderName;
    _testEmailRecipientCtrl.text = BrevoEmailService.instance.senderEmail;

    _waTokenCtrl.text = WhatsAppService.instance.apiToken;
    _waPhoneIdCtrl.text = WhatsAppService.instance.phoneId;
    _testPhoneCtrl.text = '9876543210';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _brevoApiKeyCtrl.dispose();
    _brevoSenderEmailCtrl.dispose();
    _brevoSenderNameCtrl.dispose();
    _testEmailRecipientCtrl.dispose();
    _waTokenCtrl.dispose();
    _waPhoneIdCtrl.dispose();
    _waBusinessIdCtrl.dispose();
    _testPhoneCtrl.dispose();
    _campTitleCtrl.dispose();
    _campBannerCtrl.dispose();
    _campBodyCtrl.dispose();
    _campCtaTextCtrl.dispose();
    _campCtaLinkCtrl.dispose();
    _campTestEmailCtrl.dispose();
    _campTestPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveBrevoConfig() async {
    setState(() => _isSavingConfig = true);
    await BrevoEmailService.instance.setConfig(
      apiKey: _brevoApiKeyCtrl.text.trim(),
      senderEmail: _brevoSenderEmailCtrl.text.trim(),
      senderName: _brevoSenderNameCtrl.text.trim(),
    );
    setState(() => _isSavingConfig = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Brevo Email Configuration saved successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _saveWhatsAppConfig() async {
    setState(() => _isSavingConfig = true);
    await WhatsAppService.instance.setConfig(
      apiToken: _waTokenCtrl.text.trim(),
      phoneId: _waPhoneIdCtrl.text.trim(),
      businessId: _waBusinessIdCtrl.text.trim(),
    );
    setState(() => _isSavingConfig = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WhatsApp Cloud API Configuration saved!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _verifyWhatsAppPhone() async {
    final phone = _testPhoneCtrl.text.trim();
    if (phone.isEmpty) return;

    setState(() => _isTestingFlow = true);
    final res = await EcommerceAutomationService.instance.checkUserWhatsAppStatus(phone);
    if (mounted) {
      setState(() {
        _isTestingFlow = false;
        _lastCheckResult = res;
      });
    }
  }

  Future<void> _triggerTestFlow(String flowType) async {
    setState(() => _isTestingFlow = true);
    final testEmail = _testEmailRecipientCtrl.text.trim().isNotEmpty
        ? _testEmailRecipientCtrl.text.trim()
        : 'info@neet-jee.in';
    final testPhone = _testPhoneCtrl.text.trim().isNotEmpty
        ? _testPhoneCtrl.text.trim()
        : '9876543210';

    AutomationResult result;
    switch (flowType) {
      case 'account_creation':
        result = await EcommerceAutomationService.instance.triggerAccountCreationFlow(
          email: testEmail,
          fullName: 'Aman Kumar (Test User)',
          phone: testPhone,
        );
        break;
      case 'order_placed':
        result = await EcommerceAutomationService.instance.triggerOrderPlacedFlow(
          orderId: 'CSNJ2026TEST01',
          recipientEmail: testEmail,
          userName: 'Aman Kumar',
          phone: testPhone,
          totalAmount: 499.0,
          paymentMethod: 'UPI',
          items: [
            {'title': 'NEET 2026 Full Test Series', 'price': 499.0, 'validity': 'Valid 1 Year'}
          ],
        );
        break;
      case 'payment_due':
        result = await EcommerceAutomationService.instance.triggerPaymentDueFlow(
          orderId: 'CSNJ2026PENDING',
          recipientEmail: testEmail,
          userName: 'Aman Kumar',
          phone: testPhone,
          amountDue: 299.0,
          itemTitle: 'JEE Main Chapterwise Test Pass',
        );
        break;
      case 'password_reset':
        result = await EcommerceAutomationService.instance.triggerPasswordResetFlow(
          recipientEmail: testEmail,
          userName: 'Aman Kumar',
          phone: testPhone,
          otpCode: '849204',
        );
        break;
      case 'cart_recovery':
        result = await EcommerceAutomationService.instance.triggerCartRecoveryFlow(
          recipientEmail: testEmail,
          userName: 'Aman Kumar',
          phone: testPhone,
          cartItems: [
            CartItem(
              id: 'test_ts_1',
              title: 'NEET Ultimate Mock Package',
              price: 399.0,
              originalPrice: 999.0,
            )
          ],
          couponCode: 'COSMYRA20',
        );
        break;
      default:
        result = AutomationResult(
          emailSuccess: false,
          emailMessage: 'Unknown flow',
          whatsappSuccess: false,
          whatsappMessage: 'Unknown flow',
          hasWhatsAppAccount: false,
          formattedPhone: testPhone,
        );
    }

    if (mounted) {
      setState(() => _isTestingFlow = false);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.bolt_rounded, color: Color(0xFF4F46E5)),
              const SizedBox(width: 8),
              Text('Flow Execution Summary', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusBadge('Brevo Email', result.emailSuccess, result.emailMessage),
              const SizedBox(height: 12),
              _buildStatusBadge('WhatsApp Message', result.whatsappSuccess, result.whatsappMessage),
              const SizedBox(height: 12),
              Text('Phone: ${result.formattedPhone}', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[700])),
              Text('WhatsApp Account Present: ${result.hasWhatsAppAccount ? "YES ✅" : "NO ❌"}',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: result.hasWhatsAppAccount ? Colors.green : Colors.orange)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Close', style: GoogleFonts.inter(color: const Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildStatusBadge(String title, bool isSuccess, String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSuccess ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isSuccess ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isSuccess ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                  color: isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444), size: 18),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: isSuccess ? const Color(0xFF065F46) : const Color(0xFF991B1B))),
            ],
          ),
          const SizedBox(height: 4),
          Text(message, style: GoogleFonts.inter(fontSize: 12, color: isSuccess ? const Color(0xFF047857) : const Color(0xFFB91C1C))),
        ],
      ),
    );
  }

  Future<void> _dispatchCampaign() async {
    setState(() => _isDispatchingCampaign = true);

    final recipients = [
      {
        'email': _campTestEmailCtrl.text.trim().isNotEmpty ? _campTestEmailCtrl.text.trim() : 'info@neet-jee.in',
        'name': 'Valued Student',
        'phone': _campTestPhoneCtrl.text.trim().isNotEmpty ? _campTestPhoneCtrl.text.trim() : '9876543210',
      }
    ];

    final report = await EcommerceAutomationService.instance.sendMarketingCampaign(
      recipients: recipients,
      campaignTitle: _campTitleCtrl.text.trim(),
      bannerText: _campBannerCtrl.text.trim(),
      contentBody: _campBodyCtrl.text.trim(),
      ctaText: _campCtaTextCtrl.text.trim(),
      ctaLink: _campCtaLinkCtrl.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isDispatchingCampaign = false;
        _lastCampaignReport = report;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marketing Campaign Dispatched successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email & WhatsApp Automation', style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Brevo Email Engine & WhatsApp Cloud API Dispatcher', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 11)),
              ],
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4F46E5),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF4F46E5),
          indicatorWeight: 3,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.email_outlined, size: 18), text: 'Brevo Setup'),
            Tab(icon: Icon(Icons.chat_bubble_outline_rounded, size: 18), text: 'WhatsApp Setup'),
            Tab(icon: Icon(Icons.bolt_outlined, size: 18), text: 'Flow Triggers'),
            Tab(icon: Icon(Icons.campaign_outlined, size: 18), text: 'Marketing'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBrevoSetupTab(),
          _buildWhatsAppSetupTab(),
          _buildFlowTriggersTab(),
          _buildMarketingTab(),
        ],
      ),
    );
  }

  // ================= 1. BREVO EMAIL SETUP TAB =================
  Widget _buildBrevoSetupTab() {
    final isBrevoActive = BrevoEmailService.instance.isConfigured;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 750),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: isBrevoActive
                      ? const LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)])
                      : const LinearGradient(colors: [Color(0xFFD97706), Color(0xFFF59E0B)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: (isBrevoActive ? Colors.green : Colors.orange).withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Icon(isBrevoActive ? Icons.verified_rounded : Icons.warning_amber_rounded, color: Colors.white, size: 36),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isBrevoActive ? 'Brevo SMTP Email Engine Active' : 'Brevo Configuration Pending',
                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isBrevoActive
                                ? 'Transactional & Commercial emails are live via Brevo API (${BrevoEmailService.instance.senderEmail})'
                                : 'Simulated email queue active. Set your Brevo API Key below to enable live email delivery.',
                            style: GoogleFonts.inter(color: Colors.white.withOpacity(0.9), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Configuration Form
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 10)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Brevo API & Sender Credentials', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                    Text('Configure your Brevo SMTP API key to dispatch transactional and marketing emails.', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                    const SizedBox(height: 20),

                    Text('Brevo API Key (v3)', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _brevoApiKeyCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'xkeysib-xxxxxxxxxxxxxxxxxxxxxxxxx',
                        prefixIcon: const Icon(Icons.key_rounded, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Sender Email', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _brevoSenderEmailCtrl,
                                decoration: InputDecoration(
                                  hintText: 'info@neet-jee.in',
                                  prefixIcon: const Icon(Icons.email_outlined, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Sender Name', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _brevoSenderNameCtrl,
                                decoration: InputDecoration(
                                  hintText: 'Cosmyra Edu | NEET & JEE',
                                  prefixIcon: const Icon(Icons.badge_outlined, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isSavingConfig ? null : _saveBrevoConfig,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: _isSavingConfig
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.save_rounded, color: Colors.white),
                        label: Text('Save Brevo Settings', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Customized Templates Overview
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Active Brevo Commercial Templates', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                    Text('All commercial email templates are automatically styled with Cosmyra Edu branding.', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                    const SizedBox(height: 16),
                    _buildTemplateItem('1. Account Creation (Welcome Email)', 'Triggers on user sign up. Contains user exam summary and onboarding links.'),
                    _buildTemplateItem('2. Order Confirmation (Purchase Receipt)', 'Triggers on successful checkout. Itemized invoice and instant course access.'),
                    _buildTemplateItem('3. Payment Due Notice', 'Triggers on pending payment. Displays amount due, order ID, and payment link.'),
                    _buildTemplateItem('4. Password Reset & Security OTP', 'Triggers on forgot password. Displays 6-digit OTP code and direct reset link.'),
                    _buildTemplateItem('5. Abandoned Cart Recovery', 'Triggers on cart drop-off. Itemized cart preview + promotional discount coupon.'),
                    _buildTemplateItem('6. Email Marketing & Announcements', 'Customizable broadcast email template for sales, exam news & course releases.'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.mark_email_read, color: Color(0xFF4F46E5), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF1E293B))),
                Text(desc, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= 2. WHATSAPP SETUP TAB =================
  Widget _buildWhatsAppSetupTab() {
    final isWaActive = WhatsAppService.instance.isConfigured;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 750),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // WhatsApp Status Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: isWaActive
                      ? const LinearGradient(colors: [Color(0xFF047857), Color(0xFF10B981)])
                      : const LinearGradient(colors: [Color(0xFF0284C7), Color(0xFF38BDF8)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 36),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isWaActive ? 'WhatsApp Cloud API Active' : 'WhatsApp Account Detection Ready',
                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isWaActive
                                ? 'WhatsApp notifications & presence check are connected to Meta Cloud API.'
                                : 'All phone numbers shared by users are automatically checked for active WhatsApp accounts.',
                            style: GoogleFonts.inter(color: Colors.white.withOpacity(0.9), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // WhatsApp Account Verification Tool
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('WhatsApp Account Presence Checker', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                    Text('Test whether any phone number shared by a user is registered on WhatsApp.', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _testPhoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: 'Enter phone number (e.g. 9876543210)',
                              prefixIcon: const Icon(Icons.phone_android_rounded, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _isTestingFlow ? null : _verifyWhatsAppPhone,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: _isTestingFlow
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.search_rounded, color: Colors.white, size: 18),
                          label: Text('Check WhatsApp', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),

                    if (_lastCheckResult != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _lastCheckResult!['has_whatsapp'] == true ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _lastCheckResult!['has_whatsapp'] == true ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _lastCheckResult!['has_whatsapp'] == true ? Icons.check_circle_rounded : Icons.info_rounded,
                              color: _lastCheckResult!['has_whatsapp'] == true ? const Color(0xFF10B981) : const Color(0xFFD97706),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Phone: ${_lastCheckResult!['formatted_phone']} | WhatsApp: ${_lastCheckResult!['has_whatsapp'] == true ? "ACTIVE ✅" : "NOT FOUND ❌"}',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF0F172A)),
                                  ),
                                  Text(_lastCheckResult!['message']?.toString() ?? '', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // WhatsApp Cloud API Configuration
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('WhatsApp Cloud API Credentials', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                    Text('Configure Meta Graph API credentials for automated WhatsApp messaging.', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                    const SizedBox(height: 20),

                    Text('System User Access Token', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _waTokenCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'EAAG...',
                        prefixIcon: const Icon(Icons.vpn_key_rounded, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Phone Number ID', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _waPhoneIdCtrl,
                                decoration: InputDecoration(
                                  hintText: '100654321987...',
                                  prefixIcon: const Icon(Icons.numbers_rounded, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Business Account ID (Optional)', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _waBusinessIdCtrl,
                                decoration: InputDecoration(
                                  hintText: '200987654321...',
                                  prefixIcon: const Icon(Icons.business_rounded, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isSavingConfig ? null : _saveWhatsAppConfig,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.save_rounded, color: Colors.white),
                        label: Text('Save WhatsApp Credentials', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= 3. FLOW TRIGGERS TAB =================
  Widget _buildFlowTriggersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Interactive Automated Flow Tester', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
              Text('Test Brevo Email and WhatsApp dispatches after every user action in real-time.', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
              const SizedBox(height: 20),

              // Recipient Target Controls
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _testEmailRecipientCtrl,
                        decoration: InputDecoration(
                          labelText: 'Test Email Address',
                          prefixIcon: const Icon(Icons.email_outlined, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _testPhoneCtrl,
                        decoration: InputDecoration(
                          labelText: 'Test WhatsApp Phone',
                          prefixIcon: const Icon(Icons.phone_android_rounded, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Flow Cards Grid
              _buildFlowTriggerCard(
                title: '1. Account Creation Flow',
                subtitle: 'Dispatches Brevo Welcome Email & Welcome WhatsApp message when a new user registers.',
                icon: Icons.person_add_rounded,
                color: const Color(0xFF4F46E5),
                onTap: () => _triggerTestFlow('account_creation'),
              ),
              _buildFlowTriggerCard(
                title: '2. Order Placed Flow',
                subtitle: 'Dispatches Brevo Order Confirmation Email & WhatsApp receipt when an order is completed.',
                icon: Icons.shopping_bag_rounded,
                color: const Color(0xFF10B981),
                onTap: () => _triggerTestFlow('order_placed'),
              ),
              _buildFlowTriggerCard(
                title: '3. Payment Due Notice Flow',
                subtitle: 'Dispatches Brevo Payment Due Email & WhatsApp payment reminder for pending checkout orders.',
                icon: Icons.payment_rounded,
                color: const Color(0xFFD97706),
                onTap: () => _triggerTestFlow('payment_due'),
              ),
              _buildFlowTriggerCard(
                title: '4. Password Reset & Security OTP Flow',
                subtitle: 'Dispatches Brevo Password Reset Email with OTP and WhatsApp Security alert.',
                icon: Icons.lock_reset_rounded,
                color: const Color(0xFFEF4444),
                onTap: () => _triggerTestFlow('password_reset'),
              ),
              _buildFlowTriggerCard(
                title: '5. Abandoned Cart Recovery Flow',
                subtitle: 'Dispatches Brevo Abandoned Cart Email & WhatsApp recovery message with discount coupon.',
                icon: Icons.add_shopping_cart_rounded,
                color: const Color(0xFF8B5CF6),
                onTap: () => _triggerTestFlow('cart_recovery'),
              ),

              const SizedBox(height: 24),

              // Live Automation Logs
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent Automation Audit Log', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                        Text('${EcommerceAutomationService.instance.automationLogs.length} events recorded',
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AnimatedBuilder(
                      animation: EcommerceAutomationService.instance,
                      builder: (context, _) {
                        final logs = EcommerceAutomationService.instance.automationLogs;
                        if (logs.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: Text('No automation events triggered yet. Click any flow above to test.',
                                  style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13)),
                            ),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: logs.length > 10 ? 10 : logs.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final log = logs[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFEEF2FF),
                                child: const Icon(Icons.bolt_rounded, color: Color(0xFF4F46E5), size: 18),
                              ),
                              title: Text(log['event_type'] ?? 'EVENT', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text(log['timestamp']?.toString().split('.')[0] ?? '', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                              trailing: IconButton(
                                icon: const Icon(Icons.info_outline_rounded, size: 18),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text(log['event_type'] ?? 'Log Details'),
                                      content: Text(log['details']?.toString() ?? ''),
                                      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlowTriggerCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF0F172A))),
                const SizedBox(height: 4),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _isTestingFlow ? null : onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
            label: Text('Test Flow', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ================= 4. MARKETING CAMPAIGN TAB =================
  Widget _buildMarketingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Email & WhatsApp Marketing Campaigns', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
              Text('Broadcast promotional campaigns, discount offers, and exam news to customers via Brevo & WhatsApp.', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Target Audience Group', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedTargetGroup,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'All Registered Students', child: Text('All Registered Students')),
                        DropdownMenuItem(value: 'Active Cart Users (Abandoned Carts)', child: Text('Active Cart Users (Abandoned Carts)')),
                        DropdownMenuItem(value: 'Unpaid / Pending Orders', child: Text('Unpaid / Pending Orders')),
                        DropdownMenuItem(value: 'NEET Aspirants Only', child: Text('NEET Aspirants Only')),
                        DropdownMenuItem(value: 'JEE Aspirants Only', child: Text('JEE Aspirants Only')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedTargetGroup = val);
                      },
                    ),

                    const SizedBox(height: 16),
                    Text('Campaign Title (Email Subject & WhatsApp Headline)', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _campTitleCtrl,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Text('Banner Header (Email Banner Text)', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _campBannerCtrl,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Text('Campaign Message Content', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _campBodyCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('CTA Button Label', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _campCtaTextCtrl,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('CTA Destination Link', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _campCtaLinkCtrl,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Dispatch Buttons
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _isDispatchingCampaign ? null : _dispatchCampaign,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: _isDispatchingCampaign
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.send_rounded, color: Colors.white),
                              label: Text('Dispatch Email & WhatsApp Campaign', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_lastCampaignReport != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Campaign Dispatch Report', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF065F46))),
                            const SizedBox(height: 6),
                            Text('Brevo Emails Sent: ${_lastCampaignReport!['email_success_count']} ✅', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF047857))),
                            Text('WhatsApp Messages Sent: ${_lastCampaignReport!['whatsapp_success_count']} ✅', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF047857))),
                            Text('WhatsApp Skipped (No WA Account): ${_lastCampaignReport!['whatsapp_skipped_count']}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFD97706))),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
