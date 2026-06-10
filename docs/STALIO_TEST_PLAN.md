# Stalio Test Plan

> **Version:** 1.0.0 | **Date:** June 10, 2026  
> **References:** `dev-cycle-playbook.md`, `dev-test-collaboration.md`, `DEVELOPER-PLAYBOOK.md`  
> **App:** Stalio (Flutter) | **Repo:** `ClaudeDev/stalio/`

---

## 1. Test Infrastructure

### 1.1 Current State

| Metric | Value |
|--------|-------|
| Total tests | **320** |
| Unit/widget tests | 309 |
| Integration tests | 6 (DB migration + export roundtrip) |
| UAT flows (Maestro) | Phase 4: `test/maestro/phase4_*.yaml` |
| Pipeline analysis | 0 errors (warnings only, all pre-existing) |
| Device sims | iPhone 17 Pro, iPad Air 11" M4, Android API 36 |

### 1.2 Test Files by Category

| Category | Directory | Count | Phase |
|----------|-----------|-------|-------|
| Model tests | `test/models/` | 5 files | Phase 3–4 |
| Provider tests | `test/providers/` | 7 files | Phase 3–4 |
| Core/service tests | `test/core/` | 5 files | Phase 2–4 |
| Screen/widget tests | `test/screens/` | 9 files | Phase 2–4 |
| Integration tests | `test/integration/` | 4 files | Phase 2–4 |
| Widget smoke tests | `test/widgets/` | 2 files | Phase 3 |
| L10n audit tests | `test/l10n/` | 4 files | Phase 3 |
| Maestro UAT flows | `test/maestro/` | TBD | Phase 4 |

---

## 2. Test Gate Sequence (Every Build)

Inherited from `dev-cycle-playbook.md` §4 (Three-Gate Pre-Deployment Sequence).

### Gate 1 — CI & Static Analysis

| Check | Command | Standard | Owner |
|-------|---------|----------|-------|
| Static analysis | `flutter analyze --no-pub` | 0 errors | Dev |
| Unit + Widget + Integration | `flutter test` | All pass, 0 regressions | Dev |
| File line count sanity | `wc -l <key-files>` | No unexpected changes | Dev |

**Run before every handoff to test:**
```bash
flutter analyze --no-pub && flutter test
```

### Gate 2 — Simulator Deploy (All Three Platforms)

| Platform | Command | Check |
|----------|---------|-------|
| iPhone 17 Pro | `xcrun simctl install` + `launch` | App opens, bottom nav visible |
| iPad Air 11" M4 | `xcrun simctl install` + `launch` | App opens, bottom nav visible |
| Android API 36 | `adb install` + `am start` | App opens, bottom nav visible |

**Smoke check (per device):**
1. App launches without crash
2. Bottom nav visible (My Day, Moments, Tallies, Settings)
3. Add Entry screen accessible
4. Settings → Tags tab renders
5. Settings → About → version correct

### Gate 3 — UAT + Release Artifacts

| Step | Action | Standard |
|------|--------|----------|
| 3.1 | `flutter test` | All pass |
| 3.2 | Maestro UAT on all 3 platforms | All flows pass |
| 3.3 | Manual UAT (human, real devices) | Release checklist complete |
| 3.4 | Build AAB + IPA | Production artifacts |

---

## 3. Phase 4 Test Case Inventory

### 3.1 New Tests (69 total, target was 49)

| # | File | Tests | Description |
|---|------|-------|-------------|
| 1 | `test/models/tag_category_test.dart` | 6 | CRUD, serialization, defaults, locale |
| 2 | `test/providers/tag_category_provider_test.dart` | 11 | CRUD, reorder, delete, sort, notification |
| 3 | `test/models/entry_share_format_test.dart` | 9 | Plain text/Markdown/Rich (3 per format) |
| 4 | `test/core/export_pdf_test.dart` | 4 | PDF header, content, date filter, onProgress |
| 5 | `test/core/export_csv_test.dart` | 3 | ZIP validity, date range, routines.csv |
| 6 | `test/integration/phase4_tag_migration_test.dart` | 3 | Column added, data preserved, schema correct |
| 7 | `test/integration/phase4_export_roundtrip_test.dart` | 2 | CSV → ZIP header, PDF → header + %%EOF |
| 8 | `test/screens/notes_share_selection_test.dart` | 6 | Long-press, toggle, deselect, preview, cancel, close |
| 9 | `test/screens/notes_share_preview_test.dart` | 3 | Content render, Share button, Save button |
| 10 | `test/screens/tag_category_ui_test.dart` | 9 | Expand/collapse, add/edit/delete dialogs |
| 11 | `test/screens/tag_analytics_test.dart` | 4 | Empty state, top tags, co-occurrence, timeline |
| 12 | `test/screens/tag_autosuggest_test.dart` | 5 | EN keyword, ZH keyword, no match, sparkle, select remove |
| 13 | `test/screens/category_filter_chips_test.dart` | 4 | Chips render, hide, filter, All clears |

### 3.2 Regression Test Coverage

| Screen | Tests Covering | Status |
|--------|---------------|--------|
| Home (`home_screen.dart`) | Widget rendering, calendar, FAB, bottom nav | ✅ |
| Moments (`moment_screen.dart`) | Filter chips, category chips, multi-select, share preview | ✅ |
| Tallies (`cherished_memory_screen.dart`) | Habits/Notes/Moods tabs, Tags analytics tab | ✅ |
| Settings (`settings_screen.dart`) | General (voice/theme/lang), Tags (categories/bulk), Habits, Backup/Restore, CSV/PDF Export | ✅ |
| Add Entry (`add_entry_screen.dart`) | Tag auto-suggest, format switch, media, list items | ✅ |

---

## 4. Severity Classification

Inherited from `dev-cycle-playbook.md` Appendix A and `dev-test-collaboration.md` §2.

### Automated UAT (Maestro)

| Severity | Symptom | Dev SLA |
|----------|---------|---------|
| **P0-human** | App crash, blank screen, data loss | Drop everything |
| **P1-human** | Feature broken for all input methods | Fix before release |
| **P2-automation** | Works with finger tap, fails with accessibility tap | Batch at EOD |
| **P3-cosmetic** | Visual misalignment only | Defer to next release |

### Manual UAT (Human)

| Severity | If... | Rule |
|----------|-------|------|
| **P0-human** | App crashes, data lost, save doesn't work | Fix immediately |
| **P1-human** | Feature works but output is wrong | Fix before release |
| **P3-cosmetic** | Visual nitpick (alignment off by 1px) | Defer |

**Heuristic:** "Would a paying user complain?" → P1. "Would they uninstall?" → P0.

---

## 5. Dev–Test Handoff Protocol

Inherited from `dev-test-collaboration.md` §1–4.

### 5.1 Dev → Test: Build Notification

Every push must include:

```
🔨 Build ready — commit <hash>
   Files: <changed files>
   What: <what changed, which feature/fix>
   Sims: iPhone 17 Pro ✅ | iPad Air M4 ✅ | Android ✅
```

### 5.2 Test → Dev: Bug Report

Required for every defect:

```
Title: <ID> — <one-line description>
Platform: iPhone 17 Pro / iPad Air M4 / Android
Flow: <maestro flow name>
Commit tested: <hash>
Steps: (numbered, with ✅/❌ per step)
Evidence:
- Screenshot at failure point
- Maestro hierarchy dump
- Video (if available)
Suspect: <file:line>
```

### 5.3 Dev → Test: Fix Verification

```
Root cause: [1-2 sentences]
Fix: [1-2 sentences]
Commit: <hash>
Verification: flutter analyze 0 errors, flutter test 320/320 pass
```

### 5.4 Shared Definitions of Done

| State | Meaning |
|-------|---------|
| **Open** | Bug reported, awaiting dev |
| **In Progress** | Dev has root cause + fix approach |
| **Fixed** | Dev pushed fix, awaiting test verification |
| **Verified** | Test confirmed on all 3 platforms |
| **Closed** | Fix merged, no regressions |

---

## 6. Builds Protocol (Micro Cycle)

Inherited from `dev-cycle-playbook.md` §3.2.

### State Machine

```
testing(idle) → testing(running) → verified
     ↑                │                  │
     │                ▼                  ▼
     └─────────── fixing ←────── deploying (PM approval)
```

### File Reference

| File | Writer | Reader | Purpose |
|------|--------|--------|---------|
| `.builds/current.json` | Dev | Test, PM | Build metadata (commit, files, sims) |
| `.builds/results.json` | Test | Dev, PM | Maestro test results |
| `.builds/state.json` | Both | Everyone | Phase + defect tracker |
| `.builds/DASHBOARD.md` | Auto | PM, Human | Ship Gate status |
| `.builds/uat/manual-checklist.md` | Dev | Human | Manual test cases |
| `.builds/dumps/*.txt` | Test | Dev | Hierarchy dumps for failures |

### Dev Pre-Build Checklist
```bash
flutter analyze --no-pub          # 0 errors
flutter test                       # 320 pass (or higher)
bash scripts/publish-build.sh "<fixes>" "<files>"
```

---

## 7. Maestro UAT Flow Reference

Flows live in `test/maestro/phase4_*.yaml`. Each flow exercises one acceptance criterion.

### Phase 4 Flows (to be created)

| Flow | Covers | Platforms |
|------|--------|-----------|
| `phase4_tag_categories.yaml` | Create/edit/delete tag categories, expand/collapse | All 3 |
| `phase4_bulk_operations.yaml` | Multi-select, assign category, merge, recolor | All 3 |
| `phase4_tag_analytics.yaml` | Tallies → Tags tab: charts, co-occurrence, timeline | All 3 |
| `phase4_export_csv.yaml` | Settings → Export CSV → date range → share | All 3 |
| `phase4_export_pdf.yaml` | Settings → Export PDF → date range → share | All 3 |
| `phase4_notes_share.yaml` | Moments → multi-select → share preview → format switch → share | All 3 |
| `phase4_tag_autosuggest.yaml` | Add Entry → type keyword → suggested tags appear | All 3 |
| `phase4_category_filters.yaml` | Moments → category filter chips → filter entries | All 3 |

### Maestro Run Commands
```bash
# Single flow on single platform
maestro test test/maestro/phase4_tag_categories.yaml

# Full Phase 4 suite
maestro test test/maestro/phase4_*.yaml
```

---

## 8. DB Migration Safety

Inherited from `lesson_learned_06_10.md`.

### Migration Checklist (any schema change)

1. Update model (`toJson`, `fromJson`, `copyWith`)
2. Update storage read mapper (`get*()` — `map['camel'] = m['snake']`)
3. Update storage write (`add*()`, `update*()` — `'snake': model.camel`)
4. Update `_onCreate` (gate with `if (version >= N)`)
5. Add `_onUpgrade` block (`oldVersion < N` with PRAGMA existence check)
6. Bump `kSchemaVersion`
7. Update `createTestDatabase` default → `kSchemaVersion`
8. Update `runMigration` target → `kSchemaVersion`
9. Update `db_version_test.dart` assertion
10. Update all `_MockStorageService` classes

### Test Infra Invariants
- `createTestDatabase` default → `kSchemaVersion`
- `runMigration` target → `kSchemaVersion`
- `db_version_test.dart` → `kSchemaVersion`
- `_onCreate` version-gated for new tables/columns

---

## 9. File Safety Rules

From Phase 3–4 execution experience:

| Rule | File | Reason |
|------|------|--------|
| **sed only** | `cherished_memory_screen.dart` (1609 lines) | Repeating code patterns cause `replaceAll` corruption |
| **Verify line count** | After every edit | `wc -l` as sanity check |
| **Keep git tag updated** | `safe-rollback` tag | After every successful change |
| **Split large classes** | During refactoring phases | Threshold: >1000 lines |
| **Public for cross-file use** | Private classes used across files | Make public |

---

## 10. Continuous Integration

| Trigger | What Runs |
|---------|-----------|
| PR / push to master | `flutter analyze` + `flutter test` |
| Nightly | Full Maestro suite on all 3 sims |
| Pre-release | Gate 1 → Gate 2 → Gate 3 |

---

## Appendix A — Test Execution Quick Reference

```bash
# Full suite
flutter test

# Specific category
flutter test test/models/
flutter test test/providers/
flutter test test/screens/
flutter test test/core/
flutter test test/integration/

# Single file
flutter test test/models/tag_category_test.dart

# With analysis
flutter analyze --no-pub && flutter test
```

## Appendix B — Key File Map

```
ClaudeDev/stalio/
├── lib/
│   ├── models/          ← Data models (Tag, TagCategory, Entry, etc.)
│   ├── repositories/    ← Data access layer
│   ├── providers/       ← State management (ChangeNotifier)
│   ├── core/services/   ← Database, export, storage, voice
│   ├── core/utils/      ← ShareFormat, CSV utils
│   └── screens/         ← UI screens
├── test/
│   ├── models/          ← Model unit tests
│   ├── providers/       ← Provider unit tests
│   ├── core/            ← Service unit tests
│   ├── screens/         ← Widget tests
│   ├── integration/     ← DB migration + export roundtrip
│   ├── widgets/         ← Smoke tests
│   ├── l10n/            ← Localization audit
│   └── maestro/         ← Maestro UAT flows
├── docs/                ← Documentation
│   ├── STALIO_TEST_PLAN.md  ← This file
│   └── UAT_PHASE4.md        ← Manual UAT checklist
├── lessons_learned/     ← Execution notes for next team
└── works_item_0610.md   ← Phase 4 work breakdown
```
