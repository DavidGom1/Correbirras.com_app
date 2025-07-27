import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as html_dom;
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:correbirras/favorites_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:upgrader/upgrader.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';

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

// Mensajes personalizados en español para upgrader
class CorrebirrasUpgraderMessages extends UpgraderMessages {
  @override
  String get buttonTitleUpdate => 'Actualizar Ahora';
  
  @override
  String get buttonTitleLater => 'Más Tarde';
  
  @override
  String get prompt => 'Una nueva versión de Correbirras está disponible. ¿Te gustaría actualizar ahora?';
  
  @override
  String get title => 'Actualización Disponible';
  
  @override
  String get buttonTitleIgnore => 'Ignorar';
  
  @override
  String get releaseNotes => 'Notas de la versión:';
}

class Race {
  final String month;
  final String name;
  final String? date; // Added date field
  final String? zone;
  final String? type;
  final String? terrain;
  final List<double> distances;
  final String? registrationLink;
  bool isFavorite = false;

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
  RotatingIconState createState() => RotatingIconState();
}

class RotatingIconState extends State<RotatingIcon>
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

void main() async {
  // Aseguramos que Flutter esté completamente inicializado
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Inicializar Firebase
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
  
  // Estado de autenticación con Firebase
  bool _isLoggedIn = false;
  String? _userEmail;
  String? _userDisplayName;
  String? _userPhotoURL;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '1053599538056-s4ask7gc47rsmt414vnrge6fkffmpe5i.apps.googleusercontent.com',
  );

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
    
    // Escuchar cambios de autenticación de Firebase de forma segura
    try {
      _auth.authStateChanges().listen((User? user) {
        if (mounted) {
          setState(() {
            _isLoggedIn = user != null;
            _userEmail = user?.email;
            _userDisplayName = user?.displayName;
            _userPhotoURL = user?.photoURL;
          });
          
          debugPrint('Usuario autenticado: ${user?.email}');
          debugPrint('Nombre: ${user?.displayName}');
          debugPrint('Foto: ${user?.photoURL}');
          
          if (user != null) {
            // Cargar favoritos cuando el usuario se autentica
            _loadFavoritesFromFirestore();
          }
        }
      });
      debugPrint("✅ Listener de Firebase Auth configurado");
    } catch (e) {
      debugPrint("❌ Error al configurar Firebase Auth: $e");
    }
    
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
              onNavigationRequest: (NavigationRequest request) {
                final String url = request.url.toLowerCase();

                final List<String> socialMediaDomains = [
                  'facebook.com',
                  'instagram.com',
                  'twitter.com',
                  'x.com', // Por si acaso usan el nuevo dominio de Twitter
                  'youtube.com',
                  'linkedin.com',
                  'tiktok.com',
                  // Añade aquí cualquier otra red social relevante
                ];

                if (request.url.toLowerCase().endsWith('.pdf')) {
                  debugPrint('PDF link interceptado: ${request.url}');
                  _launchURL(request.url); // Abrir externamente
                  return NavigationDecision
                      .prevent; // Prevenir navegación en WebView
                }

                // Comprobar si es un enlace de red social
                for (var domain in socialMediaDomains) {
                  if (url.contains(domain)) {
                    debugPrint('Enlace de red social interceptado: $url');
                    _launchURL(url); // Abrir externamente
                    _hideWebView();
                    return NavigationDecision
                        .prevent; // Prevenir navegación en WebView
                  }
                }

                return NavigationDecision
                    .navigate; // Permitir navegación para el resto
              },
            ),
          );
  }

  // Método para cerrar sesión con Firebase
  Future<void> _logout() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      // El estado se actualizará automáticamente por el listener en initState
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');
    }
  }

  // Método para autenticación con Google
  Future<UserCredential?> _signInWithGoogle() async {
    try {
      debugPrint('🔵 Iniciando autenticación con Google...');
      
      // Iniciar el flujo de autenticación con Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // El usuario canceló el proceso
        debugPrint('🟡 Usuario canceló la autenticación con Google');
        return null;
      }

      debugPrint('🔵 Usuario de Google obtenido: ${googleUser.email}');

      // Obtener los detalles de autenticación de Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      debugPrint('🔵 Tokens obtenidos de Google');

      // Crear credenciales de Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint('🔵 Credenciales de Firebase creadas');

      // Autenticarse con Firebase usando las credenciales de Google
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      debugPrint('✅ Autenticación con Firebase exitosa: ${userCredential.user?.email}');
      
      // Crear documento de usuario en Firestore si es la primera vez
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        debugPrint('🔵 Creando nuevo documento de usuario en Firestore');
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': userCredential.user!.email,
          'displayName': userCredential.user!.displayName,
          'photoURL': userCredential.user!.photoURL,
          'provider': 'google',
          'createdAt': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ Documento de usuario creado en Firestore');
      }

      return userCredential;
    } catch (e) {
      debugPrint('❌ Error en autenticación con Google: $e');
      debugPrint('❌ Tipo de error: ${e.runtimeType}');
      
      // Si es un PlatformException, mostrar más detalles
      if (e is PlatformException) {
        debugPrint('❌ Código de error: ${e.code}');
        debugPrint('❌ Mensaje: ${e.message}');
        debugPrint('❌ Detalles: ${e.details}');
      }
      
      rethrow;
    }
  }

  // Cargar favoritos desde Firestore
  Future<void> _loadFavoritesFromFirestore() async {
    if (!_isLoggedIn || _auth.currentUser == null) return;

    try {
      final userDoc = _firestore.collection('users').doc(_auth.currentUser!.uid);
      final favoritesSnapshot = await userDoc.collection('favorites').get();
      
      final favoriteNames = favoritesSnapshot.docs.map((doc) => doc.data()['raceName'] as String).toList();
      
      // Sincronizar con la lista actual de carreras
      for (var race in _allRaces) {
        race.isFavorite = favoriteNames.contains(race.name);
      }
      
      setState(() {
        // Actualizar la UI
      });
      
      debugPrint("Favoritos cargados desde Firestore: $favoriteNames");
    } catch (e) {
      debugPrint("Error al cargar favoritos desde Firestore: $e");
    }
  }

  Future<void> _toggleFavorite(Race race) async {
    // Actualizar UI inmediatamente
    setState(() {
      race.isFavorite = !race.isFavorite;
    });

    if (_isLoggedIn && _auth.currentUser != null) {
      // Usuario logueado - sincronizar con Firestore
      try {
        final userDoc = _firestore.collection('users').doc(_auth.currentUser!.uid);
        
        if (race.isFavorite) {
          // Añadir a favoritos en Firestore
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
        } else {
          // Eliminar de favoritos en Firestore
          await userDoc.collection('favorites').doc(race.name).delete();
        }
        debugPrint("Favoritos sincronizados con Firestore para usuario: ${_auth.currentUser!.email}");
      } catch (e) {
        debugPrint("Error al sincronizar favoritos con Firestore: $e");
        // Revertir el cambio en la UI si hay error
        setState(() {
          race.isFavorite = !race.isFavorite;
        });
      }
    } else {
      // Usuario no logueado - usar SharedPreferences local
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> favoriteRaces = prefs.getStringList('favoriteRaces') ?? [];

      if (race.isFavorite) {
        if (!favoriteRaces.contains(race.name)) {
          favoriteRaces.add(race.name);
        }
      } else {
        favoriteRaces.remove(race.name);
      }

      await prefs.setStringList('favoriteRaces', favoriteRaces);
      debugPrint("Favoritos guardados localmente: $favoriteRaces");
    }
  }

  // Método para mostrar el diálogo de autenticación con formulario integrado
  Future<void> _showAuthDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final _emailController = TextEditingController();
        final _passwordController = TextEditingController();
        final _formKey = GlobalKey<FormState>();
        bool _isLoginMode = true;
        bool _isLoading = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 400,
                  maxHeight: MediaQuery.of(context).size.height * 0.75, // Ajustar altura al 75% de la pantalla
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header del diálogo
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color.fromRGBO(239, 120, 26, 1),
                              Color.fromRGBO(255, 140, 46, 1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.account_circle,
                              color: Colors.white,
                              size: 50,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _isLoginMode ? 'Iniciar Sesión' : 'Registrarse',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Sincroniza tus favoritos en la nube',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Contenido del formulario
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                // Campo de email
                                TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: const Icon(Icons.email),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Color.fromRGBO(239, 120, 26, 1),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor ingresa tu email';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Por favor ingresa un email válido';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                // Campo de contraseña
                                TextFormField(
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    labelText: 'Contraseña',
                                    prefixIcon: const Icon(Icons.lock),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Color.fromRGBO(239, 120, 26, 1),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  obscureText: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor ingresa tu contraseña';
                                    }
                                    if (value.length < 6) {
                                      return 'La contraseña debe tener al menos 6 caracteres';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                // Botón principal
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : () async {
                                      if (!_formKey.currentState!.validate()) {
                                        return;
                                      }

                                      setDialogState(() {
                                        _isLoading = true;
                                      });

                                      try {
                                        UserCredential userCredential;
                                        
                                        if (_isLoginMode) {
                                          // Iniciar sesión con Firebase Auth
                                          userCredential = await _auth.signInWithEmailAndPassword(
                                            email: _emailController.text.trim(),
                                            password: _passwordController.text.trim(),
                                          );
                                        } else {
                                          // Registrarse con Firebase Auth
                                          userCredential = await _auth.createUserWithEmailAndPassword(
                                            email: _emailController.text.trim(),
                                            password: _passwordController.text.trim(),
                                          );
                                          
                                          // Crear documento de usuario en Firestore
                                          await _firestore.collection('users').doc(userCredential.user!.uid).set({
                                            'email': _emailController.text.trim(),
                                            'createdAt': FieldValue.serverTimestamp(),
                                          });
                                        }

                                        setDialogState(() {
                                          _isLoading = false;
                                        });

                                        Navigator.of(context).pop();

                                        // Cargar favoritos desde Firestore
                                        await _loadFavoritesFromFirestore();

                                        // Mostrar notificación de éxito
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                const Icon(Icons.check_circle, color: Colors.white),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(_isLoginMode 
                                                      ? '¡Bienvenido de vuelta ${_emailController.text.split('@')[0]}! 🎉'
                                                      : '¡Cuenta creada exitosamente ${_emailController.text.split('@')[0]}! 🎉'),
                                                ),
                                              ],
                                            ),
                                            backgroundColor: Colors.green,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            margin: const EdgeInsets.all(16),
                                            duration: const Duration(seconds: 3),
                                          ),
                                        );
                                      } catch (e) {
                                        setDialogState(() {
                                          _isLoading = false;
                                        });
                                        
                                        String errorMessage = 'Error de autenticación';
                                        if (e is FirebaseAuthException) {
                                          switch (e.code) {
                                            case 'user-not-found':
                                              errorMessage = 'No existe una cuenta con este email';
                                              break;
                                            case 'wrong-password':
                                              errorMessage = 'Contraseña incorrecta';
                                              break;
                                            case 'email-already-in-use':
                                              errorMessage = 'Este email ya está registrado';
                                              break;
                                            case 'weak-password':
                                              errorMessage = 'La contraseña es muy débil';
                                              break;
                                            case 'invalid-email':
                                              errorMessage = 'Email inválido';
                                              break;
                                            default:
                                              errorMessage = e.message ?? 'Error desconocido';
                                          }
                                        }
                                        
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                const Icon(Icons.error, color: Colors.white),
                                                const SizedBox(width: 8),
                                                Expanded(child: Text(errorMessage)),
                                              ],
                                            ),
                                            backgroundColor: Colors.red,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            margin: const EdgeInsets.all(16),
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color.fromRGBO(239, 120, 26, 1),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      elevation: 2,
                                    ),
                                    child: _isLoading
                                        ? Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(_isLoginMode ? 'Iniciando...' : 'Registrando...'),
                                            ],
                                          )
                                        : Text(
                                            _isLoginMode ? 'Iniciar Sesión' : 'Registrarse',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Divider con texto
                                Row(
                                  children: [
                                    Expanded(child: Divider(color: Colors.grey[300])),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        'o continúa con',
                                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                      ),
                                    ),
                                    Expanded(child: Divider(color: Colors.grey[300])),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Botón de Google Sign In
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _isLoading ? null : () async {
                                      debugPrint('🔵 Botón Google Sign In presionado');
                                      setDialogState(() {
                                        _isLoading = true;
                                      });

                                      try {
                                        debugPrint('🔵 Iniciando _signInWithGoogle()...');
                                        final userCredential = await _signInWithGoogle();
                                        debugPrint('🔵 _signInWithGoogle() completado. UserCredential: ${userCredential != null ? 'SÍ' : 'NO'}');
                                        
                                        if (userCredential != null) {
                                          debugPrint('✅ Login exitoso! Usuario: ${userCredential.user?.email}');
                                          
                                          setDialogState(() {
                                            _isLoading = false;
                                          });

                                          debugPrint('🔵 Cerrando diálogo...');
                                          Navigator.of(context).pop();

                                          debugPrint('🔵 Cargando favoritos desde Firestore...');
                                          // Cargar favoritos desde Firestore
                                          await _loadFavoritesFromFirestore();

                                          debugPrint('🔵 Mostrando notificación de éxito...');
                                          // Mostrar notificación de éxito
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  const Icon(Icons.check_circle, color: Colors.white),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text('¡Bienvenido ${userCredential.user?.displayName?.split(' ')[0] ?? 'Usuario'}! 🎉'),
                                                  ),
                                                ],
                                              ),
                                              backgroundColor: Colors.green,
                                              behavior: SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              margin: const EdgeInsets.all(16),
                                              duration: const Duration(seconds: 3),
                                            ),
                                          );
                                          debugPrint('✅ Notificación de éxito mostrada');
                                        } else {
                                          debugPrint('⚠️ userCredential es null - usuario canceló');
                                          setDialogState(() {
                                            _isLoading = false;
                                          });
                                        }
                                      } catch (e) {
                                        debugPrint('❌ Error en botón Google Sign In: $e');
                                        setDialogState(() {
                                          _isLoading = false;
                                        });
                                        
                                        String errorMessage = 'Error al iniciar sesión con Google';
                                        
                                        if (e.toString().contains('network_error')) {
                                          errorMessage = 'Error de conexión. Verifica tu internet.';
                                        } else if (e.toString().contains('sign_in_cancelled')) {
                                          errorMessage = 'Inicio de sesión cancelado';
                                        } else if (e.toString().contains('sign_in_failed')) {
                                          if (e.toString().contains('ApiException: 10:')) {
                                            errorMessage = 'Error de configuración. Contacta al desarrollador.';
                                          } else {
                                            errorMessage = 'Error al conectar con Google. Inténtalo de nuevo.';
                                          }
                                        }
                                        
                                        debugPrint('❌ Detalle completo del error: $e');
                                        
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                const Icon(Icons.error, color: Colors.white),
                                                const SizedBox(width: 8),
                                                Expanded(child: Text(errorMessage)),
                                              ],
                                            ),
                                            backgroundColor: Colors.red,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            margin: const EdgeInsets.all(16),
                                          ),
                                        );
                                      }
                                    },
                                    icon: Image.network(
                                      'https://developers.google.com/identity/images/g-logo.png',
                                      height: 20,
                                      width: 20,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(Icons.account_circle, size: 20);
                                      },
                                    ),
                                    label: _isLoading
                                        ? Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  color: Colors.grey[600],
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              const Text('Conectando...'),
                                            ],
                                          )
                                        : const Text(
                                            'Continuar con Google',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.grey[700],
                                      side: BorderSide(color: Colors.grey[300]!),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Botón para cambiar entre login y registro
                                TextButton(
                                  onPressed: () {
                                    setDialogState(() {
                                      _isLoginMode = !_isLoginMode;
                                    });
                                  },
                                  child: Text(
                                    _isLoginMode 
                                        ? '¿No tienes cuenta? Regístrate'
                                        : '¿Ya tienes cuenta? Inicia sesión',
                                    style: TextStyle(
                                      color: Color.fromRGBO(239, 120, 26, 1),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Botón de cancelar
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text(
                                    'Cancelar',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
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

  List<double> _getDistances(String textContent) {
    final RegExp regExp = RegExp(r"(\d+)\s*m", caseSensitive: false);
    List<double> distances = [];
    for (final match in regExp.allMatches(textContent.replaceAll('.', ''))) {
      if (match.group(1) != null) {
        distances.add(
          (double.parse(match.group(1)!) / 100.0).truncateToDouble() / 10.0,
        );
      }
    }
    return distances;
  }

  Future<void> _parseHtmlAndExtractRaces(String htmlContent) async {
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
        final linkElement = tds[1].querySelector('a[href]');
        if (linkElement != null) {
          final href = linkElement.attributes['href'];
          if (href != null &&
              !href.startsWith('#') &&
              (href.startsWith('http://') || href.startsWith('https://'))) {
            registrationLink = href;
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
        final distances = _getDistances(tds[5].text);
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

    // Cargar favoritos (Firebase o local según el estado de autenticación)
    await _loadFavorites(parsedRaces);

    if (mounted) {
      setState(() {
        _allRaces = parsedRaces;
        _applyFilters(basicFilterChanged: true);
      });
    }
  }

  // Método unificado para cargar favoritos
  Future<void> _loadFavorites(List<Race> races) async {
    if (_isLoggedIn && _auth.currentUser != null) {
      // Cargar desde Firestore
      try {
        final userDoc = _firestore.collection('users').doc(_auth.currentUser!.uid);
        final favoritesSnapshot = await userDoc.collection('favorites').get();
        
        final favoriteNames = favoritesSnapshot.docs.map((doc) => doc.data()['raceName'] as String).toList();
        
        for (var race in races) {
          race.isFavorite = favoriteNames.contains(race.name);
        }
        
        debugPrint("Favoritos cargados desde Firestore: $favoriteNames");
      } catch (e) {
        debugPrint("Error al cargar favoritos desde Firestore: $e");
        // Fallback a SharedPreferences si hay error
        await _loadFavoritesFromLocal(races);
      }
    } else {
      // Cargar desde SharedPreferences
      await _loadFavoritesFromLocal(races);
    }
  }

  // Cargar favoritos desde SharedPreferences
  Future<void> _loadFavoritesFromLocal(List<Race> races) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> favoriteRaceNames = prefs.getStringList('favoriteRaces') ?? [];

    for (var race in races) {
      race.isFavorite = favoriteRaceNames.contains(race.name);
    }
    
    debugPrint("Favoritos cargados localmente: $favoriteRaceNames");
  }

  void _applyFilters({bool basicFilterChanged = false}) {
    List<Race> basicFilteredRaces =
        _allRaces.where((race) {
          final matchMonth =
              _selectedMonth == null || race.month == _selectedMonth;
          final matchZone = _selectedZone == null || race.zone == _selectedZone;
          final matchType = _selectedType == null || race.type == _selectedType;
          final matchTerrain =
              _selectedTerrain == null || race.terrain == _selectedTerrain;
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

  void _handleShareRace(Race race) {
    if (race.registrationLink?.isNotEmpty ?? false) {
      Share.share(
        '¡Échale un vistazo a esta carrera: ${race.name}!${race.registrationLink}',
      );
    } else {
      Share.share('¡Échale un vistazo a esta carrera: ${race.name}!');
    }
  }

  void _hideWebView() {
    _controller.loadRequest(Uri.parse('about:blank'));
    setState(() {
      _isWebViewVisible = false;
    });
  }

  void _resetAllFilters() {
    setState(() {
      // Restablece todos los filtros de tipo Dropdown a null
      _selectedMonth = null;
      _selectedZone = null;
      _selectedType = null;
      _selectedTerrain = null;

      // Llama a _applyFilters con 'basicFilterChanged: true'.
      // Esto es CLAVE, porque recalculará el rango de distancias
      // y lo reiniciará automáticamente.
      _applyFilters(basicFilterChanged: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<String> availableMonths = [...meseses];
    final List<String> availableZones = [...zonascolores.keys];
    final List<String> availableTypes = [
      ..._allRaces.map((r) => r.type).whereType<String>().toSet().toList()
        ..sort(),
    ];
    final List<String> availableTerrains = [
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
          child: PopScope<Object?>(
            canPop: !_isWebViewVisible,
            onPopInvokedWithResult: (bool didPop, Object? result) async {
              if (!didPop && _isWebViewVisible) {
                // Si se intenta pop y la vista web está visible
                _hideWebView();
              }
              // Si didPop es true, el pop ya ha ocurrido: no hacemos nada
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
                systemOverlayStyle: SystemUiOverlayStyle(
                  statusBarColor: Color.fromRGBO(
                    239,
                    120,
                    26,
                    1,
                  ), // Color deseado
                  statusBarIconBrightness:
                      Brightness
                          .light, // Los iconos de la barra de estado se verán blancos
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
                    // Header personalizado del drawer
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.fromRGBO(239, 120, 26, 1),
                            Color.fromRGBO(255, 140, 50, 1),
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Foto de perfil y datos del usuario
                              Row(
                                children: [
                                  // Avatar del usuario
                                  _userPhotoURL != null && _userPhotoURL!.isNotEmpty
                                      ? CircleAvatar(
                                          radius: 30,
                                          backgroundImage: NetworkImage(_userPhotoURL!),
                                          backgroundColor: Colors.white.withOpacity(0.3),
                                          onBackgroundImageError: (exception, stackTrace) {
                                            debugPrint('Error cargando imagen de perfil: $exception');
                                          },
                                        )
                                      : CircleAvatar(
                                          radius: 30,
                                          backgroundColor: Colors.white.withOpacity(0.3),
                                          child: Icon(
                                            Icons.account_circle, 
                                            color: Colors.white, 
                                            size: 40
                                          ),
                                        ),
                                  const SizedBox(width: 16),
                                  // Información del usuario
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (_isLoggedIn) ...[
                                          Text(
                                            _userDisplayName?.isNotEmpty == true 
                                                ? _userDisplayName! 
                                                : 'Usuario',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _userEmail ?? '',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.9),
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ] else ...[
                                          const Text(
                                            'Correbirras',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Agenda de carreras',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.9),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              // Botón de acción (Gratis/Iniciar Sesión/Cerrar Sesión)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoggedIn ? () async {
                                    Navigator.pop(context); // Cerrar drawer
                                    
                                    // Mostrar notificación de que se está cerrando sesión
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Text('Cerrando sesión...'),
                                          ],
                                        ),
                                        backgroundColor: Colors.orange,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        margin: const EdgeInsets.all(16),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                    
                                    await _logout();
                                    
                                    // Mostrar notificación de éxito
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).removeCurrentSnackBar();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(Icons.check_circle, color: Colors.white),
                                              const SizedBox(width: 8),
                                              const Text('Sesión cerrada exitosamente'),
                                            ],
                                          ),
                                          backgroundColor: Colors.green,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          margin: const EdgeInsets.all(16),
                                        ),
                                      );
                                    }
                                  } : () {
                                    Navigator.pop(context); // Cerrar drawer primero
                                    _showAuthDialog(); // Mostrar el diálogo de autenticación
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Color.fromRGBO(239, 120, 26, 1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _isLoggedIn ? Icons.logout : Icons.login,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _isLoggedIn ? 'Cerrar Sesión' : 'Iniciar Sesión',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.only(top: 20),
                        children: <Widget>[
                          // ListTile para "Favoritos"
                          ListTile(
                            leading: Icon(Icons.favorite, color: Color.fromRGBO(239, 120, 26, 1)), 
                            title: const Text('Favoritos'),
                            onTap: () {
                              Navigator.pop(context); // Cierra el drawer
                              // Navega a la pantalla de favoritos, pasando la lista _allRaces
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => // PASAR LAS FUNCIONES AQUÍ
                                          FavoritesScreen(
                                        allRaces: _allRaces,
                                        toggleFavorite:
                                            _toggleFavorite, // Pasar la función
                                        showRaceInWebView:
                                            _showRaceInWebView, // Pasar la función
                                        handleShareRace: _handleShareRace,
                                      ),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: Icon(Icons.web, color: Color.fromRGBO(239, 120, 26, 1)),
                            title: const Text('Ver la pagina correbirras.com'),
                            onTap: () {
                              Navigator.pop(context); // Close the drawer
                              _launchURL(
                                'https://www.correbirras.com',
                              ); // Reusing the webview function
                            },
                          ),
                          ListTile(
                            leading: Icon(Icons.email, color: Color.fromRGBO(239, 120, 26, 1)),
                            title: const Text('Contacta con el club'),
                            onTap: () {
                              Navigator.pop(context); // Close the drawer
                              _sendEmail(
                                'correbirras@gmail.com',
                              ); // New function to send email
                            },
                          ),
                          ListTile(
                            leading: Icon(Icons.star, color: Color.fromRGBO(239, 120, 26, 1)),
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
                            icon: SvgPicture.asset(
                              'assets/images/facebook.svg',
                              width: 40,
                              height: 40,
                              colorFilter: ColorFilter.mode(
                                Color.fromRGBO(239, 120, 26, 1),
                                BlendMode.srcIn,
                              ),
                            ),
                            onPressed: () {
                              _launchURL(
                                'https://www.facebook.com/correbirras',
                              );
                            },
                          ),
                          SizedBox(width: 20),
                          IconButton(
                            icon: SvgPicture.asset(
                              'assets/images/instagram.svg',
                              width: 30,
                              height: 30,
                              colorFilter: ColorFilter.mode(
                                Color.fromRGBO(239, 120, 26, 1),
                                BlendMode.srcIn,
                              ),
                            ), // Assuming you have instagram_icon.png in assets/images
                            onPressed: () {
                              _launchURL(
                                'https://www.instagram.com/correbirras',
                              );
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
                            'Desarrollado por ',
                            style: TextStyle(
                              color: Color.fromARGB(195, 34, 34, 34),
                              // Añado un subrayado para que parezca un enlace
                            ),
                          ),
                          TextButton(
                            onPressed: () => _launchURL('https://t.me/dagodev'),
                            // Añado un padding mínimo para que no se vea desalineado
                            style: TextButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                101,
                                239,
                                118,
                                26,
                              ), // Fondo sutil
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  15.0,
                                ), // Esquinas redondeadas
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Dagodev',
                                  style: TextStyle(
                                    color: Color.fromARGB(195, 34, 34, 34),
                                    // Añado un subrayado para que parezca un enlace
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.telegram,
                                  color: Color.fromARGB(195, 34, 34, 34),
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              endDrawer:
                  _isWebViewVisible
                      ? null
                      : Drawer(
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
                                  child: Text(
                                    'Filtros',
                                    style: drawersTextStyle,
                                  ),
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
                                      _selectedMonth =
                                          v; // 'v' será null si no se elige nada, o un mes si se elige.
                                    });
                                    _applyFilters(basicFilterChanged: true);
                                  },
                                  items:
                                      availableMonths.map((m) {
                                        // Asumimos que availableMonths es ahora ['enero', 'febrero', ...]
                                        // Ya no contiene "all".
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
                                    _applyFilters(basicFilterChanged: true);
                                  },
                                  items:
                                      availableZones.map((z) {
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
                                    _applyFilters(basicFilterChanged: true);
                                  },
                                  items:
                                      availableTypes.map((t) {
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
                                    _applyFilters(basicFilterChanged: true);
                                  },
                                  items:
                                      availableTerrains.map((t) {
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
                                      activeColor: Color.fromRGBO(
                                        239,
                                        120,
                                        26,
                                        1,
                                      ),
                                      inactiveColor: Colors.grey,
                                      onChanged:
                                          (values) => setState(
                                            () =>
                                                _selectedDistanceRange = values,
                                          ),
                                      onChangeEnd:
                                          (values) => _applyFilters(
                                            basicFilterChanged: false,
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
                                                return Color.fromRGBO(
                                                  239,
                                                  120,
                                                  26,
                                                  1,
                                                );
                                              }),
                                          foregroundColor:
                                              WidgetStateProperty.resolveWith<
                                                Color?
                                              >((Set<WidgetState> states) {
                                                return Colors.white;
                                              }),
                                          shape: WidgetStateProperty.all<
                                            RoundedRectangleBorder
                                          >(
                                            RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(18.0),
                                            ),
                                          ),
                                          padding: WidgetStateProperty.all<
                                            EdgeInsets
                                          >(
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
                                          textStyle: WidgetStateProperty.all<
                                            TextStyle
                                          >(
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
                                                  return Colors.white
                                                      .withValues(alpha: 0.08);
                                                }
                                                if (states.contains(
                                                      WidgetState.focused,
                                                    ) ||
                                                    states.contains(
                                                      WidgetState.pressed,
                                                    )) {
                                                  return Colors.white
                                                      .withValues(alpha: 0.24);
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

                          Widget buildRaceItemWidget(
                            Race race,
                            bool isGridView,
                          ) {
                            // --- Variables de configuración ---
                            final double cardHorizontalMargin =
                                isGridView ? 8.0 : 16.0;
                            final double cardPadding = isGridView ? 12.0 : 16.0;
                            final int titleMaxLines = isGridView ? 2 : 1;
                            final double titleFontSize =
                                isGridView ? 15.0 : 16.0;
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
                                if (race.registrationLink?.isNotEmpty ??
                                    false) {
                                  _showRaceInWebView(race.registrationLink!);
                                } else {
                                  debugPrint(
                                    'No se encontró enlace para ${race.name}',
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
                                  // AHORA: Usamos una Row principal para separar el contenido y el icono
                                  child: IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // 1. Contenido principal que se expande
                                        Expanded(
                                          flex: 8,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Nombre de la carrera
                                              Text(
                                                race.name,
                                                maxLines: titleMaxLines,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: titleFontSize,
                                                ),
                                              ),

                                              // Separador
                                              const SizedBox(height: 8.0),

                                              // Fecha
                                              if (race.date?.isNotEmpty ??
                                                  false)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 4.0,
                                                      ),
                                                  child: Text.rich(
                                                    TextSpan(
                                                      text: 'Fecha: ',
                                                      style: labelStyle,
                                                      children: <TextSpan>[
                                                        TextSpan(
                                                          text:
                                                              '${race.date} - ${race.month}', // Asumiendo que race.month ya viene formateado
                                                          style:
                                                              resultRaceStyle,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),

                                              // Zona
                                              if (race.zone?.isNotEmpty ??
                                                  false)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
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
                                                          style:
                                                              resultRaceStyle,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),

                                              // Tipo
                                              if (race.type?.isNotEmpty ??
                                                  false)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 4.0,
                                                      ),
                                                  child: Text.rich(
                                                    TextSpan(
                                                      text: 'Tipo: ',
                                                      style: labelStyle,
                                                      children: <TextSpan>[
                                                        TextSpan(
                                                          text: race.type,
                                                          style:
                                                              resultRaceStyle,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),

                                              // Terreno
                                              if (race.terrain?.isNotEmpty ??
                                                  false)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 4.0,
                                                      ),
                                                  child: Text.rich(
                                                    TextSpan(
                                                      text: 'Terreno: ',
                                                      style: labelStyle,
                                                      children: <TextSpan>[
                                                        TextSpan(
                                                          text: race.terrain,
                                                          style:
                                                              resultRaceStyle,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),

                                              // Distancias
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 4.0,
                                                ),
                                                child: Text.rich(
                                                  TextSpan(
                                                    text: 'Distancia: ',
                                                    style: labelStyle,
                                                    children: <TextSpan>[
                                                      TextSpan(
                                                        text:
                                                            race
                                                                    .distances
                                                                    .isNotEmpty
                                                                ? (() {
                                                                  race.distances
                                                                      .sort();
                                                                  return '${race.distances.join('K, ').replaceAll('.0', '')}K';
                                                                })()
                                                                : 'No disponible',

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
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            children: [
                                              // 2. Icono de favorito que se ajusta a su tamaño
                                              IconButton(
                                                icon: Icon(
                                                  race.isFavorite
                                                      ? Icons.favorite
                                                      : Icons.favorite_border,
                                                  color:
                                                      race.isFavorite
                                                          ? Color.fromRGBO(
                                                            239,
                                                            120,
                                                            26,
                                                            1,
                                                          )
                                                          : Colors.grey,
                                                  size: 30,
                                                ),
                                                onPressed: () {
                                                  _toggleFavorite(race);
                                                },
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.share,
                                                  color: Colors.grey,
                                                  size: 30,
                                                ),
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
                            double cardHeight = 215.0;

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
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
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
      ), // Cierre de UpgradeAlert
    );
  }
}
