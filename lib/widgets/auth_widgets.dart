import 'package:flutter/material.dart';

class AuthInputField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final bool obscureText;
  final TextInputType keyboardType;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;

  const AuthInputField({
    super.key,
    required this.controller,
    required this.labelText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: labelText),
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
    );
  }
}

class EmailField extends StatelessWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final Function(String)? onChanged;
  final bool autofocus;
  final String? Function(String?)? validator;

  const EmailField({
    super.key,
    required this.controller,
    this.labelText = 'Email',
    this.hintText,
    this.errorText,
    this.onChanged,
    this.autofocus = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        errorText: errorText,
        prefixIcon: const Icon(Icons.email),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      keyboardType: TextInputType.emailAddress,
      autofocus: autofocus,
      onChanged: onChanged,
      validator: validator,
    );
  }
}

class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;

  const PasswordField({
    super.key,
    required this.controller,
    this.labelText = 'Mật khẩu',
    this.hintText,
    this.errorText,
    this.onChanged,
    this.validator,
  });

  @override
  PasswordFieldState createState() => PasswordFieldState();
}

class PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        errorText: widget.errorText,
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      obscureText: _obscureText,
      onChanged: widget.onChanged,
      validator: widget.validator,
    );
  }
}

class SubmitButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color? color;

  const SubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: const TextStyle(fontSize: 16),
              ),
      ),
    );
  }
}

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        icon: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : Image.network(
                'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
                height: 24,
              ),
        label: const Text('Đăng nhập với Google'),
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

// Helper validators
class AuthValidators {
  // Email validation
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

  // Password validation
  static bool isValidPassword(String password) {
    // Check for minimum length
    if (password.length < 8) return false;
    
    // Check for uppercase letters
    if (!RegExp(r'[A-Z]').hasMatch(password)) return false;
    
    // Check for lowercase letters
    if (!RegExp(r'[a-z]').hasMatch(password)) return false;
    
    // Check for numbers
    if (!RegExp(r'[0-9]').hasMatch(password)) return false;
    
    // Check for special characters - properly escaped
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) return false;
    
    return true;
  }

  // Password strength evaluation
  static String getPasswordStrength(String password) {
    if (password.isEmpty) return 'Trống';
    if (password.length < 6) return 'Rất yếu';
    if (password.length < 8) return 'Yếu';
    if (!RegExp(r'[A-Z]').hasMatch(password)) return 'Trung bình (thêm chữ hoa)';
    if (!RegExp(r'[a-z]').hasMatch(password)) return 'Trung bình (thêm chữ thường)';
    if (!RegExp(r'[0-9]').hasMatch(password)) return 'Trung bình (thêm số)';
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) return 'Khá (thêm ký tự đặc biệt)';
    return 'Mạnh';
  }

  // Get color for password strength indicator
  static Color getPasswordStrengthColor(String strength) {
    switch (strength) {
      case 'Trống': return Colors.grey;
      case 'Rất yếu': return Colors.red;
      case 'Yếu': return Colors.orange;
      case 'Trung bình (thêm chữ hoa)':
      case 'Trung bình (thêm chữ thường)':
      case 'Trung bình (thêm số)': return Colors.yellow;
      case 'Khá (thêm ký tự đặc biệt)': return Colors.lightGreen;
      case 'Mạnh': return Colors.green;
      default: return Colors.grey;
    }
  }

  // Get ratio for password strength progress indicator
  static double getPasswordStrengthRatio(String strength) {
    switch (strength) {
      case 'Trống': return 0.0;
      case 'Rất yếu': return 0.2;
      case 'Yếu': return 0.4;
      case 'Trung bình (thêm chữ hoa)':
      case 'Trung bình (thêm chữ thường)':
      case 'Trung bình (thêm số)': return 0.6;
      case 'Khá (thêm ký tự đặc biệt)': return 0.8;
      case 'Mạnh': return 1.0;
      default: return 0.0;
    }
  }
}
