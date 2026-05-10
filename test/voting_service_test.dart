import 'package:flutter_test/flutter_test.dart';
import 'package:correbirras/services/voting_service.dart';

void main() {
  group('UserVote', () {
    test('default values are 0', () {
      final vote = UserVote();
      expect(vote.organizacion, 0);
      expect(vote.precio, 0);
      expect(vote.bolsa, 0);
      expect(vote.avituallamientos, 0);
      expect(vote.perfil, 0);
      expect(vote.ambiente, 0);
      expect(vote.postmeta, 0);
      expect(vote.trofeos, 0);
    });

    test('isAllZero returns true for default', () {
      final vote = UserVote();
      expect(vote.isAllZero, true);
    });

    test('isAllZero returns false when one category has value', () {
      final vote = UserVote(organizacion: 5);
      expect(vote.isAllZero, false);
    });

    test('toMap returns correct map', () {
      final vote = UserVote(organizacion: 7, precio: 8);
      final map = vote.toMap();
      expect(map['organizacion'], 7);
      expect(map['precio'], 8);
      expect(map['bolsa'], 0);
    });

    test('fromJson creates UserVote correctly', () {
      final json = {
        'organizacion': 9,
        'precio': 7,
        'bolsa': 8,
        'avituallamientos': 6,
        'perfil': 5,
        'ambiente': 9,
        'postmeta': 7,
        'trofeos': 8,
      };

      final vote = UserVote.fromJson(json);
      expect(vote.organizacion, 9);
      expect(vote.precio, 7);
      expect(vote.bolsa, 8);
    });

    test('fromJson handles null values', () {
      final json = <String, dynamic>{};
      final vote = UserVote.fromJson(json);
      expect(vote.organizacion, 0);
      expect(vote.precio, 0);
    });
  });

  group('RaceRating', () {
    test('creates RaceRating correctly', () {
      final rating = RaceRating(
        carreraId: 'test_carrera',
        mediaGlobal: 7.5,
        totalVotos: 10,
        mediaPorCategoria: {'organizacion': 8.0, 'precio': 7.0},
      );

      expect(rating.carreraId, 'test_carrera');
      expect(rating.mediaGlobal, 7.5);
      expect(rating.totalVotos, 10);
    });
  });

  group('VoteCategory', () {
    test('voteCategories has 8 categories', () {
      expect(voteCategories.length, 8);
    });

    test('all categories have non-empty key and label', () {
      for (final cat in voteCategories) {
        expect(cat.key.isNotEmpty, true);
        expect(cat.label.isNotEmpty, true);
        expect(cat.emoji.isNotEmpty, true);
      }
    });
  });
}