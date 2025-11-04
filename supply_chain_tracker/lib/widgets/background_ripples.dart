import 'package:flutter/material.dart';

class BackgroundRipples extends StatefulWidget {
  final Color color;
  final int numberOfRipples;
  final double minRadius;
  final double maxRadius;
  final Duration duration;
  final Widget child;

  const BackgroundRipples({
    super.key,
    required this.color,
    this.numberOfRipples = 3,
    this.minRadius = 20,
    this.maxRadius = 100,
    this.duration = const Duration(seconds: 3),
    required this.child,
  });

  @override
  State<BackgroundRipples> createState() => _BackgroundRipplesState();
}

class _BackgroundRipplesState extends State<BackgroundRipples>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.numberOfRipples,
      (index) => AnimationController(
        vsync: this,
        duration: widget.duration,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: widget.minRadius,
        end: widget.maxRadius,
      ).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOut,
        ),
      );
    }).toList();

    // Start animations with staggered delays
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 1000), () {
        if (mounted) {
          _controllers[i].repeat();
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fixed size container to prevent layout shifts
    final fixedSize = widget.maxRadius * 2;
    
    return SizedBox(
      width: fixedSize,
      height: fixedSize,
      child: ClipRect(
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.hardEdge,
        children: [
          // Ripple effects
          ...List.generate(widget.numberOfRipples, (index) {
            return Positioned.fill(
              child: AnimatedBuilder(
                animation: _animations[index],
                builder: (context, child) {
                  final radius = _animations[index].value;
                  final opacity = 1.0 - (radius - widget.minRadius) / (widget.maxRadius - widget.minRadius);
                  
                  return Center(
                    child: Container(
                      width: radius * 2,
                      height: radius * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.color.withValues(alpha: opacity * 0.4),
                          width: 2,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
          // Child widget (truck icon)
          Center(child: widget.child),
        ],
        ),
      ),
    );
  }
}
