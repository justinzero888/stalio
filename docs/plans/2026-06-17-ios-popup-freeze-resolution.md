# iOS Popup Freeze Resolution Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Eliminate iOS-specific app freeze caused by three distinct root causes: a `Future.microtask`-wrapped `Navigator.push` in onboarding, a `showDialog` called mid-provider-rebuild in `booleanOptionalText` habits, and a full `Scaffold` nested inside `TabBarView` in the Tallies screen — then close the entire bug class so these patterns cannot recur.

**Architecture:** Phase 1 applies targeted patches to the three known freeze sites to unblock testing on the iOS simulator. Phase 2 eliminates the bug class by introducing a `showDialogDeferred` utility, moving `TabController` to `initState`, and fixing fire-and-forget async in `habit_popup_factory.dart`. Phase 3 adds the `use_build_context_synchronously` lint, widget/integration tests, and inline documentation so future code is safe by default.

**Tech Stack:** Flutter (Dart), Provider, `WidgetsBinding.instance.endOfFrame`, `SingleTickerProviderStateMixin`, `flutter_test`, `flutter_lints`.

---

## Background: The iOS ModalBarrier Freeze

On iOS (not Android), calling `showDialog` or `Navigator.push` while Flutter's rendering pipeline has a pending provider rebuild causes the `ModalBarrier` overlay entry to be installed before the route/dialog content is positioned. The barrier absorbs all touches invisibly, making the app appear permanently frozen. The codebase already documents and fixes this for the carry-forward dialog at `lib/screens/home/home_screen.dart:41-45` and `:574`. This plan extends that fix everywhere it is needed and prevents it from being re-introduced.

Three root causes confirmed:
1. `lib/screens/onboarding/onboarding_flow.dart:84` — `Future.microtask` wraps `Navigator.push`, firing mid-gesture on iOS
2. `lib/widgets/habit_popups/habit_popup_factory.dart:153` — `await _completeRoutine` (→ `notifyListeners`) before `showDialog`
3. `lib/screens/cherished/cherished_memory_screen.dart:51` — `MomentScreen` (full `Scaffold`) embedded in `TabBarView`

---

## Phase 1 — Unblock Testing (~1 day)

### Task 1.1: Remove `Future.microtask` from `_openHabitLibrary`

**Root cause fixed:** Onboarding "Add more from library" freeze — `Future.microtask` fires `Navigator.push` while UIKit is still delivering the button-tap gesture on iOS.

**Files:**
- Modify: `lib/screens/onboarding/onboarding_flow.dart:84-100`
- Test: `test/screens/onboarding_flow_test.dart`

---

**Step 1: Write the failing test**

Add this test to `test/screens/onboarding_flow_test.dart`. It navigates to screen 3, taps "Add more from library", and asserts the `_HabitLibraryScreen` route is pushed (a Text widget from the library appears). Currently this interaction freezes the app (the route push stalls), so the test times out or finds no widget.

```dart
testWidgets('Add more from library navigates to habit library without freeze', (tester) async {
  await tester.pumpWidget(_wrap(
    OnboardingFlow(onComplete: () {}),
    routines: [
      _makeRoutine('seed_H001', 'Drink water', isDefaultBundle: true),
      _makeRoutine('seed_H002', 'Take vitamins', isDefaultBundle: false),
    ],
  ));
  await tester.pumpAndSettle();

  // Navigate to screen 3 (Select Habits)
  await _goToScreen(tester, 2);

  // Tap "Add more from library"
  final libraryBtn = find.textContaining('library');
  await tester.ensureVisible(libraryBtn);
  await tester.tap(libraryBtn);
  await tester.pumpAndSettle(const Duration(seconds: 2));

  // Verify library screen pushed (search field appears)
  expect(find.byType(TextField), findsOneWidget);
  expect(find.text('Take vitamins'), findsOneWidget);
});
```

**Step 2: Run test to verify it fails**

```bash
flutter test test/screens/onboarding_flow_test.dart --name "Add more from library" -v
```

Expected: FAIL — test times out waiting for the library screen or finds no `TextField`.

---

**Step 3: Apply the fix**

In `lib/screens/onboarding/onboarding_flow.dart`, replace lines 84-100:

**Before:**
```dart
void _openHabitLibrary() {
  Future.microtask(() async {
    if (!mounted) return;
    final routines = context.read<RoutineProvider>().routines;
    final result = await Navigator.of(context).push<Set<String>>(
      MaterialPageRoute(
        builder: (_) => _HabitLibraryScreen(
          routines: routines,
          selectedIds: _selectedHabitIds.toSet(),
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => _selectedHabitIds = result);
    }
  });
}
```

**After:**
```dart
Future<void> _openHabitLibrary() async {
  if (!mounted) return;
  final routines = context.read<RoutineProvider>().routines;
  final result = await Navigator.of(context).push<Set<String>>(
    MaterialPageRoute(
      builder: (_) => _HabitLibraryScreen(
        routines: routines,
        selectedIds: _selectedHabitIds.toSet(),
      ),
    ),
  );
  if (result != null && mounted) {
    setState(() => _selectedHabitIds = result);
  }
}
```

The method signature changes from `void` to `Future<void>` and the `onPressed` caller must also be updated. Find the `OutlinedButton` that calls `_openHabitLibrary()` and confirm it is already using `onPressed: _openHabitLibrary` (a tear-off), which works with both `void` and `Future<void>`. No caller change needed.

**Step 4: Run test to verify it passes**

```bash
flutter test test/screens/onboarding_flow_test.dart --name "Add more from library" -v
```

Expected: PASS

**Step 5: Run the full test suite**

```bash
flutter test
```

Expected: all existing tests pass.

**Step 6: Commit**

```bash
git add lib/screens/onboarding/onboarding_flow.dart test/screens/onboarding_flow_test.dart
git commit -m "fix(onboarding): remove Future.microtask from _openHabitLibrary to prevent iOS route-push freeze"
```

---

### Task 1.2: Defer `showDialog` in `_showBooleanOptionalTextPopup`

**Root cause fixed:** `booleanOptionalText` habits freeze — `showDialog` is called immediately after `await _completeRoutine` which fires `notifyListeners()`, leaving HomeScreen marked dirty. On iOS, `showDialog` mid-rebuild orphans the `ModalBarrier`. This is the identical pattern already documented and fixed for the carry-forward dialog at `home_screen.dart:574`.

**Files:**
- Modify: `lib/widgets/habit_popups/habit_popup_factory.dart:151-162`
- Test: `test/screens/home_screen_test.dart`

---

**Step 1: Write the failing test**

Add to `test/screens/home_screen_test.dart`. This test requires a `booleanOptionalText` habit (e.g., "Vitamins") to be visible on the home screen, taps it, and asserts the note dialog appears. Currently the dialog never appears on iOS because the ModalBarrier absorbs input.

First confirm the test helper pattern used in `test/screens/home_screen_test.dart` — look at how it builds the widget tree and what providers it wires up. Then add:

```dart
testWidgets('booleanOptionalText habit tap shows note dialog', (tester) async {
  // Use the existing _buildApp or _wrap helper from home_screen_test.dart
  // with a routine that has trackingUiType: TrackingUiType.booleanOptionalText
  final vitamins = Routine(
    id: 'H002',
    name: 'Take vitamins',
    nameEn: 'Take vitamins',
    icon: '💊',
    frequency: RoutineFrequency.daily,
    isActive: true,
    isDefaultBundle: true,
    trackingUiType: TrackingUiType.booleanOptionalText,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  await tester.pumpWidget(buildHomeApp(routines: [vitamins])); // use existing helper
  await tester.pumpAndSettle();

  // Tap the habit card
  await tester.tap(find.text('Take vitamins'));
  await tester.pumpAndSettle();

  // The note dialog should appear
  expect(find.byType(AlertDialog), findsOneWidget);
  expect(find.text('Skip'), findsOneWidget);
  expect(find.text('Save'), findsOneWidget);
});
```

**Step 2: Run test to verify it fails**

```bash
flutter test test/screens/home_screen_test.dart --name "booleanOptionalText habit tap" -v
```

Expected: FAIL — `AlertDialog` not found (the dialog doesn't appear because the ModalBarrier is orphaned).

---

**Step 3: Apply the fix**

In `lib/widgets/habit_popups/habit_popup_factory.dart`, replace lines 151-162:

**Before:**
```dart
Future<void> _showBooleanOptionalTextPopup(BuildContext context, Routine routine, DateTime date) async {
  final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
  await _completeRoutine(context, routine, date);

  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => _BooleanNoteShell(routine: routine, isZh: isZh),
  );
  if (result != null && context.mounted) {
    _createEntry(context, routine, date, result);
  }
}
```

**After:**
```dart
Future<void> _showBooleanOptionalTextPopup(BuildContext context, Routine routine, DateTime date) async {
  final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
  await _completeRoutine(context, routine, date);
  if (!context.mounted) return;
  // Defer to let the RoutineProvider rebuild settle before the ModalBarrier is
  // installed. On iOS, showDialog called mid-rebuild orphans the barrier and
  // freezes all input. Same fix as _showCarryForwardDialog in home_screen.dart.
  await WidgetsBinding.instance.endOfFrame;
  if (!context.mounted) return;
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => _BooleanNoteShell(routine: routine, isZh: isZh),
  );
  if (result != null && context.mounted) {
    _createEntry(context, routine, date, result);
  }
}
```

**Step 4: Run test to verify it passes**

```bash
flutter test test/screens/home_screen_test.dart --name "booleanOptionalText habit tap" -v
```

Expected: PASS

**Step 5: Run the full test suite**

```bash
flutter test
```

Expected: all existing tests pass.

**Step 6: Commit**

```bash
git add lib/widgets/habit_popups/habit_popup_factory.dart test/screens/home_screen_test.dart
git commit -m "fix(habits): defer showDialog to next frame in _showBooleanOptionalTextPopup to prevent iOS ModalBarrier freeze"
```

---

### Task 1.3: Extract `MomentBody` — remove nested `Scaffold` from `TabBarView`

**Root cause fixed:** Tallies Habits→Notes tab freeze — `MomentScreen` is a full `Scaffold` embedded inside another `Scaffold`'s `TabBarView`. On iOS, nested `Scaffold` widgets create conflicting gesture recognizers (back-swipe, page-swipe, list-scroll) that deadlock the UIKit gesture arbitration system. The fix separates the widget into: `MomentBody` (the body content, no `Scaffold`) and a thin `MomentScreen` shell (wraps `MomentBody` in `Scaffold` for any future standalone route use).

**Files:**
- Modify: `lib/screens/moment/moment_screen.dart` (all 582 lines)
- Modify: `lib/screens/cherished/cherished_memory_screen.dart:51`
- Test: `test/screens/notes_share_selection_test.dart` (verify existing tests still pass)
- Create: `test/screens/moment_body_embedding_test.dart`

---

**Step 1: Write the failing test**

Create `test/screens/moment_body_embedding_test.dart`. This test renders `MomentBody` inside a `TabBarView` (under an outer `Scaffold`) and verifies no exception is thrown and the search field renders. Currently this uses `MomentScreen` which includes a nested `Scaffold`, so this test does not yet exist to catch the problem.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stalio/screens/moment/moment_screen.dart';
import 'package:stalio/providers/entry_provider.dart';
import 'package:stalio/providers/tag_provider.dart';
import 'package:stalio/providers/tag_category_provider.dart';
import 'package:stalio/providers/locale_provider.dart';
import 'package:stalio/core/services/storage_service.dart';
import 'package:stalio/repositories/repositories.dart';
import 'package:stalio/l10n/app_localizations.dart';

Widget _wrapEmbedded(Widget body) {
  SharedPreferences.setMockInitialValues({});
  final storage = StorageService.forTest(); // use test factory if available, else adapt
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => LocaleProvider()..setLocale(const Locale('en'))),
      ChangeNotifierProvider(create: (_) => EntryProvider(EntryRepository(storage))..loadEntries()),
      ChangeNotifierProvider(create: (_) => TagProvider(TagRepository(storage))..loadTags()),
      ChangeNotifierProvider(create: (_) => TagCategoryProvider(TagCategoryRepository(storage))..loadCategories()),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(  // outer Scaffold — simulates InsightsScreen
        body: DefaultTabController(
          length: 2,
          child: Column(children: [
            const TabBar(tabs: [Tab(text: 'Habits'), Tab(text: 'Notes')]),
            Expanded(child: TabBarView(children: [
              const Text('Habits Tab'),
              body,  // the widget under test
            ])),
          ]),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('MomentBody renders inside TabBarView without nested Scaffold conflict', (tester) async {
    await tester.pumpWidget(_wrapEmbedded(const MomentBody()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsOneWidget); // search bar
  });

  testWidgets('MomentScreen standalone still renders Scaffold', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService.forTest();
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()..setLocale(const Locale('en'))),
        ChangeNotifierProvider(create: (_) => EntryProvider(EntryRepository(storage))..loadEntries()),
        ChangeNotifierProvider(create: (_) => TagProvider(TagRepository(storage))..loadTags()),
        ChangeNotifierProvider(create: (_) => TagCategoryProvider(TagCategoryRepository(storage))..loadCategories()),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const MomentScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
```

> **Note on `StorageService.forTest()`:** Check how existing tests in `test/screens/home_screen_test.dart` or `test/screens/restore_integration_test.dart` create a test-safe `StorageService`. Use the same pattern here — do not invent a new factory.

**Step 2: Run test to verify it fails**

```bash
flutter test test/screens/moment_body_embedding_test.dart -v
```

Expected: FAIL — `MomentBody` is not yet defined as a public widget.

---

**Step 3: Refactor `moment_screen.dart`**

The refactor is mechanical: all state and method logic moves from `_MomentScreenState` to `_MomentBodyState`. `MomentBody.build()` returns a `Column` instead of a `Scaffold`. `MomentScreen` becomes a `StatelessWidget` wrapping `MomentBody` in a `Scaffold`.

Replace the entire `lib/screens/moment/moment_screen.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../providers/entry_provider.dart';
import '../../providers/tag_provider.dart';
import '../../providers/tag_category_provider.dart';
import '../../providers/locale_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/models.dart';
import '../../l10n/app_localizations.dart';
import '../../core/utils/share_format.dart';
import 'entry_detail_screen.dart';

/// Scaffold-free body widget — safe to embed in TabBarView or any other
/// Scaffold's body without creating nested-Scaffold gesture conflicts on iOS.
class MomentBody extends StatefulWidget {
  const MomentBody({super.key});

  @override
  State<MomentBody> createState() => _MomentBodyState();
}

class _MomentBodyState extends State<MomentBody> {
  String _filter = 'all'; // all, today, week, tag
  String _searchQuery = '';
  String? _tagFilterId;
  String? _categoryFilterId;
  bool _isSelecting = false;
  final Set<String> _selectedEntryIds = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';

    return Column(
      children: [
        // Selection action bar (replaces AppBar in embedded context)
        if (_isSelecting)
          Material(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(children: [
                  Text(
                    '${_selectedEntryIds.length} ${isZh ? '已选' : 'selected'}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.share),
                    tooltip: 'Share',
                    onPressed: () => _showSharePreview(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() {
                      _isSelecting = false;
                      _selectedEntryIds.clear();
                    }),
                  ),
                ]),
              ),
            ),
          ),
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Semantics(
            identifier: 'input_moments_search',
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l.searchEntries,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.trim());
              },
            ),
          ),
        ),
        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            _buildFilterChip(l.all, 'all'),
            const SizedBox(width: 8),
            _buildFilterChip(l.today, 'today'),
            const SizedBox(width: 8),
            _buildFilterChip(l.thisWeek, 'week'),
            const SizedBox(width: 8),
            _buildFilterChip(l.tags, 'tag'),
          ]),
        ),
        // Category Filter Chips
        Consumer<TagCategoryProvider>(
          builder: (context, catProvider, _) {
            final categories = catProvider.categories;
            if (categories.isEmpty) return const SizedBox(height: 0);
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  _buildCategoryChip(l.all, null),
                  const SizedBox(width: 8),
                  ...categories.expand((cat) => [
                    _buildCategoryChip(
                      cat.displayName(context.read<LocaleProvider>().locale.languageCode == 'zh'),
                      cat.id,
                    ),
                    const SizedBox(width: 8),
                  ]),
                ]),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        // Entry List
        Expanded(
          child: Consumer<EntryProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return Semantics(
                identifier: 'list_entries',
                child: _buildEntryList(provider),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return FilterChip(
      label: Text(label, style: TextStyle(
        color: isSelected ? const Color(0xFFE0B84F) : null,
        fontWeight: isSelected ? FontWeight.w600 : null,
      )),
      selected: isSelected,
      selectedColor: const Color(0xFF10317D),
      checkmarkColor: const Color(0xFFE0B84F),
      onSelected: (selected) {
        if (value == 'tag') {
          if (selected) {
            _showTagPicker();
          } else {
            setState(() {
              _filter = 'all';
              _tagFilterId = null;
              _categoryFilterId = null;
            });
          }
        } else {
          setState(() {
            _filter = value;
            _tagFilterId = null;
            _categoryFilterId = null;
          });
        }
      },
    );
  }

  Widget _buildCategoryChip(String label, String? categoryId) {
    final isSelected = _categoryFilterId == categoryId;
    return FilterChip(
      label: Text(label, style: TextStyle(
        color: isSelected ? const Color(0xFFE0B84F) : null,
        fontWeight: isSelected ? FontWeight.w600 : null,
        fontSize: 13,
      )),
      selected: isSelected,
      selectedColor: const Color(0xFF10317D),
      checkmarkColor: const Color(0xFFE0B84F),
      visualDensity: VisualDensity.compact,
      onSelected: (_) {
        setState(() {
          _categoryFilterId = isSelected ? null : categoryId;
        });
      },
    );
  }

  void _showTagPicker() {
    final l = AppLocalizations.of(context)!;
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    final tagProvider = context.read<TagProvider>();
    final tags = tagProvider.tags;

    if (tags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.noTagsWarning)),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.selectTags),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: tags.map((tag) {
              final colorValue =
                  int.parse(tag.color.substring(1), radix: 16) + 0xFF000000;
              return ListTile(
                leading: CircleAvatar(backgroundColor: Color(colorValue), radius: 8),
                title: Text(tag.displayName(isZh)),
                onTap: () {
                  setState(() {
                    _filter = 'tag';
                    _tagFilterId = tag.id;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _filter = 'all';
                _tagFilterId = null;
                _categoryFilterId = null;
              });
              Navigator.pop(context);
            },
            child: Text(l.cancel),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryList(EntryProvider provider) {
    final l = AppLocalizations.of(context)!;
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    final now = DateTime.now();

    List<Entry> entries;
    switch (_filter) {
      case 'today':
        entries = provider.allEntries
            .where((e) =>
                e.createdAt.year == now.year &&
                e.createdAt.month == now.month &&
                e.createdAt.day == now.day)
            .toList();
        break;
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        entries = provider.allEntries.where((e) => e.createdAt.isAfter(weekAgo)).toList();
        break;
      case 'tag':
        entries = _tagFilterId != null
            ? provider.allEntries.where((e) => e.tagIds.contains(_tagFilterId)).toList()
            : provider.allEntries;
        break;
      default:
        entries = provider.allEntries;
    }

    if (_categoryFilterId != null) {
      final tagProvider = context.read<TagProvider>();
      final catTagIds = tagProvider.tags
          .where((t) => t.categoryId == _categoryFilterId)
          .map((t) => t.id)
          .toSet();
      entries = entries
          .where((e) =>
              e.tagIds.contains(_categoryFilterId) ||
              e.tagIds.any((id) => catTagIds.contains(id)))
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      entries = entries
          .where((e) => e.content.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    entries = entries.where((e) => e.type != EntryType.routine || e.content.isNotEmpty).toList();

    if (entries.isEmpty) {
      return Center(child: Text(l.noEntriesYet, textAlign: TextAlign.center));
    }

    final grouped = <String, List<Entry>>{};
    for (var entry in entries) {
      final dateKey = isZh
          ? DateFormat('yyyy年M月d日').format(entry.createdAt)
          : DateFormat('MMM d, y').format(entry.createdAt);
      grouped.putIfAbsent(dateKey, () => []).add(entry);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final dateKey = grouped.keys.elementAt(index);
        final dateEntries = grouped[dateKey]!;
        final isToday = _isToday(dateEntries.first.createdAt);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                isToday ? l.today : dateKey,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
            ...dateEntries.map((entry) => _buildEntryCard(entry, provider)),
          ],
        );
      },
    );
  }

  Widget _buildEntryCard(Entry entry, EntryProvider provider) {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    final tagProvider = context.read<TagProvider>();
    final tags = tagProvider.tags.where((t) => entry.tagIds.contains(t.id)).toList();
    final String? routineMetaName = (entry.type == EntryType.routine && entry.metadata != null)
        ? entry.metadata!['routineName'] as String?
        : null;
    final isSelected = _selectedEntryIds.contains(entry.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        identifier: 'entry_item',
        child: ListTile(
          leading: _isSelecting
              ? Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleEntry(entry.id),
                  visualDensity: VisualDensity.compact,
                )
              : _getEntryLeading(entry, routineMetaName),
          title: Text(entry.content),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(DateFormat('HH:mm').format(entry.createdAt), style: const TextStyle(fontSize: 12)),
              if (routineMetaName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    routineMetaName,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ),
              if (entry.type != EntryType.routine && tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Wrap(
                    spacing: 4,
                    children: tags.map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Color(int.parse(t.color.replaceFirst('#', '0xFF'))).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        t.displayName(isZh),
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(int.parse(t.color.replaceFirst('#', '0xFF'))),
                        ),
                      ),
                    )).toList(),
                  ),
                ),
            ],
          ),
          onTap: _isSelecting
              ? () => _toggleEntry(entry.id)
              : () => Navigator.push(context, MaterialPageRoute(builder: (_) => EntryDetailScreen(entry: entry))),
          onLongPress: _isSelecting
              ? null
              : () => setState(() { _isSelecting = true; _selectedEntryIds.add(entry.id); }),
        ),
      ),
    );
  }

  Widget _getEntryLeading(Entry entry, String? routineMetaName) {
    if (entry.type == EntryType.routine) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            routineMetaName != null ? routineMetaName.substring(0, 1) : '✓',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }
    return Icon(_getEntryIcon(entry), color: Theme.of(context).colorScheme.primary);
  }

  IconData _getEntryIcon(Entry entry) {
    if (entry.type == EntryType.routine) return Icons.check_circle;
    if (entry.format == EntryFormat.list) return Icons.checklist;
    return Icons.note;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  void _showDeleteDialog(Entry entry, EntryProvider provider) {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.deleteEntry),
        content: Text(l.deleteEntryConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
          TextButton(
            onPressed: () {
              provider.deleteEntry(entry.id);
              Navigator.pop(context);
            },
            child: Text(l.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _toggleEntry(String id) {
    setState(() {
      if (_selectedEntryIds.contains(id)) {
        _selectedEntryIds.remove(id);
        if (_selectedEntryIds.isEmpty) _isSelecting = false;
      } else {
        _selectedEntryIds.add(id);
      }
    });
  }

  void _showSharePreview(BuildContext context) {
    final provider = context.read<EntryProvider>();
    final selected = provider.allEntries.where((e) => _selectedEntryIds.contains(e.id)).toList();
    selected.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';

    String buildFormat(int index) {
      switch (index) {
        case 1: return ShareFormat.toMarkdown(selected, isZh);
        case 2: return ShareFormat.toRichText(selected, isZh);
        default: return ShareFormat.toPlainText(selected, isZh);
      }
    }

    int formatIndex = 0;
    final controller = TextEditingController(text: buildFormat(0));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(children: [
            Text(isZh ? '分享预览' : 'Share Preview'),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: isZh ? '复制' : 'Copy',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: controller.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isZh ? '已复制' : 'Copied'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
          ]),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _formatBtn(isZh ? '纯文本' : 'Plain', 0, formatIndex,
                    () => setDialogState(() { formatIndex = 0; controller.text = buildFormat(0); })),
                const SizedBox(width: 8),
                _formatBtn('Markdown', 1, formatIndex,
                    () => setDialogState(() { formatIndex = 1; controller.text = buildFormat(1); })),
                const SizedBox(width: 8),
                _formatBtn(isZh ? '富文本' : 'Rich', 2, formatIndex,
                    () => setDialogState(() { formatIndex = 2; controller.text = buildFormat(2); })),
              ]),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(controller.text, style: const TextStyle(fontSize: 13, fontFamily: 'monospace')),
                ),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isZh ? '取消' : 'Cancel')),
            FilledButton.icon(
              icon: const Icon(Icons.share, size: 18),
              label: Text(isZh ? '分享' : 'Share'),
              onPressed: () {
                Navigator.pop(ctx);
                _shareContent(controller.text, isZh);
              },
            ),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.save_alt, size: 18),
              label: Text(isZh ? '保存为文件' : 'Save as file'),
              onPressed: () {
                Navigator.pop(ctx);
                _saveAsFile(controller.text, formatIndex, context, isZh);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _formatBtn(String label, int index, int selected, VoidCallback onTap) {
    final active = index == selected;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label,
            style: TextStyle(
              color: active ? Colors.white : Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            )),
      ),
    );
  }

  void _shareContent(String text, bool isZh) {
    SharePlus.instance.share(ShareParams(text: text));
  }

  Future<void> _saveAsFile(String content, int formatIndex, BuildContext context, bool isZh) async {
    final dir = await getApplicationDocumentsDirectory();
    final ext = formatIndex == 1 ? 'md' : 'txt';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/stalio_export_$timestamp.$ext');
    await file.writeAsString(content);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: 'Stalio Notes'));
  }
}

/// Standalone route wrapper. Use [MomentBody] directly when embedding in
/// a [TabBarView] or any widget already inside a [Scaffold].
class MomentScreen extends StatelessWidget {
  const MomentScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: MomentBody());
}
```

**Step 4: Update `cherished_memory_screen.dart`**

In `lib/screens/cherished/cherished_memory_screen.dart`, change line 51 from:
```dart
const MomentScreen(),
```
to:
```dart
const MomentBody(),
```

Also update the import at the top — `MomentBody` is in the same file as `MomentScreen`, so the existing import `'../moment/moment_screen.dart'` already covers it (both classes are in the same file). No import change needed.

**Step 5: Run the embedding test**

```bash
flutter test test/screens/moment_body_embedding_test.dart -v
```

Expected: PASS

**Step 6: Run all share/selection tests to verify no regressions**

```bash
flutter test test/screens/notes_share_selection_test.dart test/screens/notes_share_preview_test.dart -v
```

Expected: all PASS

**Step 7: Run the full test suite**

```bash
flutter test
```

Expected: all existing tests pass.

**Step 8: Commit**

```bash
git add lib/screens/moment/moment_screen.dart \
        lib/screens/cherished/cherished_memory_screen.dart \
        test/screens/moment_body_embedding_test.dart
git commit -m "fix(tallies): extract MomentBody from MomentScreen to eliminate nested Scaffold in TabBarView iOS gesture conflict"
```

---

## ⛔ CHECKPOINT: iOS Simulator Validation — Phase 1

**The executing-plans session must STOP here. Do not proceed to Phase 2 until this checkpoint is complete.**

### Instructions for the developer

1. Launch the app on an iOS simulator:
   ```bash
   flutter run -d "iPhone 16 Pro" --debug
   ```

2. Test all three freeze scenarios:

   | Scenario | Steps | Expected |
   |---|---|---|
   | Onboarding library | Fresh install or clear data → complete onboarding → screen 3 → tap "Add more from library" | Library screen slides in; tapping habits registers |
   | Habit popup | Daily tab → tap any `booleanOptionalText` habit (e.g., "Take vitamins") | Note dialog appears and is dismissible |
   | Tallies Notes tab | Navigate to Tallies → tap "Notes" tab → tap search field | Tab switches; keyboard appears |

3. Report one of the following back to the executing-plans session:
   - **"Phase 1 confirmed — all three scenarios fixed"** → session continues to Phase 2
   - **"Phase 1 partial — scenario X still freezes"** → STOP, do not continue; re-diagnose before Phase 2
   - **"Phase 1 failed — all scenarios still freeze"** → STOP, do not continue; root cause analysis needs revision

### Why this checkpoint exists

Phase 2 applies architecture changes on top of Phase 1. If Phase 1 has not resolved the freezes, running Phase 2 makes the codebase harder to reason about and obscures whether any individual fix actually worked. A clean Phase 1 confirmation also validates the root cause hypotheses before investing in the broader refactor.

If a scenario is still frozen after Phase 1, report the exact scenario and any new observations (e.g., "the freeze happens on Notes tab switch but only after navigating away and back"). This information will be used to revise the plan before Phase 2 runs.

---

## Phase 2 — Eliminate the Bug Class (~2–3 days)

### Task 2.1: Create `showDialogDeferred` utility

**Why:** The `WidgetsBinding.instance.endOfFrame` + `mounted` check pattern must be applied at every `showDialog` call site, not just the two known-bad ones. Centralizing it in a utility ensures: (a) new dialog calls are one line and safe by default, (b) the iOS-specific reason is documented once not scattered, (c) future lint rules can enforce usage.

**Files:**
- Create: `lib/core/utils/dialog_utils.dart`
- Test: `test/core/dialog_utils_test.dart`

---

**Step 1: Write the failing test**

Create `test/core/dialog_utils_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stalio/core/utils/dialog_utils.dart';

void main() {
  testWidgets('showDialogDeferred shows dialog on next frame', (tester) async {
    bool dialogShown = false;

    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) => TextButton(
        onPressed: () async {
          await showDialogDeferred<void>(
            context,
            builder: (_) {
              dialogShown = true;
              return const AlertDialog(content: Text('test'));
            },
          );
        },
        child: const Text('open'),
      )),
    ));

    await tester.tap(find.text('open'));
    await tester.pump(); // one frame — deferred dialog should now install

    expect(dialogShown, isTrue);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('showDialogDeferred returns null when context unmounted before frame', (tester) async {
    late BuildContext capturedContext;
    bool widgetVisible = true;

    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(builder: (context, setState) {
        if (widgetVisible) {
          capturedContext = context;
        }
        return widgetVisible
            ? const Text('visible')
            : const SizedBox.shrink();
      }),
    ));

    // Capture context then remove widget before frame fires
    widgetVisible = false;
    // Do NOT pump yet — widget is about to be removed
    await tester.pump();

    // Now call showDialogDeferred with a stale context
    final result = await showDialogDeferred<String>(
      capturedContext,
      builder: (_) => const AlertDialog(content: Text('should not appear')),
    );

    expect(result, isNull);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
```

**Step 2: Run test to verify it fails**

```bash
flutter test test/core/dialog_utils_test.dart -v
```

Expected: FAIL — `dialog_utils.dart` not found.

---

**Step 3: Create `lib/core/utils/dialog_utils.dart`**

```dart
import 'package:flutter/material.dart';

/// Shows a dialog deferred to the next rendering frame.
///
/// On iOS, calling [showDialog] while a provider rebuild is pending installs
/// the [ModalBarrier] before dialog content is positioned — the barrier
/// absorbs all touches invisibly, freezing the app. Awaiting
/// [WidgetsBinding.instance.endOfFrame] lets pending rebuilds settle first.
///
/// Use this instead of [showDialog] whenever the call may follow a state
/// change (provider notification, setState, or any awaited operation).
Future<T?> showDialogDeferred<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) async {
  await WidgetsBinding.instance.endOfFrame;
  if (!context.mounted) return null;
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: builder,
  );
}
```

**Step 4: Run test to verify it passes**

```bash
flutter test test/core/dialog_utils_test.dart -v
```

Expected: PASS

**Step 5: Run full test suite**

```bash
flutter test
```

Expected: all pass.

**Step 6: Commit**

```bash
git add lib/core/utils/dialog_utils.dart test/core/dialog_utils_test.dart
git commit -m "feat(utils): add showDialogDeferred to prevent iOS ModalBarrier freeze on provider-triggered dialogs"
```

---

### Task 2.2: Apply `showDialogDeferred` to all `showDialog` calls in `habit_popup_factory.dart`

**Why:** Phase 1 (Task 1.2) fixed only `_showBooleanOptionalTextPopup` with an inline deferral. Now that `showDialogDeferred` exists, replace ALL `showDialog` calls in `habit_popup_factory.dart` with it for uniform safety. This covers all popup types regardless of whether they currently have a known iOS issue.

**Files:**
- Modify: `lib/widgets/habit_popups/habit_popup_factory.dart`

---

**Step 1: Add the import**

At the top of `lib/widgets/habit_popups/habit_popup_factory.dart`, add:

```dart
import '../../core/utils/dialog_utils.dart';
```

**Step 2: Replace every `showDialog` call with `showDialogDeferred`**

There are multiple popup functions each containing a `showDialog(context: context, ...)` call. The pattern is always:

```dart
// Before:
final result = await showDialog<T>(
  context: context,
  builder: (ctx) => _SomeShell(...),
);

// After:
final result = await showDialogDeferred<T>(
  context,
  builder: (ctx) => _SomeShell(...),
);
```

Also update `_showBooleanOptionalTextPopup` to remove the now-redundant inline `endOfFrame` deferral added in Task 1.2 (since `showDialogDeferred` handles it):

```dart
Future<void> _showBooleanOptionalTextPopup(BuildContext context, Routine routine, DateTime date) async {
  final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
  await _completeRoutine(context, routine, date);
  if (!context.mounted) return;
  final result = await showDialogDeferred<String>(
    context,
    builder: (ctx) => _BooleanNoteShell(routine: routine, isZh: isZh),
  );
  if (result != null && context.mounted) {
    _createEntry(context, routine, date, result);
  }
}
```

Apply the same `showDialogDeferred` replacement to: `_showDurationPopup`, `_showDurationOptionalTextPopup`, `_showNumberPopup`, `_showTimePopup`, `_showScalePopup`, `_showScaleOptionalTextPopup`, `_showTextRequiredPopup`, `_showMultiTextRequiredPopup`, `_showStreakPopup`.

**Step 3: Run full test suite**

```bash
flutter test
```

Expected: all pass.

**Step 4: Run analyzer**

```bash
flutter analyze lib/widgets/habit_popups/habit_popup_factory.dart
```

Expected: no issues.

**Step 5: Commit**

```bash
git add lib/widgets/habit_popups/habit_popup_factory.dart
git commit -m "refactor(habits): replace showDialog with showDialogDeferred in all popup functions for uniform iOS safety"
```

---

### Task 2.3: Move `TabController` ownership to `initState` in `_InsightsContentState`

**Why:** `DefaultTabController` is created in `build()` which is called on every `SummaryProvider` change. On iOS, a `SummaryProvider` notification triggered by `MomentBody` mounting can fire during the tab-switch animation, causing `DefaultTabController` to be reconciled mid-animation and leaving `TabBarView` in an inconsistent state. Moving to `initState` means the controller is created once and is stable through all rebuilds.

**Files:**
- Modify: `lib/screens/cherished/cherished_memory_screen.dart:38-56`

---

**Step 1: No new test needed** — the existing Tallies tab switch behavior is verified by the running app. The change is verified by `flutter analyze` and `flutter test`. However, add an assertion test:

Add to `test/screens/moment_body_embedding_test.dart`:

```dart
testWidgets('InsightsContent tab switch does not throw on rebuild', (tester) async {
  // This test verifies TabController is not recreated on SummaryProvider change
  // (which previously happened when DefaultTabController was in build())
  // Render the tab bar, switch tabs, trigger a rebuild — no exception should occur.
  // Use the existing _wrapEmbedded pattern adapted for InsightsScreen.
  // Implementation: add a ChangeNotifier mock that notifies during the test.
});
```

> **Note:** If implementing this test requires too much provider setup, skip it and rely on the iOS simulator manual smoke test instead. Mark with `// TODO: add full InsightsContent integration test`.

**Step 2: Apply the fix**

Replace lines 38-55 in `lib/screens/cherished/cherished_memory_screen.dart`:

**Before:**
```dart
class _InsightsContentState extends State<_InsightsContent> {
  @override
  Widget build(BuildContext ctx) {
    final summary = ctx.watch<SummaryProvider>();
    final isZh = ctx.watch<LocaleProvider>().locale.languageCode == 'zh';

    if (summary.isLoading) return const Center(child: CircularProgressIndicator());

    return DefaultTabController(length: 2, child: Column(children: [
      TabBar(tabs: [Tab(text: isZh?'习惯':'Habits'),Tab(text: isZh?'笔记':'Notes')]),
      Expanded(child: TabBarView(children: [
        _buildHabitsContent(summary, isZh),
        const MomentBody(),
      ])),
    ]));
  }
}
```

**After:**
```dart
class _InsightsContentState extends State<_InsightsContent>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    final summary = ctx.watch<SummaryProvider>();
    final isZh = ctx.watch<LocaleProvider>().locale.languageCode == 'zh';

    if (summary.isLoading) return const Center(child: CircularProgressIndicator());

    return Column(children: [
      TabBar(
        controller: _tabController,
        tabs: [Tab(text: isZh ? '习惯' : 'Habits'), Tab(text: isZh ? '笔记' : 'Notes')],
      ),
      Expanded(child: TabBarView(
        controller: _tabController,
        children: [
          _buildHabitsContent(summary, isZh),
          const MomentBody(),
        ],
      )),
    ]);
  }
}
```

**Step 3: Run analyzer and tests**

```bash
flutter analyze lib/screens/cherished/cherished_memory_screen.dart
flutter test
```

Expected: no issues, all pass.

**Step 4: Commit**

```bash
git add lib/screens/cherished/cherished_memory_screen.dart
git commit -m "fix(tallies): move TabController to initState to prevent rebuild-during-animation on iOS tab switch"
```

---

### Task 2.4: Fix `_createEntry` fire-and-forget and `context.mounted` guards

**Why:** `_completeWithEntry` calls `_createEntry` without `await` (fire-and-forget). `_createEntry` is an `async void` function that eventually calls `context.read<EntryProvider>()` after an `await`, without checking `context.mounted`. This violates Flutter's context-after-await contract. While not currently confirmed to freeze the app, it can cause "called on a deactivated widget" exceptions on iOS under certain navigation conditions, and will be flagged by the lint in Phase 3.

**Files:**
- Modify: `lib/widgets/habit_popups/habit_popup_factory.dart:68-87`

---

**Step 1: Apply the fix**

In `lib/widgets/habit_popups/habit_popup_factory.dart`, replace lines 68-87:

**Before:**
```dart
void _createEntry(BuildContext context, Routine routine, DateTime date, String content, {List<String>? tagIds}) async {
  final usedTags = tagIds ?? await _resolveHabitTags(context, routine);
  if (content.isNotEmpty) {
    context.read<EntryProvider>().addEntry(
      type: EntryType.routine,
      content: content,
      tagIds: usedTags,
      metadata: {
        'routineId': routine.id,
        'routineName': routine.nameEn,
        'routineDate': date.toIso8601String(),
      },
    );
  }
}

Future<void> _completeWithEntry(BuildContext context, Routine routine, DateTime date, String content, {List<String>? tagIds}) async {
  await _completeRoutine(context, routine, date);
  _createEntry(context, routine, date, content, tagIds: tagIds);
}
```

**After:**
```dart
Future<void> _createEntry(BuildContext context, Routine routine, DateTime date, String content, {List<String>? tagIds}) async {
  final usedTags = tagIds ?? await _resolveHabitTags(context, routine);
  if (!context.mounted) return;
  if (content.isNotEmpty) {
    context.read<EntryProvider>().addEntry(
      type: EntryType.routine,
      content: content,
      tagIds: usedTags,
      metadata: {
        'routineId': routine.id,
        'routineName': routine.nameEn,
        'routineDate': date.toIso8601String(),
      },
    );
  }
}

Future<void> _completeWithEntry(BuildContext context, Routine routine, DateTime date, String content, {List<String>? tagIds}) async {
  await _completeRoutine(context, routine, date);
  if (!context.mounted) return;
  await _createEntry(context, routine, date, content, tagIds: tagIds);
}
```

**Step 2: Run analyzer**

```bash
flutter analyze lib/widgets/habit_popups/habit_popup_factory.dart
```

Expected: no issues.

**Step 3: Run full test suite**

```bash
flutter test
```

Expected: all pass.

**Step 4: Commit**

```bash
git add lib/widgets/habit_popups/habit_popup_factory.dart
git commit -m "fix(habits): await _createEntry in _completeWithEntry and guard context.mounted after async gap"
```

---

## Phase 3 — Systemic Safeguards (~1 day)

### Task 3.1: Enable `use_build_context_synchronously` lint and fix all violations

**Why:** This lint catches every `context` usage after an `await` that is missing a `mounted` check — the mechanical root cause of all three iOS freezes. Enabling it turns the entire bug class into a compile-time warning so it cannot be silently re-introduced.

**Files:**
- Modify: `analysis_options.yaml`
- Modify: any files reported by `flutter analyze` after enabling

---

**Step 1: Enable the lint**

In `analysis_options.yaml`, add under `linter: rules:`:

```yaml
linter:
  rules:
    use_build_context_synchronously: true
```

**Step 2: Run analyzer to surface all violations**

```bash
flutter analyze
```

Review every reported `use_build_context_synchronously` warning. Each is a potential iOS freeze site. Do NOT suppress warnings with `// ignore:` unless there is a concrete reason the pattern is safe (and document why).

**Step 3: Fix each violation**

For each violation the fix is one of:
- Add `if (!context.mounted) return;` immediately after the `await`
- Extract the needed value from `context` BEFORE the `await`:
  ```dart
  // Instead of:
  final x = await something();
  context.read<MyProvider>().doThing();  // lint violation

  // Do:
  final provider = context.read<MyProvider>();  // before await
  final x = await something();
  if (!context.mounted) return;
  provider.doThing();
  ```

After Phases 1 and 2, the violations in `habit_popup_factory.dart` are already fixed. Check `moment_screen.dart` and any other files the analyzer flags.

**Step 4: Re-run analyzer to confirm zero violations**

```bash
flutter analyze
```

Expected: no `use_build_context_synchronously` warnings.

**Step 5: Run full test suite**

```bash
flutter test
```

Expected: all pass.

**Step 6: Commit**

```bash
git add analysis_options.yaml <any modified files>
git commit -m "chore(lint): enable use_build_context_synchronously and fix all violations"
```

---

### Task 3.2: Also remove duplicate `import` in `habit_popup_factory.dart`

**Observation discovered during Phase 1:** `lib/widgets/habit_popups/habit_popup_factory.dart` has a duplicate import:

```dart
import '../../providers/tag_provider.dart';
import '../../providers/tag_provider.dart';  // line 9 — duplicate
```

**Fix:** Remove the duplicate. No test needed — `flutter analyze` already catches duplicate imports.

```bash
git add lib/widgets/habit_popups/habit_popup_factory.dart
git commit -m "chore: remove duplicate tag_provider import in habit_popup_factory"
```

---

### Task 3.3: Manual iOS simulator verification

**Why:** The iOS ModalBarrier freeze is a platform-level behavior not reproducible in `flutter_test`. After all code changes, verify all three scenarios on the iOS simulator.

**Steps:**

1. Launch on iOS simulator:
   ```bash
   flutter run -d "iPhone 16 Pro" --debug
   ```

2. **Scenario 1 — Onboarding:** Complete fresh onboarding (clear app data first or use a fresh simulator). On screen 3, tap "Add more from library". Verify the library screen slides in smoothly. Tap habits. Verify taps register (no freeze).

3. **Scenario 2 — Habit popup:** On the Daily tab, tap a `booleanOptionalText` habit (e.g., "Take vitamins" or any habit with optional note). Verify the note dialog appears and is dismissible.

4. **Scenario 3 — Tallies Notes tab:** Navigate to Tallies. Tap "Notes" tab. Verify the tab switches without freezing. Tap the search field. Verify keyboard appears.

5. **Regression — carry-forward dialog:** On daily home screen with pending carry-forward items, verify the carry-forward dialog still appears (Phase 2 changes must not break the existing `addPostFrameCallback` path).

6. **Regression — Android:** Run on an Android emulator and verify all three scenarios work as before.

---

## Completion Checklist

| Phase | Task | Done |
|---|---|---|
| 1 | Remove `Future.microtask` from `_openHabitLibrary` | ✅ |
| 1 | Defer `showDialog` in `_showBooleanOptionalTextPopup` | ✅ |
| 1 | Extract `MomentBody`, update `TabBarView` reference | ✅ |
| 2 | Create `showDialogDeferred` utility | ✅ |
| 2 | Apply `showDialogDeferred` to all popup functions | ✅ |
| 2 | Move `TabController` to `initState` in `_InsightsContentState` | ✅ |
| 2 | Fix `_createEntry` fire-and-forget and `context.mounted` guards | ✅ |
| 3 | Enable `use_build_context_synchronously` lint, fix violations | ✅ |
| 3 | Remove duplicate `tag_provider` import | ✅ |
| 3 | Manual iOS simulator verification (all 3 scenarios + regressions) | ✅ |

## Completion Notes

**Completed:** 2026-06-17 (evening session)

**Approach deviations from plan (all improvements):**
- Task 1.1: Used `endOfFrame` + inline `setState` single-Scaffold swap instead of Navigator.push — eliminates route overhead entirely
- Task 1.2: Extended beyond booleanOptionalText to all text-type dialogs; added FocusNode pattern + method channel pre-warm (`stalio/prewarm`) to eliminate tap-freeze on real devices
- Task 2.2: Redundant inline `endOfFrame` calls removed (now centralised in `showDialogDeferred`)

**Real device validation:** iPhone 13 — all 11 popup types, zero freezes (v1.0.0+10)

**iOS 26 simulator caveat:** Old sims with clipboard content cause `UIPasteboard.hasStrings` to block indefinitely — confirmed OS simulator bug, not app code. Pre-warm skipped on simulator via `#if !targetEnvironment(simulator)`.
