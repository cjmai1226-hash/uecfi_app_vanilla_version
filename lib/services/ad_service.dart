import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class AdService {
  static final AdService _instance = AdService._internal();

  factory AdService() {
    return _instance;
  }

  AdService._internal();

  static const String _appOpenAdUnitId =
      'ca-app-pub-8333503696162383/8257320695';
  static const String _bannerAdUnitId =
      'ca-app-pub-8333503696162383/6101930646';
  static const String _interstitialAdUnitId =
      'ca-app-pub-8333503696162383/4788848973';
  static const String _rewardedAdUnitId =
      'ca-app-pub-8333503696162383/2814402267'; // Replace

  static const String _testAppOpenAndroidId =
      'ca-app-pub-3940256099942544/9257395921';
  static const String _testAppOpenIOSId =
      'ca-app-pub-3940256099942544/5532089241';

  static const String _testBannerAndroidId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerIOSId =
      'ca-app-pub-3940256099942544/2934735716';

  static const String _testInterstitialAndroidId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testInterstitialIOSId =
      'ca-app-pub-3940256099942544/4411468910';

  static const String _testRewardedAndroidId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _testRewardedIOSId =
      'ca-app-pub-3940256099942544/1712485313';

  AppOpenAd? _appOpenAd;
  InterstitialAd? _interstitialAd;
  int _interstitialClickCount = 0;

  Future<void> initializeMobileAds() async {
    await MobileAds.instance.initialize();
  }

  String get _appOpenId {
    if (kDebugMode) {
      return Platform.isIOS ? _testAppOpenIOSId : _testAppOpenAndroidId;
    }
    return _appOpenAdUnitId;
  }

  String getBannerAdUnitId() {
    if (kDebugMode) {
      return Platform.isIOS ? _testBannerIOSId : _testBannerAndroidId;
    }
    return _bannerAdUnitId;
  }

  String get _interstitialId {
    if (kDebugMode) {
      return Platform.isIOS
          ? _testInterstitialIOSId
          : _testInterstitialAndroidId;
    }
    return _interstitialAdUnitId;
  }

  String get _rewardedId {
    if (kDebugMode) {
      return Platform.isIOS ? _testRewardedIOSId : _testRewardedAndroidId;
    }
    return _rewardedAdUnitId;
  }

  // AppOpen Ad for Cold Start
  void loadAndShowAppOpenAd() {
    AppOpenAd.load(
      adUnitId: _appOpenId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('AppOpen ad loaded and showing');
          _appOpenAd = ad;
          _appOpenAd!.show();
        },
        onAdFailedToLoad: (error) {
          debugPrint('AppOpen ad failed to load: $error');
        },
      ),
    );
  }

  // Interstitial Ad
  void showInterstitialAd({bool requireCounter = false}) {
    if (requireCounter) {
      _interstitialClickCount++;
      // Show ad every 3 clicks
      if (_interstitialClickCount % 3 != 0) {
        return;
      }
    }

    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Interstitial ad loaded and showing');
          _interstitialAd = ad;
          _interstitialAd!.show();
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad failed to load: $error');
        },
      ),
    );
  }

  // Rewarded Ad with fallback
  Future<void> showRewardedAdDialog({
    required BuildContext context,
    required VoidCallback onReward,
    String title = 'Support Us',
    String content = 'Watch a short ad to continue?',
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // dismiss without reward
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _loadAndShowRewardedAd(context, onReward);
            },
            child: const Text('Watch Ad'),
          ),
        ],
      ),
    );
  }

  void _loadAndShowRewardedAd(BuildContext context, VoidCallback onReward) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    RewardedAd.load(
      adUnitId: _rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          Navigator.pop(context); // hide loading
          ad.show(
            onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
              onReward();
            },
          );
        },
        onAdFailedToLoad: (error) {
          Navigator.pop(context); // hide loading
          debugPrint('Rewarded ad failed to load: $error');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not load ad. Proceeding...')),
          );
          onReward(); // Fallback to proceed if it simply fails
        },
      ),
    );
  }

  void dispose() {
    _appOpenAd?.dispose();
    _interstitialAd?.dispose();
  }
}

class AdBannerWidget extends StatefulWidget {
  final double height;
  const AdBannerWidget({super.key, this.height = 50.0});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  late BannerAd _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _createBannerAd();
  }

  void _createBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdService().getBannerAdUnitId(),
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
            });
          }
        },
      ),
    );
    _bannerAd.load();
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded) {
      return const SizedBox.shrink();
    }
    return Center(
      child: Container(
        alignment: Alignment.center,
        width: _bannerAd.size.width.toDouble(),
        height: _bannerAd.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd),
      ),
    );
  }
}

