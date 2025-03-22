import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'oauth_redirect_handler.dart';

/// Service that handles Google authentication on Windows using OAuth flow
/// 
/// IMPORTANT CONFIGURATION STEPS:
/// 1. In Google Cloud Console (https://console.cloud.google.com/):
///    - Create OAuth 2.0 Client ID of type "Desktop application"
///    - Copy the Client ID and Client Secret
///    - No need to add redirect URIs for desktop apps (they use localhost)
/// 
/// 2. In Firebase Console (https://console.firebase.google.com/):
///    - Go to Authentication > Sign-in method > Google
///    - Enable Google sign-in
///    - Add the SAME Client ID from step 1 to "Web SDK configuration"
///    - Even though it's a Desktop client ID, Firebase needs it in Web config
/// 
/// 3. In your .env file:
///    - Add GOOGLE_DESKTOP_CLIENT_ID=your_desktop_client_id
///    - Add GOOGLE_CLIENT_SECRET=your_client_secret
class WindowsGoogleAuthService {
  final Logger _logger = Logger();
  
  // Constants for OAuth
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
      // Check if configuration exists
      _validateConfiguration();
      
      // Get client ID from environment variables - prefer desktop client ID for Windows
      final clientId = dotenv.env['GOOGLE_DESKTOP_CLIENT_ID'] ?? 
                     dotenv.env['GOOGLE_CLIENT_ID'];
                     
      if (clientId == null || clientId.isEmpty) {
        _logger.e('Google client ID not found in environment variables');
        throw 'Google Client ID is missing. Please add GOOGLE_DESKTOP_CLIENT_ID to your .env file.';
      }
      
      _logger.i('Using Desktop client ID for Windows OAuth flow: ${_maskSecret(clientId)}');
      
      // Generate random state and store it for validation
      final state = _generateRandomState();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('oauth_state', state);
      
      // Start the redirect handler (local server) to listen for the response
      final redirectHandler = OAuthRedirectHandler();
      final Future<String> codePromise = redirectHandler.listenForRedirect();
      
      // Use redirectUri from OAuthRedirectHandler to ensure same port
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
      
      // Log details for debugging
      _logger.i('Using Desktop Client ID: ${_maskSecret(clientId)}');
      _logger.i('Note: Desktop Client ID must be added to Firebase Web SDK configuration');
      _logger.i('Redirect URI: $redirectUri');
      
      // Launch browser
      _logger.i('Launching browser for OAuth...');
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
  
  // Verify environment variables are properly configured
  void _validateConfiguration() {
    final clientId = dotenv.env['GOOGLE_DESKTOP_CLIENT_ID'] ?? dotenv.env['GOOGLE_CLIENT_ID'];
    final clientSecret = dotenv.env['GOOGLE_CLIENT_SECRET'];
    
    if (clientId == null || clientId.isEmpty) {
      _logger.e('GOOGLE_DESKTOP_CLIENT_ID is missing in .env file');
      throw 'Configuration Error: GOOGLE_DESKTOP_CLIENT_ID is required for Windows auth. Please add it to your .env file.';
    }
    
    if (clientSecret == null || clientSecret.isEmpty) {  // Fix missing .isEmpty
      _logger.e('GOOGLE_CLIENT_SECRET is missing in .env file');
      throw 'Configuration Error: GOOGLE_CLIENT_SECRET is required for Windows auth. Please add it to your .env file.';
    }
    
    _logger.i('Google OAuth configuration validated');
    _logger.i('FIREBASE SETUP REMINDER: The client ID must also be added to Firebase Console > Authentication > Sign-in method > Google > Web SDK configuration');
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
      final idToken = tokens['id_token'];
      
      _logger.i('Tokens received - ID token length: ${idToken?.length ?? 0}, Access token length: ${accessToken?.length ?? 0}');
      
      if (idToken == null || accessToken == null) {
        _logger.e('Failed to get valid tokens from Google OAuth');
        throw 'Authentication failed: Could not get valid tokens from Google';
      }
      
      // Get user info
      final userInfo = await _getUserInfo(accessToken);
      _logger.i('User info received: ${userInfo['email']}');
      
      // Store tokens securely
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('google_access_token', accessToken);
      if (tokens['refresh_token'] != null) {
        await prefs.setString('google_refresh_token', tokens['refresh_token']);
      }
      
      // Clear auth pending flag
      await prefs.setBool('google_auth_pending', false);
      
      // IMPORTANT: Add Firebase Authentication integration
      if (idToken != null) {
        try {
          // Create AuthCredential with the obtained idToken
          final AuthCredential credential = GoogleAuthProvider.credential(
            idToken: idToken,
            accessToken: accessToken,
          );
          
          _logger.i('Attempting Firebase sign in with Google credential');
          
          // Remove redundant null check - just proceed with sign-in
          _logger.i('Firebase is initialized, proceeding with sign-in');
          
          // Sign in to Firebase with this credential
          final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
          
          _logger.i('Successfully signed in to Firebase with Google: ${userCredential.user?.uid}');
          
          // Add Firebase UID to user info for reference
          userInfo['firebaseUid'] = userCredential.user?.uid;
        } catch (e) {
          _logger.e('Error signing in to Firebase with Google credential: $e');
          
          // If the error is "invalid-credential", provide more helpful message
          if (e.toString().contains('invalid-credential')) {
            _logger.e('CONFIGURATION ERROR: Please ensure the Desktop Client ID is added to Firebase Console > Authentication > Sign-in method > Google > Web SDK configuration');
          }
          
          // Still return user info even if Firebase sign-in fails
          // This allows the app to continue working with local authentication
        }
      } else {
        _logger.w('No ID token received from Google. Cannot authenticate with Firebase.');
      }
      
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
      final clientId = dotenv.env['GOOGLE_DESKTOP_CLIENT_ID'] ?? 
                      dotenv.env['GOOGLE_CLIENT_ID'];
                      
      final clientSecret = dotenv.env['GOOGLE_CLIENT_SECRET'];
      
      if (clientId == null || clientSecret == null) {
        throw 'Google OAuth credentials not found';
      }
      
      _logger.i('Exchanging code for tokens (code length: ${code.length})');
      _logger.i('Using client ID: ${_maskSecret(clientId)}');
      _logger.i('Using redirect URI: $redirectUri');
      
      // Make sure we're using the exact same redirect URI that was used to get the code
      final requestBody = {
        'code': code,
        'client_id': clientId,
        'client_secret': clientSecret,
        'redirect_uri': redirectUri,
        'grant_type': 'authorization_code',
      };
      
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        body: requestBody,
      );
      
      _logger.i('Token exchange response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        _logger.i('Successfully obtained tokens');
        
        // Verify tokens exist
        if (!responseData.containsKey('access_token') || !responseData.containsKey('id_token')) {
          _logger.e('Missing required tokens in response: ${responseData.keys.toList()}');
          throw 'Invalid token response: missing required tokens';
        }
        
        return responseData;
      } else {
        _logger.e('Failed to exchange code: ${response.statusCode} - ${response.body}');
        
        // Attempt to parse error response for better error message
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          final errorMessage = errorData['error_description'] ?? errorData['error'] ?? 'Unknown error';
          throw 'OAuth error: $errorMessage';
        } catch (e) {
          // If we can't parse the error, use the generic message
          throw 'Failed to exchange authorization code for tokens (HTTP ${response.statusCode})';
        }
      }
    } catch (e) {
      _logger.e('Error exchanging code for tokens: $e');
      throw 'Failed to exchange authorization code for tokens: $e';
    }
  }
  
  // Mask sensitive information for logging
  String _maskSecret(String value) {
    if (value.length <= 8) return '****';
    return '${value.substring(0, 4)}...${value.substring(value.length - 4)}';
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