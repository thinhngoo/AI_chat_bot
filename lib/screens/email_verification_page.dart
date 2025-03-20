import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_page.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({Key? key}) : super(key: key);

  @override
  EmailVerificationPageState createState() => EmailVerificationPageState();
}

class EmailVerificationPageState extends State<EmailVerificationPage> {
  final AuthService _authService = AuthService();
  late Timer _timer;
  bool _isEmailVerified = false;

  @override
  void initState() {
    super.initState();
    _isEmailVerified = _authService.isEmailVerified();
    if (!_isEmailVerified) {
      _startVerificationTimer();
    }
  }

  void _startVerificationTimer() {
    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _checkEmailVerified(),
    );
  }

  Future<void> _checkEmailVerified() async {
    await _authService.reloadUser();
    
    if (_authService.isEmailVerified()) {
      setState(() {
        _isEmailVerified = true;
      });
      _timer.cancel();
      
      if (mounted) {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    }
  }

  @override
  void dispose() {
    if (!_isEmailVerified) {
      _timer.cancel();
    }
    super.dispose();
  }

  Future<void> _resendVerificationEmail() async {
    if (!mounted) return;
    
    try {
      final user = _authService.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email xác minh đã được gửi lại')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  Future<void> _backToLogin() async {
    await _authService.signOut();
    
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xác minh email')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Email xác minh đã được gửi đến địa chỉ email của bạn.',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'Vui lòng kiểm tra hộp thư đến và nhấp vào liên kết để xác minh email của bạn.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _resendVerificationEmail,
              child: const Text('Gửi lại email xác minh'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _checkEmailVerified,
              child: const Text('Đã xác minh? Nhấn vào đây'),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _backToLogin,
              child: const Text('Quay lại trang đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }
}
