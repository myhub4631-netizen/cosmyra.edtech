
/// SEO Global Settings Model
class SeoGlobalSettingsModel {
  final String id;
  final String siteName;
  final String websiteTitle;
  final String defaultMetaTitle;
  final String defaultMetaDescription;
  final String defaultKeywords;
  final String canonicalBaseUrl;
  final String defaultOgTitle;
  final String defaultOgDescription;
  final String defaultOgImage;
  final String twitterCardType; // 'summary', 'summary_large_image'
  final String twitterSiteHandle;
  final String organizationName;
  final String organizationLogoUrl;
  final String organizationContactEmail;
  final String organizationPhone;
  final String robotsTxtContent;
  final bool sitemapXmlEnabled;

  // Google Search Console
  final String gscVerificationMethod; // 'meta_tag', 'html_file', 'dns'
  final String gscVerificationCode;
  final bool gscIsActive;

  // Google Analytics (GA4)
  final String ga4MeasurementId;
  final bool ga4IsEnabled;
  final String ga4Environment; // 'production', 'all'

  // Google Ads
  final String googleAdsConversionId;
  final String googleAdsConversionLabel;
  final bool googleAdsIsEnabled;

  // Google AdSense
  final String adsensePublisherId;
  final bool adsenseIsEnabled;
  final bool adsenseAutoAdsEnabled;
  final String adsenseCustomCode;

  // Custom Code Injection Zones
  final String headCode;
  final bool headCodeEnabled;
  final String bodyStartCode;
  final bool bodyStartCodeEnabled;
  final String bodyEndCode;
  final bool bodyEndCodeEnabled;
  final String footerCode;
  final bool footerCodeEnabled;

  // Google Tag Manager
  final String gtmContainerId;
  final bool gtmIsEnabled;
  final String gtmPlacement; // 'head', 'body'

  // Meta / Facebook Pixel
  final String metaPixelId;
  final bool metaPixelIsEnabled;

  // Bing Webmaster Verification
  final String bingVerificationId;
  final bool bingIsEnabled;

  // Custom CSS & JS
  final String customCss;
  final bool customCssEnabled;
  final String customCssScope; // 'user_facing', 'public_web', 'flutter_web'
  final String customJs;
  final bool customJsEnabled;
  final String customJsScope; // 'user_facing', 'public_web', 'flutter_web'

  // Emergency Control & Versioning
  final bool emergencyKillSwitch;
  final int currentVersion;

  final DateTime updatedAt;
  final String updatedBy;

  SeoGlobalSettingsModel({
    this.id = 'e2d3c4b5-a6b7-4c8d-9e0f-1a2b3c4d5e6f',
    this.siteName = 'Cosmyra NEET JEE',
    this.websiteTitle = 'Cosmyra NEET JEE | India\'s Premier Exam Preparation Platform',
    this.defaultMetaTitle = 'Cosmyra NEET JEE - Practice Today, Achieve Tomorrow',
    this.defaultMetaDescription = 'Cosmyra NEET JEE provides comprehensive online exam prep with high-yield question banks, full-length mock tests, detailed analytics, and expert-crafted study materials.',
    this.defaultKeywords = 'NEET 2026, JEE 2026, NEET preparation, JEE Main, mock tests, question bank, test series, Cosmyra',
    this.canonicalBaseUrl = 'https://neet-jee.in',
    this.defaultOgTitle = 'Cosmyra NEET JEE | Ace Your Medical & Engineering Entrance',
    this.defaultOgDescription = 'Join thousands of students cracking NEET & JEE with Cosmyra\'s AI-powered practice engine and top faculty test series.',
    this.defaultOgImage = 'https://neet-jee.in/icons/Icon-512.png',
    this.twitterCardType = 'summary_large_image',
    this.twitterSiteHandle = '@cosmyra_edu',
    this.organizationName = 'Cosmyra Technologies Pvt. Ltd.',
    this.organizationLogoUrl = 'https://neet-jee.in/assets/images/cosmyra_logo.png',
    this.organizationContactEmail = 'support@neet-jee.in',
    this.organizationPhone = '+91 98765 43210',
    this.robotsTxtContent = '''User-agent: *
Allow: /
Disallow: /admin/
Disallow: /superadmin/
Disallow: /api/

Sitemap: https://neet-jee.in/sitemap.xml''',
    this.sitemapXmlEnabled = true,
    this.gscVerificationMethod = 'meta_tag',
    this.gscVerificationCode = 'U3bHrqMV9245aSAvvNJxbuheY1mOPNFDfXZkGbEvHys',
    this.gscIsActive = true,
    this.ga4MeasurementId = '',
    this.ga4IsEnabled = false,
    this.ga4Environment = 'production',
    this.gtmContainerId = '',
    this.gtmIsEnabled = false,
    this.gtmPlacement = 'head',
    this.googleAdsConversionId = '',
    this.googleAdsConversionLabel = '',
    this.googleAdsIsEnabled = false,
    this.adsensePublisherId = '',
    this.adsenseIsEnabled = false,
    this.adsenseAutoAdsEnabled = false,
    this.adsenseCustomCode = '',
    this.metaPixelId = '',
    this.metaPixelIsEnabled = false,
    this.bingVerificationId = '',
    this.bingIsEnabled = false,
    this.headCode = '',
    this.headCodeEnabled = false,
    this.bodyStartCode = '',
    this.bodyStartCodeEnabled = false,
    this.bodyEndCode = '',
    this.bodyEndCodeEnabled = false,
    this.footerCode = '',
    this.footerCodeEnabled = false,
    this.customCss = '',
    this.customCssEnabled = false,
    this.customCssScope = 'user_facing',
    this.customJs = '',
    this.customJsEnabled = false,
    this.customJsScope = 'user_facing',
    this.emergencyKillSwitch = false,
    this.currentVersion = 1,
    DateTime? updatedAt,
    this.updatedBy = 'Cosmyra Superadmin',
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory SeoGlobalSettingsModel.fromJson(Map<String, dynamic> json) {
    return SeoGlobalSettingsModel(
      id: json['id']?.toString() ?? 'e2d3c4b5-a6b7-4c8d-9e0f-1a2b3c4d5e6f',
      siteName: json['site_name']?.toString() ?? 'Cosmyra NEET JEE',
      websiteTitle: json['website_title']?.toString() ?? 'Cosmyra NEET JEE | India\'s Premier Exam Preparation Platform',
      defaultMetaTitle: json['default_meta_title']?.toString() ?? 'Cosmyra NEET JEE - Practice Today, Achieve Tomorrow',
      defaultMetaDescription: json['default_meta_description']?.toString() ?? '',
      defaultKeywords: json['default_keywords']?.toString() ?? '',
      canonicalBaseUrl: json['canonical_base_url']?.toString() ?? 'https://neet-jee.in',
      defaultOgTitle: json['default_og_title']?.toString() ?? '',
      defaultOgDescription: json['default_og_description']?.toString() ?? '',
      defaultOgImage: json['default_og_image']?.toString() ?? '',
      twitterCardType: json['twitter_card_type']?.toString() ?? 'summary_large_image',
      twitterSiteHandle: json['twitter_site_handle']?.toString() ?? '@cosmyra_edu',
      organizationName: json['organization_name']?.toString() ?? 'Cosmyra Technologies Pvt. Ltd.',
      organizationLogoUrl: json['organization_logo_url']?.toString() ?? '',
      organizationContactEmail: json['organization_contact_email']?.toString() ?? '',
      organizationPhone: json['organization_phone']?.toString() ?? '',
      robotsTxtContent: json['robots_txt_content']?.toString() ?? '',
      sitemapXmlEnabled: json['sitemap_xml_enabled'] != false,
      gscVerificationMethod: json['gsc_verification_method']?.toString() ?? 'meta_tag',
      gscVerificationCode: json['gsc_verification_code']?.toString() ?? '',
      gscIsActive: json['gsc_is_active'] != false,
      ga4MeasurementId: json['ga4_measurement_id']?.toString() ?? '',
      ga4IsEnabled: json['ga4_is_enabled'] == true,
      ga4Environment: json['ga4_environment']?.toString() ?? 'production',
      gtmContainerId: json['gtm_container_id']?.toString() ?? '',
      gtmIsEnabled: json['gtm_is_enabled'] == true,
      gtmPlacement: json['gtm_placement']?.toString() ?? 'head',
      googleAdsConversionId: json['google_ads_conversion_id']?.toString() ?? '',
      googleAdsConversionLabel: json['google_ads_conversion_label']?.toString() ?? '',
      googleAdsIsEnabled: json['google_ads_is_enabled'] == true,
      adsensePublisherId: json['adsense_publisher_id']?.toString() ?? '',
      adsenseIsEnabled: json['adsense_is_enabled'] == true,
      adsenseAutoAdsEnabled: json['adsense_auto_ads_enabled'] == true,
      adsenseCustomCode: json['adsense_custom_code']?.toString() ?? '',
      metaPixelId: json['meta_pixel_id']?.toString() ?? '',
      metaPixelIsEnabled: json['meta_pixel_is_enabled'] == true,
      bingVerificationId: json['bing_verification_id']?.toString() ?? '',
      bingIsEnabled: json['bing_is_enabled'] == true,
      headCode: json['head_code']?.toString() ?? '',
      headCodeEnabled: json['head_code_enabled'] == true,
      bodyStartCode: json['body_start_code']?.toString() ?? '',
      bodyStartCodeEnabled: json['body_start_code_enabled'] == true,
      bodyEndCode: json['body_end_code']?.toString() ?? '',
      bodyEndCodeEnabled: json['body_end_code_enabled'] == true,
      footerCode: json['footer_code']?.toString() ?? '',
      footerCodeEnabled: json['footer_code_enabled'] == true,
      customCss: json['custom_css']?.toString() ?? '',
      customCssEnabled: json['custom_css_enabled'] == true,
      customCssScope: json['custom_css_scope']?.toString() ?? 'user_facing',
      customJs: json['custom_js']?.toString() ?? '',
      customJsEnabled: json['custom_js_enabled'] == true,
      customJsScope: json['custom_js_scope']?.toString() ?? 'user_facing',
      emergencyKillSwitch: json['emergency_kill_switch'] == true,
      currentVersion: (json['current_version'] as num?)?.toInt() ?? 1,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedBy: json['updated_by']?.toString() ?? 'Cosmyra Superadmin',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'site_name': siteName.trim(),
      'website_title': websiteTitle.trim(),
      'default_meta_title': defaultMetaTitle.trim(),
      'default_meta_description': defaultMetaDescription.trim(),
      'default_keywords': defaultKeywords.trim(),
      'canonical_base_url': canonicalBaseUrl.trim(),
      'default_og_title': defaultOgTitle.trim(),
      'default_og_description': defaultOgDescription.trim(),
      'default_og_image': defaultOgImage.trim(),
      'twitter_card_type': twitterCardType,
      'twitter_site_handle': twitterSiteHandle.trim(),
      'organization_name': organizationName.trim(),
      'organization_logo_url': organizationLogoUrl.trim(),
      'organization_contact_email': organizationContactEmail.trim(),
      'organization_phone': organizationPhone.trim(),
      'robots_txt_content': robotsTxtContent,
      'sitemap_xml_enabled': sitemapXmlEnabled,
      'gsc_verification_method': gscVerificationMethod,
      'gsc_verification_code': gscVerificationCode.trim(),
      'gsc_is_active': gscIsActive,
      'ga4_measurement_id': ga4MeasurementId.trim(),
      'ga4_is_enabled': ga4IsEnabled,
      'ga4_environment': ga4Environment,
      'gtm_container_id': gtmContainerId.trim(),
      'gtm_is_enabled': gtmIsEnabled,
      'gtm_placement': gtmPlacement,
      'google_ads_conversion_id': googleAdsConversionId.trim(),
      'google_ads_conversion_label': googleAdsConversionLabel.trim(),
      'google_ads_is_enabled': googleAdsIsEnabled,
      'adsense_publisher_id': adsensePublisherId.trim(),
      'adsense_is_enabled': adsenseIsEnabled,
      'adsense_auto_ads_enabled': adsenseAutoAdsEnabled,
      'adsense_custom_code': adsenseCustomCode.trim(),
      'meta_pixel_id': metaPixelId.trim(),
      'meta_pixel_is_enabled': metaPixelIsEnabled,
      'bing_verification_id': bingVerificationId.trim(),
      'bing_is_enabled': bingIsEnabled,
      'head_code': headCode,
      'head_code_enabled': headCodeEnabled,
      'body_start_code': bodyStartCode,
      'body_start_code_enabled': bodyStartCodeEnabled,
      'body_end_code': bodyEndCode,
      'body_end_code_enabled': bodyEndCodeEnabled,
      'footer_code': footerCode,
      'footer_code_enabled': footerCodeEnabled,
      'custom_css': customCss,
      'custom_css_enabled': customCssEnabled,
      'custom_css_scope': customCssScope,
      'custom_js': customJs,
      'custom_js_enabled': customJsEnabled,
      'custom_js_scope': customJsScope,
      'emergency_kill_switch': emergencyKillSwitch,
      'current_version': currentVersion,
      'updated_at': DateTime.now().toIso8601String(),
      'updated_by': updatedBy,
    };
  }

  SeoGlobalSettingsModel copyWith({
    String? id,
    String? siteName,
    String? websiteTitle,
    String? defaultMetaTitle,
    String? defaultMetaDescription,
    String? defaultKeywords,
    String? canonicalBaseUrl,
    String? defaultOgTitle,
    String? defaultOgDescription,
    String? defaultOgImage,
    String? twitterCardType,
    String? twitterSiteHandle,
    String? organizationName,
    String? organizationLogoUrl,
    String? organizationContactEmail,
    String? organizationPhone,
    String? robotsTxtContent,
    bool? sitemapXmlEnabled,
    String? gscVerificationMethod,
    String? gscVerificationCode,
    bool? gscIsActive,
    String? ga4MeasurementId,
    bool? ga4IsEnabled,
    String? ga4Environment,
    String? gtmContainerId,
    bool? gtmIsEnabled,
    String? gtmPlacement,
    String? googleAdsConversionId,
    String? googleAdsConversionLabel,
    bool? googleAdsIsEnabled,
    String? adsensePublisherId,
    bool? adsenseIsEnabled,
    bool? adsenseAutoAdsEnabled,
    String? adsenseCustomCode,
    String? metaPixelId,
    bool? metaPixelIsEnabled,
    String? bingVerificationId,
    bool? bingIsEnabled,
    String? headCode,
    bool? headCodeEnabled,
    String? bodyStartCode,
    bool? bodyStartCodeEnabled,
    String? bodyEndCode,
    bool? bodyEndCodeEnabled,
    String? footerCode,
    bool? footerCodeEnabled,
    String? customCss,
    bool? customCssEnabled,
    String? customCssScope,
    String? customJs,
    bool? customJsEnabled,
    String? customJsScope,
    bool? emergencyKillSwitch,
    int? currentVersion,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return SeoGlobalSettingsModel(
      id: id ?? this.id,
      siteName: siteName ?? this.siteName,
      websiteTitle: websiteTitle ?? this.websiteTitle,
      defaultMetaTitle: defaultMetaTitle ?? this.defaultMetaTitle,
      defaultMetaDescription: defaultMetaDescription ?? this.defaultMetaDescription,
      defaultKeywords: defaultKeywords ?? this.defaultKeywords,
      canonicalBaseUrl: canonicalBaseUrl ?? this.canonicalBaseUrl,
      defaultOgTitle: defaultOgTitle ?? this.defaultOgTitle,
      defaultOgDescription: defaultOgDescription ?? this.defaultOgDescription,
      defaultOgImage: defaultOgImage ?? this.defaultOgImage,
      twitterCardType: twitterCardType ?? this.twitterCardType,
      twitterSiteHandle: twitterSiteHandle ?? this.twitterSiteHandle,
      organizationName: organizationName ?? this.organizationName,
      organizationLogoUrl: organizationLogoUrl ?? this.organizationLogoUrl,
      organizationContactEmail: organizationContactEmail ?? this.organizationContactEmail,
      organizationPhone: organizationPhone ?? this.organizationPhone,
      robotsTxtContent: robotsTxtContent ?? this.robotsTxtContent,
      sitemapXmlEnabled: sitemapXmlEnabled ?? this.sitemapXmlEnabled,
      gscVerificationMethod: gscVerificationMethod ?? this.gscVerificationMethod,
      gscVerificationCode: gscVerificationCode ?? this.gscVerificationCode,
      gscIsActive: gscIsActive ?? this.gscIsActive,
      ga4MeasurementId: ga4MeasurementId ?? this.ga4MeasurementId,
      ga4IsEnabled: ga4IsEnabled ?? this.ga4IsEnabled,
      ga4Environment: ga4Environment ?? this.ga4Environment,
      gtmContainerId: gtmContainerId ?? this.gtmContainerId,
      gtmIsEnabled: gtmIsEnabled ?? this.gtmIsEnabled,
      gtmPlacement: gtmPlacement ?? this.gtmPlacement,
      googleAdsConversionId: googleAdsConversionId ?? this.googleAdsConversionId,
      googleAdsConversionLabel: googleAdsConversionLabel ?? this.googleAdsConversionLabel,
      googleAdsIsEnabled: googleAdsIsEnabled ?? this.googleAdsIsEnabled,
      adsensePublisherId: adsensePublisherId ?? this.adsensePublisherId,
      adsenseIsEnabled: adsenseIsEnabled ?? this.adsenseIsEnabled,
      adsenseAutoAdsEnabled: adsenseAutoAdsEnabled ?? this.adsenseAutoAdsEnabled,
      adsenseCustomCode: adsenseCustomCode ?? this.adsenseCustomCode,
      metaPixelId: metaPixelId ?? this.metaPixelId,
      metaPixelIsEnabled: metaPixelIsEnabled ?? this.metaPixelIsEnabled,
      bingVerificationId: bingVerificationId ?? this.bingVerificationId,
      bingIsEnabled: bingIsEnabled ?? this.bingIsEnabled,
      headCode: headCode ?? this.headCode,
      headCodeEnabled: headCodeEnabled ?? this.headCodeEnabled,
      bodyStartCode: bodyStartCode ?? this.bodyStartCode,
      bodyStartCodeEnabled: bodyStartCodeEnabled ?? this.bodyStartCodeEnabled,
      bodyEndCode: bodyEndCode ?? this.bodyEndCode,
      bodyEndCodeEnabled: bodyEndCodeEnabled ?? this.bodyEndCodeEnabled,
      footerCode: footerCode ?? this.footerCode,
      footerCodeEnabled: footerCodeEnabled ?? this.footerCodeEnabled,
      customCss: customCss ?? this.customCss,
      customCssEnabled: customCssEnabled ?? this.customCssEnabled,
      customCssScope: customCssScope ?? this.customCssScope,
      customJs: customJs ?? this.customJs,
      customJsEnabled: customJsEnabled ?? this.customJsEnabled,
      customJsScope: customJsScope ?? this.customJsScope,
      emergencyKillSwitch: emergencyKillSwitch ?? this.emergencyKillSwitch,
      currentVersion: currentVersion ?? this.currentVersion,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}

/// SEO Custom Script Model
class SeoCustomScriptModel {
  final String id;
  final String name;
  final String? description;
  final String code;
  final String placement; // 'head', 'body_start', 'body_end', 'footer'
  final int priorityOrder;
  final String targetScope; // 'all', 'pages_only', 'blogs_only'
  final bool isActive;
  final String environment; // 'production', 'all'
  final DateTime createdAt;
  final DateTime updatedAt;
  final String updatedBy;

  SeoCustomScriptModel({
    required this.id,
    required this.name,
    this.description,
    required this.code,
    this.placement = 'head',
    this.priorityOrder = 0,
    this.targetScope = 'all',
    this.isActive = true,
    this.environment = 'production',
    required this.createdAt,
    required this.updatedAt,
    this.updatedBy = 'Cosmyra Superadmin',
  });

  factory SeoCustomScriptModel.fromJson(Map<String, dynamic> json) {
    return SeoCustomScriptModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      code: json['code']?.toString() ?? '',
      placement: json['placement']?.toString() ?? 'head',
      priorityOrder: (json['priority_order'] as num?)?.toInt() ?? 0,
      targetScope: json['target_scope']?.toString() ?? 'all',
      isActive: json['is_active'] != false,
      environment: json['environment']?.toString() ?? 'production',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedBy: json['updated_by']?.toString() ?? 'Cosmyra Superadmin',
    );
  }

  Map<String, dynamic> toJson({bool forInsert = false}) {
    final map = <String, dynamic>{
      'name': name.trim(),
      'description': description?.trim(),
      'code': code,
      'placement': placement,
      'priority_order': priorityOrder,
      'target_scope': targetScope,
      'is_active': isActive,
      'environment': environment,
      'updated_at': DateTime.now().toIso8601String(),
      'updated_by': updatedBy,
    };
    if (forInsert && id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  SeoCustomScriptModel copyWith({
    String? id,
    String? name,
    String? description,
    String? code,
    String? placement,
    int? priorityOrder,
    String? targetScope,
    bool? isActive,
    String? environment,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return SeoCustomScriptModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      code: code ?? this.code,
      placement: placement ?? this.placement,
      priorityOrder: priorityOrder ?? this.priorityOrder,
      targetScope: targetScope ?? this.targetScope,
      isActive: isActive ?? this.isActive,
      environment: environment ?? this.environment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}

/// SEO Structured Schema (JSON-LD) Model
class SeoSchemaModel {
  final String id;
  final String schemaType; // 'organization', 'website', 'breadcrumb', 'course', 'faq', 'article', 'custom'
  final String name;
  final String jsonLdContent;
  final String? targetPageSlug; // null = global
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  SeoSchemaModel({
    required this.id,
    required this.schemaType,
    required this.name,
    required this.jsonLdContent,
    this.targetPageSlug,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SeoSchemaModel.fromJson(Map<String, dynamic> json) {
    return SeoSchemaModel(
      id: json['id']?.toString() ?? '',
      schemaType: json['schema_type']?.toString() ?? 'custom',
      name: json['name']?.toString() ?? '',
      jsonLdContent: json['json_ld_content']?.toString() ?? '{}',
      targetPageSlug: json['target_page_slug']?.toString(),
      isActive: json['is_active'] != false,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson({bool forInsert = false}) {
    final map = <String, dynamic>{
      'schema_type': schemaType,
      'name': name.trim(),
      'json_ld_content': jsonLdContent,
      'target_page_slug': targetPageSlug?.trim().isEmpty == true ? null : targetPageSlug?.trim(),
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (forInsert && id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  SeoSchemaModel copyWith({
    String? id,
    String? schemaType,
    String? name,
    String? jsonLdContent,
    String? targetPageSlug,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SeoSchemaModel(
      id: id ?? this.id,
      schemaType: schemaType ?? this.schemaType,
      name: name ?? this.name,
      jsonLdContent: jsonLdContent ?? this.jsonLdContent,
      targetPageSlug: targetPageSlug ?? this.targetPageSlug,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// SEO Health Issue Item
class SeoHealthIssue {
  final String type; // 'error', 'warning', 'info'
  final String title;
  final String description;
  final String pageUrl;
  final String suggestion;

  SeoHealthIssue({
    required this.type,
    required this.title,
    required this.description,
    required this.pageUrl,
    required this.suggestion,
  });
}

/// SEO Health Audit Result Model
class SeoHealthAuditModel {
  final int totalPagesChecked;
  final int totalBlogsChecked;
  final int healthScore; // 0 - 100
  final int missingTitlesCount;
  final int missingDescriptionsCount;
  final int missingCanonicalsCount;
  final int missingOgImagesCount;
  final int noindexPagesCount;
  final List<SeoHealthIssue> issues;
  final DateTime auditedAt;

  SeoHealthAuditModel({
    required this.totalPagesChecked,
    required this.totalBlogsChecked,
    required this.healthScore,
    required this.missingTitlesCount,
    required this.missingDescriptionsCount,
    required this.missingCanonicalsCount,
    required this.missingOgImagesCount,
    required this.noindexPagesCount,
    required this.issues,
    required this.auditedAt,
  });
}
