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
  // AdMob ad units are PLATFORM-SPECIFIC: an Android unit will not serve on iOS
  // and vice-versa. Android and iOS are registered as separate apps in AdMob,
  // each with its own app ID + ad unit IDs, so every ID below is chosen per
  // platform. (Using Android IDs on iOS was why iOS ads never showed.)
  static bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  // Android app — ca-app-pub-1104992431983026~2525746081
  static const String _androidAppId         = 'ca-app-pub-1104992431983026~2525746081';
  static const String _androidBannerId       = 'ca-app-pub-1104992431983026/9538783558';
  static const String _androidInterstitialId = 'ca-app-pub-1104992431983026/9893017095';
  static const String _androidAppOpenId      = 'ca-app-pub-1104992431983026/6709136316';

  // iOS app — ca-app-pub-1104992431983026~6693731970
  static const String _iosAppId         = 'ca-app-pub-1104992431983026~6693731970';
  static const String _iosBannerId       = 'ca-app-pub-1104992431983026/8070392828';
  static const String _iosInterstitialId = 'ca-app-pub-1104992431983026/2794015415';
  static const String _iosAppOpenId      = 'ca-app-pub-1104992431983026/1480933742';

  // Google's OFFICIAL test ad units. They always fill, so we use them in debug
  // builds — real ad units return "No ad to show" (no-fill) on dev devices /
  // brand-new units, and clicking your own LIVE ads is a policy violation that
  // can get the AdMob account banned. Release builds always use the real IDs.
  static const String _testBannerIdAndroid       = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerIdIOS           = 'ca-app-pub-3940256099942544/2934735716';
  static const String _testInterstitialIdAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testInterstitialIdIOS     = 'ca-app-pub-3940256099942544/4411468910';
  static const String _testAppOpenIdAndroid      = 'ca-app-pub-3940256099942544/9257395921';
  static const String _testAppOpenIdIOS          = 'ca-app-pub-3940256099942544/5575463023';

  static String get _bannerId => kDebugMode
      ? (_isIOS ? _testBannerIdIOS : _testBannerIdAndroid)
      : (_isIOS ? _iosBannerId : _androidBannerId);
  static String get _interstitialId => kDebugMode
      ? (_isIOS ? _testInterstitialIdIOS : _testInterstitialIdAndroid)
      : (_isIOS ? _iosInterstitialId : _androidInterstitialId);
  static String get _appOpenId => kDebugMode
      ? (_isIOS ? _testAppOpenIdIOS : _testAppOpenIdAndroid)
      : (_isIOS ? _iosAppOpenId : _androidAppOpenId);

  // The app ID is declared natively (AndroidManifest.xml / iOS Info.plist), but
  // we keep both here as the single source of truth for reference.
  static String get appId => _isIOS ? _iosAppId : _androidAppId;

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
