# Stalio — UAT Checklist: Phase 3

> **Target version:** 1.0.0+1 (dev)  
> **Scope:** L10n language switch (EN ↔ ZH), Dark Mode toggle, Branding cleanup  
> **Date:** June 9, 2026  
> **Tester:** _____________  
> **Devices:** iPhone 17 Pro / iPad Air 11" M4 / Android API 36  

---

## Pre-UAT Build Verification

| # | Check | Expected | Pass? |
|---|-------|----------|-------|
| B1 | `flutter analyze lib/` | 0 errors, 0 warnings | [ ] |
| B2 | `flutter test` | 253 tests pass, exit 0 | [ ] |
| B3 | App launches on iPhone 17 Pro | No crash, My Day visible | [ ] |
| B4 | App launches on iPad Air 11" M4 | No crash, My Day visible | [ ] |
| B5 | App launches on Android API 36 | No crash, My Day visible | [ ] |

---

## Section A — Language & L10n (Item 6)

### A1: Settings → Language Picker

| # | Test | Expected | EN | ZH | Droid |
|---|------|----------|----|----|-------|
| A1.1 | Settings → General → Language visible | Shows current language (English / 中文) | [ ] | [ ] | [ ] |
| A1.2 | Tap Language row | Dialog opens with English + 中文 | [ ] | [ ] | [ ] |
| A1.3 | Select 中文 | UI switches to Chinese immediately | [ ] | [ ] | [ ] |
| A1.4 | Select English | UI switches back to English immediately | [ ] | [ ] | [ ] |

### A2: My Day — Bilingual Labels

| # | Test | Expected | EN | ZH | Droid |
|---|------|----------|----|----|-------|
| A2.1 | AppBar title | English: `Stalio: Do. Tally. Grow.`, Chinese: `Stalio:行.积.成.` | [ ] | [ ] | [ ] |
| A2.2 | Past date title | English: `Stalio: Do. Tally. Grow. - Jun 8`, Chinese: `Stalio:行.积.成. - 6月8日` | [ ] | [ ] | [ ] |
| A2.3 | Habit Check-in section | English: `Habit Check-in`, Chinese: `习惯打卡` | [ ] | [ ] | [ ] |
| A2.4 | Edit habits tooltip | English: `Edit Habits`, Chinese: `编辑习惯` | [ ] | [ ] | [ ] |
| A2.5 | Lists section | English: `📋 Lists`, Chinese: `📋 今日清单` | [ ] | [ ] | [ ] |
| A2.6 | Notes section | English: `📝 Notes`, Chinese: `📝 笔记` | [ ] | [ ] | [ ] |
| A2.7 | Emoji jar title | English: `My Mood Jar`, Chinese: `情绪罐` | [ ] | [ ] | [ ] |
| A2.8 | Empty state (today) | English: `No entries today` + `Tap + to add an entry`, Chinese: `今天还没有记录` + `点击 + 添加记录` | [ ] | [ ] | [ ] |
| A2.9 | Empty state (past) | English: `No entries on this day`, Chinese: `当天没有记录` | [ ] | [ ] | [ ] |
| A2.10 | Welcome banner | English: `A thousand miles begins with a single step.`, Chinese: `千里之行，始于足下。` | [ ] | [ ] | [ ] |

### A3: Tallies (Insights) — Bilingual Labels

| # | Test | Expected | EN | ZH | Droid |
|---|------|----------|----|----|-------|
| A3.1 | Summary cards | English: `Total` / `Best Streak` / `Active`, Chinese: `总计` / `最佳连续` / `活跃` | [ ] | [ ] | [ ] |
| A3.2 | Streak Matrix header | English: `Streak Matrix`, Chinese: `坚持矩阵` | [ ] | [ ] | [ ] |
| A3.3 | Legend labels | English: `Missed` / `Done`, Chinese: `未完成` / `已完成` | [ ] | [ ] | [ ] |
| A3.4 | All habits done | English: `All habits completed for today!`, Chinese: `今日全部习惯已完成！` | [ ] | [ ] | [ ] |
| A3.5 | Empty state | English: `No habits yet`, Chinese: `暂无习惯` | [ ] | [ ] | [ ] |
| A3.6 | Pending section | English: `Not Completed`, Chinese: `未完成` | [ ] | [ ] | [ ] |
| A3.7 | Done section | English: `Completed`, Chinese: `已完成` | [ ] | [ ] | [ ] |

### A4: Notes (Moments) — Bilingual Labels

| # | Test | Expected | EN | ZH | Droid |
|---|------|----------|----|----|-------|
| A4.1 | AppBar title | English: `Moments`, Chinese: `瞬间` | [ ] | [ ] | [ ] |
| A4.2 | Search hint | English: `Search entries...`, Chinese: `搜索记录...` | [ ] | [ ] | [ ] |
| A4.3 | Filter chips | English: `All` / `Today` / `This Week` / `Tags`, Chinese: `全部` / `今天` / `本周` / `标签` | [ ] | [ ] | [ ] |
| A4.4 | Delete dialog | English: `Delete Entry` / `Delete this entry?` / `Cancel` / `Delete`, Chinese: `删除记录` / `确定要删除这条记录吗？` / `取消` / `删除` | [ ] | [ ] | [ ] |
| A4.5 | Empty state | English: `No entries yet\nTap + to add one`, Chinese: `暂无记录\n点击 + 添加第一条` | [ ] | [ ] | [ ] |
| A4.6 | No tags warning | English: `No tags yet. Add tags in Settings first.`, Chinese: `暂无标签，请先在设置中添加标签` | [ ] | [ ] | [ ] |

### A5: Add Memory — Bilingual Labels

| # | Test | Expected | EN | ZH | Droid |
|---|------|----------|----|----|-------|
| A5.1 | AppBar title (new) | English: `Add Memory`, Chinese: `添加记录` | [ ] | [ ] | [ ] |
| A5.2 | AppBar title (edit) | English: `Edit Memory`, Chinese: `编辑记录` | [ ] | [ ] | [ ] |
| A5.3 | AppBar title (past) | English: `View Memory`, Chinese: `查看记录` | [ ] | [ ] | [ ] |
| A5.4 | Format toggle | English: `Note` / `List`, Chinese: `笔记` / `清单` | [ ] | [ ] | [ ] |
| A5.5 | Note hint | English: `What's on your mind?`, Chinese: `今天有什么想记录的？` | [ ] | [ ] | [ ] |
| A5.6 | Mood section | English: `Mood`, Chinese: `心情` | [ ] | [ ] | [ ] |
| A5.7 | Tags section | English: `Tags`, Chinese: `标签` | [ ] | [ ] | [ ] |
| A5.8 | Save success | English: `Memory saved!` / `Memory updated!`, Chinese: `记录已保存！` / `记录已更新！` | [ ] | [ ] | [ ] |
| A5.9 | Content required | English: `Please add some content`, Chinese: `请添加一些内容` | [ ] | [ ] | [ ] |

### A6: Settings — Bilingual Labels

| # | Test | Expected | EN | ZH | Droid |
|---|------|----------|----|----|-------|
| A6.1 | AppBar title | English: `Settings`, Chinese: `设置` | [ ] | [ ] | [ ] |
| A6.2 | Tab bar | English: `General` / `Tags` / `Habit Build`, Chinese: `通用` / `标签` / `习惯建设` | [ ] | [ ] | [ ] |
| A6.3 | Voice reminder label | English: `Voice Reminder`, Chinese: `语音提醒` | [ ] | [ ] | [ ] |
| A6.4 | Language row | Shows current language in native name | [ ] | [ ] | [ ] |
| A6.5 | Backup section | English: `Backup Data` / `Full Backup (ZIP)` / `Restore Data`, Chinese: `备份数据` / `完整备份（ZIP）` / `恢复数据` | [ ] | [ ] | [ ] |
| A6.6 | About section | Shows `Stalio` + `Version 1.0.0` in both locales | [ ] | [ ] | [ ] |
| A6.7 | Legal section | English: `Terms & Privacy`, Chinese: `条款与隐私` | [ ] | [ ] | [ ] |
| A6.8 | Tags tab | `Add Tag` button label changes with locale | [ ] | [ ] | [ ] |
| A6.9 | Habit Build tab | `Add Habit` / `Active` / `Paused` change with locale | [ ] | [ ] | [ ] |

### A7: Routine Dialog (Habit Add/Edit) — Bilingual Labels

| # | Test | Expected | EN | ZH | Droid |
|---|------|----------|----|----|-------|
| A7.1 | Dialog title (new) | English: `Add Routine`, Chinese: `添加日常` | [ ] | [ ] | [ ] |
| A7.2 | Dialog title (edit) | English: `Edit Routine`, Chinese: `编辑日常` | [ ] | [ ] | [ ] |
| A7.3 | Actions | English: `Cancel` / `Add` or `Save`, Chinese: `取消` / `添加` or `保存` | [ ] | [ ] | [ ] |

---

## Section B — Dark Mode (Item 7)

### B1: Theme Toggle

| # | Test | Expected | EN | ZH | Droid |
|---|------|----------|----|----|-------|
| B1.1 | Settings → Theme visible | Shows "Theme" row with current mode label | [ ] | [ ] | [ ] |
| B1.2 | Tap Theme row | Dialog with Light Mode / Dark Mode / System | [ ] | [ ] | [ ] |
| B1.3 | Select Dark Mode | Screen switches to dark backgrounds, gold accents visible | [ ] | [ ] | [ ] |
| B1.4 | Select Light Mode | Screen switches back to light warm-white backgrounds | [ ] | [ ] | [ ] |
| B1.5 | Select System | Follows device appearance setting | [ ] | [ ] | [ ] |

### B2: Dark Mode Visual QA — All Screens

| # | Screen | Check | Pass? |
|---|--------|-------|-------|
| B2.1 | My Day | Dark background, navy calendar, gold habit check icons, readable text | [ ] |
| B2.2 | Tallies (Habits tab) | Dark cards, gold progress bars, readable stats, streak matrix cells with gold | [ ] |
| B2.3 | Tallies (Notes tab) | Dark charts, readable axis labels, gold accent markers | [ ] |
| B2.4 | Tallies (Moods tab) | Dark emoji jar container, gold jar rim, readable emotion emojis | [ ] |
| B2.5 | Notes | Dark background, readable search bar, filter chips with navy/gold, dark entry cards | [ ] |
| B2.6 | Add Memory | Dark form fields, visible text, gold mood picker selection, navy note/list toggle | [ ] |
| B2.7 | Settings | Dark tabs, readable toggles, visible gold switches, dark dialogs | [ ] |
| B2.8 | Entry Detail (read-only past) | Dark background, readable text, visible emotion/tags | [ ] |

### B3: Dark Mode Edge Cases

| # | Test | Expected | Pass? |
|---|------|----------|-------|
| B3.1 | Start in dark → add habit → edit → delete | All dialogs render in dark mode, no white flash | [ ] |
| B3.2 | Dark mode → switch language | Language changes while staying in dark mode | [ ] |
| B3.3 | Dark mode → app restart | Dark mode persists after app restart | [ ] |
| B3.4 | Dark mode → backup | Backup dialog renders in dark mode | [ ] |
| B3.5 | Dark mode → legal sheet | Terms & Privacy bottom sheet renders in dark mode | [ ] |
| B3.6 | System mode → device dark toggle | App switches to dark/light following system preference | [ ] |

---

## Section C — Branding Cleanup

| # | Test | Expected | Pass? |
|---|------|----------|-------|
| C1 | App name on home screen | Shows "Stalio" not "Blinking" or "Micro Habits" | [ ] |
| C2 | Settings → About | Shows "Stalio", Version 1.0.0 | [ ] |
| C3 | Legal content (Privacy) | No "Blinking", "AI", "Pro", "Chorus", or "记忆闪烁" in English version | [ ] |
| C4 | Legal content (Terms) | No "Blinking", "AI", "Pro", "Chorus", or "记忆闪烁" in English version | [ ] |
| C5 | Share from entry detail | Subject says "From Stalio" not "From Blinking" | [ ] |
| C6 | Backup share | Text says "Stalio data backup" not "Blinking data backup" | [ ] |
| C7 | App icon | Navy background with gold tally mark (not green/teal) | [ ] |
| C8 | No green remnants | No emerald (#2A9D8F) or teal colors anywhere in the app | [ ] |

---

## Section D — Regression

| # | Test | Expected | Pass? |
|---|------|----------|-------|
| D1 | My Day → calendar navigation | Tap dates, month nav works, today button works | [ ] |
| D2 | My Day → habit check-in | Toggle habits, checkboxes work, icons update | [ ] |
| D3 | My Day → carry forward | Previous day's unfinished list items should prompt carry-forward dialog | [ ] |
| D4 | Add Entry → create note | Save with content, appears in My Day + Notes | [ ] |
| D5 | Add Entry → create list | Add items, save, appears with checkboxes | [ ] |
| D6 | Add Entry → mood picker | Tap emoji, mood label shows, saves, appears in emoji jar | [ ] |
| D7 | Add Entry → tag picker | Tap tags, filter works in Notes tab | [ ] |
| D8 | Notes → search | Type text, list filters in real-time | [ ] |
| D9 | Notes → filter by tag | Tag chip filters entry list | [ ] |
| D10 | Notes → delete entry | Long press, confirm, entry removed | [ ] |
| D11 | Tallies → charts render | All charts load without errors, scope picker works | [ ] |
| D12 | Tallies → emoji jars | Yearly emoji jars scroll, mood counts correct | [ ] |
| D13 | Settings → Tags | Add, edit, delete tags. System tag locked | [ ] |
| D14 | Settings → Habit Build | Add, edit, toggle active/paused habits | [ ] |
| D15 | Settings → Voice toggle | Enable/disable, test voice plays sound | [ ] |
| D16 | Backup → ZIP export | Share sheet opens (may show error if no share service, but no crash) | [ ] |
| D17 | Restore → confirmation | Dialog opens with Cancel/Confirm, no crash | [ ] |

---

## Summary

| Section | Items | Passed | Failed | Notes |
|---------|-------|--------|--------|-------|
| A: L10n Labels | 43 | | | |
| B: Dark Mode | 14 | | | |
| C: Branding Cleanup | 8 | | | |
| D: Regression | 17 | | | |
| **Total** | **82** | | | |

---

**Tester signature:** _____________  
**Date:** _____________  
**Overall verdict:** [ ] APPROVED / [ ] REJECTED  

**Issues found:**  
________________________________  
________________________________  
________________________________
