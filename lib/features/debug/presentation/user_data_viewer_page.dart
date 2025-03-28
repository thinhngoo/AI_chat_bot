import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/api/jarvis_api_service.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../tools/windows_user_data_tool.dart';

class UserDataViewerPage extends StatefulWidget {
  const UserDataViewerPage({super.key});

  @override
  State<UserDataViewerPage> createState() => _UserDataViewerPageState();
}

class _UserDataViewerPageState extends State<UserDataViewerPage> with SingleTickerProviderStateMixin {
  final Logger _logger = Logger();
  final AuthService _authService = AuthService();
  final JarvisApiService _apiService = JarvisApiService();
  
  late TabController _tabController;
  
  Map<String, dynamic> _userData = {};
  Map<String, dynamic> _apiConfig = {};
  Map<String, dynamic> _envConfig = {};
  List<Map<String, dynamic>> _storedUsers = [];
  String _prefsPath = '';
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get user info
      final user = _authService.currentUser;
      
      // Get API config
      final apiConfig = _apiService.getApiConfig();
      
      // Get .env variables (sanitized)
      final envConfig = await _getEnvVariables();
      
      // Get stored users from SharedPreferences
      final storedUsers = await WindowsUserDataTool.getStoredUsers();
      
      // Get SharedPreferences path
      final prefsPath = await WindowsUserDataTool.getSharedPreferencesPath() ?? 'Unknown';
      
      if (!mounted) return;
      
      setState(() {
        if (user != null) {
          _userData = user.toMap(); // Use toMap() directly without checking type
        } else {
          _userData = {'status': 'No user logged in'};
        }
        
        _apiConfig = Map<String, dynamic>.from(apiConfig);
        _envConfig = envConfig;
        _storedUsers = storedUsers;
        _prefsPath = prefsPath;
        _isLoading = false;
      });
    } catch (e) {
      _logger.e('Error loading user data: $e');
      
      if (!mounted) return;
      
      setState(() {
        _userData = {'error': e.toString()};
        _isLoading = false;
      });
    }
  }
  
  Future<Map<String, dynamic>> _getEnvVariables() async {
    final result = <String, dynamic>{};
    
    try {
      if (dotenv.isInitialized) {
        // Get environment variables but mask sensitive data
        result['AUTH_API_URL'] = dotenv.env['AUTH_API_URL'] ?? 'Not set';
        result['JARVIS_API_URL'] = dotenv.env['JARVIS_API_URL'] ?? 'Not set';
        
        // Mask API key
        final apiKey = dotenv.env['JARVIS_API_KEY'];
        if (apiKey != null && apiKey.isNotEmpty) {
          result['JARVIS_API_KEY'] = '${apiKey.substring(0, 4)}...${apiKey.length} chars';
        } else {
          result['JARVIS_API_KEY'] = 'Not set';
        }
        
        // Mask Stack Project ID
        final stackProjectId = dotenv.env['STACK_PROJECT_ID'];
        if (stackProjectId != null && stackProjectId.isNotEmpty) {
          result['STACK_PROJECT_ID'] = '${stackProjectId.substring(0, 6)}...';
        } else {
          result['STACK_PROJECT_ID'] = 'Not set';
        }
        
        // Mask Stack Publishable Client Key
        final stackKey = dotenv.env['STACK_PUBLISHABLE_CLIENT_KEY'];
        if (stackKey != null && stackKey.isNotEmpty) {
          result['STACK_PUBLISHABLE_CLIENT_KEY'] = '${stackKey.substring(0, 4)}...${stackKey.length} chars';
        } else {
          result['STACK_PUBLISHABLE_CLIENT_KEY'] = 'Not set';
        }
      } else {
        result['dotenv'] = 'Not initialized';
      }
    } catch (e) {
      _logger.e('Error getting env variables: $e');
      result['error'] = e.toString();
    }
    
    return result;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Data Viewer'),
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
                  _buildSection('User Info', _userData),
                  _buildDivider(),
                  _buildSection('API Configuration', _apiConfig),
                  _buildDivider(),
                  _buildSection('Environment Variables', _envConfig),
                  _buildDivider(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stored Users',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('SharedPreferences Path: $_prefsPath'),
                              const SizedBox(height: 8),
                              _buildStoredUsersList(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  _buildDivider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _testConnection,
                        child: const Text('Test API Connection'),
                      ),
                      ElevatedButton(
                        onPressed: _clearTokens,
                        child: const Text('Clear Auth Tokens'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildSection(String title, Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: data.entries.map<Widget>((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${entry.key}:',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(_formatValue(entry.value)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStoredUsersList() {
    if (_storedUsers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('No stored users found'),
      );
    }
    
    return Column(
      children: _storedUsers.map((user) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            title: Text(user['email'] ?? 'Unknown email'),
            subtitle: Text('UID: ${user['uid'] ?? 'No UID'}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _removeUser(user['email']),
            ),
          ),
        );
      }).toList(),
    );
  }
  
  Future<void> _removeUser(String? email) async {
    if (email == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove User'),
        content: Text('Are you sure you want to remove user $email?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await WindowsUserDataTool.removeUser(email);
        _loadUserData(); // Refresh data
      } catch (e) {
        _logger.e('Error removing user: $e');
      }
    }
  }
  
  Widget _buildDivider() {
    return const Divider(height: 32);
  }
  
  String _formatValue(dynamic value) {
    if (value == null) return 'null';
    if (value is bool) return value ? 'true' : 'false';
    if (value is Map || value is List) return value.toString();
    return value.toString();
  }
  
  Future<void> _testConnection() async {
    try {
      final isConnected = await _apiService.checkApiStatus();
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isConnected
                ? 'Connection successful!'
                : 'Connection failed. Check API configuration.',
          ),
          backgroundColor: isConnected ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _clearTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(ApiConstants.accessTokenKey);
      await prefs.remove(ApiConstants.refreshTokenKey);
      await prefs.remove(ApiConstants.userIdKey);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Auth tokens cleared. App restart may be required.'),
        ),
      );
      
      _loadUserData(); // Refresh the data
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing tokens: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
