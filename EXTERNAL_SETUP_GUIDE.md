# Stalio — External Platform Setup Guide

**Audience:** Project lead / account owner with signing authority
**Purpose:** Step-by-step instructions for all external platform configuration needed for Phase 3 (Monetization)
**Prerequisite:** This guide assumes Phase 1-2 code work will happen in parallel — have all IDs/tokens ready before Phase 3 code development begins

---

## Overview: What You'll Create / Configure

| Platform | What | Time | Blocking? |
|---|---|---|---|
| AdMob | Account + ad units + GDPR consent | 1–3 days | Yes — need App IDs + Ad Unit IDs for code |
| Google Play Console | Merchant account + IAP product + ads declaration | 1–5 days | Yes — need product ID for IAP code |
| App Store Connect | Paid apps agreement + IAP product + SKAdNetwork | 3–7 days | Yes — need product ID, review can take 48h |
| Hosting | Privacy Policy page + app-ads.txt file | 1 day | Yes — stores require privacy URL, AdMob requires app-ads.txt |

### Values That Feed Back Into Code

After completing all steps below, provide these values to the dev team:

| Value | Source | Goes Into |
|---|---|---|
| AdMob Android App ID | AdMob Console | `android/app/src/main/AndroidManifest.xml` |
| AdMob iOS App ID | AdMob Console | `ios/Runner/Info.plist` |
| Banner Ad Unit ID(s) | AdMob Console | `lib/core/services/ad_service.dart` |
| IAP Product ID | Both stores | `lib/core/services/iap_service.dart` (constant: `remove_ads`) |
| Privacy Policy URL | Your domain | Both stores (app listing) + `lib/core/constants/legal_content.dart` |
| Support/Contact Email | Your domain | Both stores (app listing) |

**Important:** The IAP Product ID **must be identical** on both Google Play Console and App Store Connect for `in_app_purchase` to work correctly. Use `remove_ads` on both.

---

## Part 1: Google AdMob

### 1.1 Create AdMob Account

**Time:** 1–2 days for approval
**Who:** Google account owner with payment/tax authority

1. Go to [https://admob.google.com](https://admob.google.com)
2. Click **Get Started** / **Sign Up for AdMob**
3. Sign in with the Google account that will own the AdMob account (use a business Google account, not a personal one if possible)
4. Fill in account details:
   - Country / Region
   - Time zone
   - Currency for earnings (USD recommended for simplicity)
5. Complete tax information (Google will prompt for this — required before payout):
   - US: W-9 form
   - Non-US: W-8BEN form
   - You'll need your tax ID (EIN/SSN for US or local equivalent)
6. Set up payment method:
   - Add bank account for EFT/wire transfer
   - Verify bank account (Google sends micro-deposits — takes 1–3 business days)
   - Payment threshold: $100 (cannot be changed for new accounts)
7. Verify phone number (Google sends SMS code)
8. Verify physical address (Google may mail a PIN to your address)

**Completion check:** [ ] AdMob account active, payment profile verified

---

### 1.2 Register Stalio App in AdMob

**Time:** 5 minutes
**Prerequisite:** Step 1.1 complete

1. In AdMob Console, click **Apps** → **Add App**
2. Choose **No** for "Is your app listed on a supported app store yet?" (even if it is, creating manually is easier)
3. Fill in:
   - App name: `Stalio`
   - Platform: **Android**
4. Click **Add**
5. After creation, you'll see the **App ID** in format: `ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY`
   - Record this value → **AdMob Android App ID** → goes into `AndroidManifest.xml`
6. Repeat steps 1–5 for **iOS** platform
   - Record the iOS App ID → **AdMob iOS App ID** → goes into `Info.plist`

**Note:** Both platforms share the same `ca-app-pub-XXXXXXXXXXXXXXXX` prefix; only the suffix (`~YYYYYYYYYY`) differs.

**Completion check:** [ ] Android App ID recorded
**Completion check:** [ ] iOS App ID recorded

---

### 1.3 Create Banner Ad Units

**Time:** 5 minutes
**Prerequisite:** Step 1.2 complete

You need banner ad units. You can either:
- **Option A (recommended for simplicity):** One shared banner unit for all placements
- **Option B (for analytics):** One unit per screen placement (My Day, Tallies, Notes)

**Steps (repeat for each unit if using Option B):**

1. In AdMob Console, click **Apps** → Select **Stalio (Android)**
2. Click **Ad units** → **Add ad unit**
3. Choose **Banner**
4. Configure:
   - Ad unit name: `Stalio_Banner` (or `Stalio_Banner_MyDay`, etc. for Option B)
   - Ad type: **Banner** (not adaptive banner — Flutter `google_mobile_ads` uses standard banners)
   - Ad size: 320x50 (standard mobile banner)
   - Auto-refresh: Google-optimized (default, ~60 seconds)
   - Advanced settings → leave defaults
5. Click **Create Ad Unit**
6. Record the **Ad Unit ID** (format: `ca-app-pub-XXXXXXXXXXXXXXXX/NNNNNNNNNN`)
7. Repeat for iOS platform (same ad unit ID format, different suffix)

**Completion check:** [ ] Android banner ad unit ID(s) recorded
**Completion check:** [ ] iOS banner ad unit ID(s) recorded
**Completion check:** [ ] Note: for development, the SDK provides test IDs — no need to create separate test ad units

---

### 1.4 Configure GDPR Consent (European Users)

**Time:** 10 minutes
**Prerequisite:** Step 1.2 complete

1. In AdMob Console, click **Privacy & messaging**
2. Click **GDPR** → **Create message**
3. Select apps: **Stalio (Android)** and **Stalio (iOS)**
4. Configure consent screen:
   - **Consent options:** "Consent" and "Do not consent" (both required)
   - **Purpose list:** Leave defaults (store/access info, personalized ads, ad measurement, etc.)
   - **Publisher revenue model:** Select "Advertising" (this is how you monetize)
5. Customize appearance (optional):
   - You can style the consent dialog but it's generally left default
6. Privacy Policy URL: **Must provide** — enter your hosted Privacy Policy URL (see Part 4)
7. Publish the message
8. Under **GDPR settings**, ensure:
   - "Restrict data processing for eligible users" → **Enabled** (this allows users to opt out)
   - "Restrict data processing for users under the age of consent" → **Enabled** if your app is not intended for children

**Completion check:** [ ] GDPR consent message published for both Android and iOS

**Note:** If your app is **not distributed in the EU/UK**, you can skip this. But if you ever plan to ship there, do it now to avoid retrofitting.

---

### 1.5 app-ads.txt

**Time:** 15 minutes + DNS propagation (up to 24h)
**Prerequisite:** Your domain is live

1. Create a text file named `app-ads.txt`
2. Find your publisher ID from AdMob Console → **Account** → **Settings** → **Account information** → Publisher ID (format: `pub-XXXXXXXXXXXXXXXX`)
3. File contents (exact format):
   ```
   google.com, pub-XXXXXXXXXXXXXXXX, DIRECT, f08c47fec0942fa0
   ```
   Replace `pub-XXXXXXXXXXXXXXXX` with your actual publisher ID.
4. Upload `app-ads.txt` to your domain root:
   ```
   https://yourdomain.com/app-ads.txt
   ```
   Example: `https://stalioapp.com/app-ads.txt`
5. Verify it's accessible by visiting the URL in a browser
6. AdMob will automatically crawl this file (takes up to 24 hours)

**Note:** Google may reduce or withhold ad revenue if app-ads.txt is missing. Do this before launch.

**Completion check:** [ ] `app-ads.txt` live at your domain root and accessible

---

## Part 2: Google Play Console

### 2.1 Prerequisites

Before starting, ensure:
- [ ] Stalio app listing exists in Google Play Console (if not, create it with package name matching `pubspec.yaml`)
- [ ] Content rating questionnaire is completed
- [ ] Privacy Policy URL is entered in App Content → Privacy Policy

---

### 2.2 Set Up Payments Profile (Merchant Account)

**Time:** 1–5 days (bank verification)
**Who:** Person with legal/tax authority for the entity selling the app

1. Go to [Google Play Console](https://play.google.com/console)
2. Select Stalio app → **Setup** → **Payments profile**
3. If no profile exists, click **Create payments profile**
4. Fill in:
   - Business legal name (must match your tax documents exactly)
   - Business address
   - Tax identification number (EIN/SSN for US businesses, or local equivalent)
   - Contact person name and email
5. Submit verification documents if requested (Google may ask for business registration certificate)
6. Add bank account:
   - Account holder name (must match business legal name)
   - Account number + routing number (US) / IBAN (non-US)
   - Bank address
7. Google sends test deposit(s) to verify bank account — this takes 1–3 business days
8. Once verified, your payments profile shows as **Active**

**Completion check:** [ ] Payments profile is active and bank account verified

**Troubleshooting:**
- If bank verification fails, check that the account holder name matches your payments profile legal name exactly
- Non-US accounts may require intermediary bank information (SWIFT code)

---

### 2.3 Create IAP Product (Remove Ads)

**Time:** 10 minutes
**Prerequisite:** Step 2.2 complete (merchant account active)

1. In Play Console, select Stalio app → **Monetize** → **Products** → **In-app products**
2. Click **Create product**
3. Fill in:
   - **Product ID:** `remove_ads`
     - This must match the ID used in `iap_service.dart`
     - Use lowercase, underscores, no spaces
   - **Type:** **Non-consumable** (one-time purchase, permanent)
   - **Status:** **Active**
   - **Title (English):** `Remove Ads`
   - **Description (English):** `Remove all advertisements from Stalio permanently. Enjoy an ad-free experience.`
   - **Title (Chinese):** `移除广告`
   - **Description (Chinese):** `永久移除所有广告，享受无广告体验。`
4. Set pricing:
   - Click **Set price** → Select "United States" as base
   - Set price: **$6.99** (recommended — adjust per PM decision)
   - Google auto-generates prices for all other regions based on exchange rates
   - Review auto-generated prices for major markets (EU, UK, Japan, China, India, Brazil)
5. Tax category: **App functionality (non-consumable)**
6. Click **Save** → product shows as **Active**

**Completion check:** [ ] `remove_ads` product active with correct pricing

**Note:** No review is needed for Google Play IAP products. They become usable immediately for license testers.

---

### 2.4 Add License Testers

**Time:** 5 minutes

License testers can make test purchases without being charged real money.

1. In Play Console, select Stalio app → **Setup** → **License testing**
2. Add email addresses of testers (Google accounts only)
3. These testers MUST:
   - Use a Google account that is NOT the developer account
   - Be on the testing device (add this Google account on the test phone)
   - NOT be on any Google Play Family Library
4. Click **Save changes**

**Note for testers:** When testing purchases, the Google Play overlay will show "This is a test purchase" or "[Test card, always approves]" — no real charge.

**Completion check:** [ ] At least 2 tester emails added

---

### 2.5 Declare Ads & Financial Features

**Time:** 10 minutes

Google requires explicit declaration of ads and IAP for policy compliance.

**Ads declaration:**

1. In Play Console → Select Stalio app → **Policy** → **App content**
2. Click **Ads** → **Start**
3. Answer: **Yes, my app contains ads**
4. Click **Save**

**Financial features declaration:**

1. In Play Console → **Policy** → **App content**
2. Click **Financial features** → **Start**
3. Answer: **Yes, my app contains in-app purchases**
4. Click **Save**

**Completion check:** [ ] Ads declared
**Completion check:** [ ] Financial features (IAP) declared

---

### 2.6 Data Safety Section

**Time:** 15 minutes

1. In Play Console → **Policy** → **App content** → **Data safety**
2. Overview → **Next**
3. Data collection and security:
   - Answer regarding encryption: **Yes, data is encrypted in transit** (AdMob uses HTTPS)
4. Data types collected by AdMob (check these):

   | Data Type | Collected? | Shared? | Purpose |
   |---|---|---|---|
   | Device or other IDs | Yes | Yes — shared with ad providers | Advertising or marketing |
   | Approximate location | Yes | Yes — shared with ad providers | Advertising or marketing |
   | App interactions | Yes | Yes — shared with ad providers | Analytics |
   | Crash logs | Yes | No | Analytics |
   | Diagnostics | Yes | No | Analytics |
   | App info and performance | No | — | — |

5. For each data type, answer the prompted questions:
   - Is collection required? **No** (user can opt out via ATT/consent)
   - Is data encrypted in transit? **Yes** (AdMob uses HTTPS)
   - Can users request deletion? **Yes** (users can uninstall app)
6. Review summary → **Submit**

**Note:** Stalio itself collects no personal data (all on-device storage). Only AdMob collects data. Be accurate — false declarations trigger app rejection.

**Completion check:** [ ] Data safety section complete and accurate

---

## Part 3: App Store Connect

### 3.1 Prerequisites

Before starting, ensure:
- [ ] Apple Developer Program membership is active ($99/year)
- [ ] Stalio app record exists in App Store Connect (if not, create it with matching bundle ID)
- [ ] You have an Apple ID with Admin or Account Holder role

---

### 3.2 Set Up Paid Applications Agreement

**Time:** 1–5 days (bank/tax verification)
**Who:** Account Holder role in Apple Developer account

This is required before creating IAP products.

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click **Agreements, Tax, and Banking**
3. Under **Request Contracts**, find **Paid Applications** → Click **Request**
4. After requesting, click on the agreement to fill in details:

   **Contact Info:**
   - Senior management contact (name, email, phone)
   - Financial contact (name, email, phone)
   - Technical contact (name, email, phone)

   **Bank Info:**
   - Bank account holder name (must match legal entity name)
   - Bank name and address
   - Account number + routing number (US) / IBAN + SWIFT (non-US)
   - For non-US: intermediary bank details if your bank uses correspondent banking
   - Account currency (USD recommended, or your local currency)

   **Tax Forms:**
   - **US entities:** W-9 form
   - **Non-US entities:** W-8BEN / W-8BEN-E form
   - You'll need your legal entity name, address, and tax ID
   - For W-8BEN-E: you'll need to select your entity type and provide treaty claims
   - Apple's tax wizard guides you through the relevant form

5. Once all sections show as **Complete**, Apple begins review
6. Status will change to **Active** once approved (usually 1–3 business days)

**Completion check:** [ ] Paid Applications agreement shows **Active**

**Troubleshooting:**
- If tax form is rejected, double-check that entity name matches your bank account name exactly
- Non-US entities: ensure you have a valid Foreign Tax Identification Number (FTIN) if your country has one

---

### 3.3 Create IAP Product (Remove Ads)

**Time:** 15 minutes + Apple review (24–48 hours)
**Prerequisite:** Step 3.2 complete (Paid Apps agreement active)

1. In App Store Connect, select Stalio app → **Features** → **In-App Purchases**
2. Click **Add** (+ button)
3. Configure:

   **Reference Name:** `Remove Ads` (internal only, not shown to users)

   **Product ID:** `remove_ads`
   - Must match the ID used in `iap_service.dart`
   - Must match the Google Play product ID
   - Can only contain alphanumeric characters, underscores, and periods

   **Type:** **Non-Consumable** (one-time purchase, permanent)

4. Click **Create**
5. Now fill in the product details:

   **Price Schedule:**
   - Click **Add Price** → **Set USD Price**
   - Select: **Tier 2 ($6.99)** — adjust per PM decision
   - Apple auto-generates prices for 175+ regions
   - Review major markets to ensure prices are reasonable

   **Localization (English - default):**
   - Display Name: `Remove Ads`
   - Description: `Remove all advertisements from Stalio permanently. Enjoy an ad-free experience.`

   **Localization (Chinese Simplified):**
   - Click **Add Localization** → Select **Chinese (Simplified)**
   - Display Name: `移除广告`
   - Description: `永久移除 Stalio 中的所有广告，享受无广告体验。`

6. **Review Screenshot:**
   - Upload a screenshot showing the "Remove Ads" UI in the app
   - This is **required** for Apple review
   - The screenshot must show the purchase button + price + restore button
   - Recommended: screenshot of the Settings → Remove Ads section
   - If the feature isn't built yet, you can submit with a wireframe or mockup and replace later

7. **Review Notes (for Apple reviewer):**
   ```
   This is a one-time non-consumable purchase to remove all banner 
   advertisements from the app. Ads shown are Google AdMob banners. 
   
   To test: navigate to Settings → Remove Ads → tap purchase button.
   Use sandbox test account to complete the test purchase.
   
   After purchasing: all banner ads will be hidden across the app.
   ```

8. Click **Save**

**Note:** Apple requires IAP products to go through app review before they are usable in TestFlight builds. This typically takes 24–48 hours. Submit this before you need to begin testing.

**Completion check:** [ ] Product created
**Completion check:** [ ] Localization added for English + Chinese
**Completion check:** [ ] Review screenshot uploaded
**Completion check:** [ ] Product status shows **Ready to Submit** or **Approved**

---

### 3.4 Create Sandbox Tester Account

**Time:** 5 minutes

Sandbox testers can make test purchases without real money.

1. In App Store Connect → **Users and Access** → **Sandbox** → **Testers**
2. Click **Add** (+ button)
3. Fill in:
   - First name / Last name
   - Email address: **Must be a real email address not associated with any existing Apple ID**
   - Tip: Use `+sandbox` aliasing: `you+stalio_sandbox@gmail.com`
   - Password: Set any password (not used for sandbox)
   - Date of birth
   - Store country: United States (or your primary market)
4. Select **Manage** next to "Tester Territories" → select United States
5. Click **Save**

**Note:** On the test device, you'll sign out of your real Apple ID (Settings → Apple ID → Sign Out) and sign in with the sandbox tester email ONLY when prompted during a test purchase. Do NOT sign into the sandbox account through Settings.

**Completion check:** [ ] At least 2 sandbox tester accounts created

---

### 3.5 SKAdNetwork Configuration

**Time:** 5 minutes

AdMob requires Google's SKAdNetwork ID for ad attribution on iOS.

**In `Info.plist` (dev team will add — just provide the ID):**

```xml
<key>SKAdNetworkItems</key>
<array>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>cstr6suwn9.skadnetwork</string>
    </dict>
</array>
```

**In App Store Connect:**

1. Go to Stalio app → **General** → **App Privacy**
2. Under **Data Types**, ensure data collected by AdMob is declared:
   - Identifiers (Device ID)
   - Advertising Data
   - Coarse Location
3. Under **Advertising Identifier**, Apple will ask about IDFA usage during submission — answer:
   - **"Yes, this app uses the Advertising Identifier to serve advertisements"**
   - Check: "Serve advertisements within the app"
   - Also check: "Attribute this app installation to a previously served advertisement" (if you plan to run AdMob ad campaigns for user acquisition)

**Completion check:** [ ] SKAdNetwork identifier provided to dev team for Info.plist
**Completion check:** [ ] IDFA usage declared in App Store Connect

---

### 3.6 ATT (App Tracking Transparency) Configuration

**Time:** 5 minutes

Required for showing personalized ads on iOS.

**In `Info.plist` (dev team will add):**

```xml
<key>NSUserTrackingUsageDescription</key>
<string>Allow Stalio to track your activity to serve personalized advertisements. This helps keep Stalio free. You can remove ads anytime with a one-time purchase.</string>
```

**For App Store review:** Apple will check that:
- The ATT prompt appears before any ad loads
- The prompt text matches the `Info.plist` description
- The app works correctly regardless of user's choice (allow vs. deny)
- Ads are non-personalized when tracking is denied

**Completion check:** [ ] ATT description string provided to dev team
**Completion check:** [ ] ATT description is user-friendly and accurate (not misleading)

---

### 3.7 App Store Connect Fields Summary

During app submission for review, you'll need to fill in these fields. Prepare them now:

| Field | Expected Answer |
|---|---|
| App contains ads? | Yes |
| Uses IDFA? | Yes — for serving ads + campaign attribution |
| Contains IAP? | Yes — one non-consumable product |
| Privacy Policy URL | Your hosted privacy page URL |
| End User License Agreement (EULA) | Optional — standard Apple EULA if blank |
| Content Rights | Do you own all content in the app? Yes |
| Encryption | Does app use encryption? No (Flutter HTTPS doesn't count — only custom crypto) |
| Age Rating | 4+ (if no mature content) or 12+ (if content includes health/personal data tracking) |

---

## Part 4: Privacy Policy Hosting

### 4.1 Create Privacy Policy Page

The privacy policy must cover AdMob data collection + IAP + user rights. Update `legal_content.dart` from the English "Stalio Privacy Policy" section and host it as a standalone web page.

**Minimum required URL paths:**
```
https://yourdomain.com/privacy
https://yourdomain.com/terms
```

**Privacy Policy must include:**

1. **Introduction** — what this policy covers
2. **Data Stalio collects** — "Stalio collects no personal data. All notes, habits, and moods are stored exclusively on your device."
3. **Third-party data collection (AdMob)** — "Stalio uses Google AdMob to display advertisements. AdMob may collect: device identifiers, IP address, ad interaction data, approximate location, crash and performance data. See Google's Privacy Policy at https://policies.google.com/privacy"
4. **In-app purchases** — "One-time purchase 'Remove Ads' processed by Apple/Google. Payment information is not accessible to Stalio."
5. **Data sharing** — "Data collected by AdMob is shared with Google for ad serving and measurement."
6. **Your choices** — "Opt out of personalized ads via device settings (iOS: Settings → Privacy → Tracking. Android: Settings → Google → Ads → Opt out). Purchase 'Remove Ads' to eliminate all advertising."
7. **Children's privacy** — Statement about age limits
8. **Contact** — Support email
9. **Changes to policy** — Update notice

**Completion check:** [ ] Privacy Policy page live at your domain
**Completion check:** [ ] Terms of Service page live at your domain
**Completion check:** [ ] Both linked from within the app (settings → legal section)

---

## Quick Reference: All Values to Hand Off to Dev Team

| # | Value | Source | Used In |
|---|---|---|---|
| 1 | AdMob Android App ID | AdMob Console → Apps → Stalio (Android) | `AndroidManifest.xml` |
| 2 | AdMob iOS App ID | AdMob Console → Apps → Stalio (iOS) | `Info.plist` |
| 3 | Banner Ad Unit ID (Android) | AdMob Console → Ad Units | `ad_service.dart` |
| 4 | Banner Ad Unit ID (iOS) | AdMob Console → Ad Units | `ad_service.dart` |
| 5 | IAP Product ID | Both stores (must match) | `iap_service.dart` (constant: `remove_ads`) |
| 6 | Privacy Policy URL | Your domain | Both store listings + `legal_content.dart` |
| 7 | Terms of Service URL | Your domain | Both store listings + `legal_content.dart` |
| 8 | Support Email | Your domain | Both store listings + `legal_content.dart` |
| 9 | ATT Prompt Text | Your decision | `Info.plist` `NSUserTrackingUsageDescription` |
| 10 | SKAdNetwork ID | Apple requirement | `Info.plist` `SKAdNetworkItems` |

---

## Timeline Summary

| Week | Tasks |
|---|---|
| **Week 1 (parallel)** | Create AdMob account, Google Merchant account, Apple Paid Apps agreement (start ALL three immediately — longest lead times) |
| **Week 2** | Create ad units, IAP products, sandbox testers, license testers, GDPR consent, app-ads.txt. Privacy Policy page live. |
| **Week 3** | All IDs/tokens ready. Hand off values to dev team. Phase 3 code development begins. IAP review ongoing with Apple. |
| **Week 4** | Test ad serving (debug test ads), test purchases (sandbox/license testers), verify consent flows. Fix any review rejections. |
