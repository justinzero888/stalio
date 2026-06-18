# Lessons Learned — June 16, 2026

## 13. Provider Subscription Inside Navigator Transitions = iOS Deadlock

**Problem:** Onboarding screen 3 froze on iOS when tapping "Add more from library" or any habit that opened a popup. Android worked fine.

**Root Cause:** `context.watch<RoutineProvider>()` inside a `StatelessWidget` (`_SelectHabitsScreen`) that is rendered during a `Navigator.push` transition. On iOS Impeller, when the provider fires a notification during the push transition, the framework calls `element.markNeedsBuild()` directly on the `StatelessWidget` element, bypassing the parent `StatefulWidget`'s `setState`. This leaves gesture recognizers in a dangling state because Impeller's async animation disposal pipeline can't reconcile the concurrent rebuild + transition.

**Additionally:** `WidgetsBinding.instance.addPostFrameCallback` used to defer `Navigator.push` creates a race condition with Impeller's async animation controller disposal. The pop frees the controller on the next render pass (async), but the post-frame callback fires before that pass completes → the new push encounters a pending-disposal animation → deadlock.

**Rule:** Never use `context.watch` in widgets that can rebuild during Navigator transitions. Use `context.read` (no subscription) for snapshot data. Avoid `addPostFrameCallback` for Navigator operations — prefer `Future.microtask` which fires before the next frame's layout pass.

---

## 14. Nested Navigators Multiply iOS Deadlock Risk

**Problem:** Adding a nested `Navigator(onGenerateRoute: ...)` around `MainScreen` to isolate it from the onboarding lifecycle caused ALL overlay operations (tab switches, popups, route pushes) to freeze on iOS.

**Root Cause:** Impeller's overlay layer manages animation controllers per-Navigator. A nested Navigator creates a second overlay layer that inherits partially from the parent. When the parent Navigator (from `MaterialApp`) processes the onboarding→main widget swap, its animation controller enters pending-disposal state. The child Navigator's overlay layer holds a reference to the parent's scheduled render pass. When `showDialog` inside the child Navigator creates a new route transition, Impeller's overlay manager finds the parent's stale animation registration and deadlocks — waiting for a render pass that will never complete because the parent Navigator's animation is already "done" (widget already swapped).

**Rule:** Do not nest `Navigator` widgets inside `MaterialApp.home` on iOS. The root `MaterialApp` Navigator is sufficient for all overlay needs. If isolation is required, use indexed route management (`Navigator.of(context).pushReplacement`) rather than nesting.

---

## 15. `_controller.text =` in `build()` = Infinite Loop

**Problem:** Number popup (drink water) froze the app on iOS when opened. The `_NumberShell` set `_controller..text = '${_value.toInt()}'` inside its `build()` method.

**Root Cause:** Setting a `TextEditingController.text` during `build()` schedules a microtask that triggers another frame. On iOS Impeller, the synchronous layout pass re-enters `build()` before the batched frame fires, creating `build → set text → schedule → build → ...` infinitely. Android Skia batches differently and breaks the loop.

**Rule:** Never set `TextEditingController.text` in `build()`. Initialize in `initState()`, update in event handlers (`setState` + `_controller.text =`).

---

## 16. Export/Import Must Be Symmetric

**Problem:** Backup/restore said "coming soon" in Settings. After wiring up, settings (language, theme) were lost on ZIP restore.

**Root Cause:** `StorageService.exportData()` returned settings, but `ExportService.exportAll()` (ZIP path) used `ExportData` which had no `settings` field. The JSON export path included them; the ZIP path silently dropped them. Two diverging serialization formats for the same operation.

**Rule:** Export and import must use identical data structures. When adding a field to one export path, update all paths. A `clearAll()` before restore ensures no stale data survives.

---

## 17. Tallies Empty-State Guard Wrong Criterion

**Problem:** Tallies showed no sub-tabs (Habits|Notes) after onboarding.

**Root Cause:** `summary.totalEntries == 0` guard returned early before `DefaultTabController` was built. The Habits tab depends on routine data (streaks, charts), not entry data. The guard's criterion was wrong — it should check routines, not entries.

**Rule:** Empty-state guards must use the correct data source. Check `routines.isEmpty` for habit stats; check `entries.isEmpty` for Notes. Or default to rendering the container and let sub-tabs show their own empty states.

---

## 18. Boolean-Optional Double-Toggle

**Problem:** `boolean_optional_text` habits (Workout, Declutter) would not stay completed — they'd toggle back to uncompleted.

**Root Cause:** `_showBooleanOptionalTextPopup` called `_completeRoutine` (which toggles the habit ON), then if the dialog returned true, called `_completeWithEntry` which ALSO called `toggleComplete` — toggling it back OFF. Two `toggleComplete` calls for the same completion.

**Rule:** Separate "complete the habit" from "create the entry." Use `_completeRoutine` + `_createEntry` (not `_completeWithEntry`) when the habit was already completed before the dialog.

---

## 19. UIPasteboard.hasStrings Blocks iOS Main Thread — Simulator vs Real Device

**Problem:** Text-type habit dialogs (Cook at home, Write a note, Practice gratitude) froze on tap. The entire app became unresponsive when user tapped a text placeholder inside the dialog.

**Root Cause:** Flutter's `EditableText` calls `ClipboardStatusNotifier.update()` → `Clipboard.hasStrings()` → `[UIPasteboard generalPasteboard].hasStrings` on every TextField mount. On iOS, this blocks the main thread while the OS performs a privacy check. On real devices: 200–600ms. On iOS 26 simulator with clipboard content: **indefinitely**.

**Fix:** Three-part solution:
1. `await WidgetsBinding.instance.endOfFrame` before every `showDialog` (prevents dialog-open freeze)
2. FocusNode + `addPostFrameCallback` instead of `autofocus: true` (delays clipboard check until after render)
3. Method channel pre-warm via `stalio/prewarm` in `AppDelegate.didInitializeImplicitFlutterEngine` (warms OS cache at startup, skipped on simulator with `#if !targetEnvironment(simulator)`)

**Key insight:** The iOS 26 simulator infinite block is an **OS simulator bug**, not an app bug. Real iPhones only block for 200–600ms on the first call per session. Old iOS 26 simulators with clipboard content are not useful for testing text-type habits.

**Rule:** Never call `UIPasteboard.hasStrings` from a background thread (corrupts state). Never call it before `super.application(...)` in AppDelegate (blue screen). The only safe non-Dart approach is a method channel handler in `didInitializeImplicitFlutterEngine`, called from Dart via `addPostFrameCallback` after the first frame.

---

## 20. `context.read` in initState() Misses Async Provider Load

**Problem:** Onboarding page 3 and "Add more from library" showed empty habit lists on a real device fresh install.

**Root Cause:** `_habitList = context.read<RoutineProvider>().routines` in `initState()` ran before `loadRoutines()` completed (SQLite seed is async). The `build()` fallback also used `context.read` (not `watch`), so the widget never rebuilt when `notifyListeners()` fired.

**Fix:** Remove the local `_habitList` state variable. Use `context.watch<RoutineProvider>().routines` directly in `build()`. When `loadRoutines()` completes and calls `notifyListeners()`, the widget rebuilds automatically with the full list.

**Rule:** If a widget needs provider data that may not be loaded when `initState()` runs, always use `context.watch` in `build()` rather than caching the value in `initState()` with `context.read`. `context.read` is a snapshot; `context.watch` reacts to changes.

---

## 21. `showDialogDeferred` — Centralise the endOfFrame Pattern

**Problem:** `await WidgetsBinding.instance.endOfFrame` + `if (!context.mounted) return;` was copy-pasted before every `showDialog` call across 10 popup functions. Each copy was a potential mistake (forgetting one, or writing the mounted check on the wrong variable).

**Fix:** Extract into a single utility:
```dart
Future<T?> showDialogDeferred<T>(BuildContext context, {required WidgetBuilder builder, ...}) async {
  await WidgetsBinding.instance.endOfFrame;
  if (!context.mounted) return null;
  return showDialog<T>(context: context, builder: builder);
}
```

**Rule:** Any pattern that must be applied consistently at every call site belongs in a utility, not repeated inline. One-liner call sites are also easier to lint/audit.

---

## 22. `TabController` in `build()` Recreated on Every Rebuild

**Problem:** `DefaultTabController` placed inside `build()` creates a new controller on every `SummaryProvider` notification. On iOS, a notification during a tab-switch animation caused the controller to be reconciled mid-animation, leaving `TabBarView` in an inconsistent state.

**Fix:** Move to `initState()` with `SingleTickerProviderStateMixin`:
```dart
class _InsightsContentState extends State<_InsightsContent>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  ...
}
```

**Rule:** `TabController` and any animation controller should always live in `initState`, not `build`. `DefaultTabController` in `build` is convenient but breaks under frequent rebuilds.

---

## 23. Fire-and-Forget `async void` Hides Exceptions and Misses Mount Guards

**Problem:** `_createEntry` was declared `void` (implicitly async void). Calling it fire-and-forget from `_completeWithEntry` meant: (a) exceptions were swallowed silently, (b) `context.mounted` was never checked after `await _resolveHabitTags`, (c) the test's missing `TagProvider` was never discovered because the error happened after test teardown.

**Fix:** `Future<void> _createEntry(...)`, add `if (!context.mounted) return;` after the await, and `await _createEntry(...)` in the caller. The test failure that surfaced exposed a real missing provider in the test setup.

**Rule:** Never write `void` async functions that use `BuildContext`. Always `Future<void>` so callers can await, exceptions propagate, and `mounted` checks are enforceable by lint.

---

## 24. `use_build_context_synchronously` Lint Catches the Whole Bug Class

**Problem:** Every iOS freeze in this codebase traced back to `context` being used after an `await` without a `mounted` check — but this was invisible until runtime on a device.

**Fix:** Enable in `analysis_options.yaml`:
```yaml
linter:
  rules:
    use_build_context_synchronously: true
```

12 violations found across `routine_screen.dart` and `settings_screen.dart`. All fixed. Now any new violation is a compile-time warning.

**Rule:** Enable `use_build_context_synchronously` from project inception. It turns an entire class of iOS-specific runtime crashes into static analysis warnings. The cost is minor (a few `mounted` guards); the benefit is large (no more silent iOS freezes from async context use).

---

## 25. Mixing `context` and `ctx` in the Same Async Function Defeats Mounted Guards

**Problem:** `_restoreFromBackup(BuildContext ctx)` checked `ctx.mounted` but then called `context.read<StorageService>()` (using `this.context` of the State). The lint flagged these as "guarded by an unrelated `mounted` check" because `ctx` and `context` are different variables, even if they refer to the same element.

**Fix:** Use one context variable consistently. Inside a method that receives `BuildContext ctx`, use `ctx` for everything. Only use `this.context` for reads that happen before any await.

**Rule:** In async methods that receive a `BuildContext` parameter, use that parameter exclusively. Never mix `ctx` and `context` — the lint (and future readers) cannot tell they're the same element, and a refactor could make them genuinely different.
