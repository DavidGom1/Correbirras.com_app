import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // Banner ad unit ID de Correbirras
  static const String _bannerAdUnitId =
      'ca-app-pub-2615746028420247/7362019261';

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  bool get isBannerAdLoaded => _isBannerAdLoaded;

  /// Inicializa el SDK de Mobile Ads. Llamar una vez al inicio de la app.
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
    debugPrint("✅ AdMob SDK inicializado");
  }

  /// Carga el banner ad. Llamar desde initState().
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
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint("❌ Banner ad falló al cargar: $error");
          ad.dispose();
          _bannerAd = null;
          _isBannerAdLoaded = false;
        },
      ),
    );

    _bannerAd!.load();
  }

  /// Widget del banner para colocar en el layout.
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

  /// Liberar recursos del banner.
  void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdLoaded = false;
  }
}
