import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/services/cloudflare_r2_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../models/models.dart';

class EcommerceCheckoutDialog extends StatefulWidget {
  final CartItem? singleItem; // If Buy Now was clicked for a single item
  final Function(String testId, String title, int duration) onStartTest;

  const EcommerceCheckoutDialog({
    Key? key,
    this.singleItem,
    required this.onStartTest,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    CartItem? singleItem,
    required Function(String testId, String title, int duration) onStartTest,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => EcommerceCheckoutDialog(
        singleItem: singleItem,
        onStartTest: onStartTest,
      ),
    );
  }

  @override
  State<EcommerceCheckoutDialog> createState() => _EcommerceCheckoutDialogState();
}

class _EcommerceCheckoutDialogState extends State<EcommerceCheckoutDialog> with SingleTickerProviderStateMixin {
  final TextEditingController _couponCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  String _selectedPaymentMethod = ''; // 'UPI', 'Cashfree'
  bool _isProcessing = false;
  bool _isSuccess = false;
  bool _isPendingVerification = false;
  String _submittedUtr = '';
  Map<String, dynamic> _paymentSettings = {};
  String _orderId = '';
  String _successMessage = '';

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -5.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 5.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 5.0, end: -4.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 4.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: -2.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -2.0, end: 2.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 2.0, end: 0.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.0), weight: 8),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));

    final profile = SupabaseService.activeUserSession;
    _nameCtrl.text = profile?.fullName ?? 'Aman Kumar';
    _phoneCtrl.text = profile?.phoneNumber ?? '9876543210';
    _loadPaymentSettings();
  }

  Future<void> _loadPaymentSettings() async {
    final settings = await SupabaseService.fetchPaymentSettings();
    if (mounted) {
      setState(() {
        _paymentSettings = settings;
        final upiActive = SupabaseService.parseBool(settings['upi_active'], defaultValue: true);
        final cashfreeActive = SupabaseService.parseBool(settings['cashfree_active'], defaultValue: true);
        if (cashfreeActive && !upiActive) {
          _selectedPaymentMethod = 'Cashfree';
        } else if (upiActive) {
          _selectedPaymentMethod = 'UPI';
        } else if (cashfreeActive) {
          _selectedPaymentMethod = 'Cashfree';
        } else {
          _selectedPaymentMethod = '';
        }
      });
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _couponCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  List<CartItem> get _effectiveItems {
    if (widget.singleItem != null) {
      return [widget.singleItem!];
    }
    return CartService.instance.items;
  }

  double get _subtotal {
    double sum = 0.0;
    for (var it in _effectiveItems) {
      sum += it.price;
    }
    return sum;
  }

  double get _originalSubtotal {
    double sum = 0.0;
    for (var it in _effectiveItems) {
      sum += it.originalPrice;
    }
    return sum;
  }

  double get _discountAmount {
    if (widget.singleItem != null) {
      final coupon = CartService.instance.appliedCoupon;
      if (coupon == null) return 0.0;
      final type = coupon['discount_type']?.toString() ?? 'percentage';
      final val = (coupon['discount_value'] as num?)?.toDouble() ?? 0.0;
      final maxDisc = (coupon['max_discount'] as num?)?.toDouble() ?? 500.0;
      double calc = (type == 'percentage') ? (_subtotal * val) / 100.0 : val;
      if (calc > maxDisc) calc = maxDisc;
      if (calc > _subtotal) calc = _subtotal;
      return calc;
    }
    return CartService.instance.discountAmount;
  }

  double get _totalPayable {
    final res = _subtotal - _discountAmount;
    return res > 0 ? res : 0.0;
  }

  Future<void> _applyCoupon() async {
    final code = _couponCtrl.text.trim();
    if (code.isEmpty) return;

    final res = await CartService.instance.applyCoupon(code);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? ''),
          backgroundColor: res['success'] == true ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handlePayment() async {
    final user = SupabaseService.activeUserSession ??
        SupabaseService.getMockProfile(role: 'student');

    final itemsData = _effectiveItems.map((e) => e.toJson()).toList();

    if (_selectedPaymentMethod == 'UPI') {
      final upiId = (_paymentSettings['upi_id'] ?? '1mdollar2027@okicici').toString().trim();
      final payeeName = (_paymentSettings['upi_payee_name'] ?? 'Cosmyra Edu Platform').toString().trim();
      final amountStr = _totalPayable.toStringAsFixed(2);
      final upiUrl = 'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(payeeName)}&am=$amountStr&tn=${Uri.encodeComponent('Cosmyra Order Enrollment')}&cu=INR';

      // Automatically launch UPI app chooser (GPay, PhonePe, Paytm, BHIM) on all devices
      _launchUpiApp(upiUrl);

      await _showUpiVerificationModal(
        context: context,
        user: user,
        items: itemsData,
        upiId: upiId,
        payeeName: payeeName,
        upiUrl: upiUrl,
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final couponCode = CartService.instance.appliedCoupon?['code']?.toString();

      final orderRes = await SupabaseService.createOrder(
        user: user,
        items: itemsData,
        couponCode: couponCode,
        paymentMethod: 'Cashfree PG',
      );

      final orderData = orderRes['order'];
      final createdOrderId = (orderData['order_number'] ?? orderData['order_id'] ?? orderData['id']).toString();

      if (widget.singleItem == null) {
        CartService.instance.clearCart();
      }

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isSuccess = true;
          _isPendingVerification = true;
          _orderId = createdOrderId;
          _successMessage = 'Order Submitted! Pending Admin Verification.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cashfree payment error: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _launchUpiApp(String upiUrl) async {
    try {
      final uri = Uri.parse(upiUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('UPI app launcher note: $e');
    }
  }

  Future<void> _showUpiVerificationModal({
    required BuildContext context,
    required UserProfileModel user,
    required List<Map<String, dynamic>> items,
    required String upiId,
    required String payeeName,
    required String upiUrl,
  }) async {
    final utrCtrl = TextEditingController();
    bool isSubmitting = false;
    String? paymentScreenshotUrl;
    bool isUploadingScreenshot = false;
    String? screenshotFileName;

    final qrImageUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=260x260&data=${Uri.encodeComponent(upiUrl)}';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final submitButtonWidget = Container(
            height: 50,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: isSubmitting
                  ? const LinearGradient(colors: [Color(0xFF94A3B8), Color(0xFF64748B)])
                  : const LinearGradient(
                      colors: [Color(0xFFFF3B30), Color(0xFFEF4444), Color(0xFFDC2626)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              boxShadow: [
                BoxShadow(
                  color: isSubmitting
                      ? Colors.black.withValues(alpha: 0.1)
                      : const Color(0xFFEF4444).withValues(alpha: 0.5),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: isSubmitting || isUploadingScreenshot
                    ? null
                    : () async {
                        final utr = utrCtrl.text.trim();
                        final hasUtr = utr.isNotEmpty && utr.length >= 6;
                        final hasScreenshot = paymentScreenshotUrl != null && paymentScreenshotUrl!.isNotEmpty;

                        if (!hasUtr && !hasScreenshot) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid 12-digit UTR number OR attach a payment screenshot (or both).'),
                              backgroundColor: Color(0xFFEF4444),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        setDialogState(() => isSubmitting = true);

                        final res = await SupabaseService.submitUpiPaymentVerification(
                          user: user,
                          items: items,
                          utrNumber: utr,
                          paymentScreenshotUrl: paymentScreenshotUrl,
                          couponCode: CartService.instance.appliedCoupon?['code']?.toString() ?? '',
                          totalAmount: _totalPayable,
                        );

                        if (widget.singleItem == null) {
                          CartService.instance.clearCart();
                        }

                        if (ctx.mounted) Navigator.pop(ctx);

                        if (mounted) {
                          setState(() {
                            _isProcessing = false;
                            _isSuccess = true;
                            _isPendingVerification = true;
                            _orderId = res['order_number'] ?? 'ORD-${DateTime.now().millisecondsSinceEpoch}';
                            _submittedUtr = utr.isNotEmpty ? utr : 'Screenshot Attached';
                            _successMessage = 'UPI Payment request submitted (${utr.isNotEmpty ? "UTR: $utr" : "Screenshot attached"}). Pending Admin approval.';
                          });
                        }
                      },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isSubmitting) ...[
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Submitting Verification...',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ] else ...[
                        const Icon(Icons.verified_rounded, size: 20, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Submit Payment Verification',
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );

          return Dialog(
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 440,
                maxHeight: MediaQuery.of(dialogCtx).size.height * 0.88,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Modal Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Complete UPI Payment',
                                style: GoogleFonts.inter(fontSize: 16.5, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Pay ₹${_totalPayable.toInt()}',
                                      style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w900, color: const Color(0xFF059669)),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'GPay • PhonePe • Paytm • BHIM',
                                      style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: Color(0xFFE2E8F0)),

                    // Scrollable Inner Body to prevent clipping
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // STEP 1 Badge & Direct App Launch Button
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'STEP 1',
                                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF4F46E5)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Tap below to open UPI App:',
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF334155)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => _launchUpiApp(upiUrl),
                                icon: const Icon(Icons.touch_app_rounded, size: 18),
                                label: Text(
                                  'Open UPI App (GPay / PhonePe / Paytm)',
                                  style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // QR Code Card Display
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        qrImageUrl,
                                        width: 160,
                                        height: 160,
                                        fit: BoxFit.contain,
                                        errorBuilder: (ctx, err, st) => Container(
                                          width: 160,
                                          height: 160,
                                          color: const Color(0xFFF1F5F9),
                                          child: const Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.qr_code_2_rounded, size: 44, color: Color(0xFF64748B)),
                                              SizedBox(height: 6),
                                              Text('Scan with any UPI App', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Scan QR using GPay, PhonePe, Paytm, BHIM',
                                      style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Merchant UPI ID Card
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Official Merchant UPI ID:', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                                        const SizedBox(height: 2),
                                        SelectableText(
                                          upiId,
                                          style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w900, color: const Color(0xFF2563EB)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: upiId));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('✓ Merchant UPI ID copied to clipboard!'),
                                          backgroundColor: Color(0xFF10B981),
                                          behavior: SnackBarBehavior.floating,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.copy_rounded, size: 13, color: Color(0xFF475569)),
                                    label: Text('Copy ID', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF475569))),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // STEP 2: Instructions & Verification Submission (UTR, Screenshot or Both)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD97706),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'STEP 2',
                                          style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w900, color: Colors.white),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Verify Payment (UTR, Screenshot or Both)',
                                          style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w800, color: const Color(0xFF92400E)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'For verification, you can submit your 12-digit UTR/Ref Number, upload a payment screenshot receipt (Cloudflare S3), or provide BOTH:',
                                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF78350F), height: 1.35),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),

                            // OPTION 1: 12-DIGIT UTR NUMBER INPUT
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.pin_rounded, size: 15, color: Color(0xFF2563EB)),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Option 1: Enter 12-Digit UTR / Ref Number',
                                        style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: utrCtrl,
                                    keyboardType: TextInputType.number,
                                    maxLength: 12,
                                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A), letterSpacing: 1.0),
                                    decoration: InputDecoration(
                                      hintText: 'e.g. 429182736410 (UTR / Ref No.)',
                                      hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8), letterSpacing: 0.0),
                                      counterText: '',
                                      isDense: true,
                                      filled: true,
                                      fillColor: Colors.white,
                                      prefixIcon: const Icon(Icons.confirmation_number_rounded, size: 18, color: Color(0xFF64748B)),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),

                            // OPTION 2: PAYMENT SCREENSHOT UPLOAD (CLOUDFLARE S3)
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.cloud_upload_rounded, size: 15, color: Color(0xFF4F46E5)),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Option 2: Upload Payment Screenshot (Cloudflare S3)',
                                        style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  if (isUploadingScreenshot) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFF93C5FD)),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(color: Color(0xFF2563EB), strokeWidth: 2.5),
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            'Uploading Receipt to Cloudflare S3...',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else if (paymentScreenshotUrl != null && paymentScreenshotUrl!.isNotEmpty) ...[
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFECFDF5),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFA7F3D0)),
                                      ),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(6),
                                            child: Image.network(
                                              paymentScreenshotUrl!,
                                              width: 44,
                                              height: 44,
                                              fit: BoxFit.cover,
                                              errorBuilder: (c, e, s) => Container(width: 44, height: 44, color: const Color(0xFFD1FAE5), child: const Icon(Icons.image, color: Color(0xFF059669))),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF059669)),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Screenshot Uploaded to S3',
                                                      style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w800, color: const Color(0xFF065F46)),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  screenshotFileName ?? 'payment_receipt.png',
                                                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF047857)),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                                            tooltip: 'Remove Screenshot',
                                            onPressed: () {
                                              setDialogState(() {
                                                paymentScreenshotUrl = null;
                                                screenshotFileName = null;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else ...[
                                    Material(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      child: InkWell(
                                        onTap: () async {
                                          try {
                                            final result = await FilePicker.platform.pickFiles(
                                              type: FileType.custom,
                                              allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
                                              withData: true,
                                              withReadStream: true,
                                            );
                                            if (result != null && result.files.isNotEmpty) {
                                              final file = result.files.first;
                                              Uint8List? bytes = file.bytes;
                                              if ((bytes == null || bytes.isEmpty) && file.readStream != null) {
                                                final List<int> allBytes = [];
                                                await for (final chunk in file.readStream!) {
                                                  allBytes.addAll(chunk);
                                                }
                                                bytes = Uint8List.fromList(allBytes);
                                              }

                                              if (bytes != null && bytes.isNotEmpty) {
                                                setDialogState(() => isUploadingScreenshot = true);
                                                final ext = (file.extension ?? 'png').toLowerCase();
                                                final mimeType = ext == 'jpg' || ext == 'jpeg' ? 'image/jpeg' : (ext == 'webp' ? 'image/webp' : 'image/png');
                                                final url = await SupabaseService.uploadMediaFile(
                                                  fileBytes: bytes,
                                                  fileName: file.name,
                                                  mimeType: mimeType,
                                                );
                                                setDialogState(() {
                                                  paymentScreenshotUrl = url;
                                                  screenshotFileName = file.name;
                                                  isUploadingScreenshot = false;
                                                });
                                              }
                                            }
                                          } catch (e) {
                                            setDialogState(() => isUploadingScreenshot = false);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Screenshot upload error: $e'), backgroundColor: const Color(0xFFEF4444)),
                                            );
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFFCBD5E1)),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFEEF2FF),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Icon(Icons.add_a_photo_rounded, size: 18, color: Color(0xFF4F46E5)),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Upload Payment Screenshot Receipt',
                                                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                                                    ),
                                                    Text(
                                                      'Tap to select GPay / PhonePe / Paytm receipt (S3)',
                                                      style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Icon(Icons.cloud_upload_outlined, color: Color(0xFF4F46E5), size: 18),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Shaking Vibrant Red Gradient Submit Button
                            AnimatedBuilder(
                              animation: _shakeAnimation,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(_shakeAnimation.value, 0),
                                  child: child,
                                );
                              },
                              child: submitButtonWidget,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(duration: 250.ms).scale(begin: const Offset(0.96, 0.96));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) {
      return _buildSuccessDialog();
    }

    final isMobile = MediaQuery.of(context).size.width < 700;

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: isMobile ? double.infinity : 680,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          children: [
            // Header
            _buildDialogHeader(),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Order Summary Cards
                    _buildOrderItemsSection(),
                    const SizedBox(height: 18),

                    // 2. Coupon Code Input
                    _buildCouponSection(),
                    const SizedBox(height: 18),

                    // 3. Customer Info Summary
                    _buildCustomerInfoSection(),
                    const SizedBox(height: 18),

                    // 4. Payment Method Selector
                    _buildPaymentMethodSection(),
                    const SizedBox(height: 18),

                    // 5. Price Breakdown
                    _buildPriceBreakdown(),
                  ],
                ),
              ),
            ),

            // Sticky Bottom CTA Bar
            _buildStickyBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Complete Your Enrollment',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.lock_rounded, size: 12, color: Color(0xFF10B981)),
                  const SizedBox(width: 4),
                  Text(
                    '256-Bit SSL Encrypted • Instant Access',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
            tooltip: 'Cancel & Close',
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Selected Items (${_effectiveItems.length})',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '100% NTA Verified',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _effectiveItems.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, idx) {
            final it = _effectiveItems[idx];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.quiz_rounded, color: Color(0xFF4F46E5), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          it.title,
                          style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${it.exam} • ${it.validity} • ${it.testCount} Tests Included',
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${it.price.toInt()}',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                      ),
                      Text(
                        '₹${it.originalPrice.toInt()}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          decoration: TextDecoration.lineThrough,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCouponSection() {
    final coupon = CartService.instance.appliedCoupon;
    final isApplied = coupon != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isApplied ? const Color(0xFF10B981) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer_outlined, color: Color(0xFF4F46E5), size: 16),
              const SizedBox(width: 6),
              Text(
                'Apply Promo Coupon',
                style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
              ),
              const Spacer(),
              if (isApplied)
                InkWell(
                  onTap: () {
                    CartService.instance.removeCoupon();
                    _couponCtrl.clear();
                  },
                  child: const Text(
                    'Remove',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (isApplied) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Coupon "${coupon['code']}" applied! You saved ₹${_discountAmount.toInt()}',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF065F46)),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: TextField(
                      controller: _couponCtrl,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, letterSpacing: 1),
                      decoration: const InputDecoration(
                        hintText: 'e.g. COSMYRA20, NEET2027',
                        hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5, letterSpacing: 0),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _applyCoupon,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Apply', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Try: COSMYRA20 (20% OFF) or NEET2027 (30% OFF)',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerInfoSection() {
    final user = SupabaseService.activeUserSession;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, color: Color(0xFF4F46E5), size: 16),
              const SizedBox(width: 6),
              Text(
                'Aspirant Details',
                style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
              ),
              const Spacer(),
              if (user != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(4)),
                  child: const Text('Verified Account', style: TextStyle(fontSize: 10, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Name: ${_nameCtrl.text.isNotEmpty ? _nameCtrl.text : "Student"}',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF334155), fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: Text(
                  'Email: ${user?.email ?? "student@cosmyra.in"}',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    final bool upiActive = SupabaseService.parseBool(_paymentSettings['upi_active'], defaultValue: true);
    final bool cashfreeActive = SupabaseService.parseBool(_paymentSettings['cashfree_active'], defaultValue: true);

    final methods = <Map<String, dynamic>>[];

    if (upiActive) {
      methods.add({
        'id': 'UPI',
        'title': '1} UPI Pay (QR & App)',
        'desc': 'GPay, PhonePe, Paytm, BHIM',
        'icon': Icons.qr_code_2_rounded,
      });
    }

    if (cashfreeActive) {
      methods.add({
        'id': 'Cashfree',
        'title': '2} CashFree PG',
        'desc': 'Cards, NetBanking & Wallets',
        'icon': Icons.security_rounded,
      });
    }

    if (methods.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: const Text(
          'No payment gateways currently active. Contact Admin to enable UPI or Cashfree PG.',
          style: TextStyle(color: Color(0xFF991B1B), fontSize: 12),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Payment Method',
          style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: methods.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: methods.length == 1 ? 1 : 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: methods.length == 1 ? 4.5 : 2.5,
          ),
          itemBuilder: (ctx, idx) {
            final m = methods[idx];
            final isSel = _selectedPaymentMethod == m['id'];
            return InkWell(
              onTap: () => setState(() => _selectedPaymentMethod = m['id'] as String),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isSel ? const Color(0xFFEEF2FF) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSel ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
                    width: isSel ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(m['icon'] as IconData, size: 20, color: isSel ? const Color(0xFF4F46E5) : const Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            m['title'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                              color: isSel ? const Color(0xFF4F46E5) : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            m['desc'] as String,
                            style: GoogleFonts.inter(fontSize: 9.5, color: const Color(0xFF64748B)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (isSel)
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF4F46E5), size: 16),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPriceBreakdown() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal MRP', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
              Text(
                '₹${_originalSubtotal.toInt()}',
                style: GoogleFonts.inter(fontSize: 12, decoration: TextDecoration.lineThrough, color: const Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Standard Series Discount', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
              Text(
                '-₹${(_originalSubtotal - _subtotal).toInt()}',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF10B981), fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (_discountAmount > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Coupon Discount', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                Text(
                  '-₹${_discountAmount.toInt()}',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF10B981), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
          const Divider(height: 16, color: Color(0xFFCBD5E1)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Payable', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                  const Text('Inclusive of all taxes', style: TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                ],
              ),
              Text(
                '₹${_totalPayable.toInt()}',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF4F46E5)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomBar() {
    final buttonWidget = Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF3B30), Color(0xFFEF4444), Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _isProcessing ? null : _handlePayment,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isProcessing) ...[
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Securing...',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ] else ...[
                  const Icon(Icons.shield_outlined, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Pay ₹${_totalPayable.toInt()}',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.white),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.security_rounded, size: 11, color: Color(0xFF10B981)),
                  const SizedBox(width: 3),
                  Text(
                    'TOTAL PAYABLE',
                    style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.bold, color: const Color(0xFF64748B), letterSpacing: 0.5),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '₹${_totalPayable.toInt()}',
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
              ),
            ],
          ),
          const Spacer(),
          AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_shakeAnimation.value, 0),
                child: child,
              );
            },
            child: buttonWidget,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessDialog() {
    final firstItem = _effectiveItems.isNotEmpty ? _effectiveItems.first : null;

    final primaryButtonWidget = Container(
      height: 50,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF3B30), Color(0xFFEF4444), Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.5),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.of(context).pop();
            if (firstItem != null) {
              widget.onStartTest(firstItem.id, firstItem.title, 180);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isPendingVerification ? Icons.rocket_launch_rounded : Icons.play_arrow_rounded,
                  size: 20,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  _isPendingVerification ? 'Go to My Courses & Tests' : 'Start Learning Now',
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Glowing Icon Badge
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: _isPendingVerification
                    ? const LinearGradient(
                        colors: [Color(0xFFFF3B30), Color(0xFFEF4444), Color(0xFFDC2626)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF10B981)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _isPendingVerification
                        ? const Color(0xFFEF4444).withValues(alpha: 0.45)
                        : const Color(0xFF10B981).withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                _isPendingVerification ? Icons.hourglass_top_rounded : Icons.check_circle_rounded,
                color: Colors.white,
                size: 42,
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 18),

            // Main Title
            Text(
              _isPendingVerification ? 'Verification Request Sent! ⏳' : 'Enrollment Confirmed! 🎉',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              _isPendingVerification
                  ? 'Order #${_orderId.isNotEmpty ? _orderId : "ORD-39346739"} has been submitted${_submittedUtr.isNotEmpty ? " with UTR: $_submittedUtr" : ""}. Our Admin team will verify your payment and grant instant access shortly.'
                  : 'Congratulations! Your payment has been verified. All test series and solutions are now active.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B), height: 1.45),
            ),
            const SizedBox(height: 18),

            // Summary Order Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Order Number:', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
                      Text(
                        _orderId.length > 20 ? '${_orderId.substring(0, 20)}...' : (_orderId.isNotEmpty ? _orderId : 'ORD-39346739'),
                        style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  if (_submittedUtr.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('UTR Ref No:', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _submittedUtr,
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w900, color: const Color(0xFF4F46E5)),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Divider(height: 18, color: Color(0xFFE2E8F0)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Verification Status:', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _isPendingVerification ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _isPendingVerification ? const Color(0xFFFCA5A5) : const Color(0xFFA7F3D0),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isPendingVerification ? Icons.schedule_rounded : Icons.verified_rounded,
                              size: 11,
                              color: _isPendingVerification ? const Color(0xFFDC2626) : const Color(0xFF059669),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isPendingVerification ? 'Pending Admin Approval' : 'Verified & Active',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _isPendingVerification ? const Color(0xFFDC2626) : const Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Shaking Vibrant Red Gradient Primary Button
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_shakeAnimation.value, 0),
                  child: child,
                );
              },
              child: primaryButtonWidget,
            ),
            const SizedBox(height: 10),

            // Secondary Option: Explore More Test Series
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Explore More Test Series',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF475569)),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.94, 0.94));
  }
}
