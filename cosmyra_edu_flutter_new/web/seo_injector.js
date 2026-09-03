/**
 * Cosmyra NEET JEE - Live SEO & Tracking Pre-Render Injector
 * Dynamically loads verification meta tags, GA4, AdSense, and pre-render metadata
 */
(function() {
  const SUPABASE_URL = "https://kxlseyibgwpfthpryrgn.supabase.co";
  const SUPABASE_ANON = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt4bHNleWliZ3dwZnRocHJ5cmduIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc2NzM4NTQsImV4cCI6MjEwMzI0OTg1NH0.l4_fUxXoTX2Q4sOPTqB9XtvYzpvAEkljevBmsjrO2JU";

  function fetchAndApplySEO() {
    // Check cached settings in localStorage first for instant execution
    const cached = localStorage.getItem("cosmyra_seo_settings");
    if (cached) {
      try {
        applySettings(JSON.parse(cached));
      } catch (e) {}
    }

    // Fetch latest settings from Supabase REST API
    fetch(SUPABASE_URL + "/rest/v1/seo_global_settings?select=*&limit=1", {
      headers: {
        "apikey": SUPABASE_ANON,
        "Authorization": "Bearer " + SUPABASE_ANON
      }
    })
    .then(res => res.json())
    .then(data => {
      if (data && data.length > 0) {
        const settings = data[0];
        localStorage.setItem("cosmyra_seo_settings", JSON.stringify(settings));
        applySettings(settings);
      }
    })
    .catch(err => {
      console.warn("SEO pre-render loader notice:", err);
    });
  }

  function applySettings(s) {
    if (!s) return;

    // 1. Google Site Verification
    if (s.gsc_is_active && s.gsc_verification_code) {
      let gscMeta = document.querySelector('meta[name="google-site-verification"]');
      if (!gscMeta) {
        gscMeta = document.createElement("meta");
        gscMeta.name = "google-site-verification";
        document.head.appendChild(gscMeta);
      }
      gscMeta.content = s.gsc_verification_code;
    }

    // 2. Google Analytics 4 (GA4)
    if (s.ga4_is_enabled && s.ga4_measurement_id) {
      if (!document.getElementById("cosmyra-ga4-script")) {
        const gaScript = document.createElement("script");
        gaScript.id = "cosmyra-ga4-script";
        gaScript.async = true;
        gaScript.src = "https://www.googletagmanager.com/gtag/js?id=" + s.ga4_measurement_id;
        document.head.appendChild(gaScript);

        const initScript = document.createElement("script");
        initScript.id = "cosmyra-ga4-init";
        initScript.text = "window.dataLayer = window.dataLayer || []; function gtag(){dataLayer.push(arguments);} gtag('js', new Date()); gtag('config', '" + s.ga4_measurement_id + "');";
        document.head.appendChild(initScript);
      }
    }

    // 3. Google AdSense
    if (s.adsense_is_enabled && s.adsense_publisher_id) {
      if (!document.getElementById("cosmyra-adsense-script")) {
        const adScript = document.createElement("script");
        adScript.id = "cosmyra-adsense-script";
        adScript.async = true;
        adScript.crossOrigin = "anonymous";
        const pubId = s.adsense_publisher_id.startsWith("ca-pub-") ? s.adsense_publisher_id : "ca-pub-" + s.adsense_publisher_id;
        adScript.src = "https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=" + pubId;
        document.head.appendChild(adScript);
      }
    }

    // 4. Default meta title & description
    if (s.default_meta_title && !document.title) {
      document.title = s.default_meta_title;
    }
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", fetchAndApplySEO);
  } else {
    fetchAndApplySEO();
  }
})();
