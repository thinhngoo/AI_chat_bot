import 'package:flutter/material.dart';

/// Email field widget with standard validation and styling
class EmailField extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;
  final Function(String)? onChanged;
  final Function(String)? onSubmit;

  const EmailField({
    super.key, 
    required this.controller,
    this.errorText,
    this.onChanged,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: 'Email',
        hintText: 'Nhập địa chỉ email của bạn',
        prefixIcon: const Icon(Icons.email),
        border: const OutlineInputBorder(),
        errorText: errorText,
      ),
      onChanged: onChanged,
      onSubmitted: onSubmit,
    );
  }
}

/// Password field widget with standard styling and visibility toggle
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? errorText;
  final Function(String)? onChanged;
  final Function()? onSubmit;

  const PasswordField({
    super.key, 
    required this.controller,
    required this.labelText,
    this.errorText,
    this.onChanged,
    this.onSubmit,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscureText,
      decoration: InputDecoration(
        labelText: widget.labelText,
        prefixIcon: const Icon(Icons.lock),
        border: const OutlineInputBorder(),
        errorText: widget.errorText,
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
          tooltip: _obscureText ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
        ),
      ),
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmit != null ? (_) => widget.onSubmit!() : null,
    );
  }
}

/// Submit button with loading state
class SubmitButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  const SubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

/// Social login button
class SocialLoginButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;

  const SocialLoginButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black87,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: textColor),
        label: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }
}