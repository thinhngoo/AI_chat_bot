import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Reusable auth link widget for switching between login and register screens
class AuthLinkWidget extends StatelessWidget {
  final String questionText;
  final String linkText;
  final VoidCallback onPressed;

  const AuthLinkWidget({
    super.key,
    required this.questionText,
    required this.linkText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          questionText,
          style: TextStyle(
            color: colors.muted,
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
              color: colors.foreground,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
