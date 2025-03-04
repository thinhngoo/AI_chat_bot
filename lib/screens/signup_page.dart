import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key); // Add key parameter

  @override
  SignUpPageState createState() => SignUpPageState(); // Make state class public
}

class SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();

  Future<void> _signUp() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      if (!mounted) return; // Ensure context is mounted before using it
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu không khớp')),
      );
      return;
    }
    try {
      await _authService.signUpWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (!mounted) return; // Ensure context is mounted before using it
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng ký thành công! Vui lòng kiểm tra email.')),
      );
      if (!mounted) return; // Check if the state is still mounted
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()), // Add const
      );
    } catch (e) {
      if (!mounted) return; // Ensure context is mounted before using it
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký')), // Add const
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Add const
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'), // Add const
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Mật khẩu'), // Add const
              obscureText: true,
            ),
            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu'), // Add const
              obscureText: true,
            ),
            const SizedBox(height: 20), // Add const
            ElevatedButton(
              onPressed: _signUp,
              child: const Text('Đăng ký'), // Add const
            ),
          ],
        ),
      ),
    );
  }
}