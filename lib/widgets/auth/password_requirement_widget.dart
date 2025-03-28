import 'package:flutter/material.dart';

class PasswordRequirementWidget extends StatelessWidget {
  final String password;
  final bool showTitle;

  const PasswordRequirementWidget({
    super.key,
    required this.password,
    this.showTitle = false,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          const Text(
            'Yêu cầu mật khẩu:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
        ],
        ...requirements.map((req) => _buildRequirement(
          req['text'] as String,
          req['isMet'] as bool,
        )),
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
            color: isMet ? Colors.green : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isMet ? Colors.green : Colors.grey[700],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
