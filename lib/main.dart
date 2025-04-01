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
  final Logger _logger = Logger();
  
  bool _isLoading = true;
  String _errorMessage = '';
  List<ConversationMessage> _messages = [];
  String? _currentConversationId;
  
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;
  
  String _selectedAssistantId = 'gpt-4o-mini';
  
  @override
  void initState() {
    super.initState();
    _fetchConversationHistory();
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
  
  Future<void> _fetchConversationHistory() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      _logger.i('Fetching list of conversations');
      
      try {
        final conversations = await _chatService.getConversations();
        
        if (conversations.isEmpty) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'No conversations found. Start a new conversation below!';
            _currentConversationId = null;
          });
          return;
        }
        
        final conversationId = conversations.first['id'];
        _currentConversationId = conversationId;
        _logger.i('Using conversation ID: $conversationId');
        
        final response = await _chatService.getConversationHistory(
          conversationId,
          assistantId: _selectedAssistantId,
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
  
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    
    setState(() {
      _isSending = true;
    });
    
    try {
      _messageController.clear();
      
      final userMessage = ConversationMessage(
        query: message,
        answer: 'Thinking...',
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        files: [],
      );
      
      setState(() {
        _messages = [userMessage, ..._messages];
      });
      
      _logger.i('Sending message with conversation ID: $_currentConversationId');
      
      // Try with retry logic if first attempt fails
      Map<String, dynamic> response;
      try {
        response = await _chatService.sendMessage(
          content: message,
          assistantId: _selectedAssistantId,
          conversationId: _currentConversationId,
        );
      } catch (e) {
        // If error occurs and we have a conversation ID, try creating a new conversation
        if (_currentConversationId != null) {
          _logger.w('Error with existing conversation, trying to create new conversation');
          _currentConversationId = null;
          response = await _chatService.sendMessage(
            content: message,
            assistantId: _selectedAssistantId,
            conversationId: null,
          );
        } else {
          // No retry option, rethrow the error
          rethrow;
        }
      }
      
      // Update conversation ID when needed
      final String conversationId = response['conversationId'];
      if (_currentConversationId == null || _currentConversationId!.isEmpty) {
        _logger.i('New conversation started with ID: $conversationId');
        _currentConversationId = conversationId;
      } else {
        _logger.i('Continued conversation with ID: $conversationId');
      }
      
      setState(() {
        _messages[0] = ConversationMessage(
          query: message,
          answer: response['message'],
          createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          files: [],
        );
        _isSending = false;
      });
    } catch (e) {
      _logger.e('Error sending message: $e');
      
      String errorMessage = e.toString();
      
      // Check if the error might be related to conversation ID issues
      if (errorMessage.contains('500') || 
          errorMessage.contains('conversation') || 
          errorMessage.contains('context')) {
        // Reset conversation ID to force starting a new conversation next time
        _currentConversationId = null;
        errorMessage = 'Error with conversation. Starting a new chat on next message.';
        _logger.i('Reset conversation ID due to error');
      }
      
      setState(() {
        if (_messages.isNotEmpty) {
          _messages[0] = ConversationMessage(
            query: message,
            answer: 'Error: $errorMessage',
            createdAt: _messages[0].createdAt,
            files: [],
          );
        }
        _isSending = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: _currentConversationId != null ? SnackBarAction(
              label: 'New Chat',
              onPressed: () {
                setState(() {
                  _currentConversationId = null;
                  _messages = [];
                });
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ) : null,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat'),
        actions: [
          DropdownButton<String>(
            value: _selectedAssistantId,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedAssistantId = value;
                });
              }
            },
            items: const [
              DropdownMenuItem(
                value: 'gpt-4o-mini',
                child: Text('GPT-4o mini'),
              ),
              DropdownMenuItem(
                value: 'gemini-1.5-flash-latest',
                child: Text('Gemini 1.5 Flash'),
              ),
              DropdownMenuItem(
                value: 'gpt-4o',
                child: Text('GPT-4o'),
              ),
            ],
          ),
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
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty && _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32.0),
                              child: Text(
                                _errorMessage,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchConversationHistory,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _messages.isEmpty
                        ? const Center(child: Text('Send a message to start chatting!'))
                        : ListView.builder(
                            reverse: true,
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              return Column(
                                children: [
                                  ListTile(
                                    title: Text(message.query),
                                    subtitle: Text(
                                      DateTime.fromMillisecondsSinceEpoch(message.createdAt * 1000)
                                          .toString(),
                                    ),
                                    leading: const CircleAvatar(child: Icon(Icons.person)),
                                  ),
                                  ListTile(
                                    title: Text(message.answer),
                                    leading: const CircleAvatar(child: Icon(Icons.smart_toy)),
                                  ),
                                  const Divider(),
                                ],
                              );
                            },
                          ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isSending 
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  onPressed: _isSending ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}