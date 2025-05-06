import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'button.dart';

enum InformationVariant {
  error,
  loading,
  info,
}

class InformationIndicator extends StatelessWidget {
  final String? message;
  final InformationVariant variant;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  
  const InformationIndicator({
    super.key, 
    this.message,
    this.variant = InformationVariant.loading,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final colors = isDarkMode ? AppColors.dark : AppColors.light;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildIndicator(colors),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _getTextColor(colors),
              ),
            ),
          ],
          if (buttonText != null && onButtonPressed != null) ...[
            const SizedBox(height: 12),
            MiniGhostButton(
              label: buttonText!,
              onPressed: onButtonPressed,
              isDarkMode: isDarkMode,
              color: colors.foreground,
              icon: Icons.refresh,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildIndicator(AppColors colors) {
    switch (variant) {
      case InformationVariant.error:
        return Icon(
          Icons.error_outline,
          size: 48,
          color: colors.error,
        );
      case InformationVariant.info:
        return Icon(
          Icons.info_outline,
          size: 48,
          color: colors.muted,
        );
      case InformationVariant.loading:
        return CircularProgressIndicator(
          color: colors.foreground.withAlpha(160),
        );
    }
  }
  
  Color _getTextColor(AppColors colors) {
    switch (variant) {
      case InformationVariant.error:
        return colors.error;
      case InformationVariant.info:
        return colors.muted;
      case InformationVariant.loading:
        return colors.muted;
    }
  }
} 