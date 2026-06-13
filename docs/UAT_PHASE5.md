# Stalio — Manual UAT Checklist (Phase 5)

> **Date:** June 13, 2026  
> **Tester:** ___________  
> **Platform:** ___________ (real device only)  
> **Build:** 1.0.0 (8)  
> **Pre-requisite:** TestFlight build installed (iOS) / Closed Testing build installed (Android)

---

## 1. Smoke Test — App Launch & Navigation

| # | Test | Expected | Result |
|---|------|----------|--------|
| 1.1 | Cold launch the app | App opens without crash; My Day screen visible | |
| 1.2 | Navigate to Tallies → check all 4 tabs | Habits, Notes, Moods, Tags all render | |
| 1.3 | Navigate to Notes | Entry list renders; date + category filter chips visible | |
| 1.4 | Navigate to Settings → General | All tiles render: Voice, Theme, Language, Backup, Export CSV, Export PDF, Remove Ads, Restore, About | |
| 1.5 | Navigate to Settings → Tags | Category expandable sections with tags visible | |
| 1.6 | Navigate to Settings → Habit Build | Active/paused habits render correctly | |
| 1.7 | Return to My Day | Bottom nav functional; no crash on tab switch | |

---

## 2. AI & RevenueCat Cleanup Verification

| # | Test | Expected | Result |
|---|------|----------|--------|
| 2.1 | Open an entry detail (Notes tab → tap entry) | Detail screen shows content, edit, share buttons; NO "Post to Chorus" button | |
| 2.2 | Check Settings → scroll to bottom | No paywall, entitlement, or trial references in any screen | |
| 2.3 | Check app name | App name shows "Stalio" everywhere (App Bar, Settings → About) | |
| 2.4 | Check About section | Shows "Stalio", version 1.0.0 | |

---

## 3. Bundle ID & Branding

| # | Test | Expected | Result |
|---|------|----------|--------|
| 3.1 | Verify bundle ID (iOS: Settings → General → iPhone Storage; Android: App Info) | Bundle ID: `com.orbacetech.stalio` | |
| 3.2 | No "Blinking", "Micro Habits", or "micro_habits" names visible | All branding shows "Stalio" only | |

---

## 4. AdMob Banner Ads

| # | Test | Expected | Result |
|---|------|----------|--------|
| 4.1 | Open Settings → General | Banner ad visible at the bottom of the screen | |
| 4.2 | Banner does not obstruct content | All settings tiles scrollable and tappable; banner at very bottom | |
| 4.3 | Banner is a standard AdMob test/production banner | Not a placeholder; looks like a real ad | |
| 4.4 | "Remove Ads" tile visible | Shows below the banner with price "$3.99 one-time purchase" | |

---

## 5. IAP — Remove Ads Purchase

| # | Test | Expected | Result |
|---|------|----------|--------|
| 5.1 | Tap "Remove Ads" tile | Purchase dialog opens (system payment sheet) | |
| 5.2 | Purchase with sandbox tester account | Shows "$3.99" price, product name "Remove Ads" | |
| 5.3 | Cancel purchase | Returns to Settings; banner still visible | |
| 5.4 | Complete purchase | "Ads removed!" snackbar confirmation | |
| 5.5 | Banner hidden after purchase | Banner ad no longer visible in Settings | |
| 5.6 | "Remove Ads" tile hidden after purchase | Tile no longer visible in Settings | |
| 5.7 | Kill app and relaunch | Banner still hidden; "Remove Ads" tile still hidden | |
| 5.8 | Delete and reinstall app | Banner visible again; "Remove Ads" tile visible again | |
| 5.9 | Tap "Restore Purchases" (if implemented) or re-purchase via tile | Purchase restored; ads hidden again | |

---

## 6. Export — CSV & PDF

| # | Test | Expected | Result |
|---|------|----------|--------|
| 6.1 | Settings → Export CSV | Date range picker: All time, Last 30/90 days, Custom | |
| 6.2 | Export CSV → All time | Progress indicator → system share sheet opens | |
| 6.3 | Share CSV via email/message | File shares correctly | |
| 6.4 | Settings → Export PDF | Date range picker opens | |
| 6.5 | Export PDF → All time | Progress indicator → system share sheet opens | |
| 6.6 | Open shared PDF | Title page "Stalio — Journal Export" visible; entries listed | |

---

## 7. Notes Share

| # | Test | Expected | Result |
|---|------|----------|--------|
| 7.1 | Notes tab → long-press on entry | Checkboxes appear; app bar shows count + share/close | |
| 7.2 | Select 2+ entries → tap share | Format preview dialog: Plain, Markdown, Rich tabs | |
| 7.3 | Switch to Markdown | Preview updates to markdown format | |
| 7.4 | Tap Copy icon | Confirmation snackbar "Copied" | |
| 7.5 | Tap Share button | System share sheet opens | |
| 7.6 | Tap Save as file | File saved; share sheet opens | |
| 7.7 | Tap close (X) | Returns to normal view | |

---

## 8. Tag Features (Phase 4 Regression)

| # | Test | Expected | Result |
|---|------|----------|--------|
| 8.1 | Settings → Tags → Add Category | Dialog: Category name, English name, Icon, Color picker | |
| 8.2 | Create category → tags appear under it | Expandable section with tag count | |
| 8.3 | Add Entry → type "family" | "Suggested" section with Family tag + sparkle icon | |
| 8.4 | Tallies → Tags tab | Bar chart, co-occurrence pairs, timeline visible | |
| 8.5 | Notes → category filter chips | Filter entries by category | |

---

## 9. Localization (EN ↔ ZH)

| # | Test | Expected | Result |
|---|------|----------|--------|
| 9.1 | Settings → Language → switch to Chinese (中文) | All screens show Chinese text | |
| 9.2 | Verify key screens in Chinese: My Day, Tallies, Notes, Settings | No English text in Chinese mode (except proper nouns) | |
| 9.3 | Switch back to English | All screens return to English | |
| 9.4 | "Remove Ads" tile in Chinese | Shows "移除广告" with "¥3.99 一次性购买" or equivalent | |

---

## 10. Dark Mode

| # | Test | Expected | Result |
|---|------|----------|--------|
| 10.1 | Settings → Theme → Dark Mode | App switches to dark theme | |
| 10.2 | Navigate all 5 tabs in dark mode | All screens render correctly; no white artifacts | |
| 10.3 | Banner ad in dark mode | Banner renders with correct colors | |
| 10.4 | Return to Light mode | App switches back | |

---

## 11. Backup & Restore

| # | Test | Expected | Result |
|---|------|----------|--------|
| 11.1 | Settings → Full Backup (ZIP) | Progress indicator → share sheet | |
| 11.2 | Settings → Restore Data | File picker opens; confirmation dialog | |
| 11.3 | Cancel restore | Returns to settings | |

---

## 12. Edge Cases

| # | Test | Expected | Result |
|---|------|----------|--------|
| 12.1 | Airplane mode → launch app | App opens without crash; banner might not load (expected) | |
| 12.2 | Airplane mode → tap "Remove Ads" | Graceful error message (no crash) | |
| 12.3 | Kill app mid-purchase → relaunch | No crash; purchase state consistent | |
| 12.4 | Rapidly switch tabs | No crash or freeze | |

---

## Defect Summary

| # | Severity | Description | Flow | Platform |
|---|----------|-------------|------|----------|
| 1 | | | | |
| 2 | | | | |
| 3 | | | | |

---

## Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Tester | | | |
| Dev Review | | | |
| PM / Business | | | |

---

**Severity key:** P0 = crash/data loss (fix immediately) | P1 = feature broken (fix before release) | P2 = automation only | P3 = cosmetic (defer)
