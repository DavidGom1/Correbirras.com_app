import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:correbirras/models/race.dart';
import '../core/theme/app_theme.dart';

import '../widgets/race_card.dart';

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
    _filterFavoriteRaces();
  }

  void _filterFavoriteRaces() {
    // No necesitamos async aquí porque solo estamos filtrando una lista local
    setState(() {
      _favoriteRaces = widget.allRaces
          .where((race) => race.isFavorite)
          .toList();
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
  
  @override
  Widget build(BuildContext context) {
    final TextStyle drawersTextStyle = TextStyle(
      color: Colors.white,
      fontSize: 25,
      fontWeight: FontWeight.bold,
    );

    return Container(
      color: AppTheme.getPrimaryControlColor(
        context,
      ), // Usar método actualizado
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            elevation: 0,
            shadowColor: const Color.fromARGB(186, 0, 0, 0),
            backgroundColor: AppTheme.getPrimaryControlColor(
              context,
            ), // Usar método actualizado
            foregroundColor: Colors.white,
            title: Text(
              'Favoritos',
              style: drawersTextStyle.copyWith(fontSize: 20),
            ),
            centerTitle: true,
            automaticallyImplyLeading:
                true, // Asegurar que se muestre el botón de retroceso
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          body: _favoriteRaces.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 80,
                        color: AppTheme.getSecondaryIconColor(context),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Aún no has marcado ninguna carrera como favorita.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          color: AppTheme.getSecondaryTextColor(context),
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.getPrimaryControlColor(
                            context,
                          ), // Usar método actualizado
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
                      int crossAxisCount =
                          (constraints.maxWidth / cardWidthForGridReference)
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
                          return RaceCard(
                                            race: race,
                                            isGridView: false,
                                            onTap: () {
                                              if (race
                                                      .registrationLink
                                                      ?.isNotEmpty ??
                                                  false) {
                                                _handleShowRaceInWebView(
                                                  race.registrationLink!,
                                                );
                                              } else {
                                                debugPrint(
                                                  'No se encontró enlace para ${race.name}',
                                                );
                                              }
                                            },
                                            onFavoriteToggle: () =>
                                                _handleToggleFavorite(race),
                                            onShare: () =>
                                                _handleShareRace(race),
                                          );
                        },
                      );
                    } else {
                      // VISTA MÓVIL: ListView
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        itemCount: _favoriteRaces.length,
                        itemBuilder: (context, index) {
                          final race = _favoriteRaces[index];
                          return RaceCard(
                                            race: race,
                                            isGridView: false,
                                            onTap: () {
                                              if (race
                                                      .registrationLink
                                                      ?.isNotEmpty ??
                                                  false) {
                                                _handleShowRaceInWebView(
                                                  race.registrationLink!,
                                                );
                                              } else {
                                                debugPrint(
                                                  'No se encontró enlace para ${race.name}',
                                                );
                                              }
                                            },
                                            onFavoriteToggle: () =>
                                                _handleToggleFavorite(race),
                                            onShare: () =>
                                                _handleShareRace(race),
                                          );
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
