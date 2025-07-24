import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart'; // Importa tu archivo principal

// Define los tipos de funciones que pasaremos
typedef ToggleFavoriteCallback = Future<void> Function(Race race);
typedef ShowWebViewCallback = void Function(String url);


class FavoritesScreen extends StatefulWidget {
  final List<Race> allRaces;
  final ToggleFavoriteCallback toggleFavorite; // Recibe la función de toggle
  final ShowWebViewCallback showRaceInWebView; // Recibe la función de webview


  const FavoritesScreen({
    super.key,
    required this.allRaces,
    required this.toggleFavorite, // Añade al constructor
    required this.showRaceInWebView, // Añade al constructor
  });

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Race> _favoriteRaces = [];

  @override
  void initState() {
    super.initState();
    _filterFavoriteRaces();
  }

  void _filterFavoriteRaces() {
    // No necesitamos async aquí porque solo estamos filtrando una lista local
    setState(() {
      _favoriteRaces = widget.allRaces.where((race) => race.isFavorite).toList();
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


  @override
  Widget build(BuildContext context) {
    final TextStyle drawersTextStyle = TextStyle(
      color: Colors.white,
      fontSize: 25,
      fontWeight: FontWeight.bold,
    );

    // Reutilizamos las variables de configuración de la visualización de la carrera
     const double cardHorizontalMargin = 16.0; // Usamos el estilo de lista simple
     const double cardPadding = 16.0; // Usamos el estilo de lista simple
     const int titleMaxLines = 1; // Usamos el estilo de lista simple
     const double titleFontSize = 16.0; // Usamos el estilo de lista simple
     final TextStyle resultRaceStyle = TextStyle(
       fontSize: 15,
       color: Colors.grey[800],
       fontWeight: FontWeight.w400,
     );
     final TextStyle labelStyle = const TextStyle(
       fontSize: 14,
       fontWeight: FontWeight.bold,
     );


    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Color.fromRGBO(239, 120, 26, 1),
          statusBarIconBrightness: Brightness.light,
        ),
        shadowColor: const Color.fromARGB(186, 0, 0, 0),
        backgroundColor: correbirrasOrange,
        foregroundColor: Colors.white,
        title: Text('Favoritos', style: drawersTextStyle.copyWith(fontSize: 20)),
        centerTitle: true,
      ),
      body: _favoriteRaces.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
                   SizedBox(height: 16),
                  Text(
                    'Aún no has marcado ninguna carrera como favorita.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                   SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                       Navigator.pop(context); // Vuelve a la pantalla principal
                    },
                     style: ElevatedButton.styleFrom(
                        backgroundColor: correbirrasOrange,
                        foregroundColor: Colors.white,
                     ),
                    child: Text('Explorar carreras'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              itemCount: _favoriteRaces.length,
              itemBuilder: (context, index) {
                final race = _favoriteRaces[index];
                return InkWell(
                   onTap: () {
                     if (race.registrationLink?.isNotEmpty ?? false) {
                       // 1. Llama a la función para mostrar la WebView en la pantalla de abajo.
                       _handleShowRaceInWebView(race.registrationLink!);
                       // 2. Cierra esta pantalla para revelar la pantalla principal con la WebView.
                       Navigator.pop(context);
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
                        crossAxisAlignment: CrossAxisAlignment.end,
                         children: [
                           Expanded(
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
                                             text: '${race.zone?[0].toUpperCase()}${race.zone?.substring(1).toLowerCase()}',
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
                           IconButton(
                             icon: Icon(
                               Icons.favorite,
                               color: Color.fromRGBO(239, 120, 26, 1),
                               size: 30,
                             ),
                             onPressed: () {
                               _handleToggleFavorite(race); // Llama a la función local que llama a la de MyHomePage
                             },
                           ),
                         ],
                       ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
