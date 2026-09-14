// ignore_for_file: discarded_futures

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'audio_service.dart';

class AdMobService {
  static RewardedAd? _rewardedAd;
  static bool _isAdLoading = false;
  static bool _isAdShowing = false;
  static bool _initialized = false;
  static int _failedLoadAttempts = 0;
  static const int _maxFailedLoadAttempts = 3;

  static String? get rewardedAdUnitId {
    if (kIsWeb) return null;
    if (Platform.isAndroid) {
      const productionId = String.fromEnvironment('ADMOB_REWARDED_ANDROID_ID');
      return kReleaseMode ? (productionId.isEmpty ? null : productionId) : 'ca-app-pub-3940256099942544/5224354917';
    }
    if (Platform.isIOS) {
      const productionId = String.fromEnvironment('ADMOB_REWARDED_IOS_ID');
      return kReleaseMode ? (productionId.isEmpty ? null : productionId) : 'ca-app-pub-3940256099942544/1712485313';
    }
    return null;
  }

  static Future<void> initialize() async {
    if (_initialized || rewardedAdUnitId == null) return;
    await MobileAds.instance.initialize();
    _initialized = true;
    loadRewardedAd();
  }

  static void loadRewardedAd() {
    final unitId = rewardedAdUnitId;
    if (!_initialized || unitId == null || _isAdLoading || _rewardedAd != null) return;
    _isAdLoading = true;
    RewardedAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isAdLoading = false;
          _failedLoadAttempts = 0;
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isAdLoading = false;
          _failedLoadAttempts++;
          debugPrint('Rewarded ad failed to load: $error');
          if (_failedLoadAttempts < _maxFailedLoadAttempts) loadRewardedAd();
        },
      ),
    );
  }

  static void showRewardedAd({
    required BuildContext context,
    required VoidCallback onRewardEarned,
    VoidCallback? onUnavailable,
  }) {
    if (_isAdShowing) return;
    final unitId = rewardedAdUnitId;
    if (!_initialized || unitId == null) {
      _showUnavailable(context);
      onUnavailable?.call();
      return;
    }

    final cachedAd = _rewardedAd;
    if (cachedAd != null) {
      _rewardedAd = null;
      _showLoadedAd(cachedAd, onRewardEarned, onUnavailable);
      return;
    }

    _isAdShowing = true;
    var loaderOpen = true;
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFC5A059)),
      ),
    );

    void closeLoader() {
      if (!loaderOpen) return;
      loaderOpen = false;
      final navigator = Navigator.maybeOf(context, rootNavigator: true);
      if (navigator?.canPop() ?? false) navigator!.pop();
    }

    RewardedAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          closeLoader();
          _isAdShowing = false;
          _showLoadedAd(ad, onRewardEarned, onUnavailable);
        },
        onAdFailedToLoad: (error) {
          closeLoader();
          _isAdShowing = false;
          debugPrint('On-demand rewarded ad failed to load: $error');
          if (context.mounted) _showUnavailable(context);
          onUnavailable?.call();
          loadRewardedAd();
        },
      ),
    );
  }

  static void _showLoadedAd(RewardedAd ad, VoidCallback onRewardEarned, VoidCallback? onUnavailable) {
    if (_isAdShowing) {
      ad.dispose();
      return;
    }
    _isAdShowing = true;
    var rewardGranted = false;
    AudioService.instance.pauseBgm(reason: 'rewarded_ad');

    void finish(RewardedAd finishedAd) {
      finishedAd.dispose();
      _isAdShowing = false;
      AudioService.instance.resumeBgm(reason: 'rewarded_ad');
      loadRewardedAd();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: finish,
      onAdFailedToShowFullScreenContent: (failedAd, error) {
        debugPrint('Rewarded ad failed to show: $error');
        if (!rewardGranted) onUnavailable?.call();
        finish(failedAd);
      },
    );
    ad.setImmersiveMode(true);
    ad.show(onUserEarnedReward: (_, __) {
      if (rewardGranted) return;
      rewardGranted = true;
      onRewardEarned();
    });
  }

  static void _showUnavailable(BuildContext context) {
    if (!context.mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(
        content: Text('Reklam şu anda kullanılamıyor. Lütfen biraz sonra tekrar deneyin.'),
      ),
    );
  }

  static void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isAdLoading = false;
    _isAdShowing = false;
  }
}
