# Stalio — Business Decisions Record

> **Date:** June 10, 2026  
> **Decision maker:** Business Owner  
> **Status:** Confirmed

---

## Decisions Confirmed

| # | Question | Decision | Rationale |
|---|----------|----------|-----------|
| 1 | Remove all AI dead code and AI key references? | **YES — Remove all** | Stalio has no AI features. All AI-related code, services, tables, and key references should be purged. |
| 2 | AdMob format preference? | **Banner on Settings + My Day** | AdMob account already setup. Products in process. |
| 3 | `remove_ads` IAP approach? | **$2.99 one-time purchase** | Price confirmed. In process for both Google Play and App Store. |
| 4 | Repository visibility? | **Private until store launch** | Keep private during development. |

---

## Implementation Status

| Item | Status | Action Needed |
|------|--------|---------------|
| AI dead code purge (services) | ✅ Done (June 10) | `soft_prompt_service.dart`, `chorus_service.dart`, `post_to_chorus_sheet.dart` deleted |
| AI dead code purge (entry detail) | ✅ Done (June 10) | Chorus button removed from `entry_detail_screen.dart` |
| AI DB tables cleanup | 🔲 Phase 6 | `ai_identity`, `lens_sets`, `ai_call_log`, `ai_summary` — drop via migration |
| AI key references | ✅ Done (June 10) | OpenRouter key purged from git history; GitHub push protection active |
| RevenueCat/purchases cleanup | 🔲 Phase 5 Item 13 | Delete `purchases_service.dart`, `entitlement_service.dart`, `paywall_screen.dart` |
| AdMob account | ✅ Done | Account created |
| AdMob ad units | ✅ Done | Values received: Android `1333457063`, iOS `1302206478` |
| AdMob App IDs | ✅ Done | Android: `~1493778160`, iOS: `~5735736505` |
| `remove_ads` IAP (Google Play) | 🔲 In process | Business owner creating product |
| `remove_ads` IAP (App Store) | 🔲 In process | Business owner creating product |
| Privacy Policy URL | ✅ Done | `https://orbacetech.com/stalio-privacy` |

---

## Instructions for Business Owner

### Values Received — June 10, 2026

```
=== AdMob (Android) ===
AdMob App ID (Android):        ca-app-pub-7497527413129091~1493778160
Banner Ad Unit ID (Android):   ca-app-pub-7497527413129091/1333457063

=== AdMob (iOS) ===
AdMob App ID (iOS):            ca-app-pub-7497527413129091~5735736505
Banner Ad Unit ID (iOS):       ca-app-pub-7497527413129091/1302206478

=== In-App Purchase ===
Google Play product ID:        remove_ads (awaiting creation)
App Store product ID:          remove_ads (awaiting creation)
Price:                         $2.99

=== Legal ===
Privacy Policy URL:            https://orbacetech.com/stalio-privacy
Terms of Service URL:          (pending)
```

### Where to find these values

**AdMob App ID:**
1. Go to [apps.admob.com](https://apps.admob.com)
2. Select your Stalio app (or create it: "Add App" → iOS / Android)
3. The App ID is displayed at the top of the app dashboard
4. Format: `ca-app-pub-1234567890123456~9876543210987654`

**Banner Ad Unit ID:**
1. In AdMob dashboard, select your app → "Ad units" tab
2. Click "Create ad unit" → Select "Banner"
3. Name it (e.g., "Stalio Banner Settings")
4. The Ad Unit ID is displayed after creation
5. Format: `ca-app-pub-1234567890123456/1111111111`
6. Create one for iOS and one for Android

**Google Play `remove_ads` IAP Product ID:**
1. Go to [Google Play Console](https://play.google.com/console) → Your app
2. Navigate to "Monetize" → "Products" → "In-app products"
3. Click "Create product" → Select "One-time purchase" (not subscription)
4. Product ID should be something like: `remove_ads`
5. Set price to $2.99 USD
6. Status must be "Active" before dev can test

**App Store Connect `remove_ads` IAP Product ID:**
1. Go to [App Store Connect](https://appstoreconnect.apple.com) → Your app
2. Navigate to "Features" → "In-App Purchases"
3. Click "+" → Select "Consumable" (or "Non-Consumable" since it's a permanent unlock)
4. Reference name: `Remove Ads`
5. Product ID should match: `remove_ads` (same as Google Play for consistency)
6. Set price to $2.99 USD (Tier 1)
7. Must have "Paid Apps" agreement signed before this works

**Privacy Policy URL:**
- Must be a publicly accessible URL (HTTPS)
- Must disclose use of Google AdMob for advertising
- Must disclose data collection by third-party ad providers
- Template disclosure: "This app uses Google AdMob to display advertisements. AdMob may collect and use anonymized data for ad personalization. You can opt out of personalized ads in your device settings."

---

## AdMob Integration Process (Dev Team)

### Step 1 — Receive values from business owner
Business owner fills in the 6 values above and hands them off.

### Step 2 — Add AdMob to pubspec.yaml
```yaml
dependencies:
  google_mobile_ads: ^5.2.0
```

### Step 3 — Configure Android
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY"/>
```

### Step 4 — Configure iOS
Add to `ios/Runner/Info.plist`:
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~ZZZZZZZZZZ</string>
<key>SKAdNetworkItems</key>
<array>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>cstr6suwn9.skadnetwork</string>
  </dict>
</array>
```

### Step 5 — Create AdService
```dart
// lib/core/services/ad_service.dart
class AdService {
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  static BannerAd createBannerAd(String unitId) {
    return BannerAd(
      adUnitId: unitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(...),
    )..load();
  }
}
```

### Step 6 — Add banners to screens
Settings tab and My Day tab — place banner at the bottom of the screen, below all content.

### Step 7 — Wire `remove_ads` IAP
When `remove_ads` is purchased:
- Hide all ads
- Store `hasRemovedAds = true` in SharedPreferences
- Check `hasRemovedAds` before creating any banner

### Test Process
1. Use AdMob test ad unit IDs during development:
   - Banner: `ca-app-pub-3940256099942544/6300978111`
2. Verify banners render on Settings and My Day
3. Test purchase flow with Google Play Billing test cards
4. Test purchase flow with App Store sandbox account
5. Verify ads are hidden after purchase
6. Verify ads stay hidden after app restart
7. Test "Restore Purchases" flow

---

## Summary for Records

| Decision | Outcome |
|----------|---------|
| AI dead code | Purge everything — services, DB tables, key references |
| AdMob | Account exists; ad units in process; banners on Settings + My Day |
| remove_ads IAP | $2.99; in process for both stores; ID = `remove_ads` |
| Repo visibility | Private until launch |
