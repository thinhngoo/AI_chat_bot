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
  
  // Message history to maintain context
  final List<Map<String, dynamic>> _conversationHistory = [];
  
  // Mock responses for fallback mode
  final List<String> _fallbackResponses = [
    'Xin chào, tôi là trợ lý ảo. Tôi đang chạy ở chế độ ngoại tuyến do lỗi xác thực API.',
    'Tôi không thể kết nối với API Gemini, nhưng tôi có thể giúp bạn với một số câu trả lời cơ bản.',
    'Rất tiếc, API đang gặp sự cố. Vui lòng kiểm tra kết nối mạng và API key trong file .env của bạn.',
    'Đây là phản hồi ngoại tuyến. Để sử dụng API thật, hãy đảm bảo bạn đã cài đặt GEMINI_API_KEY hợp lệ trong file .env.',
    'Tôi đang hoạt động ở chế độ hạn chế do không thể kết nối tới API Gemini. Vui lòng thử lại sau.',
  ];
  
  Future<String> getDeepSeekResponse(String userMessage) async {
    // Add user message to conversation history
    _addUserMessage(userMessage);
    
    // If already in fallback mode, return a mock response
    if (_useFallbackResponses) {
      return _getFallbackResponse();
    }
    
    try {
      // Get API key from environment variables
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey == 'your_gemini_api_key_here' || 
          apiKey == 'demo_api_key_please_configure' || apiKey == 'demo_api_key') {
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
      
      // Make API call with API key as query parameter
      _logger.i('Sending request to Gemini API...');
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );
      
      // Process response
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Extract text from Gemini response format
        final assistantResponse = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? 
            'Không thể trích xuất phản hồi từ API.';
        
        // Add assistant response to conversation history
        _addAssistantResponse(assistantResponse);
        
        return assistantResponse;
      } else {
        _logger.e('API error: ${response.statusCode}, ${response.body}');
        
        // Switch to fallback mode for authentication errors
        if (response.statusCode == 401 || response.statusCode == 403) {
          _useFallbackResponses = true;
          return 'Lỗi xác thực API Gemini (${response.statusCode}). Chuyển sang chế độ ngoại tuyến. '
              'Vui lòng kiểm tra API key của bạn trong file .env và khởi động lại ứng dụng.';
        }
        
        throw Exception('Failed to load response: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      _logger.e('Error calling Gemini API: $e');
      
      // Add a more helpful error message to conversation history
      final errorResponse = 'Đã xảy ra lỗi khi gọi API: ${e.toString()}\n\n'
          'Hướng dẫn khắc phục:\n'
          '1. Kiểm tra kết nối mạng\n'
          '2. Đảm bảo đã thêm API key hợp lệ vào file .env\n'
          '3. Định dạng file .env: GEMINI_API_KEY=your_actual_api_key';
      
      _addAssistantResponse(errorResponse);
      
      // Switch to fallback mode after an error
      _useFallbackResponses = true;
      
      return errorResponse;
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
  
  // Reset fallback mode - can be called if user updates API key
  void resetFallbackMode() {
    _useFallbackResponses = false;
  }
}