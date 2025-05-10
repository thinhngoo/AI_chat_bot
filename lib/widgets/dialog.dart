import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'button.dart';

enum DialogVariant {
  info,
  error,
  warning,
  success,
}

class GlobalDialog {
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    DialogVariant variant = DialogVariant.info,
    String? confirmLabel,
    String? cancelLabel,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
  }) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colors = isDarkMode ? AppColors.dark : AppColors.light;

    final Color backgroundColor;
    final Color foregroundColor;
    final IconData iconData;
    final ButtonVariant buttonVariant;

    // Configure based on variant
    switch (variant) {
      case DialogVariant.info:
        backgroundColor = colors.card;
        foregroundColor = colors.cardForeground;
        iconData = Icons.info_outline;
        buttonVariant = ButtonVariant.primary;
        break;
      case DialogVariant.error:
        backgroundColor = colors.error;
        foregroundColor = colors.errorForeground;
        iconData = Icons.error_outline;
        buttonVariant = ButtonVariant.delete;
        break;
      case DialogVariant.warning:
        backgroundColor = colors.error;
        foregroundColor = colors.errorForeground;
        iconData = Icons.warning_amber_outlined;
        buttonVariant = ButtonVariant.delete;
        break;
      case DialogVariant.success:
        backgroundColor = colors.success;
        foregroundColor = colors.successForeground;
        iconData = Icons.check_circle_outline;
        buttonVariant = ButtonVariant.primary;
        break;
    }

    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(30),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  iconData,
                  size: 48,
                  color: backgroundColor,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(204),
                      ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (cancelLabel != null)
                      Expanded(
                        child: Button(
                          label: cancelLabel,
                          onPressed: () {
                            Navigator.of(context).pop(false);
                            onCancel?.call();
                          },
                          isDarkMode: isDarkMode,
                          variant: ButtonVariant.ghost,
                          color: isDarkMode
                              ? colors.foreground.withAlpha(180)
                              : colors.foreground.withAlpha(120),
                        ),
                      ),
                    if (cancelLabel != null && confirmLabel != null)
                      const SizedBox(width: 12),
                    if (confirmLabel != null)
                      Expanded(
                        child: Button(
                          label: confirmLabel,
                          onPressed: () {
                            Navigator.of(context).pop(true);
                            onConfirm?.call();
                          },
                          isDarkMode: isDarkMode,
                          color: backgroundColor,
                          variant: buttonVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper method for safely showing dialogs in async contexts
  static Future<bool?> showSafe(
    State state, {
    required String title,
    required String message,
    DialogVariant variant = DialogVariant.info,
    String? confirmLabel,
    String? cancelLabel,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
  }) async {
    if (state.mounted) {
      return show(
        context: state.context,
        title: title,
        message: message,
        variant: variant,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        onConfirm: onConfirm,
        onCancel: onCancel,
        barrierDismissible: barrierDismissible,
      );
    }
    return null;
  }
}
