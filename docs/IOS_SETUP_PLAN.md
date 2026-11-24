# FirstStep Mobile — iOS setup plan

> Status of this pass is at the bottom. Checked items are done in the repo. Unchecked items need a Mac, the Auth0 dashboard, or Apple/Firebase consoles.

**Goal:** Add an iOS project that matches the Android app (`careers.firststep.firststep_mobile`, display name FirstStep, Auth0 scheme `firststep`, pubspec `1.0.0+1`) without changing Android behavior or shared API contracts.

## Checklist

- [x] **1. Generate `ios/`** via `flutter create --org careers.firststep --project-name firststep_mobile --platforms=ios .` from `firststep_mobile`. Do not replace `android/`, `lib/`, or assets.
- [x] **2. Bundle ID / name / version.** Bundle ID `careers.firststep.firststep_mobile`. Display name `FirstStep`. Version stays `FLUTTER_BUILD_NAME` / `FLUTTER_BUILD_NUMBER` from pubspec `1.0.0+1`.
- [x] **3. Auth0 iOS callback.** Custom scheme `firststep` (same as Android). App-side URL type in `Info.plist`. Human adds this exact URL to **Allowed Callback URLs** and **Allowed Logout URLs** (do not remove the Android URL):

```
firststep://dev-0yrs1pb6s37h8s6u.us.auth0.com/ios/careers.firststep.firststep_mobile/callback
```

- [x] **4. Sign in with Apple capability.** Not added. The Apple button uses Auth0 connection `apple` through the browser (`signInWithApple` → `_signIn('apple')`). No native Sign in with Apple entitlement. The Auth0 `apple` connection must stay enabled in the dashboard.
- [x] **5. Firebase iOS.** Placeholder example only. Real `ios/Runner/GoogleService-Info.plist` is gitignored. Push soft-fails when the plist is missing (same as Android). APNs key/cert and the Xcode Push capability are a Mac + Apple Developer + Firebase console step.
- [x] **6. Info.plist permissions.** `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSPhotoLibraryAddUsageDescription`. ATS: `NSAllowsLocalNetworking` only (local HTTP for simulator/LAN). No `NSAllowsArbitraryLoads`.
- [x] **7. API host.** Android default stays `http://10.0.2.2:5000`. iOS with no `API_BASE_URL` define uses `http://127.0.0.1:5000`. Existing Android launch configs stay on `10.0.2.2`. Separate **iOS Simulator (Auth0)** launch config uses `127.0.0.1`. A physical iPhone still needs `--dart-define=API_BASE_URL=http://LAN_IP:5000`.
- [x] **8. UI.** Safe-area padding only on sheets that had neither `useSafeArea` nor an inner `SafeArea`, and only when `Platform.isIOS`. No product redesign.
- [x] **9. Minimum iOS 15.0.** `auth0_flutter` 3.2.0 requires iOS 15.0. This Flutter SDK scaffolds iOS with Swift Package Manager, so there is no `Podfile`. `IPHONEOS_DEPLOYMENT_TARGET` is `15.0` in `ios/Runner.xcodeproj/project.pbxproj`. Do not add a `Podfile` unless a later Flutter build creates one; if it does, set `platform :ios, '15.0'`.
- [x] **10. Windows limits.** This machine scaffolded `ios/`, edited plist/Dart, and ran `flutter analyze` (no new errors) and `flutter test` (120 passed). It cannot run `xcodebuild`, the Simulator, Swift package resolution on a Mac, or codesign.
- [x] **11. Regression.** `flutter test` passed (120). `flutter analyze` reports no errors from this change (existing info/warnings remain). `android/app/build.gradle.kts` still uses `careers.firststep.firststep_mobile` and the `firststep` Auth0 scheme. `android/` was not edited.

## Will not change

- Feature screens, tabs, and API call shapes (Home, Applications, Learn, Profile, ScoutX)
- Backend response fields (shared with the website)
- Web frontend
- Android package name `careers.firststep.firststep_mobile`
- Android Auth0 manifest placeholders, `google-services.json`, and release signing (`android/key.properties`)
- Auth0 domain, client id, and scheme defaults

## How to run on iOS

Needs a Mac with Xcode. From `firststep_mobile`:

### Simulator (backend on the Mac, port 5000)

```bash
flutter run \
  --dart-define=API_BASE_URL=http://127.0.0.1:5000
```

Or the Cursor / VS Code config **iOS Simulator (Auth0)**. Omitting `API_BASE_URL` on iOS also defaults to `http://127.0.0.1:5000`.

### Physical iPhone (same Wi-Fi)

```bash
flutter run \
  --dart-define=API_BASE_URL=http://YOUR_MAC_LAN_IP:5000
```

`127.0.0.1` on a device is the phone, not your computer.

### Compile check without signing

```bash
flutter build ios --no-codesign
```

This Flutter SDK integrates plugins with Swift Package Manager (no `Podfile` in the repo). On a Mac that command resolves packages. A real device still needs a signing team in Xcode; `--no-codesign` skips store signing.

### Firebase and push (human)

1. Firebase console → project settings → add an iOS app with bundle ID `careers.firststep.firststep_mobile`.
2. Download `GoogleService-Info.plist` into `ios/Runner/` and add it to the Runner target (Copy Bundle Resources). Do not commit it.
3. Apple Developer → Keys → create an APNs key (`.p8`). Upload that key in Firebase → Cloud Messaging. Do not commit the `.p8`.
4. Xcode → Runner → Signing & Capabilities → Push Notifications, and Background Modes → Remote notifications.

Until the plist is present, the app still launches. Push registration logs a soft failure and continues.

### Auth0 dashboard (human)

On the existing Native app (`GqPHk4oOClQaMdxwMeLOc15awKEhknkS`), append the iOS callback to **Allowed Callback URLs** and **Allowed Logout URLs**. Leave the Android URL in place:

```
firststep://dev-0yrs1pb6s37h8s6u.us.auth0.com/android/careers.firststep.firststep_mobile/callback
firststep://dev-0yrs1pb6s37h8s6u.us.auth0.com/ios/careers.firststep.firststep_mobile/callback
```

Universal Links are not configured. Login uses the `firststep` custom scheme, same as Android.

## Mac / human follow-up (cannot be finished on Windows)

- [ ] Save the iOS callback and logout URL in the Auth0 dashboard
- [ ] Apple Developer team, signing, and a device or Simulator run
- [ ] Drop in the real `GoogleService-Info.plist` and enable the Push capability
- [ ] Upload the APNs authentication key to Firebase
- [ ] `flutter build ios --no-codesign` or `flutter run` on a Mac
