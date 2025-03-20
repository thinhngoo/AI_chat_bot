import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import 'home_page.dart';
import 'login_page.dart';

class EmailVerificationPage extends StatefulWidget {
  final String email;
  const EmailVerificationPage({Key? key, required this.email}) : super(key: key);

  @override
  EmailVerificationPageState createState() => EmailVerificationPageState();
}

class EmailVerificationPageState extends State<EmailVerificationPage> {
  final AuthService _authService = AuthService();
  late Timer _timer;
  bool _isEmailVerified = false;
  bool _canResendEmail = true;
  int _resendCooldown = 0;
  late Timer _resendTimer;
  bool _isChecking = false;

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
    if (_isChecking) return;
    
    setState(() {
      _isChecking = true;
    });
    
    await _authService.reloadUser();
    
    if (!mounted) return;
    
    bool verified = _authService.isEmailVerified();
    
    setState(() {
      _isEmailVerified = verified;
      _isChecking = false;
    });
    
    if (_isEmailVerified) {
      _timer.cancel();
      // Show success dialog before navigation
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Xác minh thành công!'),
            content: const Text('Email của bạn đã được xác minh. Bạn có thể đăng nhập ngay bây giờ.'),
            actions: [
              TextButton(
                child: const Text('Đăng nhập'),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context, 
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
              ),
            ],
          );
        },
      );
    }
  }
  
  void _startResendCooldown() {
    setState(() {
      _canResendEmail = false;
      _resendCooldown = 60;
    });
    
    _resendTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        setState(() {
          if (_resendCooldown > 0) {
            _resendCooldown--;
          } else {
            _canResendEmail = true;
            timer.cancel();
          }
        });
      },
    );
  }

  @override
  void dispose() {
    if (!_isEmailVerified) {
      _timer.cancel();
    }
    if (_resendCooldown > 0) {
      _resendTimer.cancel();
    }
    super.dispose();
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResendEmail) return;
    
    try {
      // First sign out and sign back in to refresh the token
      final email = widget.email;
      await _authService.resendVerificationEmail();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email xác minh đã được gửi lại. Vui lòng kiểm tra cả thư mục Spam.')),
      );
      
      _startResendCooldown();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  Future<void> _openEmailApp() async {
    // Try to open Gmail or other email apps
    Uri emailUri;
    
    if (widget.email.endsWith('@gmail.com')) {
      // Gmail specific link
      emailUri = Uri.parse('https://mail.google.com/');
    } else {
      // Generic mailto link
      emailUri = Uri.parse('mailto:');
    }
    
    try {
      await launchUrl(emailUri);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở ứng dụng email')),
      );
    }
  }
  
  Future<void> _openSpamFolder() async {
    // Try to open Gmail spam folder
    final Uri spamUri = Uri.parse('https://mail.google.com/mail/u/0/#spam');
    
    try {
      await launchUrl(spamUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở thư mục Spam')),
      );
    }
  }

  Future<void> _backToLogin() async {
    await _authService.signOut();
    
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
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
            const Icon(
              Icons.mark_email_unread_outlined,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            Text(
              'Một email xác minh đã được gửi đến\n${widget.email}',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'Vui lòng kiểm tra email và nhấp vào liên kết xác minh.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lưu ý:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('• Email có thể mất vài phút để đến'),
                  Text('• Email xác minh thường bị lọc vào thư mục SPAM'),
                  Text('• Kiểm tra tất cả các thư mục trong email của bạn'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.email_outlined),
              label: const Text('Mở ứng dụng Email'),
              onPressed: _openEmailApp,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.report_outlined),
              label: const Text('Kiểm tra thư mục Spam'),
              onPressed: _openSpamFolder,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
                backgroundColor: Colors.amber,
              ),
            ),
            const SizedBox(height: 10),
            _isChecking 
                ? const CircularProgressIndicator()
                : TextButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tôi đã xác minh email. Kiểm tra lại'),
                    onPressed: _checkEmailVerified,
                  ),
            const SizedBox(height: 10),
            _canResendEmail
                ? TextButton.icon(
                    icon: const Icon(Icons.send),
                    label: const Text('Gửi lại email xác minh'),
                    onPressed: _resendVerificationEmail,
                  )
                : Text('Gửi lại sau $_resendCooldown giây'),
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
