import 'package:flutter/material.dart';

/// Comprehensive utility class for validating and evaluating inputs
class InputValidator {
  /// Checks if a given password meets the security requirements
  static bool isValidPassword(String password) {
    if (password.length < 8) {
      return false;
    }
    
    // Check for at least one uppercase letter
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return false;
    }
    
    // Check for at least one lowercase letter
    if (!password.contains(RegExp(r'[a-z]'))) {
      return false;
    }
    
    // Check for at least one digit
    if (!password.contains(RegExp(r'[0-9]'))) {
      return false;
    }
    
    // Check for at least one special character
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return false;
    }
    
    return true;
  }
  
  /// Checks if a given email is valid
  static bool isValidEmail(String email) {
    // Simple regex for basic email validation
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
  
  /// Evaluates password strength and returns a string description
  static String getPasswordStrength(String password) {
    if (password.isEmpty) {
      return 'Chưa nhập';
    }
    
    int strength = 0;
    
    // Length check
    if (password.length >= 8) {
      strength++;
    }
    if (password.length >= 12) {
      strength++;
    }
    
    // Character variety checks
    if (password.contains(RegExp(r'[A-Z]'))) {
      strength++;
    }
    if (password.contains(RegExp(r'[a-z]'))) {
      strength++;
    }
    if (password.contains(RegExp(r'[0-9]'))) {
      strength++;
    }
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      strength++;
    }
    
    // Convert strength score to descriptive string
    switch (strength) {
      case 0:
      case 1:
        return 'Rất yếu';
      case 2:
        return 'Yếu';
      case 3:
        return 'Trung bình';
      case 4:
        return 'Mạnh';
      case 5:
      case 6:
        return 'Rất mạnh';
      default:
        return 'Không xác định';
    }
  }
  
  /// Returns an appropriate color for displaying password strength
  static Color getPasswordStrengthColor(String strength) {
    switch (strength) {
      case 'Rất yếu':
        return Colors.red;
      case 'Yếu':
        return Colors.orange;
      case 'Trung bình':
        return Colors.yellow.shade800;
      case 'Mạnh':
        return Colors.lightGreen;
      case 'Rất mạnh':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
  
  /// Returns a ratio (0.0 to 1.0) representing password strength for progress indicators
  static double getPasswordStrengthRatio(String strength) {
    switch (strength) {
      case 'Chưa nhập':
        return 0.0;
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
  
  /// Get a list of password requirements as string descriptions
  static List<String> getRequirementsText() {
    return [
      'Ít nhất 8 ký tự',
      'Ít nhất 1 chữ hoa và 1 chữ thường',
      'Ít nhất 1 chữ số',
      'Ít nhất 1 ký tự đặc biệt (!@#\$%^&*...)'
    ];
  }
  
  // The following methods are from InputValidators class
  
  /// Validate name input (not empty, reasonable length)
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập tên của bạn';
    }
    
    if (value.trim().length < 2) {
      return 'Tên quá ngắn';
    }
    
    if (value.trim().length > 50) {
      return 'Tên quá dài';
    }
    
    return null;
  }
  
  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập email của bạn';
    }
    
    if (!isValidEmail(value.trim())) {
      return 'Email không hợp lệ';
    }
    
    return null;
  }
  
  /// Validate phone number format (Vietnamese phone numbers)
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }
    
    // Vietnamese phone number regex
    // Accepts formats like: 0912345678, 84912345678, +84912345678
    final phoneRegex = RegExp(
      r'^(0|\+84|84)([3|5|7|8|9])([0-9]{8})$',
    );
    
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Số điện thoại không hợp lệ';
    }
    
    return null;
  }
  
  /// Validate that input is not empty
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập $fieldName';
    }
    
    return null;
  }
  
  /// Validate min length of input
  static String? validateMinLength(String? value, int minLength, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập $fieldName';
    }
    
    if (value.trim().length < minLength) {
      return '$fieldName phải có ít nhất $minLength ký tự';
    }
    
    return null;
  }
  
  /// Validate max length of input
  static String? validateMaxLength(String? value, int maxLength, String fieldName) {
    if (value == null) {
      return null;
    }
    
    if (value.trim().length > maxLength) {
      return '$fieldName không được vượt quá $maxLength ký tự';
    }
    
    return null;
  }
  
  /// Validate that input is a number
  static String? validateNumber(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập $fieldName';
    }
    
    if (double.tryParse(value.trim()) == null) {
      return '$fieldName phải là số';
    }
    
    return null;
  }
  
  /// Validate that input is a positive number
  static String? validatePositiveNumber(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập $fieldName';
    }
    
    final number = double.tryParse(value.trim());
    
    if (number == null) {
      return '$fieldName phải là số';
    }
    
    if (number <= 0) {
      return '$fieldName phải là số dương';
    }
    
    return null;
  }
}
