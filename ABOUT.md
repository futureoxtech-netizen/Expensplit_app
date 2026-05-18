# Expense — a premium expense-sharing & personal finance app

> Split bills with friends, settle up fairly, see where your money actually goes.
> Built end-to-end in Flutter + Node.js by **Abdul Moiz**.

---

## What is it?

**Expense** is a modern, mobile-first money app inspired by Splitwise, Tricount and
fintech UIs like Revolut & Stripe. You create a group (trip, roommates, family,
office, event), drop expenses into it, and the app handles the awkward math —
who paid what, who owes whom, and the smallest number of payments that settle
everyone up.

There's also a personal-finance side: spend tracking by category, beautiful
reports for today / this week / this month / this year / any custom range,
and one-tap PDF export so you can keep records or share them.

---

## The headline features

### Groups, the way real life works
- Create a group for a **trip, family, roommates, office team, or event**.
- **Invite by email** or share an **invite code / QR** — anyone scans and joins.
- **Roles**: owner, admin, member. Owner can edit the group, change currency, manage members.
- Each group has its **own currency** — USD, EUR, GBP, INR, **PKR**, JPY, CAD, AUD.

### Smart expense splitting
Four split modes, all done correctly:
- **Equal** — divide evenly across everyone you tick.
- **Exact** — type the precise amount each person owes (the app checks it sums to the total).
- **Percent** — type percentages (the app checks they sum to 100).
- **Shares** — type weights like `1, 1, 2` for proportional splits.
Plus tax & tip lines, notes, categories, receipts (slot is wired, OCR integration coming).

### Debt simplification (the magic)
Three friends, six expenses, everyone owes everyone? No. The app runs a
**greedy debt-simplification algorithm** and shows you the **minimum set of payments**
that settles the whole group. One tap on "Settle" records the payment and
everything updates live.

### Real-time, across devices
Backed by **Socket.io rooms**. The moment one member adds an expense, every other
member's app updates instantly — the dashboard, the group balances, the activity
feed, the unread bell count. No refresh needed.

### Reports & analytics
- Pick a period: **Today, This week, This month, This year, or a custom range**.
- Animated **donut chart** of spending by category — tap a slice to focus.
- **Insight callout**: top category, average spend per day, transaction count.
- **One-tap PDF export** with a branded report (full Unicode currency symbols).

### Activity feed with unread badges
A live feed of what's happening in your groups — "Alice added Groceries · $40 in
Weekend Trip", "Bob settled $20 to you". An unread badge sits on the bell icon
and the bottom-nav Activity tab; it clears the moment you open Activity.

### Profile, theme, currency
- **Light, dark, system** theme — switches instantly, persists across sessions.
- Pick your **default currency** from a clean bottom-sheet picker.
- See your **referral code** ready for share-to-earn rewards.

### Beautiful, intentional UI
- Aurora gradient backgrounds, glassmorphism cards, soft shadows.
- Premium onboarding with parallax dots.
- Live shimmer skeletons while data loads.
- Friendly error messages everywhere — no raw stack traces ever shown.
- Identical experience on **Chrome (web)** and **Android**.

---

## What it took to build

### Frontend — Flutter
A Clean Architecture codebase split by feature:
```
features/
  auth · groups · expenses · settlements · activity · reports · profile · home
```
- **Riverpod 2** for state, `go_router` for navigation with auth-aware redirects.
- **Dio** with a refresh-token interceptor so 401s auto-retry the original request.
- **Hive** for offline cache & settings.
- `fl_chart` for the donut chart, `pdf` + `printing` for branded PDF generation,
  `socket_io_client` for the realtime layer.
- 60+ Dart files, custom theme system, reusable widget library
  (`GlassCard`, `PrimaryButton`, `Avatar`, `EmptyState`, `ShimmerLoader`).

### Backend — Node.js
Modular service architecture, repository pattern:
```
modules/
  auth · users · groups · expenses · settlements · activity
```
- **Express + Zod** validation, centralised error handler returning `{ ok, code, message }`.
- **JWT** access + refresh with rotation; refresh tokens persisted per-user.
- **MongoDB Atlas** for storage, **Redis** for cache, **Socket.io** for realtime.
- Aggregation pipelines for the reports & analytics endpoints.
- **Dockerised** for one-command local startup; designed to scale horizontally.

### What's already real vs roadmap
**Working today**: auth, groups, all four split modes, balances + simplified
settle-ups, settlements, activity feed, unread badges, realtime sync, monthly
analytics + reports, PDF export, theme/currency settings.

**Wired but waiting on integrations**: OCR receipts, AI categorization, voice
input, biometric login, FCM push notifications, multi-currency FX conversion.

---

## How to try it

The app currently runs locally for development:

1. **Backend** runs against MongoDB Atlas + a local Node server on port `4000`.
2. **Frontend** runs on Chrome (`flutter run -d chrome`) or any Android emulator.
3. There's a seed script with demo users: `alice@demo.io`, `bob@demo.io`, `cara@demo.io`
   (password `password123`).

Sign in, create a group, add an expense — watch the balance update in real time
on a second browser window.

---

## Why this matters

Splitwise turns 14 next year and still feels like it. **Expense** is what a
money app should feel like in 2026 — **fast, animated, intentional, real-time,
beautiful in dark mode, useful offline, and built with the same care a fintech
team would put into a paid product**.

It's also a portfolio piece showing how the whole stack — Flutter, Node, Mongo,
Socket.io, JWT, PDF generation, charts, real-time UI — fits together cleanly.

— Abdul Moiz
