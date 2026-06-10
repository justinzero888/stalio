# Stalio — Phased Implementation Plan

**Project:** Stalio (forked from Blinking Notes v1.2.0)
**Version:** 1.0.0+1 (dev, unreleased)
**Last Updated:** May 31, 2026 (v2 — reordered per PM decision)
**Source:** SESSION_SUMMARY.md — "What's Next for New Dev Team"

**Phase Order Rationale:** Monetization (AdMob + IAP) depends on external platform setup (AdMob account, Google Merchant, Apple Paid Apps agreement) which has 1–7 day lead times for human approval. Pushing it to Phase 5 gives the PM 5+ weeks for external setup, eliminating the blocker risk. All phases ship as one product — revenue timing is unaffected.

---

## Phase Gate Rules

- Each phase **must** have all tests passing (`flutter test` exits 0, no skipped/ignored tests)
- Each phase **must** pass regression — no existing functionality broken
- Each phase **must** include dedicated unit + integration test cases covering the phase's items (see Test Cases section per phase)
- Each phase **requires explicit PM sign-off** before the next phase begins
- Phases are sequential — no phase can start without prior phase sign-off

---

## Phase 1: Foundation & Branding (Week 1–2)

**Dependencies:** None | **Est. Effort:** 7–10 days

---

### Item 1: Test Suite Rebuild `[Priority #1]`

The codebase has 24 test files (4,592 lines) but many reference deleted features (AI, IAP, onboarding, Chorus, voice transcribe, photo picker). Tests that still apply (tag CRUD, entry filtering, locale, restore backend) need audit; everything else needs replacement or removal.

**Acceptance Criteria:**

- [ ] All 24 existing test files are audited and classified (keep/rewrite/delete) — audit output documented
- [ ] Deleted-feature tests (AI, IAP, onboarding, Chorus, voice transcribe, photo picker) are removed
- [ ] New tests written for:
  - [ ] `MainScreen` nav index mapping (5 nav items → 4 screen indices, center + null mapping, `_navToScreen` correctness)
  - [ ] `routine_screen.dart` scrollable single-view layout rendering with streak matrix
  - [ ] Emoji jar label count correctness (emoji count, not note count)
  - [ ] Seed data `SharedPreferences` guard — no duplicate creation on subsequent launches
  - [ ] `_TagMoodSection` empty-state `orElse` fallback (prevents crash on empty tags)
  - [ ] Settings 3-tab layout rendering (General, Tags, Habit Build)
- [ ] Widget tests for all 5 bottom nav tab screens render without errors
- [ ] Integration test: create note → view in My Day → view in Notes tab → edit → verify persistence
- [ ] All 3 restore-backend test files (1,372 lines) verified to pass with current code
- [ ] `flutter test` exits 0 with **>90% pass rate** (excluding stress/perf tests)
- [ ] Regression: all existing screens navigate correctly, seed data works, notifications schedule, emoji jar renders
- [ ] CI pipeline configured to run `flutter test` on every PR

---

### Item 2: Color Schema Update `[Priority #4]`

Replace the current green/teal palette (`#2A9D8F` seed color, emerald accents, `#F4F8F7` scaffold) inherited from Blinking with navy (`#1A2533`) + gold (`#FFD700`).

**Files to change:**

| File | Change |
|---|---|
| `lib/core/config/theme.dart:17` | Seed color → `Color(0xFF1A2533)` |
| `lib/core/config/theme.dart:19` | `scaffoldBackgroundColor` → warm light (no green tint) |
| `lib/core/config/theme.dart:70-78` | Dark theme full pass (not just colors, full parity) |
| `lib/app.dart:92` | `title` → `'Stalio'` |
| `lib/app.dart:94` | Wire `themeMode` to `ThemeProvider.themeMode` (remove hardcoded `ThemeMode.light`) |
| `lib/screens/routine/routine_screen.dart` | Streak completion cells → navy/gold |
| `lib/screens/home/home_screen.dart` | Card accents, section colors |
| `lib/screens/cherished/cherished_memory_screen.dart` | Emoji jar glass tint, card colors |
| `lib/screens/settings/settings_screen.dart` | Tag color picker palette, section headers |
| `android/app/src/main/res/values/colors.xml` | Adaptive icon background → navy |
| `android/app/src/main/res/mipmap-*/ic_launcher.xml` | Regenerate with navy+gold palette |
| `ios/Runner/LaunchScreen.storyboard` | Background color → navy |
| `assets/icons/app_icon.png` | Regenerate with navy+gold palette |

**Acceptance Criteria:**

- [ ] Theme seed color in `theme.dart` changed from `#2A9D8F` to `#1A2533` (navy)
- [ ] Gold accent (`#FFD700`) visibly present in: streak completion cells, habit check indicators, progress bars, chart fills, selected nav item, FAB icon
- [ ] Light theme scaffold background updated (not green-tinted `#F4F8F7`)
- [ ] Dark theme has full color parity with light theme (cards, nav bar, text hierarchy, surfaces, dividers, inputs)
- [ ] `app.dart:92` title reads `'Stalio'` (not `'Blinking'`)
- [ ] `app.dart:94` `themeMode` is wired to `ThemeProvider.themeMode` (not hardcoded `ThemeMode.light`)
- [ ] Android adaptive icon background changed to navy
- [ ] iOS `LaunchScreen.storyboard` background color changed to navy
- [ ] App icon regenerated with navy+gold palette
- [ ] Visual QA: every screen in light mode — no green/emerald remnants
- [ ] Visual QA: every screen in dark mode — readable, gold accents visible, no washed-out elements
- [ ] `rg '#0D3B34|#2A9D8F|emerald|0xFFF4F8F7' lib/` → zero matches

---

### Item 3: Legal Content Update `[Priority #5]`

`lib/core/constants/legal_content.dart` (417 lines) still says "Blinking" ~40 times. Must be rewritten before any public release. This phase covers Stalio rebranding + removal of deleted-feature clauses. AdMob/privacy disclosures will be added in Phase 5 (Monetization).

**Acceptance Criteria:**

- [ ] Zero occurrences of "Blinking" or "记忆闪烁" in `legal_content.dart` (verify with `rg`)
- [ ] "Stalio" used consistently in all headers, clauses, and descriptions (English + Chinese)
- [ ] All AI/LLM data processing clauses removed
- [ ] All IAP/subscription terms removed (AI Pro features)
- [ ] All Chorus/social sharing clauses removed
- [ ] Data collection scope updated: explicitly states no AI processing, no accounts, all data on-device only
- [ ] Contact email updated to Stalio address (not Blinking's)
- [ ] Chinese translation matches English content equivalently — verified by native speaker
- [ ] Legal review completed and approved
- [ ] **Note:** AdMob data collection disclosures, ATT description, and GDPR consent clauses will be added in Phase 5 (Monetization)

---

### Phase 1 Exit Gate

**Test Cases:**

| # | Type | File | Tests | Description |
|---|---|---|---|---|
| 1 | Unit | `test/core/db_index_test.dart` | 3 | Fresh DB indexes (entry_tags, entries, completions) |
| 2 | Unit | `test/core/db_version_test.dart` | 1 | Schema version check |
| 3 | Unit | `test/core/export_service_progress_test.dart` | 3 | Export progress, monotonic values, date-range media filtering |
| 4 | Unit | `test/core/storage_service_list_item_test.dart` | 11 | List item CRUD, carry-forward logic |
| 5 | Unit | `test/core/storage_service_restore_test.dart` | 9 | Restore progress, streaming, byte-weighted, zero-size, fused decode |
| 6 | Unit | `test/core/version_test.dart` | 3 | App version consistency, appName = Stalio |
| 7 | Unit | `test/core/voice_notification_service_test.dart` | 4 | Voice TTS init, speak, stop, language |
| 8 | Unit | `test/models/emotion_encoding_test.dart` | 10 | Emotion emoji to numeric score mapping |
| 9 | Unit | `test/models/entry_export_test.dart` | 4 | Entry serialization round-trip, backward compat |
| 10 | Unit | `test/models/list_item_test.dart` | 14 | ListItem CRUD, validation, equality |
| 11 | Unit | `test/models/routine_locale_test.dart` | 11 | Routine locale, voice, category, schedule |
| 12 | Unit | `test/providers/entry_filtering_test.dart` | 12 | Entry search, tag filter, type filter, performance |
| 13 | Unit | `test/providers/locale_provider_test.dart` | 6 | Locale load, set, toggle, supported locales |
| 14 | Unit | `test/providers/routine_scheduling_test.dart` | 24 | Routine frequency, schedule, category detection |
| 15 | Unit | `test/providers/routine_voice_test.dart` | 4 | VoiceEnabled DB persistence |
| 16 | Unit | `test/providers/tag_provider_test.dart` | 11 | Tag CRUD, getById, resetToDefaults |
| 17 | Widget | `test/screens/entry_detail_screen_test.dart` | 3 | Entry content, emotion emoji, edit/share buttons |
| 18 | Widget | `test/screens/home_screen_test.dart` | 6 | Routine checklist rendering, completion toggle |
| 19 | Widget | `test/screens/restore_flow_widget_test.dart` | 6 | Restore dialog, progress, snackbar |
| 20 | Widget | `test/screens/restore_integration_test.dart` | 5 | Restore progress monotonic, percentage, no-crash |
| 21 | Smoke | `test/widgets/home_screen_rendering_test.dart` | 6 | Generic UI structure rendering |
| 22 | Smoke | `test/widgets/main_screens_rendering_test.dart` | 9 | Bottom nav, TextField, TabBar, FAB, ListTile, Card |
| 23 | Smoke | `test/widget_test.dart` | 1 | Test framework sanity |
| 24 | Diag | `test/notification_diagnostic.dart` | — | Notification pipeline diagnostic (dart run) |
| **Total** | | **24 files** | **166 tests** | |

| Criterion | Requirement | Status |
|---|---|---|
| `flutter test` | All tests pass, exit code 0 | [ ] |
| Visual QA | All screens, light + dark mode, no green remnants | [ ] |
| `rg "Blinking\|记忆闪烁" lib/` | Zero matches | [ ] |
| `rg '#0D3B34\|#2A9D8F\|emerald\|0xFFF4F8F7' lib/` | Zero hardcoded color matches | [ ] |
| Regression | All existing functionality intact | [ ] |
| **PM sign-off** | **Approved — Date: _________** | **[ ]** |

---

## Phase 2: Core Features (Week 2–3)

**Dependencies:** Phase 1 sign-off | **Est. Effort:** 5–7 days

---

### Item 4: Backup/Restore UI Wiring `[Priority #2]`

**Current state:** The entire backup/restore **backend** is already implemented and tested (`export_service.dart` with ZIP/JSON/CSV export, `storage_service.dart` with `restoreFromBackup()` handling `.json` and `.zip`). Only the **UI is a placeholder** — settings screen shows "Backup coming soon..." snackbars.

**File:** `lib/screens/settings/settings_screen.dart:118-138`

**Acceptance Criteria:**

- [ ] "Full Backup (ZIP)" button in settings calls `ExportService.exportAll()` → system share sheet via `share_plus`
- [ ] Progress indicator shown during backup (uses existing progress callback in `exportAll`)
- [ ] "Restore Data" button opens file picker (`.zip` and `.json`), calls `StorageService.restoreFromBackup()` with progress bar
- [ ] Confirmation dialog before restore: warns "This will replace all current data. Continue?" with explicit Cancel/Confirm buttons
- [ ] Success feedback shows counts: "Restored X entries, Y tags, Z routines"
- [ ] Error handling:
  - [ ] Corrupted ZIP → clear error message, no crash
  - [ ] Empty backup file → "No data found in backup" message
  - [ ] Version mismatch → warning with option to proceed or cancel
  - [ ] Missing media files → restore entries without media, show warning
- [ ] Backup ZIP contents verified: `data.json` + `manifest.json` + all media files
- [ ] Restore round-trip test: backup → clear data → restore → all entries/tags/routines match original (count + content)
- [ ] All 3 existing restore test files pass with zero changes
- [ ] New widget test: settings screen backup/restore button rendering + tap interaction
- [ ] New integration test: backup round-trip (create data → backup → wipe → restore → verify)

---

### Item 5: Performance Optimization `[Priority #3]`

**Current state:** First launch takes ~5s on Android due to seed data insertion + TTS init.

**Acceptance Criteria:**

- [ ] Cold start time on Android mid-range device (Pixel 4a equivalent): **<2.5 seconds** (down from ~5s)
- [ ] Cold start time on iOS (iPhone SE equivalent): **<2 seconds**
- [ ] TTS initialization deferred — `FlutterTts` not instantiated until first voice notification triggers (lazy init)
- [ ] Seed data insertions batched into single SQLite transaction (not individual writes)
- [ ] Splash/loading state shown during initial data seeding — no blank white screen on first launch
- [ ] `SharedPreferences` reads minimized on cold start (audit and reduce unnecessary I/O)
- [ ] Flutter DevTools CPU trace confirms removal of unnecessary work from main isolate
- [ ] Performance test added: measure `Stopwatch` from `main()` entry to first frame paint, assert <3s
- [ ] Warm start (subsequent launches): **<1 second**

---

### Phase 2 Exit Gate

**Test Cases:**

| # | Type | File | Tests | Description |
|---|---|---|---|---|
| 1 | Widget | `test/screens/backup_restore_screen_test.dart` | 6 | Backup/restore buttons present with correct labels and icons, button tappable, section header |
| 2 | Integration | `test/integration/phase2_backup_roundtrip_test.dart` | 4 | Create data → export ZIP → verify, empty storage export, restore ZIP, restore JSON |
| 3 | Integration | `test/integration/phase2_restore_errors_test.dart` | 3 | Corrupted ZIP, empty file, valid empty JSON — no crash |
| 4 | Manual | Device measurement | 1 | Cold start <3s Android / <2s iOS (measured via `flutter run --profile` + DevTools) |
| **Total** | | **3 files + manual** | **14 tests + 1 manual** | |

| Criterion | Requirement | Status |
|---|---|---|
| `flutter test` | 219 + 14 = 233 tests pass, exit code 0 | [ ] |
| Backup round-trip | Backup → clear → restore → data matches exactly | [ ] |
| Restore error paths | Corrupted ZIP, empty file, version mismatch all handled without crash | [ ] |
| Android cold start | <3s measured via `flutter run --profile` + DevTools trace | [ ] |
| iOS cold start | <2s measured via Instruments | [ ] |
| Regression | All Phase 1 screens functional, data intact after backup/restore cycle | [ ] |
| **PM sign-off** | **Approved — Date: _________** | **[ ]** |

---

## Phase 3: UX & Localization (Week 3–4)

**Dependencies:** Phase 2 sign-off | **Est. Effort:** 5–7 days

---

### Item 6: Language/Localization Audit `[Priority #7]`

**Current state:** Mixed patterns — some screens use `isZh ? '中文' : 'English'` inline, others use `l10n.xxx`. ARB files have 144 lines each but still contain `"appName": "Blinking"`.

**Acceptance Criteria:**

- [ ] ARB files: `appName` changed to `"Stalio"` in both `app_en.arb` and `app_zh.arb`
- [ ] Complete audit of all screens for hardcoded strings — documented in a tracking spreadsheet
- [ ] All hardcoded `isZh ? '中文' : 'English'` patterns replaced with `l10n.xxx` keys
- [ ] Decision documented: full `AppLocalizations` delegate pattern (no new `isZh` inline patterns)
- [ ] Missing ARB keys added for:
  - [ ] Streak matrix labels (days, weeks, months)
  - [ ] Summary card labels
  - [ ] Chart tooltips
  - [ ] Seed entry content (currently only in English)
  - [ ] Background notification body text
- [ ] `flutter gen-l10n` regenerates without errors
- [ ] Both languages render correctly at all system text scale levels (0.8x – 1.5x)
- [ ] No text overflow at any text scale on any screen
- [ ] **Note:** AdMob-related strings ("Ads: Active", "Remove Ads", price display, "Restore Purchase") will be added in Phase 5 (Monetization) when the ad/IAP feature lands

---

### Item 7: Dark Mode Polish `[Priority #10]`

**Current state:** Dark theme exists but is minimal (8 lines of overrides vs ~40 for light). `themeMode` was hardcoded to `ThemeMode.light` — fixed in Phase 1.

**Acceptance Criteria:**

- [ ] Dark theme has full color definitions in `theme.dart`:
  - [ ] Card colors (surface, elevated)
  - [ ] Nav bar colors (background, selected/unselected item)
  - [ ] Text hierarchy (body, subtitle, caption, headline) with proper contrast
  - [ ] Surface variants (dialog, bottom sheet, snackbar)
  - [ ] Dividers and separators
  - [ ] Input field colors (background, border, cursor, text)
  - [ ] Tag chip colors adapt to dark background
- [ ] Theme toggle in settings UI → switches `ThemeProvider.themeMode` → `MaterialApp` rebuilds
- [ ] Gold accents (`#FFD700`) maintain sufficient contrast ratio (≥4.5:1) on dark backgrounds
- [ ] Dark mode QA pass: every screen at text scales 0.8x, 1.0x, 1.5x
- [ ] Dark mode persistence: app restart retains dark choice via SharedPreferences
- [ ] OLED test: no grey bleed on true black screens (use `Color(0xFF121212)` for surfaces)
- [ ] System theme follow option: "Use System Setting" as third theme choice
- [ ] **Note:** Ad banner dark mode theming will be handled in Phase 5 (Monetization)

---

### Item 8: iOS Name Cache Fix `[Priority #13]`

**Acceptance Criteria:**

- [ ] Fresh iOS simulator install shows app name as "Stalio" on home screen (not cached "Blinking" or "Micro Habits")
- [ ] Build clean script documented:
  ```bash
  flutter clean
  rm -rf ios/Pods ios/Podfile.lock
  flutter pub get
  cd ios && pod install && cd ..
  flutter run
  ```
- [ ] Team documentation updated with iOS cache-clearing steps
- [ ] Verified on physical device (if available)
- [ ] `Info.plist` `CFBundleDisplayName` confirmed as `"Stalio"`

---

### Phase 3 Exit Gate

**Test Cases:**

| # | Type | File | Tests | Description |
|---|---|---|---|---|
| 1 | Unit | `test/l10n/arb_completeness_test.dart` | 2 | All ARB keys present in both en/zh, no missing keys |
| 2 | Unit | `test/l10n/hardcoded_string_audit_test.dart` | 1 | Zero `isZh ?` patterns remaining in lib/ |
| 3 | Widget | `test/screens/dark_mode_theme_test.dart` | 5 | Dark mode toggle, color contrast ratios, persistence, system follow, text scale |
| 4 | Widget | `test/l10n/localized_screen_test.dart` | 6 | All 5 nav screens + settings render correctly in both en and zh locales |
| **Total** | | **4 files** | **14 tests** | |

| Criterion | Requirement | Status |
|---|---|---|
| `flutter test` | All tests pass, exit code 0 | [ ] |
| L10n audit doc | Complete, all gaps documented and resolved | [ ] |
| Dark mode QA | 20/20 screens pass at 0.8x/1.0x/1.5x text scale | [ ] |
| `rg 'isZh\s*\?' lib/` | Zero matches (all migrated to l10n) | [ ] |
| iOS home screen label | Reads "Stalio" on fresh install | [ ] |
| Regression | All screens functional in both languages and both themes | [ ] |
| **PM sign-off** | **Approved — Date: _________** | **[ ]** |

---

## Phase 4: Feature Expansion (Week 4–6)

**Dependencies:** Phase 3 sign-off | **Est. Effort:** 10–14 days

---

### Item 9: Tag Management Redesign `[Priority #6]`

**Current state:** Tags are flat (name + color + locale names). No categories, no analytics, no bulk operations.

**Design scope:**

| Feature | Description |
|---|---|
| Categories | Tags grouped under named categories with own colors/icons |
| Hierarchy | Categories → Tags (one level). Each tag belongs to exactly one category. |
| Analytics | Usage frequency per category, co-occurrence heatmap, timeline |
| Bulk operations | Multi-select → assign category, merge tags, batch recolor |
| Auto-suggest | Suggest tags during note creation based on content + patterns |
| UX | Category filter in Notes, category colors throughout app |

**Acceptance Criteria:**

- [ ] `TagCategory` model created (`id`, `name`, `nameEn`, `color`, `icon`, `sortOrder`)
- [ ] `TagCategoryRepository` with full CRUD + `getUsageCount(categoryId)`
- [ ] DB migration:
  - [ ] `tag_categories` table created (id, name, name_en, color, icon, sort_order, created_at)
  - [ ] `tags` table gains `category_id` FK column (nullable)
  - [ ] Existing tags set to `category_id = null` (uncategorized) — no data loss
  - [ ] Migration script tested forward and rollback
- [ ] Settings Tags tab redesigned:
  - [ ] Categories as expandable/collapsible sections with tag count badge
  - [ ] Tags nested within their category section
  - [ ] Add Category button → name (en + zh), color picker, icon picker form
  - [ ] Edit/delete category → confirmation if category has tags (move tags to uncategorized)
  - [ ] Drag-to-reorder categories
- [ ] Bulk tag operations:
  - [ ] Multi-select mode: tap checkbox on tags
  - [ ] "Assign to Category" action → dropdown of categories
  - [ ] "Merge Tags" action → select target tag, all entries reassigned, source tag deleted
  - [ ] "Recolor Selected" action → color picker applied to all selected tags
- [ ] Tag analytics (Tallies → Tags section or new sub-tab):
  - [ ] Bar chart: tag/category usage frequency (30-day window)
  - [ ] Co-occurrence heatmap: N×N matrix showing which tags appear together in entries
  - [ ] Timeline: first-use date per tag, adoption graph over time
- [ ] Tag auto-suggest during note creation:
  - [ ] As user types note content, match keywords against tag names + historical patterns
  - [ ] Show suggestion chips below text field (max 3 suggestions)
  - [ ] Tap chip to add tag to current entry
- [ ] Category filter chips in Notes tab:
  - [ ] Horizontal scrollable chip row at top of note list
  - [ ] "All" chip (default selected) + one chip per category
  - [ ] Selecting a category filters the note list to entries with tags in that category
- [ ] Category colors used consistently: chip background, tag dot, analytics chart segments
- [ ] Regression: all existing entries retain correct tags after migration
- [ ] Test: migration script adds `category_id` column correctly, existing data preserved
- [ ] Test: bulk merge → all entries reassigned, source tag deleted, target tag untouched
- [ ] Test: auto-suggest returns relevant tags based on content keywords
- [ ] Test: category filter correctly filters note list

---

### Item 10: Export to CSV/PDF `[Priority #12]`

**Current state:** CSV backend fully implemented (`export_service.dart` with `exportCsv()`). PDF is zero code — no `pdf` package, no PDF generation.

**Acceptance Criteria:**

- [ ] `pdf` package added to `pubspec.yaml`
- [ ] `ExportService.exportPdf()` implemented:
  - [ ] Title page with app name, export date, entry count
  - [ ] Entry list pages: date, content, tags (as colored labels), emotions, note length
  - [ ] Habit streak summary table: habit name, current streak, longest streak, completion rate
  - [ ] Mood distribution chart (pie or bar) across all entries in export range
  - [ ] Embedded fonts for CJK character support (MaShanZheng font already in assets)
  - [ ] Page numbers in footer
- [ ] CSV export button in settings calls `ExportService.exportCsv()` → share sheet or save dialog
- [ ] PDF export button in settings calls `ExportService.exportPdf()` → share sheet or save dialog
- [ ] File save dialog: user can pick local save location (Android SAF / iOS file system)
- [ ] Date range picker before export — user chooses "All time", "Last 30 days", "Last 90 days", "Custom range"
- [ ] Progress indicator during large exports (>100 entries, >10 routines)
- [ ] Exported CSV opens correctly in Excel/Numbers (UTF-8 BOM, field quoting, proper line endings)
- [ ] Exported PDF renders correctly on device and desktop with embedded fonts
- [ ] Test: `exportCsv()` output verified against expected CSV structure (header row, data rows, escaping)
- [ ] Test: `exportPdf()` produces valid PDF with correct page count and content verification

---

### Item 11: Notes Share Redesign `[Priority #8]`

**Current state:** Share was removed (was single-note plain text). No share functionality exists.

**Acceptance Criteria:**

- [ ] Multi-select mode in Notes tab:
  - [ ] Tap checkbox on note card (visible on long-press or toggle in app bar)
  - [ ] Selected count shown in app bar ("3 selected")
  - [ ] Select-all toggle in app bar when in selection mode
  - [ ] Long-press on a note card enters selection mode and selects that card
  - [ ] Range selection: select first → long-press last → all notes between selected
  - [ ] Tap selected card to deselect
  - [ ] Exit selection mode via Cancel/X button or back gesture
- [ ] Three format options in share action sheet:
  - [ ] **Plain text:** Date + content, separated by newlines between entries
  - [ ] **Markdown:** Headers with dates, content in paragraphs, tags as inline badges, emotions as emoji, metadata footer
  - [ ] **Rich formatted:** Structured with separators, includes habit streaks, mood summary
- [ ] Format preview screen before sharing:
  - [ ] Shows rendered output of selected format
  - [ ] Scrollable preview of all selected notes
  - [ ] "Share" and "Change Format" buttons in app bar
- [ ] System share sheet triggered for selected notes + chosen format
- [ ] "Copy to clipboard" action as additional option (bypasses share sheet)
- [ ] "Save as file" saves `.txt` / `.md` to device documents directory via `FileService`
- [ ] Test: select 3 notes → markdown format → verify output structure (headers, tags, dates)
- [ ] Test: single note → all 3 format options produce correct output
- [ ] Test: range selection selects correct contiguous notes

---

### Phase 4 Exit Gate

**Test Cases:**

| # | Type | File | Tests | Description |
|---|---|---|---|---|
| 1 | Unit | `test/models/tag_category_test.dart` | 6 | TagCategory model CRUD, serialization, usage count |
| 2 | Unit | `test/providers/tag_category_provider_test.dart` | 8 | Category CRUD, getByCategory, reorder, delete cascade |
| 3 | Unit | `test/models/entry_share_format_test.dart` | 9 | Entry → plain text, markdown, rich format conversion (3 per format) |
| 4 | Unit | `test/core/export_pdf_test.dart` | 4 | PDF generation, page count, CJK font embedding, content verification |
| 5 | Unit | `test/core/export_csv_test.dart` | 3 | CSV header, data rows, escaping, UTF-8 BOM |
| 6 | Integration | `test/integration/phase4_tag_migration_test.dart` | 3 | Migration adds category_id, existing tags preserved, rollback works |
| 7 | Integration | `test/integration/phase4_export_roundtrip_test.dart` | 2 | CSV export → open in spreadsheet, PDF export → valid opens |
| 8 | Widget | `test/screens/notes_share_selection_test.dart` | 6 | Multi-select, select-all, range select, deselect, cancel, count display |
| 9 | Widget | `test/screens/notes_share_preview_test.dart` | 3 | Format preview renders, scrollable, format switch button |
| 10 | Widget | `test/screens/tag_category_ui_test.dart` | 5 | Expandable category sections, add/edit/delete category, category filter chips |
| **Total** | | **10 files** | **49 tests** | |

| Criterion | Requirement | Status |
|---|---|---|
| `flutter test` | All tests pass, exit code 0 | [ ] |
| Tag migration | All existing entries retain correct tags post-migration | [ ] |
| CSV round-trip | Export → open in spreadsheet → data integrity verified | [ ] |
| PDF output | Opens correctly, all pages render, fonts embedded, CJK support | [ ] |
| Share multi-select | Select 3 notes → markdown preview → share sheet → content matches expected | [ ] |
| Regression | All screens functional, no data loss, backup includes new tag categories | [ ] |
| **PM sign-off** | **Approved — Date: _________** | **[ ]** |

---

## Phase 5: Monetization (Week 6–7)

**Dependencies:** Phase 4 sign-off | **Est. Effort:** 7–10 days

**External Dependency:** Before this phase begins, the PM must complete all platform setup from `EXTERNAL_SETUP_GUIDE.md`:
- [ ] AdMob account created + ad units provisioned
- [ ] Google Play Console: Merchant account active + `remove_ads` IAP product created
- [ ] App Store Connect: Paid Apps agreement active + `remove_ads` IAP product created
- [ ] Privacy Policy URL hosted with AdMob disclosure
- [ ] AdMob App IDs + Ad Unit IDs handed off to dev team

If any of the above are not complete by Week 5, Phase 5 start is delayed until they are ready. No code workaround — sandbox IAP testing is impossible without store-configured products.

---

### Architecture Analysis

**Current state:** The codebase has a disconnected IAP subsystem from the Blinking fork:

| File | Lines | Status |
|---|---|---|
| `lib/core/services/purchases_service.dart` | 229 | RevenueCat wrapper — **not initialized, not in provider tree** |
| `lib/core/services/entitlement_service.dart` | 268 | Entitlement/trial management — **not initialized, not in provider tree** |
| `lib/screens/purchase/paywall_screen.dart` | 529 | "Blinking Pro" $19.99 paywall — **would crash at runtime** (missing providers) |
| `lib/screens/onboarding/transition_screen.dart` | ~150 | Trial-expiry transition screen — **would crash at runtime** |
| `lib/core/services/soft_prompt_service.dart` | ~200 | Re-engagement prompts — **would crash at runtime** |

These files reference Blinking-specific pricing, server endpoints (`blinkingchorus.com`), and AI features that no longer exist. They are fully disconnected from the app's provider tree and initialization.

**Decision:** **Remove the old IAP subsystem entirely** and implement a clean monetization approach from scratch.

---

### Proposed Solution: AdMob + One-Time Remove Ads IAP

**Rationale:**
- Simple, proven model for habit/tracker apps
- No server infrastructure needed (unlike RevenueCat)
- No subscription management complexity
- `google_mobile_ads` and `in_app_purchase` are first-party plugins, well-maintained
- One-time purchase avoids recurring billing complexity and legal overhead

**Revenue model:**
- **Free tier:** Banner ads on main browsing screens
- **Paid tier:** One-time purchase `remove_ads` (non-consumable IAP) → all ads removed permanently

---

### Item 12: Remove Old IAP Subsystem

Before adding the new monetization, clean up the disconnected Blinking IAP code.

**Acceptance Criteria:**

- [ ] Delete `lib/core/services/purchases_service.dart` (229 lines, RevenueCat)
- [ ] Delete `lib/core/services/entitlement_service.dart` (268 lines, entitlement/trial)
- [ ] Delete `lib/screens/purchase/paywall_screen.dart` (529 lines, Blinking Pro paywall)
- [ ] Delete `lib/screens/onboarding/transition_screen.dart` (trial expiry transition)
- [ ] Remove `purchases_flutter` dependency from `pubspec.yaml`
- [ ] Remove any imports to deleted files from `soft_prompt_service.dart` (navigates to paywall)
- [ ] Remove RevenueCat-specific keys from `Info.plist` (if any)
- [ ] Remove RevenueCat-specific meta-data from `AndroidManifest.xml` (if any)
- [ ] Verify: `rg "purchases|entitlement|paywall|revenuecat|blinkingchorus" lib/` → zero references
- [ ] Verify: project builds and all tests pass after deletions

---

### Item 13: AdMob Integration

**Dependencies:** `google_mobile_ads` package

**Ad Placement Strategy:**

| Screen | Ad Type | Rationale |
|---|---|---|
| My Day (HomeScreen) | Banner (bottom) | Highest traffic screen, natural placement below content |
| Tallies (InsightsScreen) | Banner (bottom) | Secondary traffic, non-intrusive below charts |
| Notes (MomentScreen) | Banner (bottom) | Browsing view only — no ads during note reading/editing |
| Add Entry | **No ads** | Would disrupt creative flow |
| Entry Detail | **No ads** | Would disrupt reading experience |
| Settings | **No ads** | Settings should be clean; contains "Remove Ads" CTA |
| Emoji Jar (Cherished) | **No ads** | Emotional/personal screen |

**Platform Setup:**

| Platform | Requirements |
|---|---|
| Android | Add `com.google.android.gms.ads.APPLICATION_ID` meta-data to `AndroidManifest.xml` |
| Android | Add `INTERNET` permission to main manifest |
| iOS | Add `GADApplicationIdentifier` to `Info.plist` |
| iOS | Add `SKAdNetworkItems` to `Info.plist` (AdMob requires this for attribution) |
| iOS | Add `NSUserTrackingUsageDescription` to `Info.plist` (for ATT prompt) |

**Acceptance Criteria:**

- [ ] `google_mobile_ads` package added to `pubspec.yaml`
- [ ] `AdService` class created in `lib/core/services/ad_service.dart`:
  - [ ] Initializes Mobile Ads SDK on app start
  - [ ] Manages ad-free purchase state via `SharedPreferences`
  - [ ] Provides `bool get isAdFree` → checks both local pref + IAP receipt
  - [ ] Creates and disposes banner ad instances
  - [ ] Handles ad load failures gracefully (no crash, hide ad slot)
- [ ] `AdBanner` widget created in `lib/widgets/ad_banner.dart`:
  - [ ] Wraps `AdWidget` with fixed 50dp height (standard banner)
  - [ ] Shows loading placeholder while ad loads
  - [ ] Shows nothing when `isAdFree == true`
  - [ ] Shows nothing on ad load failure
  - [ ] Respects safe area / bottom nav bar overlap
  - [ ] Dark mode theme applied (follows Phase 3 dark mode tokens)
- [ ] Banner ads integrated on:
  - [ ] My Day screen — below scrollable content, above bottom nav
  - [ ] Tallies screen — below charts/heatmap, above bottom nav
  - [ ] Notes screen — below note list, above bottom nav
- [ ] No ads shown during: note creation/editing, entry detail view, settings, emoji jar
- [ ] Test ad unit IDs used in debug builds; production IDs in release (provided by PM from external setup)
- [ ] AdMob account created and approved (PM — external setup)
- [ ] Unit test: `AdService.isAdFree` toggle + persistence
- [ ] Widget test: `AdBanner` renders (with mock ad), hides when `isAdFree`

---

### Item 14: Remove Ads IAP

**Dependencies:** `in_app_purchase` package

**Product definition:**
- **Product ID:** `remove_ads`
- **Type:** Non-consumable (one-time, permanent)
- **Platform:** Both App Store Connect and Google Play Console (PM — external setup)
- **Price:** TBD by PM (suggested: $4.99–$9.99 range)

**Acceptance Criteria:**

- [ ] `in_app_purchase` package added to `pubspec.yaml`
- [ ] `IapService` class created in `lib/core/services/iap_service.dart`:
  - [ ] Initializes `InAppPurchase` on app start
  - [ ] Queries product details from store (handles store unavailable gracefully)
  - [ ] `purchaseRemoveAds()` — initiates purchase flow
  - [ ] `restorePurchases()` — restores previous purchase (for device migration)
  - [ ] Listens to `InAppPurchase.instance.purchaseStream` for completed transactions
  - [ ] On successful purchase: sets `isAdFree = true` in SharedPreferences + delivers content
  - [ ] Handles `pending` transactions (deferred payment, parental approval)
  - [ ] Finishes transactions after delivery (Google Play requirement)
- [ ] "Remove Ads" section added to Settings → General tab:
  - [ ] Current state display: "Ads: Active" or "Ads: Removed"
  - [ ] If ads active: shows price + "Remove Ads" purchase button
  - [ ] If already purchased: shows "Ads Removed" with restore button
  - [ ] Purchase in progress: shows loading spinner, button disabled
  - [ ] Purchase error: shows error message with retry option
- [ ] `isAdFree` state is synced between `IapService` and `AdService`:
  - [ ] `IapService` sets `isAdFree` on purchase/restore success
  - [ ] `AdService` reads `isAdFree` on every ad display check
  - [ ] State persisted to `SharedPreferences` as backup verification
- [ ] Restore purchases functionality:
  - [ ] "Restore Purchase" button in settings
  - [ ] Calls `InAppPurchase.restorePurchases()`
  - [ ] Shows success/failure feedback
- [ ] Ad-free state included in backup/restore (verify after backup → clear → restore, ads remain removed)
- [ ] Product created and configured in:
  - [ ] App Store Connect (non-consumable, `remove_ads`)
  - [ ] Google Play Console (non-consumable, `remove_ads`)
- [ ] Sandbox testing completed on both platforms
- [ ] Unit test: `IapService` purchase flow states (idle → purchasing → purchased → idle)
- [ ] Test: mock purchase success → `isAdFree` = true → ads hidden
- [ ] Test: mock restore success → `isAdFree` = true → ads hidden

---

### Item 15: Ad Privacy & Consent (ATT / GDPR)

**Regulatory requirements:**

| Regulation | Requirement |
|---|---|
| iOS ATT (App Tracking Transparency) | Must show ATT prompt before showing personalized ads. If user denies, show non-personalized ads. |
| GDPR (EU/UK) | Must show consent dialog for personalized ads (via Google's UMP SDK or custom). User can opt out of personalized ads. |
| COPPA | Must not show behaviorally-targeted ads to children. Set `tagForChildDirectedTreatment` if applicable. |

**Acceptance Criteria:**

- [ ] `app_tracking_transparency` package added to `pubspec.yaml` (iOS ATT)
- [ ] ATT prompt implementation:
  - [ ] Show ATT prompt on first app launch (before any ad loads)
  - [ ] Request tracking authorization via `ATTrackingManager.requestTrackingAuthorization`
  - [ ] If `authorized`: request personalized ads from AdMob
  - [ ] If `denied`: request non-personalized ads from AdMob
  - [ ] If `notDetermined`: wait, do not load ads until resolved
- [ ] Non-personalized ad fallback:
  - [ ] Pass `npa=1` in ad request when tracking is denied
  - [ ] Set `AdRequest.nonPersonalizedAds = true` when needed
- [ ] GDPR consent for EU users (using Google UMP SDK):
  - [ ] Integrate `google_mobile_ads` consent SDK (UMP)
  - [ ] Show consent form on first launch if user is in EEA/UK
  - [ ] Respect user consent choice in ad requests
- [ ] Privacy Policy updated in `legal_content.dart` (extends Phase 1 rewrite):
  - [ ] AdMob/Google data collection disclosure
  - [ ] List of data collected by AdMob (device ID, IP, ad interactions)
  - [ ] How to opt out of personalized ads (device settings)
  - [ ] ATT/permission description matching `NSUserTrackingUsageDescription`
  - [ ] GDPR rights (access, deletion, objection to processing)
- [ ] `Info.plist` `NSUserTrackingUsageDescription` set to user-friendly string (provided by PM)
- [ ] L10n: AdMob-related ARB keys added (deferred from Phase 3):
  - [ ] "Ads: Active" / "Ads: Removed" labels
  - [ ] "Remove Ads" button text
  - [ ] Price display format string
  - [ ] "Restore Purchase" button text
  - [ ] Purchase success/error messages
  - [ ] ATT prompt description text
  - [ ] GDPR consent dialog text
- [ ] `flutter gen-l10n` regenerated to include new keys

---

### Phase 5 Exit Gate

**Test Cases:**

| # | Type | File | Tests | Description |
|---|---|---|---|---|
| 1 | Unit | `test/core/ad_service_test.dart` | 5 | Ad init, isAdFree toggle, persistence, load failure handling, dispose |
| 2 | Unit | `test/core/iap_service_test.dart` | 6 | Purchase states, restore, pending transaction handling, error recovery, SharedPreferences sync |
| 3 | Unit | `test/providers/ad_free_provider_test.dart` | 3 | isAdFree state sync between IapService and AdService, provider notification |
| 4 | Widget | `test/widgets/ad_banner_test.dart` | 4 | Banner renders, hides when ad-free, loading placeholder, safe area handling |
| 5 | Widget | `test/screens/remove_ads_ui_test.dart` | 6 | Remove Ads section in settings, price display, purchase button, restore button, loading state, error state |
| 6 | Integration | `test/integration/phase5_ad_free_roundtrip_test.dart` | 3 | Mock purchase → ads hidden → restart → ads still hidden → backup/restore preserves state |
| 7 | Integration | `test/integration/phase5_att_consent_test.dart` | 2 | ATT prompt shown before ads, denied → non-personalized ads |
| **Total** | | **7 files** | **29 tests** | |

| Criterion | Requirement | Status |
|---|---|---|
| `flutter test` | All tests pass, exit code 0 | [ ] |
| External setup complete | AdMob IDs + IAP products + privacy URL all ready | [ ] |
| Old IAP removed | Zero references to RevenueCat, Blinking IAP, paywall | [ ] |
| Ad banners render | Visible on My Day, Tallies, Notes screens (debug test ads) | [ ] |
| No ads on excluded screens | Add Entry, Entry Detail, Settings, Emoji Jar — ad-free | [ ] |
| Remove Ads purchase | Sandbox purchase succeeds → ads hidden → persists across restarts | [ ] |
| Restore purchase | Sandbox restore succeeds → ads hidden | [ ] |
| iOS ATT prompt | Shows on first launch, ads respect user choice | [ ] |
| Privacy Policy | Updated with AdMob data disclosures | [ ] |
| Ad-free state persists | SharedPreferences, IAP receipt, backup/restore all preserve state | [ ] |
| Regression | All existing functionality intact, backup includes ad-free state | [ ] |
| **PM sign-off** | **Approved — Date: _________** | **[ ]** |

---

## Phase 6: Polish & Delight (Week 7–8)

**Dependencies:** Phase 5 sign-off | **Est. Effort:** 5–7 days

---

### Item 16: Habit Image Customization `[Priority #9]`

**Current state:** `Routine.iconImagePath` field exists and is rendered in settings, but there is no image picker or capture flow for habits.

**Acceptance Criteria:**

- [ ] Image picker accessible from habit create/edit form in settings:
  - [ ] Tap current icon opens bottom sheet: "Choose from Gallery", "Take Photo", "Use Emoji" (current default)
  - [ ] Gallery picker via `image_picker` → `ImageSource.gallery`
  - [ ] Camera capture via `image_picker` → `ImageSource.camera`
- [ ] Selected/captured image cropped to square (min 256×256, max 1024×1024) via `image_cropper`
- [ ] Image compressed and saved via `FileService` (existing JPEG compression logic)
- [ ] File saved to app documents with naming convention: `routine_{id}_icon.png`
- [ ] Custom image rendered in:
  - [ ] Habit checklist row (My Day) — replaces emoji with image thumbnail
  - [ ] Habit settings detail/edit form — larger preview with change/remove options
  - [ ] Streak matrix — cell background tint or border color from image palette
- [ ] Remove image option: "Remove Photo" → reverts to emoji icon
- [ ] Fallback to emoji icon when no custom image set (current behavior preserved)
- [ ] Image file deleted from disk when routine is deleted
- [ ] Image persists across app restarts (verify file on disk)
- [ ] Image included in backup ZIP (already handled by existing media export in `exportAll`)
- [ ] Test: create habit with custom image → verify file on disk → verify renders → delete habit → verify file removed
- [ ] Test: image persists through backup → restore cycle

---

### Item 17: Streak Celebration Animations `[Priority #11]`

**Acceptance Criteria:**

- [ ] Milestones defined: 7, 14, 30, 60, 90, 180, 365 consecutive days
- [ ] Confetti/stars animation plays on habit completion when milestone is hit:
  - [ ] Uses `confetti` package (lightweight, no native dependencies) or `Rive`/`Lottie`
  - [ ] Animation duration: 2–3 seconds
  - [ ] Animation plays over current screen content (modal overlay, not blocking)
- [ ] Gold glow pulse on habit card/row after celebration completes (subtle, 1-second fade)
- [ ] Congratulatory message shown at bottom of screen: e.g., "30-day streak! Keep it up!"
  - [ ] Localized in both English and Chinese
  - [ ] Auto-dismisses after 3 seconds or tap to dismiss
- [ ] Haptic feedback on milestone trigger: `HapticFeedback.heavyImpact`
- [ ] Milestone badge/icon shown on habit row in Tallies (permanent, not animation-only):
  - [ ] Small gold star/medal icon with day count
  - [ ] Next to habit name in streak matrix
- [ ] Animations do not block UI:
  - [ ] Milestone detection runs after habit toggle completes (non-blocking)
  - [ ] User can continue interacting with the app during animation
- [ ] Performance: animations run at 60fps on mid-range device (no frame drops)
- [ ] Test: complete habit for 7th consecutive day → verify animation triggers, badge appears
- [ ] Test: complete habit for 8th consecutive day → no animation (not a milestone)
- [ ] Test: complete habit for 14th day → different milestone animation/badge
- [ ] Test: milestone detection works correctly across time zone changes / date boundaries

---

### Phase 6 Exit Gate

**Test Cases:**

| # | Type | File | Tests | Description |
|---|---|---|---|---|
| 1 | Unit | `test/providers/streak_milestone_test.dart` | 8 | Milestone detection (7/14/30/60/90/180/365), streak calculation, timezone handling |
| 2 | Unit | `test/core/routine_image_test.dart` | 5 | Image pick, crop, save, delete on routine delete, file naming |
| 3 | Widget | `test/widgets/streak_celebration_test.dart` | 5 | Confetti animation triggers, gold glow, message display, haptic, badge icon |
| 4 | Widget | `test/screens/habit_image_ui_test.dart` | 4 | Image picker bottom sheet, gallery/camera options, remove photo, fallback to emoji |
| 5 | Integration | `test/integration/phase6_habit_image_persistence_test.dart` | 3 | Image persists across restart, image in backup ZIP, image survives restore |
| **Total** | | **5 files** | **25 tests** | |

| Criterion | Requirement | Status |
|---|---|---|
| `flutter test` | All tests pass, exit code 0 | [ ] |
| Habit image | Create → render → persist → backup → restore → delete verified | [ ] |
| Streak milestones | 7/14/30/60/90/180/365 day milestones all trigger correct animation + badge | [ ] |
| Performance (animations) | 60fps, no dropped frames on mid-range device | [ ] |
| Regression | All prior features still functional, no regressions | [ ] |
| **PM sign-off** | **Approved — Date: _________** | **[ ]** |

---

## Summary

| Phase | Items | Unit/Widget Tests | Integration Tests | Total Tests | Est. Duration | Week | PM Sign-off |
|---|---|---|---|---|---|---|---|
| 1: Foundation & Branding | Test Suite, Color Schema, Legal Content | 166 | — | 166 | 7–10 days | 1–2 | [ ] |
| 2: Core Features | Backup/Restore, Performance | 6 | 7 | 13 + 1 manual | 5–7 days | 2–3 | [ ] |
| 3: UX & Localization | L10n Audit, Dark Mode, iOS Name Cache | 14 | — | 14 | 5–7 days | 3–4 | [ ] |
| 4: Feature Expansion | Tag Redesign, CSV/PDF Export, Notes Share | 44 | 5 | 49 | 10–14 days | 4–6 | [ ] |
| 5: Monetization | Remove Old IAP, AdMob, Remove Ads IAP, Ad Privacy | 24 | 5 | 29 | 7–10 days | 6–7 | [ ] |
| 6: Polish & Delight | Habit Images, Streak Animations | 22 | 3 | 25 | 5–7 days | 7–8 | [ ] |
| **Total** | **17 items across 6 phases** | **276** | **20** | **296 + 1 manual** | **8 weeks** | | **6 PM sign-offs** |

---

## Dependency Graph

```
Phase 1 ──→ Phase 2 ──→ Phase 3 ──→ Phase 4 ──→ Phase 5 ──→ Phase 6
  │            │            │            │            │
  │            │            │            │            ├── External platform setup
  │            │            │            │            │    (blocks Phase 5 start)
  │            │            │            │            │
  │            │            │            │            ├── Adds AdMob L10n strings
  │            │            │            │            │    (deferred from Phase 3)
  │            │            │            │            │
  │            │            │            │            ├── Updates Legal Content
  │            │            │            │            │    with AdMob/privacy disclosures
  │            │            │            │            │
  │            │            │            │            ├── Ad banner dark mode theming
  │            │            │            │            │    (extends Phase 3 dark mode)
  │            │            │            │            │
  │            │            │            │            └── Ad-free state preserved
  │            │            │            │                 in Phase 2 backup/restore
  │            │            │            │
  │            │            │            └── Tag auto-suggest feeds
  │            │            │                 Phase 4 Notes Share
  │            │            │
  │            │            └── L10n strings feed
  │            │                 Phase 4 export/share labels
  │            │
  │            └── Backup infrastructure used by
  │                Phase 4 export, Phase 5 ad-free state
  │
  └── Color Schema feeds:
      Dark Mode (Phase 3), Ad styling (Phase 5),
      Export styling (Phase 4), Animations (Phase 6)
```

---

### Parallelizable Work Within Each Phase

Within each phase, items can be worked in parallel by multiple developers:

- **Phase 1:** Tests + Legal can run parallel; Color depends on test harness (verify color changes don't break tests)
- **Phase 2:** Backup/restore UI + Performance profiling are largely independent
- **Phase 3:** L10n audit + Dark mode are independent; iOS name cache is trivial
- **Phase 4:** Tag redesign + Export (CSV/PDF) are independent; Notes Share depends on tag auto-suggest
- **Phase 5:** Old IAP removal must complete first; then AdMob integration + IAP setup can run partially parallel; ad privacy comes after ad infrastructure is in place
- **Phase 6:** Habit images + Streak animations are fully independent

---

## File Safety Notes

From SESSION_SUMMARY.md lessons:

- **Never use the edit tool on `cherished_memory_screen.dart`** (1561 lines) — use `sed` for line-level changes due to repeating code patterns that cause `replaceAll` corruption
- **Verify file line count after each edit** (`wc -l`) as a sanity check
- **Keep `safe-rollback` git tag updated** after every successful change
- **Large classes should be split** into separate files during refactoring phases
- **Private classes should be made public** when used across multiple files
