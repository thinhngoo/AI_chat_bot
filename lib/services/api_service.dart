import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  Future<String> getDeepSeekResponse(String message) async {
    final url = Uri.parse('https://api.example.com/deepseek'); // Replace with your actual API endpoint
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'message': message}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['response']; // Ensure the API returns a 'response' field
    } else {
      throw Exception('Failed to load response: ${response.statusCode}');
    }
  }
}
