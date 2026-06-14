import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'app.dart';
import 'core/services/storage_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/ad_service.dart';
import 'core/services/iap_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: 'AIzaSyANONYMOUS_PLACEHOLDER_KEY',
        appId: '1:000000000000:ios:0000000000000000000000',
        messagingSenderId: '000000000000',
        projectId: 'stalio-app',
      ),
    );
    FlutterError.onError = (error) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(error);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    debugPrint('Firebase init skipped: $e');
  }

  if (kDebugMode || kProfileMode) {
    SemanticsBinding.instance.ensureSemantics();
  }

  final storageService = StorageService();
  await storageService.init();

  await NotificationService.init();
  await AdService.initialize();
  await IapService.initialize();
  IapService.handlePurchaseUpdates();

  runApp(StalioApp(storageService: storageService));
}
