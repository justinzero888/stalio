# Stalio — Phase 6: Polish & Schema Cleanup — Design & Implementation Plan

> **Date:** June 13, 2026  
> **Pre-requisite:** Phase 5 UAT sign-off  
> **Est. Effort:** 6–8 days  
> **Target:** Production-ready codebase  
> **Clarifications from business owner:** (1) Category consistency — use habit categories as base for tag categories; language should use standard locale. (2) Firebase is NOT being decommissioned; Crashlytics is free on Spark tier.

---

## 0. Phase 6 Goals

1. **Performance:** Eliminate dead schema tables and asset bloat
2. **Maintainability:** Split the 1609-line monolith into composable files
3. **Observability:** Add crash reporting (Firebase Crashlytics)
4. **Measurability:** Baseline cold-start time and test coverage

---

## Item 22: DB Schema Cleanup `[Priority #1]`

### Design Intent

Stalio's SQLite schema (version 17) contains 9 tables inherited from Blinking Notes that are never read or written by any Dart code. These tables exist in every user's database, taking up disk space and creating maintenance burden.

**Stale tables to drop:**
```
ai_identity        — AI assistant persona config
lens_sets          — AI lens/analysis sets
active_lens_set    — Active AI lens reference
ai_call_log        — AI interaction history
trial_milestones   — Trial period tracking
templates          — Note card templates (8 RedNotes templates)
card_folders       — Note card organization
note_cards         — Rendered note card instances
note_card_entries  — Card-to-entry join table
```

**Core tables to keep:**
```
entries, tags, tag_categories, entry_tags, routines, completions
```

### Implementation Plan

**Step 1 — Verify zero Dart references**
```bash
grep -rn 'ai_identity\|lens_set\|ai_call_log\|trial_milestones\|templates\|card_folders\|note_cards\|note_card_entries' lib/ --include='*.dart' | grep -v database_service.dart
```
Expected: zero results outside migration code.

**Step 2 — Create migration v17→v18**

```dart
// database_service.dart _onUpgrade
if (oldVersion < 18) {
  await db.execute('DROP TABLE IF EXISTS ai_identity');
  await db.execute('DROP TABLE IF EXISTS lens_sets');
  await db.execute('DROP TABLE IF EXISTS active_lens_set');
  await db.execute('DROP TABLE IF EXISTS ai_call_log');
  await db.execute('DROP TABLE IF EXISTS trial_milestones');
  await db.execute('DROP TABLE IF EXISTS note_card_entries');
  await db.execute('DROP TABLE IF EXISTS note_cards');
  await db.execute('DROP TABLE IF EXISTS card_folders');
  await db.execute('DROP TABLE IF EXISTS templates');
}
```

**Step 3 — Update _onCreate**

Remove table creation statements for all 9 dropped tables. `_onCreate` should only create the 6 core tables for fresh installs.

**Step 4 — Update schema version**

`kSchemaVersion = 18`

**Step 5 — Migration test**

Create DB at v17 → insert test data in core tables → run v18 migration → verify:
- Core tables (entries, tags, etc.) data intact
- Stale tables no longer exist (`PRAGMA table_info` returns empty)
- App functions normally with migrated DB

**Step 6 — Rollback safety**

Since `DROP TABLE` is destructive, add a pre-migration backup warning comment. The migration only drops tables that are confirmed zero-code-access.

### Acceptance Criteria
- [ ] 9 stale tables dropped on upgrade (v17→v18)
- [ ] 9 stale tables absent from fresh installs
- [ ] 6 core tables + data preserved
- [ ] DB file size reduced (measured on a device with seed data)
- [ ] 320 tests pass, migration test included

### Risk
- **Low.** Tables are confirmed dead — no Dart code reads or writes them. The migration is `DROP TABLE IF EXISTS` which is idempotent and safe.

---

## Item 23: Split `cherished_memory_screen.dart` `[Priority #2]`

### Design Intent

`cherished_memory_screen.dart` is currently 1609 lines — beyond the edit tool's safe limit. The file contains 4 sub-tabs (Habits, Notes, Moods, Tags) each implemented as a private widget class. Splitting into 4 files eliminates the "sed-only" constraint and makes future edits safe.

### Current Structure

```
cherished_memory_screen.dart (1609 lines)
├── InsightsScreen          — top-level Scaffold
├── _InsightsContent        — stateful tab controller
├── _HeroStatsRow           — summary stats bar
├── _HabitsTab              — habits completion chart
├── _NotesTab               — notes count + word cloud
├── _MoodsTab               — mood distribution chart
├── _TrendCharts            — line charts (unused, dead!)
├── _buildRoutineTile       — routine list item helper
├── _routineCategoryName    — localization helper
└── _buildStatRow           — stat display helper
```

### Target Structure

```
cherished_memory_screen.dart (~200 lines)
├── InsightsScreen
└── _InsightsContent

tallies/habits_tab.dart (~350 lines)
├── _HabitsTab
├── _buildRoutineTile
└── _buildStatRow

tallies/notes_tab.dart (~200 lines)
└── _NotesTab

tallies/moods_tab.dart (~300 lines)
├── _MoodsTab
└── _TrendCharts (drop if confirmed dead)

tallies/tags_tab.dart (~250 lines)
└── TagAnalyticsTab (imported from existing file)

tallies/hero_stats_row.dart (~100 lines)
└── _HeroStatsRow
```

### Implementation Plan

**Step 1 — Audit dead code**

`_TrendCharts` is marked `unused_element` in analyze output. Confirm zero usage, remove from split.

**Step 2 — Extract _HabitsTab (sed)**

1. Copy lines defining `class _HabitsTab` through its closing `}` to `tallies/habits_tab.dart`
2. Also extract `_buildRoutineTile` and `_buildStatRow` helpers
3. Add necessary imports (fl_chart, provider, models)
4. Make classes public if needed (`HabitsTab` instead of `_HabitsTab`)
5. In cherished_memory_screen.dart: replace class body with `import` + widget usage

**Step 3 — Repeat for Notes, Moods, Tags**

Same process. Each extracted file gets:
- File header comment with original source reference
- All necessary imports
- Public class names for cross-file use
- Any helper methods that were previously private

**Step 4 — Extract _HeroStatsRow**

Small shared widget used across tabs. Move to `tallies/hero_stats_row.dart`.

**Step 5 — Clean up cherished_memory_screen.dart**

After extraction, the file should be ~200 lines:
```dart
class InsightsScreen extends StatelessWidget { ... }
class _InsightsContent extends StatefulWidget { ... }
class _InsightsContentState extends State<_InsightsContent> {
  // TabController + HeroStatsRow + TabBar + TabBarView
}
```

**Step 6 — Verify**

- `flutter analyze` 0 errors
- `flutter test` all 320 pass
- Visual check: all 4 tabs render identically
- `wc -l cherished_memory_screen.dart` < 250
- Each split file < 400 lines

### Acceptance Criteria
- [ ] `cherished_memory_screen.dart` < 250 lines (from 1609)
- [ ] 4 new files in `lib/screens/cherished/tallies/`
- [ ] All tab widgets work identically to pre-split
- [ ] Dead `_TrendCharts` widget removed
- [ ] "sed-only" restriction lifted for this screen
- [ ] 320 tests pass

### Risk
- **Medium.** The file is known to have repeating code patterns. The split must use sed for line-level extraction, not the edit tool. Each extraction is verified by `wc -l` sanity check before proceeding.

---

## Item 24: Dead Asset & Import Cleanup `[Priority #3]`

### Design Intent

After Phase 5's asset removal (10 MB saved), audit remaining assets and imports for dead references.

### Implementation Plan

**Step 1 — Asset audit**
```bash
# Check each pubspec asset directory for Dart references
for dir in assets/*/; do
  refs=$(grep -rn "$dir" lib/ --include='*.dart' | wc -l)
  echo "$dir: $refs refs"
done
```

**Step 2 — Import audit**
```bash
# Find unused imports (already flagged as warnings in analyze output)
flutter analyze lib/ --no-pub 2>&1 | grep 'unused_import'
```

**Step 3 — Remove dead assets and imports**

Any asset directory with zero references → remove from pubspec + delete directory. Any `unused_import` flagged by analyze → remove.

**Step 4 — Verify**

`flutter analyze` — zero new issues. `flutter test` — still 320.

### Acceptance Criteria
- [ ] Zero dead asset directories in pubspec.yaml
- [ ] Zero unused imports in lib/
- [ ] Bundle size measured and documented

### Risk
- **Low.** Dead code removal is verifiable by analyze + test.

---

## Item 25: Crash Reporting (Firebase Crashlytics) `[Priority #4]`

### Design Intent

Production crashes are currently invisible. Firebase Crashlytics provides real-time crash reporting with stack traces, device info, and user impact metrics.

### Firebase Cost Analysis

**Firebase is NOT being decommissioned** — actively maintained with new features (AI assistance in Crashlytics added recently). Deprecation rumors are false.

| Plan | Monthly Cost | Crashlytics | Credit Card Required |
|------|-------------|-------------|---------------------|
| Spark (Free) | $0 | ✅ Unlimited | No |
| Blaze (Pay-as-you-go) | Usage-based | ✅ Unlimited | Yes |

**Recommendation:** Proceed with Spark (free) plan. Zero cost risk. No upgrades needed unless other Firebase services exceed free limits (unlikely for Stalio's usage profile — Crashlytics has no usage limits at all).

### Implementation Plan

**Step 1 — Add Firebase packages**
```yaml
# pubspec.yaml
firebase_core: ^3.6.0
firebase_crashlytics: ^4.1.0
```

**Step 2 — Platform configuration**

Android: Add `google-services.json` to `android/app/` (from Firebase console).  
iOS: Add `GoogleService-Info.plist` to `ios/Runner/` (from Firebase console).  
Both: Add Firebase initialization to AppDelegate/MainActivity if needed.

**Step 3 — Initialize in main.dart**
```dart
await Firebase.initializeApp();
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
PlatformDispatcher.instance.onError = (error, stack) {
  FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  return true;
};
```

**Step 4 — Privacy compliance**

Stalio's privacy claim ("zero data leaves the device") must be updated. Add to Privacy Policy:
```
Firebase Crashlytics collects anonymous crash data to help us improve app stability.
No personal data or journal content is collected. You can opt out in Settings.
```

Add a toggle in Settings → General:
```dart
SwitchListTile(
  title: Text('Crash Reporting'),
  subtitle: Text('Send anonymous crash reports to help improve Stalio'),
  value: crashReportingEnabled,
  onChanged: (v) {
    FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(v);
  },
),
```

**Step 5 — Test**

Force a test crash: `FirebaseCrashlytics.instance.crash()`. Verify crash appears in Firebase console within 5 minutes.

### Acceptance Criteria
- [ ] Crashlytics initialized on app startup
- [ ] Test crash appears in Firebase console
- [ ] Privacy policy updated with Crashlytics disclosure
- [ ] Opt-out toggle in Settings

### Risk
- **Medium.** Requires Firebase project setup + `google-services.json`/`GoogleService-Info.plist` files (contains API keys — must NOT be committed to git). Privacy policy must be updated before release.

---

## Item 26: Performance Baseline `[Priority #5]`

### Design Intent

Establish baseline performance metrics so future changes can be measured against a known reference.

### Implementation Plan

**Step 1 — Cold start measurement**

Instrument `main.dart`:
```dart
final stopwatch = Stopwatch()..start();
await storageService.init();
await NotificationService.init();
await AdService.initialize();
await IapService.initialize();
stopwatch.stop();
debugPrint('Cold start: ${stopwatch.elapsedMilliseconds}ms');
```

Current known: ~2s (measured on Android emulator).  
Target for production: < 3s on real device.

**Step 2 — Bundle size measurement**

```bash
ls -lh build/app/outputs/bundle/release/app-release.aab
```

Current: 57 MB (down from 70 MB after Phase 5 asset cleanup).

**Step 3 — APK/IPA size comparison**

After install on device, measure app storage. Track over time.

**Step 4 — Document baseline**

Record in `PROJECT_STATUS.md` Performance section:
```
| Metric | Value | Date |
|--------|-------|------|
| Cold start (Android emulator) | ~2s | June 2026 |
| Cold start (iPhone 17 Pro sim) | TBD | — |
| AAB size | 57 MB | June 13, 2026 |
| IPA size | 30 MB | June 13, 2026 |
| Test coverage | 70% target | — |
```

### Acceptance Criteria
- [ ] Cold start time measured on all 3 platforms
- [ ] Bundle sizes documented
- [ ] Performance section added to PROJECT_STATUS.md

---

## Item 27: Category Consistency — Unify Habit & Tag Categories `[Priority #6]`

### Design Intent

Currently, habit categories (`RoutineCategory` enum: Health, Fitness, Nutrition, Sleep, Mindfulness, Reflection, Restraint, Connection, Other) and tag categories (user-created freeform) are separate systems with different naming, icons, and localization patterns. For consistency, tag categories should use the same 9 categories as defaults, with proper AppLocalizations instead of hardcoded `isZh` ternaries.

### Current State

| Aspect | Habit Categories | Tag Categories |
|--------|-----------------|----------------|
| Source | `RoutineCategory` enum (9 values) | User-created via TagCategory model |
| Icons | `kCategoryEmoji` map (emoji per category) | User-picked in dialog |
| Colors | Fixed per category | User-picked in dialog |
| Localization | `routineCategoryName(cat, isZh)` function | `TagCategory.displayName(isZh)` method |
| Labels | Short single-character ZH (养/劲/食/息/心/省/戒/缘/杂) | User-entered freeform |

### Changes

**Step 1 — Pre-seed default tag categories**

On fresh install, create 9 default `TagCategory` entries matching habit categories:

```dart
// lib/providers/tag_category_provider.dart
static const defaultCategories = [
  (id: 'cat_health', name: '养', nameEn: 'Health', color: '#34C759', icon: '💊'),
  (id: 'cat_fitness', name: '劲', nameEn: 'Fitness', color: '#FF9500', icon: '🏃'),
  (id: 'cat_nutrition', name: '食', nameEn: 'Nutrition', color: '#FF3B30', icon: '🥗'),
  (id: 'cat_sleep', name: '息', nameEn: 'Sleep', color: '#5856D6', icon: '😴'),
  (id: 'cat_mindfulness', name: '心', nameEn: 'Mindfulness', color: '#AF52DE', icon: '🧘'),
  (id: 'cat_reflection', name: '省', nameEn: 'Reflection', color: '#007AFF', icon: '💭'),
  (id: 'cat_restraint', name: '戒', nameEn: 'Restraint', color: '#FF2D55', icon: '🛡️'),
  (id: 'cat_connection', name: '缘', nameEn: 'Connection', color: '#FF9500', icon: '👥'),
  (id: 'cat_other', name: '杂', nameEn: 'Other', color: '#9E9E9E', icon: '⭐'),
];
```

**Step 2 — Add AppLocalizations for category add/edit dialog**

Replace all hardcoded `isZh ? '添加分类' : 'Add Category'` in `settings_screen.dart` with proper ARB keys:

| Key | EN | ZH |
|-----|----|----|
| `categoryName` | Category name | 分类名称 |
| `categoryEnglishName` | English name | 英文名称 |
| `categoryIcon` | Icon (emoji) | 图标 |
| `addCategory` | Add Category | 添加分类 |
| `editCategory` | Edit Category | 编辑分类 |
| `deleteCategory` | Delete Category | 删除分类 |
| `deleteCategoryConfirm` | Delete "{name}"? Tags in this category will become uncategorized. | 确定删除"{name}"？所属标签将变为未分类。 |

Add keys to `app_en.arb`, `app_zh.arb`, regenerate `app_localizations.dart`.

**Step 3 — Update dialog code**

Replace all `isZh ?` ternaries in `_showAddCategoryDialog`, `_showEditCategoryDialog`, `_showDeleteCategoryDialog` with `AppLocalizations.of(context)!.xxx`.

**Step 4 — Seed default categories on first launch**

In `lib/core/services/storage_service.dart` `init()`: if no tag categories exist, create the 9 defaults.

**Step 5 — Migration for existing users**

Users who already have custom-created categories keep them as-is. Only new installs get the 9 defaults. No migration needed (existing data preserved).

### Acceptance Criteria
- [ ] 9 default tag categories created on fresh install
- [ ] Category add/edit/delete dialogs use AppLocalizations (zero `isZh` ternaries)
- [ ] `hardcoded_string_audit_test` for `settings_screen.dart` moved to `phase4Files` then to `fullyLocalizedFiles` after cleanup
- [ ] Existing user categories unaffected
- [ ] 320 tests pass

### Risk
- **Low.** Changes are additive (new defaults, new l10n keys). No migration needed. Existing data preserved.

---

## Phase 6 Task Breakdown

| Day | Item | Task | Effort |
|-----|------|------|--------|
| 1 | 22 | DB schema cleanup (migration + test) | 2h |
| 1 | 26 | Performance baseline measurement | 1h |
| 2 | 23a | Extract _HabitsTab + helpers | 1.5h |
| 3 | 23b | Extract _NotesTab + _MoodsTab | 1.5h |
| 3 | 23c | Extract _HeroStatsRow + clean up | 1h |
| 4 | 24 | Dead asset & import cleanup | 1h |
| 4 | 27 | Category consistency (unify habit + tag categories, l10n) | 2h |
| 5 | 25 | Firebase Crashlytics integration (Spark plan) | 3h |
| 6 | — | Regression QA | 2h |

---

## Dependencies

| Item | Blocked By | Status |
|------|-----------|--------|
| 22 (DB cleanup) | Phase 5 UAT sign-off | Ready |
| 23 (File split) | None | Ready |
| 24 (Asset cleanup) | None | Ready |
| 25 (Crashlytics) | Firebase project creation by business owner | Needs `google-services.json` + `GoogleService-Info.plist` |
| 26 (Perf baseline) | None | Ready |
| 27 (Category consistency) | None | Ready |

---

## Business Owner Action Items

1. **Firebase project** — Create a Firebase project for Stalio, download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS), provide to dev team
2. **Privacy policy update** — Add Crashlytics disclosure paragraph
3. **Store metadata update** — Add "What's New" for Phase 5/6 changes:
   - "Ad-free experience available with one-time purchase"
   - "Faster, smaller app — reduced by 20+ MB"
