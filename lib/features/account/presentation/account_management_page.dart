import 'package:flutter/material.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../widgets/auth/auth_widgets.dart';
import '../../../core/utils/validators/password_validator.dart';
import '../../../core/services/api/jarvis_api_service.dart';
import 'package:logger/logger.dart';

class AccountManagementPage extends StatefulWidget {
  const AccountManagementPage({super.key});

  @override
  AccountManagementPageState createState() => AccountManagementPageState();
}

class AccountManagementPageState extends State<AccountManagementPage> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _metadataKeyController = TextEditingController();
  final _metadataValueController = TextEditingController();
  final AuthService _authService = AuthService();
  final JarvisApiService _apiService = JarvisApiService();
  final Logger _logger = Logger();
  
  bool _isLoading = false;
  String _emailAddress = '';
  String _passwordStrength = '';
  bool _isEmailVerified = false;
  Map<String, dynamic> _clientMetadata = {};
  Map<String, dynamic> _clientReadOnlyMetadata = {};

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = _authService.currentUser;
      
      if (user != null) {
        setState(() {
          _emailAddress = user.email;
          _isEmailVerified = user.isEmailVerified;
          _clientMetadata = user.clientMetadata ?? {};
          _clientReadOnlyMetadata = user.clientReadOnlyMetadata ?? {};
        });
      } else {
        // Try to reload user data
        await _authService.reloadUser();
        final refreshedUser = _authService.currentUser;
        
        if (refreshedUser != null) {
          setState(() {
            _emailAddress = refreshedUser.email;
            _isEmailVerified = refreshedUser.isEmailVerified;
            _clientMetadata = refreshedUser.clientMetadata ?? {};
            _clientReadOnlyMetadata = refreshedUser.clientReadOnlyMetadata ?? {};
          });
        }
      }
    } catch (e) {
      _logger.e('Error loading user info: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user information: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updatePassword() async {
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
      final success = await _apiService.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text
      );
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mật khẩu đã được cập nhật thành công')),
        );
        
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
  
  Future<void> _updateClientMetadata() async {
    final key = _metadataKeyController.text.trim();
    final value = _metadataValueController.text.trim();
    
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a key')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final success = await _authService.updateClientMetadata({key: value});
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Client metadata updated successfully')),
        );
        
        _metadataKeyController.clear();
        _metadataValueController.clear();
        
        await _loadUserInfo();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update client metadata')),
        );
      }
    } catch (e) {
      _logger.e('Error updating client metadata: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating client metadata: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Management'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Account Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            title: const Text('Email'),
                            subtitle: Text(_emailAddress),
                            trailing: _isEmailVerified
                                ? const Icon(Icons.verified, color: Colors.green)
                                : const Icon(Icons.warning, color: Colors.orange),
                          ),
                          if (!_isEmailVerified)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.info, color: Colors.orange, size: 16),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Email not verified',
                                    style: TextStyle(color: Colors.orange),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () {
                                      // Implement resend verification email functionality
                                    },
                                    child: const Text('Resend Verification'),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Change Password',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          PasswordField(
                            controller: _currentPasswordController,
                            labelText: 'Current Password',
                          ),
                          const SizedBox(height: 16),
                          PasswordField(
                            controller: _newPasswordController,
                            labelText: 'New Password',
                            onChanged: (value) {
                              setState(() {
                                _passwordStrength = PasswordValidator.getPasswordStrength(value);
                              });
                            },
                          ),
                          
                          if (_newPasswordController.text.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: PasswordValidator.getPasswordStrengthRatio(_passwordStrength),
                              color: PasswordValidator.getPasswordStrengthColor(_passwordStrength),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Password strength: $_passwordStrength',
                              style: TextStyle(
                                color: PasswordValidator.getPasswordStrengthColor(_passwordStrength),
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 16),
                          PasswordField(
                            controller: _confirmPasswordController,
                            labelText: 'Confirm New Password',
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _updatePassword,
                            child: const Text('Update Password'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Client Metadata',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'User-editable custom data for your account',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          
                          if (_clientMetadata.isEmpty)
                            const Text('No client metadata set')
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _clientMetadata.length,
                              itemBuilder: (context, index) {
                                final key = _clientMetadata.keys.elementAt(index);
                                final value = _clientMetadata[key];
                                return ListTile(
                                  title: Text(key),
                                  subtitle: Text(value.toString()),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () async {
                                      await _authService.updateClientMetadata({key: null});
                                      _loadUserInfo();
                                    },
                                  ),
                                );
                              },
                            ),
                          
                          const SizedBox(height: 16),
                          
                          TextField(
                            controller: _metadataKeyController,
                            decoration: const InputDecoration(
                              labelText: 'Metadata Key',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _metadataValueController,
                            decoration: const InputDecoration(
                              labelText: 'Metadata Value',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _updateClientMetadata,
                            child: const Text('Add/Update Metadata'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  if (_clientReadOnlyMetadata.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Client Read-Only Metadata',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Server-controlled data visible to clients',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _clientReadOnlyMetadata.length,
                              itemBuilder: (context, index) {
                                final key = _clientReadOnlyMetadata.keys.elementAt(index);
                                final value = _clientReadOnlyMetadata[key];
                                return ListTile(
                                  title: Text(key),
                                  subtitle: Text(value.toString()),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
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
    _metadataKeyController.dispose();
    _metadataValueController.dispose();
    super.dispose();
  }
}