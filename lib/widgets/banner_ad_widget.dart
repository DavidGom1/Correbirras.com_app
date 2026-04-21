import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:correbirras/services/ad_service.dart';

/// Widget reutilizable que muestra un banner de AdMob en la parte inferior.
///
/// Gestiona automáticamente el ciclo de vida del anuncio:
/// carga al inicializar y dispose al destruirse.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bannerAd == null) {
      _loadAd();
    }
  }

  void _loadAd() {
    // Usar un tamaño de banner estándar
    const adSize = AdSize.banner; // 320x50

    final adService = AdService();
    _bannerAd = adService.createBannerAd(
      adSize: adSize,
      onAdLoaded: (ad) {
        debugPrint('✅ Banner ad cargado correctamente');
        if (mounted) {
          setState(() {
            _isAdLoaded = true;
          });
        }
      },
      onAdFailedToLoad: (ad, error) {
        debugPrint('❌ Error al cargar banner ad: ${error.message}');
        ad.dispose();
        if (mounted) {
          setState(() {
            _bannerAd = null;
            _isAdLoaded = false;
          });
        }
      },
    );
    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _bannerAd == null) {
      // Reservar espacio para evitar saltos de layout cuando cargue
      return const SizedBox(
        height: 50, // Altura estándar del banner
        child: Center(
          child: SizedBox.shrink(),
        ),
      );
    }

    return Container(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      alignment: Alignment.center,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
