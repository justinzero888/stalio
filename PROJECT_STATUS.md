# Micro Habits — Project Status

> Derived from Blinking Notes v1.2.0+43. Last updated: May 28, 2026

## Build Status

| Metric | Status |
|--------|--------|
| `flutter analyze` | 0 errors, 0 warnings |
| `flutter test` | Pending (test suite needs rebuild) |
| iPhone 17 Pro | Running |
| iPad Air 11" M4 | Running |
| Android API 36 | Running |

## Architecture

### Navigation (4 tabs)
```
My Day | Moments | Habits | Insights
```

### Provider Tree
```
StorageService
  └─ EntryProvider (notes CRUD, search, filter)
  └─ RoutineProvider (habits CRUD, completion, voice)
  └─ TagProvider (tag CRUD)
  └─ LocaleProvider (EN/ZH)
  └─ ThemeProvider (light/dark)
  └─ JarProvider (emotion aggregation)
  └─ SummaryProvider (chart metrics)
```

### Storage
- SQLite via `DatabaseService` (schema v16, tables preserved)
- SharedPreferences for settings (theme, locale, voice toggle)
- Export/Import: ZIP backup, JSON export, CSV export

## Completed Removals

| # | Change | Status |
|---|--------|--------|
| 1 | Remove floating AI robot from all tabs | Done |
| 2 | Rename Routine tab to Habits | Done |
| 3 | Remove AI tab, entitlement banner, purchase guards from Settings | Done |
| 4 | Remove keepsake cards (models, services, provider, widgets) | Done |
| 5 | AI services (LLM, assistant, personas, lens sets) | Core done |
| 6 | IAP (EntitlementService, PurchasesService, PaywallScreen) | Core done |
| 7 | Onboarding/Transition screens | Done |

## Screens Needing Rebuilt (currently stubbed)

| Screen | Current State | Target |
|--------|---------------|--------|
| Settings | Voice toggle only | Add tag management, backup/export, language |
| Insights | Note/habit counts only | Add charts (note counts, habit rates, mood trends, top tags) |
| Emoji Jar | Text placeholder | Restore emoji jar visualization |

## Features Preserved

| Feature | Status |
|---------|--------|
| My Day (Calendar) | Full - home screen, calendar, entry list |
| Moments | Full - note list, search, filter, add/edit |
| Habits | Full - routine CRUD, completion, streak, voice reminders |
| Voice notifications | Full - TTS + background notifications |
| Backup/Restore | Full - ZIP export/import |
| Emotion tracking | Full - emotion picker preserved |
| Bilingual UI (EN/ZH) | Full |

## Known Issues

- `cherished_memory_screen` replaced with minimal stub (72 errors in original from AI references)
- `settings_screen` replaced with minimal stub (33 errors in original)
- `emoji_jar` replaced with minimal stub (5 errors in original)
- Test suite has 38+ errors from deleted features
