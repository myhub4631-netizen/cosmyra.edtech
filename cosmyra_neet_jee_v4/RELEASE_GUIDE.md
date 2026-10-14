# COSMYRA NEET JEE v4 — Release & Versioning Guide

## 1. Versioning Policy
- **Starting Release:** `4.1.1+1` (Version: 4.1.1, Build Number: 1)
- **Sequential Increment Rule:** For every release, increment the patch version by 1 and the build number by 1:
  - `4.1.1+1` (Initial Release)
  - `4.1.2+2` (Next Release)
  - `4.1.3+3`
  - `4.1.4+4`
  - `4.1.5+5`
- **Format:** `versionName+buildNumber` (`x.y.z+n`).
- **Application ID:** `com.cosmyra.neetjee` across Android and iOS bundles.

---

## 2. Release Procedure (Step-by-Step)

When publishing a new release (e.g. `4.1.2+2`):

### Step 1: Update `pubspec.yaml`
```yaml
version: 4.1.2+2
```

### Step 2: Update `lib/core/services/analytics_service.dart`
```dart
static const String _appVersion = '4.1.2+2';
```

### Step 3: Run Full Test Suite
```bash
flutter test test/phase4_realtime_analytics_test.dart \
             test/regression_analytics_kpi_test.dart \
             test/phase3_e2e_analytics_acceptance_test.dart \
             test/phase5_live_user_activity_monitor_test.dart
```

### Step 4: Build Web Release
```bash
flutter build web --release
```
Verify generated `build/web/version.json`:
```json
{"app_name":"cosmyra_neet_jee","version":"4.1.2","build_number":"2","package_name":"cosmyra_neet_jee"}
```

### Step 5: Build Android Release APK / AAB
For direct APK download:
```bash
flutter build apk --release
```
For Google Play Store Bundle (.aab):
```bash
flutter build appbundle --release
```

---

## 3. Architecture & Verification Summary

| Component | Status | Details |
|---|---|---|
| **App Identity** | `com.cosmyra.neetjee` | Preserved across AndroidManifest and Gradle |
| **Current Version** | `4.1.1+1` | Initial release of v4 line |
| **Workspaces** | Independent | `cosmyra_neet_jee_v4/` created without modifying `cosmyra_neet_jee_v2/` or `flutter_app/` |
| **All Features** | Preserved | Auth, PYQ Paper Manager, Live User Activity Monitor, NTA examination engine, Commerce, Entitlements |
| **Test Suite** | 24/24 Passed | Unit, KPI regression, acceptance, and widget tests passing 100% |
