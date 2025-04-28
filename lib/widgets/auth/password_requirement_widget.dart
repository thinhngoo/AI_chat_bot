import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class PasswordRequirementWidget extends StatelessWidget {
  final String password;
  final bool showTitle;
  final bool darkMode;

  const PasswordRequirementWidget({
    super.key,
    required this.password,
    this.showTitle = false,
    this.darkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final requirements = [
      {
        'text': 'Ít nhất 8 ký tự',
        'isMet': password.length >= 8,
      },
      {
        'text': 'Ít nhất 1 chữ hoa',
        'isMet': password.contains(RegExp(r'[A-Z]')),
      },
      {
        'text': 'Ít nhất 1 chữ thường',
        'isMet': password.contains(RegExp(r'[a-z]')),
      },
      {
        'text': 'Ít nhất 1 chữ số',
        'isMet': password.contains(RegExp(r'[0-9]')),
      },
      {
        'text': 'Ít nhất 1 ký tự đặc biệt',
        'isMet': password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
      },
    ];

    // Split requirements into two columns
    final firstColumnReqs = requirements.sublist(0, 3);
    final secondColumnReqs = requirements.sublist(3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Text(
            'Yêu cầu mật khẩu:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: darkMode ? AppColors.muted : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: firstColumnReqs
                    .map((req) => _buildRequirement(
                          req['text'] as String,
                          req['isMet'] as bool,
                        ))
                    .toList(),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: secondColumnReqs
                    .map((req) => _buildRequirement(
                          req['text'] as String,
                          req['isMet'] as bool,
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            color: isMet
                ? Colors.green
                : darkMode
                    ? AppColors.muted
                    : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: isMet
                    ? Colors.green
                    : darkMode
                        ? AppColors.muted
                        : Colors.grey[700],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
