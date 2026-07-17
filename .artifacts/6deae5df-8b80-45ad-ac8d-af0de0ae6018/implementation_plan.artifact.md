# Implementation Plan - Flutter Package Name Migration

Migration of the Flutter application package name/bundle identifier from `com.example.webchamp_app` (and `com.example.webchampApp`) to `com.wabchamp.app`.

## Proposed Changes

### Android

#### [MODIFY] [build.gradle.kts](file:///C:/Users/muham/Documents/GitHub/webchamp_app/android/app/build.gradle.kts)
- Update `namespace` from `"com.example.webchamp_app"` to `"com.wabchamp.app"`.
- Update `applicationId` from `"com.example.webchamp_app"` to `"com.wabchamp.app"`.

#### [MODIFY] [MainActivity.kt](file:///C:/Users/muham/Documents/GitHub/webchamp_app/android/app/src/main/kotlin/com/example/webchamp_app/MainActivity.kt)
- Update the `package` declaration to `package com.wabchamp.app`.

#### [MOVE] [MainActivity.kt](file:///C:/Users/muham/Documents/GitHub/webchamp_app/android/app/src/main/kotlin/com/example/webchamp_app/MainActivity.kt)
- Move the file to `android/app/src/main/kotlin/com/wabchamp/app/MainActivity.kt`.
- Delete the old directory structure `com/example/webchamp_app`.

### iOS

#### [MODIFY] [project.pbxproj](file:///C:/Users/muham/Documents/GitHub/webchamp_app/ios/Runner.xcodeproj/project.pbxproj)
- Replace all occurrences of `com.example.webchampApp` with `com.wabchamp.app`.
- This includes the main app and `RunnerTests`.

### macOS

#### [MODIFY] [project.pbxproj](file:///C:/Users/muham/Documents/GitHub/webchamp_app/macos/Runner.xcodeproj/project.pbxproj)
- Replace all occurrences of `com.example.webchampApp` with `com.wabchamp.app`.

#### [MODIFY] [AppInfo.xcconfig](file:///C:/Users/muham/Documents/GitHub/webchamp_app/macos/Runner/Configs/AppInfo.xcconfig)
- Update `PRODUCT_BUNDLE_IDENTIFIER` to `com.wabchamp.app`.
- Update `PRODUCT_COPYRIGHT` to use `com.wabchamp` instead of `com.example`.

### General

#### [MODIFY] [Info.plist](file:///C:/Users/muham/Documents/GitHub/webchamp_app/ios/Runner/Info.plist)
- Verify `CFBundleIdentifier` uses `$(PRODUCT_BUNDLE_IDENTIFIER)`. (Already checked, it does).

## Verification Plan

### Automated Steps
- Search for any remaining occurrences of `com.example.webchamp_app` or `com.example.webchampApp`.
- Run `flutter clean`.
- Run `flutter pub get`.

### Manual Verification
- Verify the Android directory structure matches the new package name.
- Verify `MainActivity.kt` has the correct package name.
- Verify the build configuration for iOS and macOS reflects the new bundle identifier.
