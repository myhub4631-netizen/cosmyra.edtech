import 'package:flutter/foundation.dart';
import '../../models/models.dart';
import 'supabase_service.dart';
import 'seo_injector_stub.dart'
    if (dart.library.html) 'seo_injector_web.dart' as injector;

class SeoTrackingService {
  static SeoGlobalSettingsModel? _cachedSettings;
  static bool _hasInjectedGlobalScripts = false;

  /// Initializes global SEO settings, GA4, GSC, AdSense, and custom scripts on app start
  static Future<void> initialize() async {
    try {
      final settings = await SupabaseService.fetchSeoGlobalSettings();
      _cachedSettings = settings;

      // Apply initial global meta tags to Web DOM
      applyGlobalSeo();

      // Fetch and inject scripts
      if (kIsWeb && !_hasInjectedGlobalScripts) {
        final scripts = await SupabaseService.fetchSeoCustomScripts();
        injector.applyWebTrackingAndScripts(settings, scripts);
        _hasInjectedGlobalScripts = true;
      }
    } catch (e) {
      debugPrint('SeoTrackingService init warning: $e');
    }
  }

  /// Refreshes and re-applies all tracking and custom scripts (e.g. after admin saves changes)
  static Future<void> refreshTracking() async {
    try {
      final settings = await SupabaseService.fetchSeoGlobalSettings();
      _cachedSettings = settings;
      final scripts = await SupabaseService.fetchSeoCustomScripts();
      if (kIsWeb) {
        injector.applyWebTrackingAndScripts(settings, scripts);
      }
    } catch (e) {
      debugPrint('Error refreshing tracking: $e');
    }
  }

  /// Applies default global SEO metadata
  static void applyGlobalSeo() {
    final s = _cachedSettings ?? SeoGlobalSettingsModel();
    if (kIsWeb) {
      injector.applyWebSeo(
        title: s.defaultMetaTitle.isNotEmpty ? s.defaultMetaTitle : s.websiteTitle,
        description: s.defaultMetaDescription,
        keywords: s.defaultKeywords,
        canonicalUrl: s.canonicalBaseUrl,
        robotsIndex: true,
        robotsFollow: true,
        ogTitle: s.defaultOgTitle.isNotEmpty ? s.defaultOgTitle : s.defaultMetaTitle,
        ogDescription: s.defaultOgDescription.isNotEmpty ? s.defaultOgDescription : s.defaultMetaDescription,
        ogImageUrl: s.defaultOgImage,
        twitterTitle: s.defaultOgTitle,
        twitterDescription: s.defaultOgDescription,
        twitterImageUrl: s.defaultOgImage,
      );
    }
  }

  /// Dynamically updates SEO tags for a specific CMS Page
  static void applyPageSeo(CmsPageModel page) {
    final s = _cachedSettings ?? SeoGlobalSettingsModel();
    final effectiveTitle = page.seoTitle != null && page.seoTitle!.isNotEmpty
        ? page.seoTitle!
        : '${page.title} | ${s.siteName}';
    final effectiveDesc = page.metaDescription != null && page.metaDescription!.isNotEmpty
        ? page.metaDescription!
        : s.defaultMetaDescription;
    final effectiveCanonical = page.canonicalUrl != null && page.canonicalUrl!.isNotEmpty
        ? page.canonicalUrl!
        : '${s.canonicalBaseUrl}/pages/${page.slug}';
    final effectiveOgImage = page.ogImageUrl != null && page.ogImageUrl!.isNotEmpty
        ? page.ogImageUrl!
        : (page.featuredImageUrl ?? s.defaultOgImage);

    if (kIsWeb) {
      injector.applyWebSeo(
        title: effectiveTitle,
        description: effectiveDesc,
        keywords: s.defaultKeywords,
        canonicalUrl: effectiveCanonical,
        robotsIndex: page.robotsIndex,
        robotsFollow: page.robotsFollow,
        ogTitle: page.ogTitle?.isNotEmpty == true ? page.ogTitle! : effectiveTitle,
        ogDescription: page.ogDescription?.isNotEmpty == true ? page.ogDescription! : effectiveDesc,
        ogImageUrl: effectiveOgImage,
        twitterTitle: page.twitterTitle?.isNotEmpty == true ? page.twitterTitle! : effectiveTitle,
        twitterDescription: page.twitterDescription?.isNotEmpty == true ? page.twitterDescription! : effectiveDesc,
        twitterImageUrl: page.twitterImageUrl?.isNotEmpty == true ? page.twitterImageUrl! : effectiveOgImage,
        jsonLd: page.schemaJsonLd,
      );
    }
  }

  /// Dynamically updates SEO tags for a specific Blog Post
  static void applyBlogSeo(CmsBlogPostModel post) {
    final s = _cachedSettings ?? SeoGlobalSettingsModel();
    final effectiveTitle = post.seoTitle != null && post.seoTitle!.isNotEmpty
        ? post.seoTitle!
        : '${post.title} | ${s.siteName} Blog';
    final effectiveDesc = post.metaDescription != null && post.metaDescription!.isNotEmpty
        ? post.metaDescription!
        : (post.excerpt ?? s.defaultMetaDescription);
    final effectiveCanonical = post.canonicalUrl != null && post.canonicalUrl!.isNotEmpty
        ? post.canonicalUrl!
        : '${s.canonicalBaseUrl}/blog/${post.slug}';
    final effectiveOgImage = post.ogImageUrl != null && post.ogImageUrl!.isNotEmpty
        ? post.ogImageUrl!
        : (post.featuredImageUrl ?? s.defaultOgImage);

    // Build structured article JSON-LD
    final articleSchema = post.schemaJsonLd != null && post.schemaJsonLd!.isNotEmpty
        ? post.schemaJsonLd!
        : '''{
  "@context": "https://schema.org",
  "@type": "BlogPosting",
  "headline": "${post.title.replaceAll('"', '\\"')}",
  "description": "${effectiveDesc.replaceAll('"', '\\"')}",
  "image": "$effectiveOgImage",
  "author": {
    "@type": "Person",
    "name": "${post.authorName.replaceAll('"', '\\"')}"
  },
  "publisher": {
    "@type": "Organization",
    "name": "${s.organizationName}",
    "logo": {
      "@type": "ImageObject",
      "url": "${s.organizationLogoUrl}"
    }
  },
  "datePublished": "${post.publishedAt?.toIso8601String() ?? post.createdAt.toIso8601String()}",
  "dateModified": "${post.updatedAt.toIso8601String()}"
}''';

    if (kIsWeb) {
      injector.applyWebSeo(
        title: effectiveTitle,
        description: effectiveDesc,
        keywords: '${post.tags.join(', ')}, ${s.defaultKeywords}',
        canonicalUrl: effectiveCanonical,
        robotsIndex: post.robotsIndex,
        robotsFollow: post.robotsFollow,
        ogTitle: post.ogTitle?.isNotEmpty == true ? post.ogTitle! : effectiveTitle,
        ogDescription: post.ogDescription?.isNotEmpty == true ? post.ogDescription! : effectiveDesc,
        ogImageUrl: effectiveOgImage,
        twitterTitle: post.twitterTitle?.isNotEmpty == true ? post.twitterTitle! : effectiveTitle,
        twitterDescription: post.twitterDescription?.isNotEmpty == true ? post.twitterDescription! : effectiveDesc,
        twitterImageUrl: post.twitterImageUrl?.isNotEmpty == true ? post.twitterImageUrl! : effectiveOgImage,
        jsonLd: articleSchema,
      );
    }
  }
}
