# Stalio — works_item_0610.md

> Phase 4: Feature Expansion | June 10, 2026  
> Prerequisite: Phase 3 PM sign-off

---

## Current State (after Phase 3)

- 253 tests pass, zero analysis errors
- All 5 screens localized (EN ↔ ZH) via AppLocalizations framework (163 keys)
- Dark mode with system-follow + persistence
- Backup/restore UI wired
- App class renamed StalioApp, all branding cleaned
- 3 sims running: iPhone 17 Pro, iPad Air 11" M4, Android API 36

---

## Phase 4: Feature Expansion (Week 4–6)

**Dependencies:** Phase 3 sign-off | **Est. Effort:** 10–14 days | **Target:** 49 new tests

### Item 9: Tag Management Redesign `[Priority #6]`

| Feature | Description |
|---------|-------------|
| Categories | Tags grouped under named categories with own colors/icons |
| Hierarchy | Categories → Tags (one level). Each tag belongs to exactly one category. |
| DB Migration | `tag_categories` table + `category_id` FK on `tags` table |
| Bulk operations | Multi-select → assign category, merge tags, batch recolor |
| Auto-suggest | Suggest tags during note creation based on content + patterns |

**Key files to create/modify:**
- `lib/models/tag_category.dart` — new model
- `lib/repositories/tag_category_repository.dart` — new repository
- `lib/providers/tag_category_provider.dart` — new provider
- `lib/core/services/database_service.dart` — migration script
- `lib/screens/settings/settings_screen.dart` — redesigned Tags tab with expandable categories

**WARNING:** Tag migration must NOT drop/alter existing tag data. All existing tags get `category_id = null` (uncategorized). Rollback must be tested.

### Item 10: Export to CSV/PDF `[Priority #12]`

**CSV:** Backend already in `export_service.dart` — just wire the UI button.

**PDF (from scratch):**
- Add `pdf` package to pubspec.yaml
- Implement `ExportService.exportPdf()`: title page, entry list, streak summary, mood chart, CJK font embedding
- Date range picker before export (All time, Last 30/90 days, Custom)
- File save dialog (Android SAF / iOS file system)
- Progress indicator for large exports (>100 entries)

### Item 11: Notes Share Redesign `[Priority #8]`

- Multi-select mode in Notes tab (checkbox, long-press, range select)
- Three share formats: Plain text, Markdown, Rich formatted
- Format preview screen before sharing
- System share sheet + copy to clipboard + save as file

---

## Phase 4 Tasks — Sequential Breakdown

### Week 4

| Day | Task | Output |
|-----|------|--------|
| 1 | `TagCategory` model + repository + provider | `lib/models/tag_category.dart`, `lib/repositories/tag_category_repository.dart` |
| 2 | DB migration: `tag_categories` table + `tags.category_id` column | `lib/core/services/database_service.dart` migration |
| 3 | Settings Tags tab redesigned with expandable categories | `lib/screens/settings/settings_screen.dart` |
| 4 | Bulk tag operations: multi-select, assign, merge, recolor | Tags tab + dialogs |
| 5 | Tag analytics sub-tab in Tallies: usage chart, co-occurrence, timeline | `lib/screens/cherished/cherished_memory_screen.dart` (sed only!) |

### Week 5

| Day | Task | Output |
|-----|------|--------|
| 6 | Tag auto-suggest during note creation | `lib/screens/add_entry_screen.dart` + `lib/providers/` |
| 7 | Category filter chips in Notes tab | `lib/screens/moment/moment_screen.dart` |
| 8 | Export CSV UI wiring + date range picker | `lib/screens/settings/settings_screen.dart` |
| 9 | PDF export: `ExportService.exportPdf()` + date range + progress | `lib/core/services/export_service.dart` |
| 10 | Notes share: multi-select mode + format preview screen | `lib/screens/moment/moment_screen.dart` + new share screen |

### Week 6

| Day | Task | Output |
|-----|------|--------|
| 11 | Notes share: share sheet + clipboard + save file | Share integration |
| 12 | Write 49 new tests (see test case table below) | `test/models/`, `test/providers/`, `test/screens/` |
| 13 | Regression: all screens, backup includes tags, data intact | Full QA pass |
| 14 | Maestro UAT flows + manual checklist | `test/maestro/phase4_*.yaml` + `docs/UAT_PHASE4.md` |

---

## Phase 4 Test Cases (49 new)

| # | File | Tests | Description |
|---|------|-------|-------------|
| 1 | `test/models/tag_category_test.dart` | 6 | TagCategory CRUD, serialization, usage count |
| 2 | `test/providers/tag_category_provider_test.dart` | 8 | Category CRUD, reorder, delete cascade |
| 3 | `test/models/entry_share_format_test.dart` | 9 | Plain text, markdown, rich format (3 per format) |
| 4 | `test/core/export_pdf_test.dart` | 4 | PDF generation, page count, CJK fonts, content |
| 5 | `test/core/export_csv_test.dart` | 3 | CSV header, data rows, escaping, BOM |
| 6 | `test/integration/phase4_tag_migration_test.dart` | 3 | Migration adds column, data preserved, rollback |
| 7 | `test/integration/phase4_export_roundtrip_test.dart` | 2 | CSV opens in spreadsheet, PDF valid |
| 8 | `test/screens/notes_share_selection_test.dart` | 6 | Multi-select, select-all, range, deselect, cancel, count |
| 9 | `test/screens/notes_share_preview_test.dart` | 3 | Preview renders, scrollable, format switch |
| 10 | `test/screens/tag_category_ui_test.dart` | 5 | Expandable sections, add/edit/delete, filter chips |

---

## Phase 5 Pre-work (Parallel)

While Phase 4 is in progress, the PM should complete:

- [ ] **AdMob account** created + ad units provisioned
- [ ] **Google Play Console:** Merchant account active + `remove_ads` IAP product
- [ ] **App Store Connect:** Paid Apps agreement active + `remove_ads` IAP product
- [ ] **Privacy Policy URL** hosted with AdMob disclosure
- [ ] AdMob App IDs + Ad Unit IDs handed off to dev team

See `EXTERNAL_SETUP_GUIDE.md` for step-by-step instructions. This has 1–7 day lead times and **blocks Phase 5 start**.

---

## File Safety Notes (from SESSION_SUMMARY.md)

- **Never use the edit tool on `cherished_memory_screen.dart`** (1561 lines) — use `sed` for line-level changes due to repeating code patterns that cause `replaceAll` corruption
- **Verify file line count after each edit** (`wc -l`) as a sanity check
- **Keep `safe-rollback` git tag updated** after every successful change
- **Large classes should be split** into separate files during refactoring phases
- **Private classes should be made public** when used across multiple files

---

## Current Blocker List

| # | Blocker | Impact | Resolution |
|---|---------|--------|------------|
| 1 | Phase 3 PM sign-off pending | Blocks Phase 4 start | PM reviews UAT checklist, signs off |
| 2 | AdMob / Google / Apple accounts not created | Blocks Phase 5 (week 6–7) | PM follows EXTERNAL_SETUP_GUIDE.md |
| 3 | RevenueCat dead code still in tree | Phase 5 will remove it | Safe to leave until Phase 5 Item 12 |
| 4 | Seed data batching blocked by sqflite tx lock | Performance Phase 2 item | Needs deeper refactoring in Phase 6 |

---

## Known Issues

- Cold start ~2s (measured on Android emulator, TTS lazy init helped)
- `transition_screen.dart` still exists but dead code (navigates to deleted paywall)
- RevenueCat `purchases_service.dart` still runs in background (logs but no crash) — deleted in Phase 5
- `cherished_memory_screen.dart` is 1561 lines — needs to be split during Phase 4 refactoring
- Some remaining `isZh` in deeply nested dialog code (RoutineDialog, tag dialogs) — Phase 4 will clean
