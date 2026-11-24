# FirstStep Mobile — Vibrant Playful Redesign

**Date:** 2026-11-12
**Status:** Approved by user
**Direction:** Vibrant & playful. Full 3D + spring motion. Generated brand art. Both copy and visuals in scope. NOT a web clone — creative freedom on palette, type, and layout. Web reference (`firststep_frontend`) is sanity-check only, not a target.

---

## Scope

| In scope | Out of scope |
|----------|--------------|
| Today / Focus home screen | Backend API wiring (still mock seed data) |
| 5-tab shell (Applications, Inbox, Job Board, You) | Native biometric / plan purchase flow |
| Onboarding (single fresh 4–5 screen flow) | Learning center content (links to web) |
| Brand theme + palette + type | Dark mode (light-first) |
| Dead-concept deletion | React Native sibling app |
| Copy de-slopping (unslop) | Backend changes |
| 3D tilt cards + spring anims + confetti | — |
| Generated brand art (SVG assets) | — |

---

## Palette (vibrant)

Drop muted-teal + Georgia. New system:

```
// Base / surface
bg          #0F0A1E   deep indigo (page background)
card        #1A1430   card surface
cardAlt     #231B3E   alternate card
cream       #FFF8EE   warm off-white (accent card only)

// Accents (use sparingly, 1–2 per screen max)
coral       #FF4D7A
cyan        #00E5FF
lime        #A8E81C
amber       #FFB74D
violet      #7C4DFF

// Text
textHi      #F1EEFF
textMid     #B9B4D4
textLow     #6E6A8A

// Status
success     #4CD97B
warn        #FFB74D
danger      #FF5B6A
```

Radii: 14–20px. No uniform card sizes — each card has distinct personality.
Shadows: soft indigo glow (`#231B3E` at 30%), not the generic black card shadow.

---

## Typography

- **Display:** Rotunda-style rounded geometric (bundled as local `fonts/Rotunda.ttf` via asset, not runtime fetch).
- **Body:** Inter (bundled as `fonts/Inter-Regular.ttf` + `Inter-SemiBold.ttf`).
- **Labels / chips:** Inter SemiBold, uppercase, 0.5 letter-spacing.
- Georgia and Segoe UI removed entirely.

---

## Motion & 3D

- **Tilt 3D cards** — use existing `shared_widgets/tilt_3d_card.dart`, apply to hero + focus + metric cards.
- **Hero 3D element** — restyle `animated_3d_radar.dart` into a "pipeline globe": rotating rings + orbiting job dots. Placed at top of Today screen.
- **Staggered spring entrance** — `flutter_animate` on each card in Today, 50ms stagger, `spring()` curve.
- **Confetti** — `confetti` package fires on: "Mark done" challenge, streak milestone, offer received (seed data trigger).
- **Tab transitions** — `flutter_animate` slide+fade.
- **Onboarding** — 5 screens, parallax hero art, spring dot-rail, "Let's go" end card.
- Respect `MediaQuery.disableAnimations` (reduced-motion).

---

## New deps (`pubspec.yaml`)

```yaml
flutter_animate: ^4.4.2
confetti: ^0.9.1
google_fonts: ^6.2.0   # runtime fetch for prototyping; swap to local assets before release
```

Keep: `shared_preferences`. Remove: nothing else.

---

## Copy — De-slopped (unslop)

All user-facing strings pass through unslop before they ship. Key replacements:

| Before (AI) | After (human) |
|---|---|
| "Matched against your evidence and submitted to…" | "Sent to $names" |
| "Curated career guides and interview intelligence" | "Guides & interview prep" |
| "From FirstStep" (section) | "Learn" |
| "PLAN METER" | "Your plan" |
| "SUPPORT" (all-caps) | "Support" |
| "brand-locked Focus" footer | remove |
| "Renewal needed to keep applying" | "Your plan expires soon" |
| "Question of the day" | "Today's question" |

---

## Deletions

Remove these files entirely (dead concepts, no longer referenced):

```
lib/features/home/design_a_pulse/pulse_home_view.dart
lib/features/home/design_b_command/command_home_view.dart
lib/features/home/design_c_story/story_home_view.dart
lib/features/home/design_d_coach/coach_home_view.dart
lib/features/onboarding/design_a/onboarding_a_pulse.dart
lib/features/onboarding/design_b/onboarding_b_command.dart
lib/features/onboarding/design_c/onboarding_c_story.dart
lib/features/onboarding/design_d/onboarding_d_coach.dart
lib/features/gallery/design_gallery_screen.dart
lib/shared_widgets/design_switcher_sheet.dart
lib/shared_widgets/state_playground_chip.dart
```

Update all imports accordingly.

---

## New files

```
lib/theme/palette.dart          — new vibrant tokens (replaces parts of firststep_theme.dart)
lib/features/onboarding/onboarding_flow.dart   — single fresh 5-screen flow
lib/features/onboarding/onboarding_screen.dart — individual screen widget
assets/fonts/                   — Rotunda + Inter TTF files
assets/brand/                   — generated SVG art:
    hero-globe.svg
    onboarding-1.svg ... onboarding-5.svg
    confetti-burst.svg
    logo-firststep.svg
```

---

## Screen Layouts

### Today / Focus Home (v2)
1. **Hero strip** — 3D pipeline globe (radar restyle), spinning rings, job dots orbiting. 80px tall, centered.
2. **Focus card** — warm cream card, large coral number (todayCount), 2-line headline, one CTA button (indigo bg, coral text).
3. **Glance** — primary metric at 44px display type; 2 secondary chips (cyan + lime backgrounds, distinct).
4. **Pipeline row** — 4 equal cells, each a different accent color, no identical card.
5. **Coming up** — 2 interview cards with kind-based accent left border (coral = interview, lime = assessment).
6. **Learn** — horizontal card carousel, each card has a colored top ribbon (coral / cyan / lime / amber, cycling).
7. **Needs you** — up to 2 items, each with a distinct badge color.
8. **Your plan** — single progress bar (coral→cyan gradient), day counter.
9. **Support** — AIC avatar (generated), name + role, WhatsApp button (green), ticket button (outlined).
10. **Footer** — remove entirely.

### 5 tabs (quick restyle)
- **Applications** — list, each row has a kind-based left accent border, search pill.
- **Inbox** — notification cards, read/unread state dot, QOTD card at top.
- **Job board (ScoutX)** — card list, 24h filter chip, "Assign to AIC" CTA.
- **You** — profile card, plan card, quiet-hours toggle, biometric setup, referral code copy.
- **Today** — as above (center tab).

### Onboarding (5 screens)
1. **Welcome** — "FirstStep", generated hero art (rocket or globe), tagline, "Get started" button.
2. **What it does** — 3-step icon row (Apply / Track / Interview), each with distinct accent color.
3. **Your coach** — AIC avatar, name, "Your AI coach is ready", confetti burst on tap.
4. **Plan picker** — 3 plan cards (Free / Pro / Premium), each a different color, tap to select.
5. **Let's go** — big "Start your journey" button, background burst art, launch animation.

---

## Asset Generation Plan

Generate these SVGs into `assets/brand/`:
- `hero-globe.svg` — concentric rings + orbiting dots, coral/cyan, for the Today hero
- `onboarding-1.svg` — FirstStep logo (wordmark, Rotunda style)
- `onboarding-2.svg` — 3-step icons (arrows, magnifying glass, speech bubble)
- `onboarding-3.svg` — AIC coach avatar (rounded square, gradient)
- `onboarding-4.svg` — 3 plan cards illustration
- `onboarding-5.svg` — launch / rocket / burst
- `confetti-burst.svg` — confetti shapes for overlay
- `logo-firststep.svg` — standalone logo for app icon / footer

---

## Verification

- `flutter analyze` — zero errors / warnings
- `flutter run` on emulator / device — all 5 tabs + onboarding render
- Unslop check — grep `banned_phrase_scan.py` results on all user-facing strings
- No remaining references to deleted files
