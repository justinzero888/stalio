# Stalio — Phase 7: Simplify User Interface — Design & Implementation Plan

> **Date:** June 14, 2026  
> **Pre-requisite:** Phase 6 UAT sign-off  
> **Est. Effort:** 7–9 days  
> **Revised:** June 14, 2026 — 3-tab architecture per business decision

---

## 0. Architecture

### Target (3 tabs)

```
[ Daily ]  [ Tallies ]  [ Settings ]

Daily     = Calendar + Habit Checklist (tap habit → note input)
Tallies   = Sub-tabs: [ Progress ] [ Journal ]
              Progress = Habit completion charts, streaks, tag analytics
              Journal  = Search, browse, filter, share habit-generated notes
Settings  = Same as before (General, Tags, Habit Build)
```

**Key principle:** Notes are NOT separate from habits. Every note is created by completing a habit. The Journal is a browseable view of all habit-generated notes.

### Current (5 tabs) → Target (3 tabs)

```
Before: [ My Day ] [ Tallies ] [ + ] [ Notes ] [ Settings ]
  ↓
After:  [ Daily ]  [ Tallies ]  [ Settings ]
```

"What happened to Notes?" → Moved under Tallies as the "Journal" sub-tab.
"What happened to +?" → Removed. Notes are created by tapping habits, not a standalone button.

---

## Sub-Tab Naming

Tallies has 2 sub-tabs. Options for names:

| Option | Tab 1 | Tab 2 | Rationale |
|--------|-------|-------|-----------|
| **A (Recommended)** | **Progress** | **Journal** | Progress = tracking/metrics, Journal = personal record |
| B | Habits | Notes | Familiar, but "Notes" is too generic |
| C | Insights | Entries | Insights = charts, Entries = content |

**Recommendation: Option A — Progress & Journal.** Clear semantic distinction. "Progress" is about measurement; "Journal" is about reflection. No overlap with the main "Tallies" tab name.

---

## Item 28: 5-Tab → 3-Tab Navigation

### Changes

**File:** `lib/app.dart`

```dart
// OLD: 5 tabs (index 2 = "+" CTA)
static const _navToScreen = <int?>[0, 1, null, 2, 3];
_screens = [HomeScreen(), InsightsScreen(), MomentScreen(), SettingsScreen()];

// NEW: 3 tabs
static const _navToScreen = <int?>[0, 1, 2];
_screens = [HomeScreen(), InsightsScreen(), SettingsScreen()];

// Items
items: [
  BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Daily'),
  BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Tallies'),
  BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
]
```

Remove `_onTabTapped` "+" special case entirely.  
Remove `AddEntryScreen` import.  
Remove `MomentScreen` from screens list (moved into Tallies).

### Tallies Tab — New Sub-Tab Structure

**File:** `lib/screens/cherished/cherished_memory_screen.dart`

```dart
// OLD: 4 sub-tabs (Habits, Notes, Moods, Tags)
// NEW: 2 sub-tabs (Progress, Journal)
_InsightsContentState:
  DefaultTabController(length: 2, ...)
  TabBar(tabs: [
    Tab(text: isZh ? '进步' : 'Progress'),
    Tab(text: isZh ? '日记' : 'Journal'),
  ])
  TabBarView(children: [
    ProgressTab(summary: summary, isZh: isZh),
    JournalTab(),
  ])
```

**New file:** `lib/screens/cherished/tallies/progress_tab.dart`

```dart
class ProgressTab extends StatelessWidget {
  // Contains: RoutineCompletionChart, StreakMatrixSection, TopTagsChart
  // (the chart-heavy content from old Habits + Tags tabs)
}
```

**Modified:** `lib/screens/moment/moment_screen.dart` → imported into Tallies as Journal tab

```dart
// MomentScreen (entry list + search + filter + share) becomes JournalTab
// Imported directly into cherished_memory_screen.dart's TabBarView
```

### Acceptance Criteria
- [ ] 3 main tabs: Daily, Tallies, Settings
- [ ] Tallies has 2 sub-tabs: Progress, Journal
- [ ] "+" tab removed from nav bar
- [ ] "My Day" → "Daily" in navigation, AppBar, l10n
- [ ] MomentScreen still functions identically (just accessed from different tab)
- [ ] 323 tests updated for navigation changes

---

## Item 29: Habit Tap → Note Input

### Design Intent

Tapping any habit on Daily opens a note dialog. Two modes:

| Habit Type | Behavior |
|------------|----------|
| **Writing habit** (Write a note, Gratitude, Reflection) | Text input — MUST write to check off. "Save & Done" disabled until text entered. |
| **Action habit** (Walk 5000 steps, Drink water, Read) | Optional note. Checkmark works immediately. "Add detail" for optional note. |

### New Widget

**File:** `lib/widgets/routine_note_dialog.dart` (new)

```dart
class RoutineNoteDialog extends StatefulWidget {
  final Routine routine;
  final bool isZh;
  // Writing habits identified by category: reflection, mindfulness
  bool get isWritingHabit => 
    routine.category == RoutineCategory.reflection ||
    routine.category == RoutineCategory.mindfulness;
}

// In build():
// Header: habit icon + name + streak count
// Body: TextField with placeholder ("What did you accomplish?" / "Write your thoughts...")
// Footer:
//   Writing habit: [Cancel] [Save & Done] (disabled until text entered)
//   Action habit: [Cancel] [Done] [Add Details → expands TextField]
```

### Wiring

**File:** `lib/widgets/routine_item.dart`

```dart
// OLD: onTap → provider.toggleRoutine(routine)
// NEW: onTap → async showRoutineNoteDialog → on save: create entry + mark done

GestureDetector(
  onTap: () async {
    final note = await showDialog<String>(
      context: context,
      builder: (_) => RoutineNoteDialog(routine: routine, isZh: isZh),
    );
    if (note != null) {
      // Writing habits: note is non-empty. Action habits: note may be empty.
      context.read<EntryProvider>().addEntry(
        type: EntryType.routine,
        content: note,
        tagIds: _resolveTags(routine),
      );
      context.read<RoutineProvider>().toggleRoutine(routine);
    }
  },
)
```

### Data Flow

```
User taps habit in Daily
  → RoutineNoteDialog opens
  → User writes note (or skips for action habit)
  → Dialog returns note text
  → Entry created (type=habit, tagged with category + habit name)
  → Habit marked complete
  → Entry appears in Tallies → Journal (auto-tagged, searchable)
```

### Acceptance Criteria
- [ ] Tapping habit opens dialog (not instant checkbox)
- [ ] Writing habits: cannot submit empty text
- [ ] Action habits: "Done" button works without text
- [ ] Note creates Entry with correct type and auto-tags
- [ ] Habit marked complete on save
- [ ] Entry appears in Tallies → Journal

---

## Item 30: Remove Mood Jar

### Changes

**File:** `lib/screens/home/home_screen.dart`
- Remove `_EmojiJarSection` widget invocation
- Remove `JarProvider` watch (if zero remaining references)

**File:** `lib/screens/cherished/cherished_memory_screen.dart`
- Remove `EmojiJarSection` class import/usage
- Remove from old Moods tab (tab now gone anyway with 3→2 sub-tab merge)

### Acceptance Criteria
- [ ] No mood jar on Daily
- [ ] No mood jar in Tallies
- [ ] JarProvider kept in codebase (not deleted — may be repurposed)

---

## Item 31: Refactor Tag ↔ Habit Association

### Design Intent

Every habit has a category. Every category has a default tag. When a habit note is created, it's auto-tagged with:
1. The habit's category tag (e.g., "Health" → `cat_health`)
2. The habit's own name as a tag (e.g., "Walk 5000 steps")

This makes all notes filterable by category and habit in the Journal.

```dart
List<String> _resolveTags(Routine routine) {
  final tags = <String>[];
  // Category tag
  final catTag = _findTagForCategory(routine.category);
  if (catTag != null) tags.add(catTag.id);
  // Habit name tag
  final habitTag = _findOrCreateTag(routine.name, routine.nameEn, routine.category);
  tags.add(habitTag.id);
  return tags;
}
```

### Acceptance Criteria
- [ ] Habit note auto-tagged with category + habit name
- [ ] Tags visible in Journal entry cards
- [ ] Filter by category in Journal works correctly
- [ ] No duplicate tags created

---

## Visual Flow

```
┌─────────────────────────────────────────────────────┐
│ [ Daily ]  [ Tallies ]  [ Settings ]                 │
├─────────────────────────────────────────────────────┤
│                                                      │
│  Daily Screen:                                       │
│  ┌──────────────────────────────────────┐            │
│  │ Calendar (date navigation)            │            │
│  ├──────────────────────────────────────┤            │
│  │ ☐ Drink water       💧  Health       │ ← tap     │
│  │ ☐ Walk 5000 steps   🚶  Fitness      │ ← tap     │
│  │ ☐ Write a note      ✍️  Reflection   │ ← tap     │
│  │ ☐ Read 15 minutes   📖  Mindfulness  │ ← tap     │
│  └──────────────────────────────────────┘            │
│                                                      │
│  On tap → RoutineNoteDialog:                         │
│  ┌──────────────────────────────────────┐            │
│  │ ✍️ Write a note    Streak: 12 days   │            │
│  │ ┌──────────────────────────────────┐ │            │
│  │ │ Write your thoughts...            │ │            │
│  │ └──────────────────────────────────┘ │            │
│  │ [Cancel]              [Save & Done] │            │
│  └──────────────────────────────────────┘            │
│                                                      │
│  Tallies → Journal: shows all habit-generated notes   │
│  ┌──────────────────────────────────────┐            │
│  │ Search: [________]  Filter: [Health▾]│            │
│  ├──────────────────────────────────────┤            │
│  │ Jun 14, 2026                          │            │
│  │ ✍️ Today was productive... 💼 🏃     │            │
│  │ Jun 13, 2026                          │            │
│  │ 📖 Finished chapter 5... 📖          │            │
│  └──────────────────────────────────────┘            │
└─────────────────────────────────────────────────────┘
```

---

## Phase 7 Task Breakdown

| Day | Item | Task | Effort | Risk |
|-----|------|------|--------|------|
| 1 | 28a | Remove "+" tab, rename to Daily (3-tab nav) | 1h | Low |
| 1 | 28b | Move MomentScreen into Tallies as Journal sub-tab | 2h | Medium |
| 2 | 28c | Merge old Tallies tabs (4→2: Progress + Journal) | 2h | Medium |
| 3 | 29 | Create RoutineNoteDialog + wire habit tap | 4h | Medium |
| 4 | 30 | Remove mood jar from Daily + Tallies | 1h | Low |
| 5 | 31 | Refactor tag ↔ habit auto-association | 3h | Medium |
| 6 | — | Update tests + Maestro flows | 3h | High |
| 7 | — | Regression QA on 3 sims | 2h | — |

## Impact Analysis

| Area | Impact | Mitigation |
|------|--------|------------|
| Navigation | 5→3 tabs: index shifts, MomentScreen moves | Update all nav tests + Maestro flows |
| Entry creation | Freeform notes gone — all notes from habits | Existing entries preserved, only creation flow changes |
| Tallies tabs | 4→2 sub-tabs: merge charts into Progress, move notes into Journal | ProgressTab is new file; JournalTab = existing MomentScreen |
| Emotion tracking | Mood jar removed — no mood input | Future: can add mood field to RoutineNoteDialog |
| Test suite | ~25 tests reference old nav, "+" tab, mood jar | Run full suite after each item |
| AddEntryScreen | Still exists as code but no longer used from "+" tab | Can be left as dead code or removed |

## Open Decisions

| Question | Options | Recommendation |
|----------|---------|----------------|
| Tallies sub-tab names? | A: Progress + Journal / B: Habits + Notes / C: Insights + Entries | **A: Progress + Journal** |
| Keep AddEntryScreen code? | Delete / Keep (dead) | Delete — reduces bundle size |
| Calendar on Daily? | Keep / Remove | Keep ✅ (confirmed) |
| JarProvider? | Keep for future / Delete | Keep (may repurpose for streak animations) |
