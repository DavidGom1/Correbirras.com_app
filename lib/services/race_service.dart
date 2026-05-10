import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../models/race.dart';
import '../core/constants/app_constants.dart';

class RaceService {
  static final RaceService _instance = RaceService._internal();
  factory RaceService() => _instance;
  RaceService._internal();

  String _supabaseUrl = defaultSupabaseUrl;
  String _supabaseAnonKey = defaultSupabaseAnonKey;
  bool _remoteConfigInitialized = false;

  Future<void> _ensureRemoteConfig() async {
    if (_remoteConfigInitialized) return;

    try {
      final remoteConfig = FirebaseRemoteConfig.instance;

      await remoteConfig.setDefaults({
        'supabase_url': defaultSupabaseUrl,
        'supabase_anon_key': defaultSupabaseAnonKey,
      });

      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      await remoteConfig.fetchAndActivate();

      _supabaseUrl = remoteConfig.getString('supabase_url');
      _supabaseAnonKey = remoteConfig.getString('supabase_anon_key');

      debugPrint("✅ Remote Config: credenciales obtenidas");
    } catch (e) {
      debugPrint("⚠️ Remote Config no disponible, usando valores por defecto");
      _supabaseUrl = defaultSupabaseUrl;
      _supabaseAnonKey = defaultSupabaseAnonKey;
    }

    _remoteConfigInitialized = true;
  }

  Future<List<Race>> downloadAndParseRaces() async {
    await _ensureRemoteConfig();

    try {
      final uri = Uri.parse('$_supabaseUrl/rest/v1/carreras?select=*');

      final response = await http.get(
        uri,
        headers: {
          'apikey': _supabaseAnonKey,
          'Authorization': 'Bearer $_supabaseAnonKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        debugPrint("ERROR: Fallo al obtener datos: ${response.statusCode}");
        throw Exception('Error al descargar datos: ${response.statusCode}');
      }

      final List<dynamic> jsonData = json.decode(response.body);
      debugPrint("✅ Recibidas ${jsonData.length} carreras");

      final races = jsonData
          .map((row) => Race.fromSupabase(row as Map<String, dynamic>))
          .where((race) => race.name.isNotEmpty)
          .toList();

      debugPrint("✅ Parseadas ${races.length} carreras válidas");
      return races;
    } catch (e) {
      debugPrint("ERROR: Excepción al consultar datos: $e");
      rethrow;
    }
  }

  FilterOptions getFilterOptions(List<Race> races) {
    final months = <String>[];
    for (final race in races) {
      if (race.month.isNotEmpty && !months.contains(race.month)) {
        months.add(race.month);
      }
    }

    final zones = <String>[];
    for (final race in races) {
      if (race.zone != null && race.zone!.isNotEmpty && !zones.contains(race.zone)) {
        zones.add(race.zone!);
      }
    }
    zones.sort();

    final types = <String>[];
    for (final race in races) {
      if (race.type != null && race.type!.isNotEmpty && !types.contains(race.type)) {
        types.add(race.type!);
      }
    }
    types.sort();

    return FilterOptions(
      months: months.isNotEmpty ? months : List.from(meses),
      zones: zones,
      types: types,
    );
  }

  DistanceRange getDistanceRange(List<Race> races) {
    List<double> allDistances = [];
    for (var race in races) {
      allDistances.addAll(race.distances);
    }

    if (allDistances.isEmpty) {
      return DistanceRange(min: 0, max: 0);
    }

    allDistances.sort();
    return DistanceRange(min: allDistances.first, max: allDistances.last);
  }
}

class FilterOptions {
  final List<String> months;
  final List<String> zones;
  final List<String> types;

  FilterOptions({
    required this.months,
    required this.zones,
    required this.types,
  });
}

class DistanceRange {
  final double min;
  final double max;

  DistanceRange({required this.min, required this.max});
}