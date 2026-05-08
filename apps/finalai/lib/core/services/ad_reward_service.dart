import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// ═══════════════════════════════════════════════════════════════
//  AD REWARD SERVICE — Google Rewarded Ads
//  Reklam izleyerek enerji, PDF kredi, AI token kazanma
// ═══════════════════════════════════════════════════════════════

class AdRewardService {
  AdRewardService._();
  static final instance = AdRewardService._();

  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  // Android: production — iOS: test (iOS app henuz olusturulmadi)
  static const _androidAdUnitId = 'ca-app-pub-9992925769931813/2729527737';
  static const _iosAdUnitId = 'ca-app-pub-3940256099942544/1712485313';

  String get _adUnitId {
    if (defaultTargetPlatform == TargetPlatform.android) return _androidAdUnitId;
    return _iosAdUnitId;
  }

  /// Initialize Mobile Ads SDK
  static Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();
      instance._preload();
    } catch (e) {
      debugPrint('AdRewardService.initialize failed: $e');
    }
  }

  /// Preload a rewarded ad
  void _preload() {
    if (_rewardedAd != null || _isLoading) return;
    _isLoading = true;

    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
          debugPrint('AdRewardService: Ad loaded');
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isLoading = false;
          debugPrint('AdRewardService: Ad failed to load: ${error.message}');
        },
      ),
    );
  }

  /// Is ad ready to show?
  bool get isAdReady => _rewardedAd != null;

  /// Show rewarded ad and return true if reward was earned
  Future<bool> showRewardedAd() async {
    if (_rewardedAd == null) {
      _preload();
      return false;
    }

    final completer = Completer<bool>();

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _preload(); // Pre-load next ad
        if (!completer.isCompleted) completer.complete(false);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _preload();
        if (!completer.isCompleted) completer.complete(false);
        debugPrint('AdRewardService: Ad failed to show: ${error.message}');
      },
    );

    _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
      debugPrint('AdRewardService: User earned ${reward.amount} ${reward.type}');
      if (!completer.isCompleted) completer.complete(true);
    });

    return completer.future;
  }
}
