# Stalio — Manual UAT Checklist (Phase 6)

> **Date:** June 14, 2026  
> **Tester:** ___________  
> **Build:** 1.0.0 (9)  
> **Pre-requisite:** TestFlight / Closed Testing build installed

---

## 1. Crash Reporting (Firebase Crashlytics)

| # | Test | Expected | Result |
|---|------|----------|--------|
| 1.1 | Open Settings → General | "Crash Reporting" toggle visible below Voice Reminders | |
| 1.2 | Verify toggle is ON by default | Switch shows enabled | |
| 1.3 | Toggle OFF | Switch disabled; "Send anonymous crash reports..." subtitle | |
| 1.4 | Toggle ON again | Re-enabled | |
| 1.5 | Kill app → relaunch | Toggle state persists (stored in SharedPreferences) | |
| 1.6 | Verify Firebase console | Crashlytics dashboard shows app as "active" (within 5 min of first launch) | |

---

## 2. Default Tag Categories (Fresh Install)

| # | Test | Expected | Result |
|---|------|----------|--------|
| 2.1 | Fresh install → Settings → Tags | 9 default categories visible: 养/劲/食/息/心/省/戒/缘/杂 | |
| 2.2 | Expand category → check emoji | 💊 Health, 🏃 Fitness, 🥗 Nutrition, 😴 Sleep, 🧘 Mindfulness, 💭 Reflection, 🛡️ Restraint, 👥 Connection, ⭐ Other | |
| 2.3 | Create a custom category → delete app data → reinstall | Only 9 defaults reappear (temporary categories not persisted) | |

---

## 3. DB Schema Cleanup (Smoke Test)

| # | Test | Expected | Result |
|---|------|----------|--------|
| 3.1 | Launch app on existing install (upgrade path) | No crash; all existing data intact (entries, tags, habits) | |
| 3.2 | Fresh install → check app storage | App install size reduced (no card templates, no AI tables) | |
| 3.3 | Create entry with tags → kill → relaunch | Entry and tags preserved (core tables intact) | |

---

## 4. Bundle ID & Branding

| # | Test | Expected | Result |
|---|------|----------|--------|
| 4.1 | App Info (iOS: Settings → General → iPhone Storage; Android: App Info) | Bundle: `com.orbacetech.stalio` | |
| 4.2 | Check About section | "Stalio" + version 1.0.0 | |
| 4.3 | No "Blinking", "Micro Habits", "micro_habits" visible anywhere | All branding = "Stalio" only | |

---

## 5. Performance Check

| # | Test | Expected | Result |
|---|------|----------|--------|
| 5.1 | Cold launch → measure time to My Day visible | < 3 seconds on real device | |
| 5.2 | Navigate all 5 tabs rapidly | No stutter, no freeze, no crash | |
| 5.3 | Settings → Export PDF (10+ entries) | Generates without crash | |

---

## 6. Regression — Core Features

| # | Test | Expected | Result |
|---|------|----------|--------|
| 6.1 | IAP: Settings → "Remove Ads" visible | Shows $3.99 with purchase flow | |
| 6.2 | CSV/PDF export working | Date picker → progress → share sheet | |
| 6.3 | Tag categories: create/edit/delete | Dialogs work correctly | |
| 6.4 | Notes share: multi-select + share preview | Format switcher: Plain/Markdown/Rich | |
| 6.5 | Dark mode toggle | All screens render in dark | |
| 6.6 | Language toggle EN ↔ ZH | All screens switch correctly | |

---

## Defect Summary

| # | Severity | Description | Flow | Platform |
|---|----------|-------------|------|----------|
| 1 | | | | |
| 2 | | | | |

---

## Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Tester | | | |
| Dev Review | | | |
| PM / Business | | | |
