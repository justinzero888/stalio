# Stalio — Phase 5 Infrastructure & Automation Plan

> **Date:** June 10, 2026  
> **Pre-requisite:** Phase 4 sign-off  
> **Est. Effort:** 8–12 days  
> **References:** `GAP_ANALYSIS.md`, `works_item_0610.md`, `dev-cycle-playbook.md`

---

## 0. Phase 5 Overview

Phase 5 bridges the 13 gaps identified in `GAP_ANALYSIS.md` and completes the pre-work items from `works_item_0610.md` §5 (AdMob/IAP setup). It moves Stalio from manual dev workflow to automated CI/CD pipeline.

**Two tracks run in parallel:**
- **Track A (Dev):** Infrastructure & automation — CI/CD, builds protocol, pre-commit hooks, code cleanup
- **Track B (Business):** Store setup — AdMob, IAP products, Privacy Policy, store listings

Track B is a hard blocker for Phase 5 Item 13 (AdMob integration).

---

## 1. Track A — Infrastructure & Automation (Dev Team)

### Item 12: AI Dead Code Cleanup & Schema Audit `[Priority #1]`

**Status:** ✅ Complete (June 10)
**What was done:**
- Deleted `soft_prompt_service.dart`, `chorus_service.dart`, `post_to_chorus_sheet.dart`
- Removed "Post to Chorus" button from `entry_detail_screen.dart`
- Verified 320 tests pass, 0 analysis errors

**What remains (Phase 6):**
- DB schema cleanup: `ai_identity`, `lens_sets`, `active_lens_set`, `ai_call_log`, `ai_summary` tables — these exist in production DBs and can't be dropped without migration impact. Recommended approach: add `DROP TABLE IF EXISTS` migration in Phase 6 schema cleanup, with test verifying rollback safety.

### Item 13: RevenueCat / Purchases Cleanup `[Priority #2]`

**Files to modify/delete:**
- `lib/core/services/purchases_service.dart` — delete (still calls `blinkingchorus.com`, logs but no crash)
- `lib/core/services/entitlement_service.dart` — delete (BYOK code, references `blinkingchorus.com`)
- `lib/screens/purchase/paywall_screen.dart` — delete (navigates to deleted purchases)
- `lib/screens/onboarding/transition_screen.dart` — delete (dead code, navigates to deleted paywall)
- `lib/app.dart` — remove `PurchasesService` from provider tree
- `pubspec.yaml` — remove `purchases_flutter` dependency

**Acceptance criteria:**
- [ ] All 320 tests still pass
- [ ] `flutter analyze` 0 errors
- [ ] No references to `blinkingchorus.com` remain in codebase
- [ ] No references to `PurchasesService` or `EntitlementService` in imports

**Effort:** 1 day

### Item 14: CI/CD Pipeline `[Priority #3]`

**Files to create:**
- `.github/workflows/ci.yml` — analyze + test on push/PR

```yaml
name: CI
on: [push, pull_request]
jobs:
  analyze-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.32.x'
          channel: 'stable'
      - run: flutter pub get
      - run: flutter analyze --no-pub
      - run: flutter test
```

**Repository settings (requires admin access):**
- Branch protection on `main`: require `analyze-and-test` status check
- Block force pushes on `main`
- Require PR before merging to `main`

**Acceptance criteria:**
- [ ] `flutter analyze` passes in CI (green check)
- [ ] `flutter test` passes in CI (320 tests, green check)
- [ ] PR to main is blocked when checks are red

**Effort:** 2 hours (dev) + 30 min (admin settings)

### Item 15: Pre-Commit Hooks `[Priority #4]`

**Files to create:**
- `scripts/pre-commit.sh` — analyze + test + secret scan

```bash
#!/bin/bash
set -e
echo "🔍 Stalio pre-commit check..."
flutter analyze --no-pub || { echo "❌ Analyze failed"; exit 1; }
flutter test || { echo "❌ Tests failed"; exit 1; }
# Secret scan
if git diff --cached | grep -qE 'sk-[or]-[a-zA-Z0-9]{20,}'; then
  echo "❌ SECRET DETECTED — push blocked"
  exit 1
fi
echo "✅ All checks passed"
```

**Installation:**
```bash
cp scripts/pre-commit.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

**Acceptance criteria:**
- [ ] Commit blocked when analysis fails
- [ ] Commit blocked when tests fail
- [ ] Commit blocked when API key pattern detected

**Effort:** 30 minutes

### Item 16: Builds Protocol `[Priority #5]`

**Files to create:**
- `.builds/current.json` — schema: `{ commit, files_changed, sim_status, built_at }`
- `.builds/results.json` — schema: `{ passed, failed, flows, platforms, timestamp }`
- `.builds/state.json` — schema: `{ phase, defects[] }`
- `.builds/DASHBOARD.md` — auto-generated from state.json
- `scripts/publish-build.sh` — dev publishes build metadata
- `scripts/publish-results.sh` — test agent publishes results

**Workflow:**

```
Dev pushes code → runs publish-build.sh → writes current.json
Test agent polls current.json → detects new commit → runs Maestro
Test agent runs publish-results.sh → writes results.json + state.json
Dev polls results.json → fixes failures → repeats
```

**Acceptance criteria:**
- [ ] `publish-build.sh` writes valid `current.json`
- [ ] `DASHBOARD.md` auto-generates with Ship Gate status
- [ ] Test agent can detect new builds from `current.json`

**Effort:** 4 hours

### Item 17: Environment Configuration `[Priority #6]`

**Files to create/modify:**
- `lib/core/config/environment.dart` — environment enum + config
- `.env.example` — template for required env vars

```dart
enum Environment { development, staging, production }

class EnvConfig {
  final Environment environment;
  final String appName;
  final String bundleId;
  final String adMobAppId;
  final String adMobBannerUnitId;

  const EnvConfig({
    required this.environment,
    required this.appName,
    required this.bundleId,
    this.adMobAppId = '',
    this.adMobBannerUnitId = '',
  });

  static EnvConfig fromEnvironment() {
    const env = String.fromEnvironment('ENV', defaultValue: 'development');
    // ... map to config
  }
}
```

**Acceptance criteria:**
- [ ] Dev, staging, production environments are distinct
- [ ] API keys loaded from `--dart-define` flags, not hardcoded
- [ ] `.env.example` documents all required variables

**Effort:** 2 hours

### Item 18: Code Coverage Baseline `[Priority #7]`

**Add to CI workflow:**
```yaml
- run: flutter test --coverage
- uses: coverallsapp/github-action@v2
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
```

**Acceptance criteria:**
- [ ] Coverage report generated per commit
- [ ] Coverage percentage displayed in CI output
- [ ] 70% minimum line coverage target set

**Effort:** 1 hour

### Item 19: Dependabot Configuration `[Priority #8]`

**Files to create:**
- `.github/dependabot.yml`

```yaml
version: 2
updates:
  - package-ecosystem: "pub"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
```

**Acceptance criteria:**
- [ ] Dependabot opens PRs for Flutter/Dart dependency updates
- [ ] Security alerts enabled in GitHub repo settings

**Effort:** 30 minutes (dev) + 5 minutes (enable in GitHub settings)

---

## 2. Track B — Store & Ad Setup (Business Owner)

### Pre-Work: AdMob + IAP Accounts

Per `works_item_0610.md` §5 and `EXTERNAL_SETUP_GUIDE.md`, these MUST be complete before Phase 5 Items 12–14 (AdMob integration, IAP paywall replacement). These have **1–7 day lead times** and **block Phase 5 start**.

| # | Task | Owner | Lead Time | Blocking |
|---|------|-------|-----------|----------|
| B-1 | Create Google AdMob account | Business | 1 day | AdMob integration |
| B-2 | Provision AdMob ad units (banner + interstitial) | Business | 2 days | AdMob integration |
| B-3 | Obtain AdMob App ID + Ad Unit IDs | Business | After B-2 | Handoff to dev |
| B-4 | Google Play Console: activate Merchant account | Business | 3–7 days | `remove_ads` IAP |
| B-5 | Create `remove_ads` IAP product in Google Play Console | Business | After B-4 | IAP integration |
| B-6 | App Store Connect: sign Paid Apps agreement | Business | 3–7 days | `remove_ads` IAP |
| B-7 | Create `remove_ads` IAP product in App Store Connect | Business | After B-6 | IAP integration |
| B-8 | Host Privacy Policy URL (with AdMob disclosure) | Business | 1 day | Store submission |
| B-9 | Provide Privacy Policy URL to dev team | Business | After B-8 | `pubspec.yaml` / app metadata |
| B-10 | Create app store listing assets (screenshots, description) | Business | 3 days | Store submission |

### Business Owner Handoff Package

Dev team needs the following from business owner before starting AdMob/IAP work:

```
AdMob:
  - App ID (iOS):     ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY
  - App ID (Android): ca-app-pub-XXXXXXXXXXXXXXXX~ZZZZZZZZZZ
  - Banner Unit ID (iOS):     ca-app-pub-XXXXXXXXXXXXXXXX/BBBBBBBBBB
  - Banner Unit ID (Android): ca-app-pub-XXXXXXXXXXXXXXXX/CCCCCCCCCC

IAP:
  - Google Play `remove_ads` product ID:  _______________
  - App Store `remove_ads` product ID:    _______________

Legal:
  - Privacy Policy URL:  _________________________________
  - Terms of Service URL: _________________________________
```

### Decision Needed from Business Owner

| Question | Options | Recommendation |
|----------|---------|----------------|
| Should AI-related DB tables be dropped in Phase 6? | Yes / No / Defer | Yes — they're dead code. Drop via migration with rollback test. |
| Should `purchases_service.dart` be fully deleted or replaced? | Delete / Replace with AdMob-only | Delete — Phase 5 replaces with AdMob banner + `remove_ads` IAP. |
| AdMob ad format preference? | Banner only / Banner + Interstitial / Native | Start with banner on Settings/My Day. Add interstitial later. |
| `remove_ads` IAP price tier? | $2.99 / $4.99 / Other | $2.99 (Tier 1) recommended for habit-tracking apps. |
| GitHub repo: public or private? | Public / Private | Currently private. Keep private until store launch. |

---

## 3. Phase 5 Task Breakdown

### Week 7 (Days 15–19)

| Day | Item | Task | Output | Effort |
|-----|------|------|--------|--------|
| 15 | 13 | RevenueCat + Purchases cleanup | Delete 4 files, update app.dart, pubspec.yaml | 1 day |
| 16 | 14 | CI/CD Pipeline | `.github/workflows/ci.yml` + branch protection | 2h |
| 16 | 15 | Pre-commit hooks | `scripts/pre-commit.sh` + install | 0.5h |
| 17 | 17 | Environment configuration | `lib/core/config/environment.dart` + `.env.example` | 2h |
| 18 | 16 | Builds protocol | `.builds/` files + publish scripts | 4h |
| 19 | 18 | Code coverage | Coverage in CI + 70% threshold | 1h |
| 19 | 19 | Dependabot | `.github/dependabot.yml` | 0.5h |

### Week 8 (Days 20–24) — Requires Track B Complete

| Day | Item | Task | Output | Effort |
|-----|------|------|--------|--------|
| 20 | — | AdMob banner integration (Settings) | `lib/core/services/ad_service.dart` | 2h |
| 21 | — | AdMob banner integration (My Day) | My Day banner placement | 2h |
| 22 | — | `remove_ads` IAP integration | Purchase flow + receipt validation | 3h |
| 23 | — | IAP testing + edge cases | Restore purchases, network errors | 3h |
| 24 | — | Regression QA | Full test suite + Maestro + manual UAT | 2h |

---

## 4. Acceptance Criteria Summary

### Gate 1 — CI Green
- [ ] `flutter analyze --no-pub` → 0 errors
- [ ] `flutter test` → ≥320 pass
- [ ] Pre-commit hook active
- [ ] Branch protection on `main`

### Gate 2 — Clean Codebase
- [ ] Zero references to `blinkingchorus.com`
- [ ] Zero references to `PurchasesService` or `PurchaseProvider`
- [ ] Zero references to `BYOK` / `hasOwnKey`
- [ ] No hardcoded API keys or secrets
- [ ] `.env.example` documents all config

### Gate 3 — Automation Ready
- [ ] `.builds/current.json` schema valid
- [ ] `scripts/publish-build.sh` outputs build notification text
- [ ] GitHub Actions CI workflow green
- [ ] Dependabot enabled

### Gate 4 — Revenue Ready (requires Track B)
- [ ] AdMob banner renders in Settings tab
- [ ] AdMob banner renders in My Day tab
- [ ] `remove_ads` IAP purchasable on Android (sandbox)
- [ ] `remove_ads` IAP purchasable on iOS (sandbox)
- [ ] Restore purchases works

---

## 5. Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Business owner delays on AdMob/IAP setup | High | Blocks Week 8 | Start Track B NOW. Lead times are 1–7 days. |
| Deleting `purchases_service` breaks something | Low | Medium | Trace all imports first; 320 tests catch regressions |
| CI runner Flutter version mismatch | Medium | Low | Pin Flutter version in workflow; use same version as local |
| Pre-commit hook too slow | Low | Low | Analyze + test takes ~10s locally; acceptable |
| DB table drop migration breaks existing users | Low | High | Test with `createTestDatabase(version: 17)` first |

---

## 6. Documents Updated

| Document | Change |
|----------|--------|
| `docs/BUILD_TEST_VC_RULES.md` | Add pre-commit hook section to §1.1 |
| `docs/STALIO_TEST_PLAN.md` | Add Phase 5 test case table |
| `works_item_0610.md` | Update Phase 5 items status |
| `SESSION_SUMMARY.md` | Log Phase 5 completion |
