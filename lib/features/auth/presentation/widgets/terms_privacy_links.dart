import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Reusable Terms and Privacy Policy links widget
class TermsAndPrivacyLinks extends StatelessWidget {
  final String introText;

  const TermsAndPrivacyLinks({
    super.key,
    this.introText = 'By logging in, you agree to our',
  });

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.dark;

    return Column(
      children: [
        Text(
          introText,
          style: TextStyle(
            color: colors.muted.withValues(alpha: 204), // Fixed: replaced withAlpha with withValues
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
                'Terms',
                style: TextStyle(
                  color: colors.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              'and',
              style: TextStyle(
                color: colors.muted,
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
                'Privacy Policy',
                style: TextStyle(
                  color: colors.muted,
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
