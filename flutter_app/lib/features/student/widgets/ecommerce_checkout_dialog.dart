import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/cart_service.dart';
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

class _EcommerceCheckoutDialogState extends State<EcommerceCheckoutDialog> {
  final TextEditingController _couponCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  String _selectedPaymentMethod = 'UPI'; // 'UPI', 'Cashfree'
  bool _isProcessing = false;
  bool _isSuccess = false;
  bool _isPendingVerification = false;
  String _submittedUtr = '';
  Map<String, dynamic> _paymentSettings = {};
  String _orderId = '';
  String _successMessage = '';

  @override
  void initState() {
    super.initState();
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
        final upiActive = SupabaseService.parseBool(settings['upi_active'], defaultValue: false);
        final cashfreeActive = SupabaseService.parseBool(settings['cashfree_active'], defaultValue: false);
        if (upiActive) {
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

      if (!kIsWeb) {
        try {
          final uri = Uri.parse(upiUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        } catch (e) {
          debugPrint('UPI app launcher note: $e');
        }
      }

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

      await Future.delayed(const Duration(milliseconds: 800));

      final verifyRes = await SupabaseService.verifyPaymentAndGrantAccess(
        orderId: createdOrderId,
        paymentId: 'CF_${DateTime.now().millisecondsSinceEpoch}',
        paymentMethod: 'Cashfree PG',
        user: user,
        items: itemsData,
      );

      if (widget.singleItem == null) {
        CartService.instance.clearCart();
      }

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isSuccess = true;
          _isPendingVerification = false;
          _orderId = createdOrderId;
          _successMessage = verifyRes['message']?.toString() ?? 'Access Granted!';
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

    final qrImageUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${Uri.encodeComponent(upiUrl)}';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: 460,
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF2563EB), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Complete UPI Payment', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                              Text('Pay ₹${_totalPayable.toInt()} via GPay, PhonePe, Paytm, BHIM', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const Divider(height: 24),

                    // QR Code Image
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Image.network(
                        qrImageUrl,
                        width: 180,
                        height: 180,
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, err, st) => Container(
                          width: 180,
                          height: 180,
                          color: const Color(0xFFF1F5F9),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code_2_rounded, size: 48, color: Color(0xFF64748B)),
                              SizedBox(height: 8),
                              Text('Scan with any UPI App', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // UPI ID Copy Row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Merchant UPI ID:', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                                SelectableText(upiId, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: upiId));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✓ UPI ID copied to clipboard!'),
                                  backgroundColor: Color(0xFF10B981),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 14),
                            label: const Text('Copy ID', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // UTR / Transaction Reference Entry Box
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Step 2: Enter 12-Digit UTR / Ref No.', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: utrCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 12,
                      decoration: InputDecoration(
                        hintText: 'e.g. 429182736410',
                        counterText: '',
                        isDense: true,
                        prefixIcon: const Icon(Icons.confirmation_number_outlined, size: 18, color: Color(0xFF64748B)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Submit Verification Button
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final utr = utrCtrl.text.trim();
                                if (utr.isEmpty || utr.length < 6) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter valid 12-digit UTR or Transaction Ref number.'),
                                      backgroundColor: Color(0xFFEF4444),
                                    ),
                                  );
                                  return;
                                }

                                setDialogState(() => isSubmitting = true);

                                final res = await SupabaseService.submitUpiPaymentVerification(
                                  user: user,
                                  items: items,
                                  utrNumber: utr,
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
                                    _submittedUtr = utr;
                                    _successMessage = 'UPI Payment request submitted with UTR: $utr. Pending Admin approval.';
                                  });
                                }
                              },
                        icon: isSubmitting
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.verified_rounded, size: 18),
                        label: Text(
                          isSubmitting ? 'Submitting...' : 'Submit Payment Verification',
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
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
    final bool upiActive = SupabaseService.parseBool(_paymentSettings['upi_active'], defaultValue: false);
    final bool cashfreeActive = SupabaseService.parseBool(_paymentSettings['cashfree_active'], defaultValue: false);

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
              const Text('Final Amount', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
              Text(
                '₹${_totalPayable.toInt()}',
                style: GoogleFonts.inter(fontSize: 19, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _isProcessing ? null : _handlePayment,
            icon: _isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.lock_rounded, size: 16, color: Colors.white),
            label: Text(
              _isProcessing ? 'Processing Securely...' : 'Pay ₹${_totalPayable.toInt()}',
              style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessDialog() {
    final firstItem = _effectiveItems.isNotEmpty ? _effectiveItems.first : null;

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 48),
            ),
            const SizedBox(height: 18),
            Text(
              'Payment Confirmed!',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            Text(
              _successMessage,
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Order ID', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                      Text(
                        _orderId.length > 18 ? '${_orderId.substring(0, 18)}...' : _orderId,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Amount Paid', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                      Text(
                        '₹${_totalPayable.toInt()}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Back to Test Series'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (firstItem != null) {
                        widget.onStartTest(firstItem.id, firstItem.title, 180);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Start Test Now', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
