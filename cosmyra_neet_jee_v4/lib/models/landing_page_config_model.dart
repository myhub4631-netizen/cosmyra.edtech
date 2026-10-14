import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Comprehensive Canonical Landing Page Configuration Model
/// Synced live across Web, Flutter Web, Android App, and iOS via Supabase system_config.
class LandingPageConfigModel {
  final HeaderConfig header;
  final HeroSectionConfig hero;
  final StatsSectionConfig stats;
  final BannersSectionConfig banners;
  final TestSeriesSectionConfig testSeries;
  final FeaturesSectionConfig features;
  final CtaBannerConfig ctaBanner;
  final FooterConfig footer;
  final List<String> sectionOrder;
  final String primaryColorHex;
  final String accentColorHex;
  final bool enableAnimations;
  final int updatedAtTimestamp;

  const LandingPageConfigModel({
    required this.header,
    required this.hero,
    required this.stats,
    required this.banners,
    required this.testSeries,
    required this.features,
    required this.ctaBanner,
    required this.footer,
    required this.sectionOrder,
    this.primaryColorHex = '4F46E5',
    this.accentColorHex = '7C3AED',
    this.enableAnimations = true,
    this.updatedAtTimestamp = 0,
  });

  factory LandingPageConfigModel.defaultConfig() {
    return LandingPageConfigModel(
      header: HeaderConfig.defaultConfig(),
      hero: HeroSectionConfig.defaultConfig(),
      stats: StatsSectionConfig.defaultConfig(),
      banners: BannersSectionConfig.defaultConfig(),
      testSeries: TestSeriesSectionConfig.defaultConfig(),
      features: FeaturesSectionConfig.defaultConfig(),
      ctaBanner: CtaBannerConfig.defaultConfig(),
      footer: FooterConfig.defaultConfig(),
      sectionOrder: const ['hero', 'stats', 'banners', 'test_series', 'features', 'cta_banner', 'footer'],
      primaryColorHex: '4F46E5',
      accentColorHex: '7C3AED',
      enableAnimations: true,
      updatedAtTimestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  factory LandingPageConfigModel.fromJson(Map<String, dynamic> json) {
    try {
      return LandingPageConfigModel(
        header: json['header'] != null
            ? HeaderConfig.fromJson(Map<String, dynamic>.from(json['header']))
            : HeaderConfig.defaultConfig(),
        hero: json['hero'] != null
            ? HeroSectionConfig.fromJson(Map<String, dynamic>.from(json['hero']))
            : HeroSectionConfig.defaultConfig(),
        stats: json['stats'] != null
            ? StatsSectionConfig.fromJson(Map<String, dynamic>.from(json['stats']))
            : StatsSectionConfig.defaultConfig(),
        banners: json['banners'] != null
            ? BannersSectionConfig.fromJson(Map<String, dynamic>.from(json['banners']))
            : BannersSectionConfig.defaultConfig(),
        testSeries: json['testSeries'] != null
            ? TestSeriesSectionConfig.fromJson(Map<String, dynamic>.from(json['testSeries']))
            : TestSeriesSectionConfig.defaultConfig(),
        features: json['features'] != null
            ? FeaturesSectionConfig.fromJson(Map<String, dynamic>.from(json['features']))
            : FeaturesSectionConfig.defaultConfig(),
        ctaBanner: json['ctaBanner'] != null
            ? CtaBannerConfig.fromJson(Map<String, dynamic>.from(json['ctaBanner']))
            : CtaBannerConfig.defaultConfig(),
        footer: json['footer'] != null
            ? FooterConfig.fromJson(Map<String, dynamic>.from(json['footer']))
            : FooterConfig.defaultConfig(),
        sectionOrder: json['sectionOrder'] != null
            ? List<String>.from(json['sectionOrder'])
            : const ['hero', 'stats', 'banners', 'test_series', 'features', 'cta_banner', 'footer'],
        primaryColorHex: json['primaryColorHex'] ?? '4F46E5',
        accentColorHex: json['accentColorHex'] ?? '7C3AED',
        enableAnimations: json['enableAnimations'] ?? true,
        updatedAtTimestamp: json['updatedAtTimestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('Error parsing LandingPageConfigModel from json: $e');
      return LandingPageConfigModel.defaultConfig();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'header': header.toJson(),
      'hero': hero.toJson(),
      'stats': stats.toJson(),
      'banners': banners.toJson(),
      'testSeries': testSeries.toJson(),
      'features': features.toJson(),
      'ctaBanner': ctaBanner.toJson(),
      'footer': footer.toJson(),
      'sectionOrder': sectionOrder,
      'primaryColorHex': primaryColorHex,
      'accentColorHex': accentColorHex,
      'enableAnimations': enableAnimations,
      'updatedAtTimestamp': updatedAtTimestamp,
    };
  }

  LandingPageConfigModel copyWith({
    HeaderConfig? header,
    HeroSectionConfig? hero,
    StatsSectionConfig? stats,
    BannersSectionConfig? banners,
    TestSeriesSectionConfig? testSeries,
    FeaturesSectionConfig? features,
    CtaBannerConfig? ctaBanner,
    FooterConfig? footer,
    List<String>? sectionOrder,
    String? primaryColorHex,
    String? accentColorHex,
    bool? enableAnimations,
    int? updatedAtTimestamp,
  }) {
    return LandingPageConfigModel(
      header: header ?? this.header,
      hero: hero ?? this.hero,
      stats: stats ?? this.stats,
      banners: banners ?? this.banners,
      testSeries: testSeries ?? this.testSeries,
      features: features ?? this.features,
      ctaBanner: ctaBanner ?? this.ctaBanner,
      footer: footer ?? this.footer,
      sectionOrder: sectionOrder ?? this.sectionOrder,
      primaryColorHex: primaryColorHex ?? this.primaryColorHex,
      accentColorHex: accentColorHex ?? this.accentColorHex,
      enableAnimations: enableAnimations ?? this.enableAnimations,
      updatedAtTimestamp: updatedAtTimestamp ?? this.updatedAtTimestamp,
    );
  }
}

// ==================== SUB-CONFIGS ====================

class HeaderConfig {
  final String logoUrl;
  final String brandName;
  final bool stickyHeader;
  final String announcementBarText;
  final bool showAnnouncementBar;
  final String loginButtonLabel;
  final String signupButtonLabel;
  final List<NavItemConfig> navItems;

  const HeaderConfig({
    required this.logoUrl,
    required this.brandName,
    required this.stickyHeader,
    required this.announcementBarText,
    required this.showAnnouncementBar,
    required this.loginButtonLabel,
    required this.signupButtonLabel,
    required this.navItems,
  });

  factory HeaderConfig.defaultConfig() {
    return const HeaderConfig(
      logoUrl: '',
      brandName: 'Cosmyra NEET | JEE',
      stickyHeader: true,
      announcementBarText: '🚀 Early Bird Offer: Up to 85% OFF on NEET & JEE 2026 Test Series!',
      showAnnouncementBar: true,
      loginButtonLabel: 'Log In',
      signupButtonLabel: 'Get Started Free',
      navItems: [
        NavItemConfig(id: 'home', label: 'Home', destination: '/', isVisible: true),
        NavItemConfig(id: 'practice', label: 'Practice', destination: '/practice', featureKey: 'custom_practice', isVisible: true),
        NavItemConfig(id: 'tests', label: 'Tests', destination: '/tests', featureKey: 'custom_test', isVisible: true),
        NavItemConfig(id: 'pyq', label: 'PYQ', destination: '/pyq', featureKey: 'pyq_practice', isVisible: true),
        NavItemConfig(id: 'test-series', label: 'Test Series', destination: '/test-series', featureKey: 'test_series', isVisible: true),
        NavItemConfig(id: 'blog', label: 'Blog', destination: '/blog', isVisible: true),
        NavItemConfig(id: 'about', label: 'About Us', destination: '/about', isVisible: true),
      ],
    );
  }

  factory HeaderConfig.fromJson(Map<String, dynamic> json) {
    return HeaderConfig(
      logoUrl: json['logoUrl'] ?? '',
      brandName: json['brandName'] ?? 'Cosmyra NEET | JEE',
      stickyHeader: json['stickyHeader'] ?? true,
      announcementBarText: json['announcementBarText'] ?? '🚀 Early Bird Offer: Up to 85% OFF on NEET & JEE 2026 Test Series!',
      showAnnouncementBar: json['showAnnouncementBar'] ?? true,
      loginButtonLabel: json['loginButtonLabel'] ?? 'Log In',
      signupButtonLabel: json['signupButtonLabel'] ?? 'Get Started Free',
      navItems: json['navItems'] != null
          ? (json['navItems'] as List).map((e) => NavItemConfig.fromJson(Map<String, dynamic>.from(e))).toList()
          : HeaderConfig.defaultConfig().navItems,
    );
  }

  Map<String, dynamic> toJson() => {
        'logoUrl': logoUrl,
        'brandName': brandName,
        'stickyHeader': stickyHeader,
        'announcementBarText': announcementBarText,
        'showAnnouncementBar': showAnnouncementBar,
        'loginButtonLabel': loginButtonLabel,
        'signupButtonLabel': signupButtonLabel,
        'navItems': navItems.map((e) => e.toJson()).toList(),
      };
}

class NavItemConfig {
  final String id;
  final String label;
  final String destination;
  final String? featureKey;
  final bool isVisible;

  const NavItemConfig({
    required this.id,
    required this.label,
    required this.destination,
    this.featureKey,
    required this.isVisible,
  });

  factory NavItemConfig.fromJson(Map<String, dynamic> json) {
    return NavItemConfig(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      destination: json['destination'] ?? '',
      featureKey: json['featureKey'],
      isVisible: json['isVisible'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'destination': destination,
        'featureKey': featureKey,
        'isVisible': isVisible,
      };
}

class HeroSectionConfig {
  final bool isVisible;
  final String trustBadgeText;
  final bool showTrustBadge;
  final String headlineText;
  final String descriptionText;
  final String primaryButtonLabel;
  final String primaryButtonDestination;
  final String secondaryButtonLabel;
  final String secondaryButtonDestination;
  final String heroImageUrl;
  final String heroMobileImageUrl;
  final String layoutTemplate; // 'HERO_SPLIT_LEFT', 'HERO_CENTERED', 'HERO_SPLIT_RIGHT'
  final String studentCountText;
  final bool showFloatingCards;

  const HeroSectionConfig({
    required this.isVisible,
    required this.trustBadgeText,
    required this.showTrustBadge,
    required this.headlineText,
    required this.descriptionText,
    required this.primaryButtonLabel,
    required this.primaryButtonDestination,
    required this.secondaryButtonLabel,
    required this.secondaryButtonDestination,
    required this.heroImageUrl,
    required this.heroMobileImageUrl,
    required this.layoutTemplate,
    required this.studentCountText,
    required this.showFloatingCards,
  });

  factory HeroSectionConfig.defaultConfig() {
    return const HeroSectionConfig(
      isVisible: true,
      trustBadgeText: "⭐ India's Most Trusted Exam Preparation Platform",
      showTrustBadge: true,
      headlineText: 'Master NEET & JEE with All-India Test Series',
      descriptionText: 'Target NEET 2026 & JEE 2026 with 500+ Chapter Tests, 15-Year PYQ Archives & Real-time AI Error Analytics.',
      primaryButtonLabel: 'Start Practicing Now',
      primaryButtonDestination: '/signup',
      secondaryButtonLabel: 'Explore Test Series',
      secondaryButtonDestination: '/test-series',
      heroImageUrl: '',
      heroMobileImageUrl: '',
      layoutTemplate: 'HERO_SPLIT_LEFT',
      studentCountText: 'Join 50,000+ aspirants preparing smarter every day!',
      showFloatingCards: true,
    );
  }

  factory HeroSectionConfig.fromJson(Map<String, dynamic> json) {
    return HeroSectionConfig(
      isVisible: json['isVisible'] ?? true,
      trustBadgeText: json['trustBadgeText'] ?? "⭐ India's Most Trusted Exam Preparation Platform",
      showTrustBadge: json['showTrustBadge'] ?? true,
      headlineText: json['headlineText'] ?? 'Master NEET & JEE with All-India Test Series',
      descriptionText: json['descriptionText'] ?? 'Target NEET 2026 & JEE 2026 with 500+ Chapter Tests, 15-Year PYQ Archives & Real-time AI Error Analytics.',
      primaryButtonLabel: json['primaryButtonLabel'] ?? 'Start Practicing Now',
      primaryButtonDestination: json['primaryButtonDestination'] ?? '/signup',
      secondaryButtonLabel: json['secondaryButtonLabel'] ?? 'Explore Test Series',
      secondaryButtonDestination: json['secondaryButtonDestination'] ?? '/test-series',
      heroImageUrl: json['heroImageUrl'] ?? '',
      heroMobileImageUrl: json['heroMobileImageUrl'] ?? '',
      layoutTemplate: json['layoutTemplate'] ?? 'HERO_SPLIT_LEFT',
      studentCountText: json['studentCountText'] ?? 'Join 50,000+ aspirants preparing smarter every day!',
      showFloatingCards: json['showFloatingCards'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'isVisible': isVisible,
        'trustBadgeText': trustBadgeText,
        'showTrustBadge': showTrustBadge,
        'headlineText': headlineText,
        'descriptionText': descriptionText,
        'primaryButtonLabel': primaryButtonLabel,
        'primaryButtonDestination': primaryButtonDestination,
        'secondaryButtonLabel': secondaryButtonLabel,
        'secondaryButtonDestination': secondaryButtonDestination,
        'heroImageUrl': heroImageUrl,
        'heroMobileImageUrl': heroMobileImageUrl,
        'layoutTemplate': layoutTemplate,
        'studentCountText': studentCountText,
        'showFloatingCards': showFloatingCards,
      };
}

class StatsSectionConfig {
  final bool isVisible;
  final List<StatCardConfig> statsList;

  const StatsSectionConfig({
    required this.isVisible,
    required this.statsList,
  });

  factory StatsSectionConfig.defaultConfig() {
    return const StatsSectionConfig(
      isVisible: true,
      statsList: [
        StatCardConfig(id: 'students', value: '50,000+', label: 'Active Students', icon: 'groups_rounded', isVisible: true),
        StatCardConfig(id: 'tests', value: '500+', label: 'Full Length Tests', icon: 'assignment_rounded', isVisible: true),
        StatCardConfig(id: 'pyqs', value: '15+ Yrs', label: 'NTA PYQ Banks', icon: 'history_edu_rounded', isVisible: true),
        StatCardConfig(id: 'satisfaction', value: '98%', label: 'Satisfaction Rate', icon: 'sentiment_very_satisfied_rounded', isVisible: true),
      ],
    );
  }

  factory StatsSectionConfig.fromJson(Map<String, dynamic> json) {
    return StatsSectionConfig(
      isVisible: json['isVisible'] ?? true,
      statsList: json['statsList'] != null
          ? (json['statsList'] as List).map((e) => StatCardConfig.fromJson(Map<String, dynamic>.from(e))).toList()
          : StatsSectionConfig.defaultConfig().statsList,
    );
  }

  Map<String, dynamic> toJson() => {
        'isVisible': isVisible,
        'statsList': statsList.map((e) => e.toJson()).toList(),
      };
}

class StatCardConfig {
  final String id;
  final String value;
  final String label;
  final String icon;
  final bool isVisible;

  const StatCardConfig({
    required this.id,
    required this.value,
    required this.label,
    required this.icon,
    required this.isVisible,
  });

  factory StatCardConfig.fromJson(Map<String, dynamic> json) {
    return StatCardConfig(
      id: json['id'] ?? '',
      value: json['value'] ?? '',
      label: json['label'] ?? '',
      icon: json['icon'] ?? 'star_rounded',
      isVisible: json['isVisible'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'value': value,
        'label': label,
        'icon': icon,
        'isVisible': isVisible,
      };
}

class BannersSectionConfig {
  final bool isVisible;
  final String sectionTitle;
  final String sectionSubtitle;
  final bool carouselAutoPlay;
  final int carouselIntervalSeconds;

  const BannersSectionConfig({
    required this.isVisible,
    required this.sectionTitle,
    required this.sectionSubtitle,
    required this.carouselAutoPlay,
    required this.carouselIntervalSeconds,
  });

  factory BannersSectionConfig.defaultConfig() {
    return const BannersSectionConfig(
      isVisible: true,
      sectionTitle: 'Promotional Banners & Announcements',
      sectionSubtitle: 'Special offers, live mock test events & updates',
      carouselAutoPlay: true,
      carouselIntervalSeconds: 4,
    );
  }

  factory BannersSectionConfig.fromJson(Map<String, dynamic> json) {
    return BannersSectionConfig(
      isVisible: json['isVisible'] ?? true,
      sectionTitle: json['sectionTitle'] ?? 'Promotional Banners & Announcements',
      sectionSubtitle: json['sectionSubtitle'] ?? 'Special offers, live mock test events & updates',
      carouselAutoPlay: json['carouselAutoPlay'] ?? true,
      carouselIntervalSeconds: json['carouselIntervalSeconds'] ?? 4,
    );
  }

  Map<String, dynamic> toJson() => {
        'isVisible': isVisible,
        'sectionTitle': sectionTitle,
        'sectionSubtitle': sectionSubtitle,
        'carouselAutoPlay': carouselAutoPlay,
        'carouselIntervalSeconds': carouselIntervalSeconds,
      };
}

class TestSeriesSectionConfig {
  final bool isVisible;
  final String sectionTitle;
  final String sectionSubtitle;
  final int maxItemsToShow;
  final String layoutTemplate; // 'GRID', 'CAROUSEL'

  const TestSeriesSectionConfig({
    required this.isVisible,
    required this.sectionTitle,
    required this.sectionSubtitle,
    required this.maxItemsToShow,
    required this.layoutTemplate,
  });

  factory TestSeriesSectionConfig.defaultConfig() {
    return const TestSeriesSectionConfig(
      isVisible: true,
      sectionTitle: 'Recommended Test Series',
      sectionSubtitle: 'Curated by Top NEET & JEE Educators',
      maxItemsToShow: 6,
      layoutTemplate: 'GRID',
    );
  }

  factory TestSeriesSectionConfig.fromJson(Map<String, dynamic> json) {
    return TestSeriesSectionConfig(
      isVisible: json['isVisible'] ?? true,
      sectionTitle: json['sectionTitle'] ?? 'Recommended Test Series',
      sectionSubtitle: json['sectionSubtitle'] ?? 'Curated by Top NEET & JEE Educators',
      maxItemsToShow: json['maxItemsToShow'] ?? 6,
      layoutTemplate: json['layoutTemplate'] ?? 'GRID',
    );
  }

  Map<String, dynamic> toJson() => {
        'isVisible': isVisible,
        'sectionTitle': sectionTitle,
        'sectionSubtitle': sectionSubtitle,
        'maxItemsToShow': maxItemsToShow,
        'layoutTemplate': layoutTemplate,
      };
}

class FeaturesSectionConfig {
  final bool isVisible;
  final String badgeText;
  final String sectionTitle;
  final String sectionSubtitle;
  final List<LandingFeatureCardConfig> features;

  const FeaturesSectionConfig({
    required this.isVisible,
    required this.badgeText,
    required this.sectionTitle,
    required this.sectionSubtitle,
    required this.features,
  });

  factory FeaturesSectionConfig.defaultConfig() {
    return const FeaturesSectionConfig(
      isVisible: true,
      badgeText: 'EVERYTHING YOU NEED TO SUCCEED',
      sectionTitle: 'Powerful Features for Every Aspirant',
      sectionSubtitle: 'All the tools you need to plan, practice, analyze and improve your performance.',
      features: [
        LandingFeatureCardConfig(
          id: 'custom_practice',
          featureKey: 'custom_practice',
          title: 'Custom Chapter Practice',
          description: 'Practice questions from specific subjects, chapters & topics of your choice.',
          icon: 'tune_rounded',
          badge: '',
          isVisible: true,
        ),
        LandingFeatureCardConfig(
          id: 'test_series',
          featureKey: 'custom_test',
          title: 'NTA Level Test Engine',
          description: 'Create tests with custom time limit, negative marking & full video solutions.',
          icon: 'assignment_turned_in_rounded',
          badge: '',
          isVisible: true,
        ),
        LandingFeatureCardConfig(
          id: 'pyq_practice',
          featureKey: 'pyq_practice',
          title: '15-Year PYQ Archives',
          description: 'Practice previous year questions and official NTA questions chapter-wise.',
          icon: 'auto_stories_rounded',
          badge: '',
          isVisible: true,
        ),
        LandingFeatureCardConfig(
          id: 'ai_radar',
          featureKey: 'ai_analytics',
          title: 'AI Performance Radar',
          description: 'Detailed weakness analysis, accuracy trends and topic mastery score.',
          icon: 'analytics_rounded',
          badge: 'AI POWERED',
          isVisible: true,
        ),
        LandingFeatureCardConfig(
          id: 'bookmarks',
          featureKey: 'bookmarks',
          title: 'Smart Revision Bookmarks',
          description: 'Bookmark tricky questions and revise them anytime with instant solutions.',
          icon: 'bookmark_rounded',
          badge: '',
          isVisible: true,
        ),
        LandingFeatureCardConfig(
          id: 'leaderboard',
          featureKey: 'leaderboard',
          title: 'All-India Leaderboards',
          description: 'Compete with 50,000+ aspirants and track your real AIR percentile rank.',
          icon: 'emoji_events_rounded',
          badge: '',
          isVisible: true,
        ),
      ],
    );
  }

  factory FeaturesSectionConfig.fromJson(Map<String, dynamic> json) {
    return FeaturesSectionConfig(
      isVisible: json['isVisible'] ?? true,
      badgeText: json['badgeText'] ?? 'EVERYTHING YOU NEED TO SUCCEED',
      sectionTitle: json['sectionTitle'] ?? 'Powerful Features for Every Aspirant',
      sectionSubtitle: json['sectionSubtitle'] ?? 'All the tools you need to plan, practice, analyze and improve your performance.',
      features: json['features'] != null
          ? (json['features'] as List).map((e) => LandingFeatureCardConfig.fromJson(Map<String, dynamic>.from(e))).toList()
          : FeaturesSectionConfig.defaultConfig().features,
    );
  }

  Map<String, dynamic> toJson() => {
        'isVisible': isVisible,
        'badgeText': badgeText,
        'sectionTitle': sectionTitle,
        'sectionSubtitle': sectionSubtitle,
        'features': features.map((e) => e.toJson()).toList(),
      };
}

class LandingFeatureCardConfig {
  final String id;
  final String? featureKey;
  final String title;
  final String description;
  final String icon;
  final String badge;
  final bool isVisible;

  const LandingFeatureCardConfig({
    required this.id,
    this.featureKey,
    required this.title,
    required this.description,
    required this.icon,
    required this.badge,
    required this.isVisible,
  });

  factory LandingFeatureCardConfig.fromJson(Map<String, dynamic> json) {
    return LandingFeatureCardConfig(
      id: json['id'] ?? '',
      featureKey: json['featureKey'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? 'star_rounded',
      badge: json['badge'] ?? '',
      isVisible: json['isVisible'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'featureKey': featureKey,
        'title': title,
        'description': description,
        'icon': icon,
        'badge': badge,
        'isVisible': isVisible,
      };
}

class CtaBannerConfig {
  final bool isVisible;
  final String title;
  final String description;
  final String buttonLabel;
  final String buttonDestination;
  final String backgroundGradient;

  const CtaBannerConfig({
    required this.isVisible,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.buttonDestination,
    required this.backgroundGradient,
  });

  factory CtaBannerConfig.defaultConfig() {
    return const CtaBannerConfig(
      isVisible: true,
      title: 'New to Cosmyra NEET | JEE?',
      description: 'Create your free account today and get instant access to free mock tests, PYQ banks & AI analytics.',
      buttonLabel: 'Create Free Account',
      buttonDestination: '/signup',
      backgroundGradient: 'PURPLE_BLUE',
    );
  }

  factory CtaBannerConfig.fromJson(Map<String, dynamic> json) {
    return CtaBannerConfig(
      isVisible: json['isVisible'] ?? true,
      title: json['title'] ?? 'New to Cosmyra NEET | JEE?',
      description: json['description'] ?? 'Create your free account today and get instant access to free mock tests, PYQ banks & AI analytics.',
      buttonLabel: json['buttonLabel'] ?? 'Create Free Account',
      buttonDestination: json['buttonDestination'] ?? '/signup',
      backgroundGradient: json['backgroundGradient'] ?? 'PURPLE_BLUE',
    );
  }

  Map<String, dynamic> toJson() => {
        'isVisible': isVisible,
        'title': title,
        'description': description,
        'buttonLabel': buttonLabel,
        'buttonDestination': buttonDestination,
        'backgroundGradient': backgroundGradient,
      };
}

class FooterConfig {
  final bool isVisible;
  final String brandDescription;
  final String copyrightText;
  final List<FooterLinkConfig> footerLinks;

  const FooterConfig({
    required this.isVisible,
    required this.brandDescription,
    required this.copyrightText,
    required this.footerLinks,
  });

  factory FooterConfig.defaultConfig() {
    return const FooterConfig(
      isVisible: true,
      brandDescription: "Cosmyra Technologies — India's premier AI-powered exam preparation platform for NEET & JEE.",
      copyrightText: '© 2026 Cosmyra Technologies Pvt. Ltd. All rights reserved.',
      footerLinks: [
        FooterLinkConfig(label: 'Home', destination: '/'),
        FooterLinkConfig(label: 'About Us', destination: '/about'),
        FooterLinkConfig(label: 'Blog & Insights', destination: '/blog'),
        FooterLinkConfig(label: 'Privacy Policy', destination: '/privacy-policy'),
        FooterLinkConfig(label: 'Terms of Service', destination: '/terms'),
        FooterLinkConfig(label: 'Refund Policy', destination: '/refund-policy'),
        FooterLinkConfig(label: 'FAQ', destination: '/faq'),
        FooterLinkConfig(label: 'Contact Us', destination: '/contact'),
      ],
    );
  }

  factory FooterConfig.fromJson(Map<String, dynamic> json) {
    return FooterConfig(
      isVisible: json['isVisible'] ?? true,
      brandDescription: json['brandDescription'] ?? "Cosmyra Technologies — India's premier AI-powered exam preparation platform for NEET & JEE.",
      copyrightText: json['copyrightText'] ?? '© 2026 Cosmyra Technologies Pvt. Ltd. All rights reserved.',
      footerLinks: json['footerLinks'] != null
          ? (json['footerLinks'] as List).map((e) => FooterLinkConfig.fromJson(Map<String, dynamic>.from(e))).toList()
          : FooterConfig.defaultConfig().footerLinks,
    );
  }

  Map<String, dynamic> toJson() => {
        'isVisible': isVisible,
        'brandDescription': brandDescription,
        'copyrightText': copyrightText,
        'footerLinks': footerLinks.map((e) => e.toJson()).toList(),
      };
}

class FooterLinkConfig {
  final String label;
  final String destination;

  const FooterLinkConfig({
    required this.label,
    required this.destination,
  });

  factory FooterLinkConfig.fromJson(Map<String, dynamic> json) {
    return FooterLinkConfig(
      label: json['label'] ?? '',
      destination: json['destination'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'destination': destination,
      };
}
