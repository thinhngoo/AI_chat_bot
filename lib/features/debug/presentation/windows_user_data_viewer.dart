import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../tools/windows_user_data_tool.dart';

class WindowsUserDataViewer extends StatefulWidget {
  const WindowsUserDataViewer({super.key});

  @override
  State<WindowsUserDataViewer> createState() => _WindowsUserDataViewerState();
}

class _WindowsUserDataViewerState extends State<WindowsUserDataViewer> {
  final Logger _logger = Logger();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _prefsPath;
  
  @override
  void initState() {
    super.initState();
    _loadUsers();
  }
  
  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final users = await WindowsUserDataTool.getStoredUsers();
      final path = await WindowsUserDataTool.getSharedPreferencesPath();
      
      if (!mounted) return;
      
      setState(() {
        _users = users;
        _prefsPath = path;
        _isLoading = false;
      });
    } catch (e) {
      _logger.e('Error loading users: $e');
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _deleteUser(int index) async {
    if (index < 0 || index >= _users.length) return;
    
    try {
      final user = _users[index];
      final email = user['email'] as String?;
      
      if (email != null) {
        await WindowsUserDataTool.removeUser(email);
        _loadUsers(); // Reload the list
      }
    } catch (e) {
      _logger.e('Error deleting user: $e');
    }
  }
  
  Future<void> _clearAllUsers() async {
    try {
      await WindowsUserDataTool.clearAllUsers();
      _loadUsers(); // Reload the list
    } catch (e) {
      _logger.e('Error clearing all users: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Windows User Data'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Preferences Path: $_prefsPath'),
                ),
                Expanded(
                  child: _users.isEmpty
                      ? const Center(child: Text('No stored users'))
                      : ListView.builder(
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            return ListTile(
                              title: Text(user['email'] ?? 'Unknown email'),
                              subtitle: Text('UID: ${user['uid'] ?? 'No UID'}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteUser(index),
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: _clearAllUsers,
                    child: const Text('Clear All Users'),
                  ),
                ),
              ],
            ),
    );
  }
}
