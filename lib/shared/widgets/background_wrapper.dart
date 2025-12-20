import 'package:flutter/material.dart';

/// Genel arka plan sarmalayıcı: tam ekran görsel + içerik.
class BackgroundWrapper extends StatelessWidget {
  final String imagePath;
  final Widget child;
  final double opacity;
  final Alignment alignment;
  final BoxFit fit;

  const BackgroundWrapper({
    super.key,
    required this.imagePath,
    required this.child,
    this.opacity = 0.25,
    this.alignment = Alignment.center,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          imagePath,
          fit: fit,
          alignment: alignment,
          opacity: AlwaysStoppedAnimation(opacity),
          errorBuilder: (context, error, stackTrace) =>
              const ColoredBox(color: Colors.black12),
        ),
        child,
      ],
    );
  }
}
