import 'package:flutter/material.dart';

class PasswordRequirementWidget extends StatelessWidget {
  final String password;
  final List<String> requirements;
  final bool showTitle;
  final String title;
  
  const PasswordRequirementWidget({
    super.key,
    required this.password,
    this.requirements = const [
      'Ít nhất 8 ký tự',
      'Có ít nhất 1 chữ hoa và 1 chữ thường',
      'Có ít nhất 1 chữ số',
      'Có ít nhất 1 ký tự đặc biệt (@, !, #, v.v.)',
    ],
    this.showTitle = true,
    this.title = 'Yêu cầu mật khẩu:',
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, bool> actualCriteria = {
      'length': password.length >= 8,
      'uppercase': password.contains(RegExp(r'[A-Z]')),
      'lowercase': password.contains(RegExp(r'[a-z]')),
      'number': password.contains(RegExp(r'[0-9]')),
      'special': password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
    };
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle)
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        if (showTitle)
          const SizedBox(height: 8),
        ...requirements.map((requirement) {
          final bool isMet = _isRequirementMet(requirement, actualCriteria);
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(
                  isMet ? Icons.check_circle : Icons.circle_outlined,
                  color: isMet ? Colors.green : Colors.grey,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    requirement,
                    style: TextStyle(
                      color: isMet ? Colors.green : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
  
  bool _isRequirementMet(String requirement, Map<String, bool> criteria) {
    if (requirement.contains('8 ký tự')) {
      return criteria['length'] ?? false;
    } else if (requirement.contains('chữ hoa') && requirement.contains('chữ thường')) {
      return (criteria['uppercase'] ?? false) && (criteria['lowercase'] ?? false);
    } else if (requirement.contains('chữ số')) {
      return criteria['number'] ?? false;
    } else if (requirement.contains('ký tự đặc biệt')) {
      return criteria['special'] ?? false;
    }
    return false;
  }
}
