import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';

class CartItem {
  final String id;
  final String title;
  final String description;
  final double price;
  final double originalPrice;
  final String bannerImageUrl;
  final String exam;
  final String productType; // 'test_series', 'subscription'
  final String validity;
  final int testCount;

  CartItem({
    required this.id,
    required this.title,
    this.description = '',
    required this.price,
    required this.originalPrice,
    this.bannerImageUrl = '',
    this.exam = 'NEET',
    this.productType = 'test_series',
    this.validity = 'Valid until exam',
    this.testCount = 1,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'price': price,
        'original_price': originalPrice,
        'banner_image_url': bannerImageUrl,
        'exam': exam,
        'product_type': productType,
        'validity': validity,
        'test_count': testCount,
      };

  factory CartItem.fromJson(Map<String, dynamic> map) => CartItem(
        id: map['id']?.toString() ?? '',
        title: map['title']?.toString() ?? 'Test Series',
        description: map['description']?.toString() ?? '',
        price: (map['price'] is num) ? (map['price'] as num).toDouble() : (double.tryParse(map['price']?.toString() ?? '') ?? 299.0),
        originalPrice: (map['original_price'] is num)
            ? (map['original_price'] as num).toDouble()
            : (double.tryParse(map['original_price']?.toString() ?? '') ?? 999.0),
        bannerImageUrl: map['banner_image_url']?.toString() ?? '',
        exam: map['exam']?.toString() ?? 'NEET',
        productType: map['product_type']?.toString() ?? 'test_series',
        validity: map['validity']?.toString() ?? 'Valid until exam',
        testCount: (map['test_count'] is int) ? map['test_count'] : (int.tryParse(map['test_count']?.toString() ?? '') ?? 1),
      );
}

class CartService extends ChangeNotifier {
  static final CartService instance = CartService._internal();
  CartService._internal() {
    _loadFromCache();
  }

  final List<CartItem> _items = [];
  Map<String, dynamic>? _appliedCoupon;
  bool _isLoading = false;

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.length;
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
  Map<String, dynamic>? get appliedCoupon => _appliedCoupon;
  String? get appliedCouponCode => _appliedCoupon?['code']?.toString();
  double get finalTotal => finalAmount;
  bool get isLoading => _isLoading;

  double get subtotal {
    double sum = 0.0;
    for (var it in _items) {
      sum += it.price;
    }
    return sum;
  }

  double get originalSubtotal {
    double sum = 0.0;
    for (var it in _items) {
      sum += it.originalPrice;
    }
    return sum;
  }

  double get discountAmount {
    if (_appliedCoupon == null || _items.isEmpty) return 0.0;
    final type = _appliedCoupon!['discount_type']?.toString() ?? 'percentage';
    final val = (_appliedCoupon!['discount_value'] as num?)?.toDouble() ?? 0.0;
    final maxDisc = (_appliedCoupon!['max_discount'] as num?)?.toDouble() ?? 500.0;

    double calculated = 0.0;
    if (type == 'percentage') {
      calculated = (subtotal * val) / 100.0;
    } else {
      calculated = val;
    }

    if (calculated > maxDisc) calculated = maxDisc;
    if (calculated > subtotal) calculated = subtotal;
    return calculated;
  }

  double get finalAmount {
    final res = subtotal - discountAmount;
    return res > 0 ? res : 0.0;
  }

  bool containsProduct(String productId) {
    return _items.any((it) => it.id == productId);
  }

  Future<bool> addToCart(CartItem item) async {
    // Check if user already owns this product
    final user = SupabaseService.activeUserSession;
    if (user != null) {
      final owns = await SupabaseService.hasActiveEntitlement(user.id, item.id);
      if (owns) {
        return false; // Already owned
      }
    }

    // Check if already in cart
    if (!containsProduct(item.id)) {
      _items.add(item);
      _saveToCache();
      notifyListeners();
    }
    return true;
  }

  void removeFromCart(String productId) {
    _items.removeWhere((it) => it.id == productId);
    if (_items.isEmpty) {
      _appliedCoupon = null;
    }
    _saveToCache();
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _appliedCoupon = null;
    _saveToCache();
    notifyListeners();
  }

  Future<Map<String, dynamic>> applyCoupon(String code) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      return {'success': false, 'message': 'Please enter a valid coupon code.'};
    }

    _isLoading = true;
    notifyListeners();

    try {
      final res = await SupabaseService.validateCoupon(cleanCode, subtotal);
      _isLoading = false;
      if (res['valid'] == true) {
        _appliedCoupon = res['coupon'];
        notifyListeners();
        return {'success': true, 'message': 'Coupon "$cleanCode" applied successfully!'};
      } else {
        notifyListeners();
        return {'success': false, 'message': res['message'] ?? 'Invalid coupon code.'};
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Error validating coupon: $e'};
    }
  }

  void removeCoupon() {
    _appliedCoupon = null;
    notifyListeners();
  }

  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _items.map((e) => e.toJson()).toList();
      await prefs.setString('cosmyra_cart_items', jsonEncode(list));
    } catch (e) {
      debugPrint('Cart cache save notice: $e');
    }
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('cosmyra_cart_items');
      if (str != null && str.isNotEmpty) {
        final List list = jsonDecode(str);
        _items.clear();
        for (var it in list) {
          _items.add(CartItem.fromJson(Map<String, dynamic>.from(it)));
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Cart cache load notice: $e');
    }
  }
}
