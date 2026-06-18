# Session Summary — June 16–17, 2026

## What Was Built

### Phase 7a: Foundation
- **Routine model v2** — added `TrackingUiType` enum + 14 new fields from CSV (trackingTarget, trackingMin/Max, difficulty, timeOfDay, isDefaultBundle, twoMinVersionEn/Cn, etc.)
- **DB migration v18→v19** — 14 new columns in routines table, version-gated `_onCreate`, read/write mappers updated
- **54-habit seed data** — replaced old 31 routines with CSV library, 9 default-bundle active, 11 tracking types
- **12-category schema** — added growth, financial, environment to `RoutineCategory`; unified with `TagCategory`; "other" default for uncategorized

### Phase 7b: Onboarding Flow
- **3-screen flow** — Welcome (branding), How It Works (3 interaction types), Select Habits (9 pre-selected + toggles)
- **Full Habit Library** — 54 habits, 5 category filter chips, search bar, toggle selection
- **Startup gate** — `_OnboardingGate` checks `onboardingComplete` pref, shows flow or `MainScreen`
- **5 widget tests** for onboarding screens

### Phase 7c: Popup UI Factory
- **11 tracking type popups**: boolean (instant), boolean_optional_text (check + optional note), duration ± note, number (stepper + keyboard), time (clock picker), scale/scale_optional_text (1–5 emoji), text_required (must write), multi_text_required (3 fields), streak (YES/NO)
- Replaced `RoutineNoteDialog` with `showHabitPopup` factory dispatch
- Habit completion + entry creation split into `_completeRoutine` / `_createEntry` / `_completeWithEntry`

### Phase 7d: Tag System + Cleanup
- Habit name stored in entry `metadata.routineName`, displayed on entry cards and detail screen
- Custom tag input on text popups (appended as `#tag` to content)
- Category filter on Notes tab fixed (dual-match: direct category IDs + tag category associations)
- Backup/restore wired to Settings (was "coming soon"); `ExportData` now includes settings; `clearAll()` before restore
- `EmojiJarWidget` deleted; `JarProvider` retained for `_HeroStatsRow` mood display

### P1 Extras
- First-time tooltips — contextual banners per tracking type, show once, "Got it" dismiss
- Help panel — bottom sheet with habit detail (type, target, range, 2-min version, usage tips)
- Entry card header: tag icon + count replaced with habit name from metadata

### UAT Bug Fixes
| Bug | Fix |
|-----|-----|
| Tag icon instead of text on notes | Read `metadata.routineName` directly, bypass provider lookups |
| "Moment" title in Notes | Changed to "Notes"; AppBar hidden when not selecting |
| Boolean-optional habits not checking off | Separated `_completeRoutine` from `_completeWithEntry` to prevent double-toggle |
| Drink water not counter | Changed H001 `trackingUiType` from `boolean` to `number` |
| Scale emoji overflow | Wrapped in `SingleChildScrollView`, reduced font size |
| Number input too narrow | Widened from 100→130px |
| Completed icon row overflow | Wrapped in `Expanded` for multi-line support |
| Seed entries showing | Disabled `_getSeedEntries()` |
| Category filter not working | Dual-match: entry tagIds + tag category associations |
| Tallies sub-tabs missing | Removed `totalEntries == 0` early-return guard |
| Backup/restore "coming soon" | Wired to actual export/import methods |
| Settings lost on ZIP export | Added `settings` to `ExportData` |
| Old data not cleared on restore | Added `clearAll()` before import |

---

## iOS Onboarding Freeze (UNRESOLVED)

### Timeline
1. Original widget-swap: screen 3 buttons unresponsive on iOS
2. Route-based push: freezes on any overlay operation (popup, tab switch, push)
3. Nested Navigator: same freezes
4. Removed nested Navigator + `addPostFrameCallback` → microtask: **pending validation**

### Root Cause Analysis
The iOS Impeller rendering engine handles animation controller disposal asynchronously (scheduled for next render pass), while Android Skia disposes synchronously. When a `Navigator` operation (push/pop/showDialog) triggers a route transition, and the Impeller overlay layer encounters a pending-disposal animation controller, it enters a wait state → deadlock.

The `addPostFrameCallback` pattern is particularly dangerous because it queues Navigator operations at the exact point where Impeller's async disposal is mid-flight.

### Current State
- Plain widget-swap (no route push, no nested Navigator)
- `Future.microtask` instead of `addPostFrameCallback` for deferred operations
- `context.read` (not `watch`) for `RoutineProvider` in onboarding — no subscription
- Tallies sub-tabs fixed
- Android: everything works

---

## Files Changed

| File | Change |
|------|--------|
| `lib/models/routine.dart` | `TrackingUiType` enum, 14 new fields, `copyWith`/`toJson`/`fromJson` |
| `lib/core/services/database_service.dart` | v18→v19 migration, version-gated `_onCreate`, `kSchemaVersion = 19` |
| `lib/core/services/storage_service.dart` | 54-habit seed data, 12 categories, tooltip prefs, `clearAll` + `_ensureDefaultCategories`, backup/restore |
| `lib/core/services/export_service.dart` | `ExportData.settings`, settings in ZIP export |
| `lib/repositories/tag_repository.dart` | Optional `id` parameter on `create` |
| `lib/providers/tag_provider.dart` | Optional `id` parameter on `addTag`, `activateRoutine`/`deactivateRoutine` |
| `lib/providers/routine_provider.dart` | `activateRoutine`, `deactivateRoutine` |
| `lib/screens/onboarding/onboarding_flow.dart` | **New** — 750 lines, 3 screens + library + tooltips |
| `lib/widgets/habit_popups/habit_popup_factory.dart` | **New** — 755 lines, 11 popup types |
| `lib/app.dart` | `_OnboardingGate` toggle, onboarding import |
| `lib/screens/home/home_screen.dart` | Tooltips, help panel, `Expanded` icon row, StorageService access |
| `lib/screens/moment/moment_screen.dart` | Tag text, category filter fix, Notes title, empty entry filter |
| `lib/screens/moment/entry_detail_screen.dart` | Habit name tag |
| `lib/widgets/entry_card.dart` | Habit name instead of tag icon+count |
| `lib/screens/cherished/cherished_memory_screen.dart` | Removed empty-state guard, `_MoodsTab` + `_EmojiJarSection` deleted |
| `lib/screens/settings/settings_screen.dart` | Backup/restore wired up |
| `lib/widgets/emoji_jar.dart` | **Deleted** |

## Test Changes

| File | Change |
|------|--------|
| `test/screens/home_screen_test.dart` | 2 skipped tests rewritten, `_FakeStorage` updated |
| `test/screens/onboarding_flow_test.dart` | **New** — 5 widget tests |
| `test/core/db_version_test.dart` | 18→19 |
| `test/core/storage_service_restore_test.dart` | `clearAll` + `_ensureDefaultCategories` overrides |
| `test/screens/restore_integration_test.dart` | `clearAll` override |
| `test/integration/phase2_backup_roundtrip_test.dart` | `isNotEmpty`→`isEmpty` for seed entries |
