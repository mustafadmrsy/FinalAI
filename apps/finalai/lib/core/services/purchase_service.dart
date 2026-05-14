import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

// ═══════════════════════════════════════════════════════════════
//  PURCHASE SERVICE — In-App Purchase (Premium Subscriptions)
//  Google Play Console urun ID'leri:
//    Subscriptions:  premium_plus, premium_pro
//    Consumables:    pdf_credits_5
// ═══════════════════════════════════════════════════════════════

// Urun ID'leri — Google Play Console'da ayni ID ile olustur
class ProductIds {
  static const premiumPlus = 'premium_plus';
  static const premiumPro = 'premium_pro';
  static const premiumPlusMonthly = 'premium_plus_monthly';
  static const premiumProMonthly = 'premium_pro_monthly';
  static const pdfCredits5 = 'pdf_credits_5';

  static const subscriptions = {premiumPlus, premiumPro, premiumPlusMonthly, premiumProMonthly};
  static const consumables = {pdfCredits5};
  static const all = {...subscriptions, ...consumables};

  /// Plan ismi
  static String nameOf(String id) => switch (id) {
    premiumPlus || premiumPlusMonthly => 'FinalAI Plus',
    premiumPro || premiumProMonthly => 'FinalAI Pro',
    pdfCredits5 => '5 PDF Hakki',
    _ => '',
  };

  /// PDF hakki miktari
  static int pdfCreditsFor(String id) => switch (id) {
    pdfCredits5 => 5,
    _ => 0,
  };
}

typedef OnPurchaseCallback = Future<void> Function(String productId);

class PurchaseService {
  PurchaseService._();
  static final instance = PurchaseService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Map<String, ProductDetails> _products = {};
  bool _available = false;

  OnPurchaseCallback? onSubscriptionPurchased;
  OnPurchaseCallback? onConsumablePurchased;

  bool get isAvailable => _available;
  Map<String, ProductDetails> get products => _products;

  /// Initialize and start listening to purchases
  Future<void> initialize() async {
    _available = await _iap.isAvailable();
    if (!_available) {
      debugPrint('PurchaseService: Store not available');
      return;
    }

    // Urunleri yukle
    final response = await _iap.queryProductDetails(ProductIds.all);
    if (response.error != null) {
      debugPrint('PurchaseService: Query error: ${response.error!.message}');
    }
    _products = {for (final p in response.productDetails) p.id: p};
    debugPrint('PurchaseService: Loaded ${_products.length} products');

    // Satin alma akisini dinle
    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (e) => debugPrint('PurchaseService: Stream error: $e'),
    );
  }

  void dispose() {
    _subscription?.cancel();
  }

  /// Urun fiyatini getir (yoksa fallback)
  String priceOf(String productId, {String fallback = '—'}) {
    return _products[productId]?.price ?? fallback;
  }

  /// Satin alma baslat
  Future<bool> buy(String productId) async {
    final product = _products[productId];
    if (product == null) {
      debugPrint('PurchaseService: Product not found: $productId');
      return false;
    }

    final param = PurchaseParam(productDetails: product);
    try {
      if (ProductIds.consumables.contains(productId)) {
        return await _iap.buyConsumable(purchaseParam: param);
      } else {
        return await _iap.buyNonConsumable(purchaseParam: param);
      }
    } catch (e) {
      debugPrint('PurchaseService: Buy error: $e');
      return false;
    }
  }

  /// Satin alim geri yukle (restore)
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _verifyAndDeliver(purchase);
          break;
        case PurchaseStatus.error:
          debugPrint('PurchaseService: Error: ${purchase.error?.message}');
          if (purchase.pendingCompletePurchase) {
            _iap.completePurchase(purchase);
          }
          break;
        case PurchaseStatus.pending:
          debugPrint('PurchaseService: Pending: ${purchase.productID}');
          break;
        case PurchaseStatus.canceled:
          debugPrint('PurchaseService: Canceled: ${purchase.productID}');
          if (purchase.pendingCompletePurchase) {
            _iap.completePurchase(purchase);
          }
          break;
      }
    }
  }

  Future<void> _verifyAndDeliver(PurchaseDetails purchase) async {
    // TODO: Server-side receipt validation (guclu guvenlik icin)
    // Simdilik client-side dogrulama

    final productId = purchase.productID;

    if (ProductIds.subscriptions.contains(productId)) {
      await onSubscriptionPurchased?.call(productId);
      debugPrint('PurchaseService: Subscription delivered: $productId');
    } else if (ProductIds.consumables.contains(productId)) {
      await onConsumablePurchased?.call(productId);
      debugPrint('PurchaseService: Consumable delivered: $productId');
    }

    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }
}
