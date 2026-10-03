import urllib.request
import json
import ssl

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

URL = "https://kxlseyibgwpfthpryrgn.supabase.co"
KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt4bHNleWliZ3dwZnRocHJ5cmduIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc2NzM4NTQsImV4cCI6MjEwMzI0OTg1NH0.l4_fUxXoTX2Q4sOPTqB9XtvYzpvAEkljevBmsjrO2JU"

req = urllib.request.Request(
    f"{URL}/rest/v1/dashboard_banners?select=*",
    headers={"apikey": KEY, "Authorization": f"Bearer {KEY}"}
)
try:
    with urllib.request.urlopen(req, context=ctx) as resp:
        data = json.loads(resp.read().decode())
        print(f"dashboard_banners ({len(data)} rows):")
        for i, b in enumerate(data):
            print(f"Banner {i+1}:")
            print(json.dumps(b, indent=2))
except Exception as e:
    print(f"Error fetching dashboard_banners: {e}")
