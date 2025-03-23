import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

class WindowsUserDataViewer extends StatefulWidget {
  const WindowsUserDataViewer({super.key});

  @override
  State<WindowsUserDataViewer> createState() => _WindowsUserDataViewerState();
}

class _WindowsUserDataViewerState extends State<WindowsUserDataViewer> {
  final Logger _logger = Logger();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String _sharedPrefPath = 'Đang lấy đường dẫn...';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _getSharedPrefPath();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('users');

      if (usersJson == null || usersJson.isEmpty) {
        setState(() {
          _users = [];
          _isLoading = false;
        });
        return;
      }

      final List<dynamic> decoded = jsonDecode(usersJson);
      setState(() {
        _users = decoded.map((user) => Map<String, dynamic>.from(user)).toList();
        _isLoading = false;
      });
    } catch (e) {
      _logger.e('Lỗi khi đọc dữ liệu người dùng: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getSharedPrefPath() async {
    try {
      // SharedPreferences trên Windows thường được lưu tại đường dẫn:
      // %APPDATA%\Roaming\com.example.appname\SharedPreferences\
      const platform = MethodChannel('platform_channel');
      final String? path = await platform.invokeMethod('getSharedPreferencesPath');
      
      setState(() {
        _sharedPrefPath = path ?? 'C:\\Users\\<Tên người dùng>\\AppData\\Roaming\\<ID ứng dụng>\\SharedPreferences\\';
      });
    } catch (e) {
      setState(() {
        _sharedPrefPath = 'C:\\Users\\<Tên người dùng>\\AppData\\Roaming\\<ID ứng dụng>\\SharedPreferences\\';
      });
    }
  }

  Future<void> _deleteUser(int index) async {
    if (!mounted) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('users');
      if (usersJson == null) return;

      final List<dynamic> decoded = jsonDecode(usersJson);
      decoded.removeAt(index);
      await prefs.setString('users', jsonEncode(decoded));
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Người dùng đã được xóa')),
      );
      
      _loadUserData();
    } catch (e) {
      _logger.e('Lỗi khi xóa người dùng: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xóa người dùng: $e')),
      );
    }
  }

  Future<void> _clearAllUserData() async {
    if (!mounted) return;
    
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xóa tất cả dữ liệu?'),
          content: const Text('Hành động này sẽ xóa TẤT CẢ dữ liệu người dùng. Bạn có chắc chắn muốn tiếp tục?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Xóa tất cả'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('users', '[]');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa tất cả dữ liệu người dùng')),
      );
      
      _loadUserData();
    } catch (e) {
      _logger.e('Lỗi khi xóa dữ liệu: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xóa dữ liệu: $e')),
      );
    }
  }

  Future<void> _exportUserData() async {
    if (!mounted) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('users') ?? '[]';
      
      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: usersJson));
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dữ liệu người dùng đã được sao chép vào clipboard')),
      );
    } catch (e) {
      _logger.e('Lỗi khi xuất dữ liệu: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xuất dữ liệu: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dữ Liệu Người Dùng Windows'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: _loadUserData,
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Xuất dữ liệu',
            onPressed: _exportUserData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Info card showing storage location
          Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vị trí lưu trữ dữ liệu:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(_sharedPrefPath),
                  const SizedBox(height: 8),
                  const Text(
                    'Lưu ý: Dữ liệu người dùng được lưu dạng JSON trong SharedPreferences',
                    style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? const Center(child: Text('Không có dữ liệu người dùng nào được lưu trữ'))
                    : ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            child: ExpansionTile(
                              title: Text(
                                user['email'] ?? 'Không có email',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Tên: ${user['name'] ?? 'Không có tên'}',
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildDetailRow('Email', user['email'] ?? 'N/A'),
                                      _buildDetailRow('Tên người dùng', user['name'] ?? 'N/A'),
                                      _buildDetailRow('Mật khẩu', '********'),
                                      _buildDetailRow('Loại đăng nhập', user['loginType'] ?? 'email'),
                                      _buildDetailRow(
                                        'Đã xác minh', 
                                        user['isVerified'] == true ? 'Có' : 'Không'
                                      ),
                                      _buildDetailRow(
                                        'Ngày tạo', 
                                        user['createdAt'] ?? 'Không xác định'
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              // Copy to clipboard as formatted JSON
                                              Clipboard.setData(ClipboardData(
                                                text: const JsonEncoder.withIndent('  ')
                                                    .convert(user),
                                              ));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Đã sao chép thông tin vào clipboard'),
                                                ),
                                              );
                                            },
                                            child: const Text('Sao chép'),
                                          ),
                                          const SizedBox(width: 8),
                                          TextButton(
                                            onPressed: () => _deleteUser(index),
                                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                                            child: const Text('Xóa'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: _users.isNotEmpty
          ? FloatingActionButton(
              onPressed: _clearAllUserData,
              backgroundColor: Colors.red,
              tooltip: 'Xóa tất cả dữ liệu',
              child: const Icon(Icons.delete_forever),
            )
          : null,
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
