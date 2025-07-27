import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Referencia a la colección de favoritos del usuario actual
  static CollectionReference? get _userFavoritesCollection {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites');
  }

  /// Migra favoritos de SharedPreferences a Firestore (solo la primera vez)
  static Future<void> migrateLocalFavoritesToFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Verificar si ya se migró antes
      final prefs = await SharedPreferences.getInstance();
      final alreadyMigrated = prefs.getBool('favorites_migrated_${user.uid}') ?? false;
      
      if (alreadyMigrated) {
        print("🔄 Favoritos ya migrados para este usuario");
        return;
      }

      // Obtener favoritos locales
      final localFavorites = prefs.getStringList('favoriteRaces') ?? [];
      
      if (localFavorites.isEmpty) {
        print("📭 No hay favoritos locales para migrar");
        await prefs.setBool('favorites_migrated_${user.uid}', true);
        return;
      }

      print("🚀 Migrando ${localFavorites.length} favoritos a Firestore...");

      // Migrar cada favorito a Firestore
      final batch = _firestore.batch();
      for (final raceName in localFavorites) {
        final docRef = _userFavoritesCollection!.doc();
        batch.set(docRef, {
          'raceName': raceName,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      
      // Marcar como migrado
      await prefs.setBool('favorites_migrated_${user.uid}', true);
      
      print("✅ Favoritos migrados exitosamente a Firestore");
    } catch (e) {
      print("❌ Error migrando favoritos: $e");
    }
  }

  /// Obtiene la lista de nombres de carreras favoritas del usuario
  static Future<List<String>> getFavoriteRaceNames() async {
    try {
      final collection = _userFavoritesCollection;
      if (collection == null) {
        print("⚠️ No hay usuario logueado");
        return [];
      }

      final querySnapshot = await collection.get();
      final favoriteNames = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .map((data) => data['raceName'] as String)
          .toList();

      print("📋 Obtenidos ${favoriteNames.length} favoritos de Firestore");
      return favoriteNames;
    } catch (e) {
      print("❌ Error obteniendo favoritos: $e");
      return [];
    }
  }

  /// Agrega una carrera a favoritos
  static Future<bool> addFavorite(String raceName) async {
    try {
      final collection = _userFavoritesCollection;
      if (collection == null) {
        print("⚠️ No hay usuario logueado");
        return false;
      }

      // Verificar si ya existe
      final existingQuery = await collection
          .where('raceName', isEqualTo: raceName)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        print("ℹ️ La carrera '$raceName' ya está en favoritos");
        return true;
      }

      // Agregar nuevo favorito
      await collection.add({
        'raceName': raceName,
        'addedAt': FieldValue.serverTimestamp(),
      });

      print("⭐ Agregado '$raceName' a favoritos");
      return true;
    } catch (e) {
      print("❌ Error agregando favorito: $e");
      return false;
    }
  }

  /// Elimina una carrera de favoritos
  static Future<bool> removeFavorite(String raceName) async {
    try {
      final collection = _userFavoritesCollection;
      if (collection == null) {
        print("⚠️ No hay usuario logueado");
        return false;
      }

      // Buscar el documento con ese nombre de carrera
      final querySnapshot = await collection
          .where('raceName', isEqualTo: raceName)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print("ℹ️ La carrera '$raceName' no está en favoritos");
        return true;
      }

      // Eliminar todos los documentos que coincidan (debería ser solo uno)
      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      print("🗑️ Eliminado '$raceName' de favoritos");
      return true;
    } catch (e) {
      print("❌ Error eliminando favorito: $e");
      return false;
    }
  }

  /// Stream para escuchar cambios en tiempo real de los favoritos
  static Stream<List<String>>? getFavoritesStream() {
    final collection = _userFavoritesCollection;
    if (collection == null) return null;

    return collection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .map((data) => data['raceName'] as String)
          .toList();
    });
  }

  /// Limpia favoritos locales después de migrar (opcional)
  static Future<void> clearLocalFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('favoriteRaces');
      print("🧹 Favoritos locales limpiados");
    } catch (e) {
      print("❌ Error limpiando favoritos locales: $e");
    }
  }
}
