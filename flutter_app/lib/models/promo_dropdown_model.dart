import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Data Model for Admin Managed Top Dropdown Bar / Promo Ad Banner
/// Controls custom text, link/APK download, image, or raw HTML text dropdowns.
class PromoDropdownModel {
  final bool isActive;
  final String bannerType; // 'download_app', 'offer', 'promo_ad', 'custom_html', 'custom_text'
  final String title;
  final String text;
  final String actionLabel;
  final String actionUrl;
  final String imageUrl;
  final String htmlContent;
  final String badgeText;
  final String bgColorHex;
  final String textColorHex;
  final String accentColorHex;
  final bool isDismissible;
  final bool autoExpandOnLoad;
  final int updatedAt;

  const PromoDropdownModel({
    this.isActive = true,
    this.bannerType = 'download_app',
    this.title = '📱 Cosmyra NEET & JEE Official App Available!',
    this.text = 'Download our official Android APK to practice 50,000+ questions & full-length mock tests on mobile.',
    this.actionLabel = 'Download App (.apk)',
    this.actionUrl = 'https://neet-jee.in/app-release.apk',
    this.imageUrl = 'https://neet-jee.in/assets/icons/Icon-192.png',
    this.htmlContent = '',
    this.badgeText = 'NEW APP',
    this.bgColorHex = '1E1B4B',
    this.textColorHex = 'FFFFFF',
    this.accentColorHex = '10B981',
    this.isDismissible = true,
    this.autoExpandOnLoad = true,
    this.updatedAt = 0,
  });

  factory PromoDropdownModel.defaultConfig() {
    return PromoDropdownModel(
      isActive: true,
      bannerType: 'download_app',
      title: '📱 Download Cosmyra NEET & JEE Android App',
      text: 'Practice 50,000+ NTA questions, mock test series & PYQs anywhere on your phone!',
      actionLabel: 'Download App (.apk)',
      actionUrl: 'https://neet-jee.in/app-release.apk',
      imageUrl: '',
      htmlContent: '',
      badgeText: 'ANDROID APK',
      bgColorHex: '4F46E5',
      textColorHex: 'FFFFFF',
      accentColorHex: '10B981',
      isDismissible: true,
      autoExpandOnLoad: true,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  factory PromoDropdownModel.fromJson(Map<String, dynamic> json) {
    try {
      return PromoDropdownModel(
        isActive: json['isActive'] ?? json['is_active'] ?? true,
        bannerType: json['bannerType'] ?? json['banner_type'] ?? 'download_app',
        title: json['title'] ?? '📱 Download Cosmyra NEET & JEE Android App',
        text: json['text'] ?? json['description'] ?? '',
        actionLabel: json['actionLabel'] ?? json['action_label'] ?? json['buttonText'] ?? 'Download App',
        actionUrl: json['actionUrl'] ?? json['action_url'] ?? json['link'] ?? 'https://neet-jee.in/app-release.apk',
        imageUrl: json['imageUrl'] ?? json['image_url'] ?? '',
        htmlContent: json['htmlContent'] ?? json['html_content'] ?? json['customHtml'] ?? '',
        badgeText: json['badgeText'] ?? json['badge_text'] ?? 'PROMO',
        bgColorHex: json['bgColorHex'] ?? json['bg_color_hex'] ?? '4F46E5',
        textColorHex: json['textColorHex'] ?? json['text_color_hex'] ?? 'FFFFFF',
        accentColorHex: json['accentColorHex'] ?? json['accent_color_hex'] ?? '10B981',
        isDismissible: json['isDismissible'] ?? json['is_dismissible'] ?? true,
        autoExpandOnLoad: json['autoExpandOnLoad'] ?? json['auto_expand_on_load'] ?? true,
        updatedAt: (json['updatedAt'] ?? json['updated_at'] ?? 0) is int
            ? (json['updatedAt'] ?? json['updated_at'] ?? 0) as int
            : int.tryParse((json['updatedAt'] ?? json['updated_at'] ?? 0).toString()) ?? 0,
      );
    } catch (e) {
      debugPrint('Error parsing PromoDropdownModel: $e');
      return PromoDropdownModel.defaultConfig();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'isActive': isActive,
      'is_active': isActive,
      'bannerType': bannerType,
      'banner_type': bannerType,
      'title': title,
      'text': text,
      'description': text,
      'actionLabel': actionLabel,
      'action_label': actionLabel,
      'actionUrl': actionUrl,
      'action_url': actionUrl,
      'imageUrl': imageUrl,
      'image_url': imageUrl,
      'htmlContent': htmlContent,
      'html_content': htmlContent,
      'badgeText': badgeText,
      'badge_text': badgeText,
      'bgColorHex': bgColorHex,
      'bg_color_hex': bgColorHex,
      'textColorHex': textColorHex,
      'text_color_hex': textColorHex,
      'accentColorHex': accentColorHex,
      'accent_color_hex': accentColorHex,
      'isDismissible': isDismissible,
      'is_dismissible': isDismissible,
      'autoExpandOnLoad': autoExpandOnLoad,
      'auto_expand_on_load': autoExpandOnLoad,
      'updatedAt': updatedAt,
      'updated_at': updatedAt,
    };
  }

  PromoDropdownModel copyWith({
    bool? isActive,
    String? bannerType,
    String? title,
    String? text,
    String? actionLabel,
    String? actionUrl,
    String? imageUrl,
    String? htmlContent,
    String? badgeText,
    String? bgColorHex,
    String? textColorHex,
    String? accentColorHex,
    bool? isDismissible,
    bool? autoExpandOnLoad,
    int? updatedAt,
  }) {
    return PromoDropdownModel(
      isActive: isActive ?? this.isActive,
      bannerType: bannerType ?? this.bannerType,
      title: title ?? this.title,
      text: text ?? this.text,
      actionLabel: actionLabel ?? this.actionLabel,
      actionUrl: actionUrl ?? this.actionUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      htmlContent: htmlContent ?? this.htmlContent,
      badgeText: badgeText ?? this.badgeText,
      bgColorHex: bgColorHex ?? this.bgColorHex,
      textColorHex: textColorHex ?? this.textColorHex,
      accentColorHex: accentColorHex ?? this.accentColorHex,
      isDismissible: isDismissible ?? this.isDismissible,
      autoExpandOnLoad: autoExpandOnLoad ?? this.autoExpandOnLoad,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
