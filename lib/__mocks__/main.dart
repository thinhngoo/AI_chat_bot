import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget test(BuildContext context) {
    return MaterialApp(
      title: 'AI Chat Bot Mock',
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: MockChatScreen(toggleTheme: _toggleTheme),
    );
  }
}

class MockChatScreen extends StatefulWidget {
  final Function toggleTheme;

  const MockChatScreen({
    super.key,
    required this.toggleTheme,
  });

  @override
  State<MockChatScreen> createState() => _MockChatScreenState();
}

class _MockChatScreenState extends State<MockChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  bool _isTyping = false;

  // Menu state
  bool _isDialOpen = false;
  bool _showLabels = true;

  late AnimationController _sendButtonController;
  String _selectedAssistantId = 'grok-3';

  // Mock messages
  List<MockMessage> _messages = [
    MockMessage(
      query: "What is Flutter?",
      answer:
          "Flutter is Google's UI toolkit for building beautiful, natively compiled applications for mobile, web, and desktop from a single codebase. It uses the Dart programming language and allows for fast development with hot reload functionality.",
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      isUserMessage: true,
    ),
    MockMessage(
      query: "",
      answer:
          "Is there anything specific about Flutter you'd like to know more about?",
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      isUserMessage: false,
    ),
    MockMessage(
      query: "How does Flutter compare to React Native?",
      answer:
          "Flutter and React Native are both popular frameworks for cross-platform mobile development, but they have some key differences:\n\n1. **Performance**: Flutter often has better performance because it compiles to native code and doesn't require a JavaScript bridge.\n\n2. **UI Components**: Flutter has its own widget library that provides consistent UI across platforms, while React Native uses native components.\n\n3. **Language**: Flutter uses Dart, while React Native uses JavaScript/TypeScript.\n\n4. **Developer Experience**: Flutter offers hot reload (like React Native) but also has extensive documentation and strong IDE support.\n\n5. **Maturity**: React Native has been around longer and has a larger community, though Flutter is growing rapidly.\n\nThe choice between them often depends on team expertise, project requirements, and performance needs.",
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      isUserMessage: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _sendButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _sendButtonController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _isSending = true;
      _isTyping = true;
      _sendButtonController.forward();
    });

    _messageController.clear();

    final userMessage = MockMessage(
      query: message,
      answer: "",
      createdAt: DateTime.now(),
      isUserMessage: true,
    );

    setState(() {
      _messages = [userMessage, ..._messages];
    });

    // Auto-scroll to top when a new message is added
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Simulate AI thinking
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isTyping = false;
      });

      // Simulate AI response after thinking
      Future.delayed(const Duration(seconds: 1), () {
        final aiMessage = MockMessage(
          query: "",
          answer: _getAIResponse(message),
          createdAt: DateTime.now(),
          isUserMessage: false,
        );

        setState(() {
          _messages = [aiMessage, ..._messages];
          _isSending = false;
          _sendButtonController.reverse();
        });
      });
    });
  }

  String _getAIResponse(String message) {
    // Some mock responses based on user input
    if (message.toLowerCase().contains('hello') ||
        message.toLowerCase().contains('hi')) {
      return "Hello! How can I help you today?";
    } else if (message.toLowerCase().contains('flutter')) {
      return "Flutter is an amazing framework for building cross-platform applications with a single codebase. Is there something specific about Flutter you'd like to know?";
    } else if (message.toLowerCase().contains('dart')) {
      return "Dart is the programming language used by Flutter. It's developed by Google and offers features like strong typing, garbage collection, and a rich standard library.";
    } else if (message.toLowerCase().contains('who are you')) {
      return "I'm a mock AI assistant for demonstration purposes. In the real app, this would be powered by GPT-4o, Gemini, or another AI model.";
    } else {
      return "Thanks for your message! This is a mock response for demonstration purposes. In the real app, you would receive an intelligent response from an AI model.";
    }
  }

  Widget _buildSpeedDial() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final buttonColor = theme.colorScheme.primary;
    final buttonTextColor = theme.colorScheme.onPrimary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isDialOpen) ...[
          _buildDialOption(Icons.logout, 'Logout', -1, Colors.redAccent),
          const SizedBox(height: 16),
          _buildDialOption(Icons.email, 'Email', 4, buttonColor),
          const SizedBox(height: 16),
          _buildDialOption(Icons.format_quote, 'Prompts', 3, buttonColor),
          const SizedBox(height: 16),
          _buildDialOption(Icons.android, 'Bots', 2, buttonColor),
          const SizedBox(height: 16),
          _buildDialOption(Icons.person, 'Account', 1, buttonColor),
          const SizedBox(height: 16),
          _buildDialOption(Icons.chat_bubble, 'Chat', 0, buttonColor),
          const SizedBox(height: 20),
        ],
        FloatingActionButton(
          onPressed: () {
            setState(() {
              _isDialOpen = !_isDialOpen;
            });
          },
          backgroundColor: buttonColor,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isDarkMode
                ? BorderSide(color: theme.dividerColor, width: 1)
                : BorderSide.none,
          ),
          child: Icon(
            _isDialOpen ? Icons.close : Icons.menu,
            color: buttonTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDialOption(IconData icon, String label, int index, Color color) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return SizedBox(
      width: 200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_showLabels)
            GestureDetector(
              onTap: () {
                if (index == -1) {
                  _showLogoutDialog();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Switched to $label (mock)')),
                  );
                  setState(() {
                    _isDialOpen = false;
                  });
                }
              },
              child: Container(
                width: 100,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    color: index == -1
                        ? Colors.white
                        : theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          SizedBox(width: _showLabels ? 12 : 0),
          FloatingActionButton(
            onPressed: () {
              if (index == -1) {
                _showLogoutDialog();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Switched to $label (mock)')),
                );
                setState(() {
                  _isDialOpen = false;
                });
              }
            },
            backgroundColor: color,
            heroTag: 'fab_$index',
            mini: true,
            child: Icon(
              icon,
              color: index == -1 ? Colors.white : theme.colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    setState(() {
      _isDialOpen = false;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out (mock)')),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget test(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: AssistantSelector(
          selectedAssistantId: _selectedAssistantId,
          onSelect: (id) {
            setState(() {
              _selectedAssistantId = id;
            });
          },
        ),
        centerTitle: true,
        actions: [
          // Light/dark mode toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: IconButton(
              icon: Icon(
                isDarkMode ? Icons.light_mode : Icons.dark_mode,
              ),
              onPressed: () => widget.toggleTheme(),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Column(
              children: [
                // Chat messages
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF121212)
                          : const Color(0xFFF5F5F5),
                    ),
                    child: ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isUserMessage = message.isUserMessage;
                        final messageText =
                            isUserMessage ? message.query : message.answer;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Column(
                            crossAxisAlignment: isUserMessage
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: isUserMessage
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isUserMessage) ...[
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor:
                                          theme.colorScheme.primary,
                                      child: Text(
                                        'AI',
                                        style: TextStyle(
                                          color: theme.colorScheme.onPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isUserMessage
                                            ? theme.colorScheme.primary
                                            : isDarkMode
                                                ? const Color(0xFF2D2D2D)
                                                : Colors.white,
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(20),
                                          topRight: const Radius.circular(20),
                                          bottomLeft: isUserMessage
                                              ? const Radius.circular(20)
                                              : const Radius.circular(4),
                                          bottomRight: isUserMessage
                                              ? const Radius.circular(4)
                                              : const Radius.circular(20),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withAlpha(13),
                                            blurRadius: 5,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: SelectableText(
                                        messageText,
                                        style: TextStyle(
                                          color: isUserMessage
                                              ? theme.colorScheme.onPrimary
                                              : theme.colorScheme.onSurface,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (isUserMessage) ...[
                                    const SizedBox(width: 8),
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: isDarkMode
                                          ? Colors.grey[700]
                                          : Colors.grey[300],
                                      child: const Icon(
                                        Icons.person,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                  left: isUserMessage ? 0 : 40,
                                  right: isUserMessage ? 40 : 0,
                                  top: 4,
                                ),
                                child: Text(
                                  '${message.createdAt.hour}:${message.createdAt.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: theme.colorScheme.onSurface
                                        .withAlpha(153),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Typing indicator
                if (_isTyping)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: theme.colorScheme.primary,
                            child: Text(
                              'AI',
                              style: TextStyle(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Typing",
                            style: TextStyle(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildDot(0),
                          _buildDot(1),
                          _buildDot(2),
                        ],
                      ),
                    ),
                  ),

                // Message input area
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(13),
                        blurRadius: 5,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12.0),
                  child: SafeArea(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Voice input button
                        IconButton(
                          icon: Icon(
                            Icons.mic_none,
                            color: theme.colorScheme.primary,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Voice input coming soon')),
                            );
                          },
                        ),

                        // Message text field
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!,
                                width: 1,
                              ),
                              color: isDarkMode
                                  ? Colors.grey[850]
                                  : Colors.grey[50],
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: TextField(
                                controller: _messageController,
                                maxLines: null,
                                minLines: 1,
                                textInputAction: TextInputAction.newline,
                                keyboardType: TextInputType.multiline,
                                decoration: InputDecoration(
                                  hintText: 'Type a message...',
                                  border: InputBorder.none,
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  isDense: true,
                                  hintStyle: TextStyle(
                                    color: isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                                onSubmitted: (_) => _sendMessage(),
                                onChanged: (text) {
                                  setState(() {
                                    // This forces the send button to update
                                  });
                                },
                              ),
                            ),
                          ),
                        ),

                        // Image upload button
                        IconButton(
                          icon: Icon(
                            Icons.image_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Image upload coming soon')),
                            );
                          },
                        ),

                        // Send button
                        const SizedBox(width: 4),
                        AnimatedBuilder(
                          animation: _sendButtonController,
                          builder: (context, child) {
                            final bool showLoading =
                                _sendButtonController.status ==
                                        AnimationStatus.forward ||
                                    _sendButtonController.status ==
                                        AnimationStatus.completed;

                            return Material(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(24),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: (_messageController.text
                                            .trim()
                                            .isNotEmpty &&
                                        !_isSending)
                                    ? _sendMessage
                                    : null,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  child: showLoading
                                      ? SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              theme.colorScheme.onPrimary,
                                            ),
                                          ),
                                        )
                                      : Icon(
                                          Icons.send_rounded,
                                          color: _messageController.text
                                                  .trim()
                                                  .isEmpty
                                              ? theme.colorScheme.onPrimary
                                                  .withAlpha(128)
                                              : theme.colorScheme.onPrimary,
                                          size: 24,
                                        ),
                                ),
                              ),
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

          // Overlay when menu is open
          if (_isDialOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isDialOpen = false;
                  });
                },
                child: Container(
                  color: isDarkMode
                      ? Colors.black.withAlpha(160)
                      : Colors.black.withAlpha(60),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _buildSpeedDial(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _sendButtonController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          height: 6,
          width: 6,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

class MockMessage {
  final String query;
  final String answer;
  final DateTime createdAt;
  final bool isUserMessage;

  MockMessage({
    required this.query,
    required this.answer,
    required this.createdAt,
    required this.isUserMessage,
  });
}

class AssistantSelector extends StatefulWidget {
  final String selectedAssistantId;
  final ValueChanged<String> onSelect;

  const AssistantSelector({
    super.key,
    required this.selectedAssistantId,
    required this.onSelect,
  });

  @override
  State<AssistantSelector> createState() => _AssistantSelectorState();
}

class _AssistantSelectorState extends State<AssistantSelector> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  void _showMenu() {
    _overlayEntry = _buildOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _buildOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _hideMenu,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned(
              left: offset.dx,
              top: offset.dy + size.height + 6,
              width: 280,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0, size.height + 6),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMenuOption(
                          id: 'grok-3',
                          title: 'Grok 3',
                          subtitle: 'Smartest',
                          selected: widget.selectedAssistantId == 'grok-3',
                          onTap: () {
                            widget.onSelect('grok-3');
                            _hideMenu();
                          },
                        ),
                        _buildMenuOption(
                          id: 'grok-2',
                          title: 'Grok 2',
                          subtitle: 'Previous generation model',
                          selected: widget.selectedAssistantId == 'grok-2',
                          onTap: () {
                            widget.onSelect('grok-2');
                            _hideMenu();
                          },
                        ),
                        const Divider(height: 16, thickness: 1),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SuperGrok',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color:
                                      isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Mở khóa các tính năng nâng cao_',
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      isDark ? Colors.white54 : Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                  onPressed: () {
                                    // Show upgrade dialog or snackbar
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Nâng cấp SuperGrok (mock)')),
                                    );
                                    _hideMenu();
                                  },
                                  child: const Text('Nâng cấp',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required String id,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        color: selected
            ? theme.colorScheme.primary.withAlpha(10)
            : Colors.transparent,
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: selected ? theme.colorScheme.primary : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check, color: theme.colorScheme.primary, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget test(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: () {
          if (_overlayEntry == null) {
            _showMenu();
          } else {
            _hideMenu();
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.selectedAssistantId == 'grok-3')
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
              if (widget.selectedAssistantId == 'grok-2')
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                widget.selectedAssistantId == 'grok-3'
                    ? 'Grok 3'
                    : widget.selectedAssistantId == 'grok-2'
                        ? 'Grok 2'
                        : widget.selectedAssistantId,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.keyboard_arrow_down),
            ],
          ),
        ),
      ),
    );
  }
}
