# Stalio — Project Status

> Stalio: Do. Tally. Grow. v1.0.0-dev. Last updated: May 30, 2026

## Build

| Metric | Status |
|--------|--------|
| `flutter analyze` (lib) | 0 errors, 0 warnings |
| iPhone 17 Pro | Running |
| iPad Air 11" M4 | Running |
| Android API 36 | Running |

## App Identity

| Field | Value |
|-------|-------|
| Name | Stalio |
| Tagline | Do. Tally. Grow. |
| Package | stalio (com.microhabits.micro_habits) |
| Version | 1.0.0+1 (dev) |

## Navigation (5 tabs, stationed)

```
[ My Day ]  [ Tallies ]  [  +  ]  [ Notes ]  [ Settings ]
```
- `+` is navy (#1A2533) rounded square with golden (#FFD700) plus — opens Add Entry

## Architecture

### Tabs
| Tab | Screen | Content |
|-----|--------|---------|
| My Day | HomeScreen | Calendar, entries, habit check-in, emoji jar |
| Tallies | InsightsScreen | 3 sub-tabs: Habits (stats + streak matrix), Notes (writing activity + trends), Moods (jar + charts) |
| + | AddEntryScreen | Stationed nav button, opens Add Memory |
| Notes | MomentScreen | Note list with search, tag filter, tag chips on cards |
| Settings | SettingsScreen | 3 sub-tabs: General, Tags, Habit Build |

### Provider Tree
```
StorageService
├── EntryProvider     (notes CRUD, search, filter)
├── RoutineProvider   (habits CRUD, completion, voice scheduling)
├── TagProvider       (tag CRUD)
├── LocaleProvider    (EN/ZH)
├── ThemeProvider     (light/dark)
├── JarProvider       (emotion aggregation)
└── SummaryProvider   (chart metrics)
```

### Storage
- SQLite: entries, tags, entry_tags, routines, completions
- SharedPreferences: voice toggle, theme, locale, seed flag
- Seed data: 8 demo entries with tags/emotions, 31 habits (3 active), 6 custom tags + 1 system tag

### Background Notifications
- Text: OS-scheduled via `zonedSchedule` at exact reminder time
- Voice: Foreground TTS within 50s after scheduled time
- Rescheduled on every app launch

---

## Features

| Feature | Status |
|---------|--------|
| My Day — calendar, entries, habit check-in, emoji jar | Full |
| Moments — note list, search, tag filter, tag chips | Full |
| Tallies — 3 sub-tabs: Habits, Notes, Moods | Full |
| Settings — General, Tags, Habit Build | Full |
| Emoji tracking (emotion picker + jar) | Full |
| Voice reminders (foreground TTS) | Full |
| Background notifications (OS-level) | Full |
| Bilingual UI (EN/ZH) | Full |
| Streak matrix heatmap | Full |
| Habit Build (create/edit/toggle with categories) | Full |
| Tag management (CRUD with color picker) | Full |
| Seed data (entries + habits + tags) | Full |

---

## Removed from Blinking Notes

Floating AI robot, AI services (LLM, personas, lens sets), IAP/RevenueCat, keepsake cards, onboarding/transition, BYOK, Chorus social, voice transcribe, photo/camera picker, soft prompt

## Code Patterns

- `entry_card.dart` — shared by My Day (tag count in header) and Moments (no tag count)
- `cherished_memory_screen.dart` — Tallies 3-tab implementation (1561 lines, do NOT use edit tool on this file — use sed for precise line-level edits)
- `routine_screen.dart` — Habits page (single scroll view with today checklist + streak matrix + weekly reflection)
- `settings_screen.dart` — 3 subtabs with initialTab parameter

## Rollback

`git checkout safe-rollback` — last known good state at tag `safe-rollback`
