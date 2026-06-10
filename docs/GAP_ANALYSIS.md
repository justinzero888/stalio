# Stalio — Process Gap Analysis & Automation Roadmap

> **Date:** June 10, 2026  
> **Repo:** `https://github.com/justinzero888/stalio.git`  
> **Current State:** Phase 4 complete, 320 tests, 0 analysis errors, 3 sim platforms

---

## 1. Executive Summary

Stalio has a solid foundation: 320 automated tests, 8 Maestro UAT flows, a 74-case manual UAT checklist, and documented build/test/VC rules. However, when measured against the `dev-cycle-playbook.md` and `dev-test-collaboration.md` protocols, several gaps exist between the current manual processes and the target automated pipeline.

**Priority ranking:** P0 = blocks release, P1 = blocks efficiency, P2 = nice to have, P3 = future.

---

## 2. Gap Inventory

### 2.1 CI/CD Pipeline — GAP-CI-01

| Attribute | Current | Target | Priority |
|-----------|---------|--------|----------|
| Status | No GitHub Actions workflow | Automated analyze + test on every push/PR | **P0** |
| Impact | Every commit relies on dev manually running `flutter analyze` + `flutter test` | CI gate catches regressions immediately |
| Effort | 2 hours | Single YAML file in `.github/workflows/ci.yml` |

**Recommendation:** Create `.github/workflows/ci.yml` with:
```yaml
on: [push, pull_request]
jobs:
  test:
    steps:
      - flutter pub get
      - flutter analyze --no-pub
      - flutter test
```

Add branch protection on `main` requiring these checks.

---

### 2.2 Builds Protocol — GAP-BLD-01

| Attribute | Current | Target | Priority |
|-----------|---------|--------|----------|
| Status | No `.builds/` directory | Automated build state machine per `dev-cycle-playbook.md` §3.2 | **P1** |
| Impact | Test agent has no structured way to receive builds or report results | Dev publishes `current.json`, test agent runs Maestro, publishes `results.json` |
| Effort | 4 hours | Create `.builds/` structure + `publish-build.sh` + `publish-results.sh` |

**Files to create:**
- `.builds/current.json` — build metadata (commit, files, sim status)
- `.builds/results.json` — Maestro test results by platform
- `.builds/state.json` — shared phase + defect tracker
- `.builds/DASHBOARD.md` — auto-generated Ship Gate status
- `scripts/publish-build.sh` — dev agent publishes build
- `scripts/publish-results.sh` — test agent publishes results

---

### 2.3 Pipeline Protocol — GAP-PPL-01

| Attribute | Current | Target | Priority |
|-----------|---------|--------|----------|
| Status | Work items tracked in `works_item_0610.md` (static markdown) | `pipeline/` directory with status-state machine per `dev-cycle-playbook.md` §2 | **P1** |
| Impact | No automated state transitions, no owner tracking, no handoff gates | Items flow `backlog → in_dev → ready_for_test → tested → shipped` with clear ownership |
| Effort | 3 hours | Create `pipeline/stalio/` directory + work item files |

**Files to create:**
- `pipeline/stalio/stalio-001.md` through `stalio-014.md` (Phase 4 items)
- Each item has: id, app, type, project, title, status, owner, updated, acceptance criteria, dev notes, test results
- `pipeline/PROTOCOL.md` — agent ritual reference
- `pipeline/board.sh` — view board status

---

### 2.4 Automated Maestro Execution — GAP-UAT-01

| Attribute | Current | Target | Priority |
|-----------|---------|--------|----------|
| Status | 8 Maestro flows exist manually (test agent runs locally) | Maestro flows run automatically on CI or by test agent via builds protocol | **P1** |
| Impact | Test agent must manually pull + run each flow on 3 platforms | Test agent notification triggers automated or guided execution |
| Effort | 2 hours | Integrate Maestro into CI (Android) + document test agent run procedure |

**Note:** Maestro Cloud or local emulator execution can be added to CI for Android. iOS Maestro requires macOS runner (paid GitHub Actions).

---

### 2.5 Pre-Commit Hooks — GAP-HOK-01

| Attribute | Current | Target | Priority |
|-----------|---------|--------|----------|
| Status | No pre-commit hooks | `flutter analyze` + `flutter test` + secret scan before every commit | **P1** |
| Impact | Dev can commit broken code or secrets | Automated gate prevents bad commits |
| Effort | 30 minutes | Add `.git/hooks/pre-commit` script |

```bash
#!/bin/bash
flutter analyze --no-pub || { echo "Analyze failed"; exit 1; }
flutter test || { echo "Tests failed"; exit 1; }
git diff --cached | grep -qE 'sk-[or]-[a-zA-Z0-9]{20,}' && { echo "SECRET DETECTED"; exit 1; }
```

---

### 2.6 Code Coverage — GAP-COV-01

| Attribute | Current | Target | Priority |
|-----------|---------|--------|----------|
| Status | No coverage tracking | Coverage report generated per build, minimum threshold enforced | **P2** |
| Impact | Unknown what percentage of code is tested | Visibility into untested paths |
| Effort | 1 hour | Add `flutter test --coverage` + `lcov` to CI |

**Recommendation:** Set 70% minimum line coverage, track trend over time in `Business/stalio/growth/metrics.md`.

---

### 2.7 Secrets Management — GAP-SEC-01

| Attribute | Current | Target | Priority |
|-----------|---------|--------|----------|
| Status | No automated secret scanning pre-push | GitHub push protection active (blocked Phase 4 push due to legacy API key); pre-commit hook planned | **P0** (partially resolved) |
| Impact | GitHub blocked push; dev had to rewrite history to remove key | Prevention before commit |
| Effort | Already implemented: GitHub push protection is active. Pre-commit hook pending. |

**Actions taken:**
- [x] Removed OpenRouter API key from git history via `git filter-branch`
- [x] GitHub push protection now active on the repo
- [ ] Add pre-commit secret scan hook (GAP-HOK-01)
- [ ] Audit all files for hardcoded credentials
- [ ] Create `.env.example` for required environment variables

---

### 2.8 Dependency Security Scanning — GAP-DEP-01

| Attribute | Current | Target | Priority |
|-----------|---------|--------|----------|
| Status | No vulnerability scanning | Dependabot or Snyk scanning for known CVEs | **P2** |
| Impact | Unknown if dependencies have security vulnerabilities | Automated alerts on vulnerable packages |
| Effort | 30 minutes | Enable Dependabot in GitHub repo settings |

---

### 2.9 Environment Management — GAP-ENV-01

| Attribute | Current | Target | Priority |
|-----------|---------|--------|----------|
| Status | Single environment (debug builds to simulators, direct release builds) | Staging/production split with separate API keys, bundle IDs, app icons | **P2** |
| Impact | Accidentally using production keys in development | Clear environment isolation |
| Effort | 2 hours | Create `lib/core/config/environment.dart` with `--dart-define` flags |

---

### 2.10 Crash Reporting — GAP-CRS-01

| Attribute | Current | Target | Priority |
|-----------|---------|--------|----------|
| Status | No crash reporting SDK | Firebase Crashlytics or Sentry integration | **P2** |
| Impact | No visibility into production crashes | Real-time crash alerts with stack traces |
| Effort | 3 hours | Add `firebase_crashlytics` package + configuration |

---

### 2.11 Release Automation — GAP-REL-01

| Attribute | Current | Target | Priority |
|-----------|---------|--------|----------|
| Status | Manual AAB/IPA builds, manual store uploads | CI-triggered release builds, version bumping, store metadata updates | **P2** |
| Impact | Human error in release process; inconsistent versioning | Repeatable, auditable release pipeline |
| Effort | 4 hours | GitHub Actions release workflow + fastlane integration |

---

### 2.12 Performance Testing — GAP-PRF-01

| Attribute | Current | Target | Priority |
|-----------|---------|--------|----------|
| Status | No performance benchmarks | Cold start time, frame rendering budget, memory usage tracked per release | **P3** |
| Impact | No baseline for performance regressions | Trend data for optimization decisions |
| Effort | 2 hours | Add `flutter test --performance` + baseline tracking |

**Note:** `works_item_0610.md` notes cold start ~2s on Android emulator. This should be baselined.

---

### 2.13 Accessibility Testing — GAP-A11Y-01

| Attribute | Current | Target | Priority |
|-----------|---------|--------|----------|
| Status | No automated accessibility checks | Semantics tree validation, contrast ratio checks | **P3** |
| Impact | Unknown accessibility compliance | WCAG 2.1 AA baseline |
| Effort | 3 hours | Add accessibility audit tests + Maestro VoiceOver flows |

---

## 3. Implementation Roadmap

### Phase 5 (Week 6–7) — Critical Infrastructure

| ID | Gap | Action | Effort |
|----|-----|--------|--------|
| GAP-CI-01 | No CI/CD | Create `.github/workflows/ci.yml` | 2h |
| GAP-HOK-01 | No pre-commit hooks | Add `.git/hooks/pre-commit` + document in `BUILD_TEST_VC_RULES.md` | 0.5h |
| GAP-SEC-01 | Secrets management | Add pre-commit secret scan; audit all files | 1h |

### Phase 6 (Week 8–9) — Automated Pipeline

| ID | Gap | Action | Effort |
|----|-----|--------|--------|
| GAP-BLD-01 | No builds protocol | Create `.builds/` structure + publish scripts | 4h |
| GAP-PPL-01 | No pipeline tracking | Create `pipeline/stalio/` work items | 3h |
| GAP-UAT-01 | Manual Maestro | Integrate Maestro into CI (Android) | 2h |

### Phase 7 (Week 10+) — Quality & Observability

| ID | Gap | Action | Effort |
|----|-----|--------|--------|
| GAP-COV-01 | No code coverage | Add coverage to CI, set 70% threshold | 1h |
| GAP-DEP-01 | No dependency scanning | Enable Dependabot | 0.5h |
| GAP-ENV-01 | Single environment | Create environment config | 2h |
| GAP-CRS-01 | No crash reporting | Integrate Firebase Crashlytics | 3h |

### Phase 8 (Future) — Release & Performance

| ID | Gap | Action | Effort |
|----|-----|--------|--------|
| GAP-REL-01 | Manual releases | CI release workflow + fastlane | 4h |
| GAP-PRF-01 | No perf benchmarks | Baseline + trend tracking | 2h |
| GAP-A11Y-01 | No a11y tests | Audits + VoiceOver flows | 3h |

---

## 4. Quick Wins (This Week)

These can be done immediately with minimal effort:

1. **Pre-commit hook** (GAP-HOK-01) — 30 min. Prevents broken/secret commits locally.
2. **GitHub Actions CI** (GAP-CI-01) — 2 hours. Catches regressions automatically.
3. **Dependabot** (GAP-DEP-01) — 30 min. Free vulnerability scanning from GitHub.
4. **Checklist for manual UAT** — Already done (`docs/UAT_PHASE4.md`, 74 cases).

---

## 5. Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Secret committed to repo | Medium (happened) | High (account compromise) | Pre-commit hook + GitHub push protection (done) |
| Regression not caught | Medium | High (broken release) | CI gate (GAP-CI-01) |
| Test agent cannot run Maestro | Medium | Medium (delayed verification) | Documented run procedure + CI integration (GAP-UAT-01) |
| Dependency vulnerability | Low | Medium | Dependabot (GAP-DEP-01) |
| `cherished_memory_screen.dart` corruption | Medium | Medium (1609 lines, known risk) | File split in refactoring phase; sed-only rule in BUILD_TEST_VC_RULES.md |
| Build environment inconsistency | Low | Low | Flutter version pinning + CI uses same version |

---

## 6. Success Metrics

| Metric | Current | Phase 5 Target | Phase 7 Target |
|--------|---------|---------------|---------------|
| CI gate | Manual | Automated (analyze + test) | + coverage + Maestro |
| Release cycle | Manual | Manual + documented | Automated via fastlane |
| Secret exposure risk | Medium (legacy key removed) | Low (pre-commit hook) | Low + audit |
| Code coverage | Unknown | 70% measured | 80% |
| UAT execution time | Manual (4+ hours) | Manual (checklist) | Semi-automated (CI + manual) |
| Crash visibility | None | None | Firebase Crashlytics |
| Work item tracking | Static markdown | Pipeline protocol | Full board automation |
