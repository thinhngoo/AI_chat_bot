import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Background with synthwave grid and gradient overlay for auth screens
class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background grid image
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/synthwave.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Gradient overlay for better visibility
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(179), // 0.7 opacity
                    Colors.black.withAlpha(128), // 0.5 opacity
                  ],
                ),
              ),
            ),
            // Content
            SafeArea(child: child),
          ],
        ),
      ),
    );
  }
}

/// Modular form field component that can be configured for different field types
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.input,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.errorText != null
                  ? AppColors.error
                  : widget.darkMode
                      ? AppColors.border
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
              color: AppColors.inputForeground,
            ),
            cursorColor: AppColors.foreground,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: InputBorder.none,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.ring,
                  width: 1.5,
                ),
              ),
              counterText: '',
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: AppColors.muted,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: Icon(
                  widget.prefixIcon,
                  color: AppColors.muted,
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
                          color: AppColors.muted,
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
                color: AppColors.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

/// Submit button with loading state
class SubmitButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool darkMode;

  const SubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.darkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: darkMode ? AppColors.buttonForeground : Colors.white,
          backgroundColor:
              darkMode ? AppColors.button : Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(darkMode ? 27 : 8),
          ),
          elevation: darkMode ? 0 : 2,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: darkMode ? AppColors.buttonForeground : Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: darkMode ? 18 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

/// Reusable Terms and Privacy Policy links widget
class TermsAndPrivacyLinks extends StatelessWidget {
  final String introText;
  final bool darkMode;

  const TermsAndPrivacyLinks({
    super.key,
    this.introText = 'Bằng cách đăng nhập, bạn đồng ý với',
    this.darkMode = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          introText,
          style: TextStyle(
            color: AppColors.muted.withAlpha(204),
            fontSize: 14,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Điều khoản',
                style: TextStyle(
                  color: AppColors.muted,
                  decoration: TextDecoration.underline,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              'và',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 14,
              ),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Chính sách bảo mật',
                style: TextStyle(
                  color: AppColors.muted,
                  decoration: TextDecoration.underline,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Reusable auth link widget for switching between login and register screens
class AuthLinkWidget extends StatelessWidget {
  final String questionText;
  final String linkText;
  final VoidCallback onPressed;
  final bool darkMode;

  const AuthLinkWidget({
    super.key,
    required this.questionText,
    required this.linkText,
    required this.onPressed,
    this.darkMode = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          questionText,
          style: TextStyle(
            color: AppColors.muted,
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: onPressed,
          child: Text(
            linkText,
            style: TextStyle(
              color: AppColors.foreground,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
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
