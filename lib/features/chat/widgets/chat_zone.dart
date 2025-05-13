import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../widgets/typing_indicator.dart';
import '../../../widgets/information.dart';
import '../models/conversation_message.dart';

// Generic message interface 
class ChatMessage {
  final String query;         // User's message or empty string for bot-only messages
  final String answer;        // Bot's response 
  final bool isTyping;        // Whether this message is currently being typed
  final DateTime timestamp;   // When the message was sent
  
  ChatMessage({
    required this.query,
    required this.answer,
    this.isTyping = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  // Convert ConversationMessage to ChatMessage
  static ChatMessage fromConversationMessage(ConversationMessage message) {
    return ChatMessage(
      query: message.query,
      answer: message.answer,
      timestamp: DateTime.fromMillisecondsSinceEpoch(message.createdAt * 1000),
    );
  }
}

class ChatZone extends StatelessWidget {
  final List<dynamic> messages;
  final ScrollController scrollController;
  final bool isTyping;
  final bool convertMessages;  // Whether to convert ConversationMessage to ChatMessage

  const ChatZone({
    super.key,
    required this.messages,
    required this.isTyping,
    required this.scrollController,
    this.convertMessages = true,
  });

  // Create a reusable method for consistent markdown styling
  static MarkdownBody buildMarkdownBody(BuildContext context, String data) {
    return MarkdownBody(
      data: data,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: Theme.of(context).textTheme.bodyMedium?.copyWith(
          height: 1.5,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        h1: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        h2: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        h3: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        listBullet: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).hintColor,
          height: 1.5,
        ),
        blockquote: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(204),
          fontStyle: FontStyle.italic,
          height: 1.5,
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: Theme.of(context).colorScheme.primary.withAlpha(128),
              width: 4.0,
            ),
          ),
        ),
        blockquotePadding: const EdgeInsets.only(left: 16.0),
        code: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontFamily: 'monospace',
          color: Theme.of(context).colorScheme.onSurface,
          backgroundColor: Theme.of(context).colorScheme.surfaceDim,
        ),
        codeblockDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceDim,
          borderRadius: BorderRadius.circular(4.0),
        ),
        codeblockPadding: const EdgeInsets.all(8.0),
        tableHead: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        tableBody: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        tableBorder: TableBorder.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(128),
          width: 1.0,
        ),
        tableCellsPadding: const EdgeInsets.symmetric(
          horizontal: 8.0,
          vertical: 4.0,
        ),
        a: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          decoration: TextDecoration.underline,
          decorationColor: Theme.of(context).colorScheme.primary,
        ),
        listIndent: 24.0,
        orderedListAlign: WrapAlignment.start,
        unorderedListAlign: WrapAlignment.start,
      ),
      onTapLink: (text, href, title) {
        if (href != null) {
          launchUrl(Uri.parse(href), 
            mode: LaunchMode.externalApplication);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      reverse: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        // Convert the message if needed
        ChatMessage message;
        if (convertMessages && messages[index] is ConversationMessage) {
          message = ChatMessage.fromConversationMessage(messages[index]);
        } else {
          message = messages[index];
        }
        
        final isUserMessage = message.query.isNotEmpty;
        final shouldShowTyping = isTyping && index == messages.length - 1;

        // Display both query and answer for each message
        if (isUserMessage) {
          return Padding(
            // Add padding to the bottom of the message
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User question bubble
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(4),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(13),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: buildMarkdownBody(context, message.query),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // AI answer - simplified, no bubble UI
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Only hide the answer if this is the last message and we're currently typing
                      if (!(shouldShowTyping && message.answer.isEmpty)) ...[
                        buildMarkdownBody(context, message.answer),
                        if (message.answer.isNotEmpty)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              icon: Icon(
                                Icons.copy,
                                size: 18,
                                color: Theme.of(context).hintColor,
                              ),
                              tooltip: 'Copy to clipboard',
                              padding: const EdgeInsets.only(left: 0),
                              visualDensity: const VisualDensity(
                                  horizontal: -4.0, vertical: 0),
                              onPressed: () {
                                // Copy message to clipboard
                                Clipboard.setData(
                                    ClipboardData(text: message.answer));

                                // Show a snackbar confirmation
                                GlobalSnackBar.show(
                                  context: context,
                                  message: 'Response copied to clipboard',
                                  variant: SnackBarVariant.success,
                                  duration: const Duration(seconds: 2),
                                );
                              },
                            ),
                          ),
                      ],
                      // Show typing indicator for the last message when typing
                      if (shouldShowTyping)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0, left: 4.0),
                          child: TypingIndicator(isTyping: true),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20.0, right: 16),
            child: buildMarkdownBody(context, message.answer),
          );
        }
      },
    );
  }
}
