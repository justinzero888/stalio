# Stalio — Project Status

> Stalio: Do. Tally. Grow. v1.0.0+9. Last updated: June 14, 2026

## Build

| Metric | Status |
|--------|--------|
| `flutter analyze` | 0 errors, 117 pre-existing warnings |
| `flutter test` | 321 tests pass, 2 skipped (habit dialog rewrite) |
| GitHub CI | ✅ Green (analyze + test on push) |
| Firebase Crashlytics | ✅ Integrated — degrades gracefully on sims |
| iPhone 17 Pro | Running (Phase 7 UI deployed) |
| iPad Air 11" M4 | Running (Phase 7 UI deployed) |
| Android API 36 | Running (Phase 7 UI deployed) |

## Bundle ID

`com.orbacetech.stalio` — unified across all platforms

## Performance Baseline

| Metric | Value |
|--------|-------|
| AAB size | 57 MB |
| IPA size | 30 MB |
| DB schema | 6 core tables |
| Dead code | ~10 MB assets + ~1,280 lines AI/RevenueCat code removed |

---

## Phase Status

| Phase | Status | Key Deliverable |
|---|---|---|
| 1–3 | Signed off | Branding, backup/restore, localization, dark mode |
| 4 | Complete | Tags, export, share, analytics (320 tests) |
| 5 | Complete | AdMob, IAP, CI/CD, builds protocol, Firebase |
| 6 | Complete | DB cleanup (v18), default categories, perf baseline |
| **7** | **In progress** | **UI simplification — 3-tab nav, habit→note dialog** |

---

## Phase 7 Current State

### Done ✅

| Item | Feature | Lines Changed |
|------|---------|---------------|
| 28a | 5→3 tabs: Daily, Tallies, Settings | app.dart (rewrite) |
| 28b | Tallies 4→2 sub-tabs: Habits + Notes | cherished_memory_screen.dart |
| 29 | RoutineNoteDialog — tap habit → note input | routine_note_dialog.dart (new, 151 lines) |
| 30 | Mood jar removed from Daily | home_screen.dart (-110 lines) |
| 31 | Habit notes auto-tagged (category + habit name) | routine_note_dialog.dart |

### Remaining 🔲

| Item | What | Effort |
|------|------|--------|
| P7.1 | Rewrite 2 skipped habit-tap widget tests | 2h |
| P7.2 | Remove dead classes from cherished_memory_screen (safe sed pass) | 1h |
| P7.3 | Remove JarProvider + EmojiJarWidget dead code | 1h |
| P7.4 | Add entry_metadata field to link note→routine | 2h |
| P7.5 | "Skip" button on writing habits should not check off habit | 1h |
| P7.6 | Release build (AAB + IPA) for beta/testing | 1h |

---

## Navigation (3 tabs)

```
[ Daily ]  [ Tallies ]  [ Settings ]
    │           │
    │           ├── Habits (charts, streaks, completion, tags)
    │           └── Notes  (search, browse, filter habit notes)
    │
    └── Calendar + Habit Checklist (tap → note dialog)
```

## Features

| Feature | Status |
|---------|--------|
| Daily — calendar, habit checklist, tap→note flow | Full (Phase 7) |
| Tallies — Habits + Notes sub-tabs | Full (Phase 7) |
| Settings — General, Tags, Habit Build | Full |
| Tag management — categories, bulk ops, auto-suggest | Full |
| Export — CSV + PDF with date range picker | Full |
| Voice reminders | Full |
| Bilingual UI (EN/ZH) | Full |
| Dark mode | Full |
| Backup/Restore | Full |
| AdMob banners + Remove Ads IAP ($3.99) | Full |
| Firebase Crashlytics | Deployed (degraded on sims) |

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
| `docs/PHASE5_PLAN.md` | Infrastructure plan |
| `docs/PHASE6_PLAN.md` | Polish + cleanup plan |
| `docs/PHASE6_ITEM23_REDESIGN.md` | File split SWOT |
| `docs/PHASE7_PLAN.md` | UI simplification plan |
| `docs/FIREBASE_SETUP.md` | Firebase setup guide |
| `docs/APP_STORE_DESCRIPTION.md` | Store listing |
