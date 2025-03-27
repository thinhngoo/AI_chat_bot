/// Utility class for validating various input fields
class InputValidators {
  /// Validates if the provided string is a valid email
  static bool isValidEmail(String email) {
    // Regular expression for validating email address
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegExp.hasMatch(email);
  }
  
  /// Validates if string is not empty
  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
  
  /// Validates if the provided string is a valid name
  static bool isValidName(String name) {
    // At least 2 characters, only letters, spaces, and common name characters
    final nameRegExp = RegExp(r"^[a-zA-ZÀ-ỹ\s'.-]{2,}$");
    return nameRegExp.hasMatch(name);
  }
  
  /// Validates if the provided string is a valid phone number
  static bool isValidPhone(String phone) {
    // Simple validation for phone numbers
    // Accepts numbers with optional +, (), and - characters
    final phoneRegExp = RegExp(r'^\+?[0-9()\-\s]{8,}$');
    return phoneRegExp.hasMatch(phone);
  }
  
  /// Validates minimum string length
  static bool hasMinLength(String value, int minLength) {
    return value.length >= minLength;
  }
  
  /// Validates maximum string length
  static bool hasMaxLength(String value, int maxLength) {
    return value.length <= maxLength;
  }
}
