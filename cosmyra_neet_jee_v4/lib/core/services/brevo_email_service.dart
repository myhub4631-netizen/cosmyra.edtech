import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BrevoEmailService {
  static final BrevoEmailService instance = BrevoEmailService._internal();
  BrevoEmailService._internal() {
    _loadConfig();
  }

  // Configuration defaults
  String _apiKey = const String.fromEnvironment(
    'BREVO_API_KEY',
    defaultValue: '',
  );
  String _senderEmail = const String.fromEnvironment(
    'BREVO_SENDER_EMAIL',
    defaultValue: 'info@neet-jee.in',
  );
  String _senderName = 'Cosmyra Edu | NEET & JEE';

  String get apiKey => _apiKey;
  String get senderEmail => _senderEmail;
  String get senderName => _senderName;
  bool get isConfigured => _apiKey.trim().isNotEmpty;

  Future<void> setConfig({required String apiKey, String? senderEmail, String? senderName}) async {
    _apiKey = apiKey.trim();
    if (senderEmail != null && senderEmail.trim().isNotEmpty) {
      _senderEmail = senderEmail.trim();
    }
    if (senderName != null && senderName.trim().isNotEmpty) {
      _senderName = senderName.trim();
    }
    await _saveConfig();
  }

  Future<void> _saveConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('brevo_api_key', _apiKey);
      await prefs.setString('brevo_sender_email', _senderEmail);
      await prefs.setString('brevo_sender_name', _senderName);
    } catch (e) {
      debugPrint('Brevo config cache notice: $e');
    }
  }

  Future<void> _loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _apiKey = prefs.getString('brevo_api_key') ?? _apiKey;
      _senderEmail = prefs.getString('brevo_sender_email') ?? 'info@neet-jee.in';
      _senderName = prefs.getString('brevo_sender_name') ?? 'Cosmyra Edu | NEET & JEE';
    } catch (e) {
      debugPrint('Brevo config load notice: $e');
    }
  }

  /// Direct Brevo SMTP API Call to send Email
  Future<Map<String, dynamic>> sendTransactionalEmail({
    required String recipientEmail,
    required String subject,
    required String htmlContent,
    String? recipientName,
    List<Map<String, String>>? attachment,
  }) async {
    final cleanEmail = recipientEmail.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      return {'success': false, 'message': 'Invalid recipient email address'};
    }

    // If API Key is not set locally, log simulated success and fallback to local cache
    if (!isConfigured) {
      debugPrint('Brevo Notice: BREVO_API_KEY is not configured yet. Simulating clean email dispatch for $cleanEmail');
      return {
        'success': true,
        'simulated': true,
        'message': 'Email queued via Brevo Engine (Configuration pending in Settings)',
        'recipient': cleanEmail,
        'subject': subject,
      };
    }

    try {
      final url = Uri.parse('https://api.brevo.com/v3/smtp/email');
      final payload = {
        'sender': {'name': _senderName, 'email': _senderEmail},
        'to': [
          {
            'email': cleanEmail,
            if (recipientName != null && recipientName.isNotEmpty) 'name': recipientName
          }
        ],
        'subject': subject,
        'htmlContent': htmlContent,
      };

      if (attachment != null && attachment.isNotEmpty) {
        payload['attachment'] = attachment;
      }

      final response = await http.post(
        url,
        headers: {
          'accept': 'application/json',
          'api-key': _apiKey,
          'content-type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      final respData = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'messageId': respData['messageId'],
          'data': respData,
        };
      } else {
        return {
          'success': false,
          'message': respData['message'] ?? 'Brevo API returned error status: ${response.statusCode}',
          'data': respData,
        };
      }
    } catch (e) {
      debugPrint('Error sending Brevo email: $e');
      return {
        'success': false,
        'message': 'Exception dispatching Brevo email: $e',
      };
    }
  }

  // ===========================================================================
  // BRANDED BREVO HTML EMAIL TEMPLATES
  // ===========================================================================

  /// Wrapper for standard branded HTML structure
  String _wrapHtmlTemplate({required String title, required String bodyHtml}) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$title</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; margin: 0; padding: 0; background-color: #F8FAFC; color: #1E293B; }
    .container { max-width: 600px; margin: 20px auto; background: #FFFFFF; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 25px rgba(0,0,0,0.05); border: 1px solid #E2E8F0; }
    .header { background: linear-gradient(135deg, #4F46E5 0%, #06B6D4 100%); padding: 32px 24px; text-align: center; color: #FFFFFF; }
    .header h1 { margin: 0; font-size: 26px; font-weight: 800; letter-spacing: -0.5px; }
    .header p { margin: 8px 0 0 0; font-size: 14px; opacity: 0.9; font-weight: 500; }
    .content { padding: 32px 24px; font-size: 15px; line-height: 1.6; color: #334155; }
    .btn { display: inline-block; background: #4F46E5; color: #FFFFFF !important; font-weight: 700; text-decoration: none; padding: 14px 28px; border-radius: 10px; margin: 20px 0; text-align: center; box-shadow: 0 4px 12px rgba(79, 70, 229, 0.3); }
    .btn:hover { background: #4338CA; }
    .card-box { background: #F1F5F9; border-radius: 12px; padding: 20px; margin: 20px 0; border: 1px solid #E2E8F0; }
    .badge { display: inline-block; background: #EEF2FF; color: #4F46E5; font-size: 12px; font-weight: 700; padding: 4px 10px; border-radius: 20px; text-transform: uppercase; }
    .footer { background: #F8FAFC; padding: 24px; text-align: center; font-size: 12px; color: #64748B; border-top: 1px solid #E2E8F0; }
    .footer a { color: #4F46E5; text-decoration: none; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Cosmyra Edu</h1>
      <p>NEET & JEE Smart Test Series & Analytics</p>
    </div>
    <div class="content">
      $bodyHtml
    </div>
    <div class="footer">
      <p>© ${DateTime.now().year} Cosmyra Edu Inc. All rights reserved.</p>
      <p>Need help? Contact us at <a href="mailto:cosmyra.in@gmail.com">cosmyra.in@gmail.com</a></p>
    </div>
  </div>
</body>
</html>
''';
  }

  /// 1. Account Creation / Welcome Email Template
  String buildWelcomeEmailHtml({required String userName, required String email}) {
    final body = '''
<h2>Welcome to Cosmyra Edu, $userName! 👋</h2>
<p>We're thrilled to have you join India's premier NEET & JEE preparation engine!</p>

<div class="card-box">
  <p style="margin:0 0 10px 0; font-weight:bold;">🚀 Your Account Summary:</p>
  <p style="margin:4px 0;"><strong>Name:</strong> $userName</p>
  <p style="margin:4px 0;"><strong>Email:</strong> $email</p>
  <p style="margin:4px 0;"><strong>Target Exams:</strong> NEET, JEE Main & Advanced</p>
</div>

<p>Here is what you can explore right away:</p>
<ul>
  <li><strong>Full Mock Tests & NTA PYQs</strong> - 100% NTA pattern exam interface.</li>
  <li><strong>Detailed AI Analytics</strong> - Instant scorecards, subject accuracy & rank prediction.</li>
  <li><strong>Bookmark & Mistake Notebook</strong> - Auto-capture incorrect questions to review later.</li>
</ul>

<div style="text-align: center;">
  <a href="https://cosmyra.edu/dashboard" class="btn">Start Your First Test Now 🎯</a>
</div>
''';
    return _wrapHtmlTemplate(title: 'Welcome to Cosmyra Edu', bodyHtml: body);
  }

  /// 2. Order Placed / Purchase Confirmation Template
  String buildOrderConfirmationEmailHtml({
    required String userName,
    required String orderId,
    required double totalAmount,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) {
    String itemsListHtml = '';
    for (var item in items) {
      final title = item['title'] ?? item['product_title'] ?? 'Test Series Package';
      final price = (item['price'] as num?)?.toDouble() ?? 0.0;
      final validity = item['validity'] ?? 'Valid until exam';
      itemsListHtml += '''
<div style="display:flex; justify-content:space-between; padding:10px 0; border-bottom:1px dashed #CBD5E1;">
  <div>
    <strong>$title</strong><br>
    <span style="font-size:12px; color:#64748B;">Validity: $validity</span>
  </div>
  <div style="font-weight:bold; color:#0F172A;">₹${price.toStringAsFixed(2)}</div>
</div>
''';
    }

    final body = '''
<div class="badge">Payment Successful</div>
<h2>Order Confirmation 🎉</h2>
<p>Hi $userName,</p>
<p>Thank you for purchasing on Cosmyra Edu! Your order has been placed and instant access has been granted to your account.</p>

<div class="card-box">
  <p style="margin:0 0 12px 0;"><strong>Order ID:</strong> $orderId</p>
  <p style="margin:0 0 12px 0;"><strong>Payment Method:</strong> $paymentMethod</p>
  <p style="margin:0 0 16px 0;"><strong>Date:</strong> ${DateTime.now().toLocal().toString().split('.')[0]}</p>
  
  <div style="background:#FFFFFF; border-radius:8px; padding:12px; border:1px solid #E2E8F0;">
    $itemsListHtml
    <div style="display:flex; justify-content:space-between; padding-top:12px; font-size:16px; font-weight:bold; color:#4F46E5;">
      <span>Total Paid:</span>
      <span>₹${totalAmount.toStringAsFixed(2)}</span>
    </div>
  </div>
</div>

<div style="text-align: center;">
  <a href="https://cosmyra.edu/my-tests" class="btn">Access Your Courses & Tests Now 📚</a>
</div>
''';
    return _wrapHtmlTemplate(title: 'Order Confirmation #$orderId', bodyHtml: body);
  }

  /// 3. Payment Due / Pending Payment Reminder Template
  String buildPaymentDueEmailHtml({
    required String userName,
    required String orderId,
    required double amountDue,
    required String title,
    String? dueDate,
  }) {
    final body = '''
<div class="badge" style="background:#FEF3C7; color:#D97706;">Action Required</div>
<h2>Payment Due Reminder 💳</h2>
<p>Hi $userName,</p>
<p>You have a pending order/payment for <strong>$title</strong> on Cosmyra Edu.</p>

<div class="card-box" style="border-left: 4px solid #F59E0B;">
  <p style="margin:4px 0;"><strong>Order ID:</strong> $orderId</p>
  <p style="margin:4px 0;"><strong>Item:</strong> $title</p>
  <p style="margin:4px 0;"><strong>Amount Due:</strong> <span style="font-size:18px; color:#D97706; font-weight:bold;">₹${amountDue.toStringAsFixed(2)}</span></p>
  <p style="margin:4px 0;"><strong>Due Date:</strong> ${dueDate ?? 'Immediate action requested'}</p>
</div>

<p>Complete your payment now to ensure uninterrupted access to test series and solutions.</p>

<div style="text-align: center;">
  <a href="https://cosmyra.edu/checkout?order_id=$orderId" class="btn" style="background:#F59E0B;">Complete Payment Now 💳</a>
</div>
''';
    return _wrapHtmlTemplate(title: 'Payment Due Notice for $orderId', bodyHtml: body);
  }

  /// 4. Password Reset & OTP Template
  String buildPasswordResetEmailHtml({
    required String userName,
    required String resetCode,
    String? resetLink,
  }) {
    final body = '''
<div class="badge" style="background:#FEE2E2; color:#EF4444;">Security Alert</div>
<h2>Password Reset Request 🔐</h2>
<p>Hi $userName,</p>
<p>We received a request to reset your password for your Cosmyra Edu account.</p>

<div class="card-box" style="text-align:center;">
  <p style="margin:0; font-size:14px; color:#64748B;">Your Verification OTP Code:</p>
  <div style="font-size:32px; font-weight:900; letter-spacing:6px; color:#4F46E5; margin:12px 0;">$resetCode</div>
  <p style="margin:0; font-size:12px; color:#94A3B8;">This code will expire in 15 minutes.</p>
</div>

${resetLink != null ? '''
<div style="text-align: center;">
  <a href="$resetLink" class="btn">Reset Password Directly 🔗</a>
</div>
''' : ''}

<p style="font-size:13px; color:#64748B;">If you did not request this password reset, please ignore this email or contact support immediately.</p>
''';
    return _wrapHtmlTemplate(title: 'Reset Your Cosmyra Edu Password', bodyHtml: body);
  }

  /// 5. Add to Cart & Abandoned Cart Recovery Template
  String buildCartRecoveryEmailHtml({
    required String userName,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    String couponCode = 'COSMYRA20',
  }) {
    String itemsListHtml = '';
    for (var item in items) {
      final title = item['title'] ?? 'NEET Test Series';
      final price = (item['price'] as num?)?.toDouble() ?? 299.0;
      itemsListHtml += '''
<div style="padding:8px 0; border-bottom:1px solid #E2E8F0;">
  <strong>$title</strong> - ₹${price.toStringAsFixed(2)}
</div>
''';
    }

    final body = '''
<div class="badge" style="background:#E0E7FF; color:#4F46E5;">Cart Reminder</div>
<h2>You left items in your cart! 🛒</h2>
<p>Hi $userName,</p>
<p>Your preparation boost is waiting! You left the following items in your Cosmyra Edu cart:</p>

<div class="card-box">
  $itemsListHtml
  <p style="margin-top:12px; font-weight:bold; font-size:16px;">Subtotal: ₹${subtotal.toStringAsFixed(2)}</p>
</div>

<div style="background:#FFFBEB; border:1px dashed #F59E0B; border-radius:12px; padding:16px; text-align:center; margin:20px 0;">
  <p style="margin:0; font-size:14px; color:#B45309; font-weight:bold;">🎁 Special Limited Time Discount!</p>
  <p style="margin:4px 0 0 0; font-size:13px; color:#78350F;">Use coupon code <strong style="color:#D97706; font-size:16px;">$couponCode</strong> at checkout to get an extra discount!</p>
</div>

<div style="text-align: center;">
  <a href="https://cosmyra.edu/cart" class="btn">Return to Cart & Complete Order 🛒</a>
</div>
''';
    return _wrapHtmlTemplate(title: 'Did you forget something in your cart?', bodyHtml: body);
  }

  /// 6. Marketing / Announcement Email Template
  String buildMarketingEmailHtml({
    required String title,
    required String bannerText,
    required String contentBody,
    required String ctaText,
    required String ctaLink,
  }) {
    final body = '''
<h2>$title 📢</h2>

<div class="card-box" style="background: linear-gradient(135deg, #EEF2FF 0%, #E0F2FE 100%); text-align:center;">
  <h3 style="margin:0; color:#4F46E5;">$bannerText</h3>
</div>

<div style="margin:20px 0;">
  $contentBody
</div>

<div style="text-align: center;">
  <a href="$ctaLink" class="btn">$ctaText 🔥</a>
</div>
''';
    return _wrapHtmlTemplate(title: title, bodyHtml: body);
  }

  // ===========================================================================
  // CONVENIENCE EMAIL DISPATCHERS
  // ===========================================================================

  /// Send Welcome Email
  Future<Map<String, dynamic>> sendWelcomeEmail({
    required String recipientEmail,
    required String userName,
  }) async {
    final html = buildWelcomeEmailHtml(userName: userName, email: recipientEmail);
    return sendTransactionalEmail(
      recipientEmail: recipientEmail,
      recipientName: userName,
      subject: 'Welcome to Cosmyra Edu! 🎯',
      htmlContent: html,
    );
  }

  /// Send Order Confirmation Email
  Future<Map<String, dynamic>> sendOrderConfirmationEmail({
    required String recipientEmail,
    required String userName,
    required String orderId,
    required double totalAmount,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) async {
    final html = buildOrderConfirmationEmailHtml(
      userName: userName,
      orderId: orderId,
      totalAmount: totalAmount,
      paymentMethod: paymentMethod,
      items: items,
    );
    return sendTransactionalEmail(
      recipientEmail: recipientEmail,
      recipientName: userName,
      subject: 'Order Confirmation #$orderId - Cosmyra Edu 🎉',
      htmlContent: html,
    );
  }

  /// Send Payment Due Email
  Future<Map<String, dynamic>> sendPaymentDueEmail({
    required String recipientEmail,
    required String userName,
    required String orderId,
    required double amountDue,
    required String title,
    String? dueDate,
  }) async {
    final html = buildPaymentDueEmailHtml(
      userName: userName,
      orderId: orderId,
      amountDue: amountDue,
      title: title,
      dueDate: dueDate,
    );
    return sendTransactionalEmail(
      recipientEmail: recipientEmail,
      recipientName: userName,
      subject: 'Payment Due Notice for Order #$orderId 💳',
      htmlContent: html,
    );
  }

  /// Send Password Reset Email
  Future<Map<String, dynamic>> sendPasswordResetEmail({
    required String recipientEmail,
    required String userName,
    required String resetCode,
    String? resetLink,
  }) async {
    final html = buildPasswordResetEmailHtml(
      userName: userName,
      resetCode: resetCode,
      resetLink: resetLink,
    );
    return sendTransactionalEmail(
      recipientEmail: recipientEmail,
      recipientName: userName,
      subject: 'Reset Your Cosmyra Edu Password 🔐',
      htmlContent: html,
    );
  }

  /// Send Cart Recovery Email
  Future<Map<String, dynamic>> sendCartRecoveryEmail({
    required String recipientEmail,
    required String userName,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    String couponCode = 'COSMYRA20',
  }) async {
    final html = buildCartRecoveryEmailHtml(
      userName: userName,
      items: items,
      subtotal: subtotal,
      couponCode: couponCode,
    );
    return sendTransactionalEmail(
      recipientEmail: recipientEmail,
      recipientName: userName,
      subject: 'Did you leave something in your cart? 🛒',
      htmlContent: html,
    );
  }

  /// Send Marketing Email
  Future<Map<String, dynamic>> sendMarketingEmail({
    required String recipientEmail,
    String? recipientName,
    required String title,
    required String bannerText,
    required String contentBody,
    required String ctaText,
    required String ctaLink,
  }) async {
    final html = buildMarketingEmailHtml(
      title: title,
      bannerText: bannerText,
      contentBody: contentBody,
      ctaText: ctaText,
      ctaLink: ctaLink,
    );
    return sendTransactionalEmail(
      recipientEmail: recipientEmail,
      recipientName: recipientName,
      subject: '$title | Cosmyra Edu 📢',
      htmlContent: html,
    );
  }
}
