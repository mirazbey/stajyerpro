import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

enum ButtonVariant { primary, secondary, ghost, text }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
        ] else if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: DesignTokens.s8),
        ],
        Text(
          text,
          style: theme.textTheme.labelLarge?.copyWith(
            color: _getTextColor(variant),
          ),
        ),
      ],
    );

    Widget button;

    switch (variant) {
      case ButtonVariant.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignTokens.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              vertical: DesignTokens.s16,
              horizontal: DesignTokens.s24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.r12),
            ),
          ),
          child: buttonContent,
        );
        break;
      case ButtonVariant.secondary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignTokens.secondary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              vertical: DesignTokens.s16,
              horizontal: DesignTokens.s24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.r12),
            ),
          ),
          child: buttonContent,
        );
        break;
      case ButtonVariant.ghost:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: DesignTokens.primary,
            side: const BorderSide(color: DesignTokens.primary),
            padding: const EdgeInsets.symmetric(
              vertical: DesignTokens.s16,
              horizontal: DesignTokens.s24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.r12),
            ),
          ),
          child: buttonContent,
        );
        break;
      case ButtonVariant.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: DesignTokens.primary,
            padding: const EdgeInsets.symmetric(
              vertical: DesignTokens.s12,
              horizontal: DesignTokens.s16,
            ),
          ),
          child: buttonContent,
        );
        break;
    }

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }

    return button;
  }

  Color _getTextColor(ButtonVariant variant) {
    switch (variant) {
      case ButtonVariant.primary:
      case ButtonVariant.secondary:
        return Colors.white;
      case ButtonVariant.ghost:
      case ButtonVariant.text:
        return DesignTokens.primary;
    }
  }
}
