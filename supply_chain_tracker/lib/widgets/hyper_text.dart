import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class HyperText extends StatefulWidget {
  const HyperText({
    super.key,
    required this.text,
    this.duration = const Duration(milliseconds: 800),
    this.style,
    this.animationTrigger = false,
    this.animateOnLoad = true,
  });

  final bool animateOnLoad;
  final bool animationTrigger;
  final Duration duration;
  final TextStyle? style;
  final String text;

  @override
  State<HyperText> createState() => _HyperTextState();
}

class _HyperTextState extends State<HyperText> {
  int animationCount = 0;
  late List<String> displayText;
  bool isFirstRender = true;
  double iterations = 0;

  final Random _random = Random();
  Timer? _timer;

  static const String _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*()';

  @override
  void didUpdateWidget(HyperText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text ||
        (widget.animationTrigger != oldWidget.animationTrigger &&
            widget.animationTrigger)) {
      _startAnimation();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    displayText = widget.text.split('');
    if (widget.animateOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startAnimation();
      });
    }
  }

  void _startAnimation() {
    iterations = 0;
    _timer?.cancel();
    animationCount++;
    final currentAnimationCount = animationCount;

    final textLength = widget.text.length;
    if (textLength == 0) return;

    _timer = Timer.periodic(
      Duration(milliseconds: widget.duration.inMilliseconds ~/ (textLength * 10)),
      (timer) {
        if (currentAnimationCount != animationCount) {
          timer.cancel();
          return;
        }

        if (!mounted) {
          timer.cancel();
          return;
        }

        setState(() {
          displayText = List.generate(
            textLength,
            (index) {
              if (iterations >= index) {
                return widget.text[index];
              }
              return _chars[_random.nextInt(_chars.length)];
            },
          );

          iterations += 0.1;

          if (iterations >= textLength) {
            timer.cancel();
            displayText = widget.text.split('');
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: displayText.asMap().entries.map((entry) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 50),
          child: Text(
            entry.value,
            key: ValueKey('${entry.key}_${entry.value}_$iterations'),
            style: widget.style,
          ),
        );
      }).toList(),
    );
  }
}
