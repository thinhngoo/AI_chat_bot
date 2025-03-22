import 'dart:convert';
import 'dart:math';
import 'dart:async'; // Add this import for TimeoutException
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'oauth_redirect_handler.dart';

class WindowsGoogleAuthService {
  final Logger _logger = Logger();
  
  // Constants for OAuth
  // Updated to use port 8080 instead of just localhost
  static const String _redirectUri = 'http://localhost:8080';
  static const String _scope = 'email profile';
  
  // Generate a random state for OAuth security
  String _generateRandomState() {
    var random = Random.secure();
    var values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }
  
  // Launch browser for Google sign in without requiring BuildContext
  Future<Map<String, dynamic>?> startGoogleAuth() async {
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
      
      // Start the redirect handler (local server) to listen for the response
      final redirectHandler = OAuthRedirectHandler();
      final Future<String> codePromise = redirectHandler.listenForRedirect();
      
      // Sử dụng redirectUri từ OAuthRedirectHandler để đảm bảo cùng port
      final redirectUri = redirectHandler.redirectUri;
      
      // Create OAuth URL with dynamic redirect URI
      final url = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': _scope,
        'state': state,
        'access_type': 'offline',
        'prompt': 'select_account',
      });
      
      // Log chi tiết thêm để debug
      _logger.i('Sử dụng Desktop Client ID: ${clientId.substring(0, 10)}...');
      _logger.i('Lưu ý: Desktop Client ID tự động chấp nhận redirect tới bất kỳ port localhost');
      
      // Launch browser
      _logger.i('Launching browser for OAuth: ${url.toString()}');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        
        // Wait for the code to be received by the local server
        _logger.i('Waiting for authorization code...');
        try {
          final code = await codePromise.timeout(const Duration(minutes: 5));
          
          // Complete the OAuth flow with the received code
          _logger.i('Code received, completing authentication...');
          return await completeGoogleAuth(code, redirectUri);
        } catch (e) {
          if (e is TimeoutException) {
            throw 'Authentication timed out. Please try again.';
          }
          rethrow;
        }
      } else {
        throw 'Could not launch browser for authentication';
      }
    } catch (e) {
      _logger.e('Error during Google sign-in: $e');
      rethrow;
    }
  }
  
  // Update to accept the redirectUri parameter
  Future<Map<String, dynamic>> completeGoogleAuth(String authCode, [String? redirectUri]) async {
    try {
      _logger.i('Completing Google auth with code (length: ${authCode.length})');
      
      // Clean up the authorization code
      final cleanedCode = _extractAuthCode(authCode);
      _logger.i('Code extracted and cleaned (length: ${cleanedCode.length})');
      
      // Exchange code for tokens using the same redirectUri that was used to get the code
      final tokens = await _exchangeCodeForTokens(cleanedCode, redirectUri ?? _redirectUri);
      final accessToken = tokens['access_token'];
      
      // Get user info
      final userInfo = await _getUserInfo(accessToken);
      
      // Store tokens securely
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('google_access_token', accessToken);
      if (tokens['refresh_token'] != null) {
        await prefs.setString('google_refresh_token', tokens['refresh_token']);
      }
      
      // Clear auth pending flag
      await prefs.setBool('google_auth_pending', false);
      
      return userInfo;
    } catch (e) {
      _logger.e('Error completing Google sign-in: $e');
      rethrow;
    }
  }
  
  // Helper method to extract the auth code from a string that might be a full URL
  String _extractAuthCode(String input) {
    _logger.d('Extracting auth code from input: $input');
    
    // If input is a full URL, extract just the code parameter
    if (input.contains('code=')) {
      try {
        // Check if it's a URL
        if (input.startsWith('http')) {
          // Parse the URL and get the 'code' query parameter
          final uri = Uri.parse(input);
          final code = uri.queryParameters['code'];
          _logger.d('Extracted code from URL: ${code != null ? '${code.substring(0, 4)}...' : 'null'}');
          return code ?? input;
        } else {
          // It's not a URL but contains code=, extract the code part
          final codeIndex = input.indexOf('code=') + 5;
          var endIndex = input.indexOf('&', codeIndex);
          if (endIndex == -1) endIndex = input.length;
          final code = input.substring(codeIndex, endIndex);
          _logger.d('Extracted code from string: ${code.substring(0, 4)}...');
          return code;
        }
      } catch (e) {
        _logger.w('Error extracting code from URL: $e, using original input');
        // If there's an error parsing, return the original input
        return input;
      }
    }
    
    // If no 'code=' is found, return the input as is, assuming it's already the code
    return input;
  }
  
  // Exchange authorization code for tokens
  Future<Map<String, dynamic>> _exchangeCodeForTokens(String code, String redirectUri) async {
    try {
      final clientId = dotenv.env['GOOGLE_CLIENT_ID'];
      final clientSecret = dotenv.env['GOOGLE_CLIENT_SECRET'];
      
      if (clientId == null || clientSecret == null) {
        throw 'Google OAuth credentials not found';
      }
      
      _logger.i('Exchanging code for tokens (code length: ${code.length})');
      _logger.i('Using client ID: ${clientId.substring(0, 8)}...');
      _logger.i('Using redirect URI: $redirectUri');
      
      // Make sure we're using the exact same redirect URI that was used to get the code
      final requestBody = {
        'code': code,
        'client_id': clientId,
        'client_secret': clientSecret,
        'redirect_uri': redirectUri,
        'grant_type': 'authorization_code',
      };
      
      _logger.d('Token request body: $requestBody');
      
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        body: requestBody,
      );
      
      _logger.i('Token exchange response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        _logger.i('Successfully obtained tokens');
        return responseData;
      } else {
        _logger.e('Failed to exchange code: ${response.statusCode} - ${response.body}');
        throw 'Failed to exchange authorization code for tokens (HTTP ${response.statusCode}): ${response.body}';
      }
    } catch (e) {
      _logger.e('Error exchanging code for tokens: $e');
      throw 'Failed to exchange authorization code for tokens: $e';
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
  
  // Check if Google authentication is pending
  Future<bool> isAuthPending() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('google_auth_pending') ?? false;
  }
  
  // Get the stored auth URL if any
  Future<String?> getAuthUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('google_auth_url');
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