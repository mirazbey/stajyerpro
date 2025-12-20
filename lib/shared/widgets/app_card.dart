import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Gradient? gradient;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.gradient,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            Theme.of(context).cardTheme.color ??
            DesignTokens.surface,
        gradient: gradient,
        borderRadius: BorderRadius.circular(DesignTokens.r16),
        border: border ?? Border.all(color: Colors.grey.shade200),
        boxShadow: DesignTokens.shadowSm,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DesignTokens.r16),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(DesignTokens.s16),
            child: child,
          ),
        ),
      ),
    );

    return card;
  }
}
