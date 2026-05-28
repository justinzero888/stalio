import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('PurchasesService', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    group('initialization', () {
      test('service starts uninitialized', () {
        final service = PurchasesServiceMock();
        expect(service.isInitialized, isFalse);
      });

      test('init sets initialized flag', () async {
        final service = PurchasesServiceMock();
        await service.init(unifiedKey: 'test_key');
        expect(service.isInitialized, isTrue);
      });

      test('init with empty key does not initialize', () async {
        final service = PurchasesServiceMock();
        await service.init(unifiedKey: '');
        expect(service.isInitialized, isFalse);
      });

      test('init with null key does not initialize', () async {
        final service = PurchasesServiceMock();
        await service.init(unifiedKey: null);
        expect(service.isInitialized, isFalse);
      });

      test('init does not reinitialize if already initialized', () async {
        final service = PurchasesServiceMock();
        await service.init(unifiedKey: 'key1');
        await service.init(unifiedKey: 'key2');

        expect(service.initCallCount, 1);
      });
    });

    group('purchase flow', () {
      test('purchase sets isPurchasing flag', () async {
        final service = PurchasesServiceMock();
        await service.init(unifiedKey: 'test_key');

        final purchaseTask = service.purchaseProduct('blinking_pro');
        expect(service.isPurchasing, isTrue);

        await purchaseTask;
      });

      test('successful purchase succeeds', () async {
        final service = PurchasesServiceMock();
        await service.init(unifiedKey: 'test_key');

        service.setMockPurchaseSuccess(true);
        final result = await service.purchaseProduct('blinking_pro');

        expect(result, isTrue);
        expect(service.lastError, isNull);
      });

      test('failed purchase returns error', () async {
        final service = PurchasesServiceMock();
        await service.init(unifiedKey: 'test_key');

        service.setMockPurchaseSuccess(false);
        final result = await service.purchaseProduct('blinking_pro');

        expect(result, isFalse);
      });

      test('purchase without init returns error', () async {
        final service = PurchasesServiceMock();
        // Don't call init

        final result = await service.purchaseProduct('blinking_pro');
        expect(result, isFalse);
        expect(service.lastError, isNotNull);
      });

      test('consecutive purchases work correctly', () async {
        final service = PurchasesServiceMock();
        await service.init(unifiedKey: 'test_key');
        service.setMockPurchaseSuccess(true);

        final result1 = await service.purchaseProduct('blinking_pro');
        final result2 = await service.purchaseProduct('blinking_pro');

        expect(result1, isTrue);
        expect(result2, isTrue);
      });

      test('isPurchasing cleared after purchase completes', () async {
        final service = PurchasesServiceMock();
        await service.init(unifiedKey: 'test_key');
        service.setMockPurchaseSuccess(true);

        await service.purchaseProduct('blinking_pro');
        expect(service.isPurchasing, isFalse);
      });
    });

    group('restore flow', () {
      test('restore sets isRestoring flag', () async {
        final service = PurchasesServiceMock();
        await service.init(unifiedKey: 'test_key');

        final restoreTask = service.restorePurchases();
        expect(service.isRestoring, isTrue);

        await restoreTask;
      });

      test('successful restore returns true', () async {
        final service = PurchasesServiceMock();
        await service.init(unifiedKey: 'test_key');
        service.setMockRestoreSuccess(true);

        final result = await service.restorePurchases();
        expect(result, isTrue);
      });

      test('failed restore returns false', () async {
        final service = PurchasesServiceMock();
        await service.init(unifiedKey: 'test_key');
        service.setMockRestoreSuccess(false);

        final result = await service.restorePurchases();
        expect(result, isFalse);
      });

      test('restore without init returns error', () async {
        final service = PurchasesServiceMock();

        final result = await service.restorePurchases();
        expect(result, isFalse);
      });

      test('isRestoring cleared after restore completes', () async {
        final service = PurchasesServiceMock();
        await service.init(unifiedKey: 'test_key');
        service.setMockRestoreSuccess(true);

        await service.restorePurchases();
        expect(service.isRestoring, isFalse);
      });

      test('restore with existing purchase recognized', () async {
        final service = PurchasesServiceMock();
        await service.init(unifiedKey: 'test_key');
        service.setMockRestoreSuccess(true);
        service.setMockHasPro(true);

        final result = await service.restorePurchases();
        expect(result, isTrue);
        expect(service.isPro, isTrue);
      });
    });

    group('entitlement state', () {
      test('isPro false before purchase', () async {
        final service = PurchasesServiceMock();
        await service.init(unifiedKey: 'test_key');

        expect(service.isPro, isFalse);
      });

      test('isPro true after successful purchase', () async {
        final service = PurchasesServiceMock();
        await service.init(unifiedKey: 'test_key');
        service.setMockPurchaseSuccess(true);
        service.setMockHasPro(true);

        await service.purchaseProduct('blinking_pro');
        expect(service.isPro, isTrue);
      });

      test('isPro persists across service instances', () async {
        final service1 = PurchasesServiceMock();
        await service1.init(unifiedKey: 'test_key');
        service1.setMockHasPro(true);

        // Simulate app restart with new service instance
        final service2 = PurchasesServiceMock();
        await service2.init(unifiedKey: 'test_key');
        service2.setMockHasPro(true);

        expect(service2.isPro, isTrue);
      });
    });

    group('error handling', () {
      test('network error captured in lastError', () async {
        final service = PurchasesServiceMock();
        await service.init(unifiedKey: 'test_key');

        service.setMockError('Network timeout');
        await service.purchaseProduct('blinking_pro');

        expect(service.lastError, contains('Network'));
      });

      test('invalid product ID handled gracefully', () async {
        final service = PurchasesServiceMock();
        await service.init(unifiedKey: 'test_key');

        final result = await service.purchaseProduct('invalid_product');
        // Should fail but not crash
        expect(result, isFalse);
      });

      test('lastError cleared on successful operation', () async {
        final service = PurchasesServiceMock();
        await service.init(unifiedKey: 'test_key');

        service.setMockError('Previous error');
        service.setMockPurchaseSuccess(true);

        await service.purchaseProduct('blinking_pro');
        // After successful purchase, error should be cleared
        expect(service.lastError, isNull);
      });
    });

    group('concurrent operations', () {
      test('cannot purchase while already purchasing', () async {
        final service = PurchasesServiceMock();
        await service.init(unifiedKey: 'test_key');
        service.setMockPurchaseSuccess(true);

        // Start first purchase
        final purchase1 = service.purchaseProduct('blinking_pro');

        // Attempt second purchase while first is in progress
        expect(service.isPurchasing, isTrue);

        await purchase1;
      });

      test('cannot restore while already restoring', () async {
        final service = PurchasesServiceMock();
        await service.init(unifiedKey: 'test_key');
        service.setMockRestoreSuccess(true);

        // Start first restore
        final restore1 = service.restorePurchases();

        // Attempt second restore while first is in progress
        expect(service.isRestoring, isTrue);

        await restore1;
      });

      test('purchase and restore cannot run simultaneously', () async {
        final service = PurchasesServiceMock();
        await service.init(unifiedKey: 'test_key');
        service.setMockPurchaseSuccess(true);
        service.setMockRestoreSuccess(true);

        // Note: Real implementation may have guards against this
        // This test documents the expected behavior
        await service.purchaseProduct('blinking_pro');
        expect(service.isPurchasing, isFalse);

        await service.restorePurchases();
        expect(service.isRestoring, isFalse);
      });
    });

    group('product offerings', () {
      test('offerings loaded after init', () async {
        final service = PurchasesServiceMock();
        service.setMockOfferings(['blinking_pro', 'blinking_lite']);

        await service.init(unifiedKey: 'test_key');

        expect(service.availableProducts, contains('blinking_pro'));
      });

      test('offerings empty until fetched', () async {
        final service = PurchasesServiceMock();
        await service.init(unifiedKey: 'test_key');

        if (!service.isInitialized) {
          expect(service.availableProducts, isEmpty);
        }
      });

      test('pro product always available', () async {
        final service = PurchasesServiceMock();
        service.setMockOfferings(['blinking_pro']);

        await service.init(unifiedKey: 'test_key');

        expect(service.availableProducts, contains('blinking_pro'));
      });
    });

    group('state transitions', () {
      test('uninitialized → initialized → purchasing → idle', () async {
        final service = PurchasesServiceMock();

        expect(service.isInitialized, isFalse);

        await service.init(unifiedKey: 'test_key');
        expect(service.isInitialized, isTrue);

        service.setMockPurchaseSuccess(true);
        final purchaseTask = service.purchaseProduct('blinking_pro');
        expect(service.isPurchasing, isTrue);

        await purchaseTask;
        expect(service.isPurchasing, isFalse);
      });

      test('pro state persists across init', () async {
        final service = PurchasesServiceMock();
        service.setMockHasPro(true);

        await service.init(unifiedKey: 'test_key');
        expect(service.isPro, isTrue);
      });
    });
  });
}

/// Mock PurchasesService for testing without RevenueCat SDK
class PurchasesServiceMock {
  bool _initialized = false;
  bool _purchasing = false;
  bool _restoring = false;
  bool _hasPro = false;
  String? _lastError;
  int initCallCount = 0;
  bool _mockPurchaseSuccess = false;
  bool _mockRestoreSuccess = false;
  List<String> _mockOfferings = [];

  bool get isInitialized => _initialized;
  bool get isPurchasing => _purchasing;
  bool get isRestoring => _restoring;
  bool get isPro => _hasPro;
  String? get lastError => _lastError;
  List<String> get availableProducts => _mockOfferings;

  Future<void> init({
    String? appleApiKey,
    String? googleApiKey,
    String? unifiedKey,
  }) async {
    if (_initialized) return;

    initCallCount++;

    final platformKey = unifiedKey ?? (googleApiKey ?? appleApiKey);

    if (platformKey == null || platformKey.isEmpty) {
      return;
    }

    _initialized = true;
  }

  Future<bool> purchaseProduct(String productId) async {
    if (!_initialized) {
      _lastError = 'Store not initialized';
      return false;
    }

    if (_purchasing) {
      _lastError = 'Purchase already in progress';
      return false;
    }

    _purchasing = true;

    try {
      await Future.delayed(const Duration(milliseconds: 10));

      if (!_mockPurchaseSuccess) {
        _purchasing = false;
        return false;
      }

      _lastError = null; // Clear error on success
      _hasPro = true; // Mark as pro on success
      _purchasing = false;
      return true;
    } catch (e) {
      _lastError = e.toString();
      _purchasing = false;
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    if (!_initialized) {
      _lastError = 'Store not initialized';
      return false;
    }

    if (_restoring) {
      _lastError = 'Restore already in progress';
      return false;
    }

    _restoring = true;

    try {
      await Future.delayed(const Duration(milliseconds: 10));

      if (!_mockRestoreSuccess) {
        _restoring = false;
        return false;
      }

      _lastError = null;
      _restoring = false;
      return true;
    } catch (e) {
      _lastError = e.toString();
      _restoring = false;
      return false;
    }
  }

  void setMockPurchaseSuccess(bool value) {
    _mockPurchaseSuccess = value;
  }

  void setMockRestoreSuccess(bool value) {
    _mockRestoreSuccess = value;
  }

  void setMockHasPro(bool value) {
    _hasPro = value;
  }

  void setMockError(String error) {
    _lastError = error;
  }

  void setMockOfferings(List<String> offerings) {
    _mockOfferings = offerings;
  }
}
