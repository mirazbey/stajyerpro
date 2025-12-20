// Shadcn/UI Inspired Button Components
// Material You + Shadcn + GetWidget Fusion

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/shadcn_theme.dart';

/// Button Variants
enum ShadcnButtonVariant {
  primary,
  secondary,
  outline,
  ghost,
  destructive,
  link,
}

/// Button Sizes
enum ShadcnButtonSize {
  sm,
  md,
  lg,
  icon,
}

/// Shadcn-style Button
class ShadcnButton extends StatefulWidget {
  final String? text;
  final Widget? child;
  final VoidCallback? onPressed;
  final ShadcnButtonVariant variant;
  final ShadcnButtonSize size;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool isDisabled;
  final double? width;

  const ShadcnButton({
    super.key,
    this.text,
    this.child,
    this.onPressed,
    this.variant = ShadcnButtonVariant.primary,
    this.size = ShadcnButtonSize.md,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isDisabled = false,
    this.width,
  });

  @override
  State<ShadcnButton> createState() => _ShadcnButtonState();
}

class _ShadcnButtonState extends State<ShadcnButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.isDisabled || widget.isLoading;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: isDisabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: ShadcnDurations.fast,
          curve: ShadcnCurves.easeOut,
          width: widget.width,
          padding: _getPadding(),
          decoration: BoxDecoration(
            color: _getBackgroundColor(isDisabled),
            borderRadius: ShadcnRadius.borderMd,
            border: _getBorder(),
            boxShadow: _isPressed ? [] : (_isHovered ? ShadcnShadows.sm : []),
          ),
          transform: _isPressed 
              ? (Matrix4.identity()..scale(0.98, 0.98, 1.0))
              : Matrix4.identity(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                SizedBox(
                  width: _getIconSize(),
                  height: _getIconSize(),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(_getForegroundColor(isDisabled)),
                  ),
                )
              else if (widget.icon != null)
                Icon(
                  widget.icon,
                  size: _getIconSize(),
                  color: _getForegroundColor(isDisabled),
                ),
              if ((widget.icon != null || widget.isLoading) && 
                  (widget.text != null || widget.child != null))
                SizedBox(width: _getSpacing()),
              if (widget.child != null)
                widget.child!
              else if (widget.text != null)
                Text(
                  widget.text!,
                  style: _getTextStyle(isDisabled),
                ),
              if (widget.trailingIcon != null) ...[
                SizedBox(width: _getSpacing()),
                Icon(
                  widget.trailingIcon,
                  size: _getIconSize(),
                  color: _getForegroundColor(isDisabled),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  EdgeInsets _getPadding() {
    switch (widget.size) {
      case ShadcnButtonSize.sm:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case ShadcnButtonSize.md:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
      case ShadcnButtonSize.lg:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      case ShadcnButtonSize.icon:
        return const EdgeInsets.all(10);
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case ShadcnButtonSize.sm:
        return 14;
      case ShadcnButtonSize.md:
        return 16;
      case ShadcnButtonSize.lg:
        return 18;
      case ShadcnButtonSize.icon:
        return 20;
    }
  }

  double _getSpacing() {
    switch (widget.size) {
      case ShadcnButtonSize.sm:
        return 6;
      case ShadcnButtonSize.md:
        return 8;
      case ShadcnButtonSize.lg:
        return 10;
      case ShadcnButtonSize.icon:
        return 0;
    }
  }

  Color _getBackgroundColor(bool isDisabled) {
    if (isDisabled) {
      return ShadcnColors.muted.withOpacity(0.5);
    }

    switch (widget.variant) {
      case ShadcnButtonVariant.primary:
        return _isHovered ? ShadcnColors.primaryHover : ShadcnColors.primary;
      case ShadcnButtonVariant.secondary:
        return _isHovered ? ShadcnColors.secondaryHover : ShadcnColors.secondary;
      case ShadcnButtonVariant.outline:
      case ShadcnButtonVariant.ghost:
      case ShadcnButtonVariant.link:
        return _isHovered 
            ? ShadcnColors.accent.withOpacity(0.1) 
            : Colors.transparent;
      case ShadcnButtonVariant.destructive:
        return _isHovered 
            ? ShadcnColors.destructive.withOpacity(0.9) 
            : ShadcnColors.destructive;
    }
  }

  Color _getForegroundColor(bool isDisabled) {
    if (isDisabled) {
      return ShadcnColors.mutedForeground;
    }

    switch (widget.variant) {
      case ShadcnButtonVariant.primary:
        return ShadcnColors.primaryForeground;
      case ShadcnButtonVariant.secondary:
        return ShadcnColors.secondaryForeground;
      case ShadcnButtonVariant.outline:
      case ShadcnButtonVariant.ghost:
        return ShadcnColors.foreground;
      case ShadcnButtonVariant.destructive:
        return ShadcnColors.destructiveForeground;
      case ShadcnButtonVariant.link:
        return ShadcnColors.primary;
    }
  }

  Border? _getBorder() {
    if (widget.variant == ShadcnButtonVariant.outline) {
      return Border.all(
        color: _isHovered ? ShadcnColors.ring : ShadcnColors.border,
      );
    }
    return null;
  }

  TextStyle _getTextStyle(bool isDisabled) {
    final baseStyle = widget.size == ShadcnButtonSize.sm
        ? ShadcnTypography.labelSmall
        : widget.size == ShadcnButtonSize.lg
            ? ShadcnTypography.labelLarge
            : ShadcnTypography.labelMedium;

    return baseStyle.copyWith(
      color: _getForegroundColor(isDisabled),
      decoration: widget.variant == ShadcnButtonVariant.link
          ? TextDecoration.underline
          : null,
    );
  }
}

/// Icon Button - Shadcn Style
class ShadcnIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final ShadcnButtonVariant variant;
  final ShadcnButtonSize size;
  final String? tooltip;
  final bool isLoading;
  final bool isDisabled;
  final Color? iconColor;

  const ShadcnIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.variant = ShadcnButtonVariant.ghost,
    this.size = ShadcnButtonSize.md,
    this.tooltip,
    this.isLoading = false,
    this.isDisabled = false,
    this.iconColor,
  });

  @override
  State<ShadcnIconButton> createState() => _ShadcnIconButtonState();
}

class _ShadcnIconButtonState extends State<ShadcnIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.isDisabled || widget.isLoading;
    final size = _getSize();
    
    Widget button = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: isDisabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: ShadcnDurations.fast,
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: _getBackgroundColor(isDisabled),
            borderRadius: ShadcnRadius.borderMd,
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: size * 0.5,
                    height: size * 0.5,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        widget.iconColor ?? _getForegroundColor(isDisabled),
                      ),
                    ),
                  )
                : Icon(
                    widget.icon,
                    size: size * 0.5,
                    color: widget.iconColor ?? _getForegroundColor(isDisabled),
                  ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }

    return button;
  }

  double _getSize() {
    switch (widget.size) {
      case ShadcnButtonSize.sm:
        return 32;
      case ShadcnButtonSize.md:
        return 40;
      case ShadcnButtonSize.lg:
        return 48;
      case ShadcnButtonSize.icon:
        return 36;
    }
  }

  Color _getBackgroundColor(bool isDisabled) {
    if (isDisabled) {
      return Colors.transparent;
    }
    
    switch (widget.variant) {
      case ShadcnButtonVariant.primary:
        return _isHovered ? ShadcnColors.primaryHover : ShadcnColors.primary;
      case ShadcnButtonVariant.secondary:
        return _isHovered ? ShadcnColors.secondaryHover : ShadcnColors.secondary;
      case ShadcnButtonVariant.ghost:
      case ShadcnButtonVariant.outline:
      case ShadcnButtonVariant.link:
        return _isHovered ? ShadcnColors.accent : Colors.transparent;
      case ShadcnButtonVariant.destructive:
        return _isHovered ? ShadcnColors.destructive.withOpacity(0.9) : ShadcnColors.destructive;
    }
  }

  Color _getForegroundColor(bool isDisabled) {
    if (isDisabled) {
      return ShadcnColors.mutedForeground;
    }

    switch (widget.variant) {
      case ShadcnButtonVariant.primary:
        return ShadcnColors.primaryForeground;
      case ShadcnButtonVariant.destructive:
        return ShadcnColors.destructiveForeground;
      default:
        return ShadcnColors.foreground;
    }
  }
}

/// Floating Action Button - Shadcn Style
class ShadcnFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? label;
  final bool extended;

  const ShadcnFab({
    super.key,
    required this.icon,
    this.onPressed,
    this.label,
    this.extended = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: extended ? ShadcnRadius.borderXl : ShadcnRadius.borderFull,
        boxShadow: ShadcnShadows.glowPrimary(0.3),
      ),
      child: Material(
        color: ShadcnColors.primary,
        borderRadius: extended ? ShadcnRadius.borderXl : ShadcnRadius.borderFull,
        child: InkWell(
          onTap: onPressed,
          borderRadius: extended ? ShadcnRadius.borderXl : ShadcnRadius.borderFull,
          child: Padding(
            padding: extended
                ? const EdgeInsets.symmetric(horizontal: 20, vertical: 14)
                : const EdgeInsets.all(16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: ShadcnColors.primaryForeground,
                  size: 24,
                ),
                if (extended && label != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    label!,
                    style: ShadcnTypography.labelLarge.copyWith(
                      color: ShadcnColors.primaryForeground,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ).animate().scale(
      duration: ShadcnDurations.normal,
      curve: Curves.easeOutBack,
    );
  }
}
