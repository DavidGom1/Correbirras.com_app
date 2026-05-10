import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:correbirras/models/race.dart';
import '../core/theme/app_theme.dart';
import '../widgets/race_card.dart';

typedef ToggleFavoriteCallback = Future<void> Function(Race race);
typedef ShowWebViewCallback = void Function(String url);
typedef HandleShareRace = void Function(Race race);

class FavoritesScreen extends StatefulWidget {
  final List<Race> allRaces;
  final ToggleFavoriteCallback toggleFavorite;
  final ShowWebViewCallback showRaceInWebView;
  final HandleShareRace handleShareRace;

  const FavoritesScreen({
    super.key,
    required this.allRaces,
    required this.toggleFavorite,
    required this.showRaceInWebView,
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

  @override
  void didUpdateWidget(covariant FavoritesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.allRaces != oldWidget.allRaces) {
      _filterFavoriteRaces();
    }
  }

  void _filterFavoriteRaces() {
    setState(() {
      _favoriteRaces = widget.allRaces.where((race) => race.isFavorite).toList();
    });
  }

  Future<void> _handleToggleFavorite(Race race) async {
    await widget.toggleFavorite(race);
    _filterFavoriteRaces();
  }

  void _handleShowRaceInWebView(String url) {
    Navigator.of(context).pop();
    widget.showRaceInWebView(url);
  }

  void _handleShareRace(Race race) {
    widget.handleShareRace(race);
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle drawersTextStyle = TextStyle(
      color: AppTheme.getPrimaryTextColor(context),
      fontSize: 25,
      fontWeight: FontWeight.bold,
    );

    return Container(
      color: AppTheme.getPrimaryControlColor(context),
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            elevation: 0,
            shadowColor: const Color.fromARGB(186, 0, 0, 0),
            backgroundColor: AppTheme.getPrimaryControlColor(context),
            foregroundColor: AppTheme.getPrimaryTextColor(context),
            title: Text(
              'Favoritos',
              style: drawersTextStyle.copyWith(fontSize: 20),
            ),
            centerTitle: true,
            automaticallyImplyLeading: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
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
                      const SizedBox(height: 16),
                      Text(
                        'Aún no has marcado ninguna carrera como favorita.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          color: AppTheme.getDrawerTextDevColor(context),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.getPrimaryControlColor(context),
                          foregroundColor: AppTheme.getPrimaryTextColor(context),
                        ),
                        child: const Text('Explorar carreras'),
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
                            isGridView: true,
                            onTap: () {
                              if (race.registrationLink?.isNotEmpty ?? false) {
                                _handleShowRaceInWebView(race.registrationLink!);
                              }
                            },
                            onFavoriteToggle: () => _handleToggleFavorite(race),
                            onShare: () => _handleShareRace(race),
                          );
                        },
                      );
                    } else {
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        itemCount: _favoriteRaces.length,
                        itemBuilder: (context, index) {
                          final race = _favoriteRaces[index];
                          return RaceCard(
                            race: race,
                            isGridView: false,
                            onTap: () {
                              if (race.registrationLink?.isNotEmpty ?? false) {
                                _handleShowRaceInWebView(race.registrationLink!);
                              }
                            },
                            onFavoriteToggle: () => _handleToggleFavorite(race),
                            onShare: () => _handleShareRace(race),
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