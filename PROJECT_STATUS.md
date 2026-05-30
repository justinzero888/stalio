# Stalio — Project Status

> Stalio: Do. Tally. Grow. Last updated: May 30, 2026

## Build Status

| Metric | Status |
|--------|--------|
| `flutter analyze` (lib) | 0 errors, 0 warnings |
| iPhone 17 Pro sim | Running |
| iPad Air 11" M4 sim | Running |
| Android API 36 emu | Running |

## Versions

| Tag | Commit | Description |
|-----|--------|-------------|
| v1.3.0 | e68deab | Current: Stalio branding, 5-tab nav with center + |
| safe-rollback | e68deab | Always points to last known good state |

---

## Navigation: 5-tab station

```
[ My Day ]  [ Tallies ]  [ + ]  [ Notes ]  [ Settings ]
```

- **My Day** — calendar, entries, habit check-in, emoji jar
- **Tallies** — 3 sub-tabs: Habits (stats + streak matrix), Notes (writing activity + trends), Moods (jar + charts)
- **+** — navy square with golden +, opens Add Entry
- **Notes** — note list with search + tag filter
- **Settings** — General (voice, language, backup, T&C), Tags (CRUD), Habit Build

---

## Features

| Feature | Status |
|---------|--------|
| My Day (calendar, emoji jar, habit check-in) | Full |
| Tallies (3 tabs: Habits, Notes, Moods) | Full |
| Notes (search, tag filter, add/edit) | Full |
| Settings (3 tabs: General, Tags, Habit Build) | Full |
| Voice reminders (TTS foreground) | Full |
| Background notifications (OS-level) | Full |
| Bilingual (EN/ZH) | Full |
| Streak matrix heatmap | Full |

## Completed Removals

AI, IAP, keepsake cards, onboarding, voice transcribe, photo/camera picker, floating robot, BYOK, Chorus, soft prompt, RevenueCat.

## Rollback

`git checkout safe-rollback` or `git checkout v1.3.0`
