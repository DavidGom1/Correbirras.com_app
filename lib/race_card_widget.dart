import 'package:flutter/material.dart';
import 'package:correbirras/main.dart'; // Importa la clase Race y otros elementos necesarios

// Define los tipos de funciones que pasaremos
typedef ToggleFavoriteCallback = Future<void> Function(Race race);
typedef ShowWebViewCallback = void Function(String url);
typedef HandleShareRace = void Function(Race race);

class RaceCardWidget extends StatelessWidget {
  final Race race;
  final bool isGridView;
  final ToggleFavoriteCallback toggleFavorite;
  final ShowWebViewCallback showRaceInWebView;
  final HandleShareRace handleShareRace;

  const RaceCardWidget({
    Key? key,
    required this.race,
    required this.isGridView,
    required this.toggleFavorite,
    required this.showRaceInWebView,
    required this.handleShareRace,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // --- Variables de configuración ---
    final double cardHorizontalMargin = isGridView ? 8.0 : 16.0;
    final double cardPadding = isGridView ? 12.0 : 16.0;
    final int titleMaxLines = isGridView ? 2 : 1;
    final double titleFontSize = isGridView ? 15.0 : 16.0;
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
          showRaceInWebView(race.registrationLink!);
        } else {
          debugPrint('No se encontró enlace para ${race.name}');
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 8.0),
                    if (race.date?.isNotEmpty ?? false)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 4.0,
                        ),
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
                        padding: const EdgeInsets.only(
                          top: 4.0,
                        ),
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
                        padding: const EdgeInsets.only(
                          top: 4.0,
                        ),
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
                        padding: const EdgeInsets.only(
                          top: 4.0,
                        ),
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
                        padding: const EdgeInsets.only(
                          top: 4.0,
                        ),
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
              VerticalDivider(),
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: Icon(
                        race.isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: race.isFavorite
                            ? Color.fromRGBO(239, 120, 26, 1)
                            : Colors.grey,
                        size: 30,
                      ),
                      onPressed: () {
                        toggleFavorite(race);
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.share,
                        color: Colors.grey,
                        size: 30,
                      ),
                      onPressed: () {
                        handleShareRace(race);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
