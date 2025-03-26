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
  bool _isEmailVerified = false;
  bool _canResendEmail = true;
  int _resendCooldown = 0;
  Timer? _resendTimer;
  bool _isChecking = false;
  DateTime _lastManualCheck = DateTime.now();
  bool _linkExpired = false;
  int _verificationCheckCount = 0;

  @override
  void initState() {
    super.initState();
    _isEmailVerified = _authService.isEmailVerified();
    if (!_isEmailVerified) {
      _startVerificationTimer();
    }
  }

  void _startVerificationTimer() {
    // Check every 15 seconds instead of 10 to reduce API calls
    _timer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _checkEmailVerified(isManualCheck: false),
    );
  }

  Future<void> _checkEmailVerified({bool isManualCheck = true}) async {
    // Rate limiting for manual checks (only allow every 5 seconds)
    if (isManualCheck) {
      final now = DateTime.now();
      if (now.difference(_lastManualCheck).inSeconds < 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng đợi ít nhất 5 giây giữa các lần kiểm tra')),
        );
        return;
      }
      _lastManualCheck = now;
    }
    
    if (_isChecking) return;
    
    setState(() {
      _isChecking = true;
    });
    
    try {
      await _authService.reloadUser();
      
      if (!mounted) return;
      
      // Check verification status
      bool verified = _authService.isEmailVerified();
      _logger.i('Email verification status: $verified');
      
      // Update state with verification result
      setState(() {
        _isEmailVerified = verified;
        _isChecking = false;
        
        // Increment check count for non-manual checks to track frequency
        if (!isManualCheck) {
          _verificationCheckCount++;
          
          // After many checks without success, consider the link expired
          if (_verificationCheckCount > 20 && !_isEmailVerified) {
            _linkExpired = true;
          }
        }
      });
      
      // Handle verification success
      if (_isEmailVerified) {
        _logger.i('Email verification confirmed');
        _timer?.cancel();
        
        // Navigate to home page or show success message
        if (isManualCheck) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email đã được xác minh thành công!')),
          );
          
          // Slight delay before navigating away to show the success message
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/home');
            }
          });
        }
      } else if (isManualCheck) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email chưa được xác minh. Vui lòng kiểm tra hộp thư của bạn.')),
        );
      }
    } catch (e) {
      _logger.e('Email verification check error: $e');
      if (!mounted) return;
      
      setState(() {
        _isChecking = false;
      });
      
      // Only show error messages for manual checks
      if (isManualCheck) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi kiểm tra xác minh email: ${e.toString()}')),
        );
      }
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
    _timer?.cancel();
    _resendTimer?.cancel();
    super.dispose();
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResendEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng đợi $_resendCooldown giây trước khi gửi lại')),
      );
      return;
    }
    
    setState(() {
      _isChecking = true; // Use existing loading indicator
    });
    
    try {
      // Check if there is a logged in user first
      if (_authService.currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phiên đã hết hạn. Đang chuyển về trang đăng nhập...')),
        );
        
        // Navigate back to login page after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          }
        });
        return;
      }
      
      // Reset expired link status
      setState(() {
        _linkExpired = false;
        _verificationCheckCount = 0;
      });
      
      await _authService.resendVerificationEmail();
      
      if (!mounted) return;
      
      _startResendCooldown();
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Email đã gửi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Email xác minh mới đã được gửi đến ${_maskEmail(widget.email)}.'),
              const SizedBox(height: 8),
              const Text('Lưu ý:', style: TextStyle(fontWeight: FontWeight.bold)),
              const Text('• Kiểm tra thư mục Spam nếu bạn không thấy email'),
              const Text('• Email có thể mất vài phút để đến'),
              const Text('• Liên kết xác minh có hiệu lực trong 24 giờ'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _openEmailApp();
              },
              child: const Text('Mở ứng dụng Email'),
            ),
          ],
        ),
      );
    } catch (e) {
      _logger.e('Error resending verification email: $e');
      if (!mounted) return;
      
      String errorMessage = 'Không thể gửi lại email xác minh';
      
      if (e.toString().contains('too-many-requests')) {
        errorMessage = 'Quá nhiều yêu cầu. Vui lòng thử lại sau vài phút';
      } else if (e.toString().contains('network-request-failed')) {
        errorMessage = 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet';
      } else if (e.toString().contains('Người dùng chưa đăng nhập')) {
        errorMessage = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại';
        
        // Navigate back to login after a delay
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          }
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _openEmailApp() async {
    setState(() {
      _isChecking = true;
    });
    
    try {
      // Get email provider
      final emailProvider = _detectEmailProvider(widget.email);
      final Uri? emailUri = _getEmailProviderUri(emailProvider);
      
      if (emailUri != null) {
        final success = await launchUrl(
          emailUri,
          mode: LaunchMode.externalApplication,
        );
        
        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể mở ứng dụng email. Vui lòng kiểm tra thủ công.')),
          );
        }
      } else {
        // Fallback to generic mailto
        final Uri mailtoUri = Uri(scheme: 'mailto', path: '');
        await launchUrl(mailtoUri);
      }
    } catch (e) {
      _logger.e('Error opening email app: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở ứng dụng email. Vui lòng kiểm tra thủ công.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }
  
  Future<void> _openSpamFolder() async {
    setState(() {
      _isChecking = true;
    });
    
    try {
      // Get email provider
      final emailProvider = _detectEmailProvider(widget.email);
      final Uri? spamUri = _getSpamFolderUri(emailProvider);
      
      if (spamUri != null) {
        final success = await launchUrl(
          spamUri,
          mode: LaunchMode.externalApplication,
        );
        
        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể mở thư mục spam. Vui lòng kiểm tra thủ công.')),
          );
        }
      } else {
        // Fallback to generic spam instructions
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Kiểm tra thư mục Spam'),
              content: const Text(
                'Vui lòng mở ứng dụng email của bạn và kiểm tra thư mục "Spam", "Junk Mail", hoặc "Rác" để tìm email xác minh.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      _logger.e('Error opening spam folder: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở thư mục spam. Vui lòng kiểm tra thủ công.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _backToLogin() async {
    try {
      await _authService.signOut();
    } catch (e) {
      _logger.e('Error signing out: $e');
    } finally {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }
  
  // Helper methods for email providers - Fix style warning by adding braces
  String _detectEmailProvider(String email) {
    email = email.toLowerCase();
    
    if (email.endsWith('@gmail.com')) {
      return 'gmail';
    }
    if (email.endsWith('@yahoo.com')) {
      return 'yahoo';
    }
    if (email.endsWith('@outlook.com') || 
        email.endsWith('@hotmail.com') || 
        email.endsWith('@live.com')) {
      return 'outlook';
    }
    
    return 'other';
  }
  
  Uri? _getEmailProviderUri(String provider) {
    switch (provider) {
      case 'gmail':
        return Uri.parse('https://mail.google.com/');
      case 'yahoo':
        return Uri.parse('https://mail.yahoo.com/');
      case 'outlook':
        return Uri.parse('https://outlook.live.com/mail/');
      default:
        return null;
    }
  }
  
  Uri? _getSpamFolderUri(String provider) {
    switch (provider) {
      case 'gmail':
        return Uri.parse('https://mail.google.com/mail/u/0/#spam');
      case 'yahoo':
        return Uri.parse('https://mail.yahoo.com/d/folders/6');
      case 'outlook':
        return Uri.parse('https://outlook.live.com/mail/junkemail');
      default:
        return null;
    }
  }
  
  // Helper method to mask email for privacy
  String _maskEmail(String email) {
    if (email.isEmpty || !email.contains('@')) return email;
    
    final atIndex = email.indexOf('@');
    final name = email.substring(0, atIndex);
    final domain = email.substring(atIndex);
    
    if (name.length <= 2) return email;
    
    return '${name.substring(0, 2)}${'*' * (name.length - 2)}$domain';
  }

  @override
  Widget build(BuildContext context) {
    final maskedEmail = _maskEmail(widget.email);
    final emailProvider = _detectEmailProvider(widget.email);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Xác minh email')),
      body: SingleChildScrollView(
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
              'Một email xác minh đã được gửi đến\n$maskedEmail',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'Vui lòng kiểm tra email và nhấp vào liên kết xác minh.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            
            if (_linkExpired) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Liên kết có thể đã hết hạn',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Bạn đã chờ quá lâu và liên kết xác minh có thể đã hết hạn. Hãy gửi lại email xác minh.'),
                  ],
                ),
              ),
            ],
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lưu ý:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text('• Email có thể mất vài phút để đến'),
                  const Text('• Email xác minh thường bị lọc vào thư mục SPAM'),
                  const Text('• Liên kết xác minh có hiệu lực trong 24 giờ'),
                  if (emailProvider == 'gmail')
                    const Text('• Đối với Gmail, kiểm tra cả thẻ "Quảng cáo" và "Diễn đàn"')
                  else if (emailProvider == 'yahoo')
                    const Text('• Đối với Yahoo Mail, kiểm tra mục "Bulk Mail"')
                  else if (emailProvider == 'outlook')
                    const Text('• Đối với Outlook, kiểm tra mục "Junk Email"'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.email_outlined),
              label: Text('Mở ${_getEmailProviderName(emailProvider)}'),
              onPressed: _isChecking ? null : _openEmailApp,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
                disabledBackgroundColor: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.report_outlined),
              label: const Text('Kiểm tra thư mục Spam'),
              onPressed: _isChecking ? null : _openSpamFolder,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
                backgroundColor: Colors.amber,
                disabledBackgroundColor: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            _isChecking 
                ? Column(
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(height: 10),
                      Text('Đang kiểm tra...'),
                    ],
                  )
                : TextButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tôi đã xác minh email. Kiểm tra lại'),
                    onPressed: () => _checkEmailVerified(isManualCheck: true),
                  ),
            const SizedBox(height: 10),
            _canResendEmail
                ? TextButton.icon(
                    icon: const Icon(Icons.send),
                    label: const Text('Gửi lại email xác minh'),
                    onPressed: _isChecking ? null : _resendVerificationEmail,
                  )
                : Text('Gửi lại sau $_resendCooldown giây'),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _isChecking ? null : _backToLogin,
              child: const Text('Quay lại trang đăng nhập'),
            ),
            if (_verificationCheckCount > 5 && !_isEmailVerified) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Đã xác minh nhưng vẫn gặp lỗi?',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Nếu bạn đã xác minh email nhưng ứng dụng vẫn không nhận ra, '
                      'hãy thử bấm nút dưới đây để bỏ qua bước xác minh:',
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.verified_user),
                      label: const Text('Đánh dấu đã xác minh và tiếp tục'),
                      onPressed: _isChecking ? null : _manualVerificationOverride,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  String _getEmailProviderName(String provider) {
    switch (provider) {
      case 'gmail':
        return 'Gmail';
      case 'yahoo':
        return 'Yahoo Mail';
      case 'outlook':
        return 'Outlook';
      default:
        return 'Ứng dụng Email';
    }
  }
  
  Future<void> _manualVerificationOverride() async {
    setState(() {
      _isChecking = true;
    });
    
    try {
      _logger.i('User requested manual verification override');
      
      // First try to refresh tokens to ensure we have fresh data
      await _authService.reloadUser();
      
      // Manually set the email as verified
      await _authService.manuallySetEmailVerified();
      
      _timer?.cancel();
      _timer = null;
      
      setState(() {
        _isEmailVerified = true;
        _isChecking = false;
      });
      
      if (!mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã đánh dấu email là đã xác minh')),
      );
      
      // Navigate to home page after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      });
    } catch (e) {
      _logger.e('Manual verification override failed: $e');
      
      if (!mounted) return;
      
      setState(() {
        _isChecking = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể bỏ qua xác minh: ${e.toString()}')),
      );
    }
  }
}