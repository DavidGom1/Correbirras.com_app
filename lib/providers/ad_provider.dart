import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdProvider extends ChangeNotifier {
  static const String _bannerAdUnitId = 'ca-app-pub-2615746028420247/7362019261';

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  bool get isBannerAdLoaded => _isBannerAdLoaded;

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
    debugPrint("✅ AdMob SDK inicializado");
  }

  void loadBannerAd({VoidCallback? onLoaded}) {
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          debugPrint("✅ Banner ad cargado");
          _isBannerAdLoaded = true;
          onLoaded?.call();
          notifyListeners();
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint("❌ Banner ad falló al cargar: $error");
          ad.dispose();
          _bannerAd = null;
          _isBannerAdLoaded = false;
          notifyListeners();
        },
      ),
    );
    _bannerAd!.load();
  }

  Widget getBannerWidget() {
    if (_bannerAd == null || !_isBannerAdLoaded) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdLoaded = false;
    super.dispose();
  }
}