import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
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
              title: const Text('Quản lý tài khoản'),
              subtitle: const Text('Thay đổi mật khẩu, email và các thông tin khác'),
              leading: const Icon(Icons.person),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AccountManagementPage(),
                  ),
                );
              },
            ),
            // Add new item for user data viewer
            ListTile(
              title: const Text('Xem dữ liệu người dùng'),
              subtitle: const Text('Xem thông tin dữ liệu đã lưu'),
              leading: const Icon(Icons.data_usage),
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
              'Appearance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Enable dark theme throughout the app'),
              value: true, // This should be connected to a theme provider
              onChanged: (bool value) {
                // Update theme
              },
            ),
            ListTile(
              title: const Text('Font Size'),
              subtitle: const Text('Change text size throughout the app'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Show font size options
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
              'Storage',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Clear Chat History'),
              subtitle: const Text('Remove all chat sessions from this device'),
              trailing: const Icon(Icons.delete_outline),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear Chat History'),
                    content: const Text('This will delete all chat history. This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          // Clear chat history
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Chat history cleared')),
                          );
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
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
              'API Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Reset API Connection'),
              subtitle: const Text('Clear API error state if you\'ve fixed connectivity issues'),
              trailing: const Icon(Icons.refresh),
              onTap: () {
                // Reset API connection
                _chatService.resetApiErrorState();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('API connection reset. Next operations will try reconnecting.'),
                  )
                );
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
              'API Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('API URL'),
              subtitle: Text(apiConfig['jarvisApiUrl'] ?? 'Not configured'),
              leading: const Icon(Icons.cloud),
            ),
            ListTile(
              title: const Text('Authentication Status'),
              subtitle: Text(apiConfig['isAuthenticated'] ?? 'Unknown'),
              leading: const Icon(Icons.security),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                final bool isAvailable = await apiService.checkApiStatus();
                // Show status dialog
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(isAvailable ? 'API is Available' : 'API is Unavailable'),
                      content: Text(
                        isAvailable 
                            ? 'The Jarvis API is responding correctly.' 
                            : 'Cannot connect to the Jarvis API. Please check your configuration and internet connection.'
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              },
              child: const Text('Test API Connection'),
            ),
          ],
        ),
      ),
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