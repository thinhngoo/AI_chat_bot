import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../core/services/api/jarvis_api_service.dart';
import '../../../core/services/chat/jarvis_chat_service.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../features/support/presentation/help_feedback_page.dart';
import '../../../features/account/presentation/account_management_page.dart';
import '../../../features/debug/presentation/user_data_viewer_page.dart';
import '../../auth/presentation/login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final Logger _logger = Logger();
  final AuthService _authService = AuthService();
  final JarvisApiService _apiService = JarvisApiService();
  final JarvisChatService _chatService = JarvisChatService();
  
  bool _isLoading = false;
  bool _isSendingTestMessage = false;
  String? _userEmail;
  String? _userName;
  
  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }
  
  Future<void> _loadUserInfo() async {
    try {
      final user = await _apiService.getCurrentUser();
      
      if (mounted) {
        setState(() {
          _userEmail = user?.email;
          _userName = user?.name;
        });
      }
    } catch (e) {
      _logger.e('Error loading user info: $e');
    }
  }
  
  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _authService.signOut();
      
      if (!mounted) return;
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      _logger.e('Error signing out: $e');
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi đăng xuất: ${e.toString()}')),
      );
    }
  }
  
  Future<void> _testAPIConnection() async {
    setState(() {
      _isSendingTestMessage = true;
    });
    
    try {
      final isConnected = await _apiService.checkApiStatus();
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isConnected
                ? 'Kết nối API thành công!'
                : 'Kết nối API thất bại. Vui lòng kiểm tra cấu hình.',
          ),
          backgroundColor: isConnected ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      _logger.e('Test API connection error: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi kiểm tra kết nối: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingTestMessage = false;
        });
      }
    }
  }
  
  void _resetApiErrorState() {
    _chatService.resetApiErrorState();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã đặt lại trạng thái lỗi API'),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Account section
                ListTile(
                  title: const Text(
                    'Tài khoản',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  leading: const Icon(Icons.person, color: Colors.blue),
                ),
                Divider(color: Colors.grey.shade300),
                
                ListTile(
                  title: Text(_userName ?? 'Người dùng'),
                  subtitle: Text(_userEmail ?? 'Không có thông tin'),
                  leading: const Icon(Icons.account_circle),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AccountManagementPage(),
                      ),
                    ).then((_) => _loadUserInfo());
                  },
                ),
                
                ListTile(
                  title: const Text('Đăng xuất'),
                  leading: const Icon(Icons.logout),
                  onTap: _logout,
                ),
                
                const SizedBox(height: 16),
                
                // Support section
                ListTile(
                  title: const Text(
                    'Hỗ trợ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  leading: const Icon(Icons.help, color: Colors.blue),
                ),
                Divider(color: Colors.grey.shade300),
                
                ListTile(
                  title: const Text('Trợ giúp & Phản hồi'),
                  leading: const Icon(Icons.help_outline),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HelpFeedbackPage(),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Diagnostics section
                ListTile(
                  title: const Text(
                    'Chẩn đoán',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  leading: const Icon(Icons.bug_report, color: Colors.blue),
                ),
                Divider(color: Colors.grey.shade300),
                
                ListTile(
                  title: const Text('Thông tin người dùng'),
                  subtitle: const Text('Xem thông tin chi tiết về người dùng và cấu hình'),
                  leading: const Icon(Icons.info_outline),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserDataViewerPage(),
                      ),
                    );
                  },
                ),
                
                ListTile(
                  title: const Text('Kiểm tra kết nối API'),
                  leading: const Icon(Icons.network_check),
                  trailing: _isSendingTestMessage
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _isSendingTestMessage ? null : _testAPIConnection,
                ),
                
                ListTile(
                  title: const Text('Đặt lại trạng thái lỗi API'),
                  subtitle: const Text('Đặt lại trạng thái lỗi để thử kết nối lại'),
                  leading: const Icon(Icons.refresh),
                  onTap: _resetApiErrorState,
                ),
                
                const SizedBox(height: 16),
                
                // About section
                ListTile(
                  title: const Text(
                    'Thông tin',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  leading: const Icon(Icons.info, color: Colors.blue),
                ),
                Divider(color: Colors.grey.shade300),
                
                const ListTile(
                  title: Text('AI Chat Bot'),
                  subtitle: Text('Phiên bản 1.0.0'),
                  leading: Icon(Icons.app_settings_alt),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
    );
  }
}