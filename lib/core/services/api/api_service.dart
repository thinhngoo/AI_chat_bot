import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

class ApiService {
  final Logger _logger = Logger();
  // Update to use Gemini API endpoint
  final String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  
  bool _useFallbackResponses = false;
  int _consecutiveFailures = 0;
  final int _maxRetries = 2;
  
  // Message history to maintain context
  final List<Map<String, dynamic>> _conversationHistory = [];
  
  // Mock responses for fallback mode
  final List<String> _fallbackResponses = [
    'Xin chào, tôi là trợ lý ảo. Tôi đang chạy ở chế độ ngoại tuyến do API Gemini đang tạm thời không khả dụng.',
    'Dịch vụ API đang gặp vấn đề. Tôi sẽ hoạt động ở chế độ ngoại tuyến cho đến khi dịch vụ được khôi phục.',
    'Rất tiếc, máy chủ API Gemini hiện không khả dụng (lỗi 503). Vui lòng thử lại sau vài phút.',
    'API đang bảo trì hoặc gặp sự cố tạm thời. Tôi đang chạy ở chế độ ngoại tuyến với khả năng giới hạn.',
    'Tôi đang hoạt động ở chế độ hạn chế do máy chủ API đang quá tải. Trạng thái hiện tại: 503 Service Unavailable.',
  ];
  
  Future<String> getDeepSeekResponse(String userMessage) async {
    // Add user message to conversation history
    _addUserMessage(userMessage);
    
    // Check if we're already in fallback mode
    if (_useFallbackResponses) {
      return _getFallbackResponse();
    }
    
    try {
      // Check if .env is loaded at all
      if (!dotenv.isInitialized) {
        _logger.e('.env file is not loaded. Make sure it exists in the project root directory.');
        _useFallbackResponses = true;
        return 'Lỗi: Không thể tải file .env. Vui lòng đảm bảo file .env tồn tại trong thư mục gốc của dự án và chứa GEMINI_API_KEY hợp lệ.';
      }
      
      // Get API key from environment variables with fallback
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? 'demo_api_key';
      
      // If API key is missing or using placeholder, switch to fallback mode
      if (apiKey == 'your_gemini_api_key_here' || 
          apiKey == 'demo_api_key_please_configure' || 
          apiKey == 'demo_api_key' ||
          apiKey == 'placeholder_client_id') {
        _logger.w('Valid GEMINI_API_KEY not found in environment variables, using fallback mode');
        _useFallbackResponses = true;
        return _getFallbackResponse();
      }
      
      // Create request body matching the exact Gemini API format
      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': userMessage}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 1024,
        }
      };
      
      // Try up to _maxRetries times for transient errors
      for (int attempt = 0; attempt <= _maxRetries; attempt++) {
        if (attempt > 0) {
          _logger.i('Retry attempt $attempt for API call after transient error');
          // Add exponential backoff delay between retries
          await Future.delayed(Duration(milliseconds: 500 * pow(2, attempt).toInt()));
        }
        
        try {
          // Make API call with API key as query parameter
          _logger.i('Sending request to Gemini API...');
          final response = await http.post(
            Uri.parse('$_baseUrl?key=$apiKey'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(requestBody),
          ).timeout(const Duration(seconds: 15)); // Add timeout to avoid hanging requests
          
          // Process response
          if (response.statusCode == 200) {
            // Reset failure counter on success
            _consecutiveFailures = 0;
            
            final data = jsonDecode(response.body);
            
            // Extract text from Gemini response format
            final assistantResponse = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? 
                'Không thể trích xuất phản hồi từ API.';
            
            // Add assistant response to conversation history
            _addAssistantResponse(assistantResponse);
            
            return assistantResponse;
          } else {
            // Handle specific error codes
            if (response.statusCode == 503) {
              _logger.e('API error: 503 Service Unavailable, ${response.body}');
              
              // Only continue retrying for 503 errors
              if (attempt < _maxRetries) {
                continue; // Try again
              }
              
              // After max retries, track consecutive failures and potentially switch to fallback
              _consecutiveFailures++;
              if (_consecutiveFailures >= 2) { // Switch to fallback after 2 consecutive 503 errors
                _useFallbackResponses = true;
                return 'Dịch vụ API Gemini đang không khả dụng (Lỗi 503). Đã chuyển sang chế độ ngoại tuyến. '
                    'Vui lòng thử lại sau. Lỗi: ${_getErrorMessage(response.body)}';
              }
              
              // Return a more specific error for 503
              throw 'Dịch vụ API Gemini hiện đang quá tải hoặc bảo trì (Lỗi 503). Vui lòng thử lại sau vài phút.';
            } else if (response.statusCode == 401 || response.statusCode == 403) {
              _useFallbackResponses = true;
              return 'Lỗi xác thực API Gemini (${response.statusCode}). Chuyển sang chế độ ngoại tuyến. '
                  'Vui lòng kiểm tra API key của bạn trong file .env và khởi động lại ứng dụng.';
            } else if (response.statusCode == 429) {
              // Rate limit exceeded
              _consecutiveFailures++;
              return 'Đã vượt quá giới hạn tần suất gọi API (429 Too Many Requests). Vui lòng thử lại sau ít phút.';
            } else {
              // Other error codes
              _logger.e('API error: ${response.statusCode}, ${response.body}');
              throw 'Lỗi từ API Gemini: ${response.statusCode} - ${_getErrorMessage(response.body)}';
            }
          }
        } catch (e) {
          // Only retry if this is a timeout or connection error and not the final attempt
          if ((e is http.ClientException || e.toString().contains('timeout')) && attempt < _maxRetries) {
            _logger.w('Network error during API call, will retry: $e');
            continue;
          }
          // Otherwise, rethrow to be handled by the outer catch block
          rethrow;
        }
      }
      
      // If we get here, all retries failed
      throw 'Không thể kết nối đến API Gemini sau nhiều lần thử. Dịch vụ có thể đang bảo trì.';
    } catch (e) {
      _logger.e('Error calling Gemini API: $e');
      
      // Track consecutive failures and potentially switch to fallback mode
      _consecutiveFailures++;
      if (_consecutiveFailures >= 3) { // After 3 consecutive failures of any kind
        _useFallbackResponses = true;
        
        // Create a user-friendly message indicating we're switching to fallback mode
        final errorResponse = 'Đã xảy ra lỗi liên tục khi gọi API. Chuyển sang chế độ ngoại tuyến.\n\n'
            'Lỗi: ${e.toString()}\n\n'
            'Các lỗi thường gặp:\n'
            '• 503: Dịch vụ tạm thời không khả dụng (đang bảo trì hoặc quá tải)\n'
            '• Lỗi mạng: Kiểm tra kết nối internet của bạn\n'
            '• Lỗi API key: Đảm bảo API key hợp lệ trong file .env';
        
        _addAssistantResponse(errorResponse);
        return errorResponse;
      }
      
      // General error handling for non-fallback errors
      final errorResponse = 'Đã xảy ra lỗi khi gọi API: ${e.toString()}\n\n'
          'Hướng dẫn khắc phục:\n'
          '1. Nếu lỗi 503, đây là sự cố từ phía máy chủ Google, vui lòng thử lại sau\n'
          '2. Kiểm tra kết nối mạng\n'
          '3. Đảm bảo đã thêm API key hợp lệ vào file .env';
      
      _addAssistantResponse(errorResponse);
      return errorResponse;
    }
  }
  
  // Helper method to extract error message from API response
  String _getErrorMessage(String responseBody) {
    try {
      final data = jsonDecode(responseBody);
      return data['error']?['message'] ?? 'Unknown error';
    } catch (e) {
      return 'Unable to parse error message';
    }
  }
  
  // Helper method to add user message to conversation history in Gemini format
  void _addUserMessage(String message) {
    _conversationHistory.add({
      'role': 'user',
      'parts': [{'text': message}]
    });
  }
  
  // Helper method to add assistant response to conversation history in Gemini format
  void _addAssistantResponse(String message) {
    _conversationHistory.add({
      'role': 'model',
      'parts': [{'text': message}]
    });
  }
  
  String _getFallbackResponse() {
    // Get a random response from the fallback list
    final random = Random();
    final response = _fallbackResponses[random.nextInt(_fallbackResponses.length)];
    
    // Add to conversation history
    _addAssistantResponse(response);
    
    return response;
  }
  
  // Method to clear conversation history
  void clearConversationHistory() {
    _conversationHistory.clear();
  }
  
  // Reset fallback mode and failure counter - can be called if user updates API key or service is restored
  void resetFallbackMode() {
    _useFallbackResponses = false;
    _consecutiveFailures = 0;
  }
  
  // Method to manually check if API is available again after being in fallback mode
  Future<bool> checkApiAvailability() async {
    if (!_useFallbackResponses) {
      return true; // Not in fallback mode, so assume API is available
    }
    
    try {
      // Try a minimal API call to check if service is back up
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? 'demo_api_key';
      if (apiKey == 'your_gemini_api_key_here' || apiKey == 'demo_api_key') {
        return false; // Invalid API key, so API won't be available
      }
      
      final response = await http.get(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        _logger.i('API service has been restored, exiting fallback mode');
        resetFallbackMode();
        return true;
      }
      
      return false;
    } catch (e) {
      _logger.w('API still unavailable during availability check: $e');
      return false;
    }
  }
}