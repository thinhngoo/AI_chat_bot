import 'package:flutter/material.dart';
import '../../../core/services/api/jarvis_api_service.dart';
import '../../../core/services/chat/jarvis_chat_service.dart';
import '../../../features/account/presentation/account_management_page.dart';
import '../../../features/debug/presentation/user_data_viewer_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  final JarvisChatService _chatService = JarvisChatService();
  bool _isDarkMode = false;
  
  @override
  void initState() {
    super.initState();
    // Removed the call to _loadUserModel()
  }

  Widget _buildAccountSection() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tài khoản',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Quản lý tài khoản'),
              subtitle: const Text('Thay đổi mật khẩu, thông tin cá nhân'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AccountManagementPage()),
                );
              },
            ),
            // Add new item for user data viewer
            ListTile(
              leading: const Icon(Icons.data_usage),
              title: const Text('Xem dữ liệu người dùng'),
              subtitle: const Text('Kiểm tra thông tin và trạng thái đăng nhập'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserDataViewerPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceSection() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Giao diện',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Chế độ tối'),
              subtitle: const Text('Thay đổi giao diện sang màu tối'),
              value: _isDarkMode,
              onChanged: (value) {
                setState(() {
                  _isDarkMode = value;
                });
                // Implement dark mode functionality in a real app
              },
            ),
            ListTile(
              leading: const Icon(Icons.font_download),
              title: const Text('Kích thước chữ'),
              subtitle: const Text('Điều chỉnh kích thước chữ hiển thị'),
              onTap: () {
                // Font size selection would be implemented here
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageSection() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lưu trữ & Dữ liệu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Xóa lịch sử trò chuyện'),
              subtitle: const Text('Xóa tất cả các cuộc trò chuyện'),
              onTap: () {
                _showClearHistoryDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiSection() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'API & Tích hợp',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.api),
              title: const Text('Cài đặt API'),
              subtitle: const Text('Xem và quản lý cài đặt API'),
              onTap: () {
                // Navigate to API settings
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiSettingsCard() {
    final JarvisApiService apiService = JarvisApiService();
    final apiConfig = apiService.getApiConfig();
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin API',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.cloud),
              title: const Text('Jarvis API URL'),
              subtitle: Text(apiConfig['jarvisApiUrl'] ?? 'Not configured'),
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('API Authentication'),
              subtitle: Text('Status: ${apiConfig['isAuthenticated']}'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _testApiConnection(context),
              child: const Text('Test API Connection'),
            ),
          ],
        ),
      ),
    );
  }
  
  // New method to test API connection with proper context handling
  Future<void> _testApiConnection(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      // Show loading indicator
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Testing API connection...')),
      );
      
      final apiService = JarvisApiService();
      final isConnected = await apiService.checkApiStatus();
      
      // Only proceed if the widget is still mounted
      if (!mounted) return;
      
      // Show result
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(isConnected 
              ? 'API connection successful!' 
              : 'API connection failed. Check your API configuration.'),
          backgroundColor: isConnected ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      // Only proceed if the widget is still mounted
      if (!mounted) return;
      
      // Show error
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error testing API connection: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xóa lịch sử'),
          content: const Text('Bạn có chắc chắn muốn xóa toàn bộ lịch sử trò chuyện?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                // Clear chat history would be implemented here
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa lịch sử trò chuyện')),
                );
              },
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAccountSection(),
            _buildApiSection(),
            _buildApiSettingsCard(),
            _buildAppearanceSection(),
            _buildStorageSection(),
            
            // Version info
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'AI Chat Bot v1.0.0',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}