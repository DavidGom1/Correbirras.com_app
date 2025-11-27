import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/race.dart';

class UtilService {
  static final UtilService _instance = UtilService._internal();
  factory UtilService() => _instance;
  UtilService._internal();

  // Function to send email
  Future<void> sendEmail(String emailAddress) async {
    final Uri emailLaunchUri = Uri(scheme: 'mailto', path: emailAddress);
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      throw 'Could not launch $emailLaunchUri';
    }
  }

  // Function to rate the app on Google Play
  Future<void> rateApp({String? packageName}) async {
    const String defaultPackage = 'com.correbirras.agenda';
    final String appPackage = packageName ?? defaultPackage;
    final Uri storeUri = Uri.parse(
      'market://details?id=$appPackage&showAllReviews=true',
    );

    if (await canLaunchUrl(storeUri)) {
      await launchUrl(storeUri, mode: LaunchMode.externalApplication);
      return;
    }

    final Uri webUri = Uri.parse(
      'https://play.google.com/store/apps/details?id=$appPackage&showAllReviews=true',
    );
    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $webUri';
    }
  }

  // Modified _launchURL function to open in external apps for social media
  Future<void> launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      // Use externalApplication for social media links
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $uri';
    }
  }

  // Function to share race information
  void shareRace(Race race) {
    final String shareText =
        '''
🏃‍♂️ ¡Echa un vistazo a esta carrera!

📅 Carrera: ${race.name}
📍 Fecha: ${race.date} - ${race.month}
🌍 Zona: ${race.zone?[0].toUpperCase()}${race.zone?.substring(1).toLowerCase() ?? ''}
🏃 Tipo: ${race.type ?? 'No especificado'}
🌲 Terreno: ${race.terrain ?? 'No especificado'}
📏 Distancias: ${_formatDistances(race.distances)}

${race.registrationLink?.isNotEmpty ?? false ? '🔗 Más información: ${race.registrationLink}' : ''}

¡Encontrado en Correbirras! 🏃‍♀️🏃‍♂️
    '''
            .trim();

    Share.share(shareText);
  }

  // Helper method to format distances
  String _formatDistances(List<double> distances) {
    if (distances.isEmpty) return 'No disponible';

    List<double> sortedDistances = List.from(distances)..sort();
    return '${sortedDistances.join('K, ').replaceAll('.0', '')}K';
  }

  // Method to check if URL is a social media domain
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

  // Method to check if URL is a PDF
  bool isPdfUrl(String url) {
    return url.toLowerCase().endsWith('.pdf');
  }
}
