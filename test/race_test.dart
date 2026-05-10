import 'package:flutter_test/flutter_test.dart';
import 'package:correbirras/models/race.dart';

void main() {
  group('Race', () {
    test('fromJson creates Race correctly', () {
      final json = {
        'month': 'enero',
        'name': 'Carrera Test',
        'date': '15-01-26',
        'hora': '09:30',
        'place': 'Murcia',
        'zone': 'murcia',
        'type': 'Carrera',
        'distances': [5.0, 10.0, 21.1],
        'registrationLink': 'https://example.com',
        'precio': '10-20€',
        'senderista': false,
        'nocturna': true,
        'solidaria': false,
      };

      final race = Race.fromJson(json);

      expect(race.month, 'enero');
      expect(race.name, 'Carrera Test');
      expect(race.date, '15-01-26');
      expect(race.hora, '09:30');
      expect(race.place, 'Murcia');
      expect(race.zone, 'murcia');
      expect(race.type, 'Carrera');
      expect(race.distances, [5.0, 10.0, 21.1]);
      expect(race.registrationLink, 'https://example.com');
      expect(race.precio, '10-20€');
      expect(race.senderista, false);
      expect(race.nocturna, true);
      expect(race.solidaria, false);
    });

    test('toJson serializes Race correctly', () {
      final race = Race(
        month: 'febrero',
        name: 'Test Race',
        distances: [10.0],
      );
      race.isFavorite = false;

      final json = race.toJson();

      expect(json['month'], 'febrero');
      expect(json['name'], 'Test Race');
      expect(json['distances'], [10.0]);
      expect(json['isFavorite'], false);
    });

    test('displayZone capitalizes first letter', () {
      final race = Race(month: 'enero', name: 'Test', zone: 'murcia');
      expect(race.displayZone, 'Murcia');
    });

    test('displayZone handles empty zone', () {
      final race = Race(month: 'enero', name: 'Test', zone: '');
      expect(race.displayZone, '');
    });

    test('displayZone handles null zone', () {
      final race = Race(month: 'enero', name: 'Test', zone: null);
      expect(race.displayZone, '');
    });

    test('displayMonth capitalizes first letter', () {
      final race = Race(month: 'septiembre', name: 'Test');
      expect(race.displayMonth, 'Septiembre');
    });

    test('displayPlace capitalizes place without parenthesis', () {
      final race = Race(month: 'enero', name: 'Test', place: 'MURCIA');
      expect(race.displayPlace, 'Murcia');
    });

    test('displayPlace strips parenthetical suffix', () {
      final race = Race(month: 'enero', name: 'Test', place: 'Murcia (centro)');
      expect(race.displayPlace, 'Murcia');
    });

    test('displayPlace handles null place', () {
      final race = Race(month: 'enero', name: 'Test', place: null);
      expect(race.displayPlace, '');
    });

    test('displayDistances formats distances correctly', () {
      final race = Race(month: 'enero', name: 'Test', distances: [5.0, 10.0, 21.1]);
      expect(race.displayDistances, '5K, 10K, 21.1K');
    });

    test('displayDistances handles empty distances', () {
      final race = Race(month: 'enero', name: 'Test', distances: []);
      expect(race.displayDistances, 'No disponible');
    });

    test('parsedMinPrice parses "Gratis"', () {
      final race = Race(month: 'enero', name: 'Test', precio: 'Gratis');
      expect(race.parsedMinPrice, 0);
    });

    test('parsedMinPrice parses "10-13"', () {
      final race = Race(month: 'enero', name: 'Test', precio: '10-13');
      expect(race.parsedMinPrice, 10.0);
    });

    test('parsedMinPrice parses "5"', () {
      final race = Race(month: 'enero', name: 'Test', precio: '5');
      expect(race.parsedMinPrice, 5.0);
    });

    test('parsedMinPrice handles null', () {
      final race = Race(month: 'enero', name: 'Test', precio: null);
      expect(race.parsedMinPrice, null);
    });

    test('parsedMinPrice handles empty string', () {
      final race = Race(month: 'enero', name: 'Test', precio: '');
      expect(race.parsedMinPrice, null);
    });

    test('formatDate with hora', () {
      final race = Race(month: 'enero', name: 'Test', date: '15-01-26', hora: '09:30');
      expect(race.formatDate(), '15-01-26 (09:30)');
    });

    test('formatDate without hora', () {
      final race = Race(month: 'enero', name: 'Test', date: '15-01-26');
      expect(race.formatDate(), '15-01-26');
    });

    test('copyWith preserves values', () {
      final race = Race(month: 'enero', name: 'Test', distances: [10.0]);
      race.isFavorite = true;
      final copy = race.copyWith(name: 'Updated');
      copy.isFavorite = false;

      expect(copy.month, 'enero');
      expect(copy.name, 'Updated');
      expect(copy.distances, [10.0]);
      expect(copy.isFavorite, false);
    });

    test('parseDistances parses "10K / 21K"', () {
      final result = Race.parseDistances('10K / 21K');
      expect(result, [10.0, 21.0]);
    });

    test('parseDistances parses "5K"', () {
      final result = Race.parseDistances('5K');
      expect(result, [5.0]);
    });

    test('parseDistances parses "10.5K"', () {
      final result = Race.parseDistances('10.5K');
      expect(result, [10.5]);
    });

    test('parseDistances handles null', () {
      final result = Race.parseDistances(null);
      expect(result, []);
    });

    test('fromSupabase parses correctly', () {
      final row = {
        'nombre': 'Carrera Murcia',
        'fecha': '2026-03-15',
        'hora_time': '09:30:00',
        'localidad': 'Murcia',
        'provincia': 'Murcia',
        'tipo': 'Carrera',
        'distancia': '10K / 21K',
        'url_web': 'https://example.com',
        'precio_min': 10.0,
        'precio_max': 20.0,
        'senderista': true,
        'nocturna': false,
        'solidaria': true,
        'url_ranking': null,
        'url_recorrido': null,
      };

      final race = Race.fromSupabase(row);

      expect(race.name, 'Carrera Murcia');
      expect(race.month, 'marzo');
      expect(race.hora, '09:30');
      expect(race.place, 'Murcia');
      expect(race.zone, 'murcia');
      expect(race.type, 'Carrera');
      expect(race.distances, [10.0, 21.0]);
      expect(race.precio, '10-20€');
      expect(race.senderista, true);
      expect(race.nocturna, false);
      expect(race.solidaria, true);
    });
  });
}