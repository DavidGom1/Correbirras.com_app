import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../services/util_service.dart';
import '../utils/notification_utils.dart';
import '../core/theme/theme_provider.dart';
import '../core/theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  final bool isLoggedIn;
  final String? userDisplayName;
  final String? userEmail;
  final String? userPhotoURL;
  final VoidCallback onAuthTap;
  final VoidCallback onLogout;
  final VoidCallback onFavoritesTap;

  const AppDrawer({
    super.key,
    required this.isLoggedIn,
    required this.userDisplayName,
    required this.userEmail,
    required this.userPhotoURL,
    required this.onAuthTap,
    required this.onLogout,
    required this.onFavoritesTap,
  });

  @override
  Widget build(BuildContext context) {
    final UtilService utilService = UtilService();

    final TextStyle drawersTextStyle = TextStyle(
      color: AppTheme.getPrimaryTextColor(context),
      fontSize: 25,
      fontWeight: FontWeight.bold,
    );

    return Drawer(
      child: Column(
        children: <Widget>[
          // Header del drawer con información de usuario - Clickeable para autenticación
          InkWell(
            onTap: isLoggedIn
                ? null
                : onAuthTap, // Solo clickeable si no está logueado
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.getDrawerHeaderColor(context),
              ),
              child: Column(
                children: [
                  // Título "Menú"
                  Text('Menú', style: drawersTextStyle),
                  SizedBox(height: 16),

                  // Información del usuario - Area clickeable para autenticación
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        // Avatar del usuario
                        CircleAvatar(
                          radius: 25,
                          backgroundImage:
                              userPhotoURL != null && userPhotoURL!.isNotEmpty
                              ? NetworkImage(userPhotoURL!)
                              : null,
                          backgroundColor: AppTheme.getPrimaryTextColor(
                            context,
                          ).withValues(alpha: 0.2),
                          child: userPhotoURL == null || userPhotoURL!.isEmpty
                              ? Icon(
                                  Icons.person,
                                  size: 30,
                                  color: AppTheme.getPrimaryTextColor(context),
                                )
                              : null,
                        ),
                        SizedBox(width: 12),

                        // Información de texto del usuario
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isLoggedIn) ...[
                                Text(
                                  userDisplayName ?? 'Usuario',
                                  style: TextStyle(
                                    color: AppTheme.getPrimaryTextColor(
                                      context,
                                    ),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (userEmail != null && userEmail!.isNotEmpty)
                                  Text(
                                    userEmail!,
                                    style: TextStyle(
                                      color: AppTheme.getSecondaryTextColor(
                                        context,
                                      ),
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ] else ...[
                                Text(
                                  'Toca para iniciar sesión',
                                  style: TextStyle(
                                    color: AppTheme.getPrimaryTextColor(
                                      context,
                                    ),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Accede con Google',
                                  style: TextStyle(
                                    color: AppTheme.getSecondaryTextColor(
                                      context,
                                    ),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Botón de cerrar sesión cuando está autenticado, o icono de login cuando no
                        if (isLoggedIn)
                          IconButton(
                            onPressed: () => _showLogoutConfirmation(context),
                            icon: Icon(
                              Icons.logout,
                              color: AppTheme.getPrimaryTextColor(context),
                              size: 20,
                            ),
                            tooltip: 'Cerrar Sesión',
                          )
                        else
                          Icon(
                            Icons.login,
                            color: AppTheme.getSecondaryTextColor(context),
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(top: 20),
              children: <Widget>[
                // ListTile para "Favoritos"
                ListTile(
                  leading: Icon(Icons.favorite), // Icono de favorito
                  title: const Text('Favoritos'),
                  onTap: onFavoritesTap,
                ),

                // ListTile para cambiar tema
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return ListTile(
                      leading: Icon(
                        themeProvider.themeMode == ThemeMode.dark
                            ? Icons.light_mode
                            : Icons.dark_mode,
                      ),
                      title: Text(
                        themeProvider.themeMode == ThemeMode.dark
                            ? 'Modo Claro'
                            : 'Modo Oscuro',
                      ),
                      onTap: () {
                        themeProvider.toggleTheme();
                      },
                    );
                  },
                ),

                // Línea divisoria moderna
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: AppTheme.getDrawerDividerGradient(
                              context,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                ListTile(
                  leading: Icon(Icons.web),
                  title: const Text('Ver la pagina correbirras.com'),
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    utilService.launchURL('https://www.correbirras.com');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.email),
                  title: const Text('Contacta con el club'),
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    utilService.sendEmail('correbirras@gmail.com');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.star),
                  title: const Text('Calificar en Google Play'),
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    utilService.rateApp();
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
                      AppTheme.getDrawerSocialIconColor(context),
                      BlendMode.srcIn,
                    ),
                  ),
                  onPressed: () {
                    utilService.launchURL(
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
                      AppTheme.getDrawerSocialIconColor(context),
                      BlendMode.srcIn,
                    ),
                  ),
                  onPressed: () {
                    utilService.launchURL(
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
                    color: AppTheme.getDrawerTextDevColor(context),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      utilService.launchURL('https://t.me/dagodev'),
                  style: TextButton.styleFrom(
                    backgroundColor: AppTheme.getDrawerButtonBackground(
                      context,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
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
                          color: AppTheme.getDrawerTextDevColor(context),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.telegram,
                        color: AppTheme.getDrawerTextDevColor(context),
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
    );
  }

  // Método para mostrar confirmación antes de cerrar sesión
  Future<void> _showLogoutConfirmation(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.getDialogBackground(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(
                Icons.logout,
                color: AppTheme.getPrimaryTextColor(context),
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Cerrar Sesión',
                style: TextStyle(
                  color: AppTheme.getPrimaryTextColor(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            '¿Estás seguro de que quieres cerrar sesión?\n\nTus favoritos se guardarán automáticamente.',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.getPrimaryTextColor(context),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: AppTheme.getSecondaryTextColor(context),
                  fontSize: 16,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.getDrawerButtonBackground(context),
                foregroundColor: AppTheme.getPrimaryTextColor(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Cerrar Sesión',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar diálogo
                Navigator.of(context).pop(); // Cerrar drawer

                try {
                  onLogout(); // Ejecutar el logout

                  // Mostrar notificación de éxito usando las utilidades
                  NotificationUtils.showSuccess(
                    context,
                    'Tu sesión se ha cerrado correctamente',
                    title: 'Sesión Cerrada',
                  );
                } catch (e) {
                  // Mostrar error usando las utilidades
                  NotificationUtils.showError(
                    context,
                    'No se pudo cerrar la sesión: ${e.toString()}',
                    title: 'Error',
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
