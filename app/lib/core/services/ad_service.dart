import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Central place for all AdMob IDs and ad management.
///
/// Usage:
///   - Call [AdService.instance.loadInterstitial()] after the app is ready.
///   - Call [AdService.instance.showInterstitial()] after an expense is saved.
///   - Call [AdService.instance.loadAppOpenAd()] on app resume.
///   - Use [AdBannerWidget] in any screen for inline banner ads.
class AdService {
  AdService._();
  static final instance = AdService._();

  /// AdMob only ships for Android/iOS. Everywhere else (web, Windows, macOS,
  /// Linux) every ad call is a safe no-op so the app never crashes.
  static bool get _adsSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// True only where banner ads can render (used by [AdBannerWidget]).
  static bool get adsSupported => _adsSupported;

  // ── Ad Unit IDs ────────────────────────────────────────────────────────────
  static const String _appId        = 'ca-app-pub-1104992431983026~2525746081';
  static const String _bannerId      = 'ca-app-pub-1104992431983026/9538783558';
  static const String _interstitialId = 'ca-app-pub-1104992431983026/9893017095';
  static const String _appOpenId     = 'ca-app-pub-1104992431983026/6709136316';

  // Suppress unused warning — the app ID is used in AndroidManifest.xml
  // but we keep it here as the single source of truth.
  // ignore: unused_field
  static const String appId = _appId;

  // ── State ──────────────────────────────────────────────────────────────────
  InterstitialAd? _interstitial;
  AppOpenAd?      _appOpenAd;
  bool            _appOpenAdLoading  = false;
  bool            _appOpenAdShowing  = false;

  // Track how many records (expenses, loans, goals, personal entries…) the user
  // has added this session. Show an interstitial every 3rd save so monetisation
  // stays in the background without nagging.
  int _recordSaveCount = 0;
  static const int _interstitialFrequency = 3;

  // ── Initialization ─────────────────────────────────────────────────────────
  Future<void> init() async {
    if (!_adsSupported) return;
    await MobileAds.instance.initialize();
    // Pre-load the interstitial so it's ready after a few records are saved.
    // The App Open ad is intentionally NOT loaded/shown — it interrupted users
    // every time the app came to the foreground, which was disruptive. Banner +
    // cadence-based interstitial ads remain the monetisation surfaces.
    loadInterstitial();
  }

  // ── Interstitial ───────────────────────────────────────────────────────────
  void loadInterstitial() {
    if (!_adsSupported) return;
    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _interstitial!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdService] Interstitial failed: ${error.message}');
          _interstitial = null;
        },
      ),
    );
  }

  /// Call this after every successful record save (expense, loan, goal,
  /// personal entry, payment…). Shows an interstitial every
  /// [_interstitialFrequency] saves so the cadence is shared across the whole
  /// app rather than per-feature.
  Future<void> onRecordSaved() async {
    if (!_adsSupported) return;
    _recordSaveCount++;
    if (_recordSaveCount % _interstitialFrequency != 0) return;
    await showInterstitial();
  }

  /// Back-compat alias — group expenses already call this.
  Future<void> onExpenseSaved() => onRecordSaved();

  Future<void> showInterstitial() async {
    if (_interstitial == null) {
      loadInterstitial(); // start pre-loading for next time
      return;
    }
    _interstitial!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitial = null;
        loadInterstitial(); // pre-load the next one
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitial = null;
        loadInterstitial();
      },
    );
    await _interstitial!.show();
  }

  // ── App Open Ad ────────────────────────────────────────────────────────────
  void loadAppOpenAd() {
    if (!_adsSupported || _appOpenAdLoading) return;
    _appOpenAdLoading = true;
    AppOpenAd.load(
      adUnitId: _appOpenId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _appOpenAdLoading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdService] AppOpen failed: ${error.message}');
          _appOpenAd = null;
          _appOpenAdLoading = false;
        },
      ),
    );
  }

  /// Call this when the app returns to foreground (AppLifecycleState.resumed).
  Future<void> showAppOpenAd() async {
    if (!_adsSupported || _appOpenAdShowing || _appOpenAd == null) {
      if (!_appOpenAdLoading) loadAppOpenAd();
      return;
    }
    _appOpenAdShowing = true;
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _appOpenAdShowing = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _appOpenAdShowing = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
    );
    await _appOpenAd!.show();
  }

  // ── Banner helper ──────────────────────────────────────────────────────────
  static String get bannerId => _bannerId;
}
