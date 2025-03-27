import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../core/services/api/api_service.dart';

class HelpFeedbackPage extends StatefulWidget {
  const HelpFeedbackPage({super.key});

  @override
  HelpFeedbackPageState createState() => HelpFeedbackPageState();
}

class HelpFeedbackPageState extends State<HelpFeedbackPage> {
  final _feedbackController = TextEditingController();
  final ApiService _apiService = ApiService();
  final Logger _logger = Logger();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trợ giúp & Phản hồi')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text('Câu hỏi thường gặp', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const ExpansionTile(
              title: Text('Làm thế nào để đăng nhập?'),
              children: [Text('Sử dụng email và mật khẩu đã đăng ký.')],
            ),
            const ExpansionTile(
              title: Text('Tôi quên mật khẩu phải làm sao?'),
              children: [Text('Sử dụng chức năng "Quên mật khẩu" trên trang đăng nhập.')],
            ),
            const ExpansionTile(
              title: Text('Tại sao câu trả lời của AI không chính xác?'),
              children: [Text('AI đưa ra câu trả lời dựa trên dữ liệu đã học. Đôi khi có thể không chính xác hoàn toàn.')],
            ),
            const SizedBox(height: 20),
            const Text('Gửi phản hồi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _feedbackController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Nhập phản hồi của bạn ở đây...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitFeedback,
              child: const Text('Gửi phản hồi'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập phản hồi trước khi gửi')),
      );
      return;
    }

    // In a real app, this would send the feedback to a server
    // For now, just log it and show a success message
    _logger.i('Feedback submitted: ${_feedbackController.text}');
    
    // Clear the feedback field
    _feedbackController.clear();
    
    // Show a success message
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cảm ơn bạn đã gửi phản hồi!')),
    );
  }
  
  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }
}