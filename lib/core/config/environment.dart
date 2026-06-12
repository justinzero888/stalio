/// Environment configuration for Stalio.
/// Values are injected at build time via --dart-define flags.
/// Fallback values are for local development only.

class Environment {
  final String name;
  final String adMobAppIdAndroid;
  final String adMobAppIdIos;
  final String adMobBannerUnitIdAndroid;
  final String adMobBannerUnitIdIos;

  const Environment({
    required this.name,
    required this.adMobAppIdAndroid,
    required this.adMobAppIdIos,
    required this.adMobBannerUnitIdAndroid,
    required this.adMobBannerUnitIdIos,
  });

  bool get isProduction => name == 'production';
  bool get isStaging => name == 'staging';
  bool get isDevelopment => name == 'development';

  static Environment get current {
    const name = String.fromEnvironment('APP_ENV', defaultValue: 'development');

    // Production values — injected via --dart-define at build time
    final prodAdMobAppIdAndroid = const String.fromEnvironment(
      'ADMOB_APP_ID_ANDROID',
      defaultValue: '',
    );
    final prodAdMobAppIdIos = const String.fromEnvironment(
      'ADMOB_APP_ID_IOS',
      defaultValue: '',
    );
    final prodAdMobBannerUnitIdAndroid = const String.fromEnvironment(
      'ADMOB_BANNER_UNIT_ID_ANDROID',
      defaultValue: '',
    );
    final prodAdMobBannerUnitIdIos = const String.fromEnvironment(
      'ADMOB_BANNER_UNIT_ID_IOS',
      defaultValue: '',
    );

    switch (name) {
      case 'production':
        return Environment(
          name: 'production',
          adMobAppIdAndroid: prodAdMobAppIdAndroid,
          adMobAppIdIos: prodAdMobAppIdIos,
          adMobBannerUnitIdAndroid: prodAdMobBannerUnitIdAndroid,
          adMobBannerUnitIdIos: prodAdMobBannerUnitIdIos,
        );
      case 'staging':
        // Staging uses same AdMob IDs as production for testing
        return Environment(
          name: 'staging',
          adMobAppIdAndroid: prodAdMobAppIdAndroid.isNotEmpty
              ? prodAdMobAppIdAndroid
              : 'ca-app-pub-3940256099942544~3347511713', // AdMob test App ID
          adMobAppIdIos: prodAdMobAppIdIos.isNotEmpty
              ? prodAdMobAppIdIos
              : 'ca-app-pub-3940256099942544~1458002511',
          adMobBannerUnitIdAndroid: prodAdMobBannerUnitIdAndroid.isNotEmpty
              ? prodAdMobBannerUnitIdAndroid
              : 'ca-app-pub-3940256099942544/6300978111', // AdMob test banner
          adMobBannerUnitIdIos: prodAdMobBannerUnitIdIos.isNotEmpty
              ? prodAdMobBannerUnitIdIos
              : 'ca-app-pub-3940256099942544/2934735716',
        );
      default:
        // Development — use AdMob test IDs
        return const Environment(
          name: 'development',
          adMobAppIdAndroid: 'ca-app-pub-3940256099942544~3347511713',
          adMobAppIdIos: 'ca-app-pub-3940256099942544~1458002511',
          adMobBannerUnitIdAndroid: 'ca-app-pub-3940256099942544/6300978111',
          adMobBannerUnitIdIos: 'ca-app-pub-3940256099942544/2934735716',
        );
    }
  }
}
