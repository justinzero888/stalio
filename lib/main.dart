import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'app.dart';
import 'core/services/storage_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/ad_service.dart';
import 'core/services/iap_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
