# Micro Habits — Project Status

> Forked from Blinking Notes v1.2.0. Last updated: May 29, 2026

## Build Status

| Metric | Status |
|--------|--------|
| `flutter analyze` (lib) | 0 errors, 0 warnings |
| iPhone 17 Pro sim | Running |
| iPad Air 11" M4 sim | Running |
| Android API 36 emulator | Running |

## App Identity

| Field | Value |
|-------|-------|
| Name | Micro Habits |
| Tagline | Do. Tally. Grow. |
| Motto | A thousand miles begins with a single step |
| AppBar header | Stalio: Do. Tally. Grow. |

---

## Navigation (4 tabs)

| Tab | Label | Content |
|-----|-------|---------|
| 1 | My Day | Calendar navigation, today's entries + habit check-in with emoji jar |
| 2 | Moments | Note list with search, tag filter, add/edit notes |
| 3 | Habits | Single unified view: summary cards + today checklist + streak matrix |
| 4 | Tallies | 10 chart sections: hero stats, heatmap, pie chart, trend charts, top tags, checklist, tag-mood, emoji jars |

---

## Architecture

### Provider Tree
```
StorageService
├── EntryProvider     (notes CRUD, search, filter by tag)
├── RoutineProvider   (habits CRUD, completion toggle, voice reminder scheduling)
├── TagProvider       (tag CRUD)
├── LocaleProvider    (EN/ZH)
├── ThemeProvider     (light/dark)
├── JarProvider       (emotion aggregation per day/month/year)
└── SummaryProvider   (chart metrics: note counts, habit rates, streaks, mood)
```

### Storage
- SQLite via `DatabaseService` (5 tables: entries, tags, entry_tags, routines, completions)
- SharedPreferences for settings (voice toggle, theme, locale)
- Export/Import: ZIP backup (UI placeholder), JSON export

### Background Notifications
- **Text**: OS-scheduled via `zonedSchedule` — fires at exact reminder time regardless of app state
- **Voice**: Foreground TTS — periodic 30s timer speaks habit name within 50s after scheduled time
- Both reschedule on every app launch to survive device reboots
- Per-habit voice toggle + global voice toggle in Settings

---

## Features

| Feature | Status |
|---------|--------|
| My Day | Full — calendar, entries, habit check-in, emoji jar |
| Moments | Full — note list, search, tag filter, add/edit with tags + mood |
| Habits | Full — single scrollable: summary cards (Total/Best Streak/Active), today checklist, streak matrix heatmap |
| Tallies | Full — hero stats, calendar heatmap, mood pie chart, writing stats, 3 trend charts (notes/habits/mood), top tags, checklist insights, tag-mood correlation, yearly emoji jars |
| Settings | Full — 3 tabs: General (voice, language, backup/restore, version, T&C), Tags (add/edit/delete with color picker), Habit Build (create/edit/toggle habits with category icons) |
| Emoji tracking | Full — mood picker on add entry, jar visualization on My Day and Tallies |
| Voice reminders | Full — TTS foreground reminders |
| Background notifications | Full — OS-scheduled text alerts at exact time |
| Bilingual UI | Full — EN/ZH toggle in Settings > General |
| Backup/Restore | Placeholder (UI exists) |

---

## Completed Removals (from Blinking Notes)

| # | Feature | Committed |
|---|---------|-----------|
| 1 | Floating AI robot | Step 1 |
| 2 | Keepsake cards (templates, renderer, builder, preview) | Step 4 |
| 3 | AI services (LLM, assistant, personas, lens sets, prompt assembler) | Step 5 |
| 4 | IAP (EntitlementService, PurchasesService, PaywallScreen, RevenueCat) | Step 5 |
| 5 | Onboarding/Transition screens | Step 5 |
| 6 | BYOK setup, lens config | Step 5 |
| 7 | Soft prompt / re-engagement | Removed |
| 8 | AI/Welcome system tags (tag_synthesis, tag_welcome) | Removed |
| 9 | Voice transcribe (speech_to_text) | Removed |
| 10 | Photo/Camera picker from add entry | Removed |
| 11 | Card sharing / Chorus posting | Removed |

---

## Design Decisions

| Decision | Resolution |
|----------|------------|
| Keep emoji emotion picker? | Yes — kept |
| Keep keepsake cards? | No — removed entirely |
| Routine → Habits rename | Yes — tab label |
| Settings structure | 3 tabs: General, Tags, Habit Build |
| Insights → Tallies rename | Yes — branding alignment |
| Combine Do/Streaks into one view | Yes — single scrollable page |
| Voice transcribe | Removed — unnecessary complexity |
| Tag location in Add Memory | Moved up right below note text field |
| Edit Tag CTA in Add Memory | Navigates to Settings > Tags tab |
| Edit Habit CTA on My Day | Navigates to Settings > Habit Build tab |
| Welcome banner | "A thousand miles begins with a single step" |

---

## Known Issues

- Test suite has errors from deleted features (needs rebuild)
- Backup/Restore feature has placeholder UI only
- Nested ListView in Habits fixed with shrinkWrap + NeverScrollableScrollPhysics
