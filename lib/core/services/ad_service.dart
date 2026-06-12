import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdService {
  static bool _initialized = false;
  static bool _adsRemoved = false;

  static bool get adsRemoved => _adsRemoved;

  static Future<void> initialize() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    final prefs = await SharedPreferences.getInstance();
    _adsRemoved = prefs.getBool('ads_removed') ?? false;
    _initialized = true;
  }

  static Future<void> markAdsRemoved() async {
    _adsRemoved = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ads_removed', true);
  }

  static BannerAd? createBanner(String unitId) {
    if (_adsRemoved) return null;
    return BannerAd(
      adUnitId: unitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: const BannerAdListener(),
    )..load();
  }
}
