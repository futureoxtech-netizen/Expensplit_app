# Expense — premium expense sharing & personal finance

Monorepo with a Node.js backend and a Flutter (web + Android) client. Local development only.

```
expense/
├── backend/   # Node.js + Express + Mongo + Redis + Socket.io
└── app/       # Flutter — web (Chrome) + Android
```

## What's working in this Phase 1 build

- Email/password auth with JWT access + refresh token rotation, persistent session, automatic refresh on 401
- Groups: create, list, detail, invite codes (with QR), join by code, invite by email, leave
- Expenses: all four split modes (equal, exact, percent, shares), categories, recurring flag, tax/tip, paginated list, feed, delete
- Settlements: record payments, see history
- Balances: per-member net + greedy debt simplification ("you pay X to Y")
- Activity feed (per-group + global)
- Real-time Socket.io updates for expense/settlement/group events
- Monthly analytics aggregated by category
- Premium Flutter UI: dark/light theme, glassmorphism, gradient cards, fl_chart bar chart, shimmer loading, animated onboarding

Stubbed (env-var ready) for later: OCR receipts, AI categorization, FCM push, biometric login, voice input, multi-currency FX.

---

## 1) Run the backend

You need Docker Desktop. From `backend/`:

```bash
cd backend
cp .env.example .env   # On Windows PowerShell:  Copy-Item .env.example .env
docker compose up --build
```

The API is at `http://localhost:4000`. Health check: `GET /health`.

Seed demo data (Alice / Bob / Cara, all with password `password123`):

```bash
docker compose exec api npm run seed
```

Backend details: see [backend/README.md](backend/README.md).

> No Docker? Install Node 18+ and a local MongoDB on `localhost:27017`, then:
> ```bash
> cd backend && npm install && npm run dev
> ```

---

## 2) Run the Flutter app on Chrome

You need Flutter 3.22+. First time only:

```bash
cd app
flutter create . --platforms=web,android --org io.expense --project-name expense_app
flutter pub get
```

`flutter create .` re-generates the missing platform folders (`web/`, `android/`) without
overwriting the `lib/`, `pubspec.yaml`, or our custom `web/index.html`.

Run on Chrome:

```bash
flutter run -d chrome
```

The web client points to `http://localhost:4000` automatically. To override (e.g. another machine):

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://192.168.1.20:4000
```

Log in with `alice@demo.io` / `password123` (after seeding) or create a new account.

---

## 3) Run on Android (emulator or device)

```bash
cd app
flutter devices                 # list available targets
flutter run -d <device-id>
```

- **Emulator**: the app uses `http://10.0.2.2:4000` automatically (the host loopback).
- **Physical device**: pass your machine's LAN IP via `--dart-define`:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:4000
```

Make sure the phone and laptop are on the same Wi-Fi and your firewall allows port 4000.

---

## 4) Build production binaries

Web (for static hosting):

```bash
cd app
flutter build web --release
# output in app/build/web — drop into any static host (e.g. Firebase Hosting, S3)
```

Android APK / AAB (when you're ready for Play Store):

```bash
flutter build apk --release           # quick install on device
flutter build appbundle --release     # upload to Play Console
```

The AAB lands in `app/build/app/outputs/bundle/release/app-release.aab`. You'll need to:
1. Bump `version:` in `app/pubspec.yaml`.
2. Create a release keystore and reference it in `android/key.properties` and `android/app/build.gradle` (Flutter docs walk you through it).
3. Set up the Play Console listing, icons, screenshots, and content rating.

This Phase-1 codebase doesn't pre-configure Play signing because keystores should not be committed.

---

## Architecture quick tour

**Backend (Node.js, ESM):** modular service architecture under `src/modules/<feature>/` — each feature has `model`, `service`, `controller`, `routes`, `validation`. Auth via JWT with refresh-token rotation. Zod for request validation. Centralised error handler returns `{ ok, code, message }`. Socket.io rooms keyed by `group:<id>` so events fan-out to participants only.

**Flutter app:** Clean Architecture per feature.
```
lib/
├── app/                # MaterialApp, router, theme
├── core/               # network (Dio + refresh interceptor), storage (Hive + secure), errors, formatters
├── features/<x>/
│   ├── data/           # models + repository
│   ├── providers/      # Riverpod providers
│   └── presentation/   # screens / widgets
└── shared/widgets/     # GlassCard, PrimaryButton, Avatar, EmptyState, etc.
```
State: `flutter_riverpod` 2.x with `StateNotifier`/`FutureProvider`. Routing: `go_router` with auth-aware redirects. Caching: Hive boxes + cached repositories. Realtime: `socket_io_client` connected after login.

---

## Known limitations of Phase 1

- No OCR / AI categorization / voice / biometric yet — code paths and env vars exist, integrations not wired.
- No push notifications yet — `users/me/fcm-token` endpoint exists, no provider hookup.
- No multi-currency FX conversion — currency stored per expense but no conversion at read time.
- No tests yet — pre-commit and CI will land in Phase 4.
- Web Hive uses IndexedDB; tokens on web use `SharedPreferences` (no secure keystore in browsers).

These are explicit Phase-2/3 follow-ups, not oversights.
