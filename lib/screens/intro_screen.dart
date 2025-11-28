import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Pantalla de introducción animada con efectos visuales llamativos.
/// Se adapta automáticamente al tema del sistema (claro/oscuro).
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  @override
  void initState() {
    super.initState();
    // Navegar a home después de las animaciones
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Detectar si el sistema usa tema oscuro
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;

    // Colores adaptativos según el tema
    final colors = _IntroColors.fromBrightness(isDark);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors.backgroundGradient,
          ),
        ),
        child: Stack(
          children: [
            // Partículas flotantes de fondo
            ...List.generate(
              20,
              (index) => _FloatingParticle(index: index, colors: colors),
            ),

            // Contenido principal centrado
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo con animaciones espectaculares
                  _buildAnimatedLogo(colors),

                  const SizedBox(height: 40),

                  // Texto "Correbirras" con shimmer
                  _buildAnimatedTitle(colors),

                  const SizedBox(height: 16),

                  // Subtítulo
                  _buildSubtitle(colors),

                  const SizedBox(height: 50),

                  // Indicador de carga elegante
                  _buildLoadingIndicator(colors),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo(_IntroColors colors) {
    return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.logoBackground,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: colors.accentColor.withValues(alpha: 0.4),
                blurRadius: 30,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/Correbirras_00.png',
            width: 120,
            height: 120,
            fit: BoxFit.contain,
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms, curve: Curves.easeOut)
        .scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1.0, 1.0),
          duration: 800.ms,
          curve: Curves.elasticOut,
        )
        .then(delay: 200.ms)
        .shimmer(
          duration: 1500.ms,
          color: colors.accentColor.withValues(alpha: 0.3),
        );
  }

  Widget _buildAnimatedTitle(_IntroColors colors) {
    return ShaderMask(
          shaderCallback: (bounds) =>
              LinearGradient(colors: colors.titleGradient).createShader(bounds),
          child: const Text(
            'Correbirras',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        )
        .animate(delay: 500.ms)
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.3, end: 0, duration: 600.ms, curve: Curves.easeOut)
        .then(delay: 300.ms)
        .shimmer(duration: 2000.ms, color: colors.shimmerColor);
  }

  Widget _buildSubtitle(_IntroColors colors) {
    return Text(
          'Tu agenda de carreras',
          style: TextStyle(
            fontSize: 16,
            color: colors.subtitleColor,
            letterSpacing: 4,
            fontWeight: FontWeight.w300,
          ),
        )
        .animate(delay: 1000.ms)
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.5, end: 0, duration: 500.ms);
  }

  Widget _buildLoadingIndicator(_IntroColors colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colors.accentColor,
                borderRadius: BorderRadius.circular(6),
              ),
            )
            .animate(
              delay: Duration(milliseconds: 1500 + (index * 200)),
              onPlay: (controller) => controller.repeat(reverse: true),
            )
            .scaleXY(begin: 0.5, end: 1.2, duration: 600.ms)
            .fadeIn(duration: 300.ms);
      }),
    );
  }
}

/// Colores adaptativos para modo claro y oscuro
class _IntroColors {
  final List<Color> backgroundGradient;
  final List<Color> titleGradient;
  final Color accentColor;
  final Color logoBackground;
  final Color subtitleColor;
  final Color shimmerColor;
  final Color particleColor;

  const _IntroColors({
    required this.backgroundGradient,
    required this.titleGradient,
    required this.accentColor,
    required this.logoBackground,
    required this.subtitleColor,
    required this.shimmerColor,
    required this.particleColor,
  });

  /// Tema OSCURO - usa los mismos grises que la app
  factory _IntroColors.dark() {
    return const _IntroColors(
      backgroundGradient: [
        Color(0xFF1A1A1A), // darkBackground de la app
        Color(0xFF2A2A2A), // darkSurface de la app
        Color(0xFF1A1A1A), // Vuelve al fondo
      ],
      titleGradient: [
        Color(0xFFEF781A), // correbirrasOrange
        Color(0xFFFF9A4D), // Naranja más claro
        Color(0xFFFECA57), // Amarillo
        Color(0xFFEF781A), // Volver al naranja
      ],
      accentColor: Color(0xFFEF781A), // correbirrasOrange
      logoBackground: Colors.white,
      subtitleColor: Color(0xAAFFFFFF), // Blanco 70%
      shimmerColor: Color(0x80FFFFFF), // Blanco 50%
      particleColor: Color(0xFFEF781A), // Partículas naranjas
    );
  }

  /// Tema CLARO - colores elegantes sobre fondo claro
  factory _IntroColors.light() {
    return const _IntroColors(
      backgroundGradient: [
        Color(0xFFF9F9F9), // lightBackground de la app
        Color(0xFFFFFFFF), // Blanco
        Color(0xFFF9F9F9), // Vuelve al fondo
      ],
      titleGradient: [
        Color(0xFFEF781A), // correbirrasOrange
        Color(0xFFFF9A4D), // Naranja más claro
        Color(0xFFC86414), // correbirrasOrangeDark
        Color(0xFFEF781A), // Volver al naranja
      ],
      accentColor: Color(0xFFEF781A), // correbirrasOrange
      logoBackground: Colors.white,
      subtitleColor: Color(0xFF495057), // Gris oscuro
      shimmerColor: Color(0x40EF781A), // Naranja 25%
      particleColor: Color(0xFFEF781A), // Partículas naranjas
    );
  }

  /// Selector automático según el brillo del sistema
  factory _IntroColors.fromBrightness(bool isDark) {
    return isDark ? _IntroColors.dark() : _IntroColors.light();
  }
}

/// Partícula flotante para el fondo
class _FloatingParticle extends StatelessWidget {
  final int index;
  final _IntroColors colors;

  const _FloatingParticle({required this.index, required this.colors});

  @override
  Widget build(BuildContext context) {
    final random = Random(index);
    final size = random.nextDouble() * 6 + 2;
    final startX = random.nextDouble() * MediaQuery.of(context).size.width;
    final startY = random.nextDouble() * MediaQuery.of(context).size.height;
    final duration = Duration(milliseconds: 3000 + random.nextInt(4000));
    final delay = Duration(milliseconds: random.nextInt(2000));

    return Positioned(
      left: startX,
      top: startY,
      child:
          Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: colors.particleColor.withValues(
                    alpha: random.nextDouble() * 0.3 + 0.1,
                  ),
                  shape: BoxShape.circle,
                ),
              )
              .animate(delay: delay, onPlay: (c) => c.repeat(reverse: true))
              .fadeIn(duration: duration ~/ 2)
              .then()
              .fadeOut(duration: duration ~/ 2)
              .moveY(
                begin: 0,
                end: -30 - random.nextDouble() * 50,
                duration: duration,
              ),
    );
  }
}
