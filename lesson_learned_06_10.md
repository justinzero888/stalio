# Lessons Learned — June 10, 2026

## 1. iOS Store Submission: The Hidden Dependency Trap

**Problem:** App crashed on iPad launch (TestFlight build #1). Apple rejected build #1 with missing `NSPhotoLibraryUsageDescription`.

**Root Cause:** Adding `google_mobile_ads` to `pubspec.yaml` causes the native SDK to register at startup via `GeneratedPluginRegistrant`, even with zero Dart imports. The SDK crashes immediately if `GADApplicationIdentifier` is missing from `Info.plist`. Additionally, `file_picker` and `share_plus` trigger `NSPhotoLibraryUsageDescription` requirements even if the Dart code doesn't use photo features.

**Rule:** **Any new plugin added to pubspec.yaml must be matched with its iOS Info.plist requirements AND Android manifest permissions immediately** — before building. Native plugins initialize at launch, not at first use.

**Checklist before iOS build:**
```
[ ] Every plugin in pubspec.yaml has its Info.plist keys
[ ] Privacy usage descriptions: PhotoLibrary, Microphone, Camera, Location
[ ] AdMob: GADApplicationIdentifier + SKAdNetworkItems
[ ] Encryption: ITSAppUsesNonExemptEncryption
```

---

## 2. CI Pipeline: Version Mismatch Hides in Plain Sight

**Problem:** 6 consecutive CI workflow runs failed on `flutter pub get`.

**Root Cause:** `pubspec.yaml` required Dart SDK `^3.11.0` (from local Flutter 3.44.x) but CI workflow specified Flutter `3.32.x` which ships Dart `3.8.1`. The constraint mismatch only surfaced in CI.

**Rule:** **CI Flutter version MUST match the local dev Flutter version.** After upgrading Flutter locally, update `.github/workflows/ci.yml` immediately.

**Second CI failure:** Flutter 3.44.x treats analyzer warnings as fatal by default (exit code 1), unlike local 3.32.x. The `--no-fatal-warnings` flag was not honored. Fixed with grep-based error detection.

---

## 3. Bundle ID Unification: Do It Before Store Setup

**Problem:** Android used `com.microhabits.micro_habits` (snake_case) while iOS used `com.microhabits.microHabits` (camelCase) — inconsistent from two separate rename passes.

**Root Cause:** The app went through Blinking → Micro Habits → Stalio renames. Each rename touched different platforms at different times, leaving inconsistent IDs.

**Fix:** Unified to `com.orbacetech.stalio` across all platforms (17 files). Changed BEFORE any store submission — trivial since no store listing existed yet. Would have been impossible after first store upload.

**Rule:** **Unify bundle IDs across platforms before any store submission.** After first upload, the bundle ID is permanent.

---

## 4. Git History: Secrets Survive Deletion

**Problem:** GitHub push protection blocked the initial push — an OpenRouter API key existed in git history from a file deleted months ago.

**Root Cause:** `git rm` removes from working tree but the old commit still contains the secret. GitHub scans ALL commits, not just HEAD.

**Fix:** Used `git filter-branch --tree-filter` with sed to replace the key with a placeholder across all commits. Then force-pushed. Deleted old tags that still pointed to pre-cleanup commits.

**Rule:** **Never commit API keys. Period.** If one is committed by accident, use `git filter-branch` or `BFG Repo-Cleaner` to purge it from the entire history. GitHub push protection catches this at push time — fix before fighting it.

---

## 5. Android AAB Signing: Debug ≠ Release

**Problem:** AAB was signed with debug keystore. Google Play Console rejects debug-signed AABs.

**Root Cause:** `build.gradle.kts` defaulted to `signingConfigs.getByName("debug")` for the release build type. The TODO comment ("// TODO: Add your own signing config") was never addressed.

**Fix:** Generated RSA 2048-bit keystore, created `android/key.properties`, updated `build.gradle.kts` to read signing config from properties, added keystore + key.properties to `.gitignore`.

**Rule:** **Generate the release keystore immediately after creating the project.** Back it up outside the repo. If lost, the app cannot be updated on Google Play.

---

## 6. DB Migration Checklist (from lesson_learned_06_10.md)

When adding a new table or column, follow this order strictly:

| Step | What | Where |
|------|------|-------|
| 1 | Update model (`toJson`, `fromJson`, `copyWith`) | `lib/models/*.dart` |
| 2 | Update storage read mapper | `storage_service.dart` `get*()` |
| 3 | Update storage write | `storage_service.dart` `add*()` / `update*()` |
| 4 | Update `_onCreate` (version-gated) | `database_service.dart` |
| 5 | Add `_onUpgrade` block | `database_service.dart` |
| 6 | Bump `kSchemaVersion` | `database_service.dart` |
| 7 | Update test infra defaults | `createTestDatabase` → `kSchemaVersion` |
| 8 | Update `runMigration` target | → `kSchemaVersion` |
| 9 | Update version test | `test/core/db_version_test.dart` |
| 10 | Update test mocks | All `_MockStorageService` classes |

**Invariants that must stay in sync:** `createTestDatabase` default, `runMigration` target, `db_version_test.dart` assertion — all must reference `kSchemaVersion`, never a hardcoded number.

---

## 7. `git checkout -- file` is Dangerous

**Problem:** Running `git checkout -- lib/screens/settings/settings_screen.dart` reverted ALL Phase 3-4 changes (Days 3, 4, 7, 8) to that file — ~900 lines of lost work.

**Root Cause:** The checkout command reverts to the last committed state. Since no commits had been made during the session, it reverted to the pre-Phase 3 state.

**Fix:** Had to re-apply 4 days of changes manually. Lesson: **commit after every completed work item.** Atomic commits are cheap; manually rewriting lost code is not.

**Rule:** Commit after each day's work. Never leave uncommitted changes that span multiple features.
