import 'package:flutter/material.dart';
import '../../core/utils/validators/password_validator.dart';

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
    final requirements = PasswordValidator.getRequirementsText();
    
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle) ...[
            const Text(
              'Yêu cầu mật khẩu:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
          ],
          ...requirements.map(
            (requirement) => _buildRequirement(
              requirement,
              _checkRequirement(requirement, password),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            color: isMet ? Colors.green : Colors.grey,
            size: 16.0,
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isMet ? Colors.black : Colors.grey.shade700,
                fontSize: 12.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _checkRequirement(String requirement, String password) {
    if (password.isEmpty) return false;
    
    if (requirement.contains('8 ký tự')) {
      return password.length >= 8;
    } else if (requirement.contains('chữ hoa') && requirement.contains('chữ thường')) {
      return password.contains(RegExp(r'[A-Z]')) && password.contains(RegExp(r'[a-z]'));
    } else if (requirement.contains('chữ số')) {
      return password.contains(RegExp(r'[0-9]'));
    } else if (requirement.contains('ký tự đặc biệt')) {
      return password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    }
    
    return false;
  }
}
