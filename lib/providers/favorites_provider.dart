import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:correbirras/models/race.dart';
import 'dart:convert';

class FavoritesProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  List<String> _favoriteNames = [];
  bool _isLoadingFavorites = false;

  List<String> get favoriteNames => _favoriteNames;
  bool get isLoadingFavorites => _isLoadingFavorites;
  bool get isLoggedIn => _auth.currentUser != null;
  User? get currentUser => _auth.currentUser;
  String? get userEmail => _auth.currentUser?.email;
  String? get userDisplayName => _auth.currentUser?.displayName;
  String? get userPhotoURL => _auth.currentUser?.photoURL;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  String _favoriteDocId(String raceName) {
    try {
      return base64Url.encode(utf8.encode(raceName));
    } catch (_) {
      return raceName.replaceAll('/', '_');
    }
  }

  Future<void> loadFavorites() async {
    if (_auth.currentUser != null) {
      await _loadFromFirestore();
    } else {
      await _loadFromLocal();
    }
  }

  Future<void> _loadFromFirestore() async {
    if (_auth.currentUser == null) return;
    _isLoadingFavorites = true;
    notifyListeners();

    try {
      final userDoc = _firestore.collection('users').doc(_auth.currentUser!.uid);
      final snapshot = await userDoc.collection('favorites').get();
      _favoriteNames = snapshot.docs.map((doc) => doc.data()['raceName'] as String).toList();
      debugPrint("Favoritos cargados desde Firestore: $_favoriteNames");
    } catch (e) {
      debugPrint("Error al cargar favoritos desde Firestore: $e");
    } finally {
      _isLoadingFavorites = false;
      notifyListeners();
    }
  }

  Future<void> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _favoriteNames = prefs.getStringList('favoriteRaces') ?? [];
      debugPrint("Favoritos cargados localmente: $_favoriteNames");
    } catch (e) {
      debugPrint("Error al cargar favoritos locales: $e");
    }
    notifyListeners();
  }

  Future<bool> toggleFavorite(Race race) async {
    final isCurrentlyFavorite = _favoriteNames.contains(race.name);

    if (isCurrentlyFavorite) {
      _favoriteNames.remove(race.name);
    } else {
      _favoriteNames.add(race.name);
    }
    notifyListeners();

    if (_auth.currentUser != null) {
      try {
        final userDoc = _firestore.collection('users').doc(_auth.currentUser!.uid);
        final docId = _favoriteDocId(race.name);

        if (!isCurrentlyFavorite) {
          await userDoc.collection('favorites').doc(docId).set({
            'raceName': race.name,
            'month': race.month,
            'zone': race.zone,
            'type': race.type,
            'distances': race.distances,
            'registrationLink': race.registrationLink,
            'date': race.date,
            'hora': race.hora,
            'precio': race.precio,
            'senderista': race.senderista,
            'addedAt': FieldValue.serverTimestamp(),
          });
        } else {
          await userDoc.collection('favorites').doc(docId).delete();
        }
        return true;
      } catch (e) {
        debugPrint("Error al sincronizar favoritos con Firestore: $e");
        if (isCurrentlyFavorite) {
          _favoriteNames.add(race.name);
        } else {
          _favoriteNames.remove(race.name);
        }
        notifyListeners();
        return false;
      }
    } else {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('favoriteRaces', _favoriteNames);
        return true;
      } catch (e) {
        debugPrint("Error al guardar favoritos locales: $e");
        if (isCurrentlyFavorite) {
          _favoriteNames.add(race.name);
        } else {
          _favoriteNames.remove(race.name);
        }
        notifyListeners();
        return false;
      }
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      _favoriteNames = [];
      notifyListeners();
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      debugPrint('🔵 Iniciando autenticación con Google...');

      final bool isAvailable = await _googleSignIn.isSignedIn();
      debugPrint('🔵 Google Sign-In disponible: $isAvailable');

      if (isAvailable) {
        await _googleSignIn.signOut();
        debugPrint('🔵 Sesión previa de Google cerrada');
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('🟡 Usuario canceló la autenticación con Google');
        return null;
      }

      debugPrint('🔵 Usuario de Google obtenido: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        debugPrint('❌ Error: Tokens de Google no obtenidos');
        throw Exception('No se pudieron obtener los tokens de autenticación de Google');
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      debugPrint('✅ Autenticación con Firebase exitosa: ${userCredential.user?.email}');

      if (userCredential.additionalUserInfo?.isNewUser == true) {
        debugPrint('🔵 Creando nuevo documento de usuario en Firestore');
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': userCredential.user!.email,
          'displayName': userCredential.user!.displayName,
          'photoURL': userCredential.user!.photoURL,
          'provider': 'google',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Error de Firebase Auth: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'account-exists-with-different-credential':
          throw Exception('Ya existe una cuenta con este email usando un método diferente');
        case 'invalid-credential':
          throw Exception('Las credenciales son inválidas o han expirado');
        case 'operation-not-allowed':
          throw Exception('Google Sign-In no está habilitado en este proyecto');
        case 'user-disabled':
          throw Exception('Esta cuenta ha sido deshabilitada');
        default:
          throw Exception('Error de autenticación: ${e.message}');
      }
    } catch (e) {
      debugPrint('❌ Error en autenticación con Google: $e');
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No existe una cuenta asociada a este email');
        case 'invalid-email':
          throw Exception('El email proporcionado no es válido');
        case 'too-many-requests':
          throw Exception('Demasiados intentos. Intenta de nuevo más tarde');
        default:
          throw Exception('Error al enviar email: ${e.message}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> mergeLocalToCloud() async {
    if (_auth.currentUser == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final localFavorites = prefs.getStringList('favoriteRaces') ?? [];
      if (localFavorites.isEmpty) return;

      final userDoc = _firestore.collection('users').doc(_auth.currentUser!.uid);

      final snapshot = await userDoc.collection('favorites').get();
      final cloudNames = snapshot.docs.map((doc) => doc.data()['raceName'] as String).toList();

      for (final name in localFavorites) {
        if (!cloudNames.contains(name)) {
          final docId = _favoriteDocId(name);
          await userDoc.collection('favorites').doc(docId).set({
            'raceName': name,
            'addedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      _favoriteNames = {...cloudNames, ...localFavorites}.toList();
      notifyListeners();
      await prefs.remove('favoriteRaces');
      debugPrint("✅ Favoritos locales sincronizados con la nube");
    } catch (e) {
      debugPrint("Error al mergear favoritos: $e");
    }
  }
}