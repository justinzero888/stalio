// lib/core/config/constants.dart

class AppConstants {
  // App Info
  static const String appName = 'Blinking';
  static const String appVersion = '1.2.0';

  // Feature Switches
  static const bool kUseMultiTurnChat = false;

  // Storage Keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'language';
  static const String keyFirstLaunch = 'first_launch';

  // Default Tags
  static const List<Map<String, dynamic>> defaultTags = [
    {'name': '工作', 'nameEn': 'Work', 'color': 0xFF34C759},
    {'name': '生活', 'nameEn': 'Life', 'color': 0xFF007AFF},
    {'name': '健康', 'nameEn': 'Health', 'color': 0xFFFF9500},
    {'name': '学习', 'nameEn': 'Learning', 'color': 0xFF5856D6},
    {'name': '家庭菜单', 'nameEn': 'Family Menu', 'color': 0xFFFF2D55},
    {'name': '睡眠', 'nameEn': 'Sleep', 'color': 0xFFAF52DE},
  ];

  // Default Routines
  static const List<Map<String, dynamic>> defaultRoutines = [
    {'name': '维生素', 'nameEn': 'Vitamin', 'icon': '💊', 'frequency': 'daily', 'reminderTime': '08:00'},
    {'name': '5000步', 'nameEn': '5000 Steps', 'icon': '🚶', 'frequency': 'daily', 'target': 5000},
    {'name': '喝水', 'nameEn': 'Water', 'icon': '💧', 'frequency': 'daily', 'target': 1500},
  ];

  // Export
  static const String exportFileName = 'blinking_export';
  static const String exportVersion = '1.0';
}