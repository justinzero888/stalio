# Stalio — Item 23 Redesign: cherished_memory_screen.dart Split

> **Current State:** 1609 lines, 30 classes, 4 tabs. Edits require `sed` only.
> **Goal:** Safer editing, under 400 lines per file, no class corruption.
> **Previous Attempt:** Failed — sed corrupted class names and constructors (93 errors).

---

## Current Dependency Map

```
InsightsScreen (entry point)
└── _InsightsContent (TabController)
    ├── _HeroStatsRow (shared header — used by all tabs)
    ├── Tab 1: _HabitsTab
    │   ├── _RoutineCompletionChart
    │   └── _StreakMatrixSection
    ├── Tab 2: _NotesTab
    │   ├── _WritingStatsSection
    │   ├── _NoteCountChart
    │   ├── _TopTagsChart
    │   ├── _ChecklistInsightsSection
    │   └── _TagMoodSection
    ├── Tab 3: _MoodsTab
    │   ├── _MoodDistributionChart
    │   ├── _EmotionTrendChart
    │   └── _EmojiJarSection
    └── Tab 4: TagAnalyticsTab (already separate file)
Shared helpers: _SectionTitle, _EmptyChart, _ScopePicker, _MiniStatCard, _CalendarHeatmap
Dead: _TrendCharts, _ChecklistInsightsEmpty, _ChecklistStatRow, _TagMoodEmpty
```

---

## Option A: Widget Library Pattern (Recommended)

**Approach:** Extract ALL chart and helper widgets into a shared widget library file. Keep only the 4 tab shells + TabController in the main file. Tab shells are thin wrappers (~30 lines each).

```
cherished_memory_screen.dart (~200 lines)
├── InsightsScreen
└── _InsightsContent (TabController + TabBar + TabBarView)

cherished/tallies/charts.dart (~800 lines)
├── RoutineCompletionChart
├── StreakMatrixSection
├── NoteCountChart, TopTagsChart, WritingStatsSection
├── MoodDistributionChart, EmotionTrendChart
├── ChecklistInsightsSection, TagMoodSection
└── EmojiJarSection

cherished/tallies/shared.dart (~400 lines)
├── SectionTitle, EmptyChart, MiniStatCard
├── HeroStatsRow, HeroCard, HeroCardData
├── SectionCard, CalendarHeatmap
└── ScopePicker, ScopeChip

cherished/tallies/habits_tab.dart (~30 lines)
cherished/tallies/notes_tab.dart (~30 lines)
cherished/tallies/moods_tab.dart (~30 lines)
```

**How:** Create `charts.dart` and `shared.dart` by copying class bodies via sed. The extracted classes remain private (`_` prefix) and are accessed only from within their library file. Tab widgets reference chart classes via imports of `charts.dart` and `shared.dart`.

### SWOT — Option A

| Strengths | Weaknesses |
|-----------|------------|
| Clear separation of concerns (charts vs shared vs tabs) | Requires making ~20 classes public or re-exporting via library |
| Each file under 800 lines — safe for edit tool | Large initial move (3 new files, ~1200 lines total) |
| Future chart additions go to `charts.dart` naturally | Risk of missing a dependency during extraction |
| Tab files are trivially thin (30 lines each) | |
| **Opportunities** | **Threats** |
| Dead classes (_TrendCharts etc.) removed in one pass | Sed line numbers shift during extraction — use copy, then delete |
| Charts become independently testable | Cross-file private class access requires `part`/`part of` or public visibility |
| Shared helpers become reusable for other screens | If extraction misses a dependency, rebuild needed |

---

## Option B: `part` / `part of` Pattern (Dart Native)

**Approach:** Use Dart's `part` directive to split the file without changing any class visibility. Each extracted section is a `part of` the main library.

```
cherished_memory_screen.dart (~200 lines)
├── library cherished_memory;
├── part 'tallies/charts.dart';
├── part 'tallies/shared.dart';
├── part 'tallies/habits_tab.dart';
├── part 'tallies/notes_tab.dart';
└── part 'tallies/moods_tab.dart';

tallies/charts.dart           ← part of cherished_memory;
tallies/shared.dart           ← part of cherished_memory;
tallies/habits_tab.dart       ← part of cherished_memory;
tallies/notes_tab.dart        ← part of cherished_memory;
tallies/moods_tab.dart        ← part of cherished_memory;
```

**How:** Add `library cherished_memory;` at top of main file. Copy class bodies to part files. Add `part of cherished_memory;` at top of each part file. All classes remain private (`_` prefix). Zero visibility changes needed.

### SWOT — Option B

| Strengths | Weaknesses |
|-----------|------------|
| Zero class renames — preserves all `_` prefixes | Relies on `part` — considered legacy by some Dart style guides |
| Imports stay in one place (main file) | Part files cannot have their own imports |
| No risk of missing dependencies | Less portable — can't easily move charts to another screen later |
| Simple sed: just cut-paste class bodies | `part` isn't widely used in Flutter community |
| **Opportunities** | **Threats** |
| Dead code removal still possible within part files | If Dart tooling deprecates `part` support, refactor needed |
| Fastest implementation — ~1 hour | Incompatible with `part of` in other libraries if reused |
| Can convert to Option A later | |

---

## Option C: Do Nothing (Status Quo)

**Approach:** Leave the 1609-line file as-is. Document the "sed-only" constraint permanently. Accept the technical debt.

### SWOT — Option C

| Strengths | Weaknesses |
|-----------|------------|
| Zero risk of corruption | Every future edit requires sed — slow, error-prone |
| Zero implementation effort | Cannot use edit tool (core dev workflow tool) |
| Known working state | 30 classes in one file — hard to navigate |
| | Scares away contributors |
| **Opportunities** | **Threats** |
| None | File will only grow (Phase 6 adds features) |
| | Regression risk increases over time |
| | Knowledge of sed-only constraint may be lost |

---

## Decision (June 14, 2026)

**Option C selected — defer to Phase 7.** Option B adds temporary `part`-file abstraction that must be migrated later. The sed-only constraint has proven manageable (Phases 3-8 edited this file successfully). Phase 7 will implement Option A (proper widget library extraction) when new chart features justify the effort. Phase 6's only remaining edit to this file is dead code removal (~30 lines deleted).

---

