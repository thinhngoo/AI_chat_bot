import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart'; // Add the logger import
import '../../../core/services/auth/platform/desktop/windows_google_auth_service.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../chat/presentation/home_page.dart';
import 'login_page.dart';

class GoogleAuthHandlerPage extends StatefulWidget {
  final String initialAuthUrl;
  final bool autoStartAuth;

  const GoogleAuthHandlerPage({
    super.key, 
    required this.initialAuthUrl,
    this.autoStartAuth = true
  });

  @override
  GoogleAuthHandlerPageState createState() => GoogleAuthHandlerPageState();
}

class GoogleAuthHandlerPageState extends State<GoogleAuthHandlerPage> {
  final TextEditingController _codeController = TextEditingController();
  final WindowsGoogleAuthService _googleAuthService = WindowsGoogleAuthService();
  final AuthService _authService = AuthService();
  final Logger _logger = Logger(); // Initialize the logger

  bool _isLoading = false;
  String? _errorMessage;
  String? _statusMessage;
  bool _manualEntryMode = false;
  bool _autoAuthStarted = false;

  @override
  void initState() {
    super.initState();
    // Start automatic authentication after a brief delay
    if (widget.autoStartAuth) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !_autoAuthStarted) {
          _attemptAutomaticAuth();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Sign-In'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading && !_manualEntryMode
          ? _buildAutomaticAuthUI()
          : _manualEntryMode
              ? _buildManualEntryUI()
              : _buildInitialUI(),
      ),
    );
  }

  // Widget shown during automatic authentication
  Widget _buildAutomaticAuthUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 32.0),
          const Text(
            'Authenticating with Google...',
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16.0),
          if (_statusMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                _statusMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16.0),
              ),
            ),
          const SizedBox(height: 24.0),
          const Text(
            'A browser window has opened.\nPlease complete the sign-in process there.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32.0),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _manualEntryMode = true;
                _isLoading = false;
              });
            },
            child: const Text('Enter Code Manually Instead'),
          ),
        ],
      ),
    );
  }

  // Widget shown for manual code entry
  Widget _buildManualEntryUI() {
    return ListView(
      children: [
        const Icon(
          Icons.login,
          size: 64.0,
          color: Colors.blue,
        ),
        const SizedBox(height: 24.0),
        const Text(
          'Enter Authorization Code',
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24.0),
        
        // Instructions with steps
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Instructions:',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),
                _buildStep(1, 'Sign in to your Google account in the browser window'),
                _buildStep(2, 'After signing in, you\'ll see a code on the page'),
                _buildStep(3, 'Copy that code and paste it below'),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Authorization Code',
                    hintText: 'Paste the code here',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8.0),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16.0),

        // Couldn't get code section
        ExpansionTile(
          title: const Text('Having trouble?'),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Try the following:'),
                  const SizedBox(height: 8.0),
                  _buildBulletPoint('Make sure pop-ups are not blocked in your browser'),
                  _buildBulletPoint('Try signing in again by clicking the button below'),
                  _buildBulletPoint('The code page might be minimized or behind other windows'),
                  const SizedBox(height: 16.0),
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Restart Authentication'),
                      onPressed: () {
                        setState(() {
                          _manualEntryMode = false;
                          _autoAuthStarted = false;
                        });
                        _attemptAutomaticAuth();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24.0),

        // Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitCode,
                child: _isLoading 
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Submit Code'),
              ),
            ),
          ],
        ),
        
        // Copy auth URL button
        const SizedBox(height: 16.0),
        TextButton.icon(
          icon: const Icon(Icons.copy),
          label: const Text('Copy Authorization URL'),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: widget.initialAuthUrl));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('URL copied to clipboard')),
            );
          },
        ),
      ],
    );
  }

  // Initial UI before automatic auth starts
  Widget _buildInitialUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.login,
            size: 64.0,
            color: Colors.blue,
          ),
          const SizedBox(height: 24.0),
          const Text(
            'Sign in with Google',
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16.0),
          const Text(
            'Please wait while we prepare the authentication process...',
            style: TextStyle(fontSize: 16.0),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32.0),
          ElevatedButton(
            onPressed: _attemptAutomaticAuth,
            child: const Text('Start Authentication'),
          ),
        ],
      ),
    );
  }

  // Helper method for UI
  Widget _buildStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24.0,
            height: 24.0,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  // Helper method for UI
  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16.0)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  // Main method for automatic authentication
  Future<void> _attemptAutomaticAuth() async {
    if (_autoAuthStarted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusMessage = "Preparing authentication server...";
      _autoAuthStarted = true;
    });

    try {
      // Add additional logging for troubleshooting
      _logger.i('Starting Google authentication on Windows platform');
      _logger.i('Using redirect URI from WindowsGoogleAuthService');
      
      setState(() {
        _statusMessage = "Opening browser window. Please sign in with your Google account.";
      });
      
      // This will open browser and wait for redirect
      final authResult = await _googleAuthService.startGoogleAuth();
      
      if (!mounted) return;
      
      if (authResult != null && authResult.containsKey('email')) {
        setState(() {
          _statusMessage = "Authentication successful! Completing sign-in...";
        });
        
        // Authentication succeeded automatically
        await _completeSignIn(authResult);
      } else {
        // Fall back to manual entry
        setState(() {
          _isLoading = false;
          _manualEntryMode = true;
          _errorMessage = 'Automatic authentication failed. Please enter the code manually.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      
      _logger.e('Error during Google authentication: $e');
      
      // Show error and fall back to manual mode
      setState(() {
        _isLoading = false;
        _manualEntryMode = true;
        
        // Provide a more user-friendly error message based on the error
        if (e.toString().contains('Cannot open any ports')) {
          _errorMessage = 'Could not start authentication server. '
              'This may be due to firewall settings or another application using required ports. '
              'Please enter the code manually.';
        } else if (e.toString().contains('Authentication timed out')) {
          _errorMessage = 'Authentication request timed out. '
              'Please try again or enter the code manually.';
        } else {
          _errorMessage = 'Error during automatic authentication: ${e.toString()}';
        }
      });
    }
  }

  // Manual code submission
  Future<void> _submitCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter the authorization code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Try to complete the auth with the manual code
      final userInfo = await _googleAuthService.completeGoogleAuth(code);
      
      if (userInfo.containsKey('email')) {
        // Now trigger the login in AuthService
        await _authService.signInWithGoogle();
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      } else {
        throw 'Failed to get user information from Google';
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          String errorMsg = e.toString();
          
          // Make the error message more user-friendly
          if (errorMsg.contains('invalid_grant')) {
            _errorMessage = 'The authorization code is invalid or expired. Please try again.';
          } else if (errorMsg.contains('redirect_uri_mismatch')) {
            _errorMessage = 'There\'s a mismatch in the redirect URI. Please contact the app developer.';
          } else {
            _errorMessage = 'Authentication failed: $errorMsg';
          }
          _isLoading = false;
        });
      }
    }
  }

  // Complete the sign-in process
  Future<void> _completeSignIn(Map<String, dynamic> authResult) async {
    try {
      // Call auth service to complete sign in
      await _authService.signInWithGoogle();
      
      if (!mounted) return;
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _manualEntryMode = true;
        _errorMessage = 'Error completing sign in: ${e.toString()}';
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}
