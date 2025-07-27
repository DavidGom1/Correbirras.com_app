import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'main.dart'; // Importa tu archivo principal

// Define los tipos de funciones que pasaremos
typedef ToggleFavoriteCallback = Future<void> Function(Race race);
typedef ShowWebViewCallback = void Function(String url);
typedef HandleShareRace = void Function(Race race);

class FavoritesScreen extends StatefulWidget {
  final List<Race> allRaces;
  final ToggleFavoriteCallback toggleFavorite; // Recibe la función de toggle
  final ShowWebViewCallback showRaceInWebView; // Recibe la función de webview
  final HandleShareRace handleShareRace;

  const FavoritesScreen({
    super.key,
    required this.allRaces,
    required this.toggleFavorite, // Añade al constructor
    required this.showRaceInWebView, // Añade al constructor
    required this.handleShareRace,
  });

  @override
  FavoritesScreenState createState() => FavoritesScreenState();
}

class FavoritesScreenState extends State<FavoritesScreen> {
  List<Race> _favoriteRaces = [];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color.fromRGBO(239, 120, 26, 1),
        statusBarIconBrightness: Brightness.light,
        systemStatusBarContrastEnforced: true,
        systemNavigationBarColor: Color.fromRGBO(
          239,
          120,
          26,
          1,
        ), // Esta línea configura la barra inferior
        systemNavigationBarIconBrightness:
            Brightness
                .light, // Esta línea configura los iconos de la barra inferior
      ),
    );
    _filterFavoriteRaces();
  }

  void _filterFavoriteRaces() {
    // No necesitamos async aquí porque solo estamos filtrando una lista local
    setState(() {
      _favoriteRaces =
          widget.allRaces.where((race) => race.isFavorite).toList();
    });
  }

  // Llama a la función pasada desde MyHomePage y luego actualiza la lista local
  Future<void> _handleToggleFavorite(Race race) async {
    await widget.toggleFavorite(race); // Llama a la función recibida

    // Actualiza la lista local en FavoritesScreen después de que la principal haya guardado
    _filterFavoriteRaces();
  }

  // Llama a la función de webview pasada desde MyHomePage
  void _handleShowRaceInWebView(String url) {
    widget.showRaceInWebView(url); // Llama a la función recibida
  }

  void _handleShareRace(Race race) {
    widget.handleShareRace(race); // Llama a la función recibida
  }

  // Widget reutilizable para construir cada tarjeta de carrera
  Widget _buildRaceItem(Race race, bool isGridView) {
    // --- Variables de configuración ---
    final double cardHorizontalMargin = isGridView ? 4.0 : 16.0;
    final double cardVerticalMargin = isGridView ? 4.0 : 6.0;
    final double cardPadding = 16.0;
    final int? titleMaxLines = isGridView ? null : 1; // null permite líneas ilimitadas en grid
    final double titleFontSize = 16.0;
    final TextStyle resultRaceStyle = TextStyle(
      fontSize: 15,
      color: Colors.grey[800],
      fontWeight: FontWeight.w400,
    );
    final TextStyle labelStyle = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
    );

    return InkWell(
      onTap: () {
        if (race.registrationLink?.isNotEmpty ?? false) {
          _handleShowRaceInWebView(race.registrationLink!);
          Navigator.pop(context);
        } else {
          debugPrint('No se encontró enlace para ${race.name}');
        }
      },
      child: Card(
        margin: EdgeInsets.symmetric(
          horizontal: cardHorizontalMargin,
          vertical: cardVerticalMargin,
        ),
        elevation: 2.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // Important for height
                    children: [
                      Text(
                        race.name,
                        maxLines: titleMaxLines,
                        overflow: titleMaxLines != null ? TextOverflow.ellipsis : TextOverflow.visible,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: titleFontSize,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      if (race.date?.isNotEmpty ?? false)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text.rich(
                            TextSpan(
                              text: 'Fecha: ',
                              style: labelStyle,
                              children: <TextSpan>[
                                TextSpan(
                                  text: '${race.date} - ${race.month}',
                                  style: resultRaceStyle,
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (race.zone?.isNotEmpty ?? false)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text.rich(
                            TextSpan(
                              text: 'Zona: ',
                              style: labelStyle,
                              children: <TextSpan>[
                                TextSpan(
                                  text:
                                      '${race.zone?[0].toUpperCase()}${race.zone?.substring(1).toLowerCase()}',
                                  style: resultRaceStyle,
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (race.type?.isNotEmpty ?? false)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text.rich(
                            TextSpan(
                              text: 'Tipo: ',
                              style: labelStyle,
                              children: <TextSpan>[
                                TextSpan(
                                  text: race.type,
                                  style: resultRaceStyle,
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (race.terrain?.isNotEmpty ?? false)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text.rich(
                            TextSpan(
                              text: 'Terreno: ',
                              style: labelStyle,
                              children: <TextSpan>[
                                TextSpan(
                                  text: race.terrain,
                                  style: resultRaceStyle,
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (race.distances.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text.rich(
                            TextSpan(
                              text: 'Distancias: ',
                              style: labelStyle,
                              children: <TextSpan>[
                                TextSpan(
                                  text: '${race.distances.join('m, ')}m',
                                  style: resultRaceStyle,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const VerticalDivider(),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.favorite,
                          color: Color.fromRGBO(239, 120, 26, 1),
                          size: 30,
                        ),
                        onPressed: () {
                          _handleToggleFavorite(race);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.share, color: Colors.grey, size: 30),
                        onPressed: () {
                          _handleShareRace(race);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle drawersTextStyle = TextStyle(
      color: Colors.white,
      fontSize: 25,
      fontWeight: FontWeight.bold,
    );

    return Container(
      color: Color.fromRGBO(239, 120, 26, 1),
      child: SafeArea(
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          shadowColor: const Color.fromARGB(186, 0, 0, 0),
          backgroundColor: Color.fromRGBO(239, 120, 26, 1) ,
          foregroundColor: Colors.white,
          title: Text(
            'Favoritos',
            style: drawersTextStyle.copyWith(fontSize: 20),
          ),
          centerTitle: true,
        ),
        body:
            _favoriteRaces.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Aún no has marcado ninguna carrera como favorita.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromRGBO(239, 120, 26, 1),
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Explorar carreras'),
                      ),
                    ],
                  ),
                )
                : LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    const double tabletBreakpoint = 600.0;

                    const double cardWidthForGridReference = 350.0;
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

                      return MasonryGridView.count(
                        padding: const EdgeInsets.all(12.0),
                        itemCount: _favoriteRaces.length,
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 10.0,
                        mainAxisSpacing: 10.0,
                        itemBuilder: (context, index) {
                          final race = _favoriteRaces[index];
                          return _buildRaceItem(race, true);
                        },
                      );
                    } else {
                      // VISTA MÓVIL: ListView
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        itemCount: _favoriteRaces.length,
                        itemBuilder: (context, index) {
                          final race = _favoriteRaces[index];
                          return _buildRaceItem(race, false);
                        },
                      );
                    }
                  },
                ),
      ),
      ),
    );
  }
}
