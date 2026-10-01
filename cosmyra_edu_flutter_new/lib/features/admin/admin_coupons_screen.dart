import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/supabase_service.dart';

class AdminCouponManagerScreen extends StatefulWidget {
  const AdminCouponManagerScreen({Key? key}) : super(key: key);

  @override
  State<AdminCouponManagerScreen> createState() => _AdminCouponManagerScreenState();
}

class _AdminCouponManagerScreenState extends State<AdminCouponManagerScreen> {
  List<Map<String, dynamic>> _coupons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    setState(() => _isLoading = true);
    final list = await SupabaseService.fetchAllCoupons();
    if (mounted) {
      setState(() {
        _coupons = list;
        _isLoading = false;
      });
    }
  }

  void _openCouponDialog([Map<String, dynamic>? existing]) {
    final bool isEdit = existing != null;
    final codeCtrl = TextEditingController(text: existing?['code']?.toString() ?? '');
    final descCtrl = TextEditingController(text: existing?['description']?.toString() ?? '');
    final valCtrl = TextEditingController(text: (existing?['discount_value'] ?? 20).toString());
    final minCtrl = TextEditingController(text: (existing?['min_purchase'] ?? 299).toString());
    final maxCtrl = TextEditingController(text: (existing?['max_discount'] ?? 500).toString());
    String selectedType = existing?['discount_type']?.toString() ?? 'percentage';
    bool isActive = existing?['is_active'] ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 520,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEdit ? 'Edit Promo Coupon' : 'Create New Coupon',
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                      ),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Coupon Code
                  Text('Coupon Code', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'e.g. NEET2026, SUMMER50',
                      prefixIcon: const Icon(Icons.confirmation_number_outlined, size: 20, color: Color(0xFF4F46E5)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Discount Type & Value
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Discount Type', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedType,
                                  isExpanded: true,
                                  items: const [
                                    DropdownMenuItem(value: 'percentage', child: Text('Percentage (%)', style: TextStyle(fontSize: 13))),
                                    DropdownMenuItem(value: 'fixed', child: Text('Flat Amount (₹)', style: TextStyle(fontSize: 13))),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setDialogState(() => selectedType = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedType == 'percentage' ? 'Discount Percentage (%)' : 'Discount Amount (₹)',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF475569)),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: valCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: selectedType == 'percentage' ? '20' : '100',
                                suffixText: selectedType == 'percentage' ? '%' : '₹',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Min Purchase & Max Discount
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Min Cart Value (₹)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                            const SizedBox(height: 6),
                            TextField(
                              controller: minCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                prefixText: '₹ ',
                                hintText: '299',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Max Discount Cap (₹)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                            const SizedBox(height: 6),
                            TextField(
                              controller: maxCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                prefixText: '₹ ',
                                hintText: '500',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Description
                  Text('Description / Note', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. Special 20% discount on All India Mock Test Series',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Active Switch
                  Row(
                    children: [
                      Switch(
                        value: isActive,
                        activeColor: const Color(0xFF10B981),
                        onChanged: (val) => setDialogState(() => isActive = val),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isActive ? 'Active (Ready for checkout)' : 'Inactive / Paused',
                        style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? const Color(0xFF10B981) : const Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          final cleanCode = codeCtrl.text.trim().toUpperCase();
                          if (cleanCode.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a coupon code.'), backgroundColor: Color(0xFFEF4444)),
                            );
                            return;
                          }

                          final coupon = {
                            'code': cleanCode,
                            'discount_type': selectedType,
                            'discount_value': double.tryParse(valCtrl.text.trim()) ?? 20.0,
                            'min_purchase': double.tryParse(minCtrl.text.trim()) ?? 0.0,
                            'max_discount': double.tryParse(maxCtrl.text.trim()) ?? 500.0,
                            'description': descCtrl.text.trim(),
                            'is_active': isActive,
                          };

                          await SupabaseService.saveCoupon(coupon);
                          if (ctx.mounted) Navigator.pop(ctx);
                          _loadCoupons();

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('✓ Coupon "$cleanCode" saved successfully!'), backgroundColor: const Color(0xFF10B981)),
                            );
                          }
                        },
                        child: Text(isEdit ? 'Save Changes' : 'Create Coupon'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(String code) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Coupon'),
        content: Text('Are you sure you want to permanently delete coupon "$code"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await SupabaseService.deleteCoupon(code);
              _loadCoupons();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Coupon "$code" deleted.'), backgroundColor: const Color(0xFFEF4444)),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => context.canPop() ? context.pop() : context.go('/admin'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Coupon Management System', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
            Text('Manage discount codes and promotional offers for checkout', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => _openCouponDialog(),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Create Coupon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFC7D2FE)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.discount_outlined, color: Color(0xFF4F46E5), size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Coupons created here can be applied by students on the Checkout and Cart pages. Minimum purchase limits and maximum discount caps are enforced in real time.',
                                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF3730A3)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Coupons List
                      ..._coupons.map((c) {
                        final code = (c['code'] ?? '').toString().toUpperCase();
                        final type = (c['discount_type'] ?? 'percentage').toString();
                        final val = c['discount_value'] ?? 0;
                        final minPurchase = c['min_purchase'] ?? 0;
                        final maxDisc = c['max_discount'] ?? 0;
                        final desc = (c['description'] ?? '').toString();
                        final bool isActive = c['is_active'] != false;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Coupon Code Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3E8FF),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFD8B4FE)),
                                ),
                                child: Text(
                                  code,
                                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w900, color: const Color(0xFF7C3AED), letterSpacing: 0.5),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          type == 'percentage' ? '$val% OFF' : 'Flat ₹$val OFF',
                                          style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('• Min order ₹$minPurchase • Max disc ₹$maxDisc', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                                      ],
                                    ),
                                    if (desc.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(desc, style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF94A3B8))),
                                    ],
                                  ],
                                ),
                              ),

                              // Active Toggle
                              Row(
                                children: [
                                  Text(
                                    isActive ? 'Active' : 'Disabled',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isActive ? const Color(0xFF10B981) : const Color(0xFF94A3B8)),
                                  ),
                                  Switch(
                                    value: isActive,
                                    activeColor: const Color(0xFF10B981),
                                    onChanged: (val) async {
                                      await SupabaseService.toggleCouponStatus(code, val);
                                      _loadCoupons();
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),

                              // Edit & Delete Buttons
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF4F46E5)),
                                tooltip: 'Edit',
                                onPressed: () => _openCouponDialog(c),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFEF4444)),
                                tooltip: 'Delete',
                                onPressed: () => _confirmDelete(code),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
