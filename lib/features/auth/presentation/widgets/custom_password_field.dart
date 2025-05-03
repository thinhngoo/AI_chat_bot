import 'package:flutter/material.dart';
import '../../../../widgets/custom_text_field.dart';

class CustomPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final String? errorText;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final bool darkMode;

  const CustomPasswordField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.darkMode = false,
  });

  @override
  State<CustomPasswordField> createState() => _CustomPasswordFieldState();
}

class _CustomPasswordFieldState extends State<CustomPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: widget.controller,
      label: widget.label,
      hintText: widget.hintText,
      errorText: widget.errorText,
      prefixIcon: Icons.lock_outline,
      keyboardType: TextInputType.visiblePassword,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      darkMode: widget.darkMode,
      obscureText: _obscureText,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: widget.darkMode ? Colors.grey : Colors.grey.shade600,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
        tooltip: _obscureText ? 'Show password' : 'Hide password',
      ),
    );
  }
}
