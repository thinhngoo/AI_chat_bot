import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/api/jarvis_api_service.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/services/platform/platform_service_helper.dart';

class UserDataViewerPage extends StatefulWidget {
  const UserDataViewerPage({super.key});

  @override
  State<UserDataViewerPage> createState() => _UserDataViewerPageState();
}

class _UserDataViewerPageState extends State<UserDataViewerPage> {
  final Logger _logger = Logger();
  final JarvisApiService _apiService = JarvisApiService();
  final AuthService _authService = AuthService();
  
  bool _isLoading = true;
  Map<String, dynamic> _userData = {};
  Map<String, String> _tokenData = {};
  List<Map<String, dynamic>> _localUsers = [];
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      // 1. Lấy dữ liệu từ Jarvis API nếu đã đăng nhập - Fix boolean condition
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        final currentUser = await _apiService.getCurrentUser();
        if (currentUser != null) {
          _userData = currentUser.toMap();
        }
      }
      
      // 2. Lấy thông tin token từ SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('jarvis_access_token') ?? 'Không có';
      final refreshToken = prefs.getString('jarvis_refresh_token') ?? 'Không có';
      final userId = prefs.getString('jarvis_user_id') ?? 'Không có';
      
      _tokenData = {
        'Access Token': _maskToken(accessToken),
        'Refresh Token': _maskToken(refreshToken),
        'User ID': userId,
      };
      
      // 3. Lấy dữ liệu người dùng local (Windows)
      if (PlatformServiceHelper.isDesktopWindows) {
        _localUsers = await PlatformServiceHelper.getUsers();
      }
      
    } catch (e) {
      _logger.e('Error loading user data: $e');
      // Check if widget is still mounted before using context
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải dữ liệu: $e')),
      );
    } finally {
      // Check if widget is still mounted before calling setState
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  // Che dấu token để bảo mật
  String _maskToken(String token) {
    if (token.length <= 10) return '*' * token.length;
    return '${token.substring(0, 5)}...${token.substring(token.length - 5)}';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xem Dữ Liệu Người Dùng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hiển thị thông tin người dùng từ API
                  Card(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dữ liệu từ Jarvis API',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          _userData.isEmpty
                              ? const Text('Không có dữ liệu hoặc chưa đăng nhập')
                              : _buildDataTable(_userData),
                        ],
                      ),
                    ),
                  ),
                  
                  // Hiển thị thông tin token
                  Card(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Thông tin Token đăng nhập',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          _buildTokenTable(_tokenData),
                        ],
                      ),
                    ),
                  ),
                  
                  // Hiển thị dữ liệu người dùng cục bộ (Windows)
                  if (PlatformServiceHelper.isDesktopWindows) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dữ liệu cục bộ (Windows)',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(),
                            _localUsers.isEmpty
                                ? const Text('Không có dữ liệu người dùng cục bộ')
                                : _buildLocalUsersTable(_localUsers),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
  
  Widget _buildDataTable(Map<String, dynamic> data) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(2),
      },
      border: TableBorder.all(
        color: Colors.grey.shade300,
        width: 1,
      ),
      children: data.entries.map((entry) {
        final value = entry.value is DateTime
            ? entry.value.toString()
            : entry.value?.toString() ?? 'null';
        
        return TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                entry.key,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(value),
            ),
          ],
        );
      }).toList(),
    );
  }
  
  Widget _buildTokenTable(Map<String, String> data) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(2),
      },
      border: TableBorder.all(
        color: Colors.grey.shade300,
        width: 1,
      ),
      children: data.entries.map((entry) {
        return TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                entry.key,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(entry.value),
            ),
          ],
        );
      }).toList(),
    );
  }
  
  Widget _buildLocalUsersTable(List<Map<String, dynamic>> users) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: users.map((user) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: user.entries.map((entry) {
                // Mask password
                final value = entry.key == 'password'
                    ? '********'
                    : entry.value?.toString() ?? 'null';
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Text(
                        '${entry.key}: ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Expanded(child: Text(value)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      }).toList(),
    );
  }
}
