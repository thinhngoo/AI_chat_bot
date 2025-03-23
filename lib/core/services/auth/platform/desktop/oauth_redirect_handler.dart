import 'dart:io';
import 'dart:async';
import 'package:logger/logger.dart';

class OAuthRedirectHandler {
  final Logger _logger = Logger();
  final Completer<String> _codeCompleter = Completer<String>();
  HttpServer? _server;
  Timer? _timeoutTimer;
  
  // Remove unused _fallbackPorts field
  String _actualRedirectUri = 'http://localhost:8080';

  Future<String> listenForRedirect({Duration timeout = const Duration(minutes: 5)}) async {
    try {
      // Try port 8080 first since it's likely the one registered in Google Cloud Console
      _logger.i('Attempting to listen on http://localhost:8080 (primary port)');
      try {
        _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080, shared: true)
            .timeout(const Duration(seconds: 2));
        _actualRedirectUri = 'http://localhost:8080';
        _logger.i('Successfully bound to primary port 8080');
      } catch (e) {
        _logger.w('Failed to bind to port 8080: $e');
        _logger.w('⚠️ Warning: port 8080 is not available but it is required for Google authentication');
        
        // Try only one alternative port - port 3000
        try {
          _actualRedirectUri = 'http://localhost:3000';
          _logger.i('Attempting to listen on $_actualRedirectUri');
            
          // Try binding with the address and port
          _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 3000, shared: true)
              .timeout(const Duration(seconds: 2));
            
          _logger.i('Successfully listening on $_actualRedirectUri');
          _logger.w('⚠️ Using fallback port 3000 - you MUST add this redirect URI to Google Cloud Console');
        } catch (e) {
          _logger.w('Failed to bind to fallback port: $e');
          throw 'Cannot open required ports (8080 or 3000). '
              'Please close applications using these ports or check your firewall settings.';
        }
      }

      // Set a timeout to automatically close the server if no code is received
      _timeoutTimer = Timer(timeout, () {
        if (!_codeCompleter.isCompleted) {
          _codeCompleter.completeError(
            'Authentication timed out (${timeout.inMinutes} minutes). ' 
            'Please try again or use manual code entry.'
          );
        }
        closeServer();
      });

      // Log port actually used
      _logger.i('OAuth server listening on $_actualRedirectUri. '
          'If you see "redirect_uri_mismatch", you must add this exact URI to Google Cloud Console');

      // Process incoming requests
      _server!.listen(
        (HttpRequest request) async {
          final uri = request.uri;
          _logger.i('Received request: ${uri.toString()}');
          
          // Check for redirect_uri_mismatch error
          if (uri.queryParameters.containsKey('error')) {
            final error = uri.queryParameters['error'];
            final errorDescription = uri.queryParameters['error_description'] ?? 'No description provided';
            
            _logger.e('Received OAuth error: $error - $errorDescription');
            
            if (error == 'redirect_uri_mismatch') {
              // Send specific redirect URI mismatch error page
              request.response.headers.contentType = ContentType.html;
              request.response.write('''
                <!DOCTYPE html>
                <html>
                  <head>
                    <title>Lỗi Redirect URI Mismatch</title>
                    <meta charset="UTF-8">
                    <style>
                      body { font-family: Arial, sans-serif; text-align: center; padding-top: 50px; background-color: #f5f5f5; }
                      .container { background-color: white; max-width: 600px; margin: 0 auto; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
                      h1 { color: #d32f2f; }
                      .error-code { font-family: monospace; background-color: #f5f5f5; padding: 10px; border-radius: 4px; }
                      p { margin-top: 20px; color: #333; }
                      .steps { text-align: left; margin: 20px 0; }
                    </style>
                  </head>
                  <body>
                    <div class="container">
                      <h1>Lỗi Redirect URI Mismatch</h1>
                      <div class="error-code">Lỗi 400: redirect_uri_mismatch</div>
                      <p>URI đang được sử dụng không khớp với danh sách URI đã đăng ký trong Google Cloud Console.</p>
                      <p><b>URI hiện tại:</b> $_actualRedirectUri</p>
                      
                      <div class="steps">
                        <h3>Cách khắc phục:</h3>
                        <ol>
                          <li>Đi đến <a href="https://console.cloud.google.com/apis/credentials" target="_blank">Google Cloud Console > APIs & Services > Credentials</a></li>
                          <li>Tìm và chỉnh sửa OAuth 2.0 Client ID đang được sử dụng</li>
                          <li>Thêm URI sau vào danh sách "Authorized redirect URIs":</li>
                          <div class="error-code">$_actualRedirectUri</div>
                          <li>Lưu thay đổi và thử lại</li>
                          <li>Nếu vẫn gặp lỗi, thêm cả URI sau: http://localhost:8080</li>
                        </ol>
                      </div>
                    </div>
                  </body>
                </html>
              ''');
              await request.response.close();
              
              // Complete with error
              if (!_codeCompleter.isCompleted) {
                _codeCompleter.completeError('redirect_uri_mismatch: Please add $_actualRedirectUri to Google Cloud Console');
              }
              
              // Close server
              await closeServer();
              return;
            }
          }
          
          final code = uri.queryParameters['code'];
          
          if (code != null) {
            _logger.i('Received authorization code (length: ${code.length})');
            
            // Cancel timeout timer since we got a response
            _timeoutTimer?.cancel();
            
            // Send success response HTML to close the browser window
            request.response.headers.contentType = ContentType.html;
            request.response.write('''
              <!DOCTYPE html>
              <html>
                <head>
                  <title>Xác thực thành công</title>
                  <meta charset="UTF-8">
                  <style>
                    body { font-family: Arial, sans-serif; text-align: center; padding-top: 50px; background-color: #f5f5f5; }
                    .container { background-color: white; max-width: 500px; margin: 0 auto; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
                    h1 { color: #4285f4; }
                    p { margin-top: 20px; color: #333; }
                    .success-icon { font-size: 64px; color: #34A853; }
                  </style>
                </head>
                <body>
                  <div class="container">
                    <div class="success-icon">✓</div>
                    <h1>Xác thực thành công!</h1>
                    <p>Bạn có thể đóng cửa sổ này và quay lại ứng dụng.</p>
                    <p><small>Cửa sổ này sẽ tự động đóng sau 3 giây...</small></p>
                  </div>
                  <script>
                    setTimeout(() => window.close(), 3000);
                  </script>
                </body>
              </html>
            ''');
            await request.response.close();
            
            // Complete future with code received
            if (!_codeCompleter.isCompleted) {
              _codeCompleter.complete(code);
            }
            
            // Close server
            await closeServer();
          } else {
            // If someone just navigates to localhost without a code, show helpful information
            request.response.headers.contentType = ContentType.html;
            request.response.write('''
              <!DOCTYPE html>
              <html>
                <head>
                  <title>Authentication in Progress</title>
                  <meta charset="UTF-8">
                  <style>
                    body { font-family: Arial, sans-serif; text-align: center; padding-top: 50px; background-color: #f5f5f5; }
                    .container { background-color: white; max-width: 500px; margin: 0 auto; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
                    h1 { color: #4285f4; }
                    p { margin-top: 20px; color: #333; }
                  </style>
                </head>
                <body>
                  <div class="container">
                    <h1>Authentication Server Active</h1>
                    <p>This is an OAuth authentication server for your application.</p>
                    <p>Please return to the application and follow the authentication instructions there.</p>
                    <p><small>Current redirect URI: $_actualRedirectUri</small></p>
                  </div>
                </body>
              </html>
            ''');
            await request.response.close();
          }
        },
        onError: (e) {
          _logger.e('Error handling request: $e');
        },
        cancelOnError: false,
      );
      
      return _codeCompleter.future;
    } catch (e) {
      _logger.e('Error setting up redirect handler: $e');
      // Clean up any resources before throwing
      await closeServer();
      // Return a more descriptive error
      throw 'Failed to start OAuth redirect listener: $e. '
          'This might be caused by firewall restrictions or port conflicts. '
          'Try using manual code entry instead.';
    }
  }
  
  // Getter to access the actual redirect URI being used
  String get redirectUri => _actualRedirectUri;
  
  Future<void> closeServer() async {
    _timeoutTimer?.cancel();
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
      _logger.i('Closed OAuth redirect server');
    }
  }
}
