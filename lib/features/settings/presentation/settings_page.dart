import 'package:flutter/material.dart';
import '../../../core/services/firestore/firestore_data_service.dart';
import '../../../core/utils/firebase/firebase_rules_helper.dart';
import '../../../core/services/auth/auth_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AuthService _authService = AuthService();
  bool _isUsingFirebase = false;

  @override
  void initState() {
    super.initState();
    _isUsingFirebase = _authService.isUsingFirebaseAuth();
  }

  Widget _buildFirestoreSection() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Firebase Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Reset Firestore Permissions'),
              subtitle: const Text('Clears error state if you\'ve updated Firebase rules'),
              trailing: const Icon(Icons.refresh),
              onTap: () {
                final firestoreService = FirestoreDataService();
                firestoreService.resetPermissionCheck();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Firestore permissions check reset. Next operations will try accessing Firestore.'),
                  )
                );
              },
            ),
            ListTile(
              title: const Text('View Recommended Rules'),
              subtitle: const Text('Shows Firebase security rules required for this app'),
              trailing: const Icon(Icons.security),
              onTap: () {
                FirebaseRulesHelper.showFirestoreRulesDialog(context);
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
            // Only show Firebase section if using Firebase Auth
            if (_isUsingFirebase) _buildFirestoreSection(),
            
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