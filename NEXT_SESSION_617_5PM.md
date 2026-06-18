# Next Session — iOS Freeze Fixes (resumed 2026-06-17)

## What's Working Now ✅
- **"Add more from library"** — no freeze on library open (tap-to-activate search + single Scaffold)
- **"Drink water" / number-type habits** — no freeze on dialog open (endOfFrame + tap-to-activate number display)
- **"Workout" / booleanOptionalText** — dialog opens without freeze (moved _completeRoutine to AFTER dialog)
- **All other dialog types** — opening freeze fixed with endOfFrame before showDialog

## Still Broken ❌

### "Cook at home" (booleanOptionalText) and "Write a note" (textRequired)
**Root cause:** Dialog opens fine. Freeze happens when user **taps the text placeholder** to activate the TextField. Mounting `TextField(autofocus: true)` fires `EditableText.didChangeDependencies()` → `Clipboard.hasStrings()` → `[UIPasteboard generalPasteboard].hasStrings` → blocks iOS main thread 200–600 ms.

This is the same root cause as always, just deferred to the user's first tap inside the dialog instead of dialog-open.

### Android onboarding not shown
Android SharedPreferences not cleared during tests. Not yet investigated.

---

## Approaches Tried for Tap Freeze (All Failed This Session)

| Approach | Result |
|---|---|
| `Clipboard.hasStrings()` in `main()` before `runApp()` | Blue screen — channel not ready |
| `Clipboard.hasStrings()` in `addPostFrameCallback` in `_MainScreenState` | Blue screen — unknown runtime crash |
| `DispatchQueue.global(background).async { UIPasteboard.general.hasStrings }` in AppDelegate | TextFields greyed out — UIPasteboard not thread-safe, corrupted state |
| `DispatchQueue.main.asyncAfter(1.0) { UIPasteboard.general.hasStrings }` in AppDelegate | Blue screen on iPhone, no habits on iPad |

**Current state:** All AppDelegate / Dart clipboard changes reverted. App is in working state (dialog opens fine, tap still freezes).

---

## Recommended Fix for Next Session

### Try First: Synchronous pre-warm in didFinishLaunchingWithOptions BEFORE super

```swift
// AppDelegate.swift
override func application(_ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Block 200-600ms HERE while launch screen is showing — invisible to user.
    // Caches the UIPasteboard privacy check so all TextField mounts are instant.
    _ = UIPasteboard.general.hasStrings
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
}
```

Key difference from what failed: **synchronous** (no async), **before `super`** (before Flutter starts), **main thread** (thread-safe). The launch screen covers the delay.

### If That Fails: Check Flutter version
```
flutter --version
```
Flutter 3.13+ has a fix where `Clipboard.hasStrings()` is only called when the field is focused, not on every mount. Upgrading could eliminate the issue entirely.

### Fallback: Native method swizzle to no-op hasStrings
Swizzle `[UIPasteboard generalPasteboard].hasStrings` in Swift to return a cached value immediately after the first real call.

---

## Files Changed This Session (all in working build)

**Keep these:**
- `lib/widgets/habit_popups/habit_popup_factory.dart` — endOfFrame + tap-to-activate + booleanOptionalText post-dialog completion
- `lib/screens/onboarding/onboarding_flow.dart` — single Scaffold, tap-to-activate library search
- `lib/widgets/routine_note_dialog.dart` — (dead code, safe to delete)
- `test/screens/onboarding_flow_test.dart` — updated for tap-to-activate search bar

**Already reverted:**
- `ios/Runner/AppDelegate.swift` — clipboard pre-warm removed
- `lib/main.dart` — clipboard pre-warm removed  
- `lib/app.dart` — clipboard pre-warm removed

---

## Key Lessons Learned This Session

1. **UIPasteboard is NOT thread-safe** — never call from background thread; corrupts pasteboard state and breaks all TextFields.
2. **Platform channels not ready before `runApp()`** — `Clipboard.hasStrings()` in `main()` before `runApp()` crashes (blue screen).
3. **`asyncAfter` in AppDelegate interferes with Flutter startup** — even 1-second delayed main-thread dispatch caused Flutter rendering failures.
4. **The fix pattern for dialog-open freeze:** `await endOfFrame` before `showDialog` (not in dialog builder, not in `addPostFrameCallback` on dialog open).
5. **The fix pattern for tap-activate freeze:** still unsolved — needs UIPasteboard pre-warm at the right time/thread.
6. **`_completeRoutine` before `showDialog` for booleanOptionalText** was causing a SummaryProvider cascade that made `endOfFrame` insufficient — moving it after the dialog fixed it.
