# FirstStep Mobile — Focus Mock Design Notes

## Unified direction: Focus

Stakeholders asked for a **cleaner, Apple-style** mobile surface: direct the eye, less content above the fold, and a customizable glance at metrics. The previous four-concept gallery (Pulse / Command / Story / Coach) remains in the repo under `lib/features/home/design_*` and `lib/features/gallery/` but is **unlinked** from the default app entry.

### Information hierarchy (Today)

1. Date + greeting (no logo in the top bar)
2. Compact **live activity** strip → sheet with full AIC run
3. One **focus card** (scenario-aware: applying / weekend / holiday / paused…)
4. **Customizable metrics** (edit icon → up to 4 slots, persisted with `shared_preferences`)
5. Pipeline row: Applied / Replied / Interview / Offers
6. Needs you (2 action items)
7. Collapsed **More** (weekly challenge, referral)

### Navigation (5 tabs)

| Index | Tab | Role |
|-------|-----|------|
| 0 | Applications | Pipeline list, search, filters |
| 1 | Inbox | Notifications + question of the day |
| 2 | **Today** (center, brand mark) | Primary home |
| 3 | Job board | ScoutX listings, 24h filter, Assign to AIC |
| 4 | You | Profile, plan, quiet hours, biometric; debug playground via long-press version |

Learning center is **not** in primary nav (heavy on mobile) — Profile links out to web as a mock.

### Brand

Locked tokens in `lib/theme/firststep_theme.dart`:

- Teal `#023345` · Accent `#2A8E9E` · Soft `#E7F4F6` · Cream `#FFF8EE` · Page `#F4F8FA`
- Display: Libre Baskerville (serif) · Body: DM Sans
- No purple AI glow; light mode first

### Mock scope

No API login or plan management. Fake seed data mirrors backend home sections conceptually (`liveRibbon`, stats, QOTD, holiday). Wire-up later to user view / home sections without 30s polling.

### Phase 2 (deferred)

React Native / Expo sibling mock with the same 5-tab IA for APK comparison.
