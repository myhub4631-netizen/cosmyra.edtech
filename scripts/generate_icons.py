import os
import sys
import hashlib
from collections import deque
from PIL import Image, ImageFilter

SOURCE_PATH = "/Users/mahboobhasan/.gemini/antigravity-ide/brain/2c66e1ad-1375-4e0b-9c81-b9156658a88c/.user_uploaded/media_1788420778950.jpg"
BASE_DIR = "/Users/mahboobhasan/Desktop/Cosmyra Edu Flutter"

print(f"Loading source image from {SOURCE_PATH}...")
src = Image.open(SOURCE_PATH).convert("RGB")
w, h = src.size

# 1. Flood fill corner black regions
visited = set()
queue = deque([(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)])
for pt in queue:
    visited.add(pt)

while queue:
    x, y = queue.popleft()
    for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
        nx, ny = x + dx, y + dy
        if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in visited:
            r, g, b = src.getpixel((nx, ny))
            if r < 20 and g < 20 and b < 20:
                visited.add((nx, ny))
                queue.append((nx, ny))

outside_pixels = set(visited)
print(f"Detected {len(outside_pixels)} outside black corner pixels.")

# 2. Bleed edge colors into the outside region so alpha feathering has no dark halos
border = []
for (x, y) in outside_pixels:
    for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
        nx, ny = x + dx, y + dy
        if (nx, ny) not in outside_pixels:
            border.append((x, y))
            break

img_bled = src.copy()
visited_bleed = set(outside_pixels)
current_layer = set(border)
for step in range(8):
    next_layer = set()
    for (x, y) in current_layer:
        valid = []
        for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1), (-1, -1), (1, 1), (-1, 1), (1, -1)]:
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in visited_bleed:
                valid.append(img_bled.getpixel((nx, ny)))
        if valid:
            avg_c = (
                sum(c[0] for c in valid) // len(valid),
                sum(c[1] for c in valid) // len(valid),
                sum(c[2] for c in valid) // len(valid),
            )
            img_bled.putpixel((x, y), avg_c)
        for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            nx, ny = x + dx, y + dy
            if (nx, ny) in visited_bleed and (nx, ny) not in current_layer:
                next_layer.add((nx, ny))
    visited_bleed.difference_update(current_layer)
    current_layer = next_layer

# Create smoothed alpha mask
alpha_mask = Image.new("L", (w, h), 255)
for (x, y) in outside_pixels:
    alpha_mask.putpixel((x, y), 0)

smoothed_alpha = alpha_mask.filter(ImageFilter.GaussianBlur(radius=1.2))

# Master RGBA (transparent corners)
master_rgba = img_bled.convert("RGBA")
master_rgba.putalpha(smoothed_alpha)

# Master Opaque RGB (for iOS where transparency is disallowed, corners filled with matching soft background)
master_opaque_rgb = img_bled.copy()
for (x, y) in visited_bleed:
    master_opaque_rgb.putpixel((x, y), (245, 243, 252))

print("Master images prepared.")

def save_image(img, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    print(f"Saved: {path} ({img.size[0]}x{img.size[1]})")

# 1. Android Launcher Icons (RGBA with transparent corners)
android_sizes = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

android_base_dirs = [
    os.path.join(BASE_DIR, "flutter_app/android/app/src/main/res"),
    os.path.join(BASE_DIR, "cosmyra_edu_flutter_new/android/app/src/main/res"),
]

for res_dir in android_base_dirs:
    if os.path.exists(res_dir):
        for folder, sz in android_sizes.items():
            out_img = master_rgba.resize((sz, sz), Image.Resampling.LANCZOS)
            target = os.path.join(res_dir, folder, "ic_launcher.png")
            save_image(out_img, target)

# 2. iOS AppIcon Set (RGB without alpha as required by Apple App Store)
ios_sizes = {
    "Icon-App-20x20@1x.png": (20, 20),
    "Icon-App-20x20@2x.png": (40, 40),
    "Icon-App-20x20@3x.png": (60, 60),
    "Icon-App-29x29@1x.png": (29, 29),
    "Icon-App-29x29@2x.png": (58, 58),
    "Icon-App-29x29@3x.png": (87, 87),
    "Icon-App-40x40@1x.png": (40, 40),
    "Icon-App-40x40@2x.png": (80, 80),
    "Icon-App-40x40@3x.png": (120, 120),
    "Icon-App-60x60@2x.png": (120, 120),
    "Icon-App-60x60@3x.png": (180, 180),
    "Icon-App-76x76@1x.png": (76, 76),
    "Icon-App-76x76@2x.png": (152, 152),
    "Icon-App-83.5x83.5@2x.png": (167, 167),
    "Icon-App-1024x1024@1x.png": (1024, 1024),
}

ios_base_dirs = [
    os.path.join(BASE_DIR, "flutter_app/ios/Runner/Assets.xcassets/AppIcon.appiconset"),
    os.path.join(BASE_DIR, "cosmyra_edu_flutter_new/ios/Runner/Assets.xcassets/AppIcon.appiconset"),
]

for appicon_dir in ios_base_dirs:
    if os.path.exists(appicon_dir):
        for filename, (sw, sh) in ios_sizes.items():
            out_img = master_opaque_rgb.resize((sw, sh), Image.Resampling.LANCZOS)
            target = os.path.join(appicon_dir, filename)
            save_image(out_img, target)

# 3. Web PWA Icons (RGBA with transparent corners)
web_icon_dirs = [
    os.path.join(BASE_DIR, "public/icons"),
    os.path.join(BASE_DIR, "flutter_app/web/icons"),
    os.path.join(BASE_DIR, "cosmyra_edu_flutter_new/web/icons"),
]

for icon_dir in web_icon_dirs:
    if os.path.exists(icon_dir):
        img_192 = master_rgba.resize((192, 192), Image.Resampling.LANCZOS)
        img_512 = master_rgba.resize((512, 512), Image.Resampling.LANCZOS)
        save_image(img_192, os.path.join(icon_dir, "Icon-192.png"))
        save_image(img_512, os.path.join(icon_dir, "Icon-512.png"))
        save_image(img_192, os.path.join(icon_dir, "Icon-maskable-192.png"))
        save_image(img_512, os.path.join(icon_dir, "Icon-maskable-512.png"))

# 4. Favicons
# 48x48 crisp PNG (recommended by Google & modern browsers) and multi-size ICO
favicon_png = master_rgba.resize((48, 48), Image.Resampling.LANCZOS)
favicon_dirs = [
    os.path.join(BASE_DIR, "public"),
    os.path.join(BASE_DIR, "flutter_app/web"),
    os.path.join(BASE_DIR, "cosmyra_edu_flutter_new/web"),
]

ico_sizes = [(16, 16), (32, 32), (48, 48)]
ico_images = [master_rgba.resize(s, Image.Resampling.LANCZOS) for s in ico_sizes]

for fdir in favicon_dirs:
    if os.path.exists(fdir):
        save_image(favicon_png, os.path.join(fdir, "favicon.png"))
        ico_path = os.path.join(fdir, "favicon.ico")
        ico_images[0].save(ico_path, format="ICO", sizes=ico_sizes)
        print(f"Saved: {ico_path} (multi-size ICO [16, 32, 48])")

# 5. App Assets (cosmyra_icon.png)
asset_targets = [
    os.path.join(BASE_DIR, "flutter_app/assets/images/cosmyra_icon.png"),
    os.path.join(BASE_DIR, "cosmyra_edu_flutter_new/assets/images/cosmyra_icon.png"),
    os.path.join(BASE_DIR, "public/cosmyra_icon.png"),
    os.path.join(BASE_DIR, "public/assets/assets/images/cosmyra_icon.png"),
    os.path.join(BASE_DIR, "public/assets/images/cosmyra_icon.png"),
]

for target in asset_targets:
    if os.path.exists(os.path.dirname(target)):
        save_image(master_rgba, target)

# Also check build directory if present
build_web_favicon = os.path.join(BASE_DIR, "flutter_app/build/web/favicon.png")
if os.path.exists(os.path.dirname(build_web_favicon)):
    save_image(favicon_png, build_web_favicon)

build_web_icon = os.path.join(BASE_DIR, "flutter_app/build/web/assets/assets/images/cosmyra_icon.png")
if os.path.exists(os.path.dirname(build_web_icon)):
    save_image(master_rgba, build_web_icon)

print("All icon and favicon files generated successfully!")
