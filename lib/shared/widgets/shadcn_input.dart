// Shadcn/UI Inspired Input Components
// Material You + Shadcn + GetWidget Fusion

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/shadcn_theme.dart';

/// Shadcn-style Text Input
class ShadcnInput extends StatefulWidget {
  final String? label;
  final String? placeholder;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  const ShadcnInput({
    super.key,
    this.label,
    this.placeholder,
    this.helperText,
    this.errorText,
    this.controller,
    this.focusNode,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<ShadcnInput> createState() => _ShadcnInputState();
}

class _ShadcnInputState extends State<ShadcnInput> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: ShadcnTypography.labelMedium.copyWith(
              color: hasError ? ShadcnColors.error : ShadcnColors.foreground,
            ),
          ),
          const SizedBox(height: 6),
        ],
        
        // Input field
        AnimatedContainer(
          duration: ShadcnDurations.fast,
          decoration: BoxDecoration(
            borderRadius: ShadcnRadius.borderMd,
            border: Border.all(
              color: hasError
                  ? ShadcnColors.error
                  : _isFocused
                      ? ShadcnColors.ring
                      : ShadcnColors.border,
              width: _isFocused ? 2 : 1,
            ),
            color: widget.enabled ? ShadcnColors.input : ShadcnColors.muted,
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            obscureText: widget.obscureText && !_showPassword,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            maxLength: widget.maxLength,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            inputFormatters: widget.inputFormatters,
            textCapitalization: widget.textCapitalization,
            style: ShadcnTypography.bodyMedium,
            cursorColor: ShadcnColors.primary,
            decoration: InputDecoration(
              hintText: widget.placeholder,
              hintStyle: ShadcnTypography.bodyMedium.copyWith(
                color: ShadcnColors.mutedForeground,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: InputBorder.none,
              counterText: '',
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      size: 18,
                      color: ShadcnColors.mutedForeground,
                    )
                  : null,
              suffixIcon: widget.obscureText
                  ? IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                        color: ShadcnColors.mutedForeground,
                      ),
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                    )
                  : widget.suffixIcon != null
                      ? IconButton(
                          icon: Icon(
                            widget.suffixIcon,
                            size: 18,
                            color: ShadcnColors.mutedForeground,
                          ),
                          onPressed: widget.onSuffixTap,
                        )
                      : null,
            ),
          ),
        ),
        
        // Helper/Error text
        if (widget.errorText != null || widget.helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.errorText ?? widget.helperText!,
            style: ShadcnTypography.bodySmall.copyWith(
              color: hasError ? ShadcnColors.error : ShadcnColors.mutedForeground,
            ),
          ),
        ],
      ],
    );
  }
}

/// Shadcn-style Search Input
class ShadcnSearchInput extends StatefulWidget {
  final String? placeholder;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;

  const ShadcnSearchInput({
    super.key,
    this.placeholder = 'Ara...',
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
  });

  @override
  State<ShadcnSearchInput> createState() => _ShadcnSearchInputState();
}

class _ShadcnSearchInputState extends State<ShadcnSearchInput> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChange);
    _hasText = _controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChange() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ShadcnColors.secondary,
        borderRadius: ShadcnRadius.borderMd,
        border: Border.all(color: ShadcnColors.border),
      ),
      child: TextField(
        controller: _controller,
        autofocus: widget.autofocus,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        style: ShadcnTypography.bodyMedium,
        cursorColor: ShadcnColors.primary,
        decoration: InputDecoration(
          hintText: widget.placeholder,
          hintStyle: ShadcnTypography.bodyMedium.copyWith(
            color: ShadcnColors.mutedForeground,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: InputBorder.none,
          prefixIcon: const Icon(
            Icons.search,
            size: 20,
            color: ShadcnColors.mutedForeground,
          ),
          suffixIcon: _hasText
              ? IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: ShadcnColors.mutedForeground,
                  ),
                  onPressed: () {
                    _controller.clear();
                    widget.onClear?.call();
                  },
                )
              : null,
        ),
      ),
    );
  }
}

/// Shadcn-style Checkbox
class ShadcnCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final bool disabled;

  const ShadcnCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : () => onChanged?.call(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: ShadcnDurations.fast,
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: value 
                  ? (disabled ? ShadcnColors.muted : ShadcnColors.primary)
                  : Colors.transparent,
              borderRadius: ShadcnRadius.borderSm,
              border: Border.all(
                color: value
                    ? (disabled ? ShadcnColors.muted : ShadcnColors.primary)
                    : ShadcnColors.border,
                width: 1.5,
              ),
            ),
            child: value
                ? const Icon(
                    Icons.check,
                    size: 14,
                    color: ShadcnColors.primaryForeground,
                  )
                : null,
          ),
          if (label != null) ...[
            const SizedBox(width: 8),
            Text(
              label!,
              style: ShadcnTypography.bodyMedium.copyWith(
                color: disabled ? ShadcnColors.mutedForeground : ShadcnColors.foreground,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shadcn-style Switch
class ShadcnSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final bool disabled;

  const ShadcnSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : () => onChanged?.call(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: ShadcnDurations.fast,
            width: 44,
            height: 24,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: value
                  ? (disabled ? ShadcnColors.muted : ShadcnColors.primary)
                  : ShadcnColors.secondary,
              borderRadius: ShadcnRadius.borderFull,
            ),
            child: AnimatedAlign(
              duration: ShadcnDurations.fast,
              curve: Curves.easeInOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: ShadcnColors.foreground,
                  shape: BoxShape.circle,
                  boxShadow: ShadcnShadows.sm,
                ),
              ),
            ),
          ),
          if (label != null) ...[
            const SizedBox(width: 8),
            Text(
              label!,
              style: ShadcnTypography.bodyMedium.copyWith(
                color: disabled ? ShadcnColors.mutedForeground : ShadcnColors.foreground,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shadcn-style Radio
class ShadcnRadio<T> extends StatelessWidget {
  final T value;
  final T groupValue;
  final ValueChanged<T>? onChanged;
  final String? label;
  final bool disabled;

  const ShadcnRadio({
    super.key,
    required this.value,
    required this.groupValue,
    this.onChanged,
    this.label,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    
    return GestureDetector(
      onTap: disabled ? null : () => onChanged?.call(value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: ShadcnDurations.fast,
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? (disabled ? ShadcnColors.muted : ShadcnColors.primary)
                    : ShadcnColors.border,
                width: isSelected ? 5 : 1.5,
              ),
            ),
          ),
          if (label != null) ...[
            const SizedBox(width: 8),
            Text(
              label!,
              style: ShadcnTypography.bodyMedium.copyWith(
                color: disabled ? ShadcnColors.mutedForeground : ShadcnColors.foreground,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shadcn-style Slider
class ShadcnSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double>? onChanged;
  final String? label;
  final bool showValue;

  const ShadcnSlider({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 100,
    this.divisions,
    this.onChanged,
    this.label,
    this.showValue = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null || showValue)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (label != null)
                  Text(
                    label!,
                    style: ShadcnTypography.labelMedium,
                  ),
                if (showValue)
                  Text(
                    value.toStringAsFixed(0),
                    style: ShadcnTypography.bodySmall.copyWith(
                      color: ShadcnColors.mutedForeground,
                    ),
                  ),
              ],
            ),
          ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: ShadcnColors.primary,
            inactiveTrackColor: ShadcnColors.secondary,
            thumbColor: ShadcnColors.foreground,
            overlayColor: ShadcnColors.primary.withOpacity(0.2),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
