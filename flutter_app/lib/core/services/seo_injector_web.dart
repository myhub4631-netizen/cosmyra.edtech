// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js' as js;
import '../../models/models.dart';

/// Web implementation of SEO DOM injector
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
  try {
    // 1. Title
    if (title.isNotEmpty) {
      html.document.title = title;
    }

    // 2. Meta Tags
    _setMeta('description', description);
    _setMeta('keywords', keywords);

    // Robots
    final robotsValue = '${robotsIndex ? "index" : "noindex"}, ${robotsFollow ? "follow" : "nofollow"}';
    _setMeta('robots', robotsValue);

    // Canonical link
    if (canonicalUrl.isNotEmpty) {
      _setCanonical(canonicalUrl);
    }

    // Open Graph
    _setMetaProperty('og:title', ogTitle.isNotEmpty ? ogTitle : title);
    _setMetaProperty('og:description', ogDescription.isNotEmpty ? ogDescription : description);
    if (ogImageUrl.isNotEmpty) {
      _setMetaProperty('og:image', ogImageUrl);
    }
    if (canonicalUrl.isNotEmpty) {
      _setMetaProperty('og:url', canonicalUrl);
    }

    // Twitter Cards
    _setMeta('twitter:title', twitterTitle.isNotEmpty ? twitterTitle : title);
    _setMeta('twitter:description', twitterDescription.isNotEmpty ? twitterDescription : description);
    if (twitterImageUrl.isNotEmpty) {
      _setMeta('twitter:image', twitterImageUrl);
    }

    // Structured Data JSON-LD
    if (jsonLd != null && jsonLd.trim().isNotEmpty) {
      _setJsonLd('cosmyra-page-schema', jsonLd);
    }
  } catch (e) {
    // Gracefully ignore any DOM security restrictions
  }
}

/// Injects GA4, Google Ads, AdSense, and custom scripts into Web DOM
void applyWebTrackingAndScripts(SeoGlobalSettingsModel settings, List<SeoCustomScriptModel> customScripts) {
  try {
    // 1. Google Search Console Meta Verification
    if (settings.gscIsActive && settings.gscVerificationCode.isNotEmpty) {
      _setMeta('google-site-verification', settings.gscVerificationCode);
    }

    // 2. Google Analytics 4 (GA4)
    if (settings.ga4IsEnabled && settings.ga4MeasurementId.isNotEmpty) {
      _injectGa4(settings.ga4MeasurementId);
    }

    // 3. Google AdSense
    if (settings.adsenseIsEnabled && settings.adsensePublisherId.isNotEmpty) {
      _injectAdSense(settings.adsensePublisherId, settings.adsenseAutoAdsEnabled);
    }

    // 4. Code Injection Zones
    if (settings.headCodeEnabled && settings.headCode.isNotEmpty) {
      _injectRawCode('zone-head-code', settings.headCode, html.document.head);
    }
    if (settings.bodyStartCodeEnabled && settings.bodyStartCode.isNotEmpty) {
      _injectRawCode('zone-body-start-code', settings.bodyStartCode, html.document.body, insertAtStart: true);
    }
    if (settings.bodyEndCodeEnabled && settings.bodyEndCode.isNotEmpty) {
      _injectRawCode('zone-body-end-code', settings.bodyEndCode, html.document.body);
    }
    if (settings.footerCodeEnabled && settings.footerCode.isNotEmpty) {
      _injectRawCode('zone-footer-code', settings.footerCode, html.document.body);
    }

    // 5. Modular Custom Scripts
    for (final s in customScripts.where((s) => s.isActive)) {
      html.Element? target = html.document.head;
      bool insertAtStart = false;
      if (s.placement == 'body_start') {
        target = html.document.body;
        insertAtStart = true;
      } else if (s.placement == 'body_end' || s.placement == 'footer') {
        target = html.document.body;
      }
      _injectRawCode('custom-script-${s.id}', s.code, target, insertAtStart: insertAtStart);
    }
  } catch (e) {
    // Silent catch
  }
}

// Helper methods for DOM updates
void _setMeta(String name, String content) {
  if (content.isEmpty) return;
  var meta = html.document.querySelector('meta[name="$name"]');
  if (meta == null) {
    meta = html.MetaElement()..name = name;
    html.document.head?.append(meta);
  }
  meta.setAttribute('content', content);
}

void _setMetaProperty(String property, String content) {
  if (content.isEmpty) return;
  var meta = html.document.querySelector('meta[property="$property"]');
  if (meta == null) {
    meta = html.MetaElement()..setAttribute('property', property);
    html.document.head?.append(meta);
  }
  meta.setAttribute('content', content);
}

void _setCanonical(String url) {
  var link = html.document.querySelector('link[rel="canonical"]');
  if (link == null) {
    link = html.LinkElement()..setAttribute('rel', 'canonical');
    html.document.head?.append(link);
  }
  link.setAttribute('href', url);
}

void _setJsonLd(String id, String jsonContent) {
  var script = html.document.getElementById(id);
  if (script == null) {
    script = html.ScriptElement()
      ..id = id
      ..type = 'application/ld+json';
    html.document.head?.append(script);
  }
  script.text = jsonContent;
}

void _injectGa4(String ga4Id) {
  const scriptId = 'cosmyra-ga4-script';
  if (html.document.getElementById(scriptId) != null) return; // Deduplicated

  final script = html.ScriptElement()
    ..id = scriptId
    ..async = true
    ..src = 'https://www.googletagmanager.com/gtag/js?id=$ga4Id';
  html.document.head?.append(script);

  final configScript = html.ScriptElement()
    ..id = '$scriptId-init'
    ..text = '''
      window.dataLayer = window.dataLayer || [];
      function gtag(){dataLayer.push(arguments);}
      gtag('js', new Date());
      gtag('config', '$ga4Id', { send_page_view: true });
    ''';
  html.document.head?.append(configScript);
}

void _injectAdSense(String pubId, bool autoAds) {
  const scriptId = 'cosmyra-adsense-script';
  if (html.document.getElementById(scriptId) != null) return;

  final cleanPubId = pubId.startsWith('ca-pub-') ? pubId : 'ca-pub-$pubId';
  final script = html.ScriptElement()
    ..id = scriptId
    ..async = true
    ..crossOrigin = 'anonymous'
    ..src = 'https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=$cleanPubId';
  html.document.head?.append(script);
}

void _injectRawCode(String id, String rawCode, html.Element? parent, {bool insertAtStart = false}) {
  if (parent == null || rawCode.trim().isEmpty) return;
  // Remove existing element if already injected to allow live refresh
  html.document.getElementById(id)?.remove();

  final container = html.DivElement()
    ..id = id
    ..style.display = 'none';
  container.setInnerHtml(rawCode, treeSanitizer: html.NodeTreeSanitizer.trusted);

  if (insertAtStart && parent.children.isNotEmpty) {
    parent.insertBefore(container, parent.firstChild);
  } else {
    parent.append(container);
  }
}
