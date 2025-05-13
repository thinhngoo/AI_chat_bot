import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'button.dart';
import 'text_field.dart';

// Make sure to export everything
export 'package:flutter/material.dart' show DialogRoute;

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

    final Color themeColor;
    final IconData iconData;
    final ButtonVariant buttonVariant;

    // Configure based on variant
    switch (variant) {
      case DialogVariant.info:
        themeColor = colors.card;
        iconData = Icons.info_outline;
        buttonVariant = ButtonVariant.primary;
        break;
      case DialogVariant.error:
        themeColor = colors.red;
        iconData = Icons.error_outline;
        buttonVariant = ButtonVariant.delete;
        break;
      case DialogVariant.warning:
        themeColor = colors.red;
        iconData = Icons.warning_amber_outlined;
        buttonVariant = ButtonVariant.delete;
        break;
      case DialogVariant.success:
        themeColor = colors.green;
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
                  color: themeColor,
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
                  textAlign: TextAlign.center,
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
                          radius: ButtonRadius.small,
                          variant: ButtonVariant.ghost,
                          color: colors.foreground.withAlpha(180),
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
                          radius: ButtonRadius.small,
                          color: themeColor,
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

/// Input dialog for text input with validation
class GlobalInputDialog {
  static Future<String?> show({
    required BuildContext context,
    required String title,
    String? message,
    required String hintText,
    String? initialValue,
    String? labelText,
    String confirmLabel = 'Submit',
    String cancelLabel = 'Cancel',
    DialogVariant variant = DialogVariant.info,
    TextInputType keyboardType = TextInputType.text,
    IconData? prefixIcon,
    int maxLines = 1,
    int? maxLength,
    bool barrierDismissible = true,
    String? Function(String?)? validator,
  }) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colors = isDarkMode ? AppColors.dark : AppColors.light;
    
    final textController = TextEditingController(text: initialValue);
    String? errorText;
    
    // Configure based on variant
    IconData iconData;
    Color themeColor;
    ButtonVariant buttonVariant;
    
    switch (variant) {
      case DialogVariant.info:
        themeColor = colors.primary;
        iconData = Icons.text_fields;
        buttonVariant = ButtonVariant.primary;
        break;
      case DialogVariant.error:
        themeColor = colors.red;
        iconData = Icons.error_outline;
        buttonVariant = ButtonVariant.delete;
        break;
      case DialogVariant.warning:
        themeColor = colors.red;
        iconData = Icons.warning_amber_outlined;
        buttonVariant = ButtonVariant.delete;
        break;
      case DialogVariant.success:
        themeColor = colors.green;
        iconData = Icons.check_circle_outline;
        buttonVariant = ButtonVariant.primary;
        break;
    }
    
    // Use StatefulBuilder to handle state changes inside the dialog
    return showDialog<String?>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                      prefixIcon ?? iconData,
                      size: 48,
                      color: themeColor,
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
                    if (message != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        message,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(204),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 20),
                    
                    // Input field
                    CommonTextField(
                      controller: textController,
                      label: labelText ?? title,
                      hintText: hintText,
                      darkMode: isDarkMode,
                      errorText: errorText,
                      prefixIcon: prefixIcon,
                      keyboardType: keyboardType,
                      maxLines: maxLines,
                      maxLength: maxLength,
                      onSubmitted: (_) {
                        // Validate on submit
                        if (validator != null) {
                          final error = validator(textController.text);
                          if (error != null) {
                            setState(() {
                              errorText = error;
                            });
                            return;
                          }
                        }
                        Navigator.of(dialogContext).pop(textController.text);
                      },
                    ),
                    
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Button(
                            label: cancelLabel,
                            onPressed: () {
                              Navigator.of(dialogContext).pop(null);
                            },
                            isDarkMode: isDarkMode,
                            variant: ButtonVariant.ghost,
                            radius: ButtonRadius.small,
                            color: colors.foreground.withAlpha(180),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Button(
                            label: confirmLabel,
                            onPressed: () {
                              // Validate before closing
                              if (validator != null) {
                                final error = validator(textController.text);
                                if (error != null) {
                                  setState(() {
                                    errorText = error;
                                  });
                                  return;
                                }
                              }
                              Navigator.of(dialogContext).pop(textController.text);
                            },
                            isDarkMode: isDarkMode,
                            radius: ButtonRadius.small,
                            color: themeColor,
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
          }
        );
      },
    ).then((value) {
      textController.dispose();
      return value;
    });
  }
}
