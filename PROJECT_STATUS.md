# Stalio — Project Status

> Stalio: Do. Tally. Grow. v1.0.0+5. Last updated: June 10, 2026

## Build

| Metric | Status |
|--------|--------|
| `flutter analyze` | 0 errors, 134 pre-existing warnings |
| `flutter test` | 320 tests pass, exit 0 |
| GitHub CI | ✅ Green (analyze + test on push) |
| Pre-commit hook | `scripts/pre-commit.sh` (analyze + test + secret scan) |
| iPhone 17 Pro | Running |
| iPad Air 11" M4 | Running |
| Android API 36 | Running |

## App Identity

| Field | Value |
|-------|-------|
| Name | Stalio |
| Tagline | Do. Tally. Grow. |
| Package | com.orbacetech.stalio |
| Version | 1.0.0+5 |
| Repo | https://github.com/justinzero888/stalio.git |

## Navigation (5 tabs)

```
[ My Day ]  [ Tallies ]  [  +  ]  [ Notes ]  [ Settings ]
```

## Store Builds

| Platform | Build | Artifact | Status |
|----------|-------|----------|--------|
| Android | 1.0.0 (5) | `app-release.aab` (70.1 MB) | Release-signed (CN=Stalio) |
| iOS | 1.0.0 (5) | `stalio.ipa` (43.9 MB) | App Store Connect (processing) |

## Phase Status

| Phase | Status | Tests | Sign-off |
|---|---|---|---|
| 1: Foundation & Branding | **Signed off** | 166 | ✓ |
| 2: Core Features | **Signed off** | 13 | ✓ |
| 3: UX & Localization | **Signed off** | 74 | ✓ (253 total) |
| 4: Feature Expansion | **Complete** | 67 (320 total) | Ready for QA |
| 5: Infrastructure & Monetization | **In progress** | — | — |

## Phase 4 Deliverables

| Day | Feature | Tests |
|-----|---------|-------|
| 1 | TagCategory model + repo + provider | 17 |
| 2 | DB migration v16→v17 | 3 |
| 3 | Settings Tags tab redesign (expandable categories) | 5 |
| 4 | Bulk tag operations (multi-select, assign, merge, recolor) | 4 |
| 5 | Tag analytics sub-tab in Tallies | 4 |
| 6 | Tag auto-suggest in Add Entry | 5 |
| 7 | Category filter chips in Notes tab | 4 |
| 8 | Export CSV with date range picker | 3 |
| 9 | Export PDF with title page, entries, summary | 4 |
| 10 | Notes share redesign (multi-select, format preview) | 9 |
| 11-14 | Maestro UAT flows + docs | 69 total |

## Phase 5 Deliverables

| Item | Feature | Status |
|------|---------|--------|
| 12 | AI dead code cleanup | ✅ Done |
| 13 | RevenueCat / Purchases cleanup | ✅ Done |
| 14 | CI/CD pipeline (.github/workflows/ci.yml) | ✅ Done |
| 15 | Pre-commit hooks | ✅ Done |
| 16 | Builds protocol (.builds/) | ✅ Done |
| 17 | Environment configuration | 🔲 Pending |
| 18 | Code coverage baseline | 🔲 Pending |
| 19 | Dependabot | 🔲 Pending |
| 20 | AdMob dependency (google_mobile_ads) | ✅ Dependency added |
| — | Bundle ID unification → com.orbacetech.stalio | ✅ Done |
| — | Release keystore (Android AAB signing) | ✅ Done |
| — | Info.plist privacy strings + encryption decl | ✅ Done |
| — | AdMob iOS GADApplicationIdentifier | ✅ Done |
| — | Business decisions record | ✅ Done |
| — | Gap analysis + automation roadmap | ✅ Done |

## Architecture

### Provider Tree
```
StorageService
├── EntryProvider       (notes CRUD, search, filter)
├── RoutineProvider     (habits CRUD, completion, voice scheduling)
├── TagProvider         (tag CRUD, merge, batch update)
├── TagCategoryProvider (category CRUD, reorder, delete cascade)
├── LocaleProvider      (EN/ZH)
├── ThemeProvider       (light/dark/system)
├── JarProvider         (emotion aggregation)
└── SummaryProvider     (chart metrics, tag analytics)
```

### Storage (SQLite schema v17)
- entries, tags (with category_id FK), tag_categories, entry_tags, routines, completions
- Stale tables: ai_identity, lens_sets, ai_call_log, templates, note_cards (Phase 6 cleanup)

## Maestro UAT Flows

| File | Flows | Phase |
|------|-------|-------|
| `phase1_branding.yaml` | 4 | Phase 1 |
| `phase1_navigation.yaml` | 7 | Phase 1 |
| `phase1_smoke.yaml` | 8 | Phase 1 |
| `phase2_backup_restore.yaml` | 4 | Phase 2 |
| `phase3_l10n.yaml` | 12 | Phase 3 |
| `phase3_dark_mode.yaml` | 11 | Phase 3 |
| `phase4_*.yaml` (8 files) | 34 | Phase 4 |
| **Total** | **80** | |

## Features

| Feature | Status |
|---------|--------|
| My Day — calendar, entries, habit check-in, emoji jar | Full |
| Moments — note list, search, tag/category filter, multi-select share | Full |
| Tallies — 4 sub-tabs: Habits, Notes, Moods, Tags | Full |
| Settings — General, Tags (expandable categories), Habit Build | Full |
| Tag management — CRUD, categories, bulk ops, auto-suggest | Full |
| Export — CSV + PDF with date range picker | Full |
| Emoji tracking (emotion picker + jar) | Full |
| Voice reminders (foreground TTS) | Full |
| Background notifications (OS-level) | Full |
| Bilingual UI (EN/ZH) | Full |
| Streak matrix heatmap | Full |
| Habit Build (create/edit/toggle with categories) | Full |
| Dark mode (light/dark/system with persistence) | Full |
| Backup/Restore UI (ZIP export + restore from file) | Full |

## Removed from Original App

Floating AI robot, AI services (LLM, personas, lens sets), RevenueCat/purchases, BYOK, Chorus social, voice transcribe, photo/camera picker, soft prompt, trial banners, paywall, AI Secrets tag, Blinking branding, onboarding transition screen, keepsake cards

## Documents

| Document | Purpose |
|----------|---------|
| `docs/STALIO_TEST_PLAN.md` | Test infrastructure + gates + protocol |
| `docs/UAT_PHASE4.md` | 74 manual UAT test cases |
| `docs/BUILD_TEST_VC_RULES.md` | Build, test, and version control rules |
| `docs/GAP_ANALYSIS.md` | 13 gaps + automation roadmap |
| `docs/BUSINESS_DECISIONS_RECORD.md` | All decisions + AdMob/IAP values |
| `docs/PHASE5_PLAN.md` | Phase 5 infrastructure + business prerequisites |
| `lesson_learned_06_10.md` | DB migration checklist |
| `works_item_0610.md` | Phase 4 work breakdown |
