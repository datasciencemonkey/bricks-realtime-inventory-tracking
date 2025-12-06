import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../theme/colors.dart';

class GeminiSplash extends StatefulWidget {
  final VoidCallback? onAnimationComplete;
  final Duration duration;
  final Color? primaryColor;
  final Color? secondaryColor;

  const GeminiSplash({
    super.key,
    this.onAnimationComplete,
    this.duration = const Duration(milliseconds: 3000),
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  State<GeminiSplash> createState() => GeminiSplashState();
}

class GeminiSplashState extends State<GeminiSplash>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _waveController;

  // Star animations
  late Animation<double> _starScale;
  late Animation<double> _starRotation;
  late Animation<double> _starGlow;
  late Animation<double> _circleScale;
  late Animation<double> _circleOpacity;
  late Animation<double> _starPositionY;

  // Explosion animations
  late Animation<double> _explosionProgress;
  late Animation<double> _waveOpacity;

  // Particles
  late List<_Particle> _particles;
  bool _callbackCalled = false;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _initializeParticles();
    _setupAnimations();

    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_callbackCalled) {
        _callbackCalled = true;
        widget.onAnimationComplete?.call();
      }
    });

    // Start the animation
    _mainController.forward();
  }

  void _initializeParticles() {
    _particles = List.generate(16, (index) {
      final angle = (index * 2 * math.pi) / 16;
      return _Particle(
        angle: angle,
        speed: 0.8 + (index % 3) * 0.2,
        size: 3.0 + (index % 4) * 1.5,
      );
    });
  }

  void _setupAnimations() {
    // Phase 1: Circle appears and star grows (0-30%)
    _circleScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.15, curve: Curves.easeOut),
      ),
    );

    _circleOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.15, 0.35, curve: Curves.easeIn),
      ),
    );

    _starScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.1, 0.4, curve: Curves.elasticOut),
      ),
    );

    _starRotation = Tween<double>(begin: 0.0, end: math.pi * 2).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
      ),
    );

    _starGlow = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.6), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 1.5), weight: 40),
    ]).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.1, 0.8),
      ),
    );

    // Phase 2: Star moves down (30-70%)
    _starPositionY = Tween<double>(begin: 0.0, end: 200.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 0.75, curve: Curves.easeInQuart),
      ),
    );

    // Phase 3: Explosion (70-100%)
    _explosionProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    _waveOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.65, 0.85, curve: Curves.easeIn),
      ),
    );
  }

  void replay() {
    _callbackCalled = false;
    _mainController.reset();
    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = widget.primaryColor ?? AppColors.lava500;
    final secondaryColor = widget.secondaryColor ?? AppColors.lava600;

    return AnimatedBuilder(
      animation: Listenable.merge([_mainController, _waveController]),
      builder: (context, child) {
        return Container(
          width: size.width,
          height: size.height,
          color: isDark ? AppColors.navy900 : AppColors.oatLight,
          child: Stack(
            children: [
              // Waves at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: _waveOpacity.value,
                  child: CustomPaint(
                    size: Size(size.width, 200),
                    painter: _WavesPainter(
                      animation: _waveController.value,
                      colors: [
                        primaryColor.withValues(alpha: 0.6),
                        secondaryColor.withValues(alpha: 0.5),
                        primaryColor.withValues(alpha: 0.4),
                      ],
                    ),
                  ),
                ),
              ),

              // Star and effects
              Positioned(
                left: size.width / 2 - 75,
                top: size.height / 2 - 75 + _starPositionY.value,
                child: SizedBox(
                  width: 150,
                  height: 150,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glow effect
                      if (_starGlow.value > 0)
                        Container(
                          width: 100 * _starScale.value * (1 + _starGlow.value * 0.5),
                          height: 100 * _starScale.value * (1 + _starGlow.value * 0.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.3 * _starGlow.value),
                                blurRadius: 40 * _starGlow.value,
                                spreadRadius: 20 * _starGlow.value,
                              ),
                            ],
                          ),
                        ),

                      // Initial circle
                      if (_circleOpacity.value > 0)
                        Container(
                          width: 30 * _circleScale.value,
                          height: 30 * _circleScale.value,
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: _circleOpacity.value),
                            shape: BoxShape.circle,
                          ),
                        ),

                      // Star
                      if (_explosionProgress.value < 1)
                        Transform.rotate(
                          angle: _starRotation.value,
                          child: Transform.scale(
                            scale: _starScale.value * (1 - _explosionProgress.value * 0.5),
                            child: CustomPaint(
                              size: const Size(60, 60),
                              painter: _StarPainter(
                                color: primaryColor,
                                glowIntensity: _starGlow.value,
                              ),
                            ),
                          ),
                        ),

                      // Explosion particles
                      if (_explosionProgress.value > 0)
                        ...List.generate(_particles.length, (index) {
                          final particle = _particles[index];
                          final distance = 80 * _explosionProgress.value * particle.speed;
                          final opacity = (1 - _explosionProgress.value).clamp(0.0, 1.0);

                          return Transform.translate(
                            offset: Offset(
                              math.cos(particle.angle) * distance,
                              math.sin(particle.angle) * distance,
                            ),
                            child: Container(
                              width: particle.size * (1 - _explosionProgress.value * 0.5),
                              height: particle.size * (1 - _explosionProgress.value * 0.5),
                              decoration: BoxDecoration(
                                color: (index % 2 == 0 ? primaryColor : secondaryColor)
                                    .withValues(alpha: opacity),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: opacity * 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),

              // Center text that appears during explosion
              if (_explosionProgress.value > 0.3)
                Positioned(
                  left: 0,
                  right: 0,
                  top: size.height / 2 + 100,
                  child: Opacity(
                    opacity: ((_explosionProgress.value - 0.3) / 0.7).clamp(0.0, 1.0),
                    child: Text(
                      'Supply Chain Planning Agent',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.navy800,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Particle {
  final double angle;
  final double speed;
  final double size;

  _Particle({
    required this.angle,
    required this.speed,
    required this.size,
  });
}

class _StarPainter extends CustomPainter {
  final Color color;
  final double glowIntensity;

  _StarPainter({
    required this.color,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw glow
    if (glowIntensity > 0) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.3 * glowIntensity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15 * glowIntensity);

      final glowPath = _createStarPath(center, size.width / 2 * 1.2);
      canvas.drawPath(glowPath, glowPaint);
    }

    // Draw star
    final starPath = _createStarPath(center, size.width / 2 * 0.9);
    canvas.drawPath(starPath, paint);
  }

  Path _createStarPath(Offset center, double radius) {
    final path = Path();
    final innerRadius = radius * 0.4;

    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi / 2) - math.pi / 4;
      final outerX = center.dx + math.cos(angle) * radius;
      final outerY = center.dy + math.sin(angle) * radius;

      final innerAngle = angle + math.pi / 4;
      final innerX = center.dx + math.cos(innerAngle) * innerRadius;
      final innerY = center.dy + math.sin(innerAngle) * innerRadius;

      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }
      path.lineTo(innerX, innerY);
    }
    path.close();

    return path;
  }

  @override
  bool shouldRepaint(_StarPainter oldDelegate) =>
      oldDelegate.glowIntensity != glowIntensity;
}

class _WavesPainter extends CustomPainter {
  final double animation;
  final List<Color> colors;

  _WavesPainter({
    required this.animation,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < colors.length; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

      final path = Path();
      final waveOffset = i * 0.3;
      final amplitude = 25.0 - i * 5;
      final frequency = 1.5 + i * 0.3;

      path.moveTo(0, size.height);

      for (double x = 0; x <= size.width; x += 2) {
        final y = size.height * 0.4 +
            math.sin((x / size.width * frequency * 2 * math.pi) +
                    (animation * 2 * math.pi) +
                    waveOffset) *
                amplitude;
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_WavesPainter oldDelegate) => true;
}
