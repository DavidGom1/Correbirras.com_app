import 'package:flutter/material.dart';
import 'package:correbirras/models/race.dart';
import 'package:correbirras/services/race_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class RaceProvider extends ChangeNotifier {
  final RaceService _raceService = RaceService();

  List<Race> _allRaces = [];
  List<Race> _filteredRaces = [];
  bool _isLoading = true;
  String? _error;

  String? _selectedMonth;
  String? _selectedZone;
  String? _selectedType;

  double _filteredMinDistance = 0;
  double _filteredMaxDistance = 0;
  RangeValues _selectedDistanceRange = const RangeValues(0, 0);

  double _filteredMinPrice = 0;
  double _filteredMaxPrice = 0;
  RangeValues _selectedPriceRange = const RangeValues(0, 0);

  List<Race> get allRaces => _allRaces;
  List<Race> get filteredRaces => _filteredRaces;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedMonth => _selectedMonth;
  String? get selectedZone => _selectedZone;
  String? get selectedType => _selectedType;
  double get filteredMinDistance => _filteredMinDistance;
  double get filteredMaxDistance => _filteredMaxDistance;
  RangeValues get selectedDistanceRange => _selectedDistanceRange;
  double get filteredMinPrice => _filteredMinPrice;
  double get filteredMaxPrice => _filteredMaxPrice;
  RangeValues get selectedPriceRange => _selectedPriceRange;
  FilterOptions get filterOptions => _raceService.getFilterOptions(_allRaces);

  static const String _cacheKey = 'cached_races';

  Future<void> loadRaces() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final races = await _raceService.downloadAndParseRaces();
      _allRaces = races;
      await _saveRacesToCache(races);
      _isLoading = false;
      _applyFilters(basicFilterChanged: true);
    } catch (e) {
      debugPrint("ERROR: Excepción durante la descarga: $e");
      final cached = await _loadRacesFromCache();
      if (cached.isNotEmpty) {
        _allRaces = cached;
        _error = null;
        _applyFilters(basicFilterChanged: true);
      } else {
        _error = 'No se pudieron cargar las carreras. Verifica tu conexión.';
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFavoritesIntoRaces(List<String> favoriteNames) async {
    for (var race in _allRaces) {
      race.isFavorite = favoriteNames.contains(race.name);
    }
    notifyListeners();
  }

  void setFavorite(Race race, bool isFavorite) {
    race.isFavorite = isFavorite;
    notifyListeners();
  }

  void setMonth(String? month) {
    _selectedMonth = month;
    _applyFilters(basicFilterChanged: true);
  }

  void setZone(String? zone) {
    _selectedZone = zone;
    _applyFilters(basicFilterChanged: true);
  }

  void setType(String? type) {
    _selectedType = type;
    _applyFilters(basicFilterChanged: true);
  }

  void setDistanceRange(RangeValues range, {bool manualChange = false}) {
    _selectedDistanceRange = range;
    _applyFilters(manualDistanceChange: manualChange);
  }

  void setPriceRange(RangeValues range, {bool manualChange = false}) {
    _selectedPriceRange = range;
    _applyFilters(manualPriceChange: manualChange);
  }

  void resetAllFilters() {
    _selectedMonth = null;
    _selectedZone = null;
    _selectedType = null;
    _selectedDistanceRange = RangeValues(_filteredMinDistance, _filteredMaxDistance);
    _selectedPriceRange = RangeValues(_filteredMinPrice, _filteredMaxPrice);
    _applyFilters(basicFilterChanged: true);
  }

  double? parseMinPrice(String? precio) {
    if (precio == null || precio.trim().isEmpty) return null;
    final lower = precio.toLowerCase().trim();
    if (lower == 'gratis' || lower == 'gratuita' || lower == '0') return 0;
    final match = RegExp(r'(\d+[.,]?\d*)').firstMatch(lower);
    if (match != null) {
      return double.tryParse(match.group(1)!.replaceAll(',', '.'));
    }
    return null;
  }

  void _applyFilters({
    bool basicFilterChanged = false,
    bool manualDistanceChange = false,
    bool manualPriceChange = false,
  }) {
    List<Race> basicFilteredRaces = _allRaces.where((race) {
      final matchMonth = _selectedMonth == null || race.month == _selectedMonth;
      final matchZone = _selectedZone == null || race.zone == _selectedZone;
      final matchType = _selectedType == null || race.type == _selectedType;
      return matchMonth && matchZone && matchType;
    }).toList();

    double newMin = 0;
    double newMax = 0;
    final filteredDistances = basicFilteredRaces.expand((race) => race.distances).toList();
    if (filteredDistances.isNotEmpty) {
      newMin = filteredDistances.reduce((a, b) => a < b ? a : b).toDouble();
      newMax = filteredDistances.reduce((a, b) => a > b ? a : b).toDouble();
    }

    double newPriceMin = 0;
    double newPriceMax = 0;
    final filteredPrices = basicFilteredRaces
        .map((race) => parseMinPrice(race.precio))
        .whereType<double>()
        .toList();
    if (filteredPrices.isNotEmpty) {
      newPriceMin = filteredPrices.reduce((a, b) => a < b ? a : b);
      newPriceMax = filteredPrices.reduce((a, b) => a > b ? a : b);
    }

    RangeValues newDistanceRange = _selectedDistanceRange;
    if (basicFilterChanged) {
      newDistanceRange = RangeValues(newMin, newMax);
    } else if (!manualDistanceChange) {
      double adjustedStart = _selectedDistanceRange.start;
      double adjustedEnd = _selectedDistanceRange.end;
      if (newMin <= newMax) {
if (newMin < _selectedDistanceRange.start) {
        adjustedStart = newMin;
      } else if (adjustedStart < newMin) {
        adjustedStart = newMin;
      }
      if (newMax > _selectedDistanceRange.end) {
        adjustedEnd = newMax;
      } else if (adjustedEnd > newMax) {
        adjustedEnd = newMax;
      }
      if (adjustedStart > newMax) {
        adjustedStart = newMax;
      }
      if (adjustedEnd < newMin) {
        adjustedEnd = newMin;
      }
      if (adjustedStart > adjustedEnd) {
        adjustedStart = adjustedEnd;
      }
        newDistanceRange = RangeValues(adjustedStart, adjustedEnd);
      } else {
        newDistanceRange = const RangeValues(0, 0);
      }
    } else {
      double adjustedStart = _selectedDistanceRange.start;
      double adjustedEnd = _selectedDistanceRange.end;
      if (newMin <= newMax) {
        if (adjustedStart < newMin) adjustedStart = newMin;
        if (adjustedStart > newMax) adjustedStart = newMax;
        if (adjustedEnd < newMin) adjustedEnd = newMin;
        if (adjustedEnd > newMax) adjustedEnd = newMax;
        if (adjustedStart > adjustedEnd) adjustedStart = adjustedEnd;
        newDistanceRange = RangeValues(adjustedStart, adjustedEnd);
      }
    }

    RangeValues newPriceRange = _selectedPriceRange;
    if (basicFilterChanged) {
      newPriceRange = RangeValues(newPriceMin, newPriceMax);
    } else if (!manualPriceChange) {
      double adjStart = _selectedPriceRange.start;
      double adjEnd = _selectedPriceRange.end;
      if (newPriceMin <= newPriceMax) {
        if (newPriceMin < adjStart) adjStart = newPriceMin;
        if (adjStart < newPriceMin) adjStart = newPriceMin;
        if (newPriceMax > adjEnd) adjEnd = newPriceMax;
        if (adjEnd > newPriceMax) adjEnd = newPriceMax;
        if (adjStart > adjEnd) adjStart = adjEnd;
        newPriceRange = RangeValues(adjStart, adjEnd);
      } else {
        newPriceRange = const RangeValues(0, 0);
      }
    } else {
      double adjStart = _selectedPriceRange.start;
      double adjEnd = _selectedPriceRange.end;
      if (newPriceMin <= newPriceMax) {
        if (adjStart < newPriceMin) adjStart = newPriceMin;
        if (adjStart > newPriceMax) adjStart = newPriceMax;
        if (adjEnd < newPriceMin) adjEnd = newPriceMin;
        if (adjEnd > newPriceMax) adjEnd = newPriceMax;
        if (adjStart > adjEnd) adjStart = adjEnd;
        newPriceRange = RangeValues(adjStart, adjEnd);
      }
    }

    List<Race> finalFilteredRaces = List.from(basicFilteredRaces);
    if (newMax > 0 && (newDistanceRange.start > newMin || newDistanceRange.end < newMax)) {
      finalFilteredRaces = finalFilteredRaces.where((race) {
        if (race.distances.isEmpty) return false;
        return race.distances.any(
          (d) => d >= newDistanceRange.start && d <= newDistanceRange.end,
        );
      }).toList();
    }

    if (newPriceMax > 0 && (newPriceRange.start > newPriceMin || newPriceRange.end < newPriceMax)) {
      finalFilteredRaces = finalFilteredRaces.where((race) {
        final price = parseMinPrice(race.precio);
        if (price == null) return true;
        return price >= newPriceRange.start && price <= newPriceRange.end;
      }).toList();
    }

    double finalMin = newMin;
    double finalMax = newMax > newMin ? newMax : newMin + 1;
    double adjustedStart = newDistanceRange.start;
    double adjustedEnd = newDistanceRange.end;
    if (adjustedStart < finalMin) adjustedStart = finalMin;
    if (adjustedStart > finalMax) adjustedStart = finalMax;
    if (adjustedEnd < finalMin) adjustedEnd = finalMin;
    if (adjustedEnd > finalMax) adjustedEnd = finalMax;
    if (adjustedStart > adjustedEnd) adjustedStart = adjustedEnd;

    double finalPriceMin = newPriceMin;
    double finalPriceMax = newPriceMax > newPriceMin ? newPriceMax : newPriceMin + 1;
    double adjPriceStart = newPriceRange.start;
    double adjPriceEnd = newPriceRange.end;
    if (adjPriceStart < finalPriceMin) adjPriceStart = finalPriceMin;
    if (adjPriceStart > finalPriceMax) adjPriceStart = finalPriceMax;
    if (adjPriceEnd < finalPriceMin) adjPriceEnd = finalPriceMin;
    if (adjPriceEnd > finalPriceMax) adjPriceEnd = finalPriceMax;
    if (adjPriceStart > adjPriceEnd) adjPriceStart = adjPriceEnd;

    _filteredMinDistance = newMin;
    _filteredMaxDistance = newMax;
    _filteredMinPrice = newPriceMin;
    _filteredMaxPrice = newPriceMax;
    _selectedDistanceRange = RangeValues(adjustedStart, adjustedEnd);
    _selectedPriceRange = RangeValues(adjPriceStart, adjPriceEnd);
    _filteredRaces = finalFilteredRaces;

    notifyListeners();
  }

  Future<void> _saveRacesToCache(List<Race> races) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = races.map((r) => jsonEncode(r.toJson())).toList();
      await prefs.setStringList(_cacheKey, jsonList);
      debugPrint("✅ Carreras guardadas en caché local (${races.length})");
    } catch (e) {
      debugPrint("⚠️ Error al guardar caché: $e");
    }
  }

  Future<List<Race>> _loadRacesFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_cacheKey);
      if (jsonList == null) return [];
      return jsonList.map((json) => Race.fromJson(jsonDecode(json))).toList();
    } catch (e) {
      debugPrint("⚠️ Error al cargar caché: $e");
      return [];
    }
  }
}