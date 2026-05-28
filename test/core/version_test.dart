import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:blinking/core/config/constants.dart';

void main() {
  group('App version consistency', () {
    // Regression: v1.1.0 beta had AppConstants.appVersion = '1.0.0' while
    // pubspec.yaml was '1.1.0-beta.1+9'. The Settings "About" tile showed the
    // wrong version to users. Fix: keep both in sync manually; this test
    // catches future drift.
    test('AppConstants.appVersion matches semver prefix in pubspec.yaml', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();

      // Extract "version: X.Y.Z..." line
      final match = RegExp(r'^version:\s+(\S+)', multiLine: true).firstMatch(pubspec);
      expect(match, isNotNull, reason: 'pubspec.yaml must have a version: line');

      final pubspecVersion = match!.group(1)!; // e.g. "1.1.0-beta.1+9"

      // Strip build number (+N) to get the display version
      final displayVersion = pubspecVersion.split('+').first; // "1.1.0-beta.1"

      expect(
        AppConstants.appVersion,
        equals(displayVersion),
        reason: 'AppConstants.appVersion must match the pubspec version (without build number). '
            'Found pubspec="$pubspecVersion", constant="${AppConstants.appVersion}".',
      );
    });

    test('AppConstants.appVersion is non-empty', () {
      expect(AppConstants.appVersion, isNotEmpty);
    });

    test('AppConstants.appName is Blinking', () {
      expect(AppConstants.appName, 'Blinking');
    });
  });
}
