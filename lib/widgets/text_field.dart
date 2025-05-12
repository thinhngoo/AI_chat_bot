import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class CommonTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final bool darkMode;
  final bool autocorrect;
  final TextCapitalization textCapitalization;
  final int? maxLines;
  final int? maxLength;
  final bool readOnly;
  final bool enabled;
  final bool obscureText;

  const CommonTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.onSubmitted,
    this.darkMode = false,
    this.autocorrect = false,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.maxLength,
    this.readOnly = false,
    this.enabled = true,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors colors = darkMode ? AppColors.dark : AppColors.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: colors.input,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            autocorrect: autocorrect,
            textCapitalization: textCapitalization,
            maxLines: maxLines,
            maxLength: maxLength,
            readOnly: readOnly,
            enabled: enabled,
            obscureText: obscureText,
            style: TextStyle(
              color: colors.inputForeground,
            ),
            cursorColor: colors.foreground,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: errorText != null ? colors.red : colors.border,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colors.ring,
                  width: 1.5,
                ),
              ),
              counterText: '',
              hintText: hintText,
              hintStyle: TextStyle(
                color: colors.muted,
              ),
              prefixIcon: prefixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 12, right: 8),
                      child: Icon(
                        prefixIcon,
                        color: colors.muted,
                      ),
                    )
                  : null,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              filled: false,
              suffixIcon: suffixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: suffixIcon,
                    )
                  : null,
            ),
            onChanged: onChanged,
            onSubmitted: onSubmitted,
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              errorText!,
              style: TextStyle(
                color: colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

/// A variant of CustomTextField specifically for the email compose screen
/// that supports focus nodes and has a label displayed in the field.
class FloatingLabelTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final bool darkMode;
  final bool autocorrect;
  final TextCapitalization textCapitalization;
  final int? maxLines;
  final int? maxLength;
  final bool readOnly;
  final bool enabled;
  final FocusNode? focusNode;
  final bool obscureText;

  const FloatingLabelTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.onSubmitted,
    this.darkMode = false,
    this.autocorrect = false,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.maxLength,
    this.readOnly = false,
    this.enabled = true,
    this.focusNode,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors colors = darkMode ? AppColors.dark : AppColors.light;
    final bool isMultiline = maxLines != null && maxLines! > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: colors.input,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            autocorrect: autocorrect,
            textCapitalization: textCapitalization,
            maxLines: maxLines,
            maxLength: maxLength,
            readOnly: readOnly,
            enabled: enabled,
            focusNode: focusNode,
            obscureText: obscureText,
            style: TextStyle(
              color: colors.inputForeground,
            ),
            cursorColor: colors.foreground,
            textAlignVertical:
                isMultiline ? TextAlignVertical.top : TextAlignVertical.center,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: isMultiline ? 16 : 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: errorText != null ? colors.red : colors.border,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colors.ring,
                  width: 1.5,
                ),
              ),
              counterText: '',
              hintText: prefixIcon == null ? hintText : null,
              hintStyle: TextStyle(
                color: colors.muted.withAlpha(180),
              ),
              labelText: label,
              labelStyle: TextStyle(
                color: colors.muted,
              ),
              floatingLabelStyle: TextStyle(
                color: colors.foreground,
              ),
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              alignLabelWithHint: isMultiline,
              prefixIcon: prefixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 12, right: 8),
                      child: Icon(
                        prefixIcon,
                        color: colors.muted,
                      ),
                    )
                  : null,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              filled: false,
              suffixIcon: suffixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: suffixIcon,
                    )
                  : null,
            ),
            onChanged: onChanged,
            onSubmitted: onSubmitted,
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              errorText!,
              style: TextStyle(
                color: colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

/// A styled dropdown that matches the FloatingLabelTextField design
class StyledDropdown<T> extends StatelessWidget {
  final String label;
  final String hintText;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool darkMode;
  final String? errorText;
  final bool enabled;
  final IconData? prefixIcon;

  const StyledDropdown({
    super.key,
    required this.label,
    required this.hintText,
    required this.value,
    required this.items,
    required this.onChanged,
    this.darkMode = false,
    this.errorText,
    this.enabled = true,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors colors = darkMode ? AppColors.dark : AppColors.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: colors.input,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<T>(
            value: value,
            items: items,
            onChanged: enabled ? onChanged : null,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: errorText != null ? colors.red : colors.border,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colors.ring,
                  width: 1.5,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colors.border.withAlpha(100),
                  width: 1,
                ),
              ),
              labelText: label,
              labelStyle: TextStyle(
                color: colors.muted,
              ),
              floatingLabelStyle: TextStyle(
                color: colors.foreground,
              ),
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              hintText: hintText,
              hintStyle: TextStyle(
                color: colors.muted.withAlpha(180),
              ),
              filled: false,
              prefixIcon: prefixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 12, right: 8),
                      child: Icon(
                        prefixIcon,
                        color: colors.muted,
                      ),
                    )
                  : null,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
            ),
            icon: Icon(
              Icons.arrow_drop_down,
              color: colors.muted,
            ),
            dropdownColor: colors.card,
            style: TextStyle(
              color: colors.inputForeground,
            ),
            isExpanded: true,
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              errorText!,
              style: TextStyle(
                color: colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
