# Stalio — Project Status

> Stalio: Do. Tally. Grow. v1.0.0-dev. Last updated: June 9, 2026

## Build

| Metric | Status |
|--------|--------|
| `flutter analyze` (lib) | 0 errors, 0 warnings |
| `flutter test` | 253 tests pass, exit 0 |
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
- `+` is navy (#10317D) rounded square with golden (#E0B84F) plus — opens Add Entry

## Architecture

### Provider Tree
```
StorageService
├── EntryProvider     (notes CRUD, search, filter)
├── RoutineProvider   (habits CRUD, completion, voice scheduling)
├── TagProvider       (tag CRUD)
├── LocaleProvider    (EN/ZH)
├── ThemeProvider     (light/dark/system)
├── JarProvider       (emotion aggregation)
└── SummaryProvider   (chart metrics)
```

### Storage
- SQLite: entries, tags, entry_tags, routines, completions
- SharedPreferences: voice toggle, theme_mode, locale, seed flags
- Theme persistence: SharedPreferences key `theme_mode` (light/dark/system)
- Seed data: 8 demo entries, 31 habits (3 active), 6 custom tags + 1 system tag

---

## Phase Status

| Phase | Status | Tests | Sign-off |
|---|---|---|---|
| 1: Foundation & Branding | **Signed off** | 166 | ✓ |
| 2: Core Features | **Signed off** | 13 + 1 manual | ✓ |
| 3: UX & Localization | **Awaiting PM sign-off** | 21 new (253 total) | [ ] |
| 4: Feature Expansion | Not started | — | — |
| 5: Monetization | Blocked (external setup) | — | — |
| 6: Polish & Delight | Not started | — | — |

---

## Phase 3 Deliverables

### Item 6: Language/Localization Audit ✓
- ARB files: `appName` → `"Stalio"` in both en/zh, 40+ deleted-feature keys removed, 70+ new keys added
- `AppLocalizations` abstract class + en/zh implementations rewritten with full coverage
- Inline `isZh ? '中文' : 'English'` replaced with `AppLocalizations.of(context)!` in 8 files:
  - `home_screen.dart`, `moment_screen.dart`, `add_entry_screen.dart`
  - `settings_screen.dart`, `routine_screen.dart`
  - `calendar_widget.dart`, `emoji_jar.dart`, `routine_item.dart`
- Remaining `isZh` patterns are legitimate boolean passes to model methods (`displayName(isZh)`, `DateFormat` patterns, dialog form labels)

### Item 7: Dark Mode Polish ✓
- Theme persistence via SharedPreferences (`theme_mode` key)
- System theme follow (`ThemeMode.system`) as third option
- Theme settings UI in Settings → General with RadioListTile picker
- Dark theme: navy (#6B8FDE) primary, gold (#E0B84F) accent, dark surfaces (#121212/#0D0D0D/#1E1E1E)

### Item 8: iOS Name Cache Fix ✓
- `CFBundleDisplayName` already `"Stalio"` in Info.plist — no change needed

### BlinkingApp → StalioApp
- `lib/app.dart` class renamed `BlinkingApp` → `StalioApp`
- `lib/main.dart` updated to use `StalioApp`
- Remaining "Blinking" refs only in dead code (purchases_service, paywall_screen) and DB migrations

---

## L10n Architecture

```
lib/l10n/
├── app_en.arb              (163 keys, English source)
├── app_zh.arb              (163 keys, Chinese source)
├── app_localizations.dart  (abstract class, 163 getters + delegate)
├── app_localizations_en.dart (English implementation)
├── app_localizations_zh.dart (Chinese implementation)
└── l10n.dart               (Locale list + getLanguageName helper)
```

---

## Maestro UAT Flows

| File | Flows | Covers |
|------|-------|--------|
| `test/maestro/phase1_branding.yaml` | 4 | Branding, Stalio name, no Blinking |
| `test/maestro/phase1_navigation.yaml` | 7 | 5-tab nav, + button, roundtrip |
| `test/maestro/phase1_smoke.yaml` | 8 | Visual smoke, all tabs, language toggle |
| `test/maestro/phase2_backup_restore.yaml` | 4 | Backup button, restore dialog, no crash |
| `test/maestro/phase3_l10n.yaml` | 12 | EN↔ZH toggle, all 5 screens both locales |
| `test/maestro/phase3_dark_mode.yaml` | 11 | Light/Dark/System, all screens dark mode |
| **Total** | **46** | |

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
| Backup/Restore UI (ZIP export + restore from file) | Full |
| Dark mode (light/dark/system with persistence) | Full |
| Theme provider (SharedPreferences persistence) | Full |
| AppLocalizations framework (163 keys, fully wired) | Full |

---

## Removed from Blinking Notes

Floating AI robot, AI services (LLM, personas, lens sets), IAP/RevenueCat, keepsake cards, onboarding/transition, BYOK, Chorus social, voice transcribe, photo/camera picker, soft prompt, trial banners, paywall, AI Secrets tag, Blinking branding

---

## Code Patterns

- `entry_card.dart` — shared by My Day (tag count in header) and Moments (no tag count)
- `cherished_memory_screen.dart` — Tallies 3-tab implementation (1561 lines, do NOT use edit tool on this file — use sed for precise line-level edits)
- `routine_screen.dart` — Habits page (single scroll view with today checklist + streak matrix)
- `settings_screen.dart` — 3 subtabs with initialTab parameter
- `l10n/` — full AppLocalizations framework, ARB-driven, 163 keys

## Rollback

`git checkout safe-rollback` — last known good state at tag `safe-rollback`
