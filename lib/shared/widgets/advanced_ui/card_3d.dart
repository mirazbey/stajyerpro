import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// 3D Dönen Kart Widget (Spring Physics ile)
class Card3D extends StatefulWidget {
  final Widget front;
  final Widget? back;
  final VoidCallback? onFlip;
  final bool flipOnTap;
  final double perspective;

  const Card3D({
    super.key,
    required this.front,
    this.back,
    this.onFlip,
    this.flipOnTap = true,
    this.perspective = 0.002,
  });

  @override
  State<Card3D> createState() => Card3DState();
}

class Card3DState extends State<Card3D> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late SpringSimulation _springSimulation;
  bool _isFront = true;
  double _targetAngle = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void flip() {
    _isFront = !_isFront;
    _targetAngle = _isFront ? 0.0 : math.pi;

    final spring = SpringDescription(
      mass: 1.0,
      stiffness: 100.0,
      damping: 15.0,
    );

    _springSimulation = SpringSimulation(
      spring,
      _controller.value,
      _targetAngle,
      _controller.velocity,
    );

    _controller.animateWith(_springSimulation);
    widget.onFlip?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.flipOnTap ? flip : null,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, widget.perspective)
          ..rotateY(_controller.value),
        child: _controller.value < math.pi / 2
            ? widget.front
            : Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateY(math.pi),
                child: widget.back ?? widget.front,
              ),
      ),
    );
  }
}

/// Gelişmiş Tilt Efektli Kart
class TiltCard extends StatefulWidget {
  final Widget child;
  final double maxTilt;
  final double perspective;
  final bool enableGlow;
  final Color glowColor;
  final VoidCallback? onTap;

  const TiltCard({
    super.key,
    required this.child,
    this.maxTilt = 20.0,
    this.perspective = 0.003,
    this.enableGlow = true,
    this.glowColor = Colors.white,
    this.onTap,
  });

  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _rotateX = 0.0;
  double _rotateY = 0.0;
  Alignment _glowAlignment = Alignment.center;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _controller.addListener(() {
      setState(() {
        // Reset animation logic
        _rotateX = _rotateX * (1 - _controller.value);
        _rotateY = _rotateY * (1 - _controller.value);
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    if (size.width == 0 || size.height == 0) return;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final x = details.localPosition.dx;
    final y = details.localPosition.dy;

    // Calculate rotation based on touch position relative to center
    final percentX = (x - centerX) / centerX;
    final percentY = (y - centerY) / centerY;

    setState(() {
      _rotateY = (percentX * widget.maxTilt).clamp(
        -widget.maxTilt,
        widget.maxTilt,
      );
      _rotateX = (-percentY * widget.maxTilt).clamp(
        -widget.maxTilt,
        widget.maxTilt,
      ); // Invert X for natural tilt

      // Update glow position opposite to tilt
      _glowAlignment = Alignment(
        -percentX.clamp(-1.0, 1.0),
        -percentY.clamp(-1.0, 1.0),
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: widget.onTap,
          onPanUpdate: (details) => _onPanUpdate(details, constraints.biggest),
          onPanEnd: _onPanEnd,
          child: TweenAnimationBuilder(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, value, child) {
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, widget.perspective)
                  ..rotateX(_rotateX * math.pi / 180)
                  ..rotateY(_rotateY * math.pi / 180),
                child: Stack(
                  children: [
                    widget.child,
                    if (widget.enableGlow)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                widget.glowColor.withOpacity(0.4),
                                Colors.transparent,
                              ],
                              center: _glowAlignment,
                              radius: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(
                              20,
                            ), // Match card radius
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Animated Glow Card
class GlowCard extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double spreadRadius;
  final double blurRadius;
  final VoidCallback? onTap;

  const GlowCard({
    super.key,
    required this.child,
    this.glowColor = Colors.blue,
    this.spreadRadius = 2.0,
    this.blurRadius = 15.0,
    this.onTap,
  });

  @override
  State<GlowCard> createState() => _GlowCardState();
}

class _GlowCardState extends State<GlowCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withOpacity(0.3 * _animation.value),
                blurRadius: widget.blurRadius * _animation.value,
                spreadRadius: widget.spreadRadius * _animation.value,
              ),
            ],
          ),
          child: GestureDetector(onTap: widget.onTap, child: widget.child),
        );
      },
      child: widget.child,
    );
  }
}
