import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Router-compatible Gooey Page Transition
/// Use this in CustomTransitionPage's transitionsBuilder
class GooeyPageTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  final Color blobColor;
  final bool reverse;

  const GooeyPageTransition({
    super.key,
    required this.animation,
    required this.child,
    this.blobColor = const Color(0xFF6C63FF), // Default Indigo
    this.reverse = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final progress = animation.value;

        return Stack(
          children: [
            // Background Blob Effect
            if (progress > 0 && progress < 1)
              CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _OrganicGooeyPainter(
                  progress: progress,
                  color: blobColor,
                  reverse: reverse,
                ),
              ),

            // Content Transition
            Transform.scale(
              scale: Curves.easeOutBack.transform(progress.clamp(0.0, 1.0)),
              child: Opacity(opacity: progress.clamp(0.0, 1.0), child: child),
            ),
          ],
        );
      },
    );
  }
}

class _OrganicGooeyPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool reverse;

  _OrganicGooeyPainter({
    required this.progress,
    required this.color,
    this.reverse = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Calculate radius to cover screen
    final maxRadius = math.sqrt(
      size.width * size.width + size.height * size.height,
    );
    final currentRadius = maxRadius * (reverse ? (1 - progress) : progress);

    // Organic Blob Shape
    const int points = 12;
    final double angleStep = (math.pi * 2) / points;

    for (int i = 0; i <= points; i++) {
      final double angle = i * angleStep;

      // Add multiple sine waves for organic feel
      final double wave1 = math.sin(angle * 3 + progress * 5) * 20;
      final double wave2 = math.cos(angle * 5 - progress * 3) * 15;
      final double wave =
          (wave1 + wave2) * (1 - progress); // Flatten as it expands

      final double r = currentRadius + wave;

      final double x = centerX + r * math.cos(angle);
      final double y = centerY + r * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // Use quadratic bezier for smoother curves
        final double prevAngle = (i - 1) * angleStep;
        final double prevWave1 = math.sin(prevAngle * 3 + progress * 5) * 20;
        final double prevWave2 = math.cos(prevAngle * 5 - progress * 3) * 15;
        final double prevWave = (prevWave1 + prevWave2) * (1 - progress);
        final double prevR = currentRadius + prevWave;
        final double prevX = centerX + prevR * math.cos(prevAngle);
        final double prevY = centerY + prevR * math.sin(prevAngle);

        final double cpX = (prevX + x) / 2;
        final double cpY = (prevY + y) / 2;

        path.quadraticBezierTo(prevX, prevY, cpX, cpY);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_OrganicGooeyPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// Standalone Gooey Transition Widget
class GooeyTransition extends StatefulWidget {
  final Widget child;
  final Color blobColor;
  final Duration duration;
  final bool isActive;
  final VoidCallback? onComplete;

  const GooeyTransition({
    super.key,
    required this.child,
    this.blobColor = Colors.purple,
    this.duration = const Duration(milliseconds: 800),
    this.isActive = false,
    this.onComplete,
  });

  @override
  State<GooeyTransition> createState() => _GooeyTransitionState();
}

class _GooeyTransitionState extends State<GooeyTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    if (widget.isActive) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(GooeyTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.forward(from: 0);
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          foregroundPainter: _OrganicGooeyPainter(
            progress: _animation.value,
            color: widget.blobColor,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Liquid Wave Transition
class LiquidWaveTransition extends StatefulWidget {
  final Widget frontChild;
  final Widget backChild;
  final bool showBack;
  final Duration duration;
  final Color waveColor;

  const LiquidWaveTransition({
    super.key,
    required this.frontChild,
    required this.backChild,
    this.showBack = false,
    this.duration = const Duration(milliseconds: 1000),
    this.waveColor = Colors.blue,
  });

  @override
  State<LiquidWaveTransition> createState() => _LiquidWaveTransitionState();
}

class _LiquidWaveTransitionState extends State<LiquidWaveTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _waveAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutQuart,
    );

    if (widget.showBack) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(LiquidWaveTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showBack != oldWidget.showBack) {
      if (widget.showBack) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, _) {
        return Stack(
          children: [
            widget.frontChild,
            ClipPath(
              clipper: _LiquidWaveClipper(_waveAnimation.value),
              child: Container(
                color: widget.waveColor, // Background for the wave
                child: Opacity(
                  opacity: _waveAnimation.value.clamp(0.5, 1.0),
                  child: widget.backChild,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LiquidWaveClipper extends CustomClipper<Path> {
  final double progress;

  _LiquidWaveClipper(this.progress);

  @override
  Path getClip(Size size) {
    final path = Path();

    // Wave moves from bottom to top
    final waveHeight = size.height * (1 - progress);

    path.moveTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, waveHeight);

    // Add wave effect at the top edge
    final amplitude = 20.0 * (1 - progress); // Flatten as it fills
    final frequency = 2.0;

    for (double x = size.width; x >= 0; x -= 5) {
      final y =
          waveHeight +
          math.sin((x / size.width * math.pi * frequency) + (progress * 10)) *
              amplitude;
      path.lineTo(x, y);
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(_LiquidWaveClipper oldClipper) {
    return oldClipper.progress != progress;
  }
}
