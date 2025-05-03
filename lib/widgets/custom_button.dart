import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isDarkMode;
  final bool fullWidth;
  final double height;
  final double fontSize;
  final FontWeight fontWeight;
  final double borderRadius;
  final double elevation;

  const CustomButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isPrimary = true,
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
      foregroundColor: isPrimary ? colors.primaryForeground : null,
      backgroundColor: isPrimary ? colors.primary : null,
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
