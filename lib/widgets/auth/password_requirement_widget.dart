import 'package:flutter/material.dart';
import '../../core/utils/validators/password_validator.dart';

/// Widget to display password requirements and validation status
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
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle)
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Mật khẩu phải:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          _buildRequirementList(),
        ],
      ),
    );
  }

  Widget _buildRequirementList() {
    final requirements = [
      {
        'text': 'Có ít nhất 8 ký tự',
        'isMet': password.length >= PasswordValidator.minLength,
      },
      {
        'text': 'Có ít nhất 1 chữ hoa (A-Z)',
        'isMet': password.contains(PasswordValidator.upperCaseRegex),
      },
      {
        'text': 'Có ít nhất 1 chữ thường (a-z)',
        'isMet': password.contains(PasswordValidator.lowerCaseRegex),
      },
      {
        'text': 'Có ít nhất 1 chữ số (0-9)',
        'isMet': password.contains(PasswordValidator.digitRegex),
      },
      {
        'text': 'Có ít nhất 1 ký tự đặc biệt (!@#\$...)',
        'isMet': password.contains(PasswordValidator.specialCharRegex),
      },
    ];

    return Column(
      children: requirements.map((req) {
        return _buildRequirementItem(
          req['text'] as String,
          req['isMet'] as bool,
        );
      }).toList(),
    );
  }

  Widget _buildRequirementItem(String text, bool isMet) {
    final metColor = isMet ? Colors.green : Colors.grey;
    final icon = isMet ? Icons.check_circle : Icons.circle_outlined;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: metColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: isMet ? Colors.black87 : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
