import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/cart_service.dart';
import '../../../models/models.dart';
import '../upi_payment_verification_screen.dart';

class EcommerceCheckoutDialog extends StatefulWidget {
  final CartItem? singleItem;
  final Function(String testId, String title, int duration)? onStartTest;

  const EcommerceCheckoutDialog({
    super.key,
    this.singleItem,
    this.onStartTest,
  });

  static Future<void> show(
    BuildContext context, {
    CartItem? singleItem,
    Function(String testId, String title, int duration)? onStartTest,
  }) async {
    if (context.mounted) {
      if (singleItem != null) {
        context.push('/checkout', extra: singleItem);
      } else {
        context.push('/checkout');
      }
    }
  }

  @override
  State<EcommerceCheckoutDialog> createState() => _EcommerceCheckoutDialogState();
}

class _EcommerceCheckoutDialogState extends State<EcommerceCheckoutDialog> {
  @override
  Widget build(BuildContext context) {
    return UpiPaymentVerificationScreen(
      items: widget.singleItem != null ? [widget.singleItem!.toJson()] : null,
      totalAmount: widget.singleItem?.price,
    );
  }
}
