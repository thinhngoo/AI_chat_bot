import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

/// This page has been deprecated since Google Authentication is no longer supported
/// when using the Jarvis API for authentication.
///
/// This stub is kept for backward compatibility with existing code.
class GoogleAuthHandlerPage extends StatelessWidget {
  final Logger _logger = Logger();
  
  GoogleAuthHandlerPage({super.key}) {
    _logger.w('GoogleAuthHandlerPage is deprecated and should not be used with Jarvis API');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unsupported Feature'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 80,
                color: Colors.orange,
              ),
              const SizedBox(height: 20),
              const Text(
                'Google Authentication is not supported',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'This application now uses Jarvis API for authentication, which does not support Google Sign-In.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                child: const Text('Go to Login Page'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
