# Stalio — Phase 7: Simplify User Interface — Design & Implementation Plan

> **Date:** June 14, 2026  
> **Pre-requisite:** Phase 6 UAT sign-off  
> **Est. Effort:** 6–8 days  
> **Strategic Goal:** Reduce cognitive load. Habits are the center of the app — notes flow from habits, not from a separate action.

---

## 0. Current vs Target Architecture

### Current (5 tabs + mood jar)

```
[ My Day ]  [ Tallies ]  [  +  ]  [ Notes ]  [ Settings ]

My Day = Calendar + Habit Checklist + Emoji Jar
  + = AddEntryScreen (freeform notes, checklists, media)
Notes = Browse/search past entries
Tallies = Charts + Moods + Tags (contains Emoji Jar)
```

### Target (4 tabs, no mood jar)

```
[ Daily ]  [ Tallies ]  [ Notes ]  [ Settings ]

Daily = Calendar + Habit Checklist (tap → note input)
Notes = Browse/search past notes (only habit-generated notes)
Tallies = Charts, Habit completion, Tags (no mood jar)
Settings = Same as before
```

---

## Item 28: Remove "+" Tab & Rename "My Day" → "Daily"

### Changes

**File:** `lib/app.dart`

```dart
// Before: 5 tabs, index 2 = "+" button
static const _navToScreen = <int?>[0, 1, null, 2, 3];
// After: 4 tabs
static const _navToScreen = <int?>[0, 1, 2, 3];

// Before: 5 items
items: [
  BottomNavigationBarItem(label: 'My Day'),
  BottomNavigationBarItem(label: 'Tallies'),
  BottomNavigationBarItem(...), // "+" CTA button
  BottomNavigationBarItem(label: 'Notes'),
  BottomNavigationBarItem(label: 'Settings'),
]
// After: 4 items
items: [
  BottomNavigationBarItem(label: 'Daily'),     // Renamed from "My Day"
  BottomNavigationBarItem(label: 'Tallies'),
  BottomNavigationBarItem(label: 'Notes'),
  BottomNavigationBarItem(label: 'Settings'),
]
```

Remove `_onTabTapped` "+" special case:
```dart
// Before
if (index == 2) {
  Navigator.push(...AddEntryScreen...); return;
}
// After: nothing special — all tabs switch screens
```

Remove `AddEntryScreen` import if no longer used elsewhere.

**Also update:**
- `lib/screens/home/home_screen.dart`: `AppBar` title from `'My Day'` to `isZh ? '日常' : 'Daily'`
- All Maestro test flows: update tab labels and remove "+" tap tests
- Seed data welcome entry: remove "Tap the + button" text

### Acceptance Criteria
- [ ] 4 tabs: Daily, Tallies, Notes, Settings
- [ ] "My Day" → "Daily" in navigation, AppBar, and l10n keys
- [ ] "+" button removed from nav bar
- [ ] 323 tests updated (tab index shifts)
- [ ] Maestro flows updated

---

## Item 29: Habit Tap → Note Input (The Core Redesign)

### Design Intent

Tapping a habit on Daily opens a lightweight note input instead of just checking a box. The note is associated with the habit. Two modes:

| Habit Type | Behavior | Example |
|------------|----------|---------|
| **Writing habit** | Text input modal. User MUST type to check off. Submit button saves note + marks complete. | "Write a note", "Log gratitude" |
| **Action habit** | Optional note modal. Checkmark works without text. "Add detail" button to record actual count or reason. | "Walk 5000 steps", "Drink water" |

### Current Code

**File:** `lib/widgets/routine_item.dart`

```dart
// Current: simple checkbox toggle
GestureDetector(
  onTap: () => provider.toggleRoutine(routine),
  child: Checkbox(value: completed, onChanged: (_) => provider.toggleRoutine(routine)),
)
```

### New Implementation

**File:** `lib/widgets/routine_note_dialog.dart` (new)

```dart
class RoutineNoteDialog extends StatefulWidget {
  final Routine routine;
  final bool isZh;
  const RoutineNoteDialog({required this.routine, required this.isZh});
  // ...
}

// In build():
// - Writing habits: TextField + "Save & Done" button (disabled until text entered)
// - Action habits: optional TextField + "Done" button (always enabled)
// - Both: display habit icon, name, streak count in header
```

**File:** `lib/widgets/routine_item.dart` (modified)

```dart
// Before: simple toggle
// After: tap opens RoutineNoteDialog
GestureDetector(
  onTap: () async {
    final result = await showRoutineNoteDialog(context, routine, isZh);
    if (result != null) {
      // Create entry + mark habit complete
      provider.toggleRoutineWithNote(routine, result);
    }
  },
  child: Checkbox(...),
)
```

**New provider method:** `RoutineProvider.toggleRoutineWithNote(Routine routine, String note)`

Creates an `Entry` with:
```dart
Entry(
  type: EntryType.routine,       // marks as habit-generated
  content: note,
  tagIds: _inferTagsFromHabit(routine),  // auto-tag from habit category
  createdAt: now,
  updatedAt: now,
)
```

### Acceptance Criteria
- [ ] Tapping a habit opens note dialog (not instant check)
- [ ] Writing habits: "Save & Done" disabled until text entered
- [ ] Action habits: "Done" always available, optional note
- [ ] Note creates an Entry associated with the habit
- [ ] Routine marked as completed on save
- [ ] Existing `toggleRoutine` still works for programmatic use

---

## Item 30: Remove Mood Jar (Daily + Tallies)

### Changes

**File:** `lib/screens/home/home_screen.dart`
```dart
// Remove emoji_jar import
// Remove _EmojiJarSection widget invocation (lines ~545-680)
// Remove JarProvider watch
```

**File:** `lib/screens/cherished/cherished_memory_screen.dart`
```dart
// Remove _EmojiJarSection class definition
// Remove emoji_jar import
// Remove mood jar from MoodsTab (tallies/moods_tab.dart if split)
```

**File:** `pubspec.yaml`
```dart
// Optional: remove jar_provider.dart if zero references remain
```

### Acceptance Criteria
- [ ] No mood jar on Daily screen
- [ ] No mood jar in Tallies → Moods tab
- [ ] No visual regression in other tabs
- [ ] JarProvider can be safely deprecated (not yet deleted — may be repurposed)

---

## Item 31: Refactor Tag ↔ Habit Association

### Design Intent

Currently tags and habits are separate systems with overlapping categories. After Phase 6 (Item 27), default tag categories match habit categories. This item makes the relationship explicit:

```
Habit Category (RoutineCategory enum)
  └── auto-creates tags when user creates habits
  └── habit completion → auto-tags the generated note
```

### Changes

**File:** `lib/repositories/routine_repository.dart`

```dart
Future<Routine> create({...}) async {
  // After creating routine:
  // 1. Look up TagCategory matching RoutineCategory
  // 2. Ensure Tag exists for this habit name
  // 3. Return routine with tag reference
}
```

**File:** `lib/widgets/routine_note_dialog.dart`

```dart
// When saving a habit note:
void _saveNote() {
  final tagIds = []; // Tags from habit's category
  final categoryTag = _findTagForCategory(routine.category);
  final habitTag = _findOrCreateTag(routine.name, routine.nameEn);
  tagIds.addAll([categoryTag?.id, habitTag?.id].whereNotNull());
  
  entryProvider.addEntry(
    type: EntryType.routine,
    content: _controller.text,
    tagIds: tagIds,
  );
  routineProvider.toggleRoutine(routine);
}
```

### Acceptance Criteria
- [ ] Creating a habit auto-creates matching tag (if not exists)
- [ ] Habit note gets auto-tagged with habit name + category
- [ ] Existing habits retain their current tags
- [ ] No duplicate tags created

---

## Phase 7 Task Breakdown

| Day | Item | Task | Effort | Risk |
|-----|------|------|--------|------|
| 1 | 28 | Remove "+" tab, rename to Daily | 1h | Low |
| 1 | 30 | Remove mood jar (Daily + Tallies) | 1h | Low |
| 2 | 29a | Create RoutineNoteDialog widget | 3h | Medium |
| 3 | 29b | Wire habit tap → dialog in routine_item | 2h | Medium |
| 4 | 29c | toggleRoutineWithNote + entry creation | 2h | Medium |
| 5 | 31 | Refactor tag ↔ habit association | 3h | Medium |
| 6 | — | Update all tests + Maestro flows | 3h | High |
| 7 | — | Regression QA on 3 sims | 2h | — |

## Impact Analysis

| Area | Impact | Mitigation |
|------|--------|------------|
| Navigation | 5-tab → 4-tab: index shifts require test updates | Update all navigation tests |
| Existing entries | Notes tab still shows all entries, just no "+" to create them | Entry creation now only via habit tap |
| Emotion tracking | Mood jar removed — no mood tracking | Future: mood can be added to habit note dialog |
| Analytics | MoodDistributionChart needs refactor or removal | Keep chart data structure, remove from UI only |
| Test suite | ~20 tests reference "My Day" text or "+" tab | Run full suite after each item |
| Maestro flows | 8 flows reference "+" or mood jar screens | Update flows after all UI changes |

## Open Questions for Business Owner

| Question | Options |
|----------|---------|
| Should Tallies keep the 3-tab structure (Habits, Notes, Moods → Tags) or simplify further? | Keep 3 tabs / Reduce to 2 |
| Should habit notes appear in the Notes tab browse list? | Yes (auto-tagged) / No (only in habit history) |
| Should writing habits like "Write gratitude" still be togglable without writing (if user skips)? | No (must write) / Yes (skip allowed with note) |
| Should the calendar widget on Daily stay? | Yes / Remove |
