import 'package:flutter_test/flutter_test.dart';
import 'package:correbirras/services/util_service.dart';
import 'package:correbirras/models/race.dart';

void main() {
  group('UtilService', () {
    final utilService = UtilService();

    test('isSocialMediaUrl detects facebook', () {
      expect(utilService.isSocialMediaUrl('https://www.facebook.com/correbirras'), true);
    });

    test('isSocialMediaUrl detects instagram', () {
      expect(utilService.isSocialMediaUrl('https://www.instagram.com/correbirras'), true);
    });

    test('isSocialMediaUrl detects twitter', () {
      expect(utilService.isSocialMediaUrl('https://twitter.com/user'), true);
    });

    test('isSocialMediaUrl detects x.com', () {
      expect(utilService.isSocialMediaUrl('https://x.com/user'), true);
    });

    test('isSocialMediaUrl detects youtube', () {
      expect(utilService.isSocialMediaUrl('https://www.youtube.com/channel/test'), true);
    });

    test('isSocialMediaUrl returns false for regular url', () {
      expect(utilService.isSocialMediaUrl('https://www.correbirras.com'), false);
    });

    test('isPdfUrl detects pdf', () {
      expect(utilService.isPdfUrl('https://example.com/file.pdf'), true);
    });

    test('isPdfUrl returns false for html', () {
      expect(utilService.isPdfUrl('https://example.com/page.html'), false);
    });

    test('isValidUrl validates http and https', () {
      expect(utilService.isValidUrl('https://example.com'), true);
      expect(utilService.isValidUrl('http://example.com'), true);
      expect(utilService.isValidUrl('ftp://example.com'), false);
      expect(utilService.isValidUrl('not a url'), false);
    });

    test('shareRace formats text correctly', () {
      final race = Race(
        month: 'marzo',
        name: 'Carrera Test',
        date: '15-03',
        hora: '09:30',
        zone: 'murcia',
        type: 'Carrera',
        distances: [10.0, 21.1],
        precio: '15€',
        registrationLink: 'https://example.com',
      );

      final shareText = race.displayDistances;
      expect(shareText, contains('10K'));
      expect(shareText, contains('21.1K'));
    });
  });
}