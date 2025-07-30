import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Getters para el estado actual
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  String? get userEmail => _auth.currentUser?.email;
  String? get userDisplayName => _auth.currentUser?.displayName;
  String? get userPhotoURL => _auth.currentUser?.photoURL;

  // Stream de cambios de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Método para cerrar sesión
  Future<void> logout() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');
      rethrow;
    }
  }

  // Método para enviar email de restablecimiento de contraseña
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      debugPrint('✅ Email de restablecimiento enviado a: $email');
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '❌ Error al enviar email de restablecimiento: ${e.code} - ${e.message}',
      );
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
      debugPrint('❌ Error general al enviar email de restablecimiento: $e');
      rethrow;
    }
  }

  // Método para autenticación con Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      debugPrint('🔵 Iniciando autenticación con Google...');

      // Verificar si Google Sign-In está disponible
      final bool isAvailable = await _googleSignIn.isSignedIn();
      debugPrint('🔵 Google Sign-In disponible: $isAvailable');

      // Cerrar sesión previa si existe para evitar conflictos
      if (isAvailable) {
        await _googleSignIn.signOut();
        debugPrint('🔵 Sesión previa de Google cerrada');
      }

      // Iniciar el flujo de autenticación con Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // El usuario canceló el proceso
        debugPrint('🟡 Usuario canceló la autenticación con Google');
        return null;
      }

      debugPrint('🔵 Usuario de Google obtenido: ${googleUser.email}');

      // Obtener los detalles de autenticación de Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        debugPrint('❌ Error: Tokens de Google no obtenidos');
        throw Exception(
          'No se pudieron obtener los tokens de autenticación de Google',
        );
      }

      debugPrint('🔵 Tokens obtenidos de Google correctamente');

      // Crear credenciales de Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint('🔵 Credenciales de Firebase creadas');

      // Autenticarse con Firebase usando las credenciales de Google
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      debugPrint(
        '✅ Autenticación con Firebase exitosa: ${userCredential.user?.email}',
      );

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
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Error de Firebase Auth: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'account-exists-with-different-credential':
          throw Exception(
            'Ya existe una cuenta con este email usando un método diferente',
          );
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
      debugPrint('❌ Tipo de error: ${e.runtimeType}');

      // Si es un PlatformException, mostrar más detalles
      if (e is PlatformException) {
        debugPrint('❌ Código de error: ${e.code}');
        debugPrint('❌ Mensaje: ${e.message}');
        debugPrint('❌ Detalles: ${e.details}');

        // Manejo específico de errores de Google Sign-In
        switch (e.code) {
          case 'sign_in_failed':
            throw Exception(
              'Error al iniciar sesión con Google. Verifica tu conexión a internet y configuración.',
            );
          case 'network_error':
            throw Exception('Error de red. Verifica tu conexión a internet.');
          case 'sign_in_canceled':
            return null; // Usuario canceló
          default:
            throw Exception(
              'Error de plataforma: ${e.message ?? 'Error desconocido'}',
            );
        }
      }

      rethrow;
    }
  }
}
