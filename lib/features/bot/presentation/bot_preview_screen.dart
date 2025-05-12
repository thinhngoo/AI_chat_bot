import 'package:ai_chat_bot/widgets/button.dart';
import 'package:ai_chat_bot/widgets/text_field.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../services/bot_service.dart';
import '../../../widgets/information.dart'
    show GlobalSnackBar, SnackBarVariant, DrawerTopIndicator;
import '../../../widgets/dialog.dart';
import '../../../features/chat/widgets/chat_zone.dart' as chat;
import '../../../core/constants/app_colors.dart';

class BotPreviewScreen extends StatefulWidget {
  final String botId;
  final String botName;

  const BotPreviewScreen({
    super.key,
    required this.botId,
    required this.botName,
  });

  @override
  State<BotPreviewScreen> createState() => _BotPreviewScreenState();
}

class _BotPreviewScreenState extends State<BotPreviewScreen>
    with TickerProviderStateMixin {
  final Logger _logger = Logger();
  final BotService _botService = BotService();

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<chat.ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isTyping = false;

  // Animation controllers
  late AnimationController _sendButtonController;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();

    _sendButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _sendButtonController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(
        chat.ChatMessage(
          query: '',
          answer: 'Hello! I am ${widget.botName}. You can ask me anything.',
        ),
      );
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Start loading animation
    _sendButtonController.forward();

    setState(() {
      _isLoading = true;
      _isTyping = true;

      // Add the user message at the end of the list
      _messages.add(
        chat.ChatMessage(
          query: message,
          answer: '',
        ),
      );

      _messageController.clear();
    });

    // Scroll to bottom after adding user message
    _scrollToBottom();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));

      // Call bot service
      final response = await _botService.askBot(
        botId: widget.botId,
        message: message,
      );

      if (!mounted) return;

      // Update message delivery status
      setState(() {
        final lastUserMessageIndex =
            _messages.lastIndexWhere((msg) => msg.query.isNotEmpty);
        if (lastUserMessageIndex != -1) {
          _messages[lastUserMessageIndex] = chat.ChatMessage(
            query: _messages[lastUserMessageIndex].query,
            answer: response,
          );
        }
      });

      setState(() {
        _isLoading = false;
        _isTyping = false;
        _sendButtonController.reverse();
      });

      // Scroll to bottom after adding bot response
      _scrollToBottom();
    } catch (e) {
      _logger.e('Error sending message: $e');

      if (!mounted) return;

      setState(() {
        final lastUserMessageIndex =
            _messages.lastIndexWhere((msg) => msg.query.isNotEmpty);
        if (lastUserMessageIndex != -1) {
          _messages[lastUserMessageIndex] = chat.ChatMessage(
            query: _messages[lastUserMessageIndex].query,
            answer: 'Sorry, an error occurred: ${e.toString()}',
          );
        }

        _isLoading = false;
        _isTyping = false;
        _sendButtonController.reverse();
      });

      // Scroll to bottom after adding error message
      _scrollToBottom();
    }
  }

  // Show attachment options
  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
            height: MediaQuery.of(context).size.height * 0.4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                // Drawer indicator
                const DrawerTopIndicator(),

                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 6.0, horizontal: 10.0),
                  child: Row(
                    children: [
                      // Left side - placeholder for balance
                      const SizedBox(width: 48),

                      // Centered title
                      Expanded(
                        child: Center(
                          child: Text(
                            'Send an attachment',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ),

                      // Right side - close button
                      IconButton(
                        icon: const Icon(Icons.close, size: 24),
                        color: Theme.of(context).hintColor,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      _buildAttachmentOption(context, Icons.insert_drive_file,
                          'Document', 'PDF, Word, Excel...', () {
                        Navigator.pop(context);
                        _showFeatureNotImplemented(
                            'The feature of uploading documents is under development');
                      }),
                      _buildAttachmentOption(
                          context, Icons.image, 'Image', 'Upload an image file',
                          () {
                        Navigator.pop(context);
                        _showFeatureNotImplemented(
                            'The feature of uploading images is under development');
                      }),
                      _buildAttachmentOption(
                          context, Icons.link, 'Link', 'Send a website link',
                          () {
                        Navigator.pop(context);
                        _showFeatureNotImplemented(
                            'The feature of uploading images is under development');
                      }),
                    ]),
                  ),
                ),
              ],
            ));
      },
    );
  }

  ListTile _buildAttachmentOption(BuildContext context, IconData icon,
      String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.onSurface),
      ),
      title: Text(title),
      subtitle: Text(subtitle,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Theme.of(context).hintColor)),
      onTap: onTap,
    );
  }

  // ignore: unused_element
  void _showUrlInputDialog() {
    GlobalInputDialog.show(
      context: context,
      title: 'Enter URL',
      message: 'Provide a website URL to analyze',
      hintText: 'https://example.com',
      labelText: 'Website URL',
      prefixIcon: Icons.link,
      keyboardType: TextInputType.url,
      confirmLabel: 'Submit',
      cancelLabel: 'Cancel',
      variant: DialogVariant.info,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a URL';
        }

        // Basic URL validation
        if (!value.startsWith('http://') && !value.startsWith('https://')) {
          return 'URL must start with http:// or https://';
        }

        return null;
      },
    ).then((url) {
      if (url != null && url.isNotEmpty) {
        setState(() {
          _messages.add(
            chat.ChatMessage(
              query: url,
              answer: '',
            ),
          );
        });

        // Simulate bot response
        _simulateBotResponseWithDelay(
            'Thank you for sharing the link. I am analyzing the content.');
      }
    });
  }

  // Simulate bot response with delay
  Future<void> _simulateBotResponseWithDelay(String message) async {
    setState(() {
      _isTyping = true;
    });

    // Scroll to bottom to show typing indicator
    _scrollToBottom();

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      // Update the last user message with a response
      final lastUserMessageIndex =
          _messages.lastIndexWhere((msg) => msg.query.isNotEmpty);
      if (lastUserMessageIndex != -1) {
        _messages[lastUserMessageIndex] = chat.ChatMessage(
          query: _messages[lastUserMessageIndex].query,
          answer: message,
        );
      }

      _isTyping = false;
    });

    // Scroll to bottom again after adding bot response
    _scrollToBottom();
  }

  // Show feature not implemented dialog
  void _showFeatureNotImplemented(String message) {
    GlobalSnackBar.show(
      context: context,
      message: message,
      variant: SnackBarVariant.info,
      duration: const Duration(seconds: 3),
    );
  }

  // Clear chat history
  void _clearChat() {
    GlobalDialog.show(
      context: context,
      title: 'Delete conversation',
      message:
          'Are you sure you want to delete all messages? This action cannot be undone.',
      variant: DialogVariant.warning,
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      onConfirm: () {
        setState(() {
          _messages.clear();
          _addWelcomeMessage();
        });
      },
    );
  }

  // Rate conversation
  void _rateConversation() {
    int selectedRating = 0;
    final feedbackController = TextEditingController();
    final isDarkMode =
        Theme.of(context).colorScheme.brightness == Brightness.dark;
    final colors = isDarkMode ? AppColors.dark : AppColors.light;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return Dialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(30),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Rate Conversation',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'How was your experience with the bot?',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Theme.of(context).hintColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Star rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      return IconButton(
                        icon: Icon(
                          selectedRating >= starIndex
                              ? Icons.star
                              : Icons.star_border,
                          color: selectedRating >= starIndex
                              ? colors.yellow
                              : colors.muted,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() {
                            selectedRating = starIndex;
                          });
                        },
                      );
                    }),
                  ),

                  const SizedBox(height: 20),

                  // Feedback text field
                  FloatingLabelTextField(
                    controller: feedbackController,
                    label: 'Additional Comments (optional)',
                    hintText: 'Tell us more about your experience...',
                    maxLines: 3,
                    darkMode: isDarkMode,
                  ),

                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Button(
                          onPressed: () => Navigator.pop(context),
                          variant: ButtonVariant.ghost,
                          color: colors.cardForeground.withAlpha(180),
                          label: 'Cancel',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Button(
                          onPressed: () {
                            if (selectedRating > 0) {
                              // Submit rating and feedback
                              GlobalSnackBar.show(
                                context: context,
                                message:
                                    'Thanks for your $selectedRating-star rating!',
                                variant: SnackBarVariant.success,
                              );
                              Navigator.pop(context);
                            } else {
                              GlobalSnackBar.show(
                                context: context,
                                message: 'Please select a rating',
                                variant: SnackBarVariant.warning,
                              );
                            }
                          },
                          label: 'Submit',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
      },
    ).then((_) => feedbackController.dispose());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.botName,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Preview Mode',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.thumb_up,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(180)),
            tooltip: 'Rate Conversation',
            onPressed: _rateConversation,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Icon(Icons.delete_outline,
                  color:
                      Theme.of(context).colorScheme.onSurface.withAlpha(180)),
              tooltip: 'Clear Chat',
              onPressed: _clearChat,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat header info
          Container(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Icon(
                  Icons.info,
                  size: 18,
                  color: Theme.of(context).hintColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This is a preview mode of the bot. Messages are not stored and this is only an environment for testing.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ),
              ],
            ),
          ),

          // Chat messages
          Expanded(
            child: chat.ChatZone(
              messages: _messages,
              isTyping: _isTyping,
              scrollController: _scrollController,
              convertMessages: false, // We're already using ChatMessage objects
            ),
          ),

          // Message input area
          Container(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
            margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceDim,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 5,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              child: Column(
                children: [
                  // Message text field
                  TextField(
                    controller: _messageController,
                    focusNode: _focusNode,
                    maxLines: 5,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                    cursorColor: Theme.of(context).colorScheme.onSurface,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      fillColor: Theme.of(context).colorScheme.surfaceDim,
                      filled: true,
                      hintText: 'Enter a message...',
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 8),
                      isDense: true,
                      hintStyle: TextStyle(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    onChanged: (text) {
                      setState(() {
                        // This forces the send button to update
                      });
                    },
                  ),

                  // Buttons row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Attachment button
                      IconButton(
                        icon: Icon(
                          Icons.attach_file,
                          color: Theme.of(context).hintColor,
                        ),
                        onPressed: _showAttachmentOptions,
                        tooltip: 'Add attachment',
                      ),

                      // Send button
                      AnimatedBuilder(
                        animation: _sendButtonController,
                        builder: (context, child) {
                          final bool showLoading =
                              _sendButtonController.status ==
                                      AnimationStatus.forward ||
                                  _sendButtonController.status ==
                                      AnimationStatus.completed;
                          final bool isDisabled =
                              _messageController.text.trim().isEmpty ||
                                  _isLoading;

                          return Material(
                            color: isDisabled
                                ? Theme.of(context).hintColor.withAlpha(30)
                                : Theme.of(context).colorScheme.onSurface,
                            borderRadius: BorderRadius.circular(24),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: isDisabled ? null : _sendMessage,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: showLoading
                                    ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Theme.of(context).hintColor,
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        Icons.arrow_upward,
                                        color: isDisabled
                                            ? Theme.of(context)
                                                .hintColor
                                                .withAlpha(128)
                                            : Theme.of(context)
                                                .colorScheme
                                                .surfaceDim,
                                        size: 24,
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
