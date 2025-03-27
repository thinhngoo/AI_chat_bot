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
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading users: $e')),
      );
    }
  }
  
  Future<void> _deleteUser(int index) async {
    try {
      final user = _users[index];
      final email = user['email'];
      
      if (email == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot delete: No email found')),
        );
        return;
      }
      
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete User Data'),
          content: Text('Are you sure you want to delete user data for $email?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        ),
      );
      
      if (confirmed != true) return;
      
      final success = await WindowsUserDataTool.removeUser(email);
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User data for $email deleted')),
        );
        _loadUsers(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete user data for $email')),
        );
      }
    } catch (e) {
      _logger.e('Error deleting user: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  
  Future<void> _clearAllUsers() async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Clear All User Data'),
          content: const Text(
            'Are you sure you want to delete ALL user data? '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Clear All'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        ),
      );
      
      if (confirmed != true) return;
      
      final success = await WindowsUserDataTool.clearAllUsers();
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All user data cleared')),
        );
        _loadUsers(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to clear user data')),
        );
      }
    } catch (e) {
      _logger.e('Error clearing all users: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SharedPreferences Path:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(_prefsPath ?? 'Unknown'),
                      const SizedBox(height: 16),
                      Text(
                        'Stored Users (${_users.length}):',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _users.isEmpty
                      ? const Center(child: Text('No stored users found'))
                      : ListView.builder(
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 4.0,
                              ),
                              child: ExpansionTile(
                                title: Text(user['email'] ?? 'Unknown email'),
                                subtitle: Text('UID: ${user['uid'] ?? 'No UID'}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteUser(index),
                                  tooltip: 'Delete user data',
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: user.entries.map((entry) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(
                                                width: 120,
                                                child: Text(
                                                  '${entry.key}:',
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  entry.value?.toString() ?? 'null',
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
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
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_users.length} users'),
              TextButton.icon(
                icon: const Icon(Icons.delete_forever),
                label: const Text('Clear All'),
                onPressed: _users.isEmpty ? null : _clearAllUsers,
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
