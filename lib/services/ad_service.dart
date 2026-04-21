import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Servicio centralizado para gestionar anuncios de AdMob.
/// 
/// Usa IDs de test por defecto. Para producción, sustituir
/// [bannerAdUnitId] por el Ad Unit ID real de AdMob.
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  /// Ad Unit ID del banner (producción).
  static const String bannerAdUnitId =
      'ca-app-pub-2615746028420247/7362019261';

  bool _isInitialized = false;

  /// Inicializa el SDK de Google Mobile Ads.
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('✅ Google Mobile Ads inicializado correctamente');
    } catch (e) {
      debugPrint('❌ Error al inicializar Google Mobile Ads: $e');
    }
  }

  /// Crea y carga un BannerAd adaptable al ancho del dispositivo.
  BannerAd createBannerAd({
    required AdSize adSize,
    required void Function(Ad) onAdLoaded,
    required void Function(Ad, LoadAdError) onAdFailedToLoad,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
      ),
    );
  }
}
