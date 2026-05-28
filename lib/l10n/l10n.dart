// lib/l10n/l10n.dart

import 'package:flutter/material.dart';

class L10n {
  static final all = [
    const Locale('en'),
    const Locale('zh'),
  ];

  static String getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'zh':
        return '中文';
      default:
        return '中文';
    }
  }
}