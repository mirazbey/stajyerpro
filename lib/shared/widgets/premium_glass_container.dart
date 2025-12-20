import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/settings/presentation/settings_controller.dart';

class PremiumGlassContainer extends ConsumerWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final double opacity;
  final Color? color;
  final Gradient? gradient;
  final BoxBorder? border;
  final List<BoxShadow>? shadows;
  final bool hasNoise;
  final ImageProvider? backgroundImage;

  const PremiumGlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = DesignTokens.r24,
    this.blur = 20.0,
    this.opacity = 0.05,
    this.color,
    this.gradient,
    this.border,
    this.shadows,
    this.hasNoise = true,
    this.backgroundImage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsControllerProvider);
    final isPerformanceMode = settingsAsync.value?.performanceMode ?? false;

    // Reduce blur and disable noise in performance mode
    final effectiveBlur = isPerformanceMode ? 0.0 : blur;
    final effectiveHasNoise = isPerformanceMode ? false : hasNoise;

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        boxShadow: shadows ?? DesignTokens.shadowLg,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: effectiveBlur,
            sigmaY: effectiveBlur,
          ),
          child: Stack(
            children: [
              // Base Layer with Color/Gradient/Image
              Container(
                decoration: BoxDecoration(
                  color:
                      color?.withOpacity(opacity) ??
                      (gradient == null
                          ? Colors.white.withOpacity(opacity)
                          : null),
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(borderRadius),
                  image: backgroundImage != null
                      ? DecorationImage(
                          image: backgroundImage!,
                          fit: BoxFit.cover,
                          opacity: 0.3, // Subtle overlay
                        )
                      : null,
                  border:
                      border ??
                      Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                ),
                child: Padding(
                  padding: padding ?? const EdgeInsets.all(DesignTokens.s24),
                  child: child,
                ),
              ),

              // Noise Texture Overlay (Optional)
              if (effectiveHasNoise)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.02,
                      child: Image.asset(
                        'assets/images/noise.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox(),
                      ),
                    ),
                  ),
                ),

              // Inner Glow (Top-Left Highlight)
              if (!isPerformanceMode)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 1,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.4),
                            Colors.white.withOpacity(0.0),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
