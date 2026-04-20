import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

class PlayStoreUpdateService {
  bool _promptedThisSession = false;

  /// Cambiar a `true` para probar los diálogos en modo debug
  static const bool _debugSimulateUpdate = false;

  Future<void> maybePrompt(BuildContext context) async {
    if (!Platform.isAndroid || kIsWeb || _promptedThisSession) {
      return;
    }

    // Modo demo para ver la UI en debug
    if (kDebugMode && _debugSimulateUpdate) {
      _promptedThisSession = true;
      _showStoreDialog(context);
      return;
    }

    try {
      final info = await InAppUpdate.checkForUpdate();
      if (!context.mounted) {
        return;
      }

      final availability = info.updateAvailability;
      if (availability != UpdateAvailability.updateAvailable) {
        return;
      }

      _promptedThisSession = true;

      if (info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
        return;
      }

      if (info.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate();
        if (!context.mounted) {
          return;
        }
        _showRestartBanner(context);
        return;
      }

      _showStoreDialog(context);
    } catch (error, stack) {
      debugPrint('[PlayStoreUpdate] $error');
      debugPrint(stack.toString());
    }
  }

  void _showRestartBanner(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Hay una versión nueva disponible'),
        action: SnackBarAction(
          label: 'INSTALAR',
          onPressed: () {
            InAppUpdate.completeFlexibleUpdate();
          },
        ),
      ),
    );
  }

  void _showStoreDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Actualización disponible'),
        content: const Text(
          'Existe una versión más reciente en Google Play. Actualiza para continuar usando la app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Luego'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              InAppUpdate.performImmediateUpdate();
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }
}
