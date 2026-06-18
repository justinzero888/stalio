# RCA: iOS Onboarding Buttons Unresponsive

**Date:** June 15, 2026  
**Severity:** Critical (blocked iOS onboarding)  
**Status:** Resolved

---

## Symptom

On iPhone and iPad simulators, the onboarding flow's "Add more from library" and "Start Tracking" buttons did not respond to taps. Screen 1 ("Get Started") and Screen 2 ("Select Your Habits") worked. Screen 3 was completely unresponsive. Android worked correctly throughout.

Additionally, after the onboarding fix, tapping a `number`-type habit (e.g., "Drink water") caused the app to freeze due to an infinite rebuild loop in the number popup dialog.

---

## Timeline of Attempts

| Attempt | Approach | Result |
|---------|----------|--------|
| 1 | `PageView` + `NeverScrollableScrollPhysics` | iOS: all screen 3 buttons dead |
| 2 | `Navigator.of(context, rootNavigator: true).push()` | No change |
| 3 | `showModalBottomSheet` replacing Navigator | No change |
| 4 | `AnimatedSwitcher` + `KeyedSubtree` | No change |
| 5 | `IndexedStack` (no animation, no Scaffold) | Black background, still no change |
| 6 | **Route-based push from `initState` + `addPostFrameCallback`** | **Resolved** |

---

## Root Cause

### Primary: iOS Impeller cannot reconcile animated children inside `MaterialApp.home`

The `OnboardingFlow` widget was rendered as the `home` property of `MaterialApp` via a `_OnboardingGate` wrapper that used `setState` to swap between `OnboardingFlow` and `MainScreen` in `build()`.

On iOS (Impeller rendering engine), when a `StatefulWidget` at the root of the `MaterialApp.home` subtree calls `setState` and returns a different widget tree, Impeller enters a transitional state where child gesture recognizers are not properly attached. This is specific to how Impeller handles route transitions vs. in-place widget swaps.

Flutter's `MaterialApp.home` internally creates a `_WidgetsAppState` route. When the home widget is swapped via `setState`, the framework attempts a widget reconciliation pass. On Android (Skia), this reconciliation correctly transfers gesture arena state to the new widget tree. On iOS (Impeller), the reconciliation leaves the new widget tree in a state where `HitTestBehavior` is not propagated, causing all `onPressed` callbacks to silently fail.

### Secondary: `_controller.text` set in `build()` causes infinite loop on iOS

The number popup (`_NumberShell`) set `_controller..text = '${_value.toInt()}'` inside the `build()` method. Setting a `TextEditingController`'s `text` property during build schedules a microtask that triggers a new frame. This created an infinite loop: `build → set text → schedule frame → build → ...`  
On Android (Skia), this loop is broken by the async scheduler batching. On iOS (Impeller), the synchronous layout pass re-enters `build()` before the batched frame fires, causing an unbounded loop that freezes the UI thread.

### Tertiary: `showModalBottomSheet` called during frame build on iOS

`_openHabitLibrary()` called `showModalBottomSheet` inline from the `onPressed` callback. On Android, the Navigator resolves correctly. On iOS, when the parent widget is mid-rebuild (because `onPressed` triggered `setState` which cascades through `MaterialApp.home`), the Navigator returned by `Navigator.of(context)` is the same Navigator that is currently executing a route transition, causing the bottom sheet to open behind the current route or to be invisible.

---

## Solution

### 1. Route-based onboarding (replaces widget swap)

```dart
// BEFORE: widget swap in build()
class _OnboardingGateState extends State<_OnboardingGate> {
  late bool _onboardingComplete;

  Widget build(BuildContext context) {
    if (!_onboardingComplete) return OnboardingFlow(...);
    return const MainScreen();
  }
}

// AFTER: route push from initState
class _OnboardingGateState extends State<_OnboardingGate> {
  void initState() {
    super.initState();
    if (!widget.storageService.isOnboardingComplete()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => OnboardingFlow(
            onComplete: () {
              widget.storageService.setOnboardingComplete(true);
              Navigator.of(context).pop();
            },
          )),
        );
      });
    }
  }

  Widget build(BuildContext context) {
    return const MainScreen(); // always renders
  }
}
```

**Why this works:** The onboarding is pushed as a proper `MaterialPageRoute` via the Navigator. Route transitions are fully handled by the framework with correct gesture arena lifecycle on both platforms. The `home` widget never changes — `MainScreen` is always the root, eliminating Impeller's widget swap reconciliation issue.

### 2. Controller text set in `initState`, not `build()`

```dart
// BEFORE
Widget build(...) {
  ...
  controller: _controller..text = '${_value.toInt()}',  // infinite loop
}

// AFTER
void initState() {
  super.initState();
  _controller.text = _value.toInt().toString();  // set once
}

void _updateValue(double newValue) {
  setState(() {
    _value = newValue;
    _controller.text = newValue.toInt().toString();  // sync on change
  });
}
```

### 3. Bottom sheet deferred to next frame

```dart
void _openHabitLibrary() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    showModalBottomSheet(context: context, ...);
  });
}
```

---

## Key Lesson

**Never swap `MaterialApp.home` in a `setState`-driven `build()` on iOS.** Always use `Navigator.push` for screen transitions. The `home` property of `MaterialApp` should be a stable widget that doesn't change identity.

| Pattern | Android | iOS Impeller | Safe? |
|---------|---------|-------------|-------|
| `setState` swap in `home.build()` | Works | Silent failure | No |
| `Navigator.push` from `initState` | Works | Works | Yes |
| `Navigator.push` from button callback | Works | Works | Yes |

---

## Files Changed

| File | Change |
|------|--------|
| `lib/app.dart` | `_OnboardingGate` rewritten: route push from `initState`, always renders `MainScreen` |
| `lib/screens/onboarding/onboarding_flow.dart` | Removed `AnimatedSwitcher`/`IndexedStack`, `onComplete` now pops route, `_openHabitLibrary` deferred to next frame |
| `lib/widgets/habit_popups/habit_popup_factory.dart` | `_NumberShell` controller text init moved from `build()` to `initState()` |
