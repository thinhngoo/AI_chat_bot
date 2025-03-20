import 'package:flutter/material.dart';

class HelpFeedbackPage extends StatefulWidget {
  const HelpFeedbackPage({super.key});

  @override
  HelpFeedbackPageState createState() => HelpFeedbackPageState();
}

class HelpFeedbackPageState extends State<HelpFeedbackPage> {
  final _feedbackController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trợ giúp & Phản hồi')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
              },
              child: const Text('Gửi'),
            ),
          ],
        ),
      ),
    );
  }
}
