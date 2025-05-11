import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

enum ButtonSize {
  small,
  medium,
  large,
}

enum ButtonRadius {
  small,
  medium,
  large,
}

enum ButtonVariant {
  primary,
  normal,
  delete,
  ghost,
}

class Button extends StatelessWidget {
  final String label;
  final IconData? icon;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool isDarkMode;
  final bool fullWidth;
  final FontWeight fontWeight;
  final ButtonRadius radius;
  final double elevation;
  final VoidCallback? onPressed;
  final Color? color;
  final int ghostAlpha;
  final double? width;

  const Button({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isDarkMode = false,
    this.fullWidth = true,
    this.fontWeight = FontWeight.normal,
    this.size = ButtonSize.medium,
    this.radius = ButtonRadius.large,
    this.elevation = 2.0,
    this.color,
    this.ghostAlpha = 20,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors colors = isDarkMode ? AppColors.dark : AppColors.light;

    final EdgeInsetsGeometry buttonPadding;
    final double iconSize;
    final double fontSize;
    final double spacing;
    switch (size) {
      case ButtonSize.small:
        buttonPadding = const EdgeInsets.symmetric(vertical: 4, horizontal: 10);
        iconSize = 20.0;
        fontSize = 12.0;
        spacing = 4.0;
        break;
      case ButtonSize.medium:
        buttonPadding = const EdgeInsets.symmetric(vertical: 12, horizontal: 16);
        iconSize = 24.0;
        fontSize = 14.0;
        spacing = 8.0;
        break;
      case ButtonSize.large:{
        buttonPadding = const EdgeInsets.symmetric(vertical: 16);
        iconSize = 24.0;
        fontSize = 18.0;
        spacing = 8.0;
        break;
        }
    }

    final double borderRadius;
    switch (radius) {
      case ButtonRadius.small:
        borderRadius = 12.0;
        break;
      case ButtonRadius.medium:
        borderRadius = 24.0;
        break;
      case ButtonRadius.large:
        borderRadius = 27.0;
        break;
    }

    final Color background;
    final Color foreground;
    switch (variant) {
      case ButtonVariant.primary:
        background = colors.primary;
        foreground = colors.primaryForeground;
        break;
      case ButtonVariant.normal:
        background = colors.card;
        foreground = colors.cardForeground;
        break;
      case ButtonVariant.delete:
        background = colors.red;
        foreground = colors.redForeground;
        break;
      case ButtonVariant.ghost:
        final Color ghostColor = (color ?? colors.primary);
        background = ghostColor.withAlpha(ghostAlpha);
        foreground = ghostColor;
        break;
    }

    final Widget buttonChild = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: iconSize, color: variant == ButtonVariant.ghost ? foreground : null),
          SizedBox(width: spacing),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: variant == ButtonVariant.ghost ? foreground : null,
          ),
        ),
      ],
    );

    final ButtonStyle buttonStyle = variant == ButtonVariant.ghost
        ? TextButton.styleFrom(
            foregroundColor: foreground,
            backgroundColor: background,
            padding: buttonPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          )
        : ElevatedButton.styleFrom(
            foregroundColor: foreground,
            backgroundColor: background,
            padding: buttonPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            elevation: elevation,
          );

    // Get the available width from constraints if in an unbounded context
    return LayoutBuilder(
      builder: (context, constraints) {
        double? buttonWidth;
        if (fullWidth) {
          // If fullWidth is true, take the available width (or a reasonable default)
          buttonWidth = constraints.hasBoundedWidth ? constraints.maxWidth : 280.0;
        } else if (width != null) {
          buttonWidth = width;
        }

        return SizedBox(
          width: buttonWidth,
          child: variant == ButtonVariant.ghost
              ? TextButton(
                  onPressed: onPressed,
                  style: buttonStyle,
                  child: buttonChild,
                )
              : ElevatedButton(
                  onPressed: onPressed,
                  style: buttonStyle,
                  child: buttonChild,
                ),
        );
      }
    );
  }
}
