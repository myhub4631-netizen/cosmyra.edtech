import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/supabase_service.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({Key? key}) : super(key: key);

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];
  String _searchQuery = '';
  String _statusFilter = 'All'; // All, Completed, Pending, Incomplete, Cancelled

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
      });
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    return _orders.where((o) {
      final q = _searchQuery.trim().toLowerCase();
      final id = (o['id'] ?? '').toString().toLowerCase();
      final name = (o['student_name'] ?? o['user_name'] ?? '').toString().toLowerCase();
      final email = (o['student_email'] ?? o['user_email'] ?? '').toString().toLowerCase();
      final phone = (o['student_phone'] ?? '').toString().toLowerCase();
      final product = (o['product_name'] ?? '').toString().toLowerCase();

      final matchesQuery = q.isEmpty ||
          id.contains(q) ||
          name.contains(q) ||
          email.contains(q) ||
          phone.contains(q) ||
          product.contains(q);

      final status = (o['payment_status'] ?? o['status'] ?? 'completed').toString().toLowerCase();
      final matchesStatus = _statusFilter == 'All' ||
          status == _statusFilter.toLowerCase();

      return matchesQuery && matchesStatus;
    }).toList();
  }

  int get _completedCount => _orders.where((o) => (o['payment_status'] ?? o['status'] ?? '') == 'completed').length;
  int get _pendingCount => _orders.where((o) => (o['payment_status'] ?? o['status'] ?? '') == 'pending').length;
  int get _incompleteCount => _orders.where((o) => (o['payment_status'] ?? o['status'] ?? '') == 'incomplete').length;
  int get _cancelledCount => _orders.where((o) => (o['payment_status'] ?? o['status'] ?? '') == 'cancelled').length;

  double get _totalRevenue {
    double sum = 0.0;
    for (var o in _orders) {
      if ((o['payment_status'] ?? o['status'] ?? '') == 'completed') {
        final amt = (o['amount'] ?? o['total_amount'] as num?)?.toDouble() ?? 0.0;
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

  Future<void> _updateOrderStatus(String orderId, String newStatus, {String? note}) async {
    final success = await SupabaseService.updateAdminOrderStatus(
      orderId: orderId,
      newStatus: newStatus,
      adminNote: note,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Order #$orderId updated to ${newStatus.toUpperCase()}'),
          backgroundColor: newStatus == 'completed'
              ? const Color(0xFF10B981)
              : (newStatus == 'cancelled' ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)),
        ),
      );
      _loadOrders();
    }
  }

  Future<void> _showPaymentReminderDialog(Map<String, dynamic> order) async {
    final orderId = (order['id'] ?? '').toString();
    final reminder = await SupabaseService.sendOrderPaymentReminder(orderId);
    final reminderText = reminder['reminder_text'] ?? '';
    final paymentLink = reminder['payment_link'] ?? '';
    final studentPhone = (order['student_phone'] ?? '').toString().replaceAll(' ', '').replaceAll('-', '');

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 520,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF3C7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_active_rounded, color: Color(0xFFD97706), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Payment Reminder', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                        Text('Order #$orderId • ${order['student_name'] ?? 'Student'}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, size: 20)),
                ],
              ),
              const Divider(height: 24),
              const Text('Generated Reminder Message:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Text(
                  reminderText,
                  style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF1E293B), height: 1.4),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Link: $paymentLink',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _copyToClipboard(paymentLink, 'Checkout Link'),
                    icon: const Icon(Icons.copy_rounded, size: 14),
                    label: const Text('Copy Link', style: TextStyle(fontSize: 11.5)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _copyToClipboard(reminderText, 'Reminder Message'),
                    icon: const Icon(Icons.copy_all_rounded, size: 16),
                    label: const Text('Copy Message'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final cleanNumber = studentPhone.replaceAll('+', '');
                      final encodedMsg = Uri.encodeComponent(reminderText);
                      final waUrl = Uri.parse('https://wa.me/$cleanNumber?text=$encodedMsg');
                      if (await canLaunchUrl(waUrl)) {
                        await launchUrl(waUrl, mode: LaunchMode.externalApplication);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                    label: const Text('Send on WhatsApp'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderDetailsDialog(Map<String, dynamic> order) {
    final rawId = (order['order_number'] ?? order['order_id'] ?? order['id'] ?? '').toString();
    final uid = (order['user_id'] ?? order['student_id'] ?? '').toString();
    final created = order['created_at'] != null ? DateTime.tryParse(order['created_at'].toString()) : null;
    final orderId = SupabaseService.formatOrderId(rawId: rawId, userId: uid, date: created);
    final name = (order['student_name'] ?? order['user_name'] ?? 'Student').toString();
    final email = (order['student_email'] ?? order['user_email'] ?? '-').toString();
    final phone = (order['student_phone'] ?? '-').toString();
    final product = (order['product_name'] ?? 'Test Series').toString();
    final amount = (order['amount'] ?? order['total_amount'] ?? 0).toString();
    final method = (order['payment_method'] ?? 'Online').toString();
    final status = (order['payment_status'] ?? order['status'] ?? 'completed').toString();
    final date = order['created_at'] != null ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(order['created_at'])) : '-';
    final notes = (order['notes'] ?? 'Standard purchase via student portal').toString();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 540,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Order #$orderId', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                  _buildStatusBadge(status),
                ],
              ),
              const Divider(height: 24),
              _buildDetailRow('Student Name', name),
              _buildDetailRow('Email Address', email),
              _buildDetailRow('Mobile Number', phone),
              _buildDetailRow('Product Enrolled', product),
              _buildDetailRow('Amount Paid', '₹$amount'),
              _buildDetailRow('Payment Mode', method),
              _buildDetailRow('Transaction Date', date),
              _buildDetailRow('Admin / Audit Notes', notes),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)))),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label;

    switch (status.toLowerCase()) {
      case 'completed':
        bg = const Color(0xFFDCFCE7);
        text = const Color(0xFF15803D);
        label = 'COMPLETED / PAID';
        break;
      case 'pending':
        bg = const Color(0xFFFEF3C7);
        text = const Color(0xFFB45309);
        label = 'PAYMENT PENDING';
        break;
      case 'incomplete':
        bg = const Color(0xFFFFEDD5);
        text = const Color(0xFFC2410C);
        label = 'INCOMPLETE';
        break;
      case 'cancelled':
      default:
        bg = const Color(0xFFFEE2E2);
        text = const Color(0xFFB91C1C);
        label = 'CANCELLED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: text)),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => context.canPop() ? context.pop() : context.go('/admin'),
        ),
        title: Text(
          'Orders & Purchases Management',
          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF4F46E5)),
            onPressed: _loadOrders,
            tooltip: 'Refresh Orders',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Metric Stats Cards
                  Row(
                    children: [
                      _buildMetricStat('Total Orders', '${_orders.length}', Icons.shopping_bag_outlined, const Color(0xFF4F46E5), const Color(0xFFEEF2FF)),
                      const SizedBox(width: 14),
                      _buildMetricStat('Total Revenue', '₹${_totalRevenue.toInt()}', Icons.currency_rupee_rounded, const Color(0xFF10B981), const Color(0xFFECFDF5)),
                      const SizedBox(width: 14),
                      _buildMetricStat('Completed / Paid', '$_completedCount', Icons.check_circle_outline_rounded, const Color(0xFF16A34A), const Color(0xFFDCFCE7)),
                      const SizedBox(width: 14),
                      _buildMetricStat('Payment Pending', '$_pendingCount', Icons.hourglass_top_rounded, const Color(0xFFD97706), const Color(0xFFFEF3C7)),
                      const SizedBox(width: 14),
                      _buildMetricStat('Incomplete', '$_incompleteCount', Icons.warning_amber_rounded, const Color(0xFFEA580C), const Color(0xFFFFEDD5)),
                      const SizedBox(width: 14),
                      _buildMetricStat('Cancelled', '$_cancelledCount', Icons.cancel_outlined, const Color(0xFFEF4444), const Color(0xFFFEE2E2)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 2. Filter & Search Controls
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onChanged: (v) => setState(() => _searchQuery = v),
                            decoration: InputDecoration(
                              hintText: 'Search by Order ID, Student Name, Email, or Product...',
                              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'All', label: Text('All')),
                            ButtonSegment(value: 'Completed', label: Text('Completed')),
                            ButtonSegment(value: 'Pending', label: Text('Pending')),
                            ButtonSegment(value: 'Incomplete', label: Text('Incomplete')),
                            ButtonSegment(value: 'Cancelled', label: Text('Cancelled')),
                          ],
                          selected: {_statusFilter},
                          onSelectionChanged: (set) => setState(() => _statusFilter = set.first),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. Orders Table
                  if (filtered.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(48),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.receipt_long_outlined, size: 54, color: Color(0xFF94A3B8)),
                          const SizedBox(height: 12),
                          Text('No orders found', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
                          const SizedBox(height: 4),
                          const Text('Adjust search criteria or status filter above.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                        ],
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DataTable(
                        columnSpacing: 20,
                        columns: const [
                          DataColumn(label: Text('Order ID')),
                          DataColumn(label: Text('Student Info')),
                          DataColumn(label: Text('Product')),
                          DataColumn(label: Text('Amount')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Quick Actions')),
                        ],
                        rows: filtered.map((o) {
                          final rawId = (o['order_number'] ?? o['order_id'] ?? o['id'] ?? '').toString();
                          final uid = (o['user_id'] ?? o['student_id'] ?? '').toString();
                          final created = o['created_at'] != null ? DateTime.tryParse(o['created_at'].toString()) : null;
                          final orderId = SupabaseService.formatOrderId(rawId: rawId, userId: uid, date: created);
                          final name = (o['student_name'] ?? o['user_name'] ?? 'Student').toString();
                          final email = (o['student_email'] ?? o['user_email'] ?? '').toString();
                          final product = (o['product_name'] ?? 'Test Series').toString();
                          final amount = (o['amount'] ?? o['total_amount'] ?? 0);
                          final status = (o['payment_status'] ?? o['status'] ?? 'completed').toString();
                          final dateStr = o['created_at'] != null ? DateFormat('dd MMM, hh:mm a').format(DateTime.parse(o['created_at'])) : '-';

                          return DataRow(cells: [
                            DataCell(
                              InkWell(
                                onTap: () => _showOrderDetailsDialog(o),
                                child: Text(
                                  orderId,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5), fontFamily: 'monospace'),
                                ),
                              ),
                            ),
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text(email, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                ],
                              ),
                            ),
                            DataCell(
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 180),
                                child: Text(product, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                              ),
                            ),
                            DataCell(
                              Text(
                                '₹$amount',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
                              ),
                            ),
                            DataCell(_buildStatusBadge(status)),
                            DataCell(Text(dateStr, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)))),
                            DataCell(
                              PopupMenuButton<String>(
                                onSelected: (act) {
                                  if (act == 'confirm') {
                                    _updateOrderStatus(orderId, 'completed', note: 'Manually verified and confirmed by Admin');
                                  } else if (act == 'cancel') {
                                    _updateOrderStatus(orderId, 'cancelled', note: 'Cancelled by Admin');
                                  } else if (act == 'incomplete') {
                                    _updateOrderStatus(orderId, 'incomplete', note: 'Marked payment incomplete');
                                  } else if (act == 'reminder') {
                                    _showPaymentReminderDialog(o);
                                  } else if (act == 'details') {
                                    _showOrderDetailsDialog(o);
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(
                                    value: 'details',
                                    child: Row(
                                      children: [
                                        Icon(Icons.receipt_long_rounded, size: 18, color: Color(0xFF4F46E5)),
                                        SizedBox(width: 10),
                                        Text('View Order Details'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'confirm',
                                    child: Row(
                                      children: [
                                        Icon(Icons.check_circle_outline_rounded, size: 18, color: Color(0xFF10B981)),
                                        SizedBox(width: 10),
                                        Text('Confirm Order (Grant Access)'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'reminder',
                                    child: Row(
                                      children: [
                                        Icon(Icons.notifications_active_outlined, size: 18, color: Color(0xFFD97706)),
                                        SizedBox(width: 10),
                                        Text('Send Payment Reminder'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'incomplete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFEA580C)),
                                        SizedBox(width: 10),
                                        Text('Mark Payment Incomplete'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuDivider(),
                                  const PopupMenuItem(
                                    value: 'cancel',
                                    child: Row(
                                      children: [
                                        Icon(Icons.cancel_outlined, size: 18, color: Color(0xFFEF4444)),
                                        SizedBox(width: 10),
                                        Text('Cancel Order (Revoke Access)', style: TextStyle(color: Color(0xFFEF4444))),
                                      ],
                                    ),
                                  ),
                                ],
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Actions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                                      SizedBox(width: 4),
                                      Icon(Icons.arrow_drop_down_rounded, size: 18, color: Color(0xFF334155)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricStat(String title, String count, IconData icon, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
                  const SizedBox(height: 2),
                  Text(count, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
