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

  // Credenciales de Supabase (se actualizan desde Remote Config)
  String _supabaseUrl = defaultSupabaseUrl;
  String _supabaseAnonKey = defaultSupabaseAnonKey;
  bool _remoteConfigInitialized = false;

  /// Inicializa Firebase Remote Config y obtiene las credenciales de Supabase.
  /// Si falla, se usan los valores por defecto hardcodeados.
  Future<void> _ensureRemoteConfig() async {
    if (_remoteConfigInitialized) return;

    try {
      final remoteConfig = FirebaseRemoteConfig.instance;

      await remoteConfig.setDefaults({
        'supabase_url': defaultSupabaseUrl,
        'supabase_anon_key': defaultSupabaseAnonKey,
      });

      // Fetch con timeout corto para no bloquear la app
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      await remoteConfig.fetchAndActivate();

      _supabaseUrl = remoteConfig.getString('supabase_url');
      _supabaseAnonKey = remoteConfig.getString('supabase_anon_key');

      debugPrint("✅ Remote Config: credenciales Supabase obtenidas");
      debugPrint("   URL: $_supabaseUrl");
    } catch (e) {
      debugPrint("⚠️ Remote Config no disponible, usando valores por defecto: $e");
      _supabaseUrl = defaultSupabaseUrl;
      _supabaseAnonKey = defaultSupabaseAnonKey;
    }

    _remoteConfigInitialized = true;
  }

  /// Descarga las carreras desde la API REST de Supabase.
  ///
  /// Las credenciales se obtienen de Firebase Remote Config (con fallback
  /// a los valores hardcodeados si Remote Config no está disponible).
  Future<List<Race>> downloadAndParseRaces() async {
    // Obtener credenciales actualizadas de Remote Config
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
        debugPrint(
          "ERROR: Fallo al obtener datos de Supabase: ${response.statusCode}",
        );
        debugPrint("Cuerpo: ${response.body}");
        throw Exception(
          'Error al descargar datos de Supabase: ${response.statusCode}',
        );
      }

      final List<dynamic> jsonData = json.decode(response.body);
      debugPrint("✅ Recibidas ${jsonData.length} carreras de Supabase");

      final races = jsonData
          .map((row) => Race.fromSupabase(row as Map<String, dynamic>))
          .where((race) => race.name.isNotEmpty)
          .toList();

      debugPrint("✅ Parseadas ${races.length} carreras válidas");
      return races;
    } catch (e) {
      debugPrint("ERROR: Excepción al consultar Supabase: $e");
      rethrow;
    }
  }

  // Métodos de filtrado
  List<Race> applyFilters({
    required List<Race> races,
    String? selectedMonth,
    String? selectedZone,
    String? selectedType,
    String? selectedTerrain,
    RangeValues? selectedDistanceRange,
    double? minDistance,
    double? maxDistance,
  }) {
    List<Race> filtered = List.from(races);

    if (selectedMonth != null) {
      filtered = filtered.where((race) => race.month == selectedMonth).toList();
    }

    if (selectedZone != null) {
      filtered = filtered.where((race) => race.zone == selectedZone).toList();
    }

    if (selectedType != null) {
      filtered = filtered.where((race) => race.type == selectedType).toList();
    }

    if (selectedTerrain != null) {
      filtered = filtered
          .where((race) => race.terrain == selectedTerrain)
          .toList();
    }

    if (selectedDistanceRange != null &&
        minDistance != null &&
        maxDistance != null) {
      filtered = filtered.where((race) {
        if (race.distances.isEmpty) return false;
        return race.distances.any(
          (distance) =>
              distance >= selectedDistanceRange.start &&
              distance <= selectedDistanceRange.end,
        );
      }).toList();
    }

    return filtered;
  }

  // Obtener opciones únicas para filtros
  FilterOptions getFilterOptions(List<Race> races) {
    return FilterOptions(
      months: meseses,
      zones: zonascolores.keys.toList(),
      types: races.map((r) => r.type).whereType<String>().toSet().toList()
        ..sort(),
      terrains: races.map((r) => r.terrain).whereType<String>().toSet().toList()
        ..sort(),
    );
  }

  // Obtener rango de distancias
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
  final List<String> terrains;

  FilterOptions({
    required this.months,
    required this.zones,
    required this.types,
    required this.terrains,
  });
}

class DistanceRange {
  final double min;
  final double max;

  DistanceRange({required this.min, required this.max});
}
