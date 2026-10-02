import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/models.dart';
import '../../core/services/supabase_service.dart';

class UpiPaymentVerificationScreen extends StatefulWidget {
  final UserProfileModel user;
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final String couponCode;
  final String upiId;
  final String payeeName;
  final String upiUrl;

  const UpiPaymentVerificationScreen({
    super.key,
    required this.user,
    required this.items,
    required this.totalAmount,
    this.couponCode = '',
    required this.upiId,
    required this.payeeName,
    required this.upiUrl,
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

  @override
  void dispose() {
    _utrController.dispose();
    super.dispose();
  }

  Future<void> _launchUpiApp() async {
    final uri = Uri.parse(widget.upiUrl);
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
            content: Text('Could not auto-open UPI App. Please scan QR code or copy UPI ID: ${widget.upiId}'),
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
        user: widget.user,
        items: widget.items,
        utrNumber: utrText,
        paymentScreenshotUrl: _paymentScreenshotUrl,
        couponCode: widget.couponCode,
        totalAmount: widget.totalAmount,
      );

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
    final qrImageUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=260x260&data=${Uri.encodeComponent(widget.upiUrl)}';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Complete UPI Payment',
              style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            Text(
              'Pay Rs. ${widget.totalAmount.toInt()} | Instant Verification',
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Summary Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A0F172A),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0x332563EB),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.shopping_bag, color: Color(0xFF60A5FA), size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Amount Payable',
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8)),
                                  ),
                                  Text(
                                    'Rs. ${widget.totalAmount.toStringAsFixed(2)}',
                                    style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0x3316A34A),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF22C55E)),
                              ),
                              child: Text(
                                'UPI DISCOUNT',
                                style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w900, color: const Color(0xFF4ADE80)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // STEP 1: Open UPI App & QR Code Box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x08000000),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'STEP 1',
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Tap to Open App OR Scan QR',
                                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Open UPI App Button
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              onPressed: _launchUpiApp,
                              icon: const Icon(Icons.touch_app, size: 20),
                              label: Text(
                                'Open UPI App (GPay / PhonePe / Paytm)',
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // QR Code
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x0D000000),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Image.network(
                                      qrImageUrl,
                                      width: 200,
                                      height: 200,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 200,
                                        height: 200,
                                        color: const Color(0xFFF1F5F9),
                                        alignment: Alignment.center,
                                        child: const Text('QR Code Unavailable', style: TextStyle(fontSize: 12)),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Scan QR using GPay, PhonePe, Paytm, BHIM',
                                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Merchant UPI ID Box
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                  Text(
                                    'Official Merchant UPI ID:',
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF1E40AF)),
                                  ),
                                  SelectableText(
                                    widget.upiId,
                                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w900, color: const Color(0xFF1D4ED8)),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: widget.upiId));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Merchant UPI ID copied to clipboard!'),
                                    backgroundColor: Color(0xFF10B981),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy, size: 14),
                              label: Text('Copy ID', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // STEP 2: Payment Verification Options
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x08000000),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD97706),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'STEP 2',
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Verify Payment Details',
                                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please attach your payment screenshot receipt OR enter the 12-digit UTR/Ref number (or both) for admin verification:',
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), height: 1.4),
                            ),
                            const SizedBox(height: 16),

                            // OPTION 1: PAYMENT SCREENSHOT UPLOAD (CLOUDFLARE S3)
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F3FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFDDD6FE), width: 1.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.cloud_upload, size: 18, color: Color(0xFF6D28D9)),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Option 1: Upload Payment Screenshot (Cloudflare S3)',
                                        style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w800, color: const Color(0xFF5B21B6)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  if (_isUploadingScreenshot)
                                    Container(
                                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFF93C5FD)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(color: Color(0xFF2563EB), strokeWidth: 2.5),
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'Uploading Receipt to Cloudflare S3...',
                                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
                                          ),
                                        ],
                                      ),
                                    )
                                  else if (_paymentScreenshotUrl != null && _paymentScreenshotUrl!.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFECFDF5),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFFA7F3D0)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 24),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Screenshot Uploaded',
                                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w900, color: const Color(0xFF065F46)),
                                                ),
                                                Text(
                                                  _screenshotFileName ?? 'payment_receipt.png',
                                                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF047857)),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _paymentScreenshotUrl = null;
                                                _screenshotFileName = null;
                                              });
                                            },
                                            child: Text('Remove', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFFEF4444))),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    InkWell(
                                      onTap: _pickAndUploadScreenshot,
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: const Color(0xFF7C3AED), width: 1.5),
                                          color: Colors.white,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF7C3AED),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(Icons.add_a_photo, size: 20, color: Colors.white),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Upload Payment Screenshot Receipt',
                                                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF5B21B6)),
                                                  ),
                                                  Text(
                                                    'Tap to attach payment proof from GPay / PhonePe / Paytm',
                                                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6D28D9)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(Icons.chevron_right, color: Color(0xFF7C3AED)),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // OPTION 2: 12-DIGIT UTR / REFERENCE NUMBER INPUT
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.numbers, size: 18, color: Color(0xFF2563EB)),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Option 2: Enter 12-Digit UTR / Ref Number',
                                        style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: _utrController,
                                    keyboardType: TextInputType.number,
                                    maxLength: 12,
                                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A), letterSpacing: 1.2),
                                    decoration: InputDecoration(
                                      hintText: 'e.g. 429182736410 (12-Digit UTR)',
                                      hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8), letterSpacing: 0.0),
                                      counterText: '',
                                      isDense: true,
                                      filled: true,
                                      fillColor: Colors.white,
                                      prefixIcon: const Icon(Icons.confirmation_number, size: 20, color: Color(0xFF64748B)),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom Fixed Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              boxShadow: [
                BoxShadow(
                  color: Color(0x0D0F172A),
                  blurRadius: 10,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isSubmitting ? null : _submitVerification,
                    child: _isSubmitting
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              ),
                              const SizedBox(width: 12),
                              const Text('Submitting Payment Verification...', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.verified, size: 20, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                'Submit Payment Verification',
                                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.3),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
