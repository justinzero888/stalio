import 'dart:convert';
import 'dart:io' show Platform;
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

/// Generates an anonymous device fingerprint that survives app reinstall
/// on both iOS and Android. No PII, no tracking, no permissions needed.
class DeviceFingerprintService {
  /// Returns a fingerprint string or null if unavailable.
  /// iOS: identifierForVendor → sha256
  /// Android: ANDROID_ID → sha256
  static Future<String?> getFingerprint() async {
    try {
      if (Platform.isIOS) {
        return await _getIOSFingerprint();
      } else if (Platform.isAndroid) {
        return await _getAndroidFingerprint();
      }
    } catch (_) {
      // Fingerprint generation failed — preview will work without server-side
      // identity check. Server skips fingerprint when not provided.
    }
    return null;
  }

  /// iOS: identifierForVendor → sha256. Survives reinstalls when at least
  /// one app from the same developer remains (common case: most users just
  /// reinstall the app, not the entire developer catalog).
  static Future<String?> _getIOSFingerprint() async {
    try {
      const channel = MethodChannel('blinking/device');
      final idfv = await channel.invokeMethod<String>('getIdentifierForVendor');
      if (idfv != null && idfv.isNotEmpty) {
        return sha256.convert(utf8.encode('ios:$idfv')).toString();
      }
    } catch (_) {}
    return null;
  }

  /// Android: ANDROID_ID survives reinstalls since Android 8.0.
  /// Scoped to app signing key — anonymous, no permissions required.
  static Future<String?> _getAndroidFingerprint() async {
    try {
      const channel = MethodChannel('blinking/device');
      final androidId = await channel.invokeMethod<String>('getAndroidId');
      if (androidId != null && androidId.isNotEmpty) {
        return sha256.convert(utf8.encode('android:$androidId')).toString();
      }
    } catch (_) {}
    return null;
  }
}
