import 'package:in_app_purchase/in_app_purchase.dart';
import 'ad_service.dart';

class IapService {
  static const _productId = 'stalio_removeads_v1';
  static final _iap = InAppPurchase.instance;
  static bool _available = false;

  static bool get isAvailable => _available;

  static Future<void> initialize() async {
    _available = await _iap.isAvailable();
  }

  static Future<ProductDetails?> getProduct() async {
    if (!_available) return null;
    final response = await _iap.queryProductDetails({_productId});
    if (response.error != null || response.productDetails.isEmpty) return null;
    return response.productDetails.first;
  }

  static Future<bool> buyRemoveAds() async {
    if (!_available) return false;
    final product = await getProduct();
    if (product == null) return false;

    final purchaseParam = PurchaseParam(productDetails: product);
    return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  static Future<bool> restorePurchases() async {
    if (!_available) return false;
    await _iap.restorePurchases();
    // Purchase restored via purchaseStream listener
    return true;
  }

  static void handlePurchaseUpdates() {
    _iap.purchaseStream.listen((purchases) {
      for (final p in purchases) {
        if (p.productID == _productId && p.status == PurchaseStatus.purchased) {
          AdService.markAdsRemoved();
          _iap.completePurchase(p);
        }
      }
    });
  }
}
