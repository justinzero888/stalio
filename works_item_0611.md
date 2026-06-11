# Stalio — works_item_0611.md

> Phase 5: Infrastructure & Monetization | June 11, 2026  
> Prerequisite: Phase 4 QA sign-off

---

## Current State (after Phase 4 + Phase 5 partial)

- 320 tests pass, zero analysis errors, CI green
- All 5 screens localized (EN ↔ ZH)
- Dark mode with system-follow + persistence
- Backup/restore UI wired
- Tag categories + bulk operations + auto-suggest
- CSV/PDF export with date range picker
- Notes multi-select share with format preview
- Bundle ID unified: `com.orbacetech.stalio`
- Repo: `https://github.com/justinzero888/stalio.git`
- Store builds: Android AAB (release-signed) + iOS IPA (App Store Connect)
- GitHub CI: ✅ Green (analyze + test on push)
- Pre-commit hook: `scripts/pre-commit.sh`

---

## Phase 5 Remaining Items

### Item 17: Environment Configuration `[Priority #5]`

| Feature | Description |
|---------|-------------|
| Environment enum | dev / staging / production with `--dart-define` flags |
| Config class | `EnvConfig` with AdMob IDs, bundle ID, app name per environment |
| `.env.example` | Template for required environment variables |

**Key files:**
- `lib/core/config/environment.dart` — new
- `.env.example` — new
- Update `lib/main.dart` to use environment config

**Acceptance criteria:**
- Staging/production builds use different AdMob IDs
- No hardcoded secrets in source code
- `.env.example` documents all required variables

---

### Item 18: Code Coverage Baseline `[Priority #6]`

**Add to CI:**
```yaml
- run: flutter test --coverage
```

**Acceptance criteria:**
- Coverage report generated per commit
- 70% minimum line coverage target set

---

### Item 19: Dependabot Configuration `[Priority #7]`

**File:** `.github/dependabot.yml`

**Acceptance criteria:**
- Weekly dependency update PRs
- Security alerts enabled

---

### Item 20: AdMob Banner Integration `[Priority #8]`

**Values received:**
```
Android Banner: ca-app-pub-7497527413129091/1333457063
iOS Banner:     ca-app-pub-7497527413129091/1302206478
```

| Feature | Description |
|---------|-------------|
| AdService | Initialize MobileAds, create banner ads |
| Settings banner | Banner at bottom of Settings → General tab |
| My Day banner | Banner at bottom of My Day screen |
| Test mode | Use AdMob test IDs during development |

**Key files:**
- `lib/core/services/ad_service.dart` — new
- `lib/screens/settings/settings_screen.dart` — add banner
- `lib/screens/home/home_screen.dart` — add banner

---

### Item 21: `remove_ads` IAP Integration `[Priority #9]`

**Blocked on:** Business owner creating IAP products in Google Play Console + App Store Connect.

**Product ID:** `remove_ads`  
**Price:** $2.99

| Feature | Description |
|---------|-------------|
| Purchase flow | Buy `remove_ads` → store `hasRemovedAds = true` in SharedPreferences |
| Restore purchases | Button to restore previous purchase |
| Hide ads | Check `hasRemovedAds` before creating banners |
| Edge cases | Network errors, cancelled purchases, already purchased |

**Key files:**
- `lib/core/services/iap_service.dart` — new (Google Play Billing + StoreKit)
- `lib/providers/iap_provider.dart` — new
- `lib/screens/settings/settings_screen.dart` — add "Remove Ads" purchase tile

---

## Phase 5 Tasks — Sequential Breakdown

| Day | Item | Task | Output | Effort |
|-----|------|------|--------|--------|
| 1 | 17 | Environment config | `environment.dart` + `.env.example` | 2h |
| 1 | 18 | Code coverage | Coverage in CI + 70% target | 1h |
| 1 | 19 | Dependabot | `.github/dependabot.yml` | 0.5h |
| 2 | 20 | AdMob banner integration | `ad_service.dart` + banners on 2 screens | 3h |
| 3 | 21 | IAP purchase flow | `iap_service.dart` + purchase/restore UI | 4h |
| 4 | — | IAP testing + edge cases | Test cards, sandbox, restore, error states | 3h |
| 5 | — | Regression QA | Full test suite + Maestro + manual UAT | 2h |

---

## Phase 6 Pre-Work (Parallel)

### DB Schema Cleanup
- Drop stale tables: `ai_identity`, `lens_sets`, `active_lens_set`, `ai_call_log`, `ai_summary`, `templates`, `note_cards`, `note_card_entries`, `card_folders`
- Migration v17→v18 with rollback test
- Reduce schema from 14 tables to 5 core tables

### `cherished_memory_screen.dart` Split
- Current: 1609 lines (sed-only for edits)
- Split into: `habits_tab.dart`, `notes_tab.dart`, `moods_tab.dart`, `tags_tab.dart`
- Each under 400 lines

### Known Issues
- Cold start ~2s (Android emulator)
- `cherished_memory_screen.dart` is 1609 lines — needs split during Phase 6
- Stale DB tables (templates, cards, AI) still in schema
- No crash reporting (Firebase Crashlytics planned for Phase 7)

---

## Business Owner Blockers

| # | Blocker | Impact | Resolution |
|---|---------|--------|------------|
| 1 | `remove_ads` IAP product not created (Google Play) | Blocks Item 21 | Create product in Google Play Console |
| 2 | `remove_ads` IAP product not created (App Store) | Blocks Item 21 | Create product in App Store Connect |
| 3 | Google Play Console app metadata not filled | Blocks Android internal testing | Screenshots, description, content rating |
| 4 | App Store Connect metadata not filled | Blocks iOS TestFlight distribution | Screenshots, description, age rating |
