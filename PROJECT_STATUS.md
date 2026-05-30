# Micro Habits — Project Status

> Derived from Blinking Notes v1.2.0. Last updated: May 29, 2026

## Build Status

| Metric | Status |
|--------|--------|
| `flutter analyze` | 0 errors, 0 warnings |
| iPhone 17 Pro | Running |
| iPad Air 11" M4 | Running |
| Android API 36 | Running |

## Architecture

### Navigation (4 tabs)
```
My Day | Moments | Habits | Insights
```

### Habits Page — Single Unified View
1. **Summary Cards** — Total habits, Best Streak, Active count
2. **Today Section** — Date header, pending/completed checklist with progress bar
3. **Streak Matrix** — GitHub-style heatmap per habit row, spanning from earliest data date
4. Settings > Habits tab — Full Build tab with category icons, active/paused toggle, +Add Habit dialog

## Background Notification Behavior

### Text Notifications (OS-level)
- Scheduled via `zonedSchedule` (flutter_local_notifications)
- **Fires at exact scheduled time** regardless of app state (foreground, background, killed)
- Android: AlarmManager with `inexactAllowWhileIdle` for Doze mode
- iOS: UNUserNotificationCenter scheduled trigger
- Rescheduled on every app launch to survive device reboots
- Title: "Habit Reminder", Body: habit name

### Voice Notifications (in-app TTS)
- Foreground-only via `flutter_tts`
- Periodic 30-second timer checks if any reminder time has just passed (within 50 seconds)
- Fires approximately at the scheduled time, only when app is in foreground
- Global voice toggle in Settings > General

## Completed Changes

| # | Change | Status |
|---|--------|--------|
| 1 | Remove floating AI robot from all tabs | Done |
| 2 | Rename Routine tab to Habits | Done |
| 3 | Remove AI tab, entitlement banner, purchase guards from Settings | Done |
| 4 | Remove keepsake cards | Done |
| 5 | AI services (LLM, assistant, personas, lens sets) | Done |
| 6 | IAP (EntitlementService, PurchasesService, PaywallScreen) | Done |
| 7 | Onboarding/Transition screens | Done |
| 8 | Restore emoji jar with prettier glass design | Done |
| 9 | Restore insights templates (10 non-AI charts) | Done |
| 10 | Settings → 3 tabs (General, Tags, Habit Build) | Done |
| 11 | Habits → single unified view with streak matrix | Done |
| 12 | Remove voice transcribe | Done |
| 13 | Remove AI/Welcome tags | Done |
| 14 | Welcome message updated to Micro Habits branding | Done |

## Features

| Feature | Status |
|---------|--------|
| My Day (Calendar) | Full |
| Moments (Notes) | Full |
| Habits | Full - Today checklist, Streak Matrix, Summary Cards |
| Insights | Full - 10 sections (hero stats, heatmap, pie chart, 3 trend charts, top tags, checklist, tag-mood, emoji jars) |
| Settings | Full - General (voice, language, backup, terms), Tags (CRUD), Habit Build |
| Voice notifications | Full - TTS foreground reminders |
| Background notifications | Full - OS-scheduled text alerts |
| Emotion tracking | Full |
| Bilingual UI (EN/ZH) | Full |
| Backup/Restore | Placeholder (UI exists, implementation pending) |
