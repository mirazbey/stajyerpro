// Shadcn/UI Inspired Badge, Progress & Misc Components
// Material You + Shadcn + GetWidget Fusion

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../core/theme/shadcn_theme.dart';

/// Badge Variants
enum ShadcnBadgeVariant {
  default_,
  secondary,
  outline,
  destructive,
  success,
  warning,
}

/// Shadcn-style Badge
class ShadcnBadge extends StatelessWidget {
  final String text;
  final ShadcnBadgeVariant variant;
  final IconData? icon;
  final bool dot;

  const ShadcnBadge({
    super.key,
    required this.text,
    this.variant = ShadcnBadgeVariant.default_,
    this.icon,
    this.dot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: ShadcnRadius.borderFull,
        border: variant == ShadcnBadgeVariant.outline
            ? Border.all(color: ShadcnColors.border)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: _getForegroundColor(),
                shape: BoxShape.circle,
              ),
            ),
          if (icon != null) ...[
            Icon(icon, size: 12, color: _getForegroundColor()),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: ShadcnTypography.labelSmall.copyWith(
              color: _getForegroundColor(),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (variant) {
      case ShadcnBadgeVariant.default_:
        return ShadcnColors.primary;
      case ShadcnBadgeVariant.secondary:
        return ShadcnColors.secondary;
      case ShadcnBadgeVariant.outline:
        return Colors.transparent;
      case ShadcnBadgeVariant.destructive:
        return ShadcnColors.destructive;
      case ShadcnBadgeVariant.success:
        return ShadcnColors.success;
      case ShadcnBadgeVariant.warning:
        return ShadcnColors.warning;
    }
  }

  Color _getForegroundColor() {
    switch (variant) {
      case ShadcnBadgeVariant.default_:
        return ShadcnColors.primaryForeground;
      case ShadcnBadgeVariant.secondary:
        return ShadcnColors.secondaryForeground;
      case ShadcnBadgeVariant.outline:
        return ShadcnColors.foreground;
      case ShadcnBadgeVariant.destructive:
        return ShadcnColors.destructiveForeground;
      case ShadcnBadgeVariant.success:
      case ShadcnBadgeVariant.warning:
        return Colors.white;
    }
  }
}

/// Shadcn-style Progress Bar
class ShadcnProgress extends StatelessWidget {
  final double value; // 0.0 - 1.0
  final Color? color;
  final Color? backgroundColor;
  final double height;
  final String? label;
  final bool showPercentage;
  final bool animate;

  const ShadcnProgress({
    super.key,
    required this.value,
    this.color,
    this.backgroundColor,
    this.height = 8,
    this.label,
    this.showPercentage = false,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null || showPercentage)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (label != null)
                  Text(label!, style: ShadcnTypography.labelMedium),
                if (showPercentage)
                  Text(
                    '${(value * 100).toInt()}%',
                    style: ShadcnTypography.bodySmall.copyWith(
                      color: ShadcnColors.mutedForeground,
                    ),
                  ),
              ],
            ),
          ),
        LinearPercentIndicator(
          lineHeight: height,
          percent: value.clamp(0.0, 1.0),
          backgroundColor: backgroundColor ?? ShadcnColors.secondary,
          progressColor: color ?? ShadcnColors.primary,
          barRadius: Radius.circular(height / 2),
          padding: EdgeInsets.zero,
          animation: animate,
          animationDuration: 500,
        ),
      ],
    );
  }
}

/// Shadcn-style Circular Progress
class ShadcnCircularProgress extends StatelessWidget {
  final double value; // 0.0 - 1.0
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final double strokeWidth;
  final Widget? center;
  final bool showPercentage;
  final bool animate;

  const ShadcnCircularProgress({
    super.key,
    required this.value,
    this.color,
    this.backgroundColor,
    this.size = 100,
    this.strokeWidth = 10,
    this.center,
    this.showPercentage = true,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    return CircularPercentIndicator(
      radius: size / 2,
      lineWidth: strokeWidth,
      percent: value.clamp(0.0, 1.0),
      backgroundColor: backgroundColor ?? ShadcnColors.secondary,
      progressColor: color ?? ShadcnColors.primary,
      circularStrokeCap: CircularStrokeCap.round,
      animation: animate,
      animationDuration: 800,
      center: center ?? (showPercentage
          ? Text(
              '${(value * 100).toInt()}%',
              style: ShadcnTypography.h3.copyWith(
                fontWeight: FontWeight.w700,
              ),
            )
          : null),
    );
  }
}

/// Shadcn-style Avatar
class ShadcnAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? fallbackText;
  final double size;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool showBorder;
  final Widget? badge;

  const ShadcnAvatar({
    super.key,
    this.imageUrl,
    this.fallbackText,
    this.size = 40,
    this.backgroundColor,
    this.onTap,
    this.showBorder = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatar = GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor ?? ShadcnColors.secondary,
          border: showBorder
              ? Border.all(color: ShadcnColors.border, width: 2)
              : null,
          image: imageUrl != null
              ? DecorationImage(
                  image: NetworkImage(imageUrl!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: imageUrl == null
            ? Center(
                child: Text(
                  _getInitials(),
                  style: ShadcnTypography.labelMedium.copyWith(
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : null,
      ),
    );

    if (badge != null) {
      avatar = Stack(
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: badge!,
          ),
        ],
      );
    }

    return avatar;
  }

  String _getInitials() {
    if (fallbackText == null || fallbackText!.isEmpty) return '?';
    final parts = fallbackText!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fallbackText![0].toUpperCase();
  }
}

/// Shadcn-style Skeleton Loader
class ShadcnSkeleton extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool circle;

  const ShadcnSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.circle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: ShadcnColors.secondary,
        borderRadius: circle ? null : (borderRadius ?? ShadcnRadius.borderMd),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: const Duration(milliseconds: 1500),
          color: ShadcnColors.muted.withOpacity(0.3),
        );
  }
}

/// Shadcn-style Empty State
class ShadcnEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final Widget? action;

  const ShadcnEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ShadcnColors.secondary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: ShadcnColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: ShadcnTypography.h4,
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: ShadcnTypography.bodyMedium.copyWith(
                  color: ShadcnColors.mutedForeground,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }
}

/// Shadcn-style Divider with text
class ShadcnDivider extends StatelessWidget {
  final String? text;
  final Color? color;

  const ShadcnDivider({
    super.key,
    this.text,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (text == null) {
      return Divider(color: color ?? ShadcnColors.border, thickness: 1);
    }

    return Row(
      children: [
        Expanded(
          child: Divider(color: color ?? ShadcnColors.border, thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text!,
            style: ShadcnTypography.bodySmall.copyWith(
              color: ShadcnColors.mutedForeground,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: color ?? ShadcnColors.border, thickness: 1),
        ),
      ],
    );
  }
}

/// Shadcn-style Alert
class ShadcnAlert extends StatelessWidget {
  final String title;
  final String? description;
  final IconData? icon;
  final ShadcnBadgeVariant variant;
  final VoidCallback? onDismiss;

  const ShadcnAlert({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.variant = ShadcnBadgeVariant.default_,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: ShadcnRadius.borderLg,
        border: Border.all(color: _getBorderColor()),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(icon, size: 20, color: _getIconColor()),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ShadcnTypography.labelLarge.copyWith(
                    color: _getTextColor(),
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    description!,
                    style: ShadcnTypography.bodySmall.copyWith(
                      color: _getTextColor().withOpacity(0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: Icon(Icons.close, size: 18, color: _getTextColor()),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: -0.02);
  }

  Color _getBackgroundColor() {
    switch (variant) {
      case ShadcnBadgeVariant.destructive:
        return ShadcnColors.errorMuted;
      case ShadcnBadgeVariant.success:
        return ShadcnColors.successMuted;
      case ShadcnBadgeVariant.warning:
        return ShadcnColors.warningMuted;
      default:
        return ShadcnColors.infoMuted;
    }
  }

  Color _getBorderColor() {
    switch (variant) {
      case ShadcnBadgeVariant.destructive:
        return ShadcnColors.error.withOpacity(0.3);
      case ShadcnBadgeVariant.success:
        return ShadcnColors.success.withOpacity(0.3);
      case ShadcnBadgeVariant.warning:
        return ShadcnColors.warning.withOpacity(0.3);
      default:
        return ShadcnColors.info.withOpacity(0.3);
    }
  }

  Color _getIconColor() {
    switch (variant) {
      case ShadcnBadgeVariant.destructive:
        return ShadcnColors.error;
      case ShadcnBadgeVariant.success:
        return ShadcnColors.success;
      case ShadcnBadgeVariant.warning:
        return ShadcnColors.warning;
      default:
        return ShadcnColors.info;
    }
  }

  Color _getTextColor() {
    return ShadcnColors.foreground;
  }
}

/// Countdown Timer Widget
class ShadcnCountdown extends StatelessWidget {
  final Duration duration;
  final Duration remaining;
  final bool isWarning;
  final bool isDanger;

  const ShadcnCountdown({
    super.key,
    required this.duration,
    required this.remaining,
    this.isWarning = false,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    // Progress ratio: remaining.inSeconds / duration.inSeconds
    
    Color color = ShadcnColors.primary;
    if (isDanger) {
      color = ShadcnColors.error;
    } else if (isWarning) {
      color = ShadcnColors.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: ShadcnRadius.borderMd,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: ShadcnTypography.h4.copyWith(
              color: color,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
