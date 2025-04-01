import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'core/services/auth/auth_service.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/chat/services/chat_service.dart';
import 'features/chat/models/conversation_message.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the auth service
  await AuthService().initializeService();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Authentication App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthCheckPage(),
    );
  }
}

class AuthCheckPage extends StatefulWidget {
  const AuthCheckPage({super.key});

  @override
  State<AuthCheckPage> createState() => _AuthCheckPageState();
}

class _AuthCheckPageState extends State<AuthCheckPage> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      
      if (!mounted) return;
      
      if (isLoggedIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
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
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : const Text('Checking authentication status...'),
      ),
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  final Logger _logger = Logger(); // Add logger instance
  
  bool _isLoading = true;
  String _errorMessage = '';
  List<ConversationMessage> _messages = [];
  
  @override
  void initState() {
    super.initState();
    _fetchConversationHistory();
  }
  
  Future<void> _fetchConversationHistory() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      // First fetch the list of conversations to get a valid ID
      _logger.i('Fetching list of conversations');
      
      try {
        final conversations = await _chatService.getConversations();
        
        if (conversations.isEmpty) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'No conversations found. Start a new conversation to view history.';
          });
          return;
        }
        
        // Get the first conversation's ID from the result
        final conversationId = conversations.first['id'];
        _logger.i('Using conversation ID: $conversationId');
        
        final response = await _chatService.getConversationHistory(
          conversationId,
          assistantId: 'gpt-4o-mini', // Optional, choose a model
        );
        
        if (mounted) {
          setState(() {
            _messages = response.items;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = e.toString();
            _isLoading = false;
          });
          
          _logger.e('Error fetching conversations: $e');
          
          // Don't attempt to fetch conversation history if we can't get the list
          return;
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
        
        _logger.e('Error in _fetchConversationHistory: $e');
        
        // Show more user-friendly error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to load conversations: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text('Error: $_errorMessage'))
              : _messages.isEmpty
                  ? const Center(child: Text('No conversation history found'))
                  : ListView.builder(
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return Column(
                          children: [
                            // User message
                            ListTile(
                              title: Text(message.query),
                              subtitle: Text(
                                DateTime.fromMillisecondsSinceEpoch(message.createdAt * 1000)
                                    .toString(),
                              ),
                              leading: const CircleAvatar(child: Icon(Icons.person)),
                            ),
                            // AI response
                            ListTile(
                              title: Text(message.answer),
                              leading: const CircleAvatar(child: Icon(Icons.smart_toy)),
                            ),
                            const Divider(),
                          ],
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchConversationHistory,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}