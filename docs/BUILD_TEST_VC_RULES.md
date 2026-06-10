# Stalio — Build, Test & Version Control Rules

> **Version:** 1.0.0 | **Date:** June 10, 2026  
> **Repo:** `https://github.com/justinzero888/stalio.git`  
> **References:** `dev-cycle-playbook.md`, `dev-test-collaboration.md`, `DEVELOPER-PLAYBOOK.md`

---

## 1. Build Rules

### 1.1 Pre-Commit Gate

Every commit must pass before push:

| Check | Command | Standard |
|-------|---------|----------|
| Static analysis | `flutter analyze --no-pub` | 0 errors |
| All tests | `flutter test` | All pass, no regressions |
| Line count sanity | `wc -l lib/screens/cherished/cherished_memory_screen.dart` | Must match expected (1609) |

### 1.2 Build Commands

```bash
# Development (debug)
flutter run                      # Launch on connected device
flutter run -d <device-id>       # Launch on specific device

# Testing on simulators
flutter test                     # Unit + widget + integration
flutter test test/<path>/        # Specific test directory

# Production builds
flutter build apk --release      # Android APK
flutter build appbundle          # Android AAB (Play Store)
flutter build ios --release      # iOS IPA (App Store)
```

### 1.3 Build Notification Protocol

Per `dev-test-collaboration.md` §1: After every push, post in the shared channel:

```
🔨 Build ready — commit <hash>
   Files: <changed files>
   What: <feature/fix description>
   Tests: <count> pass | analyze: 0 errors
   Sims: iPhone 17 Pro ✅ | iPad Air M4 ✅ | Android ✅
```

### 1.4 Simulator Management

```bash
# Boot sims sequentially (iOS sims can't boot concurrently)
xcrun simctl boot <iphone-uuid> && xcrun simctl bootstatus <iphone-uuid> -b
xcrun simctl boot <ipad-uuid> && xcrun simctl bootstatus <ipad-uuid> -b
nohup emulator -avd <avd-name> -no-snapshot-load -no-boot-anim &

# Install on all three
xcrun simctl install <iphone-uuid> build/ios/iphonesimulator/Runner.app
xcrun simctl install <ipad-uuid> build/ios/iphonesimulator/Runner.app
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk
```

### 1.5 Dependency Management

```bash
flutter pub get                  # Install dependencies
flutter pub outdated             # Check for updates
flutter pub upgrade              # Upgrade all (test before committing)
```

---

## 2. Test Rules

### 2.1 Test Categories

| Category | Directory | Run Command | When |
|----------|-----------|-------------|------|
| Unit (models) | `test/models/` | `flutter test test/models/` | Every commit |
| Unit (providers) | `test/providers/` | `flutter test test/providers/` | Every commit |
| Unit (core) | `test/core/` | `flutter test test/core/` | Every commit |
| Widget (screens) | `test/screens/` | `flutter test test/screens/` | Every commit |
| Integration | `test/integration/` | `flutter test test/integration/` | Schema changes |
| L10n audit | `test/l10n/` | `flutter test test/l10n/` | After UI string changes |
| Widget smoke | `test/widgets/` | `flutter test test/widgets/` | Pre-release |
| Maestro UAT | `test/maestro/` | `maestro test test/maestro/*.yaml` | Pre-handoff to test agent |

### 2.2 Test Gate Sequence

```
Gate 1 (CI):  flutter analyze → flutter test → all pass
Gate 2 (Sim): Install on 3 sims → smoke check each
Gate 3 (UAT): Maestro flows → manual checklist → release artifacts
```

### 2.3 Test Count Baseline

| Phase | Baseline Tests | New Tests | Total |
|-------|---------------|-----------|-------|
| Phase 3 | 253 | 0 | 253 |
| Phase 4 | 253 | 67 | 320 |
| Phase 5+ | 320 | TBD | TBD |

**Rule:** Never reduce the test count. Any regression that reduces test count must be explained in the commit message.

### 2.4 Severity Classification (for UAT Defects)

| Severity | Symptom | Dev SLA |
|----------|---------|---------|
| **P0-human** | App crash, blank screen, data loss | Drop everything |
| **P1-human** | Feature broken for all input methods | Fix before release |
| **P2-automation** | Works with finger tap, fails with accessibility tap | Batch at EOD |
| **P3-cosmetic** | Visual misalignment only | Defer to next release |

### 2.5 Bug Report Format

Per `dev-test-collaboration.md` §2:

```
Title: <ID> — <one-line description>
Platform: iPhone 17 Pro / iPad Air M4 / Android
Flow: <maestro flow name>
Commit tested: <hash>
Steps: (numbered, with ✅/❌ per step)
Evidence:
- Screenshot at failure point
- Maestro hierarchy dump
- Video (if available)
Suspect: <file:line>
```

---

## 3. Version Control Rules

### 3.1 Branch Strategy

```
main           ← production-ready, protected
├── feature/*  ← feature branches (e.g., feature/tag-categories)
├── fix/*      ← bug fix branches (e.g., fix/DEF-V-001)
└── release/*  ← release preparation branches
```

### 3.2 Commit Convention

```
<type>: <short description>

<detailed body explaining WHAT and WHY>

Files: <key files changed>
Tests: <count> pass | analyze: 0 errors
```

**Types:** `feat`, `fix`, `refactor`, `test`, `docs`, `chore`

### 3.3 Commit Frequency

- Commit after every completed work item (not mid-work)
- Atomic commits: one logical change per commit
- Never commit broken code (analyze + test must pass)

### 3.4 Tagging

```bash
git tag -a v1.0.0 -m "Phase 4: Feature Expansion complete"
git push --tags
```

**Tags:** Semantic versioning (`v<major>.<minor>.<patch>`)

### 3.5 Push Rules

- Push only after `flutter analyze` + `flutter test` pass
- Never push secrets (API keys, tokens, credentials)
- Use `.gitignore` for build artifacts, IDE files, local config
- After pushing, post build notification in shared channel

### 3.6 File Safety Rules

| Rule | Applies To | Reason |
|------|-----------|--------|
| **sed only** | `cherished_memory_screen.dart` (1609 lines) | Repeating code patterns corrupt `replaceAll` |
| Line count check | After every edit | `wc -l` sanity check |
| `safe-rollback` tag | After successful change | Quick recovery point |
| Split at 1000 lines | All files | Prevents edit tool corruption |
| Public for cross-file | Private classes used across files | Make public |

### 3.7 Secrets Management

**Never commit:**
- API keys (OpenRouter, AdMob, RevenueCat, Google, Apple)
- Private keys (.pem, .jks, .keystore)
- Service account credentials
- OAuth client secrets
- Personal access tokens

**Use environment variables or secure storage:**
```dart
// ✅ Correct
final apiKey = const String.fromEnvironment('API_KEY');

// ❌ Never
final apiKey = 'sk-or-v1-abc123...';
```

### 3.8 `.gitignore` Requirements

Must exclude:
- `build/`, `.dart_tool/`, `.pub-cache/`
- `.idea/`, `*.iml`, `.vscode/`
- `*.pem`, `*.jks`, `*.keystore`
- `google-services.json`, `GoogleService-Info.plist`
- Any file containing secrets

### 3.9 Protected Branches

`main` branch must have:
- Require pull request before merging
- Require status checks: `flutter analyze` + `flutter test`
- Require branch to be up to date
- Block force pushes (except for emergency history rewrites)

---

## 4. CI/CD Pipeline (Recommended Additions)

### 4.1 GitHub Actions Workflow

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]
jobs:
  analyze-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter analyze --no-pub
      - run: flutter test
```

### 4.2 Pre-Commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit
flutter analyze --no-pub || exit 1
flutter test || exit 1
```

---

## 5. Document References

| Document | Location | Purpose |
|----------|----------|---------|
| Test Plan | `docs/STALIO_TEST_PLAN.md` | Full test infrastructure reference |
| UAT Checklist | `docs/UAT_PHASE4.md` | Manual UAT test cases |
| Lesson Learned | `lesson_learned_06_10.md` | DB migration checklist |
| Work Items | `works_item_0610.md` | Phase 4 breakdown |
| Implementation Plan | `IMPLEMENTATION_PLAN.md` | Architecture decisions |

---

## Appendix — Quick Reference

```bash
# Before every commit
flutter analyze --no-pub && flutter test

# Before push
git status && flutter analyze --no-pub && flutter test

# Build notification (post in shared channel)
echo "🔨 Build ready — commit $(git rev-parse --short HEAD)" && echo "   Tests: $(flutter test 2>&1 | grep -oP '\d+(?=:) tests' | tail -1) pass"

# File line count sanity
wc -l lib/screens/cherished/cherished_memory_screen.dart

# Check for secrets before commit
git diff --cached | grep -E 'sk-[or]-|api[_-]?key|secret[_-]?key|token' || echo "No secrets found"
```
