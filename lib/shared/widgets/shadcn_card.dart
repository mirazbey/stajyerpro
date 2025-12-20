// Shadcn/UI Inspired Card Components
// Material You + Shadcn + GetWidget Fusion

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/shadcn_theme.dart';

/// Card Variants
enum ShadcnCardVariant {
  default_,
  outline,
  ghost,
  elevated,
  gradient,
  glass,
}

/// Shadcn-style Card
class ShadcnCard extends StatefulWidget {
  final Widget child;
  final ShadcnCardVariant variant;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final bool isSelected;
  final Color? backgroundColor;
  final Gradient? gradient;
  final double? width;
  final double? height;
  final bool animate;

  const ShadcnCard({
    super.key,
    required this.child,
    this.variant = ShadcnCardVariant.default_,
    this.padding,
    this.onTap,
    this.isSelected = false,
    this.backgroundColor,
    this.gradient,
    this.width,
    this.height,
    this.animate = false,
  });

  @override
  State<ShadcnCard> createState() => _ShadcnCardState();
}

class _ShadcnCardState extends State<ShadcnCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Widget card = MouseRegion(
      onEnter: widget.onTap != null ? (_) => setState(() => _isHovered = true) : null,
      onExit: widget.onTap != null ? (_) => setState(() => _isHovered = false) : null,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: ShadcnDurations.fast,
          curve: ShadcnCurves.easeOut,
          width: widget.width,
          height: widget.height,
          padding: widget.padding ?? const EdgeInsets.all(16),
          decoration: _getDecoration(),
          transform: _isHovered && widget.onTap != null
              ? (Matrix4.identity()..translate(0.0, -2.0, 0.0))
              : Matrix4.identity(),
          child: widget.child,
        ),
      ),
    );

    if (widget.animate) {
      card = card
          .animate()
          .fadeIn(duration: ShadcnDurations.normal)
          .slideY(begin: 0.02, end: 0, duration: ShadcnDurations.normal);
    }

    return card;
  }

  BoxDecoration _getDecoration() {
    switch (widget.variant) {
      case ShadcnCardVariant.default_:
        return BoxDecoration(
          color: widget.backgroundColor ?? ShadcnColors.card,
          borderRadius: ShadcnRadius.borderLg,
          border: Border.all(
            color: widget.isSelected ? ShadcnColors.ring : ShadcnColors.border,
            width: widget.isSelected ? 2 : 1,
          ),
        );
        
      case ShadcnCardVariant.outline:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: ShadcnRadius.borderLg,
          border: Border.all(
            color: _isHovered ? ShadcnColors.ring : ShadcnColors.border,
            width: widget.isSelected ? 2 : 1,
          ),
        );
        
      case ShadcnCardVariant.ghost:
        return BoxDecoration(
          color: _isHovered 
              ? ShadcnColors.accent.withOpacity(0.1) 
              : Colors.transparent,
          borderRadius: ShadcnRadius.borderLg,
        );
        
      case ShadcnCardVariant.elevated:
        return BoxDecoration(
          color: widget.backgroundColor ?? ShadcnColors.card,
          borderRadius: ShadcnRadius.borderLg,
          boxShadow: _isHovered ? ShadcnShadows.lg : ShadcnShadows.md,
        );
        
      case ShadcnCardVariant.gradient:
        return BoxDecoration(
          gradient: widget.gradient ?? LinearGradient(
            colors: [
              ShadcnColors.primary.withOpacity(0.2),
              ShadcnColors.primary.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: ShadcnRadius.borderLg,
          border: Border.all(
            color: ShadcnColors.primary.withOpacity(0.3),
          ),
        );
        
      case ShadcnCardVariant.glass:
        return BoxDecoration(
          color: ShadcnColors.card.withOpacity(0.6),
          borderRadius: ShadcnRadius.borderLg,
          border: Border.all(
            color: ShadcnColors.border.withOpacity(0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        );
    }
  }
}

/// Stats Card - Özel istatistik kartı
class ShadcnStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showTrend;
  final double? trendValue;

  const ShadcnStatsCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.trailing,
    this.onTap,
    this.showTrend = false,
    this.trendValue,
  });

  @override
  Widget build(BuildContext context) {
    final card = ShadcnCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBackgroundColor ?? ShadcnColors.primary.withOpacity(0.1),
                  borderRadius: ShadcnRadius.borderMd,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor ?? ShadcnColors.primary,
                ),
              ),
              // Trend indicator
              if (showTrend && trendValue != null)
                _buildTrendIndicator(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          // Value
          Text(
            value,
            style: ShadcnTypography.h2.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          // Title
          Text(
            title,
            style: ShadcnTypography.bodySmall.copyWith(
              color: ShadcnColors.mutedForeground,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: ShadcnTypography.labelSmall.copyWith(
                color: ShadcnColors.mutedForeground,
              ),
            ),
          ],
        ],
      ),
    );
    return Animate(
      effects: [
        FadeEffect(duration: ShadcnDurations.normal),
        SlideEffect(begin: const Offset(0, 0.05), end: Offset.zero, duration: ShadcnDurations.normal),
      ],
      child: card,
    );
  }

  Widget _buildTrendIndicator() {
    final isPositive = trendValue! >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPositive 
            ? ShadcnColors.successMuted 
            : ShadcnColors.errorMuted,
        borderRadius: ShadcnRadius.borderFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            size: 14,
            color: isPositive ? ShadcnColors.success : ShadcnColors.error,
          ),
          const SizedBox(width: 4),
          Text(
            '${isPositive ? '+' : ''}${trendValue!.toStringAsFixed(1)}%',
            style: ShadcnTypography.labelSmall.copyWith(
              color: isPositive ? ShadcnColors.success : ShadcnColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Feature Card - Özellik/Aksiyon kartı
class ShadcnFeatureCard extends StatelessWidget {
  final String title;
  final String? description;
  final IconData icon;
  final Color? accentColor;
  final VoidCallback? onTap;
  final Widget? badge;
  final bool isLocked;

  const ShadcnFeatureCard({
    super.key,
    required this.title,
    this.description,
    required this.icon,
    this.accentColor,
    this.onTap,
    this.badge,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? ShadcnColors.primary;
    
    final card = ShadcnCard(
      variant: ShadcnCardVariant.gradient,
      gradient: LinearGradient(
        colors: [
          color.withOpacity(0.15),
          color.withOpacity(0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      onTap: isLocked ? null : onTap,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: ShadcnRadius.borderMd,
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  if (badge != null) badge!,
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: ShadcnTypography.h4,
              ),
              if (description != null) ...[
                const SizedBox(height: 4),
                Text(
                  description!,
                  style: ShadcnTypography.bodySmall.copyWith(
                    color: ShadcnColors.mutedForeground,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
          if (isLocked)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: ShadcnColors.background.withOpacity(0.7),
                  borderRadius: ShadcnRadius.borderLg,
                ),
                child: const Center(
                  child: Icon(
                    Icons.lock_outline,
                    color: ShadcnColors.mutedForeground,
                    size: 32,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    return Animate(
      effects: [
        FadeEffect(duration: ShadcnDurations.normal),
        ScaleEffect(begin: const Offset(0.95, 0.95), duration: ShadcnDurations.normal),
      ],
      child: card,
    );
  }
}

/// Quiz Option Card - Soru şıkkı kartı
class ShadcnOptionCard extends StatelessWidget {
  final String label;
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final bool isRevealed;
  final VoidCallback? onTap;

  const ShadcnOptionCard({
    super.key,
    required this.label,
    required this.text,
    this.isSelected = false,
    this.isCorrect = false,
    this.isWrong = false,
    this.isRevealed = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isRevealed ? null : onTap,
      child: AnimatedContainer(
        duration: ShadcnDurations.normal,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: ShadcnRadius.borderLg,
          border: Border.all(
            color: _getBorderColor(),
            width: isSelected || isCorrect || isWrong ? 2 : 1,
          ),
          boxShadow: isSelected && !isRevealed ? ShadcnShadows.sm : null,
        ),
        child: Row(
          children: [
            // Label circle
            AnimatedContainer(
              duration: ShadcnDurations.fast,
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _getLabelBackgroundColor(),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getBorderColor(),
                ),
              ),
              child: Center(
                child: isRevealed && isCorrect
                    ? const Icon(Icons.check, size: 18, color: ShadcnColors.success)
                    : isRevealed && isWrong
                        ? const Icon(Icons.close, size: 18, color: ShadcnColors.error)
                        : Text(
                            label,
                            style: ShadcnTypography.labelLarge.copyWith(
                              color: _getLabelTextColor(),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
              ),
            ),
            const SizedBox(width: 12),
            // Option text
            Expanded(
              child: Text(
                text,
                style: ShadcnTypography.bodyMedium.copyWith(
                  color: _getTextColor(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (isRevealed) {
      if (isCorrect) return ShadcnColors.successMuted;
      if (isWrong) return ShadcnColors.errorMuted;
    }
    if (isSelected) return ShadcnColors.primaryMuted;
    return ShadcnColors.card;
  }

  Color _getBorderColor() {
    if (isRevealed) {
      if (isCorrect) return ShadcnColors.success;
      if (isWrong) return ShadcnColors.error;
    }
    if (isSelected) return ShadcnColors.primary;
    return ShadcnColors.border;
  }

  Color _getLabelBackgroundColor() {
    if (isRevealed) {
      if (isCorrect) return ShadcnColors.success.withOpacity(0.2);
      if (isWrong) return ShadcnColors.error.withOpacity(0.2);
    }
    if (isSelected) return ShadcnColors.primary.withOpacity(0.2);
    return ShadcnColors.secondary;
  }

  Color _getLabelTextColor() {
    if (isRevealed) {
      if (isCorrect) return ShadcnColors.success;
      if (isWrong) return ShadcnColors.error;
    }
    if (isSelected) return ShadcnColors.primary;
    return ShadcnColors.foreground;
  }

  Color _getTextColor() {
    if (isRevealed) {
      if (isCorrect) return ShadcnColors.success;
      if (isWrong) return ShadcnColors.error;
    }
    return ShadcnColors.foreground;
  }
}
