import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/cart_service.dart';
import '../../core/services/cloudflare_r2_service.dart';
import '../../core/services/supabase_service.dart';
import '../../models/models.dart';

class CheckoutScreen extends StatefulWidget {
  final CartItem? singleItem;
  final String? productId;

  const CheckoutScreen({
    Key? key,
    this.singleItem,
    this.productId,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _couponController = TextEditingController();
  String _selectedPaymentMethod = '';
  bool _isProcessingPayment = false;
  bool _isOrderSuccess = false;
  bool _isPendingVerification = false;
  String _submittedUtr = '';
  Map<String, dynamic> _paymentSettings = {};
  String _createdOrderId = '';
  CartItem? _activeItem;
  bool _isLoadingProduct = true;

  bool _isAlreadyOwned = false;

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

    _loadPaymentSettings();
    _initCheckoutItem();
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
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _initCheckoutItem() async {
    if (widget.singleItem != null) {
      setState(() {
        _activeItem = widget.singleItem;
        _isLoadingProduct = false;
      });
      return;
    }

    if (widget.productId != null && widget.productId!.isNotEmpty) {
      final all = await SupabaseService.fetchAllTestSeries();
      Map<String, dynamic>? match;
      for (var m in all) {
        if (m['id']?.toString() == widget.productId) {
          match = m;
          break;
        }
      }

      if (match != null) {
        final item = CartItem(
          id: match['id']?.toString() ?? widget.productId!,
          title: (match['title'] ?? match['name'] ?? 'Test Series').toString(),
          description: (match['description'] ?? '').toString(),
          price: (match['price'] is num) ? (match['price'] as num).toDouble() : 499.0,
          originalPrice: (match['original_price'] is num) ? (match['original_price'] as num).toDouble() : 1999.0,
          bannerImageUrl: (match['banner_image_url'] ?? '').toString(),
          exam: (match['exam'] ?? 'NEET').toString(),
          validity: (match['validity'] ?? 'Valid until exam').toString(),
          testCount: (match['test_count'] is num) ? (match['test_count'] as num).toInt() : 10,
        );

        if (mounted) {
          setState(() {
            _activeItem = item;
            _isLoadingProduct = false;
          });
          _checkEntitlement();
        }
        return;
      }
    }

    // Otherwise check if Cart has items
    if (CartService.instance.isNotEmpty) {
      setState(() {
        _activeItem = null; // Uses cart items
        _isLoadingProduct = false;
      });
      return;
    }

    setState(() {
      _activeItem = null;
      _isLoadingProduct = false;
    });
  }

  Future<void> _checkEntitlement() async {
    final user = SupabaseService.activeUserSession;
    if (user != null) {
      final pId = _activeItem?.id ?? (CartService.instance.items.isNotEmpty ? CartService.instance.items.first.id : '');
      if (pId.isNotEmpty) {
        final owns = await SupabaseService.hasActiveEntitlement(user.id, pId);
        if (mounted) setState(() => _isAlreadyOwned = owns);
      }
    }
  }

  double get _subtotal {
    if (_activeItem != null) return _activeItem!.price;
    return CartService.instance.subtotal;
  }

  double get _discountAmount {
    if (_activeItem != null) {
      final code = CartService.instance.appliedCouponCode?.toUpperCase() ?? '';
      if (code == 'COSMYRA20') return _subtotal * 0.20;
      if (code == 'NEET2027') return _subtotal * 0.30;
      if (code == 'EARLYBIRD') return _subtotal * 0.15;
      if (code == 'WELCOME100') return _subtotal >= 299 ? 100.0 : 0.0;
      return 0.0;
    }
    return CartService.instance.discountAmount;
  }

  double get _finalTotal => (_subtotal - _discountAmount).clamp(0.0, double.infinity);

  void _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    final result = await SupabaseService.validateCoupon(code, _subtotal);
    if (result['valid'] == true) {
      await CartService.instance.applyCoupon(code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Coupon applied successfully!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {});
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Invalid coupon code.'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _processPayment() async {
    if (_isAlreadyOwned) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You already own this test series! Redirecting to your tests...'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      context.go('/my-tests');
      return;
    }

    final user = SupabaseService.activeUserSession ??
        UserProfileModel(
          id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
          fullName: 'Student Aspirant',
          email: 'student@cosmyra.edtech',
          role: 'student',
        );

    final List<CartItem> itemsToPurchase = _activeItem != null
        ? [_activeItem!]
        : (CartService.instance.items.isNotEmpty
            ? CartService.instance.items
            : [_activeItem ?? CartItem(id: 'ts_default', title: 'Test Series', price: 499, originalPrice: 1999)]);

    final List<Map<String, dynamic>> itemsJson = itemsToPurchase.map((it) => it.toJson()).toList();

    if (_selectedPaymentMethod == 'UPI') {
      final upiId = (_paymentSettings['upi_id'] ?? '1mdollar2027@okicici').toString().trim();
      final payeeName = (_paymentSettings['upi_payee_name'] ?? 'Cosmyra Edu Platform').toString().trim();
      final amountStr = _finalTotal.toStringAsFixed(2);
      final upiUrl = 'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(payeeName)}&am=$amountStr&tn=${Uri.encodeComponent('Cosmyra Order Enrollment')}&cu=INR';

      // Automatically launch UPI app chooser (GPay, PhonePe, Paytm, BHIM) on all devices
      _launchUpiApp(upiUrl);

      await _showUpiVerificationModal(
        context: context,
        user: user,
        items: itemsJson,
        upiId: upiId,
        payeeName: payeeName,
        upiUrl: upiUrl,
      );
      return;
    }

    // Cashfree PG flow
    setState(() => _isProcessingPayment = true);
    try {
      final orderResult = await SupabaseService.createOrder(
        user: user,
        items: itemsJson,
        couponCode: CartService.instance.appliedCouponCode,
        paymentMethod: 'Cashfree PG',
      );

      final orderData = orderResult['order'] as Map<String, dynamic>?;
      final orderId = orderData?['order_number']?.toString() ??
          orderData?['order_id']?.toString() ??
          orderData?['id']?.toString() ??
          await SupabaseService.generateOrderId(userId: user.id);

      if (_activeItem == null) {
        CartService.instance.clearCart();
      }

      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
          _isPendingVerification = true;
          _isOrderSuccess = true;
          _createdOrderId = orderId;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cashfree Payment initiation note: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
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
                          couponCode: CartService.instance.appliedCouponCode ?? '',
                          totalAmount: _finalTotal,
                        );

                        if (widget.singleItem == null) {
                          CartService.instance.clearCart();
                        }

                        if (ctx.mounted) Navigator.pop(ctx);

                        if (mounted) {
                          setState(() {
                            _isProcessingPayment = false;
                            _isPendingVerification = true;
                            _isOrderSuccess = true;
                            _createdOrderId = res['order_number'] ?? 'ORD-${DateTime.now().millisecondsSinceEpoch}';
                            _submittedUtr = utr.isNotEmpty ? utr : 'Screenshot Attached';
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
                                      'Pay ₹${_finalTotal.toInt()}',
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

                            // OPTION 1: PAYMENT SCREENSHOT UPLOAD (CLOUDFLARE S3) - PROMINENT FIRST
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F3FF),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFDDD6FE), width: 1.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.cloud_upload_rounded, size: 16, color: Color(0xFF6D28D9)),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Option 1: Upload Payment Screenshot (Cloudflare S3)',
                                        style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w800, color: const Color(0xFF5B21B6)),
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
                                            border: Border.all(color: const Color(0xFF7C3AED), width: 1.2),
                                            color: const Color(0xFFF3E8FF),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF7C3AED),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Icon(Icons.add_a_photo_rounded, size: 18, color: Colors.white),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Upload Payment Screenshot Receipt',
                                                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF5B21B6)),
                                                    ),
                                                    Text(
                                                      'Tap to select GPay / PhonePe / Paytm receipt (S3)',
                                                      style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF6D28D9)),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Icon(Icons.cloud_upload_rounded, color: Color(0xFF7C3AED), size: 20),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),

                            // OPTION 2: 12-DIGIT UTR NUMBER INPUT
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
                                        'Option 2: Enter 12-Digit UTR / Ref Number',
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
    if (_isLoadingProduct) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
            onPressed: () => context.canPop() ? context.pop() : context.go('/test-series'),
          ),
          title: Text('Checkout', style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 16)),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
        ),
      );
    }

    if (_isOrderSuccess) {
      return _buildSuccessCelebration();
    }

    final user = SupabaseService.activeUserSession;
    if (user == null) {
      return _buildAuthRequiredBarrier();
    }

    final List<CartItem> items = _activeItem != null
        ? [_activeItem!]
        : (CartService.instance.items.isNotEmpty
            ? CartService.instance.items
            : [_activeItem!]);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => context.canPop() ? context.pop() : context.go('/test-series'),
        ),
        title: Text(
          'Complete Your Enrollment',
          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_rounded, size: 13, color: Color(0xFF059669)),
                  const SizedBox(width: 4),
                  Text(
                    '256-Bit SSL',
                    style: GoogleFonts.inter(color: const Color(0xFF059669), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Scrollable Checkout Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Order Items Section
                      _buildSectionTitle('Selected Package (${items.length})'),
                      const SizedBox(height: 10),
                      ...items.map((it) => _buildOrderItemTile(it)),
                      const SizedBox(height: 20),

                      // 2. Promo Coupon Section
                      _buildCouponCard(),
                      const SizedBox(height: 20),

                      // 3. Aspirant Details
                      _buildAspirantCard(user),
                      const SizedBox(height: 20),

                      // 4. Payment Method Selector
                      _buildSectionTitle('Select Payment Method'),
                      const SizedBox(height: 10),
                      _buildPaymentMethodCard(),
                      const SizedBox(height: 20),

                      // 5. Price Summary Card
                      _buildPriceSummaryCard(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom Action Bar
          _buildBottomPayBar(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), letterSpacing: -0.2),
    );
  }

  Widget _buildOrderItemTile(CartItem it) {
    final discountPercent = it.originalPrice > it.price
        ? (((it.originalPrice - it.price) / it.originalPrice) * 100).toInt()
        : 75;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.description_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  it.title,
                  style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${it.exam} • ${it.validity} • ${it.testCount} Tests Included',
                  style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${it.price.toInt()}',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
              ),
              if (it.originalPrice > it.price) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '₹${it.originalPrice.toInt()}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        decoration: TextDecoration.lineThrough,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$discountPercent% OFF',
                        style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w800, color: const Color(0xFFEF4444)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _buildCouponCard() {
    final applied = CartService.instance.appliedCouponCode;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.local_offer_rounded, color: Color(0xFF4F46E5), size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                'Apply Promo Coupon',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
              ),
              const Spacer(),
              if (applied != null)
                TextButton.icon(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: () {
                    CartService.instance.removeCoupon();
                    setState(() {});
                  },
                  icon: const Icon(Icons.close_rounded, size: 14, color: Color(0xFFEF4444)),
                  label: const Text('Remove', style: TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _couponController,
                  textCapitalization: TextCapitalization.characters,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: 'e.g. COSMYRA20, NEET2027',
                    hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _applyCoupon,
                child: Text('Apply', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Tap quick promo tags to auto-apply:',
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildQuickPromoChip('COSMYRA20', '20% OFF'),
              _buildQuickPromoChip('NEET2027', '30% OFF'),
              _buildQuickPromoChip('EARLYBIRD', '15% OFF'),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _buildQuickPromoChip(String code, String desc) {
    final isApplied = CartService.instance.appliedCouponCode == code;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        _couponController.text = code;
        _applyCoupon();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isApplied ? const Color(0xFFEEF2FF) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isApplied ? const Color(0xFF6366F1) : const Color(0xFFCBD5E1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isApplied ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
              size: 13,
              color: isApplied ? const Color(0xFF4F46E5) : const Color(0xFF475569),
            ),
            const SizedBox(width: 4),
            Text(
              '$code ($desc)',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: isApplied ? const Color(0xFF4F46E5) : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAspirantCard(UserProfileModel? user) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person_rounded, color: Color(0xFF2563EB), size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                'Aspirant Details',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded, size: 12, color: Color(0xFF15803D)),
                    const SizedBox(width: 4),
                    Text(
                      'Verified Student',
                      style: GoogleFonts.inter(color: const Color(0xFF15803D), fontSize: 10.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.badge_outlined, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Name: ${user?.fullName ?? 'Student Aspirant'}',
                        style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Email: ${user?.email ?? 'student@cosmyra.edtech'}',
                        style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _buildPaymentMethodCard() {
    final bool upiActive = SupabaseService.parseBool(_paymentSettings['upi_active'], defaultValue: true);
    final bool cashfreeActive = SupabaseService.parseBool(_paymentSettings['cashfree_active'], defaultValue: true);

    final methods = <Map<String, dynamic>>[];

    if (upiActive) {
      methods.add({
        'id': 'UPI',
        'title': '1} UPI Pay (Instant App & QR Transfer)',
        'subtitle': 'Google Pay, PhonePe, Paytm, BHIM • Direct Transfer & Verification',
        'icon': Icons.account_balance_wallet_outlined,
        'badge': 'RECOMMENDED',
      });
    }

    if (cashfreeActive) {
      methods.add({
        'id': 'Cashfree',
        'title': '2} CashFree PG (Secure Gateway)',
        'subtitle': 'Credit/Debit Cards, Net Banking, Wallets & Cashfree SDK',
        'icon': Icons.security_rounded,
        'badge': 'GATEWAY',
      });
    }

    if (methods.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFFDC2626)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No payment methods are currently active. Please contact platform admin to enable UPI or Cashfree PG.',
                style: TextStyle(color: Color(0xFF991B1B), fontSize: 12.5),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: methods.map((m) {
          final isSelected = _selectedPaymentMethod == m['id'];
          final isLast = m == methods.last;

          return InkWell(
            borderRadius: BorderRadius.vertical(
              top: m == methods.first ? const Radius.circular(16) : Radius.zero,
              bottom: isLast ? const Radius.circular(16) : Radius.zero,
            ),
            onTap: () => setState(() => _selectedPaymentMethod = m['id'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: const Color(0xFFF1F5F9), width: isLast ? 0 : 1)),
                color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(m['icon'] as IconData, color: isSelected ? Colors.white : const Color(0xFF64748B), size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              m['title'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? const Color(0xFF1E40AF) : const Color(0xFF0F172A),
                              ),
                            ),
                            if (m['badge'] != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  m['badge'] as String,
                                  style: GoogleFonts.inter(
                                    color: isSelected ? Colors.white : const Color(0xFF475569),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          m['subtitle'] as String,
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Radio<String>(
                    value: m['id'] as String,
                    groupValue: _selectedPaymentMethod,
                    activeColor: const Color(0xFF2563EB),
                    onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _buildPriceSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF16A34A), size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                'Price Breakdown',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
              Text('₹${_subtotal.toInt()}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
            ],
          ),
          if (_discountAmount > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF16A34A)),
                    const SizedBox(width: 4),
                    Text('Coupon Discount', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF16A34A))),
                  ],
                ),
                Text('- ₹${_discountAmount.toInt()}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF16A34A))),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Platform Fee & GST', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                child: Text('₹0 (Waived)', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF15803D), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Payable', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
              Text('₹${_finalTotal.toInt()}', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _buildBottomPayBar() {
    final buttonWidget = Container(
      height: 50,
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
          onTap: _isProcessingPayment ? null : _processPayment,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isProcessingPayment) ...[
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Securing...',
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ] else ...[
                  const Icon(Icons.shield_outlined, size: 20, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Pay ₹${_finalTotal.toInt()}',
                    style: GoogleFonts.inter(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.white),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.security_rounded, size: 12, color: Color(0xFF10B981)),
                    const SizedBox(width: 3),
                    Text(
                      'TOTAL PAYABLE',
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF64748B), letterSpacing: 0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${_finalTotal.toInt()}',
                  style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
                ),
              ],
            ),
            const Spacer(),
            if (_isAlreadyOwned) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final targetId = _activeItem?.id ?? 'ts_neet_all_india_2026';
                  context.go('/product/$targetId');
                },
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: const Text('Already Owned • Access Tests', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ] else ...[
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
          ],
        ),
      ),
    );
  }

  // ==========================================
  // ==========================================
  // CELEBRATORY ORDER SUCCESS SCREEN
  // ==========================================
  Widget _buildSuccessCelebration() {
    final primaryButtonWidget = Container(
      height: 52,
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
            final targetId = _activeItem?.id ?? 'ts_neet_all_india_2026';
            context.go('/product/$targetId');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    fontSize: 15,
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Icon Badge
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
                const SizedBox(height: 20),

                // Main Title
                Text(
                  _isPendingVerification ? 'Verification Request Sent! ⏳' : 'Enrollment Confirmed! 🎉',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  _isPendingVerification
                      ? 'Your payment proof has been safely received. Our Admin team will verify your UTR and activate instant access shortly.'
                      : 'Congratulations! Your enrollment is active. All mock tests, detailed solutions, and analytics are unlocked.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B), height: 1.45),
                ),
                const SizedBox(height: 20),

                // Summary Order Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Order Number:', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
                          Text(
                            _createdOrderId.length > 20 ? '${_createdOrderId.substring(0, 20)}...' : _createdOrderId,
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      if (_submittedUtr.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('UTR Ref No:', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _submittedUtr,
                                style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w900, color: const Color(0xFF4F46E5)),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Divider(height: 20, color: Color(0xFFE2E8F0)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Verification Status:', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
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
                                  size: 12,
                                  color: _isPendingVerification ? const Color(0xFFDC2626) : const Color(0xFF059669),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _isPendingVerification ? 'Pending Admin Approval' : 'Verified & Active',
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
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
                const SizedBox(height: 24),

                // Shaking Red Gradient Primary Action Button
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
                const SizedBox(height: 12),

                // Secondary Action Button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => context.go('/test-series'),
                    child: Text('Explore More Test Series', style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.94, 0.94)),
        ),
      ),
    );
  }

  Widget _buildAuthRequiredBarrier() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => context.canPop() ? context.pop() : context.go('/test-series'),
        ),
        title: Text('Checkout', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(color: Color(0xFFEEF2FF), shape: BoxShape.circle),
                  child: const Icon(Icons.lock_person_rounded, color: Color(0xFF4F46E5), size: 34),
                ),
                const SizedBox(height: 20),
                Text('Sign In Required', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                const SizedBox(height: 10),
                Text(
                  'Please sign in or create an account to enroll in this test series. Your account ensures your test analytics, All India Rank, and solutions are safely synced.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF64748B), height: 1.5),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => context.push('/login?redirect=${Uri.encodeComponent('/checkout')}'),
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: const Text('Sign In to Continue', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    minimumSize: const Size(double.infinity, 44),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => context.canPop() ? context.pop() : context.go('/test-series'),
                  child: const Text('Return to Test Series', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
