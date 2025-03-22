import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WindowsGoogleAuthService {
  final Logger _logger = Logger();
  
  // Constants for OAuth
  static const String _redirectUri = 'http://localhost:8080/auth/google/callback';
  static const String _scope = 'email profile';
  
  // Generate a random state for OAuth security
  String _generateRandomState() {
    var random = Random.secure();
    var values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }
  
  // Launch browser for Google sign in
  Future<String?> signInWithGoogle(BuildContext context) async {
    try {
      // Get client ID from environment variables
      final clientId = dotenv.env['GOOGLE_CLIENT_ID'];
      if (clientId == null || clientId.isEmpty) {
        _logger.e('Google client ID not found in environment variables');
        throw 'Google Client ID is missing. Please add GOOGLE_CLIENT_ID to your .env file.';
      }
      
      // Generate random state and store it for validation
      final state = _generateRandomState();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('oauth_state', state);
      
      // Create OAuth URL
      final url = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': clientId,
        'redirect_uri': _redirectUri,
        'response_type': 'code',
        'scope': _scope,
        'state': state,
        'access_type': 'offline',
        'prompt': 'select_account',
      });
      
      // Launch browser
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        
        // Show dialog for user to enter the authorization code
        if (context.mounted) {
          return await _showAuthCodeDialog(context);
        }
      } else {
        throw 'Could not launch browser for authentication';
      }
    } catch (e) {
      _logger.e('Error during Google sign-in: $e');
      rethrow;
    }
    return null;
  }
  
  // Show dialog for user to enter the authorization code
  Future<String?> _showAuthCodeDialog(BuildContext context) async {
    final TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Authorization Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'After you sign in with Google, you will be redirected to a page that shows an authorization code. '
                'Please copy that code and paste it below:',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Authorization Code',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Submit'),
              onPressed: () => Navigator.of(context).pop(controller.text),
            ),
          ],
        );
      },
    );
  }
  
  // Exchange authorization code for tokens
  Future<Map<String, dynamic>> _exchangeCodeForTokens(String code) async {
    try {
      final clientId = dotenv.env['GOOGLE_CLIENT_ID'];
      final clientSecret = dotenv.env['GOOGLE_CLIENT_SECRET'];
      
      if (clientId == null || clientSecret == null) {
        throw 'Google OAuth credentials not found';
      }
      
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        body: {
          'code': code,
          'client_id': clientId,
          'client_secret': clientSecret,
          'redirect_uri': _redirectUri,
          'grant_type': 'authorization_code',
        },
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        _logger.e('Failed to exchange code: ${response.statusCode} - ${response.body}');
        throw 'Failed to exchange authorization code for tokens';
      }
    } catch (e) {
      _logger.e('Error exchanging code for tokens: $e');
      rethrow;
    }
  }
  
  // Get user info using access token
  Future<Map<String, dynamic>> _getUserInfo(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('https://www.googleapis.com/oauth2/v2/userinfo'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        _logger.e('Failed to get user info: ${response.statusCode} - ${response.body}');
        throw 'Failed to get user info from Google';
      }
    } catch (e) {
      _logger.e('Error getting user info: $e');
      rethrow;
    }
  }
  
  // Complete the sign in process after getting the authorization code
  Future<Map<String, dynamic>> completeSignIn(String authorizationCode) async {
    try {
      // Exchange code for tokens
      final tokens = await _exchangeCodeForTokens(authorizationCode);
      final accessToken = tokens['access_token'];
      final refreshToken = tokens['refresh_token'];
      
      // Get user info
      final userInfo = await _getUserInfo(accessToken);
      
      // Store tokens securely
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('google_access_token', accessToken);
      if (refreshToken != null) {
        await prefs.setString('google_refresh_token', refreshToken);
      }
      
      // Return user info for account creation/login
      return userInfo;
    } catch (e) {
      _logger.e('Error completing sign in: $e');
      rethrow;
    }
  }
  
  // Check if user is signed in with Google
  Future<bool> isSignedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('google_access_token');
    return accessToken != null;
  }
  
  // Sign out from Google
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('google_access_token');
    await prefs.remove('google_refresh_token');
  }
}