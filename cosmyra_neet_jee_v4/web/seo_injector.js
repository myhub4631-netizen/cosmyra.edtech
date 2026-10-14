/**
 * Cosmyra NEET JEE - Live SEO & Tracking Pre-Render Injector
 * Dynamically loads verification meta tags, GA4, AdSense, Tawk.to, Custom Scripts & Pre-render metadata
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

    // Fetch latest settings from Supabase REST API (app_settings key=site_code_settings or fallback)
    fetch(SUPABASE_URL + "/rest/v1/app_settings?key=eq.site_code_settings&select=value", {
      headers: {
        "apikey": SUPABASE_ANON,
        "Authorization": "Bearer " + SUPABASE_ANON
      }
    })
    .then(res => res.json())
    .then(data => {
      if (data && data.length > 0 && data[0].value) {
        const settings = data[0].value;
        localStorage.setItem("cosmyra_seo_settings", JSON.stringify(settings));
        applySettings(settings);
      } else {
        // Fallback fetch
        return fetch(SUPABASE_URL + "/rest/v1/seo_global_settings?select=*&limit=1", {
          headers: {
            "apikey": SUPABASE_ANON,
            "Authorization": "Bearer " + SUPABASE_ANON
          }
        }).then(r => r.json()).then(d => {
          if (d && d.length > 0) {
            localStorage.setItem("cosmyra_seo_settings", JSON.stringify(d[0]));
            applySettings(d[0]);
          }
        });
      }
    })
    .catch(err => {
      console.warn("SEO pre-render loader notice:", err);
    });
  }

  function injectRawHtmlCode(id, htmlCode, targetElement, insertAtStart) {
    if (!htmlCode || !htmlCode.trim() || !targetElement) return;
    
    // Remove previous instance if existing to allow clean refresh
    const prev = document.getElementById(id);
    if (prev) prev.remove();

    const container = document.createElement("div");
    container.id = id;
    container.style.display = "none";
    container.innerHTML = htmlCode;

    // Convert inert script tags into active executable script elements
    const scripts = Array.from(container.querySelectorAll("script"));
    scripts.forEach(s => {
      const newScript = document.createElement("script");
      if (s.type) newScript.type = s.type;
      if (s.src) {
        newScript.src = s.src;
        newScript.async = s.async;
      } else {
        newScript.text = s.textContent || s.innerText || s.innerHTML;
      }
      Array.from(s.attributes).forEach(attr => {
        if (attr.name !== "src" && attr.name !== "type") {
          newScript.setAttribute(attr.name, attr.value);
        }
      });
      s.parentNode.replaceChild(newScript, s);
    });

    if (insertAtStart && targetElement.firstChild) {
      targetElement.insertBefore(container, targetElement.firstChild);
    } else {
      targetElement.appendChild(container);
    }
  }

  function applySettings(s) {
    if (!s) return;

    if (s.emergency_kill_switch) {
      return;
    }

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

    // 4. Custom CSS
    if (s.custom_css_enabled && s.custom_css && s.custom_css.trim()) {
      let styleEl = document.getElementById("cosmyra-custom-css");
      if (!styleEl) {
        styleEl = document.createElement("style");
        styleEl.id = "cosmyra-custom-css";
        document.head.appendChild(styleEl);
      }
      styleEl.textContent = s.custom_css;
    }

    // 5. Custom JS
    if (s.custom_js_enabled && s.custom_js && s.custom_js.trim()) {
      if (!document.getElementById("cosmyra-custom-js")) {
        const jsEl = document.createElement("script");
        jsEl.id = "cosmyra-custom-js";
        jsEl.text = s.custom_js;
        document.body.appendChild(jsEl);
      }
    }

    // 6. Custom Code Injection Zones (Head, Body Start, Body End, Footer - e.g. Tawk.to, GTM)
    if ((s.head_code_enabled || s.head_code_enabled === undefined) && s.head_code) {
      injectRawHtmlCode("zone-head-code", s.head_code, document.head, false);
    }
    if ((s.body_start_code_enabled || s.body_start_code_enabled === undefined) && s.body_start_code) {
      injectRawHtmlCode("zone-body-start-code", s.body_start_code, document.body, true);
    }
    if ((s.body_end_code_enabled || s.body_end_code_enabled === undefined) && s.body_end_code) {
      injectRawHtmlCode("zone-body-end-code", s.body_end_code, document.body, false);
    }
    if ((s.footer_code_enabled || s.footer_code_enabled === undefined) && s.footer_code) {
      injectRawHtmlCode("zone-footer-code", s.footer_code, document.body, false);
    }

    // 7. Default meta title & description
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
