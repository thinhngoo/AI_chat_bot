import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

class ApiService {
  final logger = Logger();

  Future<String> getDeepSeekResponse(String message) async {
    final String? apiKey = dotenv.env['DEEPSEEK_API_KEY'];
    const String url = 'https://api.deepseek.com/v1/chat/completions';

    if (apiKey == null || apiKey.isEmpty) {
      logger.w('API Key chưa được khởi tạo. Kiểm tra file .env và main.dart');
      return 'Lỗi: API Key chưa được khởi tạo';
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {'role': 'user', 'content': message}
          ],
          'max_tokens': 150,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].trim();
      } else {
        logger.e('API error: ${response.statusCode} - ${response.body}');
        return 'Lỗi: ${response.statusCode}';
      }
    } catch (e) {
      logger.e('Exception occurred: $e');
      return 'Có lỗi xảy ra: $e';
    }
  }
}