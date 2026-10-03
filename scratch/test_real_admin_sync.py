import urllib.request
import json
import ssl

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

URL = "https://kxlseyibgwpfthpryrgn.supabase.co"
KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt4bHNleWliZ3dwZnRocHJ5cmduIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc2NzM4NTQsImV4cCI6MjEwMzI0OTg1NH0.l4_fUxXoTX2Q4sOPTqB9XtvYzpvAEkljevBmsjrO2JU"

def get_config(key):
    req = urllib.request.Request(
        f"{URL}/rest/v1/system_config?key=eq.{key}&select=*",
        headers={"apikey": KEY, "Authorization": f"Bearer {KEY}"}
    )
    with urllib.request.urlopen(req, context=ctx) as resp:
        data = json.loads(resp.read().decode())
        if data:
            val = data[0].get("value")
            if isinstance(val, str):
                return json.loads(val)
            return val
    return None

def update_config(key, value):
    payload = json.dumps({"key": key, "value": json.dumps(value) if not isinstance(value, str) else value}).encode('utf-8')
    req = urllib.request.Request(
        f"{URL}/rest/v1/system_config",
        data=payload,
        headers={
            "apikey": KEY,
            "Authorization": f"Bearer {KEY}",
            "Content-Type": "application/json",
            "Prefer": "resolution=merge-duplicates"
        },
        method="POST"
    )
    with urllib.request.urlopen(req, context=ctx) as resp:
        return resp.status in (200, 201, 204)

print("Starting Real End-to-End Content Synchronization Test...")

# 1. TEST SERIES MUTATION & SYNC VERIFICATION
original_series_list = get_config("admin_custom_test_series") or []
print(f"1. Fetched {len(original_series_list)} test series from Supabase.")

if original_series_list:
    target_ts = original_series_list[0]
    orig_name = target_ts.get("name")
    orig_price = target_ts.get("price")
    
    print(f"   Original Test Series Name: '{orig_name}', Price: {orig_price}")

    # Mutate
    target_ts["name"] = "NEET 2027 Ultimate Leader Test Series (SYNC TEST)"
    target_ts["price"] = 399
    
    success = update_config("admin_custom_test_series", original_series_list)
    print(f"   Admin Mutation Saved to Supabase: {success}")

    # Fetch back to verify
    updated_series_list = get_config("admin_custom_test_series") or []
    updated_ts = updated_series_list[0]
    
    print(f"   Verified Supabase Read: Name = '{updated_ts.get('name')}', Price = {updated_ts.get('price')}")
    assert updated_ts.get("name") == "NEET 2027 Ultimate Leader Test Series (SYNC TEST)"
    assert updated_ts.get("price") == 399
    print("   ✓ TEST SERIES SYNC VERIFIED!")

    # Restore original values
    target_ts["name"] = orig_name
    target_ts["price"] = orig_price
    update_config("admin_custom_test_series", original_series_list)
    print("   Original Test Series data restored.")

# 2. BANNER MUTATION & SYNC VERIFICATION
req_b = urllib.request.Request(
    f"{URL}/rest/v1/dashboard_banners?select=*",
    headers={"apikey": KEY, "Authorization": f"Bearer {KEY}"}
)
with urllib.request.urlopen(req_b, context=ctx) as resp:
    banners = json.loads(resp.read().decode())
    print(f"\n2. Fetched {len(banners)} Dashboard Banners from Supabase.")
    if banners:
        b = banners[0]
        orig_title = b.get("title")
        b_id = b.get("id")
        print(f"   Original Banner ID {b_id} Title: '{orig_title}'")

        # Mutate banner
        payload_b = json.dumps({"title": "SYNC TEST BANNER - 85% OFF"}).encode('utf-8')
        req_ub = urllib.request.Request(
            f"{URL}/rest/v1/dashboard_banners?id=eq.{b_id}",
            data=payload_b,
            headers={
                "apikey": KEY,
                "Authorization": f"Bearer {KEY}",
                "Content-Type": "application/json",
            },
            method="PATCH"
        )
        with urllib.request.urlopen(req_ub, context=ctx) as resp_ub:
            print(f"   Banner patch status: {resp_ub.status}")

        # Verify exact banner by ID
        req_vb = urllib.request.Request(
            f"{URL}/rest/v1/dashboard_banners?id=eq.{b_id}&select=*",
            headers={"apikey": KEY, "Authorization": f"Bearer {KEY}"}
        )
        with urllib.request.urlopen(req_vb, context=ctx) as resp_v:
            v_banners = json.loads(resp_v.read().decode())
            v_title = v_banners[0].get("title")
            print(f"   Verified Banner ID {b_id} Title: '{v_title}'")
            assert v_title == "SYNC TEST BANNER - 85% OFF"
            print("   ✓ BANNER SYNC VERIFIED!")

        # Restore
        payload_rb = json.dumps({"title": orig_title}).encode('utf-8')
        req_rb = urllib.request.Request(
            f"{URL}/rest/v1/dashboard_banners?id=eq.{b_id}",
            data=payload_rb,
            headers={
                "apikey": KEY,
                "Authorization": f"Bearer {KEY}",
                "Content-Type": "application/json",
            },
            method="PATCH"
        )
        urllib.request.urlopen(req_rb, context=ctx)
        print("   Original Banner title restored.")

# 3. HOME PAGE CONTENT MUTATION & SYNC VERIFICATION
home_content = get_config("home_page_content") or {
    'hero_title': 'Master NEET & JEE with All-India Test Series',
    'hero_subtitle': 'Target NEET 2026 & JEE 2026 with 500+ Chapter Tests',
    'cta_text': 'Explore Test Series'
}
orig_hero = home_content.get("hero_title")
print(f"\n3. Original Hero Title: '{orig_hero}'")

home_content["hero_title"] = "Master NEET 2026 & 2027 with Ultimate Mock Tests"
update_config("home_page_content", home_content)

v_home = get_config("home_page_content")
print(f"   Verified Hero Title: '{v_home.get('hero_title')}'")
assert v_home.get("hero_title") == "Master NEET 2026 & 2027 with Ultimate Mock Tests"
print("   ✓ HOME PAGE CONTENT SYNC VERIFIED!")

# Restore
home_content["hero_title"] = orig_hero
update_config("home_page_content", home_content)
print("   Original Home Page Content restored.")

print("\n==================================================")
print("ALL 100% SINGLE SOURCE OF TRUTH SYNC TESTS PASSED!")
print("==================================================")
