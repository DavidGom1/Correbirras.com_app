import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as html_dom;
import '../models/race.dart';
import '../core/constants/app_constants.dart';

class RaceService {
  static final RaceService _instance = RaceService._internal();
  factory RaceService() => _instance;
  RaceService._internal();

  static const String _raceUrl =
      'https://www.correbirras.com/Agenda_carreras.html';

  Future<String> _decodeHtml(http.Response response) async {
    String htmlContent = "";
    try {
      final contentType = response.headers['content-type'];
      if (contentType != null &&
          contentType.toLowerCase().contains('charset=iso-8859-1')) {
        htmlContent = latin1.decode(response.bodyBytes);
        debugPrint("DEBUG: Decodificando como ISO-8859-1 (Latin-1)");
      } else {
        htmlContent = utf8.decode(response.bodyBytes, allowMalformed: true);
        debugPrint("DEBUG: Decodificando como UTF-8");
      }
    } catch (e) {
      debugPrint("ERROR: Fallo al decodificar: $e");
      htmlContent = utf8.decode(response.bodyBytes, allowMalformed: true);
      debugPrint("DEBUG: Fallback a UTF-8 (allowMalformed)");
    }
    return htmlContent;
  }

  List<double> _getDistances(String textContent) {
    final RegExp regExp = RegExp(r"(\d+)\s*m", caseSensitive: false);
    List<double> distances = [];
    for (final match in regExp.allMatches(textContent.replaceAll('.', ''))) {
      if (match.group(1) != null) {
        distances.add(
          (double.parse(match.group(1)!) / 100.0).truncateToDouble() / 10.0,
        );
      }
    }
    return distances;
  }

  Future<List<Race>> downloadAndParseRaces() async {
    try {
      final response = await http.get(Uri.parse(_raceUrl));

      if (response.statusCode != 200) {
        debugPrint(
          "ERROR: Fallo al descargar HTML con código: ${response.statusCode}",
        );
        throw Exception('Error al descargar datos: ${response.statusCode}');
      }

      String htmlContent = await _decodeHtml(response);
      return _parseHtmlAndExtractRaces(htmlContent);
    } catch (e) {
      debugPrint("ERROR: Excepción durante la descarga o decodificación: $e");
      rethrow;
    }
  }

  List<Race> _parseHtmlAndExtractRaces(String htmlContent) {
    final document = parse(htmlContent);
    final table = document.querySelector("table");

    if (table == null) {
      debugPrint("ERROR: No se encontró tabla en el HTML");
      return [];
    }

    List<Race> parsedRaces = [];
    String? currentMonth;

    for (var tr in table.querySelectorAll("tr")) {
      final a = tr.querySelector("a[id]");
      if (a != null && meseses.contains(a.id.toLowerCase())) {
        currentMonth = a.id.toLowerCase();
        continue;
      }

      if (currentMonth != null) {
        final List<html_dom.Element> tds = tr.querySelectorAll("td");
        if (tds.length < 4) continue;

        final dateElement = tds[0];
        final nameElement = tds[1];
        final typeImgElement = tds[2].querySelector("img[alt]");
        final terrainImgElement = tds[3].querySelector("img[alt]");
        final zoneTdElement = tr.querySelector("td[bgcolor]");

        String? registrationLink;
        final linkElement = tds[1].querySelector('a[href]');
        if (linkElement != null) {
          final href = linkElement.attributes['href'];
          if (href != null &&
              !href.startsWith('#') &&
              (href.startsWith('http://') || href.startsWith('https://'))) {
            registrationLink = href;
          }
        }

        String? name = nameElement.text.trim();
        if (name.isEmpty) continue;

        String? date = dateElement.text.trim();
        String? type = typeImgElement?.attributes['alt']?.trim();
        String? terrain = terrainImgElement?.attributes['alt']?.trim();
        String? zone;
        String? foundColorKey;

        if (zoneTdElement != null) {
          final bgColor = zoneTdElement.attributes['bgcolor']?.toLowerCase();
          if (bgColor != null) {
            for (var entry in zonascolores.entries) {
              if (bgColor.contains(entry.value)) {
                foundColorKey = entry.key;
                break;
              }
            }
          }
        } else {
          final outerHtml = tr.outerHtml.toLowerCase();
          for (var entry in zonascolores.entries) {
            if (outerHtml.contains(entry.value)) {
              foundColorKey = entry.key;
              break;
            }
          }
        }

        zone = foundColorKey;
        final distances = _getDistances(tds.length > 5 ? tds[5].text : '');

        parsedRaces.add(
          Race(
            month: currentMonth,
            name: name,
            date: date,
            zone: zone,
            type: type,
            terrain: terrain,
            distances: distances,
            registrationLink: registrationLink,
          ),
        );
      }
    }

    debugPrint("✅ Parseadas ${parsedRaces.length} carreras");
    return parsedRaces;
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
