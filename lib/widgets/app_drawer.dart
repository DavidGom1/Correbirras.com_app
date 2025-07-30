import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../services/util_service.dart';
import '../utils/notification_utils.dart';
import '../core/theme/theme_provider.dart';
import '../core/theme/app_theme.dart';
import '../widgets/auth_dialog.dart'; // Importar el AuthDialog
import '../screens/favorites_screen.dart'; // Importar FavoritesScreen
import '../models/race.dart'; // Importar el modelo Race

class AppDrawer extends StatelessWidget {
  final bool isLoggedIn;
  final String? userDisplayName;
  final String? userEmail;
  final String? userPhotoURL;
  final VoidCallback onAuthTap;
  final VoidCallback onLogout;
  final VoidCallback onFavoritesTap;
  // Parámetros adicionales para favoritos con animación personalizada
  final List<Race>? allRaces;
  final ToggleFavoriteCallback? toggleFavorite;
  final ShowWebViewCallback? showRaceInWebView;
  final HandleShareRace? handleShareRace;

  const AppDrawer({
    super.key,
    required this.isLoggedIn,
    required this.userDisplayName,
    required this.userEmail,
    required this.userPhotoURL,
    required this.onAuthTap,
    required this.onLogout,
    required this.onFavoritesTap,
    // Parámetros opcionales para la navegación personalizada
    this.allRaces,
    this.toggleFavorite,
    this.showRaceInWebView,
    this.handleShareRace,
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
                : () {
                    Navigator.pop(context); // Cerrar el drawer
                    _showAuthDialogWithAnimation(
                      context,
                    ); // Abrir el popup con animación
                  }, // Solo clickeable si no está logueado
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
                  onTap: () {
                    Navigator.pop(context); // Cerrar drawer
                    _navigateToFavoritesWithAnimation(context);
                  },
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
                        themeProvider.isDarkMode ? 'Modo Claro' : 'Modo Oscuro',
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

  // Método para navegar a favoritos con animación personalizada
  void _navigateToFavoritesWithAnimation(BuildContext context) {
    // Si tenemos los parámetros necesarios, usar navegación personalizada
    if (allRaces != null &&
        toggleFavorite != null &&
        showRaceInWebView != null &&
        handleShareRace != null) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return FavoritesScreen(
              allRaces: allRaces!,
              toggleFavorite: toggleFavorite!,
              showRaceInWebView: showRaceInWebView!,
              handleShareRace: handleShareRace!,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Deslizamiento desde abajo
            final slideAnimation =
                Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                );

            return SlideTransition(position: slideAnimation, child: child);
          },
        ),
      );
    } else {
      // Fallback al método original
      onFavoritesTap();
    }
  }

  // Método para mostrar popup de autenticación con animación
  Future<void> _showAuthDialogWithAnimation(BuildContext context) async {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(
        milliseconds: 400,
      ), // Duración de la animación
      pageBuilder:
          (
            BuildContext buildContext,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            return const AuthDialog(); // Usar directamente el AuthDialog
          },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // Animación de deslizamiento desde abajo
        final slideAnimation =
            Tween<Offset>(
              begin: const Offset(0.0, 1.0), // Comienza desde abajo
              end: Offset.zero, // Termina en su posición normal
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic, // Curva suave para entrada natural
              ),
            );

        return SlideTransition(position: slideAnimation, child: child);
      },
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.logout,
                color: AppTheme.getDrawerTextDevColor(context),
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Cerrar Sesión',
                style: TextStyle(
                  color: AppTheme.getDrawerTextDevColor(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            '¿Estás seguro de que quieres cerrar sesión?\n\nTus favoritos se guardarán automáticamente.',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.getDrawerTextDevColor(context),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: AppTheme.getDrawerTextDevColor(context),
                  fontSize: 16,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.getDrawerHeaderColor(context),
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
