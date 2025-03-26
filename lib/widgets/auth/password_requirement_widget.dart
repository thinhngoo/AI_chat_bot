import 'package:flutter/material.dart';
import '../../core/utils/validators/password_validator.dart';

/// Widget to display password requirements and validation status
class PasswordRequirementWidget extends StatelessWidget {
  final String password;
  final bool showTitle;
  
  const PasswordRequirementWidget({
    super.key, // Use super parameter instead of Key? key
    required this.password,
    this.showTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final requirements = PasswordValidator.getRequirementsText();
    final hasUpperLower = password.contains(RegExp(r'[A-Z]')) && password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    final hasMinLength = password.length >= PasswordValidator.minLength;
    
    final validations = [
      hasMinLength,
      hasUpperLower,
      hasDigit,
      hasSpecial,
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle)
          const Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Yêu cầu mật khẩu:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        for (int i = 0; i < requirements.length; i++)
          _buildRequirementItem(
            requirements[i],
            password.isEmpty ? null : validations[i],
          ),
      ],
    );
  }
  
  Widget _buildRequirementItem(String text, bool? isValid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: _getIcon(isValid),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: _getColor(isValid),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _getIcon(bool? isValid) {
    if (isValid == null) {
      return const Icon(Icons.circle_outlined, size: 16, color: Colors.grey);
    } else if (isValid) {
      return const Icon(Icons.check_circle, size: 16, color: Colors.green);
    } else {
      return const Icon(Icons.cancel, size: 16, color: Colors.red);
    }
  }
  
  Color _getColor(bool? isValid) {
    if (isValid == null) {
      return Colors.grey.shade700;
    } else if (isValid) {
      return Colors.green.shade900;
    } else {
      return Colors.red.shade900;
    }
  }
}
