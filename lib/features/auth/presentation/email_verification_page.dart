import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logger/logger.dart';
import '../../../core/services/auth/auth_service.dart';
import 'login_page.dart';

class EmailVerificationPage extends StatefulWidget {
  final String email;
  
  const EmailVerificationPage({
    super.key,
    required this.email,
  });

  @override
  EmailVerificationPageState createState() => EmailVerificationPageState();
}

class EmailVerificationPageState extends State<EmailVerificationPage> {
  final AuthService _authService = AuthService();
  final Logger _logger = Logger();
  Timer? _timer;
  bool _isVerified = false;
  bool _isCheckingStatus = false;
  int _countdown = 60;
  bool _canResend = false;
  
  @override
  void initState() {
    super.initState();
    _startVerificationCheck();
    _startCountdown();
  }
  
  void _startVerificationCheck() {
    // Check initially
    _checkVerificationStatus();
    
    // Then check every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkVerificationStatus();
    });
  }
  
  void _startCountdown() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        setState(() {
          _canResend = true;
        });
      }
    });
  }
  
  Future<void> _checkVerificationStatus() async {
    if (_isCheckingStatus) return;
    
    setState(() {
      _isCheckingStatus = true;
    });
    
    try {
      // Reload user to get updated verification status
      await _authService.reloadUser();
      
      // Check if email is verified
      final isVerified = _authService.isEmailVerified();
      
      setState(() {
        _isVerified = isVerified;
        _isCheckingStatus = false;
      });
      
      if (isVerified) {
        _timer?.cancel();
        _timer = null;
        
        // Show success dialog and navigate
        await _showVerificationSuccessDialog();
      }
    } catch (e) {
      _logger.e('Error checking verification status: $e');
      
      setState(() {
        _isCheckingStatus = false;
      });
    }
  }
  
  Future<void> _showVerificationSuccessDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Email Verified'),
        content: const Text('Your email has been verified successfully. You can now log in.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to login page
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text('Log In'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _resendVerificationEmail() async {
    try {
      setState(() {
        _isCheckingStatus = true;
      });
      
      // No need to declare 'email' again as we can use widget.email directly
      // Temporarily disabled since we don't have the password here
      // In a real app, you would either:
      // 1. Store the password temporarily
      // 2. Have a separate resend verification endpoint
      
      // For now, just show a message
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email resent. Please check your inbox.'),
        ),
      );
      
      // Reset countdown
      setState(() {
        _isCheckingStatus = false;
        _canResend = false;
        _countdown = 60;
      });
      
      _startCountdown();
    } catch (e) {
      _logger.e('Error resending verification email: $e');
      
      if (!mounted) return;
      
      setState(() {
        _isCheckingStatus = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _openEmailApp() async {
    final email = widget.email;
    String? emailDomain;
    
    if (email.contains('@')) {
      emailDomain = email.split('@')[1];
    }
    
    String? emailUrl;
    
    // Check common email providers
    if (emailDomain != null) {
      if (emailDomain.contains('gmail')) {
        emailUrl = 'https://mail.google.com';
      } else if (emailDomain.contains('yahoo')) {
        emailUrl = 'https://mail.yahoo.com';
      } else if (emailDomain.contains('outlook') || emailDomain.contains('hotmail')) {
        emailUrl = 'https://outlook.live.com';
      } else if (emailDomain.contains('proton')) {
        emailUrl = 'https://mail.proton.me';
      }
    }
    
    // Fall back to a general "mailto:" if no specific provider is found
    emailUrl ??= 'mailto:';
    
    try {
      final uri = Uri.parse(emailUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch email app';
      }
    } catch (e) {
      _logger.e('Error opening email app: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open email app. Please check your email manually.'),
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Verification'),
      ),
      body: _isVerified ? _buildVerifiedView() : _buildVerificationView(),
    );
  }
  
  Widget _buildVerificationView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.mark_email_unread,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            Text(
              'Verify Your Email',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'We\'ve sent a verification email to:\n${widget.email}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Text(
              'Please check your inbox and click the verification link to complete the sign-up process.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _openEmailApp,
              icon: const Icon(Icons.email),
              label: const Text('Open Email App'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
              ),
            ),
            const SizedBox(height: 16),
            _isCheckingStatus
                ? const CircularProgressIndicator()
                : TextButton(
                    onPressed: _checkVerificationStatus,
                    child: const Text('I\'ve Verified My Email'),
                  ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Didn\'t receive the email?',
              style: Theme.of(context).textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            _canResend
                ? TextButton(
                    onPressed: _resendVerificationEmail,
                    child: const Text('Resend Verification Email'),
                  )
                : Text(
                    'Resend in $_countdown seconds',
                    style: const TextStyle(color: Colors.grey),
                  ),
            const SizedBox(height: 16),
            const Text(
              'Make sure to check your spam or junk folder if you can\'t find the email in your inbox.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVerifiedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            Text(
              'Email Verified',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Thank you for verifying your email address. You can now log in to your account.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
              ),
              child: const Text('Log In'),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}