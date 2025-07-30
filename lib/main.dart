import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:correbirras/screens/favorites_screen.dart';
import 'package:upgrader/upgrader.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// Imports refactorizados
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'models/race.dart';
import 'services/auth_service.dart';
import 'services/race_service.dart';
import 'services/util_service.dart';
import 'utils/notification_utils.dart';
import 'utils/upgrader_messages.dart';
import 'widgets/race_card.dart';
import 'widgets/app_drawer.dart';
import 'widgets/auth_dialog.dart';

void main() async {
  // Aseguramos que Flutter esté completamente inicializado
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización de Firebase de forma segura
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("✅ Firebase inicializado correctamente");
  } catch (e) {
    debugPrint("❌ Error al inicializar Firebase: $e");
    // Continuar sin Firebase en caso de error
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Agenda de carreras Correbirras',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
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
  bool isLoading = true;
  List<Race> _allRaces = [];
  List<Race> _filteredRaces = [];
  List<String>?
  _pendingFavoriteNames; // Para guardar favoritos cuando las carreras no están cargadas
  String? _selectedMonth;
  String? _selectedZone;
  String? _selectedType;
  String? _selectedTerrain;

  double _filteredMinDistance = 0;
  double _filteredMaxDistance = 0;
  RangeValues _selectedDistanceRange = const RangeValues(0, 0);

  bool _isWebViewVisible = false;
  bool _isWebViewLoading = false;
  late final WebViewController _controller;

  // Servicios refactorizados
  final AuthService _authService = AuthService();
  final RaceService _raceService = RaceService();
  final UtilService _utilService = UtilService();

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
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.light,
        systemNavigationBarDividerColor: isDark
            ? ControlColors.darkPrimary
            : ControlColors.lightPrimary,
        systemNavigationBarContrastEnforced: false,
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    // Escuchar cambios de autenticación de Firebase de forma segura
    try {
      _authService.authStateChanges.listen((User? user) {
        if (mounted) {
          setState(() {
            // Estado manejado por AuthService
          });

          debugPrint('Usuario autenticado: ${user?.email}');
          debugPrint('Nombre: ${user?.displayName}');
          debugPrint('Foto: ${user?.photoURL}');

          if (user != null) {
            _loadFavoritesFromFirestore();
          }
        }
      });
      debugPrint("✅ Listener de Firebase Auth configurado");
    } catch (e) {
      debugPrint("❌ Error al configurar Firebase Auth: $e");
    }

    _downloadHtmlAndParse();
    _controller = WebViewController()
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

  // Métodos de autenticación refactorizados
  Future<void> _logout() async {
    try {
      await _authService.logout();
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');
    }
  }

  // Cargar favoritos desde Firestore
  Future<void> _loadFavoritesFromFirestore() async {
    if (!_authService.isLoggedIn || _authService.currentUser == null) return;

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final userDoc = firestore
          .collection('users')
          .doc(_authService.currentUser!.uid);
      final favoritesSnapshot = await userDoc.collection('favorites').get();

      final favoriteNames = favoritesSnapshot.docs
          .map((doc) => doc.data()['raceName'] as String)
          .toList();

      // Si las carreras ya están cargadas, marcarlas como favoritas
      if (_allRaces.isNotEmpty) {
        for (var race in _allRaces) {
          race.isFavorite = favoriteNames.contains(race.name);
        }
        if (mounted) {
          setState(() {});
        }
      } else {
        // Si las carreras no están cargadas aún, guardar los favoritos para aplicarlos después
        _pendingFavoriteNames = favoriteNames;
      }

      debugPrint("Favoritos cargados desde Firestore: $favoriteNames");
    } catch (e) {
      debugPrint("Error al cargar favoritos desde Firestore: $e");
    }
  }

  Future<void> _toggleFavorite(Race race) async {
    setState(() {
      race.isFavorite = !race.isFavorite;
    });

    if (_authService.isLoggedIn && _authService.currentUser != null) {
      try {
        final FirebaseFirestore firestore = FirebaseFirestore.instance;
        final userDoc = firestore
            .collection('users')
            .doc(_authService.currentUser!.uid);

        if (race.isFavorite) {
          await userDoc.collection('favorites').doc(race.name).set({
            'raceName': race.name,
            'month': race.month,
            'zone': race.zone,
            'type': race.type,
            'terrain': race.terrain,
            'distances': race.distances,
            'registrationLink': race.registrationLink,
            'date': race.date,
            'addedAt': FieldValue.serverTimestamp(),
          });
          if (mounted) {
            NotificationUtils.showSuccess(
              context,
              'Carrera añadida a favoritos',
              title: '¡Éxito!',
            );
          }
        } else {
          await userDoc.collection('favorites').doc(race.name).delete();
          if (mounted) {
            NotificationUtils.showInfo(
              context,
              'Carrera eliminada de favoritos',
              title: 'Información',
            );
          }
        }
        debugPrint(
          "Favoritos sincronizados con Firestore para usuario: ${_authService.currentUser!.email}",
        );
      } catch (e) {
        debugPrint("Error al sincronizar favoritos con Firestore: $e");
        if (mounted) {
          setState(() {
            race.isFavorite = !race.isFavorite;
          });
          NotificationUtils.showError(
            context,
            'Error al sincronizar con el servidor',
            title: 'Error',
          );
        }
      }
    } else {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> favoriteRaces =
          prefs.getStringList('favoriteRaces') ?? [];

      if (race.isFavorite) {
        if (!favoriteRaces.contains(race.name)) {
          favoriteRaces.add(race.name);
        }
        if (mounted) {
          NotificationUtils.showSuccess(
            context,
            'Carrera añadida a favoritos',
            title: '¡Éxito!',
          );
        }
      } else {
        favoriteRaces.remove(race.name);
        if (mounted) {
          NotificationUtils.showSuccess(
            context,
            'Carrera eliminada de favoritos',
            title: 'Información',
          );
        }
      }

      await prefs.setStringList('favoriteRaces', favoriteRaces);
      debugPrint("Favoritos guardados localmente: $favoriteRaces");
    }
  }

  // Método para mostrar el diálogo de autenticación
  Future<void> _showAuthDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return const AuthDialog();
      },
    );
  }

  // Métodos de utilidades refactorizados
  Future<void> _launchURL(String url) async {
    await _utilService.launchURL(url);
  }

  // Métodos para el manejo de carreras
  Future<void> _downloadHtmlAndParse() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final races = await _raceService.downloadAndParseRaces();
      await _loadFavorites(races);

      if (mounted) {
        setState(() {
          _allRaces = races;
          _applyFilters(basicFilterChanged: true);
        });
      }
    } catch (e) {
      debugPrint("ERROR: Excepción durante la descarga: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Método para refrescar solo los favoritos del usuario (pull-to-refresh)
  Future<void> _refreshUserFavorites() async {
    if (_authService.isLoggedIn) {
      // Sincronizar favoritos desde Firestore para usuarios autenticados
      await _loadFavoritesFromFirestore();
    } else {
      // Para usuarios no autenticados, cargar favoritos locales
      await _loadFavoritesFromLocal(_allRaces);
    }

    // Aplicar filtros para actualizar la vista
    _applyFilters();
  }

  Future<void> _loadFavorites(List<Race> races) async {
    if (_authService.isLoggedIn) {
      await _loadFavoritesFromFirestore();
      // Si hay favoritos pendientes, aplicarlos ahora que las carreras están cargadas
      if (_pendingFavoriteNames != null) {
        for (var race in races) {
          race.isFavorite = _pendingFavoriteNames!.contains(race.name);
        }
        _pendingFavoriteNames = null; // Limpiar los favoritos pendientes
        debugPrint("Favoritos pendientes aplicados a las carreras cargadas");
      }
    } else {
      await _loadFavoritesFromLocal(races);
    }
  }

  Future<void> _loadFavoritesFromLocal(List<Race> races) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> favoriteRaces =
          prefs.getStringList('favoriteRaces') ?? [];

      for (var race in races) {
        race.isFavorite = favoriteRaces.contains(race.name);
      }

      debugPrint("Favoritos cargados localmente: $favoriteRaces");
    } catch (e) {
      debugPrint("Error al cargar favoritos locales: $e");
    }
  }

  void _applyFilters({
    bool basicFilterChanged = false,
    bool manualDistanceChange = false,
  }) {
    // Primero filtrar por criterios básicos (mes, zona, tipo, terreno)
    List<Race> basicFilteredRaces = _allRaces.where((race) {
      final matchMonth = _selectedMonth == null || race.month == _selectedMonth;
      final matchZone = _selectedZone == null || race.zone == _selectedZone;
      final matchType = _selectedType == null || race.type == _selectedType;
      final matchTerrain =
          _selectedTerrain == null || race.terrain == _selectedTerrain;
      return matchMonth && matchZone && matchType && matchTerrain;
    }).toList();

    // Calcular el nuevo rango de distancias basado en las carreras filtradas por criterios básicos
    double newMin = 0;
    double newMax = 0;
    final filteredDistances = basicFilteredRaces
        .expand((race) => race.distances)
        .toList();
    if (filteredDistances.isNotEmpty) {
      newMin = filteredDistances.reduce((a, b) => a < b ? a : b).toDouble();
      newMax = filteredDistances.reduce((a, b) => a > b ? a : b).toDouble();
    }

    // Determinar el rango de distancia a usar
    RangeValues newDistanceRange = _selectedDistanceRange;
    if (basicFilterChanged) {
      // Si es un cambio básico, usar el rango completo
      newDistanceRange = RangeValues(newMin, newMax);
    } else if (!manualDistanceChange) {
      // Solo expandir automáticamente si NO es un cambio manual del slider
      // Ajustar el rango seleccionado si está fuera de los nuevos límites
      double adjustedStart = _selectedDistanceRange.start;
      double adjustedEnd = _selectedDistanceRange.end;

      // Asegurar que tenemos un rango válido antes de ajustar
      if (newMin <= newMax) {
        // Para el mínimo: si el nuevo mínimo es menor, expandir automáticamente hacia abajo
        // Si el nuevo mínimo es mayor, ajustar al nuevo límite
        if (newMin < _selectedDistanceRange.start) {
          // Expandir automáticamente al nuevo mínimo disponible
          adjustedStart = newMin;
        } else if (adjustedStart < newMin) {
          // Ajustar al nuevo límite si se ha quedado fuera
          adjustedStart = newMin;
        }

        // Para el máximo: si el nuevo máximo es mayor, expandir automáticamente
        // Si el nuevo máximo es menor, ajustar al nuevo límite
        if (newMax > _selectedDistanceRange.end) {
          // Expandir automáticamente al nuevo máximo disponible
          adjustedEnd = newMax;
        } else if (adjustedEnd > newMax) {
          // Ajustar al nuevo límite si se ha quedado fuera
          adjustedEnd = newMax;
        }

        // Validación final para asegurar que start <= end y están dentro de los límites
        if (adjustedStart > newMax) adjustedStart = newMax;
        if (adjustedEnd < newMin) adjustedEnd = newMin;
        if (adjustedStart > adjustedEnd) adjustedStart = adjustedEnd;

        newDistanceRange = RangeValues(adjustedStart, adjustedEnd);
      } else {
        // Si no hay un rango válido (newMin > newMax), usar valores por defecto
        newDistanceRange = RangeValues(0, 0);
      }
    } else {
      // Es un cambio manual del slider, solo validar que esté dentro de los límites
      double adjustedStart = _selectedDistanceRange.start;
      double adjustedEnd = _selectedDistanceRange.end;

      if (newMin <= newMax) {
        // Solo ajustar si está fuera de los límites, sin expandir automáticamente
        if (adjustedStart < newMin) adjustedStart = newMin;
        if (adjustedStart > newMax) adjustedStart = newMax;
        if (adjustedEnd < newMin) adjustedEnd = newMin;
        if (adjustedEnd > newMax) adjustedEnd = newMax;
        if (adjustedStart > adjustedEnd) adjustedStart = adjustedEnd;

        newDistanceRange = RangeValues(adjustedStart, adjustedEnd);
      }
    }

    // Aplicar el filtro de distancia sobre las carreras ya filtradas por criterios básicos
    List<Race> finalFilteredRaces = List.from(basicFilteredRaces);
    if (newMax > 0 &&
        (newDistanceRange.start > newMin || newDistanceRange.end < newMax)) {
      finalFilteredRaces = finalFilteredRaces.where((race) {
        if (race.distances.isEmpty) {
          return false;
        }
        return race.distances.any(
          (d) => d >= newDistanceRange.start && d <= newDistanceRange.end,
        );
      }).toList();
    }

    // Actualizar el estado
    if (mounted) {
      setState(() {
        _filteredMinDistance = newMin;
        _filteredMaxDistance = newMax;

        // Asegurar que el rango seleccionado esté dentro de los límites válidos
        double finalMin = newMin;
        double finalMax = newMax > newMin ? newMax : newMin + 1;

        // Validar y ajustar el rango seleccionado
        double adjustedStart = newDistanceRange.start;
        double adjustedEnd = newDistanceRange.end;

        if (adjustedStart < finalMin) adjustedStart = finalMin;
        if (adjustedStart > finalMax) adjustedStart = finalMax;
        if (adjustedEnd < finalMin) adjustedEnd = finalMin;
        if (adjustedEnd > finalMax) adjustedEnd = finalMax;
        if (adjustedStart > adjustedEnd) adjustedStart = adjustedEnd;

        _selectedDistanceRange = RangeValues(adjustedStart, adjustedEnd);
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

  void _handleShareRace(Race race) {
    _utilService.shareRace(race);
  }

  void _hideWebView() {
    setState(() {
      _isWebViewVisible = false;
    });
  }

  void _resetAllFilters() {
    setState(() {
      _selectedMonth = null;
      _selectedZone = null;
      _selectedType = null;
      _selectedTerrain = null;
      _selectedDistanceRange = RangeValues(
        _filteredMinDistance,
        _filteredMaxDistance,
      );
    });
    _applyFilters(basicFilterChanged: true);
  }

  @override
  Widget build(BuildContext context) {
    final filterOptions = _raceService.getFilterOptions(_allRaces);

    final TextStyle drawersTextStyle = TextStyle(
      color: AppTheme.getPrimaryTextColor(context),
      fontSize: 25,
      fontWeight: FontWeight.bold,
    );

    return Container(
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
              durationUntilAlertAgain: Duration(days: 3),
              debugDisplayAlways: true,
              countryCode: 'ES',
              debugLogging: true,
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
                      onPressed: () => Scaffold.of(innerContext).openDrawer(),
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
                isLoggedIn: _authService.isLoggedIn,
                userDisplayName: _authService.userDisplayName,
                userEmail: _authService.userEmail,
                userPhotoURL: _authService.userPhotoURL,
                onAuthTap: _showAuthDialog,
                onLogout: _logout,
                onFavoritesTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FavoritesScreen(
                        allRaces: _allRaces,
                        toggleFavorite: _toggleFavorite,
                        showRaceInWebView: _showRaceInWebView,
                        handleShareRace: _handleShareRace,
                      ),
                    ),
                  );
                },
              ),
              endDrawer: _isWebViewVisible
                  ? null
                  : Drawer(
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
                            SizedBox(height: 20),
                            ListTile(
                              title: DropdownButton<String>(
                                isExpanded: true,
                                hint: const Text("Mes"),
                                value: _selectedMonth,
                                onChanged: (v) {
                                  setState(() {
                                    _selectedMonth = v;
                                  });
                                  _applyFilters(); // Sin basicFilterChanged para que se actualice dinámicamente
                                },
                                items: filterOptions.months.map((m) {
                                  return DropdownMenuItem(
                                    value: m,
                                    child: Text(
                                      m[0].toUpperCase() + m.substring(1),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            ListTile(
                              title: DropdownButton<String>(
                                isExpanded: true,
                                hint: const Text("Zona"),
                                value: _selectedZone,
                                onChanged: (v) {
                                  setState(() {
                                    _selectedZone = v;
                                  });
                                  _applyFilters(); // Sin basicFilterChanged para que se actualice dinámicamente
                                },
                                items: filterOptions.zones.map((z) {
                                  return DropdownMenuItem(
                                    value: z,
                                    child: Text(
                                      z[0].toUpperCase() + z.substring(1),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            ListTile(
                              title: DropdownButton<String>(
                                isExpanded: true,
                                hint: const Text("Tipo"),
                                value: _selectedType,
                                onChanged: (v) {
                                  setState(() {
                                    _selectedType = v;
                                  });
                                  _applyFilters(); // Sin basicFilterChanged para que se actualice dinámicamente
                                },
                                items: filterOptions.types.map((t) {
                                  return DropdownMenuItem(
                                    value: t,
                                    child: Text(t),
                                  );
                                }).toList(),
                              ),
                            ),
                            ListTile(
                              title: DropdownButton<String>(
                                isExpanded: true,
                                hint: const Text("Terreno"),
                                value: _selectedTerrain,
                                onChanged: (v) {
                                  setState(() {
                                    _selectedTerrain = v;
                                  });
                                  _applyFilters(); // Sin basicFilterChanged para que se actualice dinámicamente
                                },
                                items: filterOptions.terrains.map((t) {
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
                                  const Text('Distancia '),
                                  RangeSlider(
                                    values: _selectedDistanceRange,
                                    min: _filteredMinDistance,
                                    max:
                                        _filteredMaxDistance >
                                            _filteredMinDistance
                                        ? _filteredMaxDistance
                                        : _filteredMinDistance + 1,
                                    divisions:
                                        (_filteredMaxDistance >
                                            _filteredMinDistance)
                                        ? ((_filteredMaxDistance -
                                                      _filteredMinDistance) /
                                                  1)
                                              .round()
                                              .clamp(1, 1000)
                                        : null,
                                    labels: RangeLabels(
                                      '${_selectedDistanceRange.start.round().toString()}${'K'}',
                                      '${_selectedDistanceRange.end.round().toString()}${'K'}',
                                    ),
                                    activeColor: AppTheme.getSliderActiveColor(
                                      context,
                                    ),
                                    inactiveColor:
                                        AppTheme.getSliderInactiveColor(
                                          context,
                                        ),
                                    onChanged: (values) => setState(
                                      () => _selectedDistanceRange = values,
                                    ),
                                    onChangeEnd: (values) => _applyFilters(
                                      basicFilterChanged: false,
                                      manualDistanceChange: true,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.only(bottom: 10),
                                    child: Center(
                                      child: Text(
                                        "${_selectedDistanceRange.start.round()}K - ${_selectedDistanceRange.end.round()}K",
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.center,
                                    child: TextButton(
                                      style: ButtonStyle(
                                        backgroundColor:
                                            WidgetStateProperty.resolveWith<
                                              Color?
                                            >((Set<WidgetState> states) {
                                              if (states.contains(
                                                WidgetState.pressed,
                                              )) {
                                                return Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withValues(alpha: 0.8);
                                              }
                                              if (states.contains(
                                                WidgetState.hovered,
                                              )) {
                                                return Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withValues(alpha: 0.9);
                                              }
                                              return AppTheme.getSliderActiveColor(
                                                context,
                                              );
                                            }),
                                        foregroundColor:
                                            WidgetStateProperty.resolveWith<
                                              Color?
                                            >((Set<WidgetState> states) {
                                              return AppTheme.getPrimaryTextColor(
                                                context,
                                              );
                                            }),
                                        shape:
                                            WidgetStateProperty.all<
                                              RoundedRectangleBorder
                                            >(
                                              RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(18.0),
                                              ),
                                            ),
                                        padding:
                                            WidgetStateProperty.all<EdgeInsets>(
                                              const EdgeInsets.symmetric(
                                                horizontal: 24,
                                                vertical: 12,
                                              ),
                                            ),
                                        elevation:
                                            WidgetStateProperty.resolveWith<
                                              double?
                                            >((Set<WidgetState> states) {
                                              if (states.contains(
                                                WidgetState.pressed,
                                              )) {
                                                return 2.0;
                                              }
                                              return 5.0;
                                            }),
                                        textStyle:
                                            WidgetStateProperty.all<TextStyle>(
                                              const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                        overlayColor:
                                            WidgetStateProperty.resolveWith<
                                              Color?
                                            >((Set<WidgetState> states) {
                                              if (states.contains(
                                                WidgetState.hovered,
                                              )) {
                                                return AppTheme.getPrimaryTextColor(
                                                  context,
                                                ).withValues(alpha: 0.08);
                                              }
                                              if (states.contains(
                                                    WidgetState.focused,
                                                  ) ||
                                                  states.contains(
                                                    WidgetState.pressed,
                                                  )) {
                                                return AppTheme.getPrimaryTextColor(
                                                  context,
                                                ).withValues(alpha: 0.24);
                                              }
                                              return null;
                                            }),
                                      ),
                                      onPressed: _resetAllFilters,
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
                    ),
              body: isLoading
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
                  : Stack(
                      children: [
                        // Lista principal de carreras
                        if (!_isWebViewVisible)
                          LayoutBuilder(
                            builder: (context, constraints) {
                              const double tabletBreakpoint = 600.0;

                              if (constraints.maxWidth > tabletBreakpoint) {
                                int crossAxisCount =
                                    (constraints.maxWidth / 350.0)
                                        .floor()
                                        .clamp(2, 4);

                                return RefreshIndicator(
                                  onRefresh: _refreshUserFavorites,
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : AppTheme.getPrimaryControlColor(
                                          context,
                                        ),
                                  backgroundColor: AppTheme.getSurfaceColor(
                                    context,
                                  ),
                                  child: MasonryGridView.count(
                                    padding: const EdgeInsets.all(12.0),
                                    itemCount: _filteredRaces.length,
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 10.0,
                                    mainAxisSpacing: 10.0,
                                    itemBuilder: (context, index) {
                                      final race = _filteredRaces[index];
                                      return RaceCard(
                                        race: race,
                                        isGridView: true,
                                        onTap: () {
                                          if (race
                                                  .registrationLink
                                                  ?.isNotEmpty ??
                                              false) {
                                            _showRaceInWebView(
                                              race.registrationLink!,
                                            );
                                          } else {
                                            debugPrint(
                                              'No se encontró enlace para ${race.name}',
                                            );
                                          }
                                        },
                                        onFavoriteToggle: () =>
                                            _toggleFavorite(race),
                                        onShare: () => _handleShareRace(race),
                                      );
                                    },
                                  ),
                                );
                              } else {
                                return RefreshIndicator(
                                  onRefresh: _refreshUserFavorites,
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : AppTheme.getPrimaryControlColor(
                                          context,
                                        ),
                                  backgroundColor: AppTheme.getSurfaceColor(
                                    context,
                                  ),
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4.0,
                                    ),
                                    itemCount: _filteredRaces.length,
                                    itemBuilder: (context, index) {
                                      final race = _filteredRaces[index];
                                      return RaceCard(
                                        race: race,
                                        isGridView: false,
                                        onTap: () {
                                          if (race
                                                  .registrationLink
                                                  ?.isNotEmpty ??
                                              false) {
                                            _showRaceInWebView(
                                              race.registrationLink!,
                                            );
                                          } else {
                                            debugPrint(
                                              'No se encontró enlace para ${race.name}',
                                            );
                                          }
                                        },
                                        onFavoriteToggle: () =>
                                            _toggleFavorite(race),
                                        onShare: () => _handleShareRace(race),
                                      );
                                    },
                                  ),
                                );
                              }
                            },
                          ),

                        // WebView overlay
                        if (_isWebViewVisible)
                          Container(
                            color: AppTheme.getScaffoldBackground(context),
                            child: Column(
                              children: [
                                if (_isWebViewLoading)
                                  const LinearProgressIndicator(),
                                Expanded(
                                  child: WebViewWidget(controller: _controller),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
