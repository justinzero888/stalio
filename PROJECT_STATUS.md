# Stalio — Project Status

> Stalio: Do. Tally. Grow. v1.0.0+10. Last updated: June 17, 2026

## Build

| Metric | Status |
|--------|--------|
| `flutter analyze` | 0 errors, pre-existing warnings only |
| `flutter test` | 328 tests pass, 0 skipped |
| GitHub CI | Green (analyze + test on push) |
| Firebase Crashlytics | Integrated — degrades gracefully on sims |
| iPhone 17 Pro | Running (Phase 7 deployed, all freezes resolved) |
| iPhone 13 | Validated v1.0.0+10 — all 11 popup types, zero freezes |
| iPad Air 11" M4 | Running (Phase 7 deployed, all freezes resolved) |
| Android API 36 | Running (Phase 7 deployed, full functionality) |

## Bundle ID

`com.orbacetech.stalio` — unified across all platforms

## Performance Baseline

| Metric | Value |
|--------|-------|
| AAB size | 60.7 MB |
| IPA size | 33.4 MB |
| DB schema | v19 with 6 core tables |
| Habit library | 54 habits (CSV-based), 12 categories |
| Deployment cycle | kill → uninstall → rebuild → fresh install (Lesson #11) |

---

## Phase Status

| Phase | Status | Key Deliverable |
|---|---|---|
| 1–3 | Signed off | Branding, backup/restore, localization, dark mode |
| 4 | Complete | Tags, export, share, analytics |
| 5 | Complete | AdMob, IAP, CI/CD, builds protocol, Firebase |
| 6 | Complete | DB cleanup, default categories, perf baseline |
| **7** | **Complete** | **3-tab nav, onboarding, 11 popup types, 54-habit library** |

---

## Phase 7 Deliverables

| # | Feature | Status |
|---|---------|--------|
| 7a | Foundation — Routine model v2, v19 schema, 54 habits, 12 categories | Done |
| 7b | Onboarding flow — 3 screens + full library browser + startup gate | Done ✅ |
| 7c | Popup factory — 11 tracking types dispatched by `trackingUiType` | Done |
| 7d | Tag system — habit name from metadata, free-form tags, backup/restore | Done |
| P1 | First-time tooltips per tracking type | Done |
| P1 | Help panel bottom sheet | Done |
| P1 | Free-form tag input on popups | Done |

---

## Navigation (3 tabs)

```
[ Daily ]  [ Tallies ]  [ Settings ]
    │           │
    │           ├── Habits (charts, streaks, completion)
    │           └── Notes  (search, browse, filter)
    │
    └── Calendar + Habit Checklist (tap → type-specific popup)
```

---

## Features

| Feature | Status |
|---------|--------|
| Daily — calendar, habit checklist, 11 type-specific popups | Full |
| Tallies — Habits + Notes sub-tabs | Full |
| Settings — General, Tags, Habit Build, Backup/Restore | Full |
| Onboarding — 3-screen flow with 54-habit library | Full ✅ |
| Tag management — categories, bulk ops, auto-suggest | Full |
| Export — CSV + PDF with date range picker | Full |
| Voice reminders | Full |
| Bilingual UI (EN/ZH) | Full |
| Dark mode | Full |
| Backup/Restore — ZIP export/import, clear-before-restore | Full |
| AdMob banners + Remove Ads IAP ($3.99) | Full |
| Firebase Crashlytics | Deployed (degraded on sims) |

---

## Remaining Work

| Priority | Item | Effort |
|----------|------|--------|
| P2 | `in_app_purchase` Android implementation | 2h |
| P2 | Widget extensions (iOS/Android home screen) | 3h |
| P2 | Split `cherished_memory_screen.dart` (refactor) | 2h |
| — | Apple Watch companion | **Deferred** |

---

## Known Issues

| # | Description | Platform | Severity |
|---|-------------|----------|----------|
| 1 | iOS 26 simulator with clipboard content: `UIPasteboard.hasStrings` blocks indefinitely (OS bug, not our code) | Simulator only | — |
| 2 | Android `in_app_purchase` not implemented | Android | P2 |

## Documents

| Document | Purpose |
|----------|---------|
| `docs/STALIO_TEST_PLAN.md` | Test infrastructure + gates |
| `docs/UAT_PHASE4.md` | Phase 4 UAT (74 cases) |
| `docs/UAT_PHASE5.md` | Phase 5 UAT (56 cases) |
| `docs/UAT_PHASE6.md` | Phase 6 UAT (28 cases) |
| `docs/BUILD_TEST_VC_RULES.md` | Build, test, VC rules |
| `docs/GAP_ANALYSIS.md` | Process gaps + roadmap |
| `docs/BUSINESS_DECISIONS_RECORD.md` | All decisions + AdMob/IAP values |
| `docs/PHASE7_PLAN.md` | UI simplification plan |
| `docs/FIREBASE_SETUP.md` | Firebase setup guide |
| `docs/APP_STORE_DESCRIPTION.md` | Store listing |
| `docs/RCA_IOS_ONBOARDING_BUTTONS.md` | iOS onboarding freeze RCA |
| `docs/Stalio — Popup UI Component Design Specification/` | Popup UI specs |
| `docs/Stalio onboarding flow/` | Onboarding flow design |
