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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colors.muted.withAlpha(204),
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.muted,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              'and',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.muted.withAlpha(204),
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.muted,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
