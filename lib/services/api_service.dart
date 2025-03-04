import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  Future<String> getDeepSeekResponse(String message) async {
    // Replace with your API endpoint
    final url = Uri.parse('https://api.example.com/deepseek');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'message': message}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['response'];
    } else {
      throw Exception('Failed to load response');
    }
  }
}
