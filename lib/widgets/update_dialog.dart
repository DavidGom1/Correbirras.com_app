import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_update_service.dart';
import '../core/theme/app_theme.dart';

/// Diálogo de actualización de la app
/// Muestra información sobre la actualización disponible y permite al usuario
/// actualizar o (si es opcional) continuar usando la app
class UpdateDialog extends StatelessWidget {
  final UpdateCheckResult updateResult;
  final VoidCallback? onDismiss;

  const UpdateDialog({
    super.key,
    required this.updateResult,
    this.onDismiss,
  });

  bool get isForceUpdate => updateResult.status == UpdateStatus.forceUpdate;

  String get title =>
      isForceUpdate ? 'Actualización requerida' : '¡Nueva versión disponible!';

  String get message =>
      isForceUpdate
          ? updateResult.config?.forceUpdateMessage ??
              'Esta versión ya no es compatible. Por favor, actualiza para continuar.'
          : updateResult.config?.updateMessage ??
              '¡Hay una nueva versión disponible con mejoras!';

  String get currentVersionText =>
      'Versión actual: ${updateResult.currentVersion ?? "desconocida"}';

  String get latestVersionText =>
      'Nueva versión: ${updateResult.config?.latestVersion ?? "desconocida"}';

  Future<void> _openPlayStore(BuildContext context) async {
    final String url =
        updateResult.config?.playStoreUrl ??
        'https://play.google.com/store/apps/details?id=com.correbirras.agenda';

    // Intentar abrir con el esquema market:// primero (abre directamente Play Store)
    final Uri marketUri = Uri.parse(
      url.replaceFirst('https://play.google.com/store/apps/', 'market://'),
    );

    try {
      if (await canLaunchUrl(marketUri)) {
        await launchUrl(marketUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (e) {
      debugPrint('Error al abrir market://: $e');
    }

    // Fallback a la URL web
    final Uri webUri = Uri.parse(url);
    try {
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir Google Play Store'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error al abrir URL web: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !isForceUpdate,
      child: AlertDialog(
        backgroundColor: isDark ? darkSurface : lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              isForceUpdate ? Icons.warning_amber_rounded : Icons.system_update,
              color: isForceUpdate ? Colors.orange : correbirrasOrange,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.phone_android,
                        size: 16,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currentVersionText,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.new_releases,
                        size: 16,
                        color: correbirrasOrange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        latestVersionText,
                        style: TextStyle(
                          fontSize: 13,
                          color: correbirrasOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isForceUpdate) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Colors.red[400],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No puedes continuar sin actualizar',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Botón principal: Actualizar
              ElevatedButton.icon(
                onPressed: () => _openPlayStore(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: correbirrasOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.download, size: 20),
                label: const Text(
                  'Actualizar ahora',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Botón secundario: Más tarde (solo si no es obligatorio)
              if (!isForceUpdate) ...[
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onDismiss?.call();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: isDark ? Colors.white54 : Colors.black54,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Más tarde',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Método estático para mostrar el diálogo
  static Future<void> show({
    required BuildContext context,
    required UpdateCheckResult updateResult,
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: updateResult.status != UpdateStatus.forceUpdate,
      builder: (context) => UpdateDialog(
        updateResult: updateResult,
        onDismiss: onDismiss,
      ),
    );
  }
}
