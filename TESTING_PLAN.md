# Micro Habits — Testing Plan

> Last updated: May 29, 2026

## Build Verification (pre-UAT)

| # | Check | Command |
|---|-------|---------|
| B1 | Static analysis | `flutter analyze` → 0 errors in lib |
| B2 | Unit test compile | `flutter test` (test suite needs rebuild) |
| B3 | iPhone 17 Pro sim | `flutter run -d <iPhone ID>` |
| B4 | iPad Air 11" M4 sim | `flutter run -d <iPad ID>` |
| B5 | Android API 36 emu | `flutter run -d <Android ID>` |

---

## UAT Checklist — Per Device

### Navigation
| # | Test | Expected |
|---|------|----------|
| N1 | Bottom nav shows 4 tabs | My Day, Moments, Habits, Tallies |
| N2 | Tab switching works | Each tab loads without crash |
| N3 | Back-navigation works | Android back / iOS swipe returns to previous |

---

### My Day
| # | Test | Expected |
|---|------|----------|
| D1 | AppBar shows "Stalio: Do. Tally. Grow." | Title visible on today |
| D2 | Past date shows date suffix | e.g. "Stalio: Do. Tally. Grow. - May 28" |
| D3 | Welcome banner shows motto | "A thousand miles begins with a single step" |
| D4 | Calendar renders | Month grid with entry dots and habit badges |
| D5 | Tap past date | Entries and habits for that date shown |
| D6 | Tap + FAB | Opens Add Memory with note field, tags, mood, media |
| D7 | Add note with emotion | Save → emotion appears in emoji jar |
| D8 | Emoji jar renders | Glass jar with emoji grid, +N overflow badge |
| D9 | Mood jar title shows "My Mood Jar" | No duplicate date appended |
| D10 | Habit check-in section visible | Shows pending + completed habits |
| D11 | Tap habit checkbox | Toggles completion, updates jar |
| D12 | Tap edit icon (pencil) next to "Habit Check-in" | Opens Settings > Habit Build tab |
| D13 | Tap on entry card | Opens entry detail view |

---

### Moments
| # | Test | Expected |
|---|------|----------|
| M1 | Search bar filters notes | Typing filters list in real-time |
| M2 | Filter by tag | Tag filter chip shows filtered results |
| M3 | Clear search/filter | All notes shown |
| M4 | Tap note card | Opens edit screen |
| M5 | Edit note content/tags/mood | Changes save on back |
| M6 | Delete note | Note removed from list |

---

### Habits
| # | Test | Expected |
|---|------|----------|
| H1 | Summary cards at top | Total, Best Streak, Active with icons and counts |
| H2 | Today section shows date | Date header with today's day name |
| H3 | Pending habits show checkboxes | Tap to complete |
| H4 | Completed habits in green row | Check circle icon with emoji |
| H5 | Progress bar shows done/total | Updates on toggle |
| H6 | All done celebration message | Shows when all habits completed |
| H7 | Streak Matrix renders | Card with "Streak Matrix" header, habit rows with icons, day columns |
| H8 | Matrix starting date is correct | Starts from earliest completion, no empty future cells |
| H9 | Month labels on matrix | Month names at top of columns |
| H10 | Day labels at bottom | M/W/F labels |
| H11 | Legend shows Missed/Done colors | Grey/green dots with labels |

---

### Tallies (Insights)
| # | Test | Expected |
|---|------|----------|
| T1 | AppBar shows "Tallies" / "统计" | Title correct |
| T2 | Hero stats row | 4 stat cards with real data |
| T3 | Calendar heatmap | GitHub-style grid of colored cells |
| T4 | Writing stats | avg words, most active day, peak hour |
| T5 | Mood pie chart | Colored segments by emotion group |
| T6 | Scope picker | Day/Week/Month toggle works |
| T7 | Note count bar chart | Updates with scope |
| T8 | Habit completion bar chart | Per-habit green bars |
| T9 | Emotion trend line chart | Mood score over time |
| T10 | Top tags bar chart | Colored by tag |
| T11 | Checklist insights | 4 stat rows |
| T12 | Tag-mood correlation | 5 progress bars with mood scores |
| T13 | Yearly emoji jars | Horizontal scrollable jars per year |
| T14 | No AI/paywall popups | No "Pro required" messages |

---

### Settings — General Tab
| # | Test | Expected |
|---|------|----------|
| G1 | Voice toggle | Switch enables/disables voice reminders |
| G2 | Test voice button | Plays "Hello, this is a voice reminder test" |
| G3 | Language switcher | EN ↔ ZH toggles correctly |
| G4 | Backup (ZIP) placeholder | Shows "Backup coming soon" |
| G5 | Restore placeholder | Shows "Restore coming soon" |
| G6 | Version info | Shows "Micro Habits Version 1.0.0" |
| G7 | Terms & Privacy | Opens bottom sheet with Privacy/Terms tabs, scrollable legal text |

---

### Settings — Tags Tab
| # | Test | Expected |
|---|------|----------|
| TG1 | Default tags visible | 6 custom tags + 1 system tag (Private) |
| TG2 | Add new tag | Dialog with name, EN name, color picker works |
| TG3 | Edit existing tag | Changes save and reflect immediately |
| TG4 | Delete tag | Tag removed from list |
| TG5 | System tag locked | Private tag shows lock icon, cannot delete |
| TG6 | No AI/Welcome tags | tag_synthesis and tag_welcome not present |

---

### Settings — Habit Build Tab
| # | Test | Expected |
|---|------|----------|
| HB1 | Active habits listed | With category icons, frequency labels, descriptions |
| HB2 | Paused habits listed | Faded, best streak shown |
| HB3 | Active/paused toggle switch | Moves habit between sections |
| HB4 | Three-dot menu | Opens edit dialog (name, frequency, days, reminder, voice) |
| HB5 | "+ Add Habit" button | Opens Add Habit dialog with all fields |
| HB6 | New habit appears in Habits page | Immediately visible after add |

---

### Add Memory / Edit Memory
| # | Test | Expected |
|---|------|----------|
| AM1 | Note/List format toggle | SegmentedButton switches format |
| AM2 | Text field works | Typing content |
| AM3 | Tags section below text | FilterChips with colors, tap to select |
| AM4 | Edit tag icon (pencil) | Opens Settings > Tags tab |
| AM5 | Mood picker below tags | 10 emoji buttons, tap to select, label shown |
| AM6 | Media section (if media added) | Thumbnails with remove button |
| AM7 | Save button works | Entry appears in My Day and Moments |
| AM8 | No voice transcribe button | Mic icon removed |
| AM9 | No photo/camera buttons | Photo and Camera CTAs removed |
