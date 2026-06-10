# Stalio — Manual UAT Checklist (Phase 4)

> **Date:** June 10, 2026  
> **Tester:** ___________  
> **Platform:** ___________ (real device only, per dev-cycle-playbook §3.2)  
> **Build:** ___________  
> **Result:** ✅ Pass / ❌ Fail (file defect per dev-test-collaboration §2)

---

## Pre-Check

- [ ] App installed on device (not simulator)
- [ ] Fresh install (or cleared data) for category/export tests
- [ ] Seed data visible (default tags, demo entries)

---

## 1. Tag Categories (Settings → Tags)

| # | Test | Expected | Result |
|---|------|----------|--------|
| 1.1 | Navigate Settings → Tags | Tags tab shows "Uncategorized" section with default tags | |
| 1.2 | Tap "Add Category" | Dialog opens with Category name, English name, Icon, Color picker | |
| 1.3 | Create category "Health" (💚, green) | Category appears as expandable header | |
| 1.4 | Create category "Work" (💼, blue) | Second category appears below Health | |
| 1.5 | Tap category header to collapse | Tags hidden, arrow flips to expand | |
| 1.6 | Tap category header to expand | Tags shown again | |
| 1.7 | Edit category (change name, color, icon) | Changes reflect immediately | |
| 1.8 | Delete category | Confirmation dialog shows; tags become uncategorized | |

---

## 2. Tag CRUD with Categories

| # | Test | Expected | Result |
|---|------|----------|--------|
| 2.1 | Tap "Add Tag" | Dialog shows name fields + Category dropdown | |
| 2.2 | Create tag "Running" under "Health" category | Tag appears indented under Health header | |
| 2.3 | Create tag "Meeting" under "Work" category | Tag appears under Work header | |
| 2.4 | Edit tag — change category | Tag moves to new category section | |
| 2.5 | Edit tag — remove category (set to uncategorized) | Tag moves to Uncategorized section | |
| 2.6 | Delete tag | Tag removed from list | |

---

## 3. Bulk Tag Operations

| # | Test | Expected | Result |
|---|------|----------|--------|
| 3.1 | Long-press on a tag | Selection mode enters; checkboxes appear; action chips at bottom | |
| 3.2 | Tap additional tags | Multiple tags selected; count updates | |
| 3.3 | Tap "Select All" on category header | All tags in that category selected | |
| 3.4 | Tap "Assign Category" → pick category | Selected tags move to chosen category | |
| 3.5 | Select 2+ tags → tap "Merge" | Dialog shows radio list; pick target; source tags merge | |
| 3.6 | Select tags → tap "Recolor" → pick color | All selected tags change color | |
| 3.7 | Tap "Cancel" in selection bar | Exits selection mode; checkboxes hidden | |

---

## 4. Tag Auto-Suggest (Add Entry)

| # | Test | Expected | Result |
|---|------|----------|--------|
| 4.1 | Open Add Entry (+ button) | Entry form opens with text field and tag section | |
| 4.2 | Type "family" in content | "Suggested" section appears with Family tag + sparkle icon | |
| 4.3 | Type "学习" (learning) | "建议标签" (ZH) or "Suggested" (EN) section appears with Learning tag | |
| 4.4 | Tap suggested tag | Tag added to selection; removed from suggestions | |
| 4.5 | Type random text "xyzfoo" | No suggested section appears | |
| 4.6 | Clear text → retype keyword | Suggestions re-appear dynamically | |

---

## 5. Tag Analytics (Tallies → Tags)

| # | Test | Expected | Result |
|---|------|----------|--------|
| 5.1 | Navigate to Tallies | Tallies screen with Habits tab visible | |
| 5.2 | Tap "Tags" tab | Fourth tab visible; analytics content renders | |
| 5.3 | Verify Top Tags bar chart | Horizontal bar chart with tag names and counts | |
| 5.4 | Verify Co-occurrence section | Pairs of tags with sync icon and count below chart | |
| 5.5 | Verify Usage Timeline section | Line chart at bottom | |
| 5.6 | Tap "Habits" → "Notes" → "Moods" → "Tags" | All 4 tabs switch without crash | |

---

## 6. Category Filter Chips (Moments)

| # | Test | Expected | Result |
|---|------|----------|--------|
| 6.1 | Navigate to Moments (Notes) | Entry list visible with date filter chips | |
| 6.2 | Verify category filter row visible | Second row of chips below date filters: "All", category names | |
| 6.3 | Tap a category chip | Entry list filters to only entries with tags in that category | |
| 6.4 | Tap "All" in category row | All entries shown again | |
| 6.5 | Verify date filter still works with category filter | Both filters combine correctly | |

---

## 7. Notes Share (Moments → Multi-Select)

| # | Test | Expected | Result |
|---|------|----------|--------|
| 7.1 | Long-press on an entry card | Selection mode: checkboxes appear; app bar shows count + share/close | |
| 7.2 | Select 2+ entries | Count updates; share icon active | |
| 7.3 | Tap share icon | Format preview dialog opens with Plain/Markdown/Rich tabs | |
| 7.4 | Switch to Markdown format | Preview updates to markdown (# headers, --- separators) | |
| 7.5 | Switch to Rich format | Preview updates to box-drawing border format | |
| 7.6 | Tap "Copy" icon | Content copied to clipboard; snackbar confirms | |
| 7.7 | Tap "Share" button | System share sheet opens with formatted content | |
| 7.8 | Tap "Save as file" | File saved and share sheet opens with file | |
| 7.9 | Tap "Cancel" | Returns to selection mode | |
| 7.10 | Tap close (X) in app bar | Exits selection mode; normal view restored | |
| 7.11 | Deselect all entries (tap each) | Automatically exits selection mode | |

---

## 8. Export CSV (Settings → General)

| # | Test | Expected | Result |
|---|------|----------|--------|
| 8.1 | Navigate Settings → General | "Export CSV" tile visible between Backup and Restore | |
| 8.2 | Tap "Export CSV" | Date range picker: All time, Last 30/90 days, Custom | |
| 8.3 | Select "Last 30 days" | Progress indicator → system share sheet with CSV ZIP | |
| 8.4 | Select "All time" | Progress indicator → system share sheet with CSV ZIP | |
| 8.5 | Tap "Cancel" in date picker | Returns to settings | |

---

## 9. Export PDF (Settings → General)

| # | Test | Expected | Result |
|---|------|----------|--------|
| 9.1 | Navigate Settings → General | "Export PDF" tile visible | |
| 9.2 | Tap "Export PDF" | Date range picker: All time, Last 30/90 days, Custom | |
| 9.3 | Select "All time" | Progress indicator → system share sheet with PDF | |
| 9.4 | Open shared PDF | Title page renders with "Stalio — Journal Export" | |
| 9.5 | Verify entry content in PDF | Entry dates, content, moods visible | |
| 9.6 | Verify summary page | Total entries, active days, streak, top moods | |

---

## 10. Regression — Core Screens

| # | Test | Expected | Result |
|---|------|----------|--------|
| 10.1 | My Day loads | Bottom nav visible; calendar widget renders | |
| 10.2 | Tallies → Habits, Notes, Moods | All tabs render correctly | |
| 10.3 | Moments → entry list scrolls | All entries visible; tap opens detail | |
| 10.4 | Settings → Voice toggle works | Toggle persists across tab switches | |
| 10.5 | Settings → Theme toggle | Light/Dark/System switch works | |
| 10.6 | Settings → Language toggle | EN ↔ ZH switches all screens | |
| 10.7 | Settings → About | Shows "Stalio", version 1.0.0 | |

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
