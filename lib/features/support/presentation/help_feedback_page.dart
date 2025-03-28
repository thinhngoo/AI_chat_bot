import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpFeedbackPage extends StatefulWidget {
  const HelpFeedbackPage({super.key});

  @override
  State<HelpFeedbackPage> createState() => _HelpFeedbackPageState();
}

class _HelpFeedbackPageState extends State<HelpFeedbackPage> {
  final Logger _logger = Logger();
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _sendFeedback() async {
    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung phản hồi')),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      // Simulate sending feedback
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cảm ơn bạn đã gửi phản hồi!')),
      );
      
      _feedbackController.clear();
    } catch (e) {
      _logger.e('Error sending feedback: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi gửi phản hồi: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      _logger.e('Error launching URL: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể mở liên kết: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trợ giúp & Phản hồi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FAQ section
            const Text(
              'Câu hỏi thường gặp',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFaqItem(
              'Làm thế nào để tạo một cuộc trò chuyện mới?',
              'Bạn có thể tạo cuộc trò chuyện mới bằng cách nhấp vào nút "+" ở góc phải bên dưới màn hình chính.',
            ),
            _buildFaqItem(
              'Làm thế nào để thay đổi mô hình AI?',
              'Bạn có thể thay đổi mô hình AI bằng cách nhấp vào nút mô hình ở góc phải của thanh tiêu đề trong màn hình trò chuyện.',
            ),
            _buildFaqItem(
              'Làm thế nào để đăng xuất?',
              'Bạn có thể đăng xuất bằng cách nhấp vào nút đăng xuất ở góc phải của thanh tiêu đề trong màn hình chính.',
            ),
            
            const Divider(height: 32),
            
            // Support links
            const Text(
              'Liên kết hỗ trợ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSupportLink(
              'Trang web chính thức',
              'Truy cập trang web chính thức của chúng tôi',
              'https://jarvis.ai',
              Icons.language,
            ),
            _buildSupportLink(
              'Hướng dẫn sử dụng',
              'Xem hướng dẫn sử dụng chi tiết',
              'https://jarvis.ai/docs',
              Icons.menu_book,
            ),
            _buildSupportLink(
              'Chính sách bảo mật',
              'Đọc chính sách bảo mật của chúng tôi',
              'https://jarvis.ai/privacy',
              Icons.privacy_tip,
            ),
            
            const Divider(height: 32),
            
            // Feedback form
            const Text(
              'Gửi phản hồi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _feedbackController,
              decoration: const InputDecoration(
                hintText: 'Nhập phản hồi của bạn tại đây...',
                border: OutlineInputBorder(),
                labelText: 'Phản hồi',
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSending ? null : _sendFeedback,
                child: _isSending
                    ? const CircularProgressIndicator()
                    : const Text('Gửi phản hồi'),
              ),
            ),
            
            const SizedBox(height: 32),
            const Center(
              child: Text(
                'Phiên bản 1.0.0',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(answer),
        ),
      ],
    );
  }

  Widget _buildSupportLink(String title, String subtitle, String url, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _launchURL(url),
    );
  }
}