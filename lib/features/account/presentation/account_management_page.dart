import 'package:flutter/material.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../widgets/auth/auth_widgets.dart';
import '../../../core/utils/validators/password_validator.dart';
import '../../../core/services/api/jarvis_api_service.dart';

class AccountManagementPage extends StatefulWidget {
  const AccountManagementPage({super.key});

  @override
  AccountManagementPageState createState() => AccountManagementPageState();
}

class AccountManagementPageState extends State<AccountManagementPage> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  final JarvisApiService _apiService = JarvisApiService();
  bool _isLoading = false;
  String _emailAddress = '';
  String _passwordStrength = '';
  bool _isEmailVerified = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _passwordStrength = PasswordValidator.getPasswordStrength('');
  }

  Future<void> _loadUserInfo() async {
    dynamic user = _authService.currentUser;
    if (user != null) {
      setState(() {
        // For Jarvis API, currentUser is the UserModel
        _emailAddress = user is String ? user : user.email ?? 'Unknown';
        _isEmailVerified = _authService.isEmailVerified();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể tải thông tin người dùng')),
      );
    }
  }

  Future<void> _updatePassword() async {
    // Validate password
    if (_newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mật khẩu mới')),
      );
      return;
    }

    if (!PasswordValidator.isValidPassword(_newPasswordController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(
          'Mật khẩu mới phải có ít nhất 8 ký tự, bao gồm chữ hoa, '
          'chữ thường, số và ký tự đặc biệt'
        )),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu mới không khớp')),
      );
      return;
    }

    // Validate current password is not empty
    if (_currentPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mật khẩu hiện tại')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Use the Jarvis API to update password
      final success = await _apiService.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text
      );
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mật khẩu đã được cập nhật thành công')),
        );
        
        // Clear password fields
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        setState(() {
          _passwordStrength = '';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể cập nhật mật khẩu. Vui lòng thử lại.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Email verification is handled automatically by Jarvis API
  Future<void> _resendVerificationEmail() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng này không được hỗ trợ bởi API hiện tại')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý tài khoản')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Account info card
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thông tin tài khoản',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.email),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_emailAddress)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.verified_user),
                            const SizedBox(width: 8),
                            Text(
                              'Email: ${_isEmailVerified ? 'Đã xác minh' : 'Chưa xác minh'}',
                              style: TextStyle(
                                color: _isEmailVerified ? Colors.green : Colors.red,
                              ),
                            ),
                            if (!_isEmailVerified) ...[
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: _resendVerificationEmail,
                                child: const Text('Gửi lại email xác minh'),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Password change section
                const Text(
                  'Thay đổi mật khẩu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _currentPasswordController,
                  labelText: 'Mật khẩu hiện tại',
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _newPasswordController,
                  labelText: 'Mật khẩu mới',
                  onChanged: (value) {
                    setState(() {
                      _passwordStrength = PasswordValidator.getPasswordStrength(value);
                    });
                  },
                ),
                Text(
                  'Độ mạnh: $_passwordStrength',
                  style: TextStyle(
                    color: PasswordValidator.getPasswordStrengthColor(_passwordStrength),
                  ),
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _confirmPasswordController,
                  labelText: 'Xác nhận mật khẩu mới',
                ),
                const SizedBox(height: 24),
                SubmitButton(
                  label: 'Cập nhật mật khẩu',
                  onPressed: _updatePassword,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}