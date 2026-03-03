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

  // URL actualizada - el webmaster unificó todo en Agenda.html
  static const String _raceUrl = 'https://correbirras.com/Agenda.html';

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
    // Buscar patrones como "10K", "21K", "5K", "42K", "15,5K", "10.5K"
    final RegExp regExp = RegExp(r"(\d+[.,]?\d*)\s*[kK]", caseSensitive: false);
    List<double> distances = [];
    for (final match in regExp.allMatches(textContent)) {
      if (match.group(1) != null) {
        String numStr = match.group(1)!.replaceAll(',', '.');
        double? value = double.tryParse(numStr);
        if (value != null && value > 0) {
          distances.add(value);
        }
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

  /// Extrae la zona/provincia desde las clases CSS del elemento <td> de provincia.
  /// Ejemplo: class="col-provincia provincia-murcia" → "murcia"
  String? _extractZoneFromProvinciaClass(html_dom.Element? td) {
    if (td == null) return null;

    final classes = td.className.toLowerCase().split(' ');
    for (var cls in classes) {
      if (cls.startsWith('provincia-')) {
        final provincia = cls.replaceFirst('provincia-', '').trim();
        // Mapear al nombre de zona interno de la app
        return provinciasAZonas[provincia] ?? provincia;
      }
    }

    // Fallback: usar el texto del td
    final text = td.text.trim().toLowerCase();
    return provinciasAZonas[text] ?? text;
  }

  List<Race> _parseHtmlAndExtractRaces(String htmlContent) {
    final document = parse(htmlContent);
    List<Race> parsedRaces = [];

    // La nueva estructura tiene un <h2 id="mes" class="mes-titulo"> seguido de
    // un <div class="table-container"><table class="agenda-table">...</table></div>
    // para cada mes.

    // Estrategia: buscar todos los h2 con clase "mes-titulo" y para cada uno,
    // buscar la tabla siguiente.
    final allElements = document.querySelectorAll(
      'h2.mes-titulo, table.agenda-table',
    );

    String? currentMonth;

    for (var element in allElements) {
      if (element.localName == 'h2') {
        // Extraer el mes desde el id del h2 (ej: id="marzo")
        final monthId = element.id.toLowerCase();
        if (meseses.contains(monthId)) {
          currentMonth = monthId;
          debugPrint("📅 Parseando mes: $currentMonth");
        }
        continue;
      }

      // Si es una tabla y tenemos un mes actual
      if (element.localName == 'table' && currentMonth != null) {
        final tbody = element.querySelector('tbody');
        final rows =
            tbody?.querySelectorAll('tr') ??
            element.querySelectorAll('tbody > tr');

        if (rows.isEmpty) {
          // Si no hay tbody, buscar tr directamente
          final directRows = element.querySelectorAll('tr');
          for (var tr in directRows) {
            // Saltar el thead row
            if (tr.parent?.localName == 'thead') continue;
            final race = _parseRow(tr, currentMonth);
            if (race != null) parsedRaces.add(race);
          }
        } else {
          for (var tr in rows) {
            final race = _parseRow(tr, currentMonth);
            if (race != null) parsedRaces.add(race);
          }
        }
      }
    }

    // Si la estrategia por h2+table no funciona, intentar con data attributes
    if (parsedRaces.isEmpty) {
      debugPrint("⚠️ Fallback: buscando tablas sin h2.mes-titulo...");
      parsedRaces = _parseWithFallback(document);
    }

    debugPrint("✅ Parseadas ${parsedRaces.length} carreras");
    return parsedRaces;
  }

  Race? _parseRow(html_dom.Element tr, String currentMonth) {
    // Extraer datos desde clases CSS específicas
    final fechaTd = tr.querySelector('td.col-fecha');
    final horaTd = tr.querySelector('td.col-hora');
    final carreraTd = tr.querySelector('td.col-carrera');
    final tipoTd = tr.querySelector('td.col-tipo');
    final senderistaTd = tr.querySelector('td.col-senderista');
    final localidadTd = tr.querySelector('td.col-localidad');
    final provinciaTd = tr.querySelector('td.col-provincia');
    final distanciaTd = tr.querySelector('td.col-distancia');
    final precioTd = tr.querySelector('td.col-precio');

    // Si no hay celda de carrera o está vacía, saltar esta fila
    if (carreraTd == null) return null;

    String name = carreraTd.text.trim();
    if (name.isEmpty) return null;

    // Obtener link de inscripción
    String? registrationLink;
    final linkElement = carreraTd.querySelector('a[href]');
    if (linkElement != null) {
      final href = linkElement.attributes['href'];
      if (href != null &&
          !href.startsWith('#') &&
          (href.startsWith('http://') || href.startsWith('https://'))) {
        registrationLink = href;
      }
    }

    // Extraer los datos de cada celda
    String? date = fechaTd?.text.trim();
    String? hora = horaTd?.text.trim();
    String? place = localidadTd?.text.trim();
    String? zone = _extractZoneFromProvinciaClass(provinciaTd);

    // Tipo: extraer desde el span.tag o el data-tipo del tr
    String? type;
    final tipoSpan = tipoTd?.querySelector('span.tag');
    if (tipoSpan != null) {
      type = tipoSpan.text.trim();
    } else if (tipoTd != null) {
      type = tipoTd.text.trim();
    }
    // Fallback al data-tipo del tr
    if ((type == null || type.isEmpty) &&
        tr.attributes.containsKey('data-tipo')) {
      type = tr.attributes['data-tipo'];
      if (type != null && type.isNotEmpty) {
        type = type[0].toUpperCase() + type.substring(1);
      }
    }

    // Senderista: si tiene el emoji 🥾
    bool senderista = false;
    if (senderistaTd != null) {
      senderista = senderistaTd.text.contains('🥾');
    }

    // Distancias
    List<double> distances = [];
    if (distanciaTd != null) {
      distances = _getDistances(distanciaTd.text);
    }

    // Precio
    String? precio;
    if (precioTd != null) {
      precio = precioTd.text.trim();
      if (precio.isEmpty) precio = null;
    }

    // Limpiar hora vacía
    if (hora != null && hora.isEmpty) hora = null;

    return Race(
      month: currentMonth,
      name: name,
      date: date,
      hora: hora,
      place: place,
      zone: zone,
      type: type,
      distances: distances,
      registrationLink: registrationLink,
      precio: precio,
      senderista: senderista,
    );
  }

  /// Fallback: parsear buscando todas las tablas con agenda-table
  /// y determinando el mes desde el h2 más cercano anterior
  List<Race> _parseWithFallback(html_dom.Document document) {
    List<Race> races = [];

    // Buscar todos los h2 que podrían ser headers de mes
    final allH2 = document.querySelectorAll('h2');
    final tables = document.querySelectorAll('table');

    String currentMonth = 'enero'; // default

    for (var h2 in allH2) {
      final id = h2.id.toLowerCase();
      if (meseses.contains(id)) {
        currentMonth = id;
      }

      // Encontrar el texto del h2 para meses que no tienen id
      final text = h2.text.toLowerCase();
      for (var mes in meseses) {
        if (text.contains(mes)) {
          currentMonth = mes;
          break;
        }
      }
    }

    // Parsear todas las tablas
    for (var table in tables) {
      final rows = table.querySelectorAll('tbody tr');
      for (var tr in rows) {
        // Intentar determinar el mes desde data-attributes o contexto
        final race = _parseRow(tr, currentMonth);
        if (race != null) races.add(race);
      }
    }

    return races;
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
