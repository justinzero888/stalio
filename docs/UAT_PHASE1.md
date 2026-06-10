# Phase 1 UAT — Manual Validation Test Cases

**Phase:** 1 (Foundation & Branding)
**Date:** _________
**Tester:** _________
**Device:** _________
**OS Version:** _________

---

## Test Environment

| Item | Requirement |
|---|---|
| Build | Debug or release APK/IPA from Phase 1 branch |
| State | Clean install (no prior data). Install → open → run tests. |
| Device | One Android (mid-range) + One iOS (if available) |

---

## 1. App Identity & Branding

| # | Test Case | Steps | Expected Result | Pass/Fail |
|---|---|---|---|---|
| 1.1 | App icon shows navy + gold | View app icon on device home screen / app drawer | Icon background is navy (#1A2533), no green visible | [ ] |
| 1.2 | App name is "Stalio" (iOS) | Fresh install on iOS, view home screen label | "Stalio" shows under icon (not "Blinking" or "Micro Habits") | [ ] |
| 1.3 | App name is "Stalio" (Android) | Fresh install on Android, view app drawer label | "Stalio" shows as app name | [ ] |
| 1.4 | Launch screen is navy (iOS) | Cold launch the app on iOS | Launch screen background is navy (#1A2533), not white or green | [ ] |
| 1.5 | No "Blinking" branding anywhere | Navigate all screens, open all menus | Zero visible "Blinking" or "记忆闪烁" text | [ ] |

---

## 2. Color Theme — Light Mode

| # | Test Case | Steps | Expected Result | Pass/Fail |
|---|---|---|---|---|
| 2.1 | Bottom nav uses navy | View bottom navigation bar | Selected tab icon/text is navy (#1A2533) | [ ] |
| 2.2 | Center + button is navy square with gold plus | View the center button in bottom nav | Square background is navy, plus icon is gold (#FFD700) | [ ] |
| 2.3 | App bar is white with navy text | View any screen with app bar | Background white, title text dark navy, no green tint | [ ] |
| 2.4 | Cards are white with rounded corners | View My Day | Cards have white background, 12px radius, no green tint | [ ] |
| 2.5 | Scaffold background is warm off-white | View any list screen (My Day, Notes) | Background is warm light (#F5F3EF range), NOT green-tinted | [ ] |
| 2.6 | Chips use navy when selected | Settings → Tags → edit a tag → color picker | Selected chip option shows in navy, not teal/green | [ ] |
| 2.7 | No green/teal anywhere in light mode | Systematic scan of all 5 tabs | No #0D3B34, #2A9D8F, emerald, or teal-green hues visible | [ ] |

---

## 3. Color Theme — Dark Mode

| # | Test Case | Steps | Expected Result | Pass/Fail |
|---|---|---|---|---|
| 3.1 | Switch to dark mode | Settings → toggle dark mode ON | App switches to dark theme immediately | [ ] |
| 3.2 | Dark scaffold background | View any screen in dark mode | Background is dark (#0D0D0D range), not pure black | [ ] |
| 3.3 | Dark cards visible | View My Day in dark mode | Cards have dark background (#1E1E1E range), content readable | [ ] |
| 3.4 | Gold accents visible on dark | View bottom nav, any screen | Gold (#FFD700) accents are clearly visible, not washed out | [ ] |
| 3.5 | Text readable on dark | Read any entry or setting text | Text has sufficient contrast, not dim or invisible | [ ] |
| 3.6 | Dark mode persists across restart | Close app fully → reopen | Dark mode is still active after restart | [ ] |
| 3.7 | Switch back to light mode | Settings → toggle dark mode OFF | App returns to light theme correctly | [ ] |

---

## 4. Navigation — Bottom Nav

| # | Test Case | Steps | Expected Result | Pass/Fail |
|---|---|---|---|---|
| 4.1 | My Day tab active on launch | Fresh install → open app | "My Day" tab is selected, shows habit checklist + streak matrix | [ ] |
| 4.2 | Switch to Tallies | Tap "Tallies" in bottom nav | Tallies screen shows (3 tabs: Habits, Notes, Moods) | [ ] |
| 4.3 | Switch to Notes | Tap "Notes" in bottom nav | Notes screen shows (entry list) | [ ] |
| 4.4 | Switch to Settings | Tap "Settings" in bottom nav | Settings screen shows with 3 tabs (General, Tags, Habit Build) | [ ] |
| 4.5 | Center + opens add entry | Tap center + button | Add Entry screen opens with full form | [ ] |
| 4.6 | Back from add entry | From Add Entry, press back | Returns to previously selected tab (not always My Day) | [ ] |
| 4.7 | Rapid tab switching no crash | Tap all 5 tabs quickly in sequence | No crash, no freeze, UI remains responsive | [ ] |

---

## 5. Settings — General Tab

| # | Test Case | Steps | Expected Result | Pass/Fail |
|---|---|---|---|---|
| 5.1 | Voice reminders toggle | Settings → General → toggle voice | Toggle switches state, no crash | [ ] |
| 5.2 | Language toggle | Settings → General → language row | Shows English selected by default. Tap to switch to 中文, app translates | [ ] |
| 5.3 | Privacy Policy opens | Settings → General → Privacy Policy | Opens legal text. Scroll through — content references "Stalio" only | [ ] |
| 5.4 | Terms of Service opens | Settings → General → Terms of Service | Opens legal text. Scroll through — content references "Stalio" only | [ ] |
| 5.5 | About shows Stalio | Settings → General → scroll to "About" | Shows "Stalio" with "Version 1.0.0" | [ ] |
| 5.6 | No "Blinking" in any settings label | Scan all settings text | Zero instances of "Blinking" in settings UI | [ ] |

---

## 6. Legal Content — Full Text Audit

| # | Test Case | Steps | Expected Result | Pass/Fail |
|---|---|---|---|---|
| 6.1 | Privacy Policy — English header | Settings → Privacy Policy | Title: "Privacy Policy — Stalio" (not Blinking) | [ ] |
| 6.2 | Privacy Policy — no AI section | Scroll through Privacy Policy | No "AI Assistant", "LLM", "OpenAI", or "Pro subscription" text | [ ] |
| 6.3 | Privacy Policy — no Chorus | Scroll through Privacy Policy | No "Chorus" or "social sharing" references | [ ] |
| 6.4 | Privacy Policy — no IAP | Scroll through Privacy Policy | No "subscription", "in-app purchase", or "trial" text | [ ] |
| 6.5 | Privacy Policy — data on-device | Scroll through Privacy Policy | States "All data stays on your device", "no accounts required" | [ ] |
| 6.6 | Terms of Service — English header | Settings → Terms of Service | Title: "Terms of Service — Stalio" (not Blinking) | [ ] |
| 6.7 | Terms of Service — no AI section | Scroll through Terms | No "AI Assistant" clause | [ ] |
| 6.8 | Terms of Service — section count | Count sections in Terms | 10 sections (1-10), no gaps, no AI section, no Third-Party Services | [ ] |
| 6.9 | Switch to Chinese (中文) | Settings → switch language to 中文 | All legal content renders in Chinese | [ ] |
| 6.10 | Privacy Policy — Chinese header | Repeat 6.1-6.5 in Chinese mode | Title: "隐私政策 — Stalio" (not "记忆闪烁") | [ ] |
| 6.11 | Terms of Service — Chinese header | Repeat 6.6-6.8 in Chinese mode | Title: "服务条款 — Stalio" (not "记忆闪烁") | [ ] |

---

## 7. Settings — Tags Tab

| # | Test Case | Steps | Expected Result | Pass/Fail |
|---|---|---|---|---|
| 7.1 | Tags tab shows default tags | Settings → Tags tab | Default tags visible (Family, Insight, Gratitude, etc.) with colored dots | [ ] |
| 7.2 | Add new tag flow | Tags → + button → enter name → pick color → save | New tag appears in list | [ ] |
| 7.3 | Edit existing tag | Tags → tap custom tag → edit name/color → save | Tag updates correctly | [ ] |
| 7.4 | Delete tag | Tags → long-press or swipe to delete custom tag | Tag removed from list | [ ] |
| 7.5 | System tags are locked | Tags → view system tags | System tags show lock icon, cannot be edited or deleted | [ ] |

---

## 8. Settings — Habit Build Tab

| # | Test Case | Steps | Expected Result | Pass/Fail |
|---|---|---|---|---|
| 8.1 | Habits tab shows default habits | Settings → Habit Build tab | 31 default habits listed, 3 marked active | [ ] |
| 8.2 | Toggle habit active/inactive | Habit Build → tap habit toggle | Habit switches active/inactive | [ ] |
| 8.3 | Add new habit | Habit Build → + → fill form → save | New habit appears in list | [ ] |

---

## 9. My Day Screen

| # | Test Case | Steps | Expected Result | Pass/Fail |
|---|---|---|---|---|
| 9.1 | Today checklist renders | Navigate to My Day | Active habits shown as checklist items | [ ] |
| 9.2 | Complete a habit | Tap checkbox on a habit | Checkmark appears, habit moves to "done" section | [ ] |
| 9.3 | Streak matrix visible | Scroll down on My Day | Habit streak heatmap matrix visible below checklist | [ ] |
| 9.4 | Streak cells use navy/gold (not teal) | Inspect streak matrix colors | Completed cells are navy/gold, not green/teal | [ ] |

---

## 10. Emoji Jar

| # | Test Case | Steps | Expected Result | Pass/Fail |
|---|---|---|---|---|
| 10.1 | Emoji jar accessible | Navigate to My Day → find emoji jar entry card | Emoji jar card visible with emoji count | [ ] |
| 10.2 | Jar glass is navy-tinted | Tap emoji jar card to open jar | Glass mason jar rendered with navy tint (not green/teal) | [ ] |
| 10.3 | Jar label shows emoji count | View jar label | Label shows emoji count (not note count) | [ ] |

---

## 11. Seed Data

| # | Test Case | Steps | Expected Result | Pass/Fail |
|---|---|---|---|---|
| 11.1 | 8 seed entries on first launch | Fresh install → My Day | ~8 sample entries visible with tags and emotions | [ ] |
| 11.2 | No duplicate entries on second launch | Close app → reopen | Same 8 entries, no duplicates created | [ ] |
| 11.3 | Default tags present | Settings → Tags | 7 default tags visible | [ ] |

---

## Summary

| Section | Tests | Passed | Failed | Notes |
|---|---|---|---|---|
| 1. App Identity & Branding | 5 | | | |
| 2. Color Theme — Light Mode | 7 | | | |
| 3. Color Theme — Dark Mode | 7 | | | |
| 4. Navigation | 7 | | | |
| 5. Settings — General | 6 | | | |
| 6. Legal Content Audit | 11 | | | |
| 7. Settings — Tags | 5 | | | |
| 8. Settings — Habits | 3 | | | |
| 9. My Day | 4 | | | |
| 10. Emoji Jar | 3 | | | |
| 11. Seed Data | 3 | | | |
| **Total** | **61** | | | |

---

## Sign-off

| Role | Name | Signature | Date |
|---|---|---|---|
| Tester | _________ | _________ | _________ |
| PM Review | _________ | _________ | _________ |

**All tests must pass with zero failures before Phase 1 sign-off.**
