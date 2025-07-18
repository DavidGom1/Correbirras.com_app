
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as html_dom;
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

const List<String> meseses = [
  "enero",
  "febrero",
  "marzo",
  "abril",
  "mayo",
  "junio",
  "julio",
  "agosto",
  "septiembre",
  "octubre",
  "noviembre",
  "diciembre",
];

const Map<String, String> zonascolores = {
  "murcia": "#ffff00",
  "alicante": "#66ff66",
  "albacete": "#00ccff",
  "almería": "#ff9999",
};

final Color correbirrasOrange = Color.fromRGBO(239, 120, 26, 1);
final Color correbirrasBackground = Color(0xFFf9f9f9);

class Race {
  final String month;
  final String name;
  final String? date; // Added date field
  final String? zone;
  final String? type;
  final String? terrain;
  final List<int> distances;
  final String? registrationLink;

  Race({
    required this.month,
    required this.name,
    this.date, // Added date to constructor
    this.zone,
    this.type,
    this.terrain,
    this.distances = const [],
    this.registrationLink,
  });

  @override
  String toString() {
    return 'Race(month: $month, name: $name, date: $date, zone: $zone, type: $type, terrain: $terrain, distances: $distances, link: $registrationLink)';
  }
}

class RotatingIcon extends StatefulWidget {
  final String imagePath;
  final double size;

  const RotatingIcon({super.key, required this.imagePath, this.size = 100.0});

  @override
  _RotatingIconState createState() => _RotatingIconState();
}

class _RotatingIconState extends State<RotatingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Image.asset(
        widget.imagePath,
        width: widget.size,
        height: widget.size,
      ),
    );
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agenda de carreras Correbirras',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: correbirrasOrange),
        scaffoldBackgroundColor: correbirrasBackground,
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Correbirras.com'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
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

  bool _isWebViewVisible = false;
  bool _isWebViewLoading = false;
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color.fromRGBO(
          239,
          120,
          26,
          1,
        ), // Color de la barra de estado (notificaciones)
        statusBarIconBrightness:
            Brightness
                .light, // Color de los iconos de la barra de estado (oscuro o claro)
        systemStatusBarContrastEnforced: true,
        systemNavigationBarColor: Color.fromRGBO(
          239,
          120,
          26,
          1,
        ), // Color de la barra de navegación
        systemNavigationBarIconBrightness:
            Brightness.light, // Color de los iconos (claro u oscuro)
      ),
    );
    _downloadHtmlAndParse();
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(const Color.fromARGB(0, 0, 0, 0))
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (String url) {
                setState(() {
                  _isWebViewLoading = true;
                });
              },
              onPageFinished: (String url) {
                setState(() {
                  _isWebViewLoading = false;
                });
              },
            ),
          );
  }

  // Function to send email
  Future<void> _sendEmail(String emailAddress) async {
    final Uri emailLaunchUri = Uri(scheme: 'mailto', path: emailAddress);
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      throw 'Could not launch $emailLaunchUri';
    }
  }

  // Function to rate the app on Google Play
  Future<void> _rateApp() async {
    // You will need to replace 'YOUR_APP_PACKAGE_NAME' with your actual app package name
    final Uri uri = Uri.parse('market://details?id=YOUR_APP_PACKAGE_NAME');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Fallback for when the Play Store app is not installed
      final Uri webUri = Uri.parse(
        'https://play.google.com/store/apps/details?id=YOUR_APP_PACKAGE_NAME',
      );
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $webUri';
      }
    }
  }

  // Modified _launchURL function to open in external apps for social media
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      // Use externalApplication for social media links
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $uri';
    }
  }

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

  Future<void> _downloadHtmlAndParse() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final response = await http.get(
        Uri.parse('https://www.correbirras.com/Agenda_carreras.html'),
      );
      String htmlContent = await _decodeHtml(response);

      if (response.statusCode == 200) {
        _parseHtmlAndExtractRaces(htmlContent);
      } else {
        debugPrint(
          "ERROR: Fallo al descargar HTML con código: ${response.statusCode}",
        );
      }
    } catch (e) {
      debugPrint("ERROR: Excepción durante la descarga o decodificación: $e");
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
      if (a != null && meseses.contains(a.id.toLowerCase())) {
        currentMonth = a.id.toLowerCase();
        continue;
      }

      if (currentMonth != null) {
        final List<html_dom.Element> tds = tr.querySelectorAll("td");
        if (tds.length < 4) continue;

        final dateElement = tds[0]; // Assuming date is in the first td
        final nameElement = tds[1];
        final typeImgElement = tds[2].querySelector("img[alt]");
        final terrainImgElement = tds[3].querySelector("img[alt]");
        final zoneTdElement = tr.querySelector("td[bgcolor]");

        String? registrationLink;
        for (int i = tds.length - 1; i >= 0; i--) {
          final linkElement = tds[i].querySelector('a[href]');
          if (linkElement != null) {
            final href = linkElement.attributes['href'];
            if (href != null &&
                !href.startsWith('#') &&
                (href.startsWith('http://') || href.startsWith('https://'))) {
              registrationLink = href;
              break;
            }
          }
        }

        String? name = nameElement.text.trim();
        if (name.isEmpty) continue;
        String? date = dateElement.text.trim(); // Extracting date
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
        final distances = _getDistances(tr.text);
        parsedRaces.add(
          Race(
            month: currentMonth,
            name: name,
            date: date, // Pass date to constructor
            zone: zone,
            type: type,
            terrain: terrain,
            distances: distances,
            registrationLink: registrationLink,
          ),
        );
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
    List<Race> basicFilteredRaces =
        _allRaces.where((race) {
          final matchMonth =
              _selectedMonth == "all" || race.month == _selectedMonth;
          final matchZone =
              _selectedZone == "all" || race.zone == _selectedZone;
          final matchType =
              _selectedType == "all" || race.type == _selectedType;
          final matchTerrain =
              _selectedTerrain == "all" || race.terrain == _selectedTerrain;
          return matchMonth && matchZone && matchType && matchTerrain;
        }).toList();

    double newMin = 0;
    double newMax = 0;
    final filteredDistances =
        basicFilteredRaces.expand((race) => race.distances).toList();
    if (filteredDistances.isNotEmpty) {
      newMin = filteredDistances.reduce((a, b) => a < b ? a : b).toDouble();
      newMax = filteredDistances.reduce((a, b) => a > b ? a : b).toDouble();
    }

    RangeValues newDistanceRange = _selectedDistanceRange;
    if (basicFilterChanged) {
      newDistanceRange = RangeValues(newMin, newMax);
    }

    List<Race> finalFilteredRaces = List.from(basicFilteredRaces);
    if (newMax > 0 &&
        (newDistanceRange.start > newMin || newDistanceRange.end < newMax)) {
      finalFilteredRaces =
          finalFilteredRaces.where((race) {
            if (race.distances.isEmpty) {
              return false;
            }
            return race.distances.any(
              (d) => d >= newDistanceRange.start && d <= newDistanceRange.end,
            );
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

  void _showRaceInWebView(String url) {
    _controller.loadRequest(Uri.parse(url));
    setState(() {
      _isWebViewVisible = true;
    });
  }

  void _hideWebView() {
    _controller.loadRequest(Uri.parse('about:blank'));
    setState(() {
      _isWebViewVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<String> availableMonths = ["all", ...meseses];
    final List<String> availableZones = ["all", ...zonascolores.keys];
    final List<String> availableTypes = [
      "all",
      ..._allRaces.map((r) => r.type).whereType<String>().toSet().toList()
        ..sort(),
    ];
    final List<String> availableTerrains = [
      "all",
      ..._allRaces.map((r) => r.terrain).whereType<String>().toSet().toList()
        ..sort(),
    ];

    final TextStyle drawersTextStyle = TextStyle(
      color: Colors.white,
      fontSize: 25,
      fontWeight: FontWeight.bold,
    );

    return Container(
      color: Color.fromRGBO(239, 120, 26, 1),
      child: SafeArea(
        child: WillPopScope(
          onWillPop: () async {
            if (_isWebViewVisible) {
              _hideWebView();
              return false; // Evita que la ruta se cierre (la app no se cierra)
            }
            return true; // Permite que la ruta se cierre (la app se cerrará si no hay más rutas)
          },
          child: Scaffold(
            appBar: AppBar(
              elevation: 0,
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: Color.fromRGBO(239, 120, 26, 1), // Color deseado
                statusBarIconBrightness: Brightness.light, // Los iconos de la barra de estado se verán blancos
              ),
              shadowColor: const Color.fromARGB(186, 0, 0, 0),
              backgroundColor: Color.fromRGBO(239, 120, 26, 1),
              foregroundColor: Colors.white,
              leading: Builder(
                // Added Builder for the leading IconButton
                builder: (BuildContext innerContext) {
                  return IconButton(
                    icon: const Icon(Icons.menu), // Menu icon
                    onPressed:
                        () =>
                            Scaffold.of(
                              innerContext,
                            ).openDrawer(), // Open the new Drawer
                  );
                },
              ),
              title: Image.asset(
                'assets/images/Correbirras_00.png',
                fit: BoxFit.fitHeight,
                height: 35,
              ),
              centerTitle: true,
              actions: [
                if (_isWebViewVisible)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _hideWebView,
                  )
                else
                  Builder(
                    builder: (BuildContext innerContext) {
                      return IconButton(
                        icon: const Icon(Icons.filter_alt_outlined),
                        onPressed:
                            () => Scaffold.of(innerContext).openEndDrawer(),
                      );
                    },
                  ),
              ],
            ),
            drawer: Drawer(
              child: Column(
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(239, 120, 26, 1),
                    ),
                    child: Center(child: Text('Menú', style: drawersTextStyle)),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.only(top: 50),
                      children: <Widget>[
                        ListTile(
                          leading: Icon(Icons.web),
                          title: const Text('Ver la pagina correbirras.com'),
                          onTap: () {
                            Navigator.pop(context); // Close the drawer
                            _showRaceInWebView(
                              'https://www.correbirras.com/Agenda_carreras.html',
                            ); // Reusing the webview function
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.email),
                          title: const Text('Contacta con el club'),
                          onTap: () {
                            Navigator.pop(context); // Close the drawer
                            _sendEmail(
                              'correbirras@gmail.com',
                            ); // New function to send email
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.star),
                          title: const Text('Calificar en Google Play'),
                          onTap: () {
                            Navigator.pop(context); // Close the drawer
                            _rateApp(); // New function to rate the app
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(0.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Image.asset(
                            'assets/images/Facebook_2.png',
                            width: 40,
                            height: 40,
                          ), // Assuming you have facebook_icon.png in assets/images
                          onPressed: () {
                            _launchURL('https://www.facebook.com/correbirras');
                          },
                        ),
                        SizedBox(width: 20),
                        IconButton(
                          icon: Image.asset(
                            'assets/images/Instagram_2.png',
                            width: 40,
                            height: 40,
                          ), // Assuming you have instagram_icon.png in assets/images
                          onPressed: () {
                            _launchURL('https://www.instagram.com/correbirras');
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Desarrollado por Dagodev',
                          style: TextStyle(
                            color: Color.fromARGB(195, 34, 34, 34),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            endDrawer: Drawer(
              child: Material(
                color: Colors.white,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(239, 120, 26, 1),
                      ),
                      child: Center(
                        child: Text('Filtros', style: drawersTextStyle),
                      ),
                    ),
                    SizedBox(height: 20),
                    ListTile(
                      title: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedMonth,
                        onChanged: (v) {
                          setState(() => _selectedMonth = v!);
                          _applyFilters(basicFilterChanged: true);
                        },
                        items:
                            availableMonths
                                .map(
                                  (m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(
                                      m == "all"
                                          ? "Mes"
                                          : m[0].toUpperCase() + m.substring(1),
                                    ),
                                  ),
                                )
                                .toList(),
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
                        items:
                            availableZones
                                .map(
                                  (z) => DropdownMenuItem(
                                    value: z,
                                    child: Text(
                                      z == "all"
                                          ? "Zona"
                                          : z[0].toUpperCase() + z.substring(1),
                                    ),
                                  ),
                                )
                                .toList(),
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
                        items:
                            availableTypes
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t == "all" ? "Tipo" : t),
                                  ),
                                )
                                .toList(),
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
                        items:
                            availableTerrains
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t == "all" ? "Terreno" : t),
                                  ),
                                )
                                .toList(),
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
                            max:
                                _filteredMaxDistance > _filteredMinDistance
                                    ? _filteredMaxDistance
                                    : _filteredMinDistance + 1,
                            divisions:
                                (_filteredMaxDistance > _filteredMinDistance)
                                    ? ((_filteredMaxDistance -
                                                _filteredMinDistance) /
                                            100)
                                        .round()
                                        .clamp(1, 1000)
                                    : null,
                            labels: RangeLabels(
                              _selectedDistanceRange.start.round().toString(),
                              _selectedDistanceRange.end.round().toString(),
                            ),
                            activeColor: Color.fromRGBO(239, 120, 26, 1),
                            inactiveColor: Colors.grey,
                            onChanged:
                                (values) => setState(
                                  () => _selectedDistanceRange = values,
                                ),
                            onChangeEnd:
                                (values) =>
                                    _applyFilters(basicFilterChanged: false),
                          ),
                          Container(
                            padding: EdgeInsets.only(bottom: 10),
                            child: Center(
                              child: Text(
                                "${_selectedDistanceRange.start.round()}m - ${_selectedDistanceRange.end.round()}m",
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: TextButton(
                              style: ButtonStyle(
                                backgroundColor:
                                    WidgetStateProperty.resolveWith<Color?>((
                                      Set<WidgetState> states,
                                    ) {
                                      if (states.contains(
                                        WidgetState.pressed,
                                      )) {
                                        return Theme.of(
                                          context,
                                        ).colorScheme.primary.withOpacity(0.8);
                                      }
                                      if (states.contains(
                                        WidgetState.hovered,
                                      )) {
                                        return Theme.of(
                                          context,
                                        ).colorScheme.primary.withOpacity(0.9);
                                      }
                                      return Color.fromRGBO(239, 120, 26, 1);
                                    }),
                                foregroundColor:
                                    WidgetStateProperty.resolveWith<Color?>((
                                      Set<WidgetState> states,
                                    ) {
                                      return Colors.white;
                                    }),
                                shape: WidgetStateProperty.all<
                                  RoundedRectangleBorder
                                >(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18.0),
                                  ),
                                ),
                                padding: WidgetStateProperty.all<EdgeInsets>(
                                  const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                elevation: WidgetStateProperty.resolveWith<
                                  double?
                                >((Set<WidgetState> states) {
                                  if (states.contains(WidgetState.pressed)) {
                                    return 2.0;
                                  }
                                  return 5.0;
                                }),
                                textStyle: WidgetStateProperty.all<TextStyle>(
                                  const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                overlayColor: WidgetStateProperty.resolveWith<
                                  Color?
                                >((Set<WidgetState> states) {
                                  if (states.contains(WidgetState.hovered)) {
                                    return Colors.white.withOpacity(0.08);
                                  }
                                  if (states.contains(WidgetState.focused) ||
                                      states.contains(WidgetState.pressed)) {
                                    return Colors.white.withOpacity(0.24);
                                  }
                                  return null;
                                }),
                              ),
                              onPressed:
                                  () => _applyFilters(basicFilterChanged: true),
                              child: const Text(
                                'Restablecer distancia',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            body:
                _isLoading
                    ? Center(
                      child: RotatingIcon(
                        imagePath: 'assets/images/rotation_icon.png',
                      ),
                    )
                    : _isWebViewVisible
                    ? Stack(
                      children: [
                        if (!_isWebViewLoading)
                          WebViewWidget(controller: _controller),
                        if (_isWebViewLoading)
                          Center(
                            child: RotatingIcon(
                              imagePath: 'assets/images/rotation_icon.png',
                            ),
                          ),
                      ],
                    )
                    : _filteredRaces.isEmpty
                    ? const Center(
                      child: Text(
                        "No hay carreras para mostrar con los filtros seleccionados.",
                      ),
                    )
                    : LayoutBuilder(
                      builder: (
                        BuildContext context,
                        BoxConstraints constraints,
                      ) {
                        const double tabletBreakpoint = 600.0;
                        const double cardWidthForGridReference = 350.0;

                        Widget buildRaceItemWidget(Race race, bool isGridView) {
                          double cardHorizontalMargin = isGridView ? 8.0 : 16.0;
                          double cardPadding = isGridView ? 12.0 : 16.0;
                          int titleMaxLines = isGridView ? 2 : 1;
                          double titleFontSize = isGridView ? 15.0 : 16.0;
                          final TextStyle resultRace = TextStyle(
                            fontSize: 15,
                            color: Colors.grey[800],
                          );

                          return InkWell(
                            onTap: () {
                              // Aquí va el código que se ejecutará al pulsar la tablilla
                              if (race.registrationLink != null) {
                                _showRaceInWebView(race.registrationLink!);
                              } else {
                                print(
                                  'No hay enlace de inscripción disponible para ${race.name}',
                                );
                              }
                            },
                            child: Card(
                              margin: EdgeInsets.symmetric(
                                horizontal: cardHorizontalMargin,
                                vertical: 6.0,
                              ),
                              elevation: 2.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(cardPadding),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            // Added Column for name and date
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                race.name,
                                                maxLines: titleMaxLines,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: titleFontSize,
                                                ),
                                              ),
                                              if (race.date != null &&
                                                  race
                                                      .date!
                                                      .isNotEmpty) // Display date
                                                Container(
                                                  margin: EdgeInsets.only(
                                                    top: 4.0,
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Text(
                                                        'Fecha: ',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      Text(
                                                        '${race.date!} - ${race.month[0].toUpperCase()}${race.month.substring(1).toLowerCase()}',
                                                        style: resultRace,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        /*if (race.registrationLink != null)
                                                IconButton(
                                                  icon: const Icon(Icons.launch),
                                                  iconSize: 20.0,
                                                  constraints: BoxConstraints(),
                                                  padding: EdgeInsets.zero,
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                  onPressed: () =>
                                                      _showRaceInWebView(
                                                          race.registrationLink!),
                                                  tooltip:
                                                      'Abrir enlace de inscripción',
                                                ),*/
                                      ],
                                    ),
                                    const SizedBox(height: 0),
                                    if (race.zone != null)
                                      Row(
                                        children: [
                                          Text(
                                            'Zona: ',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '${race.zone?[0].toUpperCase()}${race.zone?.substring(1).toLowerCase()}',
                                            style: resultRace,
                                          ),
                                        ],
                                      ),
                                    if (race.type != null)
                                      Row(
                                        children: [
                                          Text(
                                            'Tipo: ',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '${race.type}',
                                            style: resultRace,
                                          ),
                                        ],
                                      ),
                                    if (race.terrain != null)
                                      Row(
                                        children: [
                                          Text(
                                            'Terreno: ',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '${race.terrain}',
                                            style: resultRace,
                                          ),
                                        ],
                                      ),
                                    if (race.distances.isNotEmpty)
                                      Row(
                                        children: [
                                          Text(
                                            'Distancias: ',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '${race.distances.join('m, ')}m',
                                            style: resultRace,
                                          ),
                                        ],
                                      ),
                                    if (isGridView) const Spacer(),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        if (constraints.maxWidth > tabletBreakpoint) {
                          int crossAxisCount = (constraints.maxWidth /
                                  cardWidthForGridReference)
                              .floor()
                              .clamp(2, 4);
                          if (constraints.maxWidth > tabletBreakpoint) {
                            if (crossAxisCount < 2) {
                              crossAxisCount = 2;
                            }
                          }

                          double cardWidth =
                              (constraints.maxWidth -
                                  ((crossAxisCount - 1) * 10.0) -
                                  24.0) /
                              crossAxisCount;
                          double cardHeight = 200.0;

                          return GridView.builder(
                            padding: const EdgeInsets.all(12.0),
                            itemCount: _filteredRaces.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 10.0,
                                  mainAxisSpacing: 10.0,
                                  childAspectRatio: cardWidth / cardHeight,
                                ),
                            itemBuilder: (context, index) {
                              final race = _filteredRaces[index];
                              return buildRaceItemWidget(race, true);
                            },
                          );
                        } else {
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            itemCount: _filteredRaces.length,
                            itemBuilder: (context, index) {
                              final race = _filteredRaces[index];
                              return buildRaceItemWidget(race, false);
                            },
                          );
                        }
                      },
                    ),
          ),
        ),
      ),
    );
  }
}
