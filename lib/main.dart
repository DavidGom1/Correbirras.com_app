import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:upgrader/upgrader.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'models/race.dart';
import 'providers/race_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/ad_provider.dart';
import 'services/ad_service.dart' as ad_service_legacy;
import 'services/util_service.dart';
import 'utils/notification_utils.dart';
import 'utils/upgrader_messages.dart';
import 'widgets/race_card.dart';
import 'widgets/app_drawer.dart';
import 'widgets/auth_dialog.dart';
import 'screens/favorites_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("✅ Firebase inicializado correctamente");
  } catch (e) {
    debugPrint("❌ Error al inicializar Firebase: $e");
  }

  try {
    await ad_service_legacy.AdService.initialize();
  } catch (e) {
    debugPrint("❌ Error al inicializar AdMob: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => RaceProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => AdProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Agenda de carreras Correbirras',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.flutterThemeMode,
            home: const MyHomePage(title: 'Correbirras.com'),
          );
        },
      ),
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
  bool _isWebViewVisible = false;
  bool _isWebViewLoading = false;
  late final WebViewController _controller;
  String? _webViewError;

  final UtilService _utilService = UtilService();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final raceProvider = context.read<RaceProvider>();
      raceProvider.loadRaces();

      final adProvider = context.read<AdProvider>();
      adProvider.loadBannerAd(onLoaded: () {
        if (mounted) setState(() {});
      });

      final favoritesProvider = context.read<FavoritesProvider>();
      favoritesProvider.authStateChanges.listen((user) {
        if (mounted && user != null) {
          _syncFavorites();
        }
      });
    });

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color.fromARGB(0, 0, 0, 0))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isWebViewLoading = true;
              _webViewError = null;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isWebViewLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isWebViewLoading = false;
              _webViewError = 'Error al cargar la página: ${error.description}';
            });
            debugPrint('❌ WebView error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            if (_utilService.isPdfUrl(request.url)) {
              debugPrint('PDF link interceptado: ${request.url}');
              _launchURL(request.url);
              return NavigationDecision.prevent;
            }

            if (_utilService.isSocialMediaUrl(request.url)) {
              debugPrint('Enlace de red social interceptado: ${request.url}');
              _launchURL(request.url);
              _hideWebView();
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _configureSystemUI();
  }

  Future<void> _syncFavorites() async {
    final favoritesProvider = context.read<FavoritesProvider>();
    final raceProvider = context.read<RaceProvider>();

    await favoritesProvider.loadFavorites();
    await favoritesProvider.mergeLocalToCloud();
    await raceProvider.loadFavoritesIntoRaces(favoritesProvider.favoriteNames);
  }

  void _configureSystemUI() {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: isDark
            ? ControlColors.darkPrimary
            : ControlColors.lightPrimary,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: isDark
            ? ControlColors.darkPrimary
            : ControlColors.lightPrimary,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: isDark
            ? ControlColors.darkPrimary
            : ControlColors.lightPrimary,
        systemNavigationBarContrastEnforced: false,
      ),
    );
  }

  Future<void> _handleToggleFavorite(Race race) async {
    final favoritesProvider = context.read<FavoritesProvider>();
    final raceProvider = context.read<RaceProvider>();

    final wasFavorite = race.isFavorite;
    raceProvider.setFavorite(race, !wasFavorite);

    final success = await favoritesProvider.toggleFavorite(race);

    if (!success) {
      raceProvider.setFavorite(race, wasFavorite);
      if (mounted) {
        NotificationUtils.showError(
          context,
          'Error al sincronizar con el servidor',
          title: 'Error',
        );
      }
    } else if (mounted) {
      NotificationUtils.showSuccess(
        context,
        wasFavorite ? 'Carrera eliminada de favoritos' : 'Carrera añadida a favoritos',
        title: wasFavorite ? 'Información' : '¡Éxito!',
      );
    }
  }

  void _showRaceInWebView(String url) {
    if (!_utilService.isValidUrl(url)) {
      debugPrint('URL inválida: $url');
      return;
    }
    _controller.loadRequest(Uri.parse(url));
    setState(() {
      _isWebViewVisible = true;
      _webViewError = null;
    });
  }

  void _handleShareRace(Race race) {
    _utilService.shareRace(race);
  }

  void _hideWebView() {
    setState(() {
      _isWebViewVisible = false;
      _webViewError = null;
    });
  }

  Future<void> _refreshData() async {
    final raceProvider = context.read<RaceProvider>();
    final favoritesProvider = context.read<FavoritesProvider>();

    await raceProvider.loadRaces();
    await favoritesProvider.loadFavorites();
    await raceProvider.loadFavoritesIntoRaces(favoritesProvider.favoriteNames);
  }

  void _showAuthDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return const AuthDialog();
      },
    );
  }

  Future<void> _launchURL(String url) async {
    await _utilService.launchURL(url);
  }

  @override
  Widget build(BuildContext context) {
    final raceProvider = context.watch<RaceProvider>();
    final favoritesProvider = context.read<FavoritesProvider>();
    final adProvider = context.watch<AdProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _configureSystemUI();
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Theme.of(context).brightness == Brightness.dark
            ? ControlColors.darkPrimary
            : ControlColors.lightPrimary,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Theme.of(context).brightness == Brightness.dark
            ? ControlColors.darkPrimary
            : ControlColors.lightPrimary,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Theme.of(context).brightness == Brightness.dark
            ? ControlColors.darkPrimary
            : ControlColors.lightPrimary,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Container(
        color: AppTheme.getPrimaryControlColor(context),
        child: SafeArea(
          child: PopScope<Object?>(
            canPop: !_isWebViewVisible,
            onPopInvokedWithResult: (bool didPop, Object? result) async {
              if (!didPop && _isWebViewVisible) {
                _hideWebView();
              }
            },
            child: UpgradeAlert(
              upgrader: Upgrader(
                durationUntilAlertAgain: const Duration(days: 3),
                countryCode: 'ES',
                messages: CorrebirrasUpgraderMessages(),
              ),
              child: Scaffold(
                appBar: AppBar(
                  elevation: 0,
                  shadowColor: const Color.fromARGB(186, 0, 0, 0),
                  backgroundColor: AppTheme.getPrimaryControlColor(context),
                  foregroundColor: AppTheme.getPrimaryTextColor(context),
                  leading: Builder(
                    builder: (BuildContext innerContext) {
                      return IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () =>
                            Scaffold.of(innerContext).openDrawer(),
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
                            onPressed: () =>
                                Scaffold.of(innerContext).openEndDrawer(),
                          );
                        },
                      ),
                  ],
                ),
                drawer: AppDrawer(
                  isLoggedIn: favoritesProvider.isLoggedIn,
                  userDisplayName: favoritesProvider.userDisplayName,
                  userEmail: favoritesProvider.userEmail,
                  userPhotoURL: favoritesProvider.userPhotoURL,
                  onAuthTap: _showAuthDialog,
                  onLogout: () async {
                    try {
                      await favoritesProvider.logout();
                      if (!mounted) return;
                      await _refreshData();
                      if (!context.mounted) return;
                      NotificationUtils.showSuccess(
                        context,
                        'Tu sesión se ha cerrado correctamente',
                        title: 'Sesión Cerrada',
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      NotificationUtils.showError(
                        context,
                        'No se pudo cerrar la sesión',
                        title: 'Error',
                      );
                    }
                  },
                  onFavoritesTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FavoritesScreen(
                          allRaces: raceProvider.allRaces,
                          toggleFavorite: _handleToggleFavorite,
                          showRaceInWebView: _showRaceInWebView,
                          handleShareRace: _handleShareRace,
                        ),
                      ),
                    );
                  },
                  allRaces: raceProvider.allRaces,
                  toggleFavorite: _handleToggleFavorite,
                  showRaceInWebView: _showRaceInWebView,
                  handleShareRace: _handleShareRace,
                ),
                endDrawer: _isWebViewVisible
                    ? null
                    : _buildFilterDrawer(context, raceProvider),
                body: Column(
                  children: [
                    Expanded(
                      child: raceProvider.isLoading && raceProvider.allRaces.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AppTheme.getSpinKitPumpingHeart(context),
                                const SizedBox(height: 20),
                                const Text(
                                  'Cargando carreras...',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : raceProvider.error != null && raceProvider.allRaces.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                                  const SizedBox(height: 16),
                                  Text(
                                    raceProvider.error!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _refreshData,
                                    child: const Text('Reintentar'),
                                  ),
                                ],
                              ),
                            )
                          : Stack(
                              children: [
                                if (!_isWebViewVisible)
                                  RefreshIndicator(
                                    onRefresh: _refreshData,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : AppTheme.getPrimaryControlColor(context),
                                    backgroundColor: AppTheme.getSurfaceColor(context),
                                    child: _buildRaceList(context, raceProvider),
                                  ),
                                if (_isWebViewVisible)
                                  Container(
                                    color: AppTheme.getScaffoldBackground(context),
                                    child: Column(
                                      children: [
                                        if (_isWebViewLoading)
                                          const LinearProgressIndicator(),
                                        if (_webViewError != null)
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            color: Colors.red.shade100,
                                            child: Row(
                                              children: [
                                                const Icon(Icons.error, color: Colors.red),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    _webViewError!,
                                                    style: const TextStyle(color: Colors.red),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () => _hideWebView(),
                                                  child: const Text('Cerrar'),
                                                ),
                                              ],
                                            ),
                                          ),
                                        if (_webViewError == null)
                                          Expanded(
                                            child: WebViewWidget(
                                              controller: _controller,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                    ),
                    if (adProvider.isBannerAdLoaded)
                      Container(
                        color: AppTheme.getPrimaryControlColor(context),
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: adProvider.getBannerWidget(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRaceList(BuildContext context, RaceProvider raceProvider) {
    final races = raceProvider.filteredRaces;
    if (races.isEmpty && !raceProvider.isLoading) {
      return ListView(
        children: const [
          SizedBox(height: 200),
          Center(
            child: Text(
              'No se encontraron carreras con los filtros seleccionados',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const double tabletBreakpoint = 600.0;

        if (constraints.maxWidth > tabletBreakpoint) {
          int crossAxisCount =
              (constraints.maxWidth / 350.0).floor().clamp(2, 4);

          return MasonryGridView.count(
            padding: const EdgeInsets.all(12.0),
            itemCount: races.length,
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 10.0,
            itemBuilder: (context, index) {
              final race = races[index];
              return RaceCard(
                race: race,
                isGridView: true,
                onTap: () {
                  if (race.registrationLink?.isNotEmpty ?? false) {
                    _showRaceInWebView(race.registrationLink!);
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
            itemCount: races.length,
            itemBuilder: (context, index) {
              final race = races[index];
              return RaceCard(
                race: race,
                isGridView: false,
                onTap: () {
                  if (race.registrationLink?.isNotEmpty ?? false) {
                    _showRaceInWebView(race.registrationLink!);
                  }
                },
                onFavoriteToggle: () => _handleToggleFavorite(race),
                onShare: () => _handleShareRace(race),
              );
            },
          );
        }
      },
    );
  }

  Widget _buildFilterDrawer(BuildContext context, RaceProvider raceProvider) {
final filterOptions = raceProvider.filterOptions;

    final TextStyle drawersTextStyle = TextStyle(
      color: AppTheme.getPrimaryTextColor(context),
      fontSize: 25,
      fontWeight: FontWeight.bold,
    );

    return Drawer(
      child: Material(
        color: AppTheme.getSurfaceColor(context),
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            Container(
              padding: EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: AppTheme.getDrawerHeaderColor(context),
              ),
              child: Center(
                child: Text('Filtros', style: drawersTextStyle),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              title: DropdownButton<String>(
                isExpanded: true,
                hint: const Text("Mes"),
                value: raceProvider.selectedMonth,
                onChanged: (v) => raceProvider.setMonth(v),
                items: filterOptions.months.map((m) {
                  return DropdownMenuItem(
                    value: m,
                    child: Text(m[0].toUpperCase() + m.substring(1)),
                  );
                }).toList(),
              ),
            ),
            ListTile(
              title: DropdownButton<String>(
                isExpanded: true,
                hint: const Text("Zona"),
                value: raceProvider.selectedZone,
                onChanged: (v) => raceProvider.setZone(v),
                items: filterOptions.zones.map((z) {
                  return DropdownMenuItem(
                    value: z,
                    child: Text(z[0].toUpperCase() + z.substring(1)),
                  );
                }).toList(),
              ),
            ),
            ListTile(
              title: DropdownButton<String>(
                isExpanded: true,
                hint: const Text("Tipo"),
                value: raceProvider.selectedType,
                onChanged: (v) => raceProvider.setType(v),
                items: filterOptions.types.map((t) {
                  return DropdownMenuItem(
                    value: t,
                    child: Text(t),
                  );
                }).toList(),
              ),
            ),
            ListTile(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Precio '),
                  RangeSlider(
                    values: raceProvider.selectedPriceRange,
                    min: raceProvider.filteredMinPrice,
                    max: raceProvider.filteredMaxPrice > raceProvider.filteredMinPrice
                        ? raceProvider.filteredMaxPrice
                        : raceProvider.filteredMinPrice + 1,
                    divisions: raceProvider.filteredMaxPrice > raceProvider.filteredMinPrice
                        ? ((raceProvider.filteredMaxPrice - raceProvider.filteredMinPrice) / 1)
                            .round()
                            .clamp(1, 200)
                        : null,
                    labels: RangeLabels(
                      '${raceProvider.selectedPriceRange.start.round()}€',
                      '${raceProvider.selectedPriceRange.end.round()}€',
                    ),
                    activeColor: AppTheme.getSliderActiveColor(context),
                    inactiveColor: AppTheme.getSliderInactiveColor(context),
                    onChanged: (values) =>
                        raceProvider.setPriceRange(values),
                    onChangeEnd: (values) =>
                        raceProvider.setPriceRange(values, manualChange: true),
                  ),
                  Container(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Center(
                      child: Text(
                        "${raceProvider.selectedPriceRange.start.round()}€ - ${raceProvider.selectedPriceRange.end.round()}€",
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Distancia '),
                  RangeSlider(
                    values: raceProvider.selectedDistanceRange,
                    min: raceProvider.filteredMinDistance,
                    max: raceProvider.filteredMaxDistance > raceProvider.filteredMinDistance
                        ? raceProvider.filteredMaxDistance
                        : raceProvider.filteredMinDistance + 1,
                    divisions: raceProvider.filteredMaxDistance > raceProvider.filteredMinDistance
                        ? ((raceProvider.filteredMaxDistance - raceProvider.filteredMinDistance) / 1)
                            .round()
                            .clamp(1, 1000)
                        : null,
                    labels: RangeLabels(
                      '${raceProvider.selectedDistanceRange.start.round()}K',
                      '${raceProvider.selectedDistanceRange.end.round()}K',
                    ),
                    activeColor: AppTheme.getSliderActiveColor(context),
                    inactiveColor: AppTheme.getSliderInactiveColor(context),
                    onChanged: (values) =>
                        raceProvider.setDistanceRange(values),
                    onChangeEnd: (values) =>
                        raceProvider.setDistanceRange(values, manualChange: true),
                  ),
                  Container(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Center(
                      child: Text(
                        "${raceProvider.selectedDistanceRange.start.round()}K - ${raceProvider.selectedDistanceRange.end.round()}K",
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: TextButton(
                      style: ButtonStyle(
                        backgroundColor:
                            WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.pressed)) {
                                return Theme.of(context).colorScheme.primary.withValues(alpha: 0.8);
                              }
                              if (states.contains(WidgetState.hovered)) {
                                return Theme.of(context).colorScheme.primary.withValues(alpha: 0.9);
                              }
                              return AppTheme.getSliderActiveColor(context);
                            }),
                        foregroundColor:
                            WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                              return AppTheme.getPrimaryTextColor(context);
                            }),
                        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18.0),
                          ),
                        ),
                        padding: WidgetStateProperty.all<EdgeInsets>(
                          const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        elevation: WidgetStateProperty.resolveWith<double?>((Set<WidgetState> states) {
                          if (states.contains(WidgetState.pressed)) return 2.0;
                          return 5.0;
                        }),
                        textStyle: WidgetStateProperty.all<TextStyle>(
                          const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        overlayColor:
                            WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.hovered)) {
                                return AppTheme.getPrimaryTextColor(context).withValues(alpha: 0.08);
                              }
                              if (states.contains(WidgetState.focused) ||
                                  states.contains(WidgetState.pressed)) {
                                return AppTheme.getPrimaryTextColor(context).withValues(alpha: 0.24);
                              }
                              return null;
                            }),
                      ),
                      onPressed: () => raceProvider.resetAllFilters(),
                      child: const Text(
                        'Restablecer filtros',
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
    );
  }
}