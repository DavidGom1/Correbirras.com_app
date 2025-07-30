import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../utils/notification_utils.dart';
import '../core/theme/app_theme.dart';
import 'package:sign_button/sign_button.dart';

class AuthDialog extends StatefulWidget {
  const AuthDialog({super.key});

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  bool _isLoginMode = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: AppTheme.getDialogBackground(context),
          borderRadius: BorderRadius.circular(20),
          boxShadow: ThemeUtils.getAdaptiveCardShadow(context),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _buildForm(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: AppTheme.getDrawerHeaderColor(context),
      child: Column(
        children: [
          Icon(
            Icons.account_circle,
            color: AppTheme.getPrimaryIconColor(
              context,
            ), // Siempre blanco sobre fondo naranja
            size: 50,
          ),
          const SizedBox(height: 10),
          Text(
            _isLoginMode ? 'Iniciar Sesión' : 'Registrarse',
            style: TextStyle(
              color: AppTheme.getPrimaryTextColor(
                context,
              ), // Siempre blanco sobre fondo naranja
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Sincroniza tus favoritos en la nube',
            style: TextStyle(
              color: AppTheme.getSecondaryTextColor(
                context,
              ), // Blanco semi-transparente sobre fondo naranja
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Campo de email
          TextFormField(
            style: AppTheme.getInputTextStyle(context),
            controller: _emailController,
            decoration: ThemeUtils.getAdaptiveInputDecoration(context, 'Email')
                .copyWith(
                  labelStyle: AppTheme.getLabelTextStyle(
                    context,
                  ), // 👈 AQUÍ AGREGAS TU MÉTODO
                  prefixIcon: Icon(
                    Icons.email,
                    color: AppTheme.getSecondaryIconColor(context),
                  ),
                ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu email';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Por favor ingresa un email válido';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Campo de contraseña
          TextFormField(
            style: AppTheme.getInputTextStyle(context),
            controller: _passwordController,
            decoration:
                ThemeUtils.getAdaptiveInputDecoration(
                  context,
                  'Contraseña',
                ).copyWith(
                  labelStyle: AppTheme.getLabelTextStyle(
                    context,
                  ), // 👈 AQUÍ TAMBIÉN
                  prefixIcon: Icon(
                    Icons.lock,
                    color: AppTheme.getSecondaryIconColor(context),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: AppTheme.getSecondaryIconColor(context),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
            obscureText: _obscurePassword,

            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu contraseña';
              }
              if (!_isLoginMode && value.length < 6) {
                return 'La contraseña debe tener al menos 6 caracteres';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // Botón principal
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleEmailAuth,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.getDrawerHeaderColor(context),
                foregroundColor: AppTheme.getPrimaryTextColor(
                  context,
                ), // Siempre blanco sobre fondo naranja
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? AppTheme.getSpinKitPumpingHeart(context)
                  : Text(
                      _isLoginMode ? 'Iniciar Sesión' : 'Registrarse',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // Divider con "O"
          Row(
            children: [
              Expanded(
                child: Divider(color: AppTheme.getDrawerTextDevColor(context)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'O',
                  style: TextStyle(
                    color: AppTheme.getDrawerTextDevColor(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Divider(color: AppTheme.getSecondaryIconColor(context)),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Botón Google
          SizedBox(
            width: double.infinity,
            height: 50,
            child: SignInButton.mini(
              buttonType: ButtonType.google,
              btnColor: AppTheme.getDrawerHeaderColor(context),
              onPressed: _isLoading ? null : _handleGoogleSignIn,
              buttonSize: ButtonSize.small,
            ),
          ),
          const SizedBox(height: 24),

          // Toggle entre login y registro
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    setState(() {
                      _isLoginMode = !_isLoginMode;
                    });
                  },
            child: Text(
              _isLoginMode
                  ? '¿No tienes cuenta? Regístrate'
                  : '¿Ya tienes cuenta? Inicia sesión',
              style: TextStyle(
                color: AppTheme.getDrawerTextDevColor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Enlace para restablecer contraseña (solo en modo login)
          if (_isLoginMode)
            TextButton(
              onPressed: _isLoading ? null : _showPasswordResetDialog,
              child: Text(
                '¿Olvidaste tu contraseña?',
                style: TextStyle(
                  color: AppTheme.getDrawerTextDevColor(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential;
      final FirebaseAuth auth = FirebaseAuth.instance;
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      if (_isLoginMode) {
        // Iniciar sesión
        userCredential = await auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // Registrarse
        userCredential = await auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Crear documento de usuario en Firestore
        await firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': _emailController.text.trim(),
          'provider': 'email',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        Navigator.of(context).pop();
        NotificationUtils.showSuccess(
          context,
          _isLoginMode
              ? 'Bienvenido de nuevo'
              : 'Tu cuenta ha sido creada exitosamente',
          title: _isLoginMode ? 'Sesión Iniciada' : 'Cuenta Creada',
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationUtils.showError(
          context,
          'Verifica tus credenciales e intenta nuevamente',
          title: 'Error de Autenticación',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await _authService.signInWithGoogle();

      if (userCredential != null && mounted) {
        Navigator.of(context).pop();
        NotificationUtils.showSuccess(
          context,
          'Has iniciado sesión con tu cuenta de Google',
          title: '¡Bienvenido!',
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationUtils.showError(
          context,
          'No se pudo conectar con Google. Intenta nuevamente.',
          title: 'Error con Google',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Método para mostrar el diálogo de restablecimiento de contraseña
  Future<void> _showPasswordResetDialog() async {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: AppTheme.getDialogBackground(context),
              borderRadius: BorderRadius.circular(20),
              boxShadow: ThemeUtils.getAdaptiveCardShadow(context),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Título
                      Text(
                        'Restablecer contraseña',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getDrawerTextDevColor(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // Descripción
                      Text(
                        'Ingresa tu email y te enviaremos un enlace para restablecer tu contraseña.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.getDrawerTextDevColor(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Campo de email
                      TextFormField(
                        controller: emailController,
                        style: AppTheme.getInputTextStyle(context),
                        decoration:
                            ThemeUtils.getAdaptiveInputDecoration(
                              context,
                              'Email',
                            ).copyWith(
                              labelStyle: AppTheme.getLabelTextStyle(context),
                              prefixIcon: Icon(
                                Icons.email,
                                color: AppTheme.getSecondaryIconColor(context),
                              ),
                            ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu email';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value)) {
                            return 'Por favor ingresa un email válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Botones
                      Row(
                        children: [
                          // Botón cancelar
                          Expanded(
                            child: TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              child: Text(
                                'Cancelar',
                                style: TextStyle(
                                  color: AppTheme.getSecondaryTextColor(
                                    context,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Botón enviar
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (formKey.currentState!.validate()) {
                                  // Guardar contextos antes de la operación async
                                  final navigator = Navigator.of(dialogContext);
                                  final parentContext = context;
                                  final currentDialogContext = dialogContext;

                                  try {
                                    await _authService.sendPasswordResetEmail(
                                      emailController.text.trim(),
                                    );

                                    if (mounted) {
                                      navigator.pop();
                                      NotificationUtils.showSuccess(
                                        mounted ? parentContext : context,
                                        'Se ha enviado un enlace de restablecimiento a tu email.\nRevisa tu bandeja de entrada y tu bandeja de SPAM.',
                                        title: 'Email enviado',
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      NotificationUtils.showError(
                                        mounted
                                            ? currentDialogContext
                                            : context,
                                        e.toString().replaceFirst(
                                          'Exception: ',
                                          '',
                                        ),
                                        title: 'Error',
                                      );
                                    }
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.getDrawerHeaderColor(
                                  context,
                                ),
                                foregroundColor: AppTheme.getPrimaryTextColor(
                                  context,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Enviar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
