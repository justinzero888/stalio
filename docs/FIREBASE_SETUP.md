# Stalio — Firebase Setup Requirements

> **Date:** June 13, 2026  
> **Cost:** $0/month (Spark plan, no credit card required)  
> **Blocking:** Phase 6 Item 25 (Crashlytics)

---

## Step-by-Step Setup

### 1. Create Firebase Project

1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Click **Create a project** (or **Add project**)
3. Project name: `Stalio` (or `stalio-app`)
4. Enable Google Analytics: **Optional** (recommended — also free)
5. Accept terms, click **Create**
6. Wait for project provisioning (~30 seconds)

### 2. Register Android App

1. In Firebase console, click **Add app** → **Android**
2. Fill in:
   - **Android package name:** `com.orbacetech.stalio`
   - **App nickname:** `Stalio` (optional)
   - **Debug signing certificate (SHA-1):** Not needed for Crashlytics (skip)
3. Click **Register app**
4. Download `google-services.json`
5. Place it at: `android/app/google-services.json`
6. Skip the "Add Firebase SDK" steps — Flutter handles this

### 3. Register iOS App

1. In Firebase console, click **Add app** → **iOS**
2. Fill in:
   - **iOS bundle ID:** `com.orbacetech.stalio`
   - **App nickname:** `Stalio` (optional)
   - **App Store ID:** Skip (enter after App Store listing is live)
3. Click **Register app**
4. Download `GoogleService-Info.plist`
5. Place it at: `ios/Runner/GoogleService-Info.plist`
6. Skip the "Add Firebase SDK" steps — Flutter handles this

### 4. Enable Crashlytics

1. In Firebase console → **Run** → **Crashlytics**
2. Click **Enable Crashlytics** (it will prompt to add the SDK — skip, we use Flutter)
3. The first crash report will appear after the app runs with the SDK integrated

### 5. Hand Off to Dev Team

Provide these two files:

| File | Path to place | Size |
|------|--------------|------|
| `google-services.json` | `android/app/google-services.json` | ~2 KB |
| `GoogleService-Info.plist` | `ios/Runner/GoogleService-Info.plist` | ~3 KB |

**DO NOT commit these files to git.** They contain API keys. They are already in `.gitignore`.

---

## Values Required from Business Owner

The two files above contain everything needed. No additional keys or IDs required.

If the business owner prefers to share the Firebase project rather than downloading files:
1. Go to Firebase console → Project settings → Users and permissions
2. Add developer's Google account as **Owner** or **Editor**

---

## Cost Confirmation

| Plan | Monthly Cost | Crashlytics | Other Limits |
|------|-------------|-------------|-------------|
| **Spark (Free)** | **$0** | Unlimited | 50K reads/day for Firestore, 1GB stored, 10GB/month transfer |
| Blaze (Paid) | Usage-based | Unlimited | Scales with usage |

**Spark plan is sufficient for Stalio indefinitely.** Crashlytics has no usage limits and no cost. The only reason to upgrade to Blaze would be if Stalio later adds Cloud Storage or Firestore — unlikely given the "all data stays on device" privacy model.
