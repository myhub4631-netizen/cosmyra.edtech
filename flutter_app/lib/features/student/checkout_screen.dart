import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/cart_service.dart';
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

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _couponController = TextEditingController();
  String _selectedPaymentMethod = 'UPI';
  bool _isProcessingPayment = false;
  bool _isOrderSuccess = false;
  String _createdOrderId = '';
  CartItem? _activeItem;
  bool _isLoadingProduct = true;

  @override
  void initState() {
    super.initState();
    _initCheckoutItem();
  }

  @override
  void dispose() {
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
      match ??= SupabaseService.defaultCuratedTestSeries.first;

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
      }
      return;
    }

    // Otherwise check if Cart has items
    if (CartService.instance.isNotEmpty) {
      setState(() {
        _activeItem = null; // Uses cart items
        _isLoadingProduct = false;
      });
      return;
    }

    // Default fallback to first curated series
    final def = SupabaseService.defaultCuratedTestSeries.first;
    setState(() {
      _activeItem = CartItem(
        id: def['id'],
        title: def['title'],
        description: def['description'],
        price: def['price'],
        originalPrice: def['original_price'],
        bannerImageUrl: def['banner_image_url'],
        exam: def['exam'],
        validity: def['validity'],
        testCount: def['test_count'],
      );
      _isLoadingProduct = false;
    });
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
    setState(() => _isProcessingPayment = true);

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

    try {
      // 1. Create order
      final orderResult = await SupabaseService.createOrder(
        user: user,
        items: itemsJson,
        couponCode: CartService.instance.appliedCouponCode,
        paymentMethod: _selectedPaymentMethod,
      );

      final orderData = orderResult['order'] as Map<String, dynamic>?;
      final orderId = orderData?['id']?.toString() ?? 'ORD_${DateTime.now().millisecondsSinceEpoch}';

      // 2. Simulate fast payment settlement
      await Future.delayed(const Duration(milliseconds: 1400));

      // 3. Verify payment and grant entitlements
      await SupabaseService.verifyPaymentAndGrantAccess(
        orderId: orderId,
        paymentId: 'PAY_${DateTime.now().millisecondsSinceEpoch}_SIM',
        paymentMethod: _selectedPaymentMethod,
        user: user,
        items: itemsJson,
      );

      // 4. Clear cart if bought cart items
      if (_activeItem == null) {
        CartService.instance.clearCart();
      }

      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
          _isOrderSuccess = true;
          _createdOrderId = orderId;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment initiation error: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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

    if (_isOrderSuccess) {
      return _buildSuccessCelebration();
    }

    final user = SupabaseService.activeUserSession;
    final List<CartItem> items = _activeItem != null
        ? [_activeItem!]
        : (CartService.instance.items.isNotEmpty
            ? CartService.instance.items
            : [_activeItem!]);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => context.canPop() ? context.pop() : context.go('/test-series'),
        ),
        title: Text(
          'Complete Your Enrollment',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Icon(Icons.lock_rounded, size: 14, color: Color(0xFF10B981)),
                SizedBox(width: 4),
                Text('256-Bit SSL', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
              ],
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
      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
    );
  }

  Widget _buildOrderItemTile(CartItem it) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
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
            child: const Icon(Icons.description_rounded, color: Color(0xFF4F46E5), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  it.title,
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${it.exam} • ${it.validity} • ${it.testCount} Tests Included',
                  style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${it.price.toInt()}',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
              ),
              if (it.originalPrice > it.price)
                Text(
                  '₹${it.originalPrice.toInt()}',
                  style: GoogleFonts.inter(fontSize: 11, decoration: TextDecoration.lineThrough, color: const Color(0xFF94A3B8)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCouponCard() {
    final applied = CartService.instance.appliedCouponCode;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer_outlined, color: Color(0xFF4F46E5), size: 18),
              const SizedBox(width: 8),
              Text('Apply Promo Coupon', style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
              const Spacer(),
              if (applied != null)
                TextButton(
                  onPressed: () {
                    CartService.instance.removeCoupon();
                    setState(() {});
                  },
                  child: const Text('Remove', style: TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _couponController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'e.g. COSMYRA20, NEET2027',
                    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _applyCoupon,
                child: const Text('Apply', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Try: COSMYRA20 (20% OFF) • NEET2027 (30% OFF) • EARLYBIRD (15% OFF)',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildAspirantCard(UserProfileModel? user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, color: Color(0xFF4F46E5), size: 18),
              const SizedBox(width: 8),
              Text('Aspirant Details', style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(4)),
                child: const Text('Verified Account', style: TextStyle(color: Color(0xFF15803D), fontSize: 10.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text('Name: ${user?.fullName ?? 'Student Aspirant'}', style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF334155))),
              ),
              Expanded(
                child: Text('Email: ${user?.email ?? 'student@cosmyra.edtech'}', style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF334155)), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    final methods = [
      {'id': 'UPI', 'title': 'UPI Instant Transfer', 'subtitle': 'Google Pay, PhonePe, Paytm, BHIM', 'icon': Icons.account_balance_wallet_outlined},
      {'id': 'Cards', 'title': 'Credit / Debit Cards', 'subtitle': 'Visa, MasterCard, RuPay, Maestro', 'icon': Icons.credit_card_outlined},
      {'id': 'NetBanking', 'title': 'Net Banking', 'subtitle': 'SBI, HDFC, ICICI, Axis & 50+ banks', 'icon': Icons.account_balance_outlined},
      {'id': 'Razorpay', 'title': 'Razorpay Secure Gateway', 'subtitle': 'All online payment channels', 'icon': Icons.security_rounded},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: methods.map((m) {
          final isSelected = _selectedPaymentMethod == m['id'];
          return InkWell(
            onTap: () => setState(() => _selectedPaymentMethod = m['id'] as String),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: const Color(0xFFF1F5F9), width: m == methods.last ? 0 : 1)),
                color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
              ),
              child: Row(
                children: [
                  Icon(m['icon'] as IconData, color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B), size: 20),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m['title'] as String, style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                        Text(m['subtitle'] as String, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
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
    );
  }

  Widget _buildPriceSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Price Breakdown', style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
          const SizedBox(height: 12),
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
                Text('Coupon Discount', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF16A34A))),
                Text('- ₹${_discountAmount.toInt()}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF16A34A))),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Platform Fee & GST', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
              const Text('₹0 (Waived)', style: TextStyle(fontSize: 13, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Payable', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
              Text('₹${_finalTotal.toInt()}', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPayBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, -2)),
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
                Text('Final Amount', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                Text('₹${_finalTotal.toInt()}', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
              ],
            ),
            const Spacer(),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _isProcessingPayment ? null : _processPayment,
              icon: _isProcessingPayment
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.lock_outline_rounded, size: 18),
              label: Text(
                _isProcessingPayment ? 'Processing...' : 'Pay ₹${_finalTotal.toInt()}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // CELEBRATORY ORDER SUCCESS SCREEN
  // ==========================================
  Widget _buildSuccessCelebration() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 540),
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
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 44),
                ),
                const SizedBox(height: 20),
                Text('Enrollment Confirmed! 🎉', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                const SizedBox(height: 8),
                Text(
                  'Order #$_createdOrderId has been successfully processed. All mock tests and study materials are now permanently unlocked in your profile.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF64748B), height: 1.5),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    final targetId = _activeItem?.id ?? 'ts_neet_all_india_2026';
                    context.go('/product/$targetId');
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text('Start Learning Now', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    minimumSize: const Size(double.infinity, 44),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => context.go('/test-series'),
                  child: const Text('Explore More Test Series', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
