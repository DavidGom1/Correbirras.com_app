import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as html_dom;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

const List<String> MESES_ES = [
  "enero", "febrero", "marzo", "abril", "mayo", "junio",
  "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"
];

const Map<String, String> ZONAS_COLORES = {
  "murcia": "#ffff00",
  "alicante": "#66ff66",
  "albacete": "#00ccff",
  "almería": "#ff9999"
};

final Color correbirrasOrange = Color(0xFFff6600);
final Color correbirrasBackground = Color(0xFFf9f9f9);

class Race {
  final String month;
  final String name;
  final String? zone;
  final String? type;
  final String? terrain;
  final List<int> distances;
  final String? registrationLink;

  Race({
    required this.month,
    required this.name,
    this.zone,
    this.type,
    this.terrain,
    this.distances = const [],
    this.registrationLink,
  });

  @override
  String toString() {
    return 'Race(month: $month, name: $name, zone: $zone, type: $type, terrain: $terrain, distances: $distances, link: $registrationLink)';
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agenda de carreras Correbirras',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: correbirrasOrange),
        scaffoldBackgroundColor: correbirrasBackground,
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Agenda de carreras Correbirras'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isLoading = true;
  List<Race> _allRaces = [];
  List<Race> _filteredRaces = [];
  String _selectedMonth = "all";
  String _selectedZone = "all";
  String _selectedType = "all";
  String _selectedTerrain = "all";

  double _filteredMinDistance = 0;
  double _filteredMaxDistance = 0;
  RangeValues _selectedDistanceRange = const RangeValues(0, 0);

  @override
  void initState() {
    super.initState();
    _downloadHtmlAndParse();
  }

  Future<String> _decodeHtml(http.Response response) async {
    String htmlContent = "";
    try {
      final contentType = response.headers['content-type'];
      if (contentType != null && contentType.toLowerCase().contains('charset=iso-8859-1')) {
        htmlContent = latin1.decode(response.bodyBytes);
        print("DEBUG: Decodificando como ISO-8859-1 (Latin-1)");
      } else {
        htmlContent = utf8.decode(response.bodyBytes, allowMalformed: true);
        print("DEBUG: Decodificando como UTF-8");
      }
    } catch (e) {
      print("ERROR: Fallo al decodificar: $e");
      htmlContent = utf8.decode(response.bodyBytes, allowMalformed: true);
      print("DEBUG: Fallback a UTF-8 (allowMalformed)");
    }
    return htmlContent;
  }

  Future<void> _downloadHtmlAndParse() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final response = await http.get(Uri.parse('https://www.correbirras.com/Agenda_carreras.html'));
      String htmlContent = await _decodeHtml(response);

      if (response.statusCode == 200) {
        _parseHtmlAndExtractRaces(htmlContent);
      } else {
        print("ERROR: Fallo al descargar HTML con código: ${response.statusCode}");
      }
    } catch (e) {
      print("ERROR: Excepción durante la descarga o decodificación: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<int> _getDistances(String textContent) {
    final RegExp regExp = RegExp(r"(\d+)\s*m", caseSensitive: false);
    List<int> distances = [];
    for (final match in regExp.allMatches(textContent.replaceAll('.', ''))) {
      if (match.group(1) != null) {
        distances.add(int.parse(match.group(1)!));
      }
    }
    return distances;
  }

  void _parseHtmlAndExtractRaces(String htmlContent) {
    final document = parse(htmlContent);
    final table = document.querySelector("table");

    if (table == null) {
      _allRaces = [];
      _filteredRaces = [];
      return;
    }

    List<Race> parsedRaces = [];
    String? currentMonth;

    for (var tr in table.querySelectorAll("tr")) {
      final a = tr.querySelector("a[id]");
      if (a != null && MESES_ES.contains(a.id?.toLowerCase())) {
        currentMonth = a.id?.toLowerCase();
        continue;
      }

      if (currentMonth != null) {
        final List<html_dom.Element> tds = tr.querySelectorAll("td");
        if (tds.length < 4) continue;
        final nameElement = tds[1];
        final typeImgElement = tds[2].querySelector("img[alt]");
        final terrainImgElement = tds[3].querySelector("img[alt]");
        final zoneTdElement = tr.querySelector("td[bgcolor]");

        String? registrationLink;
        for (int i = tds.length - 1; i >= 0; i--) {
          final linkElement = tds[i].querySelector('a[href]');
          if (linkElement != null) {
            final href = linkElement.attributes['href'];
            if (href != null && !href.startsWith('#') && (href.startsWith('http://') || href.startsWith('https://'))) {
              registrationLink = href;
              break;
            }
          }
        }

        String? name = nameElement.text.trim();
        if (name.isEmpty) continue;
        String? type = typeImgElement?.attributes['alt']?.trim();
        String? terrain = terrainImgElement?.attributes['alt']?.trim();
        String? zone;
        String? foundColorKey;
        if (zoneTdElement != null) {
          final bgColor = zoneTdElement.attributes['bgcolor']?.toLowerCase();
          if (bgColor != null) {
            for (var entry in ZONAS_COLORES.entries) {
              if (bgColor.contains(entry.value)) {
                foundColorKey = entry.key;
                break;
              }
            }
          }
        } else {
          final outerHtml = tr.outerHtml.toLowerCase();
          for (var entry in ZONAS_COLORES.entries) {
            if (outerHtml.contains(entry.value)) {
              foundColorKey = entry.key;
              break;
            }
          }
        }
        zone = foundColorKey;
        final distances = _getDistances(tr.text);
        parsedRaces.add(Race(
          month: currentMonth,
          name: name,
          zone: zone,
          type: type,
          terrain: terrain,
          distances: distances,
          registrationLink: registrationLink,
        ));
      }
    }

    if (mounted) {
      setState(() {
        _allRaces = parsedRaces;
        _applyFilters(basicFilterChanged: true);
      });
    }
  }

  void _applyFilters({bool basicFilterChanged = false}) {
    List<Race> basicFilteredRaces = _allRaces.where((race) {
      final matchMonth = _selectedMonth == "all" || race.month == _selectedMonth;
      final matchZone = _selectedZone == "all" || race.zone == _selectedZone;
      final matchType = _selectedType == "all" || race.type == _selectedType;
      final matchTerrain = _selectedTerrain == "all" || race.terrain == _selectedTerrain;
      return matchMonth && matchZone && matchType && matchTerrain;
    }).toList();

    double newMin = 0;
    double newMax = 0;
    final filteredDistances = basicFilteredRaces.expand((race) => race.distances).toList();
    if (filteredDistances.isNotEmpty) {
      newMin = filteredDistances.reduce((a, b) => a < b ? a : b).toDouble();
      newMax = filteredDistances.reduce((a, b) => a > b ? a : b).toDouble();
    }

    RangeValues newDistanceRange = _selectedDistanceRange;
    if (basicFilterChanged) {
      newDistanceRange = RangeValues(newMin, newMax);
    }

    List<Race> finalFilteredRaces = List.from(basicFilteredRaces);
    if (newMax > 0 && (newDistanceRange.start > newMin || newDistanceRange.end < newMax)) {
      finalFilteredRaces = finalFilteredRaces.where((race) {
        if (race.distances.isEmpty) return false;
        return race.distances.any((d) => d >= newDistanceRange.start && d <= newDistanceRange.end);
      }).toList();
    }

    if (mounted) {
      setState(() {
        _filteredMinDistance = newMin;
        _filteredMaxDistance = newMax;
        _selectedDistanceRange = newDistanceRange;
        _filteredRaces = finalFilteredRaces;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      if (!await launchUrl(Uri.parse(url), mode: LaunchMode.inAppWebView)) {
        throw Exception('No se pudo abrir el enlace: $url');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> availableMonths = ["all", ...MESES_ES];
    final List<String> availableZones = ["all", ...ZONAS_COLORES.keys.toList()];
    final List<String> availableTypes = ["all", ..._allRaces.map((r) => r.type).whereType<String>().toSet().toList()..sort()];
    final List<String> availableTerrains = ["all", ..._allRaces.map((r) => r.terrain).whereType<String>().toSet().toList()..sort()];

    return Container(
      color: Color.fromRGBO(239, 120, 26, 1),
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            backgroundColor:  Color.fromRGBO(239, 120, 26, 1),
            foregroundColor: Colors.white,
            title: Text(widget.title),
            actions: [
              Builder(
                builder: (BuildContext innerContext) {
                  return IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () => Scaffold.of(innerContext).openEndDrawer(),
                  );
                },
              ),
            ],
          ),
          endDrawer: Drawer(
            child: Material(
              color: Colors.white,
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  DrawerHeader(
                    decoration: BoxDecoration(color:  Color.fromRGBO(200, 90, 10, 1)),
                    child: Center(
                      child: Text(
                        'Filtros',
                        style: TextStyle(color: Colors.white, fontSize: 28),
                      ),
                    ),
                  ),
                  ListTile(
                    title: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedMonth,
                      onChanged: (v) {
                        setState(() => _selectedMonth = v!);
                        _applyFilters(basicFilterChanged: true);
                      },
                      items: availableMonths.map((m) => DropdownMenuItem(value: m, child: Text(m == "all" ? "Mes" : m[0].toUpperCase() + m.substring(1)))).toList(),
                    ),
                  ),
                  ListTile(
                    title: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedZone,
                      onChanged: (v) {
                        setState(() => _selectedZone = v!);
                        _applyFilters(basicFilterChanged: true);
                      },
                      items: availableZones.map((z) => DropdownMenuItem(value: z, child: Text(z == "all" ? "Zona" : z[0].toUpperCase() + z.substring(1)))).toList(),
                    ),
                  ),
                  ListTile(
                    title: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedType,
                      onChanged: (v) {
                        setState(() => _selectedType = v!);
                        _applyFilters(basicFilterChanged: true);
                      },
                      items: availableTypes.map((t) => DropdownMenuItem(value: t, child: Text(t == "all" ? "Tipo" : t))).toList(),
                    ),
                  ),
                  ListTile(
                    title: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedTerrain,
                      onChanged: (v) {
                        setState(() => _selectedTerrain = v!);
                        _applyFilters(basicFilterChanged: true);
                      },
                      items: availableTerrains.map((t) => DropdownMenuItem(value: t, child: Text(t == "all" ? "Terreno" : t))).toList(),
                    ),
                  ),
                  ListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Distancia (metros)'),
                        RangeSlider(
                          values: _selectedDistanceRange,
                          min: _filteredMinDistance,
                          max: _filteredMaxDistance > _filteredMinDistance ? _filteredMaxDistance : _filteredMinDistance + 1,
                          divisions: (_filteredMaxDistance > _filteredMinDistance) ? ((_filteredMaxDistance - _filteredMinDistance) / 100).round().clamp(1, 1000) : null,
                          labels: RangeLabels(_selectedDistanceRange.start.round().toString(), _selectedDistanceRange.end.round().toString()),
                          onChanged: (values) => setState(() => _selectedDistanceRange = values),
                          onChangeEnd: (values) => _applyFilters(basicFilterChanged: false),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => _applyFilters(basicFilterChanged: true),
                            child: const Text('Restablecer'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _filteredRaces.isEmpty
                  ? const Center(child: Text("No hay carreras para mostrar con los filtros seleccionados."))
                  : ListView.builder(
                      itemCount: _filteredRaces.length,
                      itemBuilder: (context, index) {
                        final race = _filteredRaces[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        race.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ),
                                    if (race.registrationLink != null)
                                      IconButton(
                                        icon: const Icon(Icons.launch),
                                        onPressed: () => _launchUrl(race.registrationLink!),
                                        tooltip: 'Abrir enlace de inscripción',
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (race.zone != null) Text('Zona: ${race.zone}'),
                                if (race.type != null) Text('Tipo: ${race.type}'),
                                if (race.terrain != null) Text('Terreno: ${race.terrain}'),
                                if (race.distances.isNotEmpty) Text('Distancias: ${race.distances.join('m, ')}m'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}
