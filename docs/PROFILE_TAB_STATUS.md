# Profile tab — done vs left

Last audited: 2026-11-19 (finish pass)  
Scope: mobile Profile tab + Settings & help + onboarding feed into Profile.  
Backend base: `firststep_backend` `/api/me/*` (additive; website ProfileHub unchanged).

Use this file in a new chat to finish remaining work without re-discovering status.

**Copy also kept at:** `01_11_2026_Version_2.0/docs/PROFILE_TAB_STATUS.md`

---

## Verdict

**Profile tab is end-to-end for the planned slices.** Core Profile data stays wired. This pass closed Zoho benefit URLs (same as web), Auth0 picture on avatar, attachment preview via the website signed-URL route, per-group settings + WhatsApp opt-in, and FCM device register + `PUSH_PROVIDER=fcm` sender. Remaining gaps are **ops/config** (real Firebase client files, `PUSH_PROVIDER=fcm` in env) and optional polish (ticket threads, CMS).

---

## Done (wired / usable)

| Area | Status | Notes |
|------|--------|--------|
| Auth0 login → bootstrap → Profile header | Done | Name/email from bootstrap; Member since from `createdAt` |
| Rename display name | Done | Tap name or Settings → Display name → `PATCH /api/me/profile` |
| Plan card (name, Active, dates, days left, progress) | Done | Extended `GET /api/me/plan-summary` |
| What’s included | Done | `plan_details` + `GET /api/me/plan-details` |
| Plan benefit chips | Done | Same Zoho URLs as web QuickActions / FORM_LINKS; ScoutX still toast (no web form) |
| WhatsApp group tile | Done | Opens `whatsappGroupUrl` when present |
| Invite a friend | Done | Share sheet uses personal referral code → `https://firststepjob.com/r/{code}` |
| Support tickets list + raise | Done | `GET/POST /api/me/requests` (`type: support`); list refreshes after submit |
| Documents list + download | Done | `GET /api/me/documents` + `GET /api/me/documents/:id/download` → share file |
| Document in-app preview | Done | `POST /firstStep/user/attachments/preview` (same as website) → in-app browser |
| Intake (read-only) | Done | Intake + onboarding fallback when intake empty |
| Personalise (location, tech, roles, news, learning) | Done | `GET/PUT /api/me/app-profile` |
| Rewards + badges | Done | `/api/me/rewards`, `/api/me/badges` |
| FAQ | Done | Full web FAQ (65 items) in-app with category chips |
| Holiday calendar | Done | `GET /api/me/calendar` |
| Terms / Privacy | Done | Full in-app Terms + Privacy (mirrored from web pages) |
| Delete account | Done | `POST /api/me/delete-account-request` |
| Face ID | Dropped | Removed from Settings (per plan) |
| Notifications prefs UI | Done | Same nine groups + preferences + timezone as web `ClientSettings` |
| WhatsApp opt-in | Done | `POST /api/me/whatsapp-opt-in` then open WhatsApp; confirm via GetGabs webhook |
| Appearance | Done | Local theme + `PATCH /api/me/theme` |
| Auth0 / Google picture | Done | `AvatarMark` shows `session.picture` when URL present |
| Push device register | Done | After login → `POST /api/me/devices` `provider: fcm`; logout → `DELETE` |
| Push send | Ready | `drainDuePushes` sends when `PUSH_PROVIDER=fcm` (Firebase Admin) |
| Onboarding questions | Done | Mongo `onboarding_questions` via bootstrap `questionCatalog` |
| Web safety | Done | Additive routes/fields only |

### Key API surface (mobile)

- `POST /api/me/bootstrap`
- `PATCH /api/me/profile`
- `GET /api/me/plan-summary` (+ dates/progress)
- `GET /api/me/plan-details`
- `GET /api/me/plan-benefits`
- `GET /api/me/documents`
- `GET /api/me/documents/:id/download`
- `POST /firstStep/user/attachments/preview` ← same as website
- `GET/PUT /api/me/app-profile`
- `GET/POST /api/me/requests`
- `GET /api/me/rewards`, `GET /api/me/badges`, `GET/PUT /api/me/intake-profile`
- `GET/PUT /api/me/settings`, `PATCH /api/me/theme`
- `POST /api/me/whatsapp-opt-in`
- `GET /api/me/calendar`
- `POST /api/me/delete-account-request`
- `PUT /api/me/onboarding/answer`
- `POST/DELETE /api/me/devices` (`token`, `platform`, `provider: fcm`)

---

## Left / incomplete (ops + optional)

### Ops / env

1. **Replace placeholder Firebase client config**  
   - `android/app/google-services.json` is a placeholder.  
   - Add real Firebase Android/iOS files from the console before production push works on device.

2. **Enable server send**  
   - Set `PUSH_PROVIDER=fcm` and ensure Firebase Admin env vars are set.  
   - Without `PUSH_PROVIDER`, outbox stays `pending_provider` (safe default).

### Optional / out of scope earlier

3. **Profile camera upload** — website never uploads; picture comes from Auth0. Pattern avatars stay local.  
4. **Invoices as real docs** — same attachments pipeline; empty when staff have not uploaded.  
5. **Support ticket detail / reply thread** — list + create only (web has no client reply thread).  
6. **Admin CMS for `plan_details` / FAQ** — optional (mobile FAQ/legal are static Dart mirrored from web).

---

## Known test account snapshot (`thobyou01@gmail.com`)

| Field | Expected live value |
|-------|---------------------|
| Name | You (renamable) |
| Email | thobyou01@gmail.com |
| Plan | Essentials / Active |
| Roles | Full Stack, Software Dev, App Sec |
| Locations (onboarding) | Remote, Colorado, Connecticut |
| Docs / tickets / rewards | Often 0 |
| Intake row | May be empty → onboarding fallback |

Debug APK path used previously: `C:\Users\user\Downloads\FirstStep-Auth0-debug.apk`  
API define: `API_BASE_URL=http://192.168.29.23:5000`

---

## Files touched in finish pass

- Backend: `journey/profilePack.ts` (benefit URLs), `notifications/channels/fcm.ts`, `notifications/dispatcher.ts`, `.env.example`
- Mobile: `avatar_mark.dart`, `profile_store.dart`, `profile_view.dart`, `profile_screens.dart` (settings), `help_pages.dart` (preview), `api_client.dart`, `push/push_registration.dart`, `auth_controller.dart`, `pubspec.yaml`, Android Google Services stub
