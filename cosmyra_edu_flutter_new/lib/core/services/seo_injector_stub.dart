import '../../models/models.dart';

/// Non-web stub implementation of SEO DOM injector
void applyWebSeo({
  required String title,
  required String description,
  required String keywords,
  required String canonicalUrl,
  required bool robotsIndex,
  required bool robotsFollow,
  required String ogTitle,
  required String ogDescription,
  required String ogImageUrl,
  required String twitterTitle,
  required String twitterDescription,
  required String twitterImageUrl,
  String? jsonLd,
}) {
  // No-op on mobile/desktop
}

void applyWebTrackingAndScripts(SeoGlobalSettingsModel settings, List<SeoCustomScriptModel> customScripts) {
  // No-op on mobile/desktop
}
