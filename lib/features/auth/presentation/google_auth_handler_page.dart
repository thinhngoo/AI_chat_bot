import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../../chat/presentation/home_page.dart';

class GoogleAuthHandlerPage extends StatefulWidget {
  final Map<String, String> params;
  
  const GoogleAuthHandlerPage({
    super.key,
    required this.params,
  });

  @override
  State<GoogleAuthHandlerPage> createState() => _GoogleAuthHandlerPageState();
}

class _GoogleAuthHandlerPageState extends State<GoogleAuthHandlerPage> {
  final Logger _logger = Logger();
  
  bool _isProcessing = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _processAuth();
  }
  
  Future<void> _processAuth() async {
    try {
      _logger.i('Processing Google auth callback with params: ${widget.params}');
      
      // For some authentication flows, we would validate the state parameter
      // against CSRF token, but this is usually handled by the underlying auth provider
      
      // Process the auth code/token
      if (widget.params.containsKey('code') || widget.params.containsKey('token')) {
        final code = widget.params['code'] ?? widget.params['token'] ?? '';
        
        if (code.isNotEmpty) {
          _logger.i('Processing auth code/token: ${code.substring(0, 5)}...');
          
          // Temporarily disabled as we're not supporting Google auth with Jarvis API
          _errorMessage = 'Google authentication is not currently supported with Jarvis API';
          
          // Handle success
          if (!mounted) return;
          setState(() {
            _isProcessing = false;
          });
          
          return;
        }
      }
      
      // If we reach here, the URL didn't contain valid auth parameters
      _logger.w('Auth parameters not found in URL');
      
      // Set error message and stop loading
      setState(() {
        _errorMessage = 'Invalid authentication parameters';
        _isProcessing = false;
      });
    } catch (e) {
      _logger.e('Error processing Google auth: $e');
      
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Error processing authentication: ${e.toString()}';
        _isProcessing = false;
      });
    }
  }
  
  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomePage()),
      (route) => false,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: _isProcessing
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 24),
                    Text(
                      'Đang xử lý đăng nhập...',
                      style: TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : _errorMessage != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[700],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Lỗi đăng nhập',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Thử lại'),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Đăng nhập thành công',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _navigateToHome,
                          child: const Text('Tiếp tục'),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
