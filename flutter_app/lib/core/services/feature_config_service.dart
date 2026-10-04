import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeatureModel {
  final String key;
  final String name;
  final String description;
  final String visibility; // 'visible' | 'hidden'
  final String status; // 'active' | 'coming_soon' | 'premium'
  final String iconName;
  final int sortOrder;
  final String ctaText;
  final String comingSoonMessage;
  final String targetRoute;
  final String updatedAt;

  FeatureModel({
    required this.key,
    required this.name,
    required this.description,
    this.visibility = 'visible',
    this.status = 'coming_soon',
    this.iconName = 'quiz',
    this.sortOrder = 1,
    this.ctaText = 'Explore',
    this.comingSoonMessage = 'This feature is currently under development. We\'re working on bringing it to you soon.',
    this.targetRoute = '',
    String? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  bool get isVisible => visibility == 'visible';
  bool get isHidden => visibility == 'hidden';
  bool get isActive => isVisible && status == 'active';
  bool get isComingSoon => isVisible && status == 'coming_soon';
  bool get isPremium => isVisible && status == 'premium';

  FeatureModel copyWith({
    String? key,
    String? name,
    String? description,
    String? visibility,
    String? status,
    String? iconName,
    int? sortOrder,
    String? ctaText,
    String? comingSoonMessage,
    String? targetRoute,
    String? updatedAt,
  }) {
    return FeatureModel(
      key: key ?? this.key,
      name: name ?? this.name,
      description: description ?? this.description,
      visibility: visibility ?? this.visibility,
      status: status ?? this.status,
      iconName: iconName ?? this.iconName,
      sortOrder: sortOrder ?? this.sortOrder,
      ctaText: ctaText ?? this.ctaText,
      comingSoonMessage: comingSoonMessage ?? this.comingSoonMessage,
      targetRoute: targetRoute ?? this.targetRoute,
      updatedAt: updatedAt ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'name': name,
        'description': description,
        'visibility': visibility,
        'status': status,
        'icon_name': iconName,
        'sort_order': sortOrder,
        'cta_text': ctaText,
        'coming_soon_message': comingSoonMessage,
        'target_route': targetRoute,
        'updated_at': updatedAt,
      };

  factory FeatureModel.fromJson(Map<String, dynamic> json) => FeatureModel(
        key: json['key'] ?? '',
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        visibility: json['visibility'] ?? 'visible',
        status: json['status'] ?? 'coming_soon',
        iconName: json['icon_name'] ?? 'quiz',
        sortOrder: json['sort_order'] is int ? json['sort_order'] : int.tryParse(json['sort_order']?.toString() ?? '1') ?? 1,
        ctaText: json['cta_text'] ?? 'Explore',
        comingSoonMessage: json['coming_soon_message'] ?? 'This feature is currently under development. Stay tuned!',
        targetRoute: json['target_route'] ?? '',
        updatedAt: json['updated_at'] ?? DateTime.now().toIso8601String(),
      );
}

class FeatureConfigService {
  static const String dbKey = 'feature_flags';
  static const String prefsCacheKey = 'cosmyra_feature_flags_cache';

  static final ValueNotifier<int> notifier = ValueNotifier<int>(0);
  static List<FeatureModel> _features = _defaultFeatures();
  static List<Map<String, dynamic>> _auditLogs = [];
  static bool _initialized = false;
  static bool _pollingStarted = false;

  static List<FeatureModel> _defaultFeatures() {
    return [
      FeatureModel(
        key: 'test_series',
        name: 'Test Series',
        description: 'Full-length & chapter-wise NEET & JEE mock test series with detailed analysis.',
        visibility: 'visible',
        status: 'active',
        iconName: 'quiz',
        sortOrder: 1,
        ctaText: 'Start Test Series',
        comingSoonMessage: 'Test Series is currently active and available!',
        targetRoute: '/practice',
      ),
      FeatureModel(
        key: 'premium_plans',
        name: 'Premium Plans',
        description: 'Unlock unlimited access to all courses, test series, and AI prep tools.',
        visibility: 'visible',
        status: 'premium',
        iconName: 'workspace_premium',
        sortOrder: 2,
        ctaText: 'Upgrade to Premium',
        comingSoonMessage: 'Premium plans are coming soon.',
        targetRoute: '/pricing',
      ),
      FeatureModel(
        key: 'performance_analytics',
        name: 'Performance Analytics',
        description: 'Track performance, topic accuracy, speed, and overall rank predictions.',
        visibility: 'visible',
        status: 'coming_soon',
        iconName: 'analytics',
        sortOrder: 3,
        ctaText: 'View Analytics',
        comingSoonMessage: 'Performance Analytics is currently under development. We\'re working on bringing this feature to you soon.',
        targetRoute: '/analytics',
      ),
      FeatureModel(
        key: 'custom_practice',
        name: 'Custom Practice',
        description: 'Create custom practice sessions filtered by subject, topic, and difficulty.',
        visibility: 'visible',
        status: 'coming_soon',
        iconName: 'tune',
        sortOrder: 4,
        ctaText: 'Custom Practice',
        comingSoonMessage: 'Custom Practice is currently under development. We\'re working to bring this feature to you soon.',
        targetRoute: '/custom-practice',
      ),
      FeatureModel(
        key: 'custom_test',
        name: 'Custom Test',
        description: 'Design custom mock tests tailored to your exam target and weak areas.',
        visibility: 'visible',
        status: 'coming_soon',
        iconName: 'timer',
        sortOrder: 5,
        ctaText: 'Create Custom Test',
        comingSoonMessage: 'Custom Test generator is currently under development. Stay tuned!',
        targetRoute: '/custom-test',
      ),
      FeatureModel(
        key: 'pyq_practice',
        name: 'PYQ Practice',
        description: 'Practice last 15 years chapter-wise NEET & JEE questions with explanations.',
        visibility: 'visible',
        status: 'coming_soon',
        iconName: 'history_edu',
        sortOrder: 6,
        ctaText: 'Practice PYQs',
        comingSoonMessage: 'PYQ Practice bank is under active preparation. Stay tuned!',
        targetRoute: '/pyq',
      ),
      FeatureModel(
        key: 'nta_questions',
        name: 'NTA Questions',
        description: 'Official NTA Abhyas question set with step-by-step solutions.',
        visibility: 'visible',
        status: 'coming_soon',
        iconName: 'menu_book',
        sortOrder: 7,
        ctaText: 'Explore NTA Questions',
        comingSoonMessage: 'NTA Official Question Bank is being updated. Available very soon!',
        targetRoute: '/nta-questions',
      ),
    ];
  }

  static Future<void> init({bool forceRefresh = false}) async {
    if (_initialized && !forceRefresh) return;

    _startAutoPolling();

    // Load from local storage cache first for zero latency startup
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedRaw = prefs.getString(prefsCacheKey);
      if (cachedRaw != null && cachedRaw.isNotEmpty) {
        _applyRawJson(cachedRaw);
      }
    } catch (_) {}

    // Fetch live from Supabase system_config / platform_settings
    try {
      final client = Supabase.instance.client;
      var res = await client
          .from('system_config')
          .select('value')
          .eq('key', dbKey)
          .maybeSingle();

      if (res == null || res['value'] == null) {
        res = await client
            .from('platform_settings')
            .select('value')
            .eq('key', dbKey)
            .maybeSingle();
      }

      if (res != null && res['value'] != null) {
        final val = res['value'];
        final String rawJson = val is String ? val : jsonEncode(val);
        _applyRawJson(rawJson);

        // Cache locally
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(prefsCacheKey, rawJson);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Notice fetching feature_flags from system_config: $e');
    }

    _initialized = true;
  }

  static void _startAutoPolling() {
    if (_pollingStarted) return;
    _pollingStarted = true;
    Future.delayed(const Duration(seconds: 8), () async {
      while (true) {
        await Future.delayed(const Duration(seconds: 12));
        try {
          final client = Supabase.instance.client;
          var res = await client
              .from('system_config')
              .select('value')
              .eq('key', dbKey)
              .maybeSingle();
          if (res == null || res['value'] == null) {
            res = await client
                .from('platform_settings')
                .select('value')
                .eq('key', dbKey)
                .maybeSingle();
          }
          if (res != null && res['value'] != null) {
            final val = res['value'];
            final String rawJson = val is String ? val : jsonEncode(val);
            _applyRawJson(rawJson);
          }
        } catch (_) {}
      }
    });
  }

  static String _lastRawJson = '';

  static void _applyRawJson(String rawJson) {
    final cleanJson = rawJson.trim();
    if (cleanJson.isNotEmpty && cleanJson == _lastRawJson && _features.isNotEmpty) {
      return;
    }
    _lastRawJson = cleanJson;

    try {
      final Map<String, dynamic> data = jsonDecode(rawJson);
      final loadedMap = <String, FeatureModel>{};

      if (data['features'] is List) {
        final List list = data['features'];
        for (var item in list) {
          if (item is Map) {
            final f = FeatureModel.fromJson(Map<String, dynamic>.from(item));
            if (f.key.isNotEmpty) {
              loadedMap[f.key] = f;
            }
          }
        }
      } else {
        // Fallback for key-value maps (e.g. {"go_premium": true/false/"hidden"})
        data.forEach((key, val) {
          final cleanKey = key.toString().toLowerCase().trim();
          String vis = 'visible';
          String st = 'active';
          if (val == false || val == 'hidden' || val == 'disabled') {
            vis = 'hidden';
          } else if (val == 'coming_soon') {
            st = 'coming_soon';
          } else if (val == 'premium') {
            st = 'premium';
          }
          loadedMap[cleanKey] = FeatureModel(
            key: cleanKey,
            name: key.toString(),
            description: '',
            visibility: vis,
            status: st,
          );
        });
      }

      // Merge loaded features with default list so new keys are automatically preserved
      final defaults = _defaultFeatures();
      final List<FeatureModel> merged = [];
      for (var def in defaults) {
        String? matchedKey;
        if (loadedMap.containsKey(def.key)) {
          matchedKey = def.key;
        } else if (def.key == 'premium_plans') {
          for (var alias in ['go_premium', 'go_premium_enabled', 'premium', 'store_packages']) {
            if (loadedMap.containsKey(alias)) {
              matchedKey = alias;
              break;
            }
          }
        }

        if (matchedKey != null) {
          final loadedModel = loadedMap.remove(matchedKey)!;
          merged.add(loadedModel.copyWith(key: def.key));
        } else {
          merged.add(def);
        }
      }
      merged.addAll(loadedMap.values);

      merged.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      _features = merged;

      if (data['audit_logs'] is List) {
        _auditLogs = List<Map<String, dynamic>>.from(
          (data['audit_logs'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
        );
      }

      Future.microtask(() {
        notifier.value++;
      });
    } catch (e) {
      debugPrint('Error parsing feature flags JSON: $e');
    }
  }

  static List<FeatureModel> getAllFeatures() {
    return List<FeatureModel>.from(_features);
  }

  static FeatureModel? getFeature(String featureKey) {
    try {
      final keyClean = featureKey.toLowerCase().trim();
      for (var f in _features) {
        if (f.key.toLowerCase().trim() == keyClean) return f;
      }
      if (keyClean == 'premium_plans' ||
          keyClean == 'go_premium' ||
          keyClean == 'go_premium_enabled' ||
          keyClean == 'premium' ||
          keyClean == 'store_packages') {
        for (var f in _features) {
          final fk = f.key.toLowerCase().trim();
          if (fk == 'premium_plans' ||
              fk == 'go_premium' ||
              fk == 'go_premium_enabled' ||
              fk == 'premium' ||
              fk == 'store_packages') {
            return f;
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static bool isFeatureEnabled(String featureKey) => isVisible(featureKey);

  static bool isVisible(String featureKey) {
    final f = getFeature(featureKey);
    if (f == null) {
      return true;
    }
    return f.isVisible;
  }

  static bool isHidden(String featureKey) {
    return !isVisible(featureKey);
  }

  static String getStatus(String featureKey) {
    final f = getFeature(featureKey);
    if (f == null) {
      return featureKey == 'test_series' ? 'active' : 'coming_soon';
    }
    return f.status;
  }

  static bool isActive(String featureKey) {
    return isVisible(featureKey) && getStatus(featureKey) == 'active';
  }

  static bool isComingSoon(String featureKey) {
    return isVisible(featureKey) && getStatus(featureKey) == 'coming_soon';
  }

  static bool isPremium(String featureKey) {
    return isVisible(featureKey) && getStatus(featureKey) == 'premium';
  }

  static List<Map<String, dynamic>> getAuditLogs() {
    return List<Map<String, dynamic>>.from(_auditLogs);
  }

  static Future<bool> saveFeatures(List<FeatureModel> features, {String adminEmail = 'Admin'}) async {
    // Generate audit logs for changes
    final newLogs = List<Map<String, dynamic>>.from(_auditLogs);
    final now = DateTime.now().toIso8601String();

    for (var newF in features) {
      final oldF = getFeature(newF.key);
      if (oldF != null) {
        if (oldF.status != newF.status || oldF.visibility != newF.visibility) {
          newLogs.insert(0, {
            'feature': newF.name,
            'feature_key': newF.key,
            'old_status': oldF.status.toUpperCase(),
            'new_status': newF.status.toUpperCase(),
            'old_visibility': oldF.visibility.toUpperCase(),
            'new_visibility': newF.visibility.toUpperCase(),
            'changed_by': adminEmail,
            'changed_at': now,
          });
        }
      }
    }

    // Keep max 50 audit logs
    if (newLogs.length > 50) {
      newLogs.removeRange(50, newLogs.length);
    }

    features.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    _features = List<FeatureModel>.from(features);
    _auditLogs = newLogs;

    final Map<String, dynamic> payload = {
      'features': _features.map((e) => e.toJson()).toList(),
      'audit_logs': _auditLogs,
    };
    final String valStr = jsonEncode(payload);

    // Save to local SharedPreferences cache
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsCacheKey, valStr);
    } catch (_) {}

    notifier.value++;

    // Save to Supabase system_config & platform_settings
    try {
      final client = Supabase.instance.client;
      await client.from('system_config').upsert({
        'key': dbKey,
        'value': valStr,
        'updated_at': now,
      });
      await client.from('platform_settings').upsert({
        'key': dbKey,
        'value': valStr,
        'updated_at': now,
      });
      return true;
    } catch (e) {
      debugPrint('Notice saving feature_flags to Supabase: $e');
      return true; // Local state saved
    }
  }

  /// Handles user tapping on a feature across all client screens
  static void handleFeatureTap(
    BuildContext context,
    String featureKey, {
    VoidCallback? onActive,
  }) {
    final feature = getFeature(featureKey);

    // Safe fallback if feature is unknown
    if (feature == null) {
      if (featureKey == 'test_series') {
        if (onActive != null) onActive(); else context.go('/practice');
      } else {
        showComingSoonDialog(
          context,
          title: 'Feature Coming Soon',
          message: 'This feature is currently under active development. We\'re working on bringing it to you soon!',
        );
      }
      return;
    }

    if (feature.isHidden) {
      // Do nothing if hidden
      return;
    }

    if (feature.isComingSoon) {
      showComingSoonDialog(
        context,
        title: feature.name,
        message: feature.comingSoonMessage,
        ctaText: feature.ctaText,
      );
      return;
    }

    if (feature.isPremium) {
      // Open existing pricing / purchase flow
      context.go('/pricing');
      return;
    }

    if (feature.isActive) {
      if (onActive != null) {
        onActive();
      } else if (feature.targetRoute.isNotEmpty) {
        context.go(feature.targetRoute);
      }
    }
  }

  /// Displays the official glassmorphic Coming Soon dialog
  static void showComingSoonDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? ctaText,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 16,
        backgroundColor: Colors.white,
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFC7D2FE), width: 2),
                ),
                child: const Center(
                  child: Text(
                    '🚀',
                    style: TextStyle(fontSize: 34),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt, size: 14, color: Color(0xFFD97706)),
                    const SizedBox(width: 4),
                    Text(
                      'COMING SOON',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFB45309),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message.isNotEmpty
                    ? message
                    : '$title is currently under development. We\'re working on bringing this feature to you soon.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.5,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Got it',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Conditional wrapper widget that completely removes hidden features from UI
  static Widget wrapFeature({
    required String featureKey,
    required Widget child,
    Widget fallback = const SizedBox.shrink(),
  }) {
    if (isHidden(featureKey)) {
      return fallback;
    }
    return child;
  }
}
