import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Modelo para la configuración de versiones desde Firebase
class AppVersionConfig {
  final String minVersion;
  final String latestVersion;
  final String updateMessage;
  final String forceUpdateMessage;
  final String playStoreUrl;

  AppVersionConfig({
    required this.minVersion,
    required this.latestVersion,
    required this.updateMessage,
    required this.forceUpdateMessage,
    required this.playStoreUrl,
  });

  factory AppVersionConfig.fromFirestore(Map<String, dynamic> data) {
    return AppVersionConfig(
      minVersion: data['min_version'] ?? '1.0.0',
      latestVersion: data['latest_version'] ?? '1.0.0',
      updateMessage: data['update_message'] ?? '¡Nueva versión disponible!',
      forceUpdateMessage: data['force_update_message'] ??
          'Esta versión ya no es compatible. Por favor, actualiza para continuar.',
      playStoreUrl: data['play_store_url'] ??
          'https://play.google.com/store/apps/details?id=com.correbirras.agenda',
    );
  }
}

/// Resultado de la comprobación de actualización
enum UpdateStatus {
  upToDate, // No necesita actualización
  optionalUpdate, // Actualización disponible pero opcional
  forceUpdate, // Actualización obligatoria
  error, // Error al comprobar
}

class UpdateCheckResult {
  final UpdateStatus status;
  final AppVersionConfig? config;
  final String? currentVersion;
  final String? errorMessage;

  UpdateCheckResult({
    required this.status,
    this.config,
    this.currentVersion,
    this.errorMessage,
  });
}

/// Servicio para gestionar las comprobaciones de actualización de la app
class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._internal();
  factory AppUpdateService() => _instance;
  AppUpdateService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtiene la configuración de versiones desde Firestore
  Future<AppVersionConfig?> _getVersionConfig() async {
    try {
      final docSnapshot =
          await _firestore.collection('app_config').doc('version').get();

      if (!docSnapshot.exists || docSnapshot.data() == null) {
        debugPrint('⚠️ Documento de versión no encontrado en Firestore');
        return null;
      }

      return AppVersionConfig.fromFirestore(docSnapshot.data()!);
    } catch (e) {
      debugPrint('❌ Error al obtener configuración de versión: $e');
      return null;
    }
  }

  /// Obtiene la versión actual de la app instalada
  Future<String> _getCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      debugPrint('❌ Error al obtener versión de la app: $e');
      return '0.0.0';
    }
  }

  /// Compara dos versiones semánticas
  /// Retorna: -1 si v1 < v2, 0 si v1 == v2, 1 si v1 > v2
  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    // Asegurar que ambas listas tengan al menos 3 elementos
    while (parts1.length < 3) {
      parts1.add(0);
    }
    while (parts2.length < 3) {
      parts2.add(0);
    }

    for (int i = 0; i < 3; i++) {
      if (parts1[i] < parts2[i]) return -1;
      if (parts1[i] > parts2[i]) return 1;
    }
    return 0;
  }

  /// Comprueba si hay una actualización disponible
  Future<UpdateCheckResult> checkForUpdate() async {
    try {
      final config = await _getVersionConfig();
      if (config == null) {
        return UpdateCheckResult(
          status: UpdateStatus.error,
          errorMessage: 'No se pudo obtener la configuración de versión',
        );
      }

      final currentVersion = await _getCurrentVersion();
      debugPrint('📱 Versión actual: $currentVersion');
      debugPrint('📦 Versión mínima requerida: ${config.minVersion}');
      debugPrint('🆕 Última versión disponible: ${config.latestVersion}');

      // Comprobar si la versión actual es menor que la mínima requerida
      if (_compareVersions(currentVersion, config.minVersion) < 0) {
        debugPrint('🚨 Actualización OBLIGATORIA requerida');
        return UpdateCheckResult(
          status: UpdateStatus.forceUpdate,
          config: config,
          currentVersion: currentVersion,
        );
      }

      // Comprobar si hay una versión más reciente disponible
      if (_compareVersions(currentVersion, config.latestVersion) < 0) {
        debugPrint('💡 Actualización OPCIONAL disponible');
        return UpdateCheckResult(
          status: UpdateStatus.optionalUpdate,
          config: config,
          currentVersion: currentVersion,
        );
      }

      debugPrint('✅ La app está actualizada');
      return UpdateCheckResult(
        status: UpdateStatus.upToDate,
        config: config,
        currentVersion: currentVersion,
      );
    } catch (e) {
      debugPrint('❌ Error al comprobar actualización: $e');
      return UpdateCheckResult(
        status: UpdateStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}
