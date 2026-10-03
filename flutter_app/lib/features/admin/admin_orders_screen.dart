import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/supabase_service.dart';
import '../../models/models.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({Key? key}) : super(key: key);

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];
  String _searchQuery = '';
  String _statusFilter = 'All'; // All, Pending Verification, Completed, Cancelled
  String _sortBy = 'date_desc'; // date_desc, date_asc, amount_desc, amount_asc, name_asc, status_pending

  // Multi-selection state
  final Set<String> _selectedOrderIds = {};
  bool _isBatchProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final data = await SupabaseService.fetchAdminOrders();
    if (mounted) {
      setState(() {
        _orders = data;
        _isLoading = false;
        // Retain selection for IDs that still exist
        final existingIds = data.map((o) => _getDisplayOrderId(o)).toSet();
        _selectedOrderIds.removeWhere((id) => !existingIds.contains(id));
      });
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    final list = _orders.where((o) {
      final q = _searchQuery.trim().toLowerCase();
      final displayId = SupabaseService.extractDisplayOrderId(o).toLowerCase();
      final rawId = (o['id'] ?? '').toString().toLowerCase();
      final name = (o['student_name'] ?? o['user_name'] ?? '').toString().toLowerCase();
      final email = (o['student_email'] ?? o['user_email'] ?? '').toString().toLowerCase();
      final phone = (o['student_phone'] ?? o['user_phone'] ?? '').toString().toLowerCase();
      final product = (o['product_name'] ?? '').toString().toLowerCase();
      final ref = SupabaseService.extractUtrNumber(o).toLowerCase();

      final matchesQuery = q.isEmpty ||
          displayId.contains(q) ||
          rawId.contains(q) ||
          name.contains(q) ||
          email.contains(q) ||
          phone.contains(q) ||
          product.contains(q) ||
          ref.contains(q);

      final status = (o['payment_status'] ?? o['status'] ?? 'pending_verification').toString().toLowerCase();
      final matchesStatus = _statusFilter == 'All' ||
          (_statusFilter == 'Pending Verification'
              ? (status == 'pending_verification' || status == 'pending')
              : (_statusFilter == 'Completed'
                  ? (status == 'completed' || status == 'paid')
                  : status == _statusFilter.toLowerCase()));

      return matchesQuery && matchesStatus;
    }).toList();

    // Sorting
    list.sort((a, b) {
      switch (_sortBy) {
        case 'date_asc':
          return (a['created_at'] ?? '').toString().compareTo((b['created_at'] ?? '').toString());
        case 'amount_desc':
          final amtA = (a['total_amount'] ?? a['amount'] as num?)?.toDouble() ?? 0.0;
          final amtB = (b['total_amount'] ?? b['amount'] as num?)?.toDouble() ?? 0.0;
          return amtB.compareTo(amtA);
        case 'amount_asc':
          final amtA = (a['total_amount'] ?? a['amount'] as num?)?.toDouble() ?? 0.0;
          final amtB = (b['total_amount'] ?? b['amount'] as num?)?.toDouble() ?? 0.0;
          return amtA.compareTo(amtB);
        case 'name_asc':
          final nameA = (a['student_name'] ?? a['user_name'] ?? '').toString().toLowerCase();
          final nameB = (b['student_name'] ?? b['user_name'] ?? '').toString().toLowerCase();
          return nameA.compareTo(nameB);
        case 'status_pending':
          final stA = (a['payment_status'] ?? a['status'] ?? '').toString().toLowerCase();
          final stB = (b['payment_status'] ?? b['status'] ?? '').toString().toLowerCase();
          final isPendA = (stA == 'pending_verification' || stA == 'pending') ? 0 : 1;
          final isPendB = (stB == 'pending_verification' || stB == 'pending') ? 0 : 1;
          return isPendA.compareTo(isPendB);
        case 'date_desc':
        default:
          return (b['created_at'] ?? '').toString().compareTo((a['created_at'] ?? '').toString());
      }
    });

    return list;
  }

  int get _totalCount => _orders.length;
  int get _pendingCount => _orders.where((o) {
        final st = (o['payment_status'] ?? o['status'] ?? '').toString().toLowerCase();
        return st == 'pending_verification' || st == 'pending';
      }).length;
  int get _completedCount => _orders.where((o) {
        final st = (o['payment_status'] ?? o['status'] ?? '').toString().toLowerCase();
        return st == 'completed' || st == 'paid';
      }).length;

  double get _totalRevenue {
    double sum = 0.0;
    for (var o in _orders) {
      final st = (o['payment_status'] ?? o['status'] ?? '').toString().toLowerCase();
      if (st == 'completed' || st == 'paid') {
        final amt = (o['total_amount'] ?? o['amount'] as num?)?.toDouble() ?? 0.0;
        sum += amt;
      }
    }
    return sum;
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Copied $label to clipboard!'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _getDisplayOrderId(Map<String, dynamic> o) {
    return SupabaseService.extractDisplayOrderId(o);
  }

  // Checkbox selection helpers
  bool get _isAllFilteredSelected {
    final filtered = _filteredOrders;
    if (filtered.isEmpty) return false;
    return filtered.every((o) => _selectedOrderIds.contains(_getDisplayOrderId(o)));
  }

  void _toggleSelectAll(bool? select) {
    setState(() {
      final filtered = _filteredOrders;
      if (select == true) {
        for (var o in filtered) {
          _selectedOrderIds.add(_getDisplayOrderId(o));
        }
      } else {
        for (var o in filtered) {
          _selectedOrderIds.remove(_getDisplayOrderId(o));
        }
      }
    });
  }

  void _toggleSelectOrder(String orderId) {
    setState(() {
      if (_selectedOrderIds.contains(orderId)) {
        _selectedOrderIds.remove(orderId);
      } else {
        _selectedOrderIds.add(orderId);
      }
    });
  }

  // --- CRUD ACTIONS ---

  Future<void> _approveOrder(Map<String, dynamic> o) async {
    final rawId = _getDisplayOrderId(o);
    final uid = (o['user_id'] ?? o['student_id'] ?? '').toString();
    final user = UserProfileModel(
      id: uid.isNotEmpty ? uid : 'usr_${DateTime.now().millisecondsSinceEpoch}',
      email: (o['student_email'] ?? o['user_email'] ?? 'student@cosmyra.in').toString(),
      fullName: (o['student_name'] ?? o['user_name'] ?? 'Student Aspirant').toString(),
    );

    List<Map<String, dynamic>> items = [];
    if (o['items'] is List && (o['items'] as List).isNotEmpty) {
      for (var it in o['items']) {
        if (it is Map) {
          items.add({
            'id': (it['id'] ?? it['product_id'] ?? o['product_id'] ?? 'ts_all_access').toString(),
            'title': (it['title'] ?? it['name'] ?? it['product_name'] ?? o['product_name'] ?? 'NEET / JEE Test Series').toString(),
            'product_type': (it['product_type'] ?? o['product_type'] ?? 'test_series').toString(),
          });
        }
      }
    }
    if (items.isEmpty) {
      items = [
        {
          'id': (o['product_id'] ?? 'ts_all_access').toString(),
          'title': (o['product_name'] ?? 'NEET / JEE Test Series').toString(),
          'product_type': (o['product_type'] ?? 'test_series').toString(),
        }
      ];
    }

    await SupabaseService.verifyPaymentAndGrantAccess(
      orderId: rawId,
      paymentId: (o['payment_id'] ?? o['payment_reference'] ?? 'VERIFIED_BY_ADMIN').toString(),
      paymentMethod: (o['payment_method'] ?? 'Online Payment').toString(),
      user: user,
      items: items,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Order #$rawId Approved & Access Granted to ${user.fullName}!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadOrders();
    }
  }

  Future<void> _deleteOrder(Map<String, dynamic> o) async {
    final rawId = _getDisplayOrderId(o);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
            SizedBox(width: 8),
            Text('Confirm Delete Order'),
          ],
        ),
        content: Text('Are you sure you want to delete Order #$rawId? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Order'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await SupabaseService.deleteAdminOrder(rawId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Order #$rawId deleted successfully'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadOrders();
      }
    }
  }

  // BATCH ACTIONS
  Future<void> _bulkApproveSelected() async {
    if (_selectedOrderIds.isEmpty) return;
    setState(() => _isBatchProcessing = true);
    int count = 0;
    final selectedTargets = _orders.where((o) => _selectedOrderIds.contains(_getDisplayOrderId(o))).toList();

    for (var o in selectedTargets) {
      final st = (o['payment_status'] ?? o['status'] ?? '').toString().toLowerCase();
      if (st == 'pending_verification' || st == 'pending') {
        await _approveOrder(o);
        count++;
      }
    }

    setState(() {
      _isBatchProcessing = false;
      _selectedOrderIds.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Successfully bulk approved $count pending orders!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadOrders();
    }
  }

  Future<void> _bulkDeleteSelected() async {
    if (_selectedOrderIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
            SizedBox(width: 8),
            Text('Bulk Delete Confirmation'),
          ],
        ),
        content: Text('Are you sure you want to permanently delete ${_selectedOrderIds.length} selected orders?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete ${_selectedOrderIds.length} Orders'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isBatchProcessing = true);
    final targetIds = _selectedOrderIds.toList();
    for (var id in targetIds) {
      await SupabaseService.deleteAdminOrder(id);
    }

    setState(() {
      _isBatchProcessing = false;
      _selectedOrderIds.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Deleted ${targetIds.length} orders successfully!'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadOrders();
    }
  }

  void _exportSelectedCsv() {
    if (_selectedOrderIds.isEmpty) return;
    final selectedTargets = _orders.where((o) => _selectedOrderIds.contains(_getDisplayOrderId(o))).toList();
    final StringBuffer csv = StringBuffer();
    csv.writeln('Order ID,Student Name,Student Email,Student Phone,Product,Amount,Payment Method,UTR,Status,Date');

    for (var o in selectedTargets) {
      final id = _getDisplayOrderId(o);
      final name = (o['student_name'] ?? o['user_name'] ?? '').toString().replaceAll(',', ' ');
      final email = (o['student_email'] ?? o['user_email'] ?? '').toString();
      final phone = (o['student_phone'] ?? o['user_phone'] ?? '').toString();
      final product = (o['product_name'] ?? '').toString().replaceAll(',', ' ');
      final amt = (o['total_amount'] ?? o['amount'] as num?)?.toDouble() ?? 0.0;
      final method = (o['payment_method'] ?? '').toString().replaceAll(',', ' ');
      final utr = SupabaseService.extractUtrNumber(o).replaceAll(',', ' ');
      final status = (o['payment_status'] ?? o['status'] ?? '').toString();
      final date = (o['created_at'] ?? '').toString();

      csv.writeln('$id,$name,$email,$phone,"$product",$amt,"$method","$utr",$status,$date');
    }

    _copyToClipboard(csv.toString(), 'CSV Data of ${selectedTargets.length} selected orders');
  }

  // --- MODALS ---

  Future<void> _showCreateManualOrderDialog() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final productCtrl = TextEditingController(text: 'NEET & JEE Complete Test Series 2026');
    final amountCtrl = TextEditingController(text: '299');
    final utrCtrl = TextEditingController();
    String paymentMethod = 'UPI';
    String status = 'pending_verification';
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dCtx, setDS) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 540,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.add_shopping_cart_rounded, color: Color(0xFF10B981), size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text('Create Manual Order', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                        ],
                      ),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, size: 20)),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildInputLabel('Student Name *'),
                  TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'e.g. Rahul Sharma', isDense: true, border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  _buildInputLabel('Student Email *'),
                  TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'e.g. rahul@example.com', isDense: true, border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  _buildInputLabel('Student Phone'),
                  TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: 'e.g. 9876543210', isDense: true, border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  _buildInputLabel('Product Package Title *'),
                  TextField(controller: productCtrl, decoration: const InputDecoration(hintText: 'e.g. NEET Test Series', isDense: true, border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputLabel('Amount (₹) *'),
                            TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '299', isDense: true, border: OutlineInputBorder())),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputLabel('Payment Method'),
                            DropdownButtonFormField<String>(
                              value: paymentMethod,
                              isDense: true,
                              decoration: const InputDecoration(border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: 'UPI', child: Text('UPI / GPay / Paytm')),
                                DropdownMenuItem(value: 'Credit Card', child: Text('Credit / Debit Card')),
                                DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer (NEFT)')),
                                DropdownMenuItem(value: 'Cash / Manual', child: Text('Cash / Manual Admin')),
                              ],
                              onChanged: (v) => setDS(() => paymentMethod = v ?? 'UPI'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInputLabel('UTR / Reference Number'),
                  TextField(controller: utrCtrl, decoration: const InputDecoration(hintText: 'e.g. UTR12849102941', isDense: true, border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  _buildInputLabel('Order Status'),
                  DropdownButtonFormField<String>(
                    value: status,
                    isDense: true,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'pending_verification', child: Text('Pending Admin Verification')),
                      DropdownMenuItem(value: 'completed', child: Text('Completed (Grant Access Instant)')),
                    ],
                    onChanged: (v) => setDS(() => status = v ?? 'pending_verification'),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill student name and email.')));
                                return;
                              }
                              setDS(() => isSaving = true);
                              await SupabaseService.createManualAdminOrder(
                                studentName: nameCtrl.text.trim(),
                                studentEmail: emailCtrl.text.trim(),
                                studentPhone: phoneCtrl.text.trim(),
                                productName: productCtrl.text.trim(),
                                amount: double.tryParse(amountCtrl.text.trim()) ?? 299.0,
                                paymentMethod: paymentMethod,
                                status: status,
                                utrOrNotes: utrCtrl.text.trim(),
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              _loadOrders();
                            },
                      icon: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check_circle_rounded, size: 18),
                      label: Text(isSaving ? 'Creating...' : 'Create Order'),
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

  Future<void> _showEditOrderDialog(Map<String, dynamic> o) async {
    final rawId = _getDisplayOrderId(o);
    final nameCtrl = TextEditingController(text: (o['student_name'] ?? o['user_name'] ?? '').toString());
    final emailCtrl = TextEditingController(text: (o['student_email'] ?? o['user_email'] ?? '').toString());
    final phoneCtrl = TextEditingController(text: (o['student_phone'] ?? o['user_phone'] ?? '').toString());
    final amountCtrl = TextEditingController(text: ((o['total_amount'] ?? o['amount'] as num?)?.toDouble() ?? 299.0).toStringAsFixed(0));
    final utrCtrl = TextEditingController(text: SupabaseService.extractUtrNumber(o));
    final notesCtrl = TextEditingController(text: _sanitizeNotes((o['notes'] ?? '').toString()));

    String status = (o['payment_status'] ?? o['status'] ?? 'pending_verification').toString().toLowerCase();
    if (status == 'paid') status = 'completed';
    if (status != 'pending_verification' && status != 'pending' && status != 'completed' && status != 'cancelled') {
      status = 'pending_verification';
    }

    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dCtx, setDS) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 540,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.edit_rounded, color: Color(0xFF2563EB), size: 20),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Edit Order Details', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                              Text('Order #$rawId', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            ],
                          ),
                        ],
                      ),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, size: 20)),
                    ],
                  ),
                  const Divider(height: 24),

                  _buildInputLabel('Student Full Name'),
                  TextField(controller: nameCtrl, decoration: const InputDecoration(isDense: true, border: OutlineInputBorder())),
                  const SizedBox(height: 12),

                  _buildInputLabel('Student Email Address'),
                  TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(isDense: true, border: OutlineInputBorder())),
                  const SizedBox(height: 12),

                  _buildInputLabel('Student Phone Number'),
                  TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(isDense: true, border: OutlineInputBorder())),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputLabel('Total Amount (₹)'),
                            TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(isDense: true, border: OutlineInputBorder())),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputLabel('Order Status'),
                            DropdownButtonFormField<String>(
                              value: status,
                              isDense: true,
                              decoration: const InputDecoration(border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: 'pending_verification', child: Text('Pending Verification')),
                                DropdownMenuItem(value: 'completed', child: Text('Verified & Completed')),
                                DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                              ],
                              onChanged: (v) => setDS(() => status = v ?? 'pending_verification'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _buildInputLabel('UTR / Ref Number'),
                  TextField(controller: utrCtrl, decoration: const InputDecoration(isDense: true, border: OutlineInputBorder())),
                  const SizedBox(height: 12),

                  _buildInputLabel('Admin / Custom Notes'),
                  TextField(controller: notesCtrl, maxLines: 2, decoration: const InputDecoration(hintText: 'Optional internal notes...', isDense: true, border: OutlineInputBorder())),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                      onPressed: isSaving
                          ? null
                          : () async {
                              setDS(() => isSaving = true);
                              final updatedMap = Map<String, dynamic>.from(o);
                              updatedMap['student_name'] = nameCtrl.text.trim();
                              updatedMap['user_name'] = nameCtrl.text.trim();
                              updatedMap['student_email'] = emailCtrl.text.trim();
                              updatedMap['user_email'] = emailCtrl.text.trim();
                              updatedMap['student_phone'] = phoneCtrl.text.trim();
                              updatedMap['user_phone'] = phoneCtrl.text.trim();
                              updatedMap['total_amount'] = double.tryParse(amountCtrl.text.trim()) ?? 299.0;
                              updatedMap['status'] = status;
                              updatedMap['payment_status'] = status;
                              updatedMap['notes'] = notesCtrl.text.trim();
                              if (utrCtrl.text.trim().isNotEmpty) {
                                updatedMap['payment_utr'] = utrCtrl.text.trim();
                                updatedMap['utr_number'] = utrCtrl.text.trim();
                              }

                              await SupabaseService.updateAdminOrderDetails(updatedMap);
                              if (ctx.mounted) Navigator.pop(ctx);
                              _loadOrders();
                            },
                      icon: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save_rounded, size: 18),
                      label: Text(isSaving ? 'Saving...' : 'Save Order Changes'),
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

  Future<void> _showMoreInfoModal(Map<String, dynamic> o) async {
    final rawId = _getDisplayOrderId(o);
    final validUuid = (o['id'] ?? '').toString();
    final name = (o['student_name'] ?? o['user_name'] ?? 'Student Aspirant').toString();
    final email = (o['student_email'] ?? o['user_email'] ?? 'student@cosmyra.in').toString();
    final phone = (o['student_phone'] ?? o['user_phone'] ?? 'N/A').toString();
    final product = (o['product_name'] ?? 'NEET / JEE Test Package').toString();
    final amount = (o['total_amount'] ?? o['amount'] as num?)?.toDouble() ?? 299.0;
    final subtotal = (o['subtotal_amount'] as num?)?.toDouble() ?? amount;
    final discount = (o['discount_amount'] as num?)?.toDouble() ?? 0.0;
    final coupon = (o['coupon_code'] ?? '').toString();
    final method = (o['payment_method'] ?? 'Online Payment').toString();
    final ref = SupabaseService.extractUtrNumber(o);
    final screenshotUrl = SupabaseService.extractPaymentScreenshotUrl(o);
    final status = (o['payment_status'] ?? o['status'] ?? 'pending_verification').toString().toLowerCase();
    final notes = (o['notes'] ?? '').toString();
    final sanitizedNotes = _sanitizeNotes(notes);
    final createdAt = (o['created_at'] ?? '').toString();

    final isPending = status == 'pending_verification' || status == 'pending';

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 580,
          padding: const EdgeInsets.all(26),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF2563EB), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Order Details & Verification', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                            Text('Order #$rawId', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF2563EB))),
                          ],
                        ),
                      ],
                    ),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, size: 20)),
                  ],
                ),
                const Divider(height: 24),

                // Status banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isPending ? const Color(0xFFFFFBEB) : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isPending ? const Color(0xFFFCD34D) : const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    children: [
                      Icon(isPending ? Icons.pending_actions_rounded : Icons.check_circle_rounded, color: isPending ? const Color(0xFFD97706) : const Color(0xFF059669), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPending ? 'STATUS: PENDING ADMIN VERIFICATION' : 'STATUS: VERIFIED & COMPLETED',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: isPending ? const Color(0xFF92400E) : const Color(0xFF065F46)),
                            ),
                            Text(
                              isPending ? 'User does NOT have course access yet. Click Approve to grant access.' : 'Student has active access to test series package.',
                              style: TextStyle(fontSize: 11.5, color: isPending ? const Color(0xFF78350F) : const Color(0xFF047857)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Grid Info Sections
                _buildModalSectionTitle('Student Information'),
                _buildInfoRow('Full Name', name),
                _buildInfoRow('Email Address', email),
                _buildInfoRow('Phone Number', phone),

                const SizedBox(height: 14),
                _buildModalSectionTitle('Payment & Transaction'),
                _buildInfoRow('Payment Method', method),
                _buildInfoRow('UTR / Ref Number', ref, copyable: true),
                _buildInfoRow('Payment Screenshot', screenshotUrl != null ? 'Uploaded to Cloudflare S3' : 'None'),
                _buildInfoRow('Package Product', product),
                if (createdAt.isNotEmpty) _buildInfoRow('Order Date', createdAt),
                if (validUuid.isNotEmpty) _buildInfoRow('Record ID', validUuid, copyable: true),

                if (screenshotUrl != null && screenshotUrl.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildModalSectionTitle('Payment Receipt Screenshot'),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => _showScreenshotLightboxDialog(context, screenshotUrl),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          Image.network(
                            screenshotUrl,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, st) => Container(
                              padding: const EdgeInsets.all(16),
                              color: const Color(0xFFF1F5F9),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image_rounded, color: Color(0xFF94A3B8)),
                                  SizedBox(width: 8),
                                  Text('Failed to load image preview'),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            color: const Color(0xFFF8FAFC),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.zoom_in_rounded, size: 16, color: Color(0xFF2563EB)),
                                SizedBox(width: 6),
                                Text('Click to View Full-Size Screenshot', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 14),
                _buildModalSectionTitle('Financial Breakdown'),
                _buildInfoRow('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
                _buildInfoRow('Discount', '₹${discount.toStringAsFixed(2)} ${coupon.isNotEmpty ? "($coupon)" : ""}'),
                _buildInfoRow('Total Paid / Due', '₹${amount.toStringAsFixed(2)}', bold: true),

                if (sanitizedNotes.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildModalSectionTitle('Notes / Remarks'),
                  Text(sanitizedNotes, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                ],

                const SizedBox(height: 22),
                Row(
                  children: [
                    if (isPending)
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await _approveOrder(o);
                          },
                          icon: const Icon(Icons.verified_rounded, size: 18),
                          label: const Text('Approve & Grant Access', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    if (isPending) const SizedBox(width: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        side: const BorderSide(color: Color(0xFF93C5FD)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showEditOrderDialog(o);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit Order', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _deleteOrder(o);
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Delete', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModalSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool bold = false, bool copyable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
          Row(
            children: [
              SelectableText(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                  color: bold ? const Color(0xFF0F172A) : const Color(0xFF334155),
                ),
              ),
              if (copyable && value != 'N/A' && value.isNotEmpty) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => _copyToClipboard(value, label),
                  child: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF2563EB)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredOrders;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text('Customer Orders & Verification Manager', style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
            onPressed: _loadOrders,
            tooltip: 'Refresh Orders',
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _showCreateManualOrderDialog,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Create Manual Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Analytics Cards Row
                  LayoutBuilder(builder: (ctx, constraints) {
                    final isMobile = constraints.maxWidth < 700;
                    return Flex(
                      direction: isMobile ? Axis.vertical : Axis.horizontal,
                      children: [
                        _buildKpiCard('Total Orders', '$_totalCount', Icons.shopping_bag_outlined, const Color(0xFF2563EB), isMobile),
                        SizedBox(width: isMobile ? 0 : 16, height: isMobile ? 12 : 0),
                        _buildKpiCard('Pending Verification', '$_pendingCount', Icons.pending_actions_rounded, const Color(0xFFD97706), isMobile, alert: _pendingCount > 0),
                        SizedBox(width: isMobile ? 0 : 16, height: isMobile ? 12 : 0),
                        _buildKpiCard('Verified & Completed', '$_completedCount', Icons.check_circle_outline_rounded, const Color(0xFF059669), isMobile),
                        SizedBox(width: isMobile ? 0 : 16, height: isMobile ? 12 : 0),
                        _buildKpiCard('Total Revenue', '₹${_totalRevenue.toStringAsFixed(0)}', Icons.payments_outlined, const Color(0xFF7C3AED), isMobile),
                      ],
                    );
                  }),
                  const SizedBox(height: 24),

                  // BATCH SELECTION BANNER
                  if (_selectedOrderIds.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(20)),
                            child: Text('${_selectedOrderIds.length} Selected', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                    onPressed: _isBatchProcessing ? null : _bulkApproveSelected,
                                    icon: const Icon(Icons.verified_rounded, size: 16),
                                    label: const Text('Bulk Approve Pending', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                    onPressed: _isBatchProcessing
                                        ? null
                                        : () async {
                                            for (var id in _selectedOrderIds) {
                                              await SupabaseService.updateAdminOrderStatus(orderId: id, newStatus: 'completed');
                                            }
                                            setState(() => _selectedOrderIds.clear());
                                            _loadOrders();
                                          },
                                    icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                                    label: const Text('Mark Completed', style: TextStyle(fontSize: 12)),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF2563EB), side: const BorderSide(color: Color(0xFF93C5FD)), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                    onPressed: _exportSelectedCsv,
                                    icon: const Icon(Icons.download_rounded, size: 16),
                                    label: const Text('Export CSV', style: TextStyle(fontSize: 12)),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                    onPressed: _isBatchProcessing ? null : _bulkDeleteSelected,
                                    icon: const Icon(Icons.delete_forever_rounded, size: 16),
                                    label: const Text('Bulk Delete', style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                            onPressed: () => setState(() => _selectedOrderIds.clear()),
                            tooltip: 'Clear Selection',
                          ),
                        ],
                      ),
                    ),

                  // Search, Sort & Filter Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                onChanged: (v) => setState(() => _searchQuery = v),
                                decoration: InputDecoration(
                                  hintText: 'Search by Order ID, Student Name, Email, Phone, UTR...',
                                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Sort By Dropdown
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _sortBy,
                                  icon: const Icon(Icons.sort_rounded, color: Color(0xFF2563EB), size: 20),
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                  onChanged: (v) {
                                    if (v != null) setState(() => _sortBy = v);
                                  },
                                  items: const [
                                    DropdownMenuItem(value: 'date_desc', child: Text('Sort: Date (Newest)')),
                                    DropdownMenuItem(value: 'date_asc', child: Text('Sort: Date (Oldest)')),
                                    DropdownMenuItem(value: 'amount_desc', child: Text('Sort: Amount (High to Low)')),
                                    DropdownMenuItem(value: 'amount_asc', child: Text('Sort: Amount (Low to High)')),
                                    DropdownMenuItem(value: 'name_asc', child: Text('Sort: Student Name (A-Z)')),
                                    DropdownMenuItem(value: 'status_pending', child: Text('Sort: Pending First')),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: ['All', 'Pending Verification', 'Completed', 'Cancelled'].map((status) {
                                  final isSelected = _statusFilter == status;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(status),
                                      selected: isSelected,
                                      selectedColor: const Color(0xFF2563EB),
                                      labelStyle: TextStyle(
                                        color: isSelected ? Colors.white : const Color(0xFF475569),
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 12.5,
                                      ),
                                      onSelected: (val) {
                                        if (val) setState(() => _statusFilter = status);
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            Text('${filtered.length} Orders Showing', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Table View with Multi-Selection & Non-Overlapping Cells
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: filtered.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(48),
                            child: Center(
                              child: Column(
                                children: [
                                  const Icon(Icons.inbox_outlined, size: 48, color: Color(0xFF94A3B8)),
                                  const SizedBox(height: 12),
                                  Text('No orders found matching filter', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                                ],
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              dataRowMinHeight: 64,
                              dataRowMaxHeight: 76,
                              headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
                              columns: [
                                DataColumn(
                                  label: Checkbox(
                                    value: _isAllFilteredSelected,
                                    onChanged: _toggleSelectAll,
                                  ),
                                ),
                                const DataColumn(label: Text('Order ID', style: TextStyle(fontWeight: FontWeight.bold))),
                                const DataColumn(label: Text('Student', style: TextStyle(fontWeight: FontWeight.bold))),
                                const DataColumn(label: Text('Product Package', style: TextStyle(fontWeight: FontWeight.bold))),
                                const DataColumn(label: Text('Payment / UTR', style: TextStyle(fontWeight: FontWeight.bold))),
                                const DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                                const DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                const DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                                const DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: filtered.map((o) {
                                final rawId = _getDisplayOrderId(o);
                                final isSelected = _selectedOrderIds.contains(rawId);
                                final displayId = rawId.length > 18 ? '${rawId.substring(0, 15)}...' : rawId;
                                final name = (o['student_name'] ?? o['user_name'] ?? 'Student').toString();
                                final email = (o['student_email'] ?? o['user_email'] ?? '').toString();
                                final product = (o['product_name'] ?? 'NEET / JEE Package').toString();
                                final method = (o['payment_method'] ?? 'UPI').toString();
                                final ref = SupabaseService.extractUtrNumber(o);
                                final screenshotUrl = SupabaseService.extractPaymentScreenshotUrl(o);
                                final amount = (o['total_amount'] ?? o['amount'] as num?)?.toDouble() ?? 299.0;
                                final status = (o['payment_status'] ?? o['status'] ?? 'pending_verification').toString().toLowerCase();
                                final dateStr = (o['created_at'] ?? '').toString();

                                final isPending = status == 'pending_verification' || status == 'pending';
                                final isCompleted = status == 'completed' || status == 'paid';

                                return DataRow(
                                  selected: isSelected,
                                  onSelectChanged: (val) => _toggleSelectOrder(rawId),
                                  cells: [
                                    DataCell(
                                      Checkbox(
                                        value: isSelected,
                                        onChanged: (val) => _toggleSelectOrder(rawId),
                                      ),
                                    ),
                                    DataCell(
                                      InkWell(
                                        onTap: () => _copyToClipboard(rawId, 'Order ID'),
                                        child: Text(displayId, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF2563EB), fontSize: 13)),
                                      ),
                                    ),
                                    DataCell(
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF0F172A))),
                                          Text(email, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                        ],
                                      ),
                                    ),
                                    DataCell(Text(product, style: const TextStyle(fontSize: 12.5))),
                                    // CLEAN NON-OVERLAPPING PAYMENT / UTR CELL
                                    DataCell(
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(method, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                                            const SizedBox(height: 2),
                                            if (ref != 'N/A (Direct Online)' && ref.isNotEmpty && ref != 'N/A')
                                              InkWell(
                                                onTap: () => _copyToClipboard(ref, 'UTR Ref'),
                                                child: Text('UTR: ${ref.length > 14 ? "${ref.substring(0, 12)}..." : ref}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                                              )
                                            else
                                              Text(ref, style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
                                            if (screenshotUrl != null && screenshotUrl.isNotEmpty) ...[
                                              const SizedBox(height: 3),
                                              InkWell(
                                                onTap: () => _showScreenshotLightboxDialog(context, screenshotUrl),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFEFF6FF),
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(color: const Color(0xFFBFDBFE)),
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.image_rounded, size: 11, color: Color(0xFF2563EB)),
                                                      SizedBox(width: 3),
                                                      Text('Receipt Image', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                    DataCell(Text('₹${amount.toStringAsFixed(0)}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13.5))),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isPending ? const Color(0xFFFEF3C7) : (isCompleted ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2)),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          isPending ? 'PENDING VERIFICATION' : (isCompleted ? 'VERIFIED & PAID' : status.toUpperCase()),
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: isPending ? const Color(0xFFD97706) : (isCompleted ? const Color(0xFF059669) : const Color(0xFFDC2626)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(dateStr.length >= 10 ? dateStr.substring(0, 10) : dateStr, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)))),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isPending)
                                            IconButton(
                                              icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                                              tooltip: 'Approve Payment & Grant Access',
                                              onPressed: () => _approveOrder(o),
                                            ),
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, color: Color(0xFF475569), size: 18),
                                            tooltip: 'Edit Order',
                                            onPressed: () => _showEditOrderDialog(o),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.remove_red_eye_outlined, color: Color(0xFF2563EB), size: 18),
                                            tooltip: 'More Info / Details',
                                            onPressed: () => _showMoreInfoModal(o),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                                            tooltip: 'Delete Order',
                                            onPressed: () => _deleteOrder(o),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color, bool isMobile, {bool alert = false}) {
    final card = Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: alert ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0), width: alert ? 1.5 : 1.0),
        boxShadow: alert ? [BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 3))] : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
            ],
          ),
        ],
      ),
    );

    if (isMobile) return card;
    return Expanded(child: card);
  }

  void _showScreenshotLightboxDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Container(
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (ctx, child, progress) {
                      if (progress == null) return child;
                      return const SizedBox(
                        height: 250,
                        child: Center(child: CircularProgressIndicator(color: Colors.white)),
                      );
                    },
                    errorBuilder: (ctx, err, st) => Container(
                      padding: const EdgeInsets.all(32),
                      color: Colors.white,
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.broken_image, size: 48, color: Colors.red),
                          SizedBox(height: 8),
                          Text('Unable to load payment screenshot.', style: TextStyle(color: Colors.black)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                _copyToClipboard(imageUrl, 'Screenshot URL');
                Navigator.pop(ctx);
              },
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Copy Screenshot URL'),
            ),
          ],
        ),
      ),
    );
  }
}

String _sanitizeNotes(String text) {
  if (text.trim().isEmpty) return '';

  String cleaned = text;

  // 1. Strip base64 image data URIs (including long multiline or non-whitespace sequences)
  cleaned = cleaned.replaceAll(
    RegExp(r'data:image/[^\s\|]*', caseSensitive: false),
    '',
  );
  cleaned = cleaned.replaceAll(
    RegExp(r'data:image/[a-zA-Z0-9\+\/=;,\s\r\n]+', multiLine: true, caseSensitive: false),
    '',
  );

  // 2. Remove http/https image URLs if labeled as Screenshot
  cleaned = cleaned.replaceAll(
    RegExp(r'Screenshot:\s*https?://[^\s\|]+', caseSensitive: false),
    '',
  );

  // 3. Remove common auto-generated system patterns
  cleaned = cleaned
      .replaceAll(RegExp(r'Order ID:\s*(?:ORD|SUB|CART|CSNJ)?[-_]?[A-Za-z0-9]+', caseSensitive: false), '')
      .replaceAll(RegExp(r'Order #\s*[A-Za-z0-9]+', caseSensitive: false), '')
      .replaceAll(RegExp(r'UPI Payment\.?', caseSensitive: false), '')
      .replaceAll(RegExp(r'Cashfree PG\.?', caseSensitive: false), '')
      .replaceAll(RegExp(r'Online Payment\.?', caseSensitive: false), '')
      .replaceAll(RegExp(r'UTR:\s*N/A', caseSensitive: false), '')
      .replaceAll(RegExp(r'UTR:\s*[^\|]+', caseSensitive: false), '')
      .replaceAll(RegExp(r'Screenshot:\s*\[Attached Receipt Image\]', caseSensitive: false), '')
      .replaceAll(RegExp(r'Screenshot:\s*', caseSensitive: false), '')
      .replaceAll(RegExp(r'Awaiting admin approval\.?', caseSensitive: false), '')
      .replaceAll(RegExp(r'Product:\s*[^\|]+', caseSensitive: false), '')
      .replaceAll(RegExp(r'Manual Order created by Admin', caseSensitive: false), '')
      .replaceAll(RegExp(r'Updated by Admin', caseSensitive: false), '')
      .replaceAll(RegExp(r'Active subscription with full access', caseSensitive: false), '');

  // 4. Clean up remaining separators, pipes, extra spaces, dots, dashes
  cleaned = cleaned
      .replaceAll(RegExp(r'\|\s*\|'), '|')
      .replaceAll(RegExp(r'^\s*[\|\.\,\:\;-]+\s*', multiLine: true), '')
      .replaceAll(RegExp(r'\s*[\|\.\,\:\;-]+\s*$', multiLine: true), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  // 5. If no alphanumeric content remains (only punctuation or whitespace), return empty
  if (cleaned.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').isEmpty) {
    return '';
  }

  return cleaned;
}
