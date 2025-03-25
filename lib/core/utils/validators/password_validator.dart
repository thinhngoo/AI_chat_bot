import 'package:flutter/material.dart';

/// Centralized password validation utility class
class PasswordValidator {
  /// Define standard password requirements that will be used throughout the app
  static const int minLength = 8;
  static final RegExp upperCaseRegex = RegExp(r'[A-Z]');
  static final RegExp lowerCaseRegex = RegExp(r'[a-z]');
  static final RegExp digitRegex = RegExp(r'[0-9]');
  static final RegExp specialCharRegex = RegExp(r'[!@#$%^&*(),.?":{}|<>]');

  /// Check password strength and return score (0.0 to 1.0)
  static double calculateStrength(String password) {
    if (password.isEmpty) return 0.0;
    
    double strength = 0.0;
    
    // Length check
    if (password.length >= minLength) strength += 0.25;
    
    // Contains uppercase and lowercase
    if (password.contains(upperCaseRegex) && password.contains(lowerCaseRegex)) {
      strength += 0.25;
    }
    
    // Contains numbers
    if (password.contains(digitRegex)) strength += 0.25;
    
    // Contains special characters
    if (password.contains(specialCharRegex)) strength += 0.25;
    
    return strength;
  }

  /// Get the strength label based on score
  static String getStrengthText(double strength) {
    if (strength <= 0.0) return 'Chưa nhập mật khẩu';
    if (strength <= 0.25) return 'Yếu';
    if (strength <= 0.5) return 'Trung bình';
    if (strength <= 0.75) return 'Khá mạnh';
    return 'Mạnh';
  }

  /// Check if a password meets all requirements (for validation)
  static bool meetsAllRequirements(String password) {
    return password.length >= minLength &&
           password.contains(upperCaseRegex) &&
           password.contains(lowerCaseRegex) &&
           password.contains(digitRegex) &&
           password.contains(specialCharRegex);
  }

  /// Get list of requirements that are not met
  static List<String> getUnmetRequirements(String password) {
    final List<String> unmetRequirements = [];
    
    if (password.length < minLength) {
      unmetRequirements.add('Mật khẩu phải có ít nhất $minLength ký tự');
    }
    
    if (!password.contains(upperCaseRegex) || !password.contains(lowerCaseRegex)) {
      unmetRequirements.add('Mật khẩu phải có chữ hoa và chữ thường');
    }
    
    if (!password.contains(digitRegex)) {
      unmetRequirements.add('Mật khẩu phải có ít nhất một chữ số');
    }
    
    if (!password.contains(specialCharRegex)) {
      unmetRequirements.add('Mật khẩu phải có ít nhất một ký tự đặc biệt');
    }
    
    return unmetRequirements;
  }

  /// Validate password against requirements
  static Map<String, dynamic> validate(String password, {String? confirmPassword}) {
    final Map<String, dynamic> result = {
      'isValid': true,
      'errorMessage': null,
      'confirmErrorMessage': null,
    };
    
    // Check if password is empty
    if (password.isEmpty) {
      result['isValid'] = false;
      result['errorMessage'] = 'Vui lòng nhập mật khẩu';
      return result;
    }
    
    // Check for all requirements
    List<String> unmetRequirements = getUnmetRequirements(password);
    if (unmetRequirements.isNotEmpty) {
      result['isValid'] = false;
      result['errorMessage'] = unmetRequirements.first; // Return first error
      return result;
    }
    
    // Check if passwords match (if confirmPassword is provided)
    if (confirmPassword != null && password != confirmPassword) {
      result['isValid'] = false;
      result['confirmErrorMessage'] = 'Mật khẩu xác nhận không khớp';
    }
    
    return result;
  }
  
  /// Get standard password requirements text for UI displays
  static List<String> getRequirementsText() {
    return [
      'Ít nhất $minLength ký tự',
      'Có ít nhất 1 chữ hoa và 1 chữ thường',
      'Có ít nhất 1 chữ số',
      'Có ít nhất 1 ký tự đặc biệt (@, !, #, v.v.)',
    ];
  }

  /// Checks if a password meets all security requirements
  static bool isValidPassword(String password) {
    return password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[0-9]')) &&
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  }

  /// Gets a text description of password strength
  static String getPasswordStrength(String password) {
    if (password.isEmpty) return '';

    int score = 0;
    
    // Length check
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    
    // Character type checks
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;
    
    switch (score) {
      case 0:
      case 1:
        return 'Rất yếu';
      case 2:
      case 3:
        return 'Yếu';
      case 4:
        return 'Trung bình';
      case 5:
        return 'Mạnh';
      case 6:
      default:
        return 'Rất mạnh';
    }
  }

  /// Gets a color corresponding to password strength
  static Color getPasswordStrengthColor(String strength) {
    switch (strength) {
      case 'Rất yếu':
        return Colors.red.shade800;
      case 'Yếu':
        return Colors.orange;
      case 'Trung bình':
        return Colors.yellow.shade800;
      case 'Mạnh':
        return Colors.green;
      case 'Rất mạnh':
        return Colors.green.shade700;
      default:
        return Colors.grey;
    }
  }
  
  /// Gets a ratio (0.0 to 1.0) for password strength progress indicator
  static double getPasswordStrengthRatio(String strength) {
    switch (strength) {
      case 'Rất yếu':
        return 0.2;
      case 'Yếu':
        return 0.4;
      case 'Trung bình':
        return 0.6;
      case 'Mạnh':
        return 0.8;
      case 'Rất mạnh':
        return 1.0;
      default:
        return 0.0;
    }
  }

  /// Email validation
  static bool isValidEmail(String email) {
    // Kiểm tra chuỗi email rỗng
    if (email.isEmpty) {
      return false;
    }
    
    try {
      final RegExp emailRegExp = RegExp(
        r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$",
      );
      return emailRegExp.hasMatch(email);
    } catch (e) {
      // Nếu có lỗi xảy ra, trả về false (hoặc ghi log lỗi nếu cần)
      return false;
    }
  }
}

// For backward compatibility with code using AuthValidators
class AuthValidators extends PasswordValidator {}
