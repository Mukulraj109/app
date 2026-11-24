# Auth0 Native app (FirstStep Mobile)

Configured Native application (same values as in Auth0 Dashboard):

| Field | Value |
| --- | --- |
| Name | My App |
| Type | Native |
| Domain | `dev-0yrs1pb6s37h8s6u.us.auth0.com` |
| Client ID | `GqPHk4oOClQaMdxwMeLOc15awKEhknkS` |
| Scheme | `firststep` |
| Android package / iOS bundle ID | `careers.firststep.firststep_mobile` |

**Do not** put the Client Secret in the app, dart-defines, or git. Native + PKCE uses no secret.

## Auth0 Dashboard checklist

Already required on this app:

1. **Allowed Callback URLs** and **Allowed Logout URLs** (exact):

```
firststep://dev-0yrs1pb6s37h8s6u.us.auth0.com/android/careers.firststep.firststep_mobile/callback
firststep://dev-0yrs1pb6s37h8s6u.us.auth0.com/ios/careers.firststep.firststep_mobile/callback
```

The iOS URL is wired in `ios/Runner/Info.plist` (`CFBundleURLSchemes` = `firststep`). Add it in the Auth0 dashboard next to the Android URL. Do not remove the Android URL. Universal Links are not set up; login uses this custom scheme on both platforms.

Sign in with Apple in the app is the Auth0 connection `apple` (browser), not the native Apple entitlement. Keep that connection enabled. Do not add the Sign in with Apple capability unless the app later switches to native Apple auth.

2. Token Endpoint Authentication Method: **None**
3. Grant types: Authorization Code + Refresh Token
4. Refresh Token Rotation: On
5. Connections: Google (`google-oauth2`); GitHub only if web uses it
6. Do **not** authorize Management API for this client

## Backend (required for mobile login)

On every API environment that should accept the app:

```
AUTH0_DOMAIN=dev-0yrs1pb6s37h8s6u.us.auth0.com
AUTH0_MOBILE_CLIENT_ID=GqPHk4oOClQaMdxwMeLOc15awKEhknkS
```

`AUTH0_DOMAIN` must be this tenant (issuer). If the website SPA lives in a **different** Auth0 tenant, create the Native app in the **website** tenant instead, or mobile tokens will fail JWT verification.

Keep website `AUTH0_SPA_CLIENT_ID` / `AUTH0_CLIENT_ID` as they are. Empty `AUTH0_MOBILE_CLIENT_ID` → mobile 401; website unchanged.

Restart the backend after changing env.

## Flutter defaults (already in code)

`lib/auth/auth_config.dart` defaults to this Auth0 app. Override with `--dart-define` when needed.

| Define | Default |
| --- | --- |
| `AUTH0_DOMAIN` | `dev-0yrs1pb6s37h8s6u.us.auth0.com` |
| `AUTH0_CLIENT_ID` | `GqPHk4oOClQaMdxwMeLOc15awKEhknkS` |
| `AUTH0_SCHEME` | `firststep` |
| `API_BASE_URL` | `http://10.0.2.2:5000` on Android. On iOS, `http://127.0.0.1:5000` when this define is omitted. |
| `WEB_APP_URL` | `https://app.firststepjob.com` |
| `AUTH0_GITHUB` | `false` |

Android placeholders in `android/app/build.gradle.kts` default to the same domain/scheme.

### Emulator (backend on your PC port 5000)

```powershell
flutter run -Pauth0Domain=dev-0yrs1pb6s37h8s6u.us.auth0.com -Pauth0Scheme=firststep
```

Or use VS Code / Cursor launch config **FirstStep Mobile (Auth0)**.

### Physical phone (same Wi‑Fi)

```powershell
flutter run `
  -Pauth0Domain=dev-0yrs1pb6s37h8s6u.us.auth0.com `
  -Pauth0Scheme=firststep `
  --dart-define=API_BASE_URL=http://YOUR_PC_LAN_IP:5000
```

### iOS Simulator (backend on the Mac, port 5000)

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:5000
```

Or the launch config **iOS Simulator (Auth0)**. A physical iPhone needs `http://YOUR_MAC_LAN_IP:5000`, not `127.0.0.1`. See `docs/IOS_SETUP_PLAN.md`.

### Hosted API

```powershell
flutter run `
  -Pauth0Domain=dev-0yrs1pb6s37h8s6u.us.auth0.com `
  -Pauth0Scheme=firststep `
  --dart-define=API_BASE_URL=https://YOUR_BACKEND_HOST
```

Login scopes: `openid profile email offline_access`.  
Bearer = **ID token** → `POST /api/me/bootstrap`.
