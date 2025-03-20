import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  SignUpPageState createState() => SignUpPageState();
}

class SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool isValidPassword(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false; // Chữ hoa
    if (!password.contains(RegExp(r'[a-z]'))) return false; // Chữ thường
    if (!password.contains(RegExp(r'[0-9]'))) return false; // Số
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false; // Ký tự đặc biệt
    return true;
  }

  String getPasswordStrength(String password) {
    if (password.isEmpty) return 'Nhập mật khẩu';
    if (password.length < 6) return 'Yếu';
    if (password.length < 8) return 'Trung bình';
    if (isValidPassword(password)) return 'Mạnh';
    return 'Trung bình';
  }

  Color getPasswordStrengthColor(String strength) {
    switch (strength) {
      case 'Yếu':
        return Colors.red;
      case 'Trung bình':
        return Colors.orange;
      case 'Mạnh':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _signUp() async {
    if (!isValidEmail(_emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email không hợp lệ')),
      );
      return;
    }
    if (!isValidPassword(_passwordController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu không hợp lệ. Phải có ít nhất 8 ký tự, bao gồm chữ hoa, chữ thường, số và ký tự đặc biệt.')),
      );
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu không khớp')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _authService.signUpWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng ký thành công! Vui lòng kiểm tra email để xác minh tài khoản.')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      if (!mounted) return;
      String errorMessage;
      if (e.toString().contains('Email already exists')) {
        errorMessage = 'Email đã được sử dụng.';
      } else {
        errorMessage = 'Đã xảy ra lỗi khi đăng ký. Vui lòng thử lại.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : Column(
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Mật khẩu'),
                  obscureText: true,
                  onChanged: (value) {
                    setState(() {}); // Update UI when typing
                  },
                ),
                Text(
                  'Độ mạnh mật khẩu: ${getPasswordStrength(_passwordController.text)}',
                  style: TextStyle(
                    color: getPasswordStrengthColor(getPasswordStrength(_passwordController.text)),
                  ),
                ),
                TextField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu'),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _signUp,
                  child: const Text('Đăng ký'),
                ),
              ],
            ),
      ),
    );
  }
}