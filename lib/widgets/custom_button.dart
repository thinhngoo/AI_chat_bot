import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class LargeButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isDelete;
  final bool isDarkMode;
  final bool fullWidth;
  final double height;
  final double fontSize;
  final FontWeight fontWeight;
  final double borderRadius;
  final double elevation;

  const LargeButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isPrimary = true,
    this.isDelete = false,
    this.isDarkMode = false,
    this.fullWidth = true,
    this.height = 60.0,
    this.fontSize = 18.0,
    this.fontWeight = FontWeight.bold,
    this.borderRadius = 27.0,
    this.elevation = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors colors = isDarkMode ? AppColors.dark : AppColors.light;

    final Widget buttonChild = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 24),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
          ),
        ),
      ],
    );

    final buttonStyle = ElevatedButton.styleFrom(
      foregroundColor: isDelete 
          ? colors.deleteForeground 
          : isPrimary ? colors.primaryForeground : null,
      backgroundColor: isDelete 
          ? colors.delete 
          : isPrimary ? colors.primary : null,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      elevation: elevation,
    );

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: icon != null
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 24),
              label: Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: fontWeight,
                ),
              ),
              style: buttonStyle,
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: buttonStyle,
              child: buttonChild,
            ),
    );
  }
}

class MiniGhostButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? color;
  final bool isDarkMode;
  final double iconSize;
  final double fontSize;
  final FontWeight fontWeight;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const MiniGhostButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.color,
    this.isDarkMode = false,
    this.iconSize = 20.0,
    this.fontSize = 14.0,
    this.fontWeight = FontWeight.w500,
    this.padding = const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
    this.borderRadius = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors colors = isDarkMode ? AppColors.dark : AppColors.light;
    final buttonColor = color ?? colors.primary;

    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: buttonColor,
        size: iconSize,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: buttonColor,
          fontWeight: fontWeight,
          fontSize: fontSize,
        ),
      ),
      style: TextButton.styleFrom(
        backgroundColor: buttonColor.withAlpha(20),
        padding: padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
