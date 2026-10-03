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
import 'upi_payment_verification_screen.dart';

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

    if (widget.singleItem != null) {
      _activeItem = widget.singleItem;
      _isLoadingProduct = false;
    } else if (CartService.instance.items.isNotEmpty) {
      _activeItem = CartService.instance.items.first;
      _isLoadingProduct = false;
    } else if (widget.productId == null || widget.productId!.isEmpty) {
      _isLoadingProduct = false;
    }

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
    if (context.mounted) {
      debugPrint('PAYMENT_FLOW: OPEN_PAYMENT_VERIFICATION');
      context.push('/upi-payment-verification', extra: {
        'user': user,
        'items': items,
        'totalAmount': _finalTotal,
        'couponCode': CartService.instance.appliedCouponCode ?? '',
        'upiId': upiId,
        'payeeName': payeeName,
        'upiUrl': upiUrl,
      });
    }
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

    final user = SupabaseService.activeUserSession ??
        UserProfileModel(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          fullName: 'Student Aspirant',
          email: 'student@cosmyra.edtech',
          role: 'student',
        );

    final List<CartItem> itemsToPurchase = _activeItem != null
        ? [_activeItem!]
        : (CartService.instance.items.isNotEmpty
            ? CartService.instance.items
            : [CartItem(id: 'ts_default', title: 'Test Series', price: 499, originalPrice: 1999)]);

    final List<Map<String, dynamic>> itemsJson = itemsToPurchase.map((it) => it.toJson()).toList();
    final upiId = (_paymentSettings['upi_id'] ?? '1mdollar2027@okicici').toString().trim();
    final payeeName = (_paymentSettings['upi_payee_name'] ?? 'Cosmyra Edu Platform').toString().trim();
    final amountStr = _finalTotal.toStringAsFixed(2);
    final upiUrl = 'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(payeeName)}&am=$amountStr&tn=${Uri.encodeComponent('Cosmyra Order Enrollment')}&cu=INR';

    return UpiPaymentVerificationScreen(
      user: user,
      items: itemsJson,
      totalAmount: _finalTotal,
      couponCode: CartService.instance.appliedCouponCode ?? '',
      upiId: upiId,
      payeeName: payeeName,
      upiUrl: upiUrl,
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
