import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CustomFormField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final String? errorText;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final Function(String)? onChanged;
  final Function()? onSubmit;
  final bool darkMode;
  final bool autocorrect;
  final TextCapitalization textCapitalization;
  final int? maxLines;
  final int? maxLength;

  const CustomFormField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    this.errorText,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.onSubmit,
    this.darkMode = false,
    this.autocorrect = false,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.maxLength,
  });

  @override
  State<CustomFormField> createState() => _CustomFormFieldState();
}

class _CustomFormFieldState extends State<CustomFormField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = widget.darkMode ? AppColors.dark : AppColors.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: colors.input,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.errorText != null
                  ? colors.error
                  : widget.darkMode
                      ? colors.border
                      : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            obscureText: widget.obscureText && _obscureText,
            keyboardType: widget.keyboardType,
            autocorrect: widget.autocorrect,
            textCapitalization: widget.textCapitalization,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            style: TextStyle(
              color: colors.inputForeground,
            ),
            cursorColor: colors.foreground,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: InputBorder.none,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colors.ring,
                  width: 1.5,
                ),
              ),
              counterText: '',
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: colors.muted,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: Icon(
                  widget.prefixIcon,
                  color: colors.muted,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              filled: false,
              suffixIcon: widget.obscureText
                  ? Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: colors.muted,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                        tooltip: _obscureText ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                      ),
                    )
                  : null,
            ),
            onChanged: widget.onChanged,
            onSubmitted:
                widget.onSubmit != null ? (_) => widget.onSubmit!() : null,
          ),
        ),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 12.0),
            child: Text(
              widget.errorText!,
              style: TextStyle(
                color: colors.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
