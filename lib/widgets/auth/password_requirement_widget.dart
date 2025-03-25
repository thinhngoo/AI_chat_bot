import 'package:flutter/material.dart';

class PasswordRequirements extends StatelessWidget {
  final Map<String, bool> criteria;
  final bool showTitle;

  const PasswordRequirements({
    super.key,
    required this.criteria,
    this.showTitle = false,
  });

  /// Static method to show fixed password requirements
  static Widget static() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Yêu cầu mật khẩu',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
        _buildStaticRequirement('Ít nhất 8 ký tự'),
        _buildStaticRequirement('Ít nhất 1 chữ hoa (A-Z)'),
        _buildStaticRequirement('Ít nhất 1 chữ thường (a-z)'),
        _buildStaticRequirement('Ít nhất 1 chữ số (0-9)'),
        _buildStaticRequirement(r'Ít nhất 1 ký tự đặc biệt (!@#$...)'),
      ],
    );
  }

  /// Helper method for static requirements
  static Widget _buildStaticRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) 
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Yêu cầu mật khẩu',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        _buildRequirement(
          'Ít nhất 8 ký tự', 
          criteria['length'] ?? false,
        ),
        _buildRequirement(
          'Ít nhất 1 chữ hoa (A-Z)', 
          criteria['uppercase'] ?? false,
        ),
        _buildRequirement(
          'Ít nhất 1 chữ thường (a-z)', 
          criteria['lowercase'] ?? false,
        ),
        _buildRequirement(
          'Ít nhất 1 chữ số (0-9)', 
          criteria['number'] ?? false,
        ),
        _buildRequirement(
          r'Ít nhất 1 ký tự đặc biệt (!@#$...)', 
          criteria['special'] ?? false,
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
            color: isMet ? Colors.green : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isMet ? Colors.black87 : Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
