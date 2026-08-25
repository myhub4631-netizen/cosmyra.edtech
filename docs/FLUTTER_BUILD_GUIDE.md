# Flutter Mobile & Cross-Platform Build Guide

## Prerequisites
* Flutter SDK (>= 3.0.0)
* Android Studio / Xcode

## Android Build (.apk / .aab)
```bash
cd flutter_app
flutter pub get
flutter build apk --release
# APK output located at: build/app/outputs/flutter-apk/app-release.apk
```

## iOS Build (.ipa)
```bash
cd flutter_app
flutter pub get
cd ios && pod install && cd ..
flutter build ipa --release
```

## Web Build
```bash
cd flutter_app
flutter build web --release
```
