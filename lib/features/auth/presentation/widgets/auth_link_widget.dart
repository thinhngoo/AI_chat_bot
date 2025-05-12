import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.foreground,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
