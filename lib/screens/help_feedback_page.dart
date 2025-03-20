import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HelpFeedbackPage extends StatefulWidget {
  const HelpFeedbackPage({super.key});

  @override
  HelpFeedbackPageState createState() => HelpFeedbackPageState();
}

class HelpFeedbackPageState extends State<HelpFeedbackPage> {
  final _feedbackController = TextEditingController();
  final ApiService _apiService = ApiService();

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
              title: Text('Làm sao để đăng nhập?'),
              children: [Text('Sử dụng email và mật khẩu đã đăng ký.')],
            ),
            const ExpansionTile(
              title: Text('Làm sao để đổi mật khẩu?'),
              children: [Text('Vào phần quản lý tài khoản để đổi.')],
            ),
            ExpansionTile(
              title: const Text('Tại sao chatbot không phản hồi chính xác?'),
              initiallyExpanded: true,
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Có thể bạn đang gặp lỗi kết nối API Gemini. Hãy kiểm tra:'),
                      SizedBox(height: 8),
                      Text('1. API Key của bạn đã được cài đặt đúng trong file .env'),
                      Text('2. Kết nối internet của bạn đang hoạt động'),
                      Text('3. Dịch vụ Gemini đang hoạt động bình thường'),
                      SizedBox(height: 8),
                      Text('Hướng dẫn cài đặt API Key:'),
                      Text('- Truy cập https://aistudio.google.com/app/apikey'),
                      Text('- Tạo API key mới'),
                      Text('- Thêm vào file .env: GEMINI_API_KEY=your_key'),
                      Text('- Khởi động lại ứng dụng'),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _apiService.resetFallbackMode();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã khởi tạo lại kết nối API')),
                    );
                  },
                  child: const Text('Khởi tạo lại kết nối API'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Gửi phản hồi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(
              controller: _feedbackController,
              decoration: const InputDecoration(labelText: 'Nhập ý kiến hoặc báo lỗi'),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Logic gửi phản hồi
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Phản hồi đã được gửi')),
                );
                _feedbackController.clear();
              },
              child: const Text('Gửi'),
            ),
          ],
        ),
      ),
    );
  }
}
