import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

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
    final AppColors colors = darkMode ? AppColors.dark : AppColors.light;

    return Column(
      children: [
        Text(
          introText,
          style: TextStyle(
            color: colors.muted.withAlpha(204),
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
                  color: colors.muted,
                  decoration: TextDecoration.underline,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              'và',
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
                'Chính sách bảo mật',
                style: TextStyle(
                  color: colors.muted,
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
