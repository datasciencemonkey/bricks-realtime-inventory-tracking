import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

enum AnimationUnit {
  character,
  word,
}

abstract class RevealStrategy {
  Widget buildReveal(
    BuildContext context,
    String text,
    bool isVisible,
    Animation<double> animation,
    AnimationUnit unit,
  );
}

class FlyingCharactersStrategy implements RevealStrategy {
  final double maxOffset;
  final bool randomDirection;
  final bool enableBlur;

  const FlyingCharactersStrategy({
    this.maxOffset = 50,
    this.randomDirection = true,
    this.enableBlur = true,
  });

  @override
  Widget buildReveal(
    BuildContext context,
    String text,
    bool isVisible,
    Animation<double> animation,
    AnimationUnit unit,
  ) {
    if (unit == AnimationUnit.word) {
      return _buildWordReveal(context, text, isVisible, animation);
    } else {
      return _buildCharacterReveal(context, text, isVisible, animation);
    }
  }

  Widget _buildCharacterReveal(
    BuildContext context,
    String text,
    bool isVisible,
    Animation<double> animation,
  ) {
    final random = math.Random(text.hashCode);
    final defaultStyle = DefaultTextStyle.of(context).style;
    final List<Widget> children = [];

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (char == ' ') {
        children.add(const SizedBox(width: 4));
        continue;
      }

      final direction = randomDirection
          ? (random.nextDouble() * 2 * math.pi)
          : (math.pi / 4); // 45 degrees if not random

      final offsetX = maxOffset * math.cos(direction);
      final offsetY = maxOffset * math.sin(direction);

      final delay = (i / text.length) * 0.3;
      final charAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Interval(
            delay.clamp(0.0, 0.9),
            (delay + 0.5).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ),
      );

      children.add(
        AnimatedBuilder(
          animation: charAnimation,
          builder: (context, child) {
            final progress = charAnimation.value;
            final currentOffsetX = offsetX * (1 - progress);
            final currentOffsetY = offsetY * (1 - progress);
            final opacity = progress;
            final blur = enableBlur ? (1 - progress) * 10 : 0.0;

            final charWidget = Text(
              char,
              style: defaultStyle,
            );

            return Transform.translate(
              offset: Offset(currentOffsetX, currentOffsetY),
              child: Opacity(
                opacity: opacity,
                child: blur > 0
                    ? ColorFiltered(
                        colorFilter: ui.ColorFilter.mode(
                          Colors.transparent,
                          BlendMode.srcOver,
                        ),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(
                            sigmaX: blur,
                            sigmaY: blur,
                          ),
                          child: charWidget,
                        ),
                      )
                    : charWidget,
              ),
            );
          },
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      children: children,
    );
  }

  Widget _buildWordReveal(
    BuildContext context,
    String text,
    bool isVisible,
    Animation<double> animation,
  ) {
    final words = text.split(' ');
    final random = math.Random(text.hashCode);
    final List<Widget> children = [];

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      if (word.isEmpty) continue;

      final direction = randomDirection
          ? (random.nextDouble() * 2 * math.pi)
          : (math.pi / 4);

      final offsetX = maxOffset * math.cos(direction);
      final offsetY = maxOffset * math.sin(direction);

      final delay = (i / words.length) * 0.3;
      final wordAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Interval(
            delay.clamp(0.0, 0.9),
            (delay + 0.5).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ),
      );

      children.add(
        AnimatedBuilder(
          animation: wordAnimation,
          builder: (context, child) {
            final progress = wordAnimation.value;
            final currentOffsetX = offsetX * (1 - progress);
            final currentOffsetY = offsetY * (1 - progress);
            final opacity = progress;
            final blur = enableBlur ? (1 - progress) * 10 : 0.0;

            return Transform.translate(
              offset: Offset(currentOffsetX, currentOffsetY),
              child: Opacity(
                opacity: opacity,
                child: blur > 0
                    ? BackdropFilter(
                        filter: ui.ImageFilter.blur(
                          sigmaX: blur,
                          sigmaY: blur,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            word,
                            style: DefaultTextStyle.of(context).style,
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          word,
                          style: DefaultTextStyle.of(context).style,
                        ),
                      ),
              ),
            );
          },
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      children: children,
    );
  }

}

class EnhancedTextRevealEffect extends StatefulWidget {
  final String text;
  final bool trigger;
  final RevealStrategy strategy;
  final AnimationUnit unit;
  final TextStyle? textStyle;
  final TextAlign textAlign;

  const EnhancedTextRevealEffect({
    super.key,
    required this.text,
    required this.trigger,
    required this.strategy,
    this.unit = AnimationUnit.character,
    this.textStyle,
    this.textAlign = TextAlign.center,
  });

  @override
  State<EnhancedTextRevealEffect> createState() =>
      _EnhancedTextRevealEffectState();
}

class _EnhancedTextRevealEffectState extends State<EnhancedTextRevealEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    if (widget.trigger) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(EnhancedTextRevealEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _controller.reset();
      _controller.forward();
    } else if (!widget.trigger && oldWidget.trigger) {
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    final style = widget.textStyle ?? defaultStyle;

    return DefaultTextStyle(
      style: style,
      textAlign: widget.textAlign,
      child: widget.strategy.buildReveal(
        context,
        widget.text,
        widget.trigger,
        _animation,
        widget.unit,
      ),
    );
  }
}

