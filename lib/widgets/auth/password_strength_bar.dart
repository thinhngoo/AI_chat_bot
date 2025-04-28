import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class PasswordStrengthBar extends StatelessWidget {
  final String password;
  final bool darkMode;

  const PasswordStrengthBar({
    super.key,
    required this.password,
    this.darkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate strength score from 0 to 100
    final int strengthScore = _calculateStrengthScore(password);
    final String strengthText = _getStrengthText(strengthScore);
    final Color strengthColor = _getStrengthColor(strengthScore);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: strengthScore / 100,
              backgroundColor: darkMode ? AppColors.border : Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
              minHeight: 4,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2.0),
          child: Row(
            children: [
              Text(
                'Độ mạnh: ',
                style: TextStyle(
                  color: darkMode ? AppColors.muted : Colors.grey[700],
                  fontSize: 12,
                ),
              ),
              Text(
                strengthText,
                style: TextStyle(
                  color: strengthColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // Strength bar
      ],
    );
  }

  // Calculate password strength as a score from 0 to 100
  int _calculateStrengthScore(String password) {
    if (password.isEmpty) return 0;

    int score = 0;

    // Length contribution - up to 25 points
    score += password.length * 2;
    if (score > 25) score = 25;

    // Character variety - up to 75 additional points
    if (password.contains(RegExp(r'[A-Z]'))) score += 15; // Uppercase
    if (password.contains(RegExp(r'[a-z]'))) score += 15; // Lowercase
    if (password.contains(RegExp(r'[0-9]'))) score += 15; // Digits
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      score += 20; // Special chars
    }

    // Bonus for combination of character types - up to 10 additional points
    int typesCount = 0;
    if (password.contains(RegExp(r'[A-Z]'))) typesCount++;
    if (password.contains(RegExp(r'[a-z]'))) typesCount++;
    if (password.contains(RegExp(r'[0-9]'))) typesCount++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) typesCount++;

    if (typesCount >= 3) score += 10;

    return score > 100 ? 100 : score;
  }

  String _getStrengthText(int score) {
    if (score == 0) return 'Chưa nhập';
    if (score < 30) return 'Rất yếu';
    if (score < 50) return 'Yếu';
    if (score < 70) return 'Trung bình';
    if (score < 90) return 'Mạnh';
    return 'Rất mạnh';
  }

  Color _getStrengthColor(int score) {
    if (score == 0) return darkMode ? AppColors.muted : Colors.grey;
    if (score < 30) return Colors.red;
    if (score < 50) return Colors.orange;
    if (score < 70) return Colors.yellow;
    if (score < 90) return Colors.lightGreen;
    return Colors.green;
  }
}
