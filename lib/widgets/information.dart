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
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIndicator(colors),

            if (message != null) ...[
              const SizedBox(height: 8),

              Text(
                message!,
                textAlign: TextAlign.center,
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
                color: colors.foreground.withAlpha(180),
                icon: Icons.refresh,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildIndicator(AppColors colors) {
    switch (variant) {
      case InformationVariant.error:
        return Icon(
          Icons.error_outline,
          size: 60,
          color: colors.error,
        );
      case InformationVariant.info:
        return Icon(
          Icons.info_outline,
          size: 60,
          color: colors.muted,
        );
      case InformationVariant.loading:
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SizedBox(
            height: 40,
            width: 40,
            child: CircularProgressIndicator(
              color: colors.muted,
            ),
          ),
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

enum SnackBarVariant {
  info,
  error,
  warning,
  success,
}

class GlobalSnackBar {
  static void show({
    required BuildContext context,
    required String message,
    SnackBarVariant variant = SnackBarVariant.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onActionPressed,
    VoidCallback? onDismissed,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final colors = isDarkMode ? AppColors.dark : AppColors.light;
    
    final Color backgroundColor;
    final Color foregroundColor;
    final IconData iconData;
    
    // Configure based on variant
    switch (variant) {
      case SnackBarVariant.info:
        backgroundColor = colors.card;
        foregroundColor = colors.cardForeground;
        iconData = Icons.info_outline;
        break;
      case SnackBarVariant.error:
        backgroundColor = colors.error;
        foregroundColor = colors.errorForeground;
        iconData = Icons.error_outline;
        break;
      case SnackBarVariant.warning:
        backgroundColor = colors.warning;
        foregroundColor = colors.warningForeground;
        iconData = Icons.warning_amber_outlined;
        break;
      case SnackBarVariant.success:
        backgroundColor = colors.success;
        foregroundColor = colors.successForeground;
        iconData = Icons.check_circle_outline;
        break;
    }
    
    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(8),
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: foregroundColor.withAlpha(30),
          width: 1,
        ),
      ),
      duration: duration,
      dismissDirection: DismissDirection.horizontal,
      content: Row(
        children: [
          Icon(
            iconData,
            color: foregroundColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: foregroundColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      action: actionLabel != null && onActionPressed != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: foregroundColor,
              onPressed: onActionPressed,
            )
          : null,
    );
    
    // Hide any existing snackbar before showing a new one
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    // Show the snackbar
    final snackBarController = ScaffoldMessenger.of(context).showSnackBar(snackBar);
    
    // Add dismissed callback if provided
    if (onDismissed != null) {
      snackBarController.closed.then((_) => onDismissed());
    }
  }
  
  // Helper method to show a pre-built SnackBar
  static void showSnackBar(BuildContext context, SnackBar snackBar) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
  
  // Helper method to hide the current snackbar
  static void hideCurrent(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }
  
  // Helper method for safely showing snackbars in async contexts
  static void showSafe(
    State state, {
    required String message,
    SnackBarVariant variant = SnackBarVariant.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onActionPressed,
    VoidCallback? onDismissed,
  }) {
    // Only show the snackbar if the widget is still mounted
    if (state.mounted) {
      show(
        context: state.context,
        message: message,
        variant: variant,
        duration: duration,
        actionLabel: actionLabel,
        onActionPressed: onActionPressed,
        onDismissed: onDismissed,
      );
    }
  }
} 