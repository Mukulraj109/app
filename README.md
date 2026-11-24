# FirstStep Mobile — Focus Mock (Flutter)

Clean, mock-only Flutter app for stakeholder review. **No backend.** Default entry is the unified **Focus** shell (5 tabs, Home centered).

## Run

```bash
cd 01_11_2026_Version_2.0/firststep_mobile
flutter pub get
flutter run                 # device / emulator
flutter run -d chrome       # desktop web with phone frame
```

## Debug APK

Android scaffolding is included under `android/`. Use the Flutter SDK on your machine (this repo was verified with `C:\src\flutter`):

```bash
# Windows example
C:\src\flutter\bin\flutter.bat pub get
C:\src\flutter\bin\flutter.bat build apk --debug
# output: build/app/outputs/flutter-apk/app-debug.apk
```

Chrome preview (no APK needed):

```bash
C:\src\flutter\bin\flutter.bat run -d chrome
```

Note: widget tests may fail on locked-down Windows if Smart App Control / WDAC blocks `flutter_tester.exe` — that is an environment policy issue, not app code.

## Tabs

1. **Applications** — search + All / This week / Interview chips  
2. **Inbox** — notifications + question of the day (+ holiday banner when scenario = holiday)  
3. **Today** — live strip, one focus card, editable metrics, pipeline, needs-you  
4. **Job board** — Last 24h filter, Assign to AIC snackbar  
5. **You** — plan progress, referral, quiet hours / biometric; **long-press version label** (or debug button) for state playground  

## Customize metrics

On Today, tap the pencil → pick up to 4 of: total applied, this week, interviews, responses, days left, hours saved. Saved via `shared_preferences`.

## Structure

```
lib/
  main.dart                 # FocusShell entry + desktop phone frame
  theme/firststep_theme.dart
  state/app_state.dart      # HomeMetricKey + prefs
  features/home/focus_home_view.dart
  features/shell/focus_shell.dart
  features/shell/tabs/      # applications, inbox, scoutx, profile
  shared_widgets/           # focus_bottom_nav, live strip, metrics sheet…
  features/gallery/         # legacy (unlinked)
  features/home/design_*    # legacy concepts (unlinked)
```

## React Native

Deferred. Same IA can be mirrored later for side-by-side APK evaluation.
