import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../core/constants/app_constants.dart';

/// Modelo para las estadísticas de valoración de una carrera.
class RaceRating {
  final String carreraId;
  final double mediaGlobal;
  final int totalVotos;
  final Map<String, double> mediaPorCategoria;

  RaceRating({
    required this.carreraId,
    required this.mediaGlobal,
    required this.totalVotos,
    required this.mediaPorCategoria,
  });
}

/// Modelo para un voto individual del usuario.
class UserVote {
  final int organizacion;
  final int precio;
  final int bolsa;
  final int avituallamientos;
  final int perfil;
  final int ambiente;
  final int postmeta;
  final int trofeos;

  UserVote({
    this.organizacion = 0,
    this.precio = 0,
    this.bolsa = 0,
    this.avituallamientos = 0,
    this.perfil = 0,
    this.ambiente = 0,
    this.postmeta = 0,
    this.trofeos = 0,
  });

  factory UserVote.fromJson(Map<String, dynamic> json) {
    return UserVote(
      organizacion: json['organizacion'] ?? 0,
      precio: json['precio'] ?? 0,
      bolsa: json['bolsa'] ?? 0,
      avituallamientos: json['avituallamientos'] ?? 0,
      perfil: json['perfil'] ?? 0,
      ambiente: json['ambiente'] ?? 0,
      postmeta: json['postmeta'] ?? 0,
      trofeos: json['trofeos'] ?? 0,
    );
  }

  Map<String, int> toMap() => {
    'organizacion': organizacion,
    'precio': precio,
    'bolsa': bolsa,
    'avituallamientos': avituallamientos,
    'perfil': perfil,
    'ambiente': ambiente,
    'postmeta': postmeta,
    'trofeos': trofeos,
  };
}

/// Categorías de votación con sus etiquetas y emojis.
class VoteCategory {
  final String key;
  final String label;
  final String emoji;

  const VoteCategory(this.key, this.label, this.emoji);
}

const List<VoteCategory> voteCategories = [
  VoteCategory('organizacion', 'Organización y logística', '📦'),
  VoteCategory('precio', 'Precio', '💸'),
  VoteCategory('bolsa', 'Bolsa del corredor', '🎽'),
  VoteCategory('avituallamientos', 'Avituallamientos', '🥤'),
  VoteCategory('perfil', 'Perfil y recorrido', '⛰️'),
  VoteCategory('ambiente', 'Ambiente y animación', '🎉'),
  VoteCategory('postmeta', 'Servicios post-meta', '🍻'),
  VoteCategory('trofeos', 'Trofeos', '🏆'),
];

class VotingService {
  static final VotingService _instance = VotingService._internal();
  factory VotingService() => _instance;
  VotingService._internal();

  String _supabaseUrl = defaultSupabaseUrl;
  String _supabaseAnonKey = defaultSupabaseAnonKey;
  bool _credentialsLoaded = false;

  Future<void> _ensureCredentials() async {
    if (_credentialsLoaded) return;
    try {
      final rc = FirebaseRemoteConfig.instance;
      _supabaseUrl = rc.getString('supabase_url');
      _supabaseAnonKey = rc.getString('supabase_anon_key');
      if (_supabaseUrl.isEmpty) _supabaseUrl = defaultSupabaseUrl;
      if (_supabaseAnonKey.isEmpty) _supabaseAnonKey = defaultSupabaseAnonKey;
    } catch (_) {
      _supabaseUrl = defaultSupabaseUrl;
      _supabaseAnonKey = defaultSupabaseAnonKey;
    }
    _credentialsLoaded = true;
  }

  Map<String, String> get _headers => {
    'apikey': _supabaseAnonKey,
    'Authorization': 'Bearer $_supabaseAnonKey',
    'Content-Type': 'application/json',
    'Prefer': 'return=minimal',
  };

  /// Obtiene todos los votos agrupados por carrera y calcula las medias.
  Future<Map<String, RaceRating>> fetchAllRatings() async {
    await _ensureCredentials();

    final uri = Uri.parse(
      '$_supabaseUrl/rest/v1/votos?select=carrera_id,organizacion,precio,bolsa,avituallamientos,perfil,ambiente,postmeta,trofeos',
    );

    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      debugPrint("ERROR votaciones: ${response.statusCode}");
      return {};
    }

    final List<dynamic> data = json.decode(response.body);
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final row in data) {
      final id = row['carrera_id'] as String;
      grouped.putIfAbsent(id, () => []);
      grouped[id]!.add(row as Map<String, dynamic>);
    }

    final Map<String, RaceRating> ratings = {};
    for (final entry in grouped.entries) {
      final votos = entry.value;
      final n = votos.length;
      final Map<String, double> sumas = {
        'organizacion': 0, 'precio': 0, 'bolsa': 0,
        'avituallamientos': 0, 'perfil': 0, 'ambiente': 0,
        'postmeta': 0, 'trofeos': 0,
      };

      for (final v in votos) {
        for (final key in sumas.keys) {
          sumas[key] = sumas[key]! + (v[key] as num? ?? 0).toDouble();
        }
      }

      final Map<String, double> medias = {};
      for (final key in sumas.keys) {
        medias[key] = sumas[key]! / n;
      }

      final mediaGlobal = medias.values.reduce((a, b) => a + b) / 8;

      ratings[entry.key] = RaceRating(
        carreraId: entry.key,
        mediaGlobal: mediaGlobal,
        totalVotos: n,
        mediaPorCategoria: medias,
      );
    }

    debugPrint("✅ Ratings obtenidos para ${ratings.length} carreras");
    return ratings;
  }

  /// Obtiene el voto del usuario para una carrera específica.
  Future<UserVote?> fetchUserVote(String carreraId, String userId) async {
    await _ensureCredentials();

    final uri = Uri.parse(
      '$_supabaseUrl/rest/v1/votos?carrera_id=eq.$carreraId&user_id=eq.$userId&select=*',
    );

    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) return null;

    final List<dynamic> data = json.decode(response.body);
    if (data.isEmpty) return null;

    return UserVote.fromJson(data.first as Map<String, dynamic>);
  }

  /// Envía o actualiza un voto (upsert).
  Future<bool> submitVote({
    required String carreraId,
    required String userId,
    required UserVote vote,
  }) async {
    await _ensureCredentials();

    final uri = Uri.parse(
      '$_supabaseUrl/rest/v1/votos?on_conflict=carrera_id,user_id',
    );

    final body = {
      'carrera_id': carreraId,
      'user_id': userId,
      ...vote.toMap(),
    };

    final response = await http.post(
      uri,
      headers: {
        ..._headers,
        'Prefer': 'resolution=merge-duplicates',
      },
      body: json.encode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      debugPrint("✅ Voto guardado para $carreraId");
      return true;
    } else {
      debugPrint("❌ Error al votar: ${response.statusCode} ${response.body}");
      return false;
    }
  }
}
