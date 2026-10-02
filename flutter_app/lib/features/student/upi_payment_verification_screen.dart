import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/models.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/cart_service.dart';

class UpiPaymentVerificationScreen extends StatefulWidget {
  final UserProfileModel? user;
  final List<Map<String, dynamic>>? items;
  final double? totalAmount;
  final String? couponCode;
  final String? upiId;
  final String? payeeName;
  final String? upiUrl;

  const UpiPaymentVerificationScreen({
    super.key,
    this.user,
    this.items,
    this.totalAmount,
    this.couponCode = '',
    this.upiId,
    this.payeeName,
    this.upiUrl,
  });

  @override
  State<UpiPaymentVerificationScreen> createState() => _UpiPaymentVerificationScreenState();
}

class _UpiPaymentVerificationScreenState extends State<UpiPaymentVerificationScreen> {
  final TextEditingController _utrController = TextEditingController();
  bool _isSubmitting = false;
  bool _isUploadingScreenshot = false;
  String? _paymentScreenshotUrl;
  String? _screenshotFileName;

  late UserProfileModel _user;
  late List<Map<String, dynamic>> _items;
  late double _totalAmount;
  late String _couponCode;
  late String _upiId;
  late String _payeeName;
  late String _upiUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    _couponCode = widget.couponCode ?? '';
    _user = widget.user ??
        SupabaseService.activeUserSession ??
        UserProfileModel(
          id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
          fullName: 'Student Aspirant',
          email: 'student@cosmyra.edtech',
          role: 'student',
        );

    _items = widget.items ?? (CartService.instance.items.isNotEmpty ? CartService.instance.items.map((e) => e.toJson()).toList() : []);
    _totalAmount = widget.totalAmount ?? (CartService.instance.subtotal > 0 ? CartService.instance.subtotal : 499.0);

    if (widget.upiId != null && widget.upiId!.isNotEmpty) {
      _upiId = widget.upiId!;
      _payeeName = widget.payeeName ?? 'Cosmyra Edu Platform';
      _upiUrl = widget.upiUrl ?? 'upi://pay?pa=$_upiId&pn=${Uri.encodeComponent(_payeeName)}&am=${_totalAmount.toStringAsFixed(2)}&tn=${Uri.encodeComponent('Cosmyra Order Enrollment')}&cu=INR';
    } else {
      final settings = await SupabaseService.fetchPaymentSettings();
      _upiId = (settings['upi_id'] ?? '1mdollar2027@okicici').toString().trim();
      _payeeName = (settings['upi_payee_name'] ?? 'Cosmyra Edu Platform').toString().trim();
      _upiUrl = 'upi://pay?pa=$_upiId&pn=${Uri.encodeComponent(_payeeName)}&am=${_totalAmount.toStringAsFixed(2)}&tn=${Uri.encodeComponent('Cosmyra Order Enrollment')}&cu=INR';
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _utrController.dispose();
    super.dispose();
  }

  Future<void> _launchUpiApp() async {
    final uri = Uri.parse(_upiUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not auto-open UPI App. Please scan QR code or copy UPI ID: $_upiId'),
            backgroundColor: const Color(0xFFD97706),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadScreenshot() async {
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
          setState(() => _isUploadingScreenshot = true);
          final ext = (file.extension ?? 'png').toLowerCase();
          final mimeType = ext == 'jpg' || ext == 'jpeg'
              ? 'image/jpeg'
              : (ext == 'webp' ? 'image/webp' : 'image/png');

          final url = await SupabaseService.uploadMediaFile(
            fileBytes: bytes,
            fileName: file.name,
            mimeType: mimeType,
          );

          setState(() {
            _paymentScreenshotUrl = url;
            _screenshotFileName = file.name;
            _isUploadingScreenshot = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment screenshot receipt uploaded successfully!'),
                backgroundColor: Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      setState(() => _isUploadingScreenshot = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Screenshot upload failed: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _submitVerification() async {
    final utrText = _utrController.text.trim();
    final hasUtr = utrText.isNotEmpty && utrText.length >= 6;
    final hasScreenshot = _paymentScreenshotUrl != null && _paymentScreenshotUrl!.isNotEmpty;

    if (!hasUtr && !hasScreenshot) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter 12-digit UTR Number OR upload a Payment Screenshot receipt.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final res = await SupabaseService.submitUpiPaymentVerification(
        user: _user,
        items: _items,
        utrNumber: utrText,
        paymentScreenshotUrl: _paymentScreenshotUrl,
        couponCode: _couponCode,
        totalAmount: _totalAmount,
      );

      CartService.instance.clearCart();

      final orderNum = (res['order_number'] ?? res['order_id'] ?? 'ORD-SUCCESS').toString();

      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSuccessDialog(orderNum);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showSuccessDialog(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 56),
              ),
              const SizedBox(height: 16),
              Text(
                'Payment Submitted!',
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Order ID: $orderId\n\nYour payment verification details have been received. Admin will verify and activate your enrollment shortly.',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B), height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/dashboard');
                    }
                  },
                  child: Text('Done & Go to Dashboard', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)),
        ),
      );
    }

    final qrImageUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=260x260&data=${Uri.encodeComponent(_upiUrl)}';

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: isMobile ? Colors.white : const Color(0xFFF8FAFC),
      appBar: isMobile
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    context.go('/test-series');
                  }
                },
              ),
              title: Text('Complete UPI Payment', style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.w800)),
              centerTitle: true,
            )
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20, vertical: isMobile ? 8 : 24),
            physics: const BouncingScrollPhysics(),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(isMobile ? 16 : 24),
                border: isMobile ? Border.all(color: const Color(0xFFF1F5F9)) : Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: isMobile
                    ? null
                    : const [
                        BoxShadow(
                          color: Color(0x0D0F172A),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
              ),
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 14 : 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Header Row
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
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x4D2563EB),
                                blurRadius: 8,
                                offset: Offset(0, 3),
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
                                      border: Border.all(color: const Color(0xFFD1FAE5)),
                                    ),
                                    child: Text(
                                      'Pay ₹${_totalAmount.toInt()}',
                                      style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w900, color: const Color(0xFF059669)),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'GPay • PhonePe • Paytm...',
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
                          onTap: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            } else {
                              context.go('/dashboard');
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: Color(0xFFE2E8F0)),

                    // STEP 1 Badge & Launch Button
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
                        onPressed: _launchUpiApp,
                        icon: const Icon(Icons.touch_app_rounded, size: 18),
                        label: Text(
                          'Open UPI App (GPay / PhonePe / Paytm)',
                          style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // QR Code Card
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0D0F172A),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                qrImageUrl,
                                width: 170,
                                height: 170,
                                fit: BoxFit.contain,
                                errorBuilder: (ctx, err, st) => Container(
                                  width: 170,
                                  height: 170,
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
                            const SizedBox(height: 8),
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
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Official Merchant UPI ID:', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF1E40AF))),
                                const SizedBox(height: 2),
                                SelectableText(
                                  _upiId,
                                  style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w900, color: const Color(0xFF1D4ED8)),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              side: const BorderSide(color: Color(0xFF93C5FD)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              backgroundColor: Colors.white,
                            ),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _upiId));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✓ Merchant UPI ID copied to clipboard!'),
                                  backgroundColor: Color(0xFF10B981),
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 13, color: Color(0xFF1D4ED8)),
                            label: Text('Copy ID', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF1D4ED8))),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // STEP 2 Container
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
                                  'Enter 12-Digit UTR / Ref Number',
                                  style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w800, color: const Color(0xFF92400E)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'After payment in GPay / PhonePe / Paytm, copy the 12-digit UTR/Ref No. from transaction details and paste below:',
                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF78350F), height: 1.35),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // UTR TextField Input Box
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
                          TextField(
                            controller: _utrController,
                            keyboardType: TextInputType.number,
                            maxLength: 12,
                            style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A), letterSpacing: 1.0),
                            decoration: InputDecoration(
                              hintText: 'e.g. 429182736410',
                              hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8), letterSpacing: 0.0),
                              counterText: '',
                              isDense: true,
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: const Icon(Icons.confirmation_number_outlined, size: 18, color: Color(0xFF64748B)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Option 1: Payment Screenshot Upload (Cloudflare S3)
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

                          if (_isUploadingScreenshot)
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
                            )
                          else if (_paymentScreenshotUrl != null && _paymentScreenshotUrl!.isNotEmpty)
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
                                      _paymentScreenshotUrl!,
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
                                              'Screenshot Uploaded',
                                              style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w800, color: const Color(0xFF065F46)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _screenshotFileName ?? 'payment_receipt.png',
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
                                      setState(() {
                                        _paymentScreenshotUrl = null;
                                        _screenshotFileName = null;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            )
                          else
                            Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                onTap: _pickAndUploadScreenshot,
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
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Red Submit Button
                    Container(
                      height: 50,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: _isSubmitting
                            ? const LinearGradient(colors: [Color(0xFF94A3B8), Color(0xFF64748B)])
                            : const LinearGradient(
                                colors: [Color(0xFFFF3B30), Color(0xFFEF4444), Color(0xFFDC2626)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        boxShadow: [
                          BoxShadow(
                            color: _isSubmitting
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
                          onTap: (_isSubmitting || _isUploadingScreenshot) ? null : _submitVerification,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isSubmitting) ...[
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
                                  const Icon(Icons.check_circle_rounded, size: 20, color: Colors.white),
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
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
