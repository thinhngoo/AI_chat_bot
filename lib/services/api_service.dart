import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

class ApiService {
  final Logger _logger = Logger();
  final String _baseUrl = 'https://api.deepseek.com/v1/chat/completions'; // DeepSeek API endpoint
  
  // Message history to maintain context
  final List<Map<String, String>> _conversationHistory = [];
  
  Future<String> getDeepSeekResponse(String userMessage) async {
    try {
      // Add user message to conversation history
      _conversationHistory.add({"role": "user", "content": userMessage});
      
      // Get API key from environment variables
      final apiKey = dotenv.env['DEEPSEEK_API_KEY'];
      if (apiKey == null) {
        throw Exception('DEEPSEEK_API_KEY not found in environment variables');
      }
      
      // Create request body
      final requestBody = {
        "model": "deepseek-chat", // DeepSeek model name, adjust as needed
        "messages": _conversationHistory,
        "temperature": 0.7,
        "max_tokens": 1024,
      };
      
      // Make API call
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(requestBody),
      );
      
      // Process response
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final assistantResponse = data['choices'][0]['message']['content'];
        
        // Add assistant response to conversation history
        _conversationHistory.add({"role": "assistant", "content": assistantResponse});
        
        // Keep conversation history manageable (limit to 10 messages)
        if (_conversationHistory.length > 10) {
          _conversationHistory.removeRange(0, 2); // Remove oldest user-assistant pair
        }
        
        return assistantResponse;
      } else {
        _logger.e('API error: ${response.statusCode}, ${response.body}');
        throw Exception('Failed to load response: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      _logger.e('Error calling DeepSeek API: $e');
      throw Exception('Error: $e');
    }
  }
  
  // Method to clear conversation history
  void clearConversationHistory() {
    _conversationHistory.clear();
  }
}
