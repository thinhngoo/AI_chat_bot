import 'dart:io';
import 'dart:async';
import 'package:logger/logger.dart';

class OAuthRedirectHandler {
  final Logger _logger = Logger();
  final Completer<String> _codeCompleter = Completer<String>();
  HttpServer? _server;
  Timer? _timeoutTimer;
  
  // Thử một số port khác nhau nếu port đầu tiên không khả dụng
  static const List<int> _fallbackPorts = [8080, 3000, 8090, 5000, 8000];
  String _actualRedirectUri = 'http://localhost:8080';

  Future<String> listenForRedirect({Duration timeout = const Duration(minutes: 5)}) async {
    try {
      for (final port in _fallbackPorts) {
        try {
          _actualRedirectUri = 'http://localhost:$port';
          _logger.i('Attempting to listen on $_actualRedirectUri');
          
          // Thử bind với địa chỉ và port
          _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port, shared: true)
              .timeout(const Duration(seconds: 2));
          
          _logger.i('Successfully listening on $_actualRedirectUri');
          
          // Log success instead of using print
          _logger.i('✓ Port $port opened successfully');
          _logger.i('Server listening on $_actualRedirectUri');
          _logger.i('Desktop Client ID automatically accepts redirects to any localhost port');
          break;
        } catch (e) {
          _logger.w('Failed to bind to port $port: $e');
          if (port == _fallbackPorts.last) {
            _logger.e('All ports failed, cannot start local server');
            throw 'Cannot open any ports (tried: ${_fallbackPorts.join(", ")}). '
                'Please close applications using these ports or use manual code entry.';
          }
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

      // Log status information instead of using print
      _logger.i('Server is listening on $_actualRedirectUri');
      _logger.i('If browser shows connection error, enter auth code manually');

      // Xử lý các request đến
      _server!.listen(
        (HttpRequest request) async {
          final uri = request.uri;
          _logger.i('Received request: ${uri.toString()}');
          final code = uri.queryParameters['code'];
          
          if (code != null) {
            _logger.i('Received authorization code (length: ${code.length})');
            
            // Cancel timeout timer since we got a response
            _timeoutTimer?.cancel();
            
            // Gửi phản hồi HTML để đóng cửa sổ trình duyệt
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
            
            // Hoàn thành future với code nhận được
            if (!_codeCompleter.isCompleted) {
              _codeCompleter.complete(code);
            }
            
            // Đóng server
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
      throw 'Failed to listen for OAuth redirect: $e';
    }
  }
  
  // Getter để lấy redirect URI thực tế đang sử dụng
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
