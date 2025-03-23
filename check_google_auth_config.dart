import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'lib/core/utils/config/firebase_config_checker.dart';

/// Simple script to check Google Auth configuration status
/// 
/// Run this from the command line with:
/// flutter run -d windows lib/check_google_auth_config.dart

final Logger _logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load();
  _logger.i('Loaded .env file');
  
  // Skip Firebase initialization since we don't have firebase_options.dart
  _logger.i('Skipping Firebase initialization (running in config check mode only)');
  
  // Check configuration status
  await FirebaseConfigChecker.printConfigStatus();
  
  // Display visual UI with results
  runApp(const ConfigCheckerApp());
}

class ConfigCheckerApp extends StatelessWidget {
  const ConfigCheckerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ConfigCheckerScreen(),
    );
  }
}

class ConfigCheckerScreen extends StatefulWidget {
  const ConfigCheckerScreen({super.key});

  @override
  State<ConfigCheckerScreen> createState() => _ConfigCheckerScreenState();
}

class _ConfigCheckerScreenState extends State<ConfigCheckerScreen> {
  Map<String, dynamic> _configStatus = {
    'isConfigured': false,
    'messages': <String>['Checking configuration...'],
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkConfiguration();
  }

  Future<void> _checkConfiguration() async {
    final configStatus = await FirebaseConfigChecker.checkGoogleSignInConfig();
    
    if (mounted) {
      setState(() {
        _configStatus = configStatus;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Auth Configuration Checker'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: _configStatus['isConfigured'] ? Colors.green.shade100 : Colors.red.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _configStatus['isConfigured'] ? Icons.check_circle : Icons.error,
                                color: _configStatus['isConfigured'] ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _configStatus['isConfigured']
                                    ? 'Configuration Valid'
                                    : 'Configuration Issues Found',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text('Web Client ID:'),
                          Text(
                            _configStatus['webClientID'] ?? 'Not configured',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _configStatus['webClientID'] != null ? Colors.black : Colors.red,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text('Firebase Initialized:'),
                          Text(
                            (_configStatus['firebaseInitialized'] ?? false) ? 'Yes' : 'No',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: (_configStatus['firebaseInitialized'] ?? false) ? Colors.black : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Details:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: (_configStatus['messages'] as List).length,
                      itemBuilder: (context, index) {
                        final message = (_configStatus['messages'] as List)[index];
                        return ListTile(
                          leading: Icon(
                            message.contains('WARNING') || message.contains('NOT')
                                ? Icons.warning
                                : Icons.info,
                            color: message.contains('WARNING') || message.contains('NOT')
                                ? Colors.orange
                                : Colors.blue,
                          ),
                          title: Text(message),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
