import urllib.request
import json
import ssl

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

URL = "https://kxlseyibgwpfthpryrgn.supabase.co"
KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt4bHNleWliZ3dwZnRocHJ5cmduIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc2NzM4NTQsImV4cCI6MjEwMzI0OTg1NH0.l4_fUxXoTX2Q4sOPTqB9XtvYzpvAEkljevBmsjrO2JU"

req = urllib.request.Request(
    f"{URL}/rest/v1/system_config?select=*",
    headers={"apikey": KEY, "Authorization": f"Bearer {KEY}"}
)
try:
    with urllib.request.urlopen(req, context=ctx) as resp:
        data = json.loads(resp.read().decode())
        print(f"system_config keys ({len(data)} total):")
        for row in data:
            print(f" Key: '{row.get('key')}'")
            val = str(row.get('value'))
            if len(val) > 200:
                print(f"   Value (truncated): {val[:200]}...")
            else:
                print(f"   Value: {val}")
except Exception as e:
    print(f"Error reading system_config: {e}")
