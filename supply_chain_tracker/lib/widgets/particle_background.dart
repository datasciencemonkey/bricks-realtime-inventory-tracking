import 'dart:math' as math;
import 'package:flutter/material.dart';

class ParticleBackground extends StatefulWidget {
  final int particleCount;
  final Color particleColor;
  final double particleSize;
  final bool connectParticles;
  final double connectionDistance;

  const ParticleBackground({
    super.key,
    this.particleCount = 100,
    required this.particleColor,
    this.particleSize = 2.0,
    this.connectParticles = true,
    this.connectionDistance = 100.0,
  });

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _controller.addListener(() {
      setState(() {
        _updateParticles();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_particles.isEmpty) {
      _initializeParticles();
    }
  }

  void _initializeParticles() {
    final size = MediaQuery.of(context).size;
    _particles = List.generate(
      widget.particleCount,
      (index) => Particle(
        x: math.Random().nextDouble() * size.width,
        y: math.Random().nextDouble() * size.height,
        vx: (math.Random().nextDouble() - 0.5) * 0.5,
        vy: (math.Random().nextDouble() - 0.5) * 0.5,
      ),
    );
  }

  void _updateParticles() {
    final size = MediaQuery.of(context).size;
    for (var particle in _particles) {
      particle.x += particle.vx;
      particle.y += particle.vy;

      // Bounce off edges
      if (particle.x < 0 || particle.x > size.width) {
        particle.vx *= -1;
      }
      if (particle.y < 0 || particle.y > size.height) {
        particle.vy *= -1;
      }

      // Keep within bounds
      particle.x = particle.x.clamp(0.0, size.width);
      particle.y = particle.y.clamp(0.0, size.height);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_particles.isEmpty) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      painter: ParticlePainter(
        particles: _particles,
        particleColor: widget.particleColor,
        particleSize: widget.particleSize,
        connectParticles: widget.connectParticles,
        connectionDistance: widget.connectionDistance,
      ),
      child: Container(),
    );
  }
}

class Particle {
  double x;
  double y;
  double vx;
  double vy;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Color particleColor;
  final double particleSize;
  final bool connectParticles;
  final double connectionDistance;

  ParticlePainter({
    required this.particles,
    required this.particleColor,
    required this.particleSize,
    required this.connectParticles,
    required this.connectionDistance,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = particleColor
      ..strokeWidth = particleSize;

    // Draw particles
    for (var particle in particles) {
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particleSize / 2,
        paint,
      );
    }

    // Draw connections between nearby particles
    if (connectParticles) {
      final linePaint = Paint()
        ..color = particleColor.withValues(alpha: 0.2)
        ..strokeWidth = 1.0;

      for (int i = 0; i < particles.length; i++) {
        for (int j = i + 1; j < particles.length; j++) {
          final dx = particles[i].x - particles[j].x;
          final dy = particles[i].y - particles[j].y;
          final distance = math.sqrt(dx * dx + dy * dy);

          if (distance < connectionDistance) {
            final opacity = 1.0 - (distance / connectionDistance);
            linePaint.color = particleColor.withValues(alpha: opacity * 0.3);
            canvas.drawLine(
              Offset(particles[i].x, particles[i].y),
              Offset(particles[j].x, particles[j].y),
              linePaint,
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

