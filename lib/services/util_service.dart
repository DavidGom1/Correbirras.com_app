import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:in_app_review/in_app_review.dart';
import '../models/race.dart';

class UtilService {
  static final UtilService _instance = UtilService._internal();
  factory UtilService() => _instance;
  UtilService._internal();

  Future<void> sendEmail(String emailAddress) async {
    final Uri emailLaunchUri = Uri(scheme: 'mailto', path: emailAddress);
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      throw 'Could not launch $emailAddress';
    }
  }

  Future<bool> rateApp({String? packageName}) async {
    final InAppReview inAppReview = InAppReview.instance;
    final String appPackage = packageName ?? 'com.correbirras.agenda';

    try {
      final isAvailable = await inAppReview.isAvailable();
      if (isAvailable) {
        await inAppReview.requestReview();
        return true;
      }
    } catch (e) {
      debugPrint('InAppReview no disponible: $e');
    }

    final Uri marketUri = Uri.parse('market://details?id=$appPackage');
    if (await canLaunchUrl(marketUri)) {
      await launchUrl(marketUri);
      return true;
    }

    final Uri webUri = Uri.parse(
      'https://play.google.com/store/apps/details?id=$appPackage',
    );
    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
      return true;
    }

    return false;
  }

  Future<void> launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $uri';
    }
  }

  void shareRace(Race race) {
    final String shareText =
        '''
🏃‍♂️ ¡Echa un vistazo a esta carrera!

📅 Carrera: ${race.name}
📍 Fecha: ${race.date ?? 'No disponible'} - ${race.displayMonth}${race.hora != null && race.hora!.isNotEmpty ? ' (${race.hora})' : ''}
🌍 Zona: ${race.displayZone}
🏃 Tipo: ${race.type ?? 'No especificado'}${race.senderista ? ' 🥾' : ''}
📏 Distancias: ${race.displayDistances}
💰 Precio: ${race.precio ?? 'No especificado'}€

${race.registrationLink?.isNotEmpty ?? false ? '🔗 Más información: ${race.registrationLink}' : ''}

¡Encontrado en Correbirras! 🏃‍♀️🏃‍♂️
    '''
            .trim();

    Share.share(shareText);
  }

  bool isSocialMediaUrl(String url) {
    final String lowerUrl = url.toLowerCase();
    final List<String> socialMediaDomains = [
      'facebook.com',
      'instagram.com',
      'twitter.com',
      'x.com',
      'youtube.com',
      'linkedin.com',
      'tiktok.com',
    ];

    return socialMediaDomains.any((domain) => lowerUrl.contains(domain));
  }

  bool isPdfUrl(String url) {
    return url.toLowerCase().endsWith('.pdf');
  }

  bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (_) {
      return false;
    }
  }
}