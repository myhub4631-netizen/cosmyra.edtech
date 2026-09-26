import 'dart:async';
import 'package:flutter/foundation.dart';
import 'brevo_email_service.dart';
import 'whatsapp_service.dart';
import 'cart_service.dart';

class AutomationResult {
  final bool emailSuccess;
  final String emailMessage;
  final bool whatsappSuccess;
  final String whatsappMessage;
  final bool hasWhatsAppAccount;
  final String formattedPhone;

  AutomationResult({
    required this.emailSuccess,
    required this.emailMessage,
    required this.whatsappSuccess,
    required this.whatsappMessage,
    required this.hasWhatsAppAccount,
    required this.formattedPhone,
  });

  Map<String, dynamic> toJson() => {
        'email_success': emailSuccess,
        'email_message': emailMessage,
        'whatsapp_success': whatsappSuccess,
        'whatsapp_message': whatsappMessage,
        'has_whatsapp_account': hasWhatsAppAccount,
        'formatted_phone': formattedPhone,
      };
}

class EcommerceAutomationService extends ChangeNotifier {
  static final EcommerceAutomationService instance = EcommerceAutomationService._internal();
  EcommerceAutomationService._internal();

  final List<Map<String, dynamic>> _automationLogs = [];
  List<Map<String, dynamic>> get automationLogs => List.unmodifiable(_automationLogs);

  void _logEvent(String eventType, Map<String, dynamic> details) {
    _automationLogs.insert(0, {
      'id': 'log_${DateTime.now().millisecondsSinceEpoch}',
      'event_type': eventType,
      'timestamp': DateTime.now().toIso8601String(),
      'details': details,
    });
    if (_automationLogs.length > 100) {
      _automationLogs.removeLast();
    }
    notifyListeners();
  }

  /// 1. CHECK WHATSAPP ACCOUNT PRESENCE WHEN USER SHARES PHONE NUMBER
  Future<Map<String, dynamic>> checkUserWhatsAppStatus(String rawPhone) async {
    final res = await WhatsAppService.instance.checkWhatsAppAccount(rawPhone);
    _logEvent('WHATSAPP_CHECK', {
      'raw_phone': rawPhone,
      'has_whatsapp': res['has_whatsapp'],
      'status': res['status'],
      'formatted_phone': res['formatted_phone'],
    });
    return res;
  }

  /// 2. ACCOUNT CREATION FLOW (Welcome Email via Brevo + Welcome WhatsApp)
  Future<AutomationResult> triggerAccountCreationFlow({
    required String email,
    required String fullName,
    required String phone,
    String targetExam = 'NEET & JEE',
  }) async {
    final cleanPhone = WhatsAppService.instance.formatPhoneNumber(phone);
    final waCheck = await WhatsAppService.instance.checkWhatsAppAccount(phone);
    final bool hasWa = waCheck['has_whatsapp'] == true;

    // Dispatch Brevo Welcome Email
    final emailRes = await BrevoEmailService.instance.sendWelcomeEmail(
      recipientEmail: email,
      userName: fullName,
    );

    // Dispatch WhatsApp Welcome Message if active on WhatsApp
    Map<String, dynamic> waRes = {
      'success': false,
      'message': 'WhatsApp message skipped: No active WhatsApp account for $cleanPhone'
    };

    if (hasWa) {
      waRes = await WhatsAppService.instance.sendWelcomeWhatsApp(
        rawPhone: phone,
        userName: fullName,
      );
    }

    final result = AutomationResult(
      emailSuccess: emailRes['success'] == true,
      emailMessage: emailRes['message']?.toString() ?? 'Email dispatched',
      whatsappSuccess: waRes['success'] == true,
      whatsappMessage: waRes['message']?.toString() ?? 'WhatsApp skipped',
      hasWhatsAppAccount: hasWa,
      formattedPhone: cleanPhone,
    );

    _logEvent('ACCOUNT_CREATION_FLOW', {
      'email': email,
      'name': fullName,
      'phone': cleanPhone,
      'result': result.toJson(),
    });

    return result;
  }

  /// 3. ORDER PLACED FLOW (Order Confirmation Email via Brevo + WhatsApp)
  Future<AutomationResult> triggerOrderPlacedFlow({
    required String orderId,
    required String recipientEmail,
    required String userName,
    required String phone,
    required double totalAmount,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) async {
    final cleanPhone = WhatsAppService.instance.formatPhoneNumber(phone);
    final waCheck = await WhatsAppService.instance.checkWhatsAppAccount(phone);
    final bool hasWa = waCheck['has_whatsapp'] == true;

    // Dispatch Brevo Order Confirmation Email
    final emailRes = await BrevoEmailService.instance.sendOrderConfirmationEmail(
      recipientEmail: recipientEmail,
      userName: userName,
      orderId: orderId,
      totalAmount: totalAmount,
      paymentMethod: paymentMethod,
      items: items,
    );

    // Dispatch WhatsApp Order Confirmation
    Map<String, dynamic> waRes = {
      'success': false,
      'message': 'WhatsApp skipped: Phone not registered on WhatsApp'
    };

    if (hasWa) {
      final firstItemTitle = items.isNotEmpty
          ? (items[0]['title'] ?? items[0]['product_title'] ?? 'NEET & JEE Package')
          : 'NEET & JEE Package';

      waRes = await WhatsAppService.instance.sendOrderConfirmationWhatsApp(
        rawPhone: phone,
        userName: userName,
        orderId: orderId,
        totalAmount: totalAmount,
        firstItemTitle: firstItemTitle.toString(),
      );
    }

    final result = AutomationResult(
      emailSuccess: emailRes['success'] == true,
      emailMessage: emailRes['message']?.toString() ?? 'Email queued',
      whatsappSuccess: waRes['success'] == true,
      whatsappMessage: waRes['message']?.toString() ?? 'WhatsApp queued',
      hasWhatsAppAccount: hasWa,
      formattedPhone: cleanPhone,
    );

    _logEvent('ORDER_PLACED_FLOW', {
      'order_id': orderId,
      'email': recipientEmail,
      'total': totalAmount,
      'result': result.toJson(),
    });

    return result;
  }

  /// 4. PAYMENT DUE FLOW (Payment Pending Notice via Brevo Email + WhatsApp)
  Future<AutomationResult> triggerPaymentDueFlow({
    required String orderId,
    required String recipientEmail,
    required String userName,
    required String phone,
    required double amountDue,
    required String itemTitle,
    String? dueDate,
  }) async {
    final cleanPhone = WhatsAppService.instance.formatPhoneNumber(phone);
    final waCheck = await WhatsAppService.instance.checkWhatsAppAccount(phone);
    final bool hasWa = waCheck['has_whatsapp'] == true;

    // Dispatch Brevo Payment Due Email
    final emailRes = await BrevoEmailService.instance.sendPaymentDueEmail(
      recipientEmail: recipientEmail,
      userName: userName,
      orderId: orderId,
      amountDue: amountDue,
      title: itemTitle,
      dueDate: dueDate,
    );

    // Dispatch WhatsApp Payment Due Message
    Map<String, dynamic> waRes = {
      'success': false,
      'message': 'WhatsApp skipped: Phone not active on WhatsApp'
    };

    if (hasWa) {
      waRes = await WhatsAppService.instance.sendPaymentDueWhatsApp(
        rawPhone: phone,
        userName: userName,
        orderId: orderId,
        amountDue: amountDue,
        itemTitle: itemTitle,
      );
    }

    final result = AutomationResult(
      emailSuccess: emailRes['success'] == true,
      emailMessage: emailRes['message']?.toString() ?? 'Payment due email sent',
      whatsappSuccess: waRes['success'] == true,
      whatsappMessage: waRes['message']?.toString() ?? 'Payment due WhatsApp sent',
      hasWhatsAppAccount: hasWa,
      formattedPhone: cleanPhone,
    );

    _logEvent('PAYMENT_DUE_FLOW', {
      'order_id': orderId,
      'email': recipientEmail,
      'amount_due': amountDue,
      'result': result.toJson(),
    });

    return result;
  }

  /// 5. PASSWORD RESET FLOW (Password Reset OTP via Brevo Email + WhatsApp)
  Future<AutomationResult> triggerPasswordResetFlow({
    required String recipientEmail,
    required String userName,
    required String phone,
    String? otpCode,
    String? resetLink,
  }) async {
    final code = otpCode ?? (100000 + (DateTime.now().microsecondsSinceEpoch % 899999)).toString();
    final cleanPhone = WhatsAppService.instance.formatPhoneNumber(phone);
    final waCheck = await WhatsAppService.instance.checkWhatsAppAccount(phone);
    final bool hasWa = waCheck['has_whatsapp'] == true;

    // Dispatch Brevo Password Reset Email
    final emailRes = await BrevoEmailService.instance.sendPasswordResetEmail(
      recipientEmail: recipientEmail,
      userName: userName,
      resetCode: code,
      resetLink: resetLink,
    );

    // Dispatch WhatsApp OTP Security Alert
    Map<String, dynamic> waRes = {
      'success': false,
      'message': 'WhatsApp skipped: Phone not active on WhatsApp'
    };

    if (hasWa) {
      waRes = await WhatsAppService.instance.sendPasswordResetWhatsApp(
        rawPhone: phone,
        userName: userName,
        resetCode: code,
      );
    }

    final result = AutomationResult(
      emailSuccess: emailRes['success'] == true,
      emailMessage: emailRes['message']?.toString() ?? 'OTP Email dispatched',
      whatsappSuccess: waRes['success'] == true,
      whatsappMessage: waRes['message']?.toString() ?? 'OTP WhatsApp dispatched',
      hasWhatsAppAccount: hasWa,
      formattedPhone: cleanPhone,
    );

    _logEvent('PASSWORD_RESET_FLOW', {
      'email': recipientEmail,
      'code': code,
      'result': result.toJson(),
    });

    return result;
  }

  /// 6. ADD TO CART & CART RECOVERY FLOW
  Future<AutomationResult> triggerCartRecoveryFlow({
    required String recipientEmail,
    required String userName,
    required String phone,
    required List<CartItem> cartItems,
    String couponCode = 'COSMYRA20',
  }) async {
    if (cartItems.isEmpty) {
      return AutomationResult(
        emailSuccess: false,
        emailMessage: 'Cart is empty',
        whatsappSuccess: false,
        whatsappMessage: 'Cart is empty',
        hasWhatsAppAccount: false,
        formattedPhone: phone,
      );
    }

    final itemsData = cartItems.map((e) => e.toJson()).toList();
    double subtotal = 0.0;
    for (var it in cartItems) {
      subtotal += it.price;
    }

    final cleanPhone = WhatsAppService.instance.formatPhoneNumber(phone);
    final waCheck = await WhatsAppService.instance.checkWhatsAppAccount(phone);
    final bool hasWa = waCheck['has_whatsapp'] == true;

    // Dispatch Brevo Cart Recovery Email
    final emailRes = await BrevoEmailService.instance.sendCartRecoveryEmail(
      recipientEmail: recipientEmail,
      userName: userName,
      items: itemsData,
      subtotal: subtotal,
      couponCode: couponCode,
    );

    // Dispatch WhatsApp Cart Recovery Message
    Map<String, dynamic> waRes = {
      'success': false,
      'message': 'WhatsApp skipped: Phone not active on WhatsApp'
    };

    if (hasWa) {
      waRes = await WhatsAppService.instance.sendCartRecoveryWhatsApp(
        rawPhone: phone,
        userName: userName,
        firstItemTitle: cartItems.first.title,
        subtotal: subtotal,
        couponCode: couponCode,
      );
    }

    final result = AutomationResult(
      emailSuccess: emailRes['success'] == true,
      emailMessage: emailRes['message']?.toString() ?? 'Cart recovery email queued',
      whatsappSuccess: waRes['success'] == true,
      whatsappMessage: waRes['message']?.toString() ?? 'Cart recovery WhatsApp queued',
      hasWhatsAppAccount: hasWa,
      formattedPhone: cleanPhone,
    );

    _logEvent('CART_RECOVERY_FLOW', {
      'email': recipientEmail,
      'item_count': cartItems.length,
      'subtotal': subtotal,
      'result': result.toJson(),
    });

    return result;
  }

  /// 7. EMAIL MARKETING & WHATSAPP BROADCAST CAMPAIGN
  Future<Map<String, dynamic>> sendMarketingCampaign({
    required List<Map<String, String>> recipients, // List of {'email': '...', 'name': '...', 'phone': '...'}
    required String campaignTitle,
    required String bannerText,
    required String contentBody,
    required String ctaText,
    required String ctaLink,
  }) async {
    int emailSuccessCount = 0;
    int emailFailCount = 0;
    int waSuccessCount = 0;
    int waFailCount = 0;
    int waSkippedCount = 0;

    for (var r in recipients) {
      final email = r['email'] ?? '';
      final name = r['name'] ?? 'Student';
      final phone = r['phone'] ?? '';

      if (email.isNotEmpty && email.contains('@')) {
        final emailRes = await BrevoEmailService.instance.sendMarketingEmail(
          recipientEmail: email,
          recipientName: name,
          title: campaignTitle,
          bannerText: bannerText,
          contentBody: contentBody,
          ctaText: ctaText,
          ctaLink: ctaLink,
        );
        if (emailRes['success'] == true) {
          emailSuccessCount++;
        } else {
          emailFailCount++;
        }
      }

      if (phone.isNotEmpty) {
        final waCheck = await WhatsAppService.instance.checkWhatsAppAccount(phone);
        if (waCheck['has_whatsapp'] == true) {
          final waRes = await WhatsAppService.instance.sendMarketingWhatsApp(
            rawPhone: phone,
            headline: campaignTitle,
            bodyText: contentBody,
            link: ctaLink,
          );
          if (waRes['success'] == true) {
            waSuccessCount++;
          } else {
            waFailCount++;
          }
        } else {
          waSkippedCount++;
        }
      }
    }

    final summary = {
      'campaign_title': campaignTitle,
      'total_recipients': recipients.length,
      'email_success_count': emailSuccessCount,
      'email_fail_count': emailFailCount,
      'whatsapp_success_count': waSuccessCount,
      'whatsapp_fail_count': waFailCount,
      'whatsapp_skipped_count': waSkippedCount,
    };

    _logEvent('MARKETING_CAMPAIGN_DISPATCH', summary);
    return summary;
  }
}
