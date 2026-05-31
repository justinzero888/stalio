# Session Summary — May 30, 2026

## What Was Built

Forked Blinking Notes v1.2.0 into **Stalio** — a clean habit/note tracking app.

### Core Development
- Removed AI, IAP, cards, onboarding, Chorus, voice transcribe, photo picker
- Restored emoji jar with glass mason jar design (CustomPainter)
- Built 3-tab Tallies page (Habits/Notes/Moods) with streak matrix heatmap
- Redesigned Habits page as single scrollable view (today checklist + streak matrix)
- Settings split into 3 tabs: General (voice, language, backup, T&C), Tags (CRUD), Habit Build
- 5-tab bottom nav: My Day, Tallies, +, Notes, Settings
- Center + button: navy (#1A2533) square with golden plus, stationed (not FAB)
- Renamed app from Micro Habits → Stalio (all platforms including iOS plist)

### UX Polish
- Sub-stat cards height capped at 110px (`SizedBox`) to prevent iPad/landscape overflow
- SectionCard titles wrapped in `Expanded` to prevent text overflow
- TagMoodSection crash fixed with `orElse` fallback for empty tags
- Voice notification timing fixed from 2-min window to 50s after scheduled time
- Background notifications confirmed working via `zonedSchedule`
- Seed data: 8 entries with tags/emotions, 31 habits (3 active), default tags
- App icon updated across iOS and Android (foreground + adaptive)
- Emoji jar label count fixed to show emoji count not note count

### Note Card Changes
- My Day: share icon removed, replaced with tag count icon
- Notes tab: tag chips shown below timestamp instead of count icon

## Files to Handle Carefully
- `cherished_memory_screen.dart` (1561 lines) — do NOT use edit tool. Use `sed` for line-level changes
- `routine_screen.dart` — complex single-view layout
- `app.dart` — nav index mapping (4 nav items → 3 screens + center button)

## Lessons Learned

### Edit Tool Pitfalls
- **Never use the edit tool on `cherished_memory_screen.dart`** — the file has many repeating patterns (`);\n  }\n}`) that cause the edit tool's `replaceAll` to match the wrong location. Four consecutive attempts to edit this file resulted in corruption (1000+ lines deleted). Use `sed` for precise line-level changes.
- **The edit tool's default behavior is `replaceAll: false`** — but `.` doesn't mean `replaceAll` is off. In at least one case, an edit that should have been a single replacement silently affected multiple locations.
- **Always `git checkout` the last known good version before making edits** on fragile files. Keep `safe-rollback` tag updated after every successful change.
- **Verify file line count after each edit** (`wc -l`) as a sanity check. The file going from 1607 → 536 lines is an immediate red flag.

### Code Organization
- **Large classes in the same Dart file** (30+ classes in `cherished_memory_screen.dart`) create fragile dependencies. Future refactoring should split these into separate files.
- **Private classes** (`_HabitsTab`, `_MiniStatCard`) prevent code reuse across files. Consider making shared widgets public when used in multiple contexts.

### Navigation Complexity
- **The `_navIndex` → `_screenIndex` mapping** is error-prone. The bottom nav has 5 items but only 3 screens (center + doesn't map to a screen). Future changes to tab count require updating `_navToScreen` mapping, `_onTabTapped`, and the screen list in `initState`.

### Seed Data
- **Always add a SharedPreferences guard** for seed data to prevent duplicate creation on subsequent launches.
- **Use stable IDs** (`seed_entry_1`, etc.) rather than UUIDs for seed entries to avoid duplicate detection issues.

## What's Next for New Dev Team

### Priority
1. **Test suite rebuild** — all tests reference deleted features, need fresh tests for current codebase
2. **Backup/Restore** — UI exists but implementation is placeholder
3. **Performance** — first launch takes ~5s on Android due to seed data + TTS init

### Color Schema Update
4. **Replace green/white palette with navy blue + gold** — the app currently inherits Blinking's green (#0D3B34 seed color, emerald accents). Replace with navy (#1A2533) and gold (#FFD700) throughout:
   - Theme seed color in `app.dart` MaterialApp
   - All card/section accent colors
   - Streak matrix completion cells
   - Habit completion indicators
   - Progress bars and chart colors
   - Android adaptive icon background
   - iOS launch screen background

### Legal Content
5. **Update Privacy Policy and Terms of Service** — currently still Blinking's legal text in `legal_content.dart`. Must be rewritten to:
   - Replace all "Blinking" references with "Stalio"
   - Remove AI/data processing clauses (LLM, personalization)
   - Remove IAP/subscription terms
   - Remove Chorus/social sharing clauses
   - Update data collection scope (no AI, no accounts)
   - Update contact email to Stalio address

### Tag Management Redesign
6. **Complete tag system overhaul** — current tags are flat (name + color). Requirements pending breakdown and design:
   - **Add category concept** to tags for maximum flexibility across different note logging styles (e.g. work, personal, health, travel)
   - Tag hierarchy or grouping: categories → tags
   - Tag analytics: usage per category, co-occurrence patterns
   - Bulk tag operations: assign category, merge tags, recolor
   - Tag auto-suggest based on content and existing patterns
   - UX: category filter in Notes tab, category colors, category-based insights

### Language/Localization Audit
7. **Thorough audit of all localizable strings** — identify and document gaps:
   - Audit every screen for hardcoded strings vs l10n keys
   - Currently mixed: some screens use `isZh ? '中文' : 'English'`, others use `l10n.xxx`
   - Missing localization surfaces: streak matrix labels, summary card labels, chart tooltips, seed entry content, background notification body text
   - Decision needed: keep current inline `isZh` pattern or migrate to full `AppLocalizations` delegate

### Notes Share Redesign
8. **Redesign notes sharing** — current share was removed (was single-note plain text). New design:
   - Multi-select notes for batch sharing
   - Format options before export: plain text, markdown, formatted with tags/emotions/dates
   - Preview before share
   - Selection UI: checkboxes on note cards, select-all, range selection
   - Share target: system share sheet, copy to clipboard, save as file

### Additional
9. **Habit image customization** — photo per habit
10. **Dark mode polish** — theme completeness audit
11. **Streak celebration animations** — milestone celebrations
12. **Export to CSV/PDF** — actual implementation (currently placeholder)
13. **iOS name cache** — needs fresh install to show "Stalio" on home screen (Info.plist is correct now, simulator caches old name)

## Git
- `safe-rollback` tag always points to last known good state
- Version: 1.0.0+1 (dev, unreleased)
- All three sims running with 0 analysis errors
