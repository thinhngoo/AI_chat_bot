import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/api_constants.dart';

/// Helper class for generating and managing webhook URLs for various platforms
class WebhookUrlHelper {
  /// Generates a webhook URL for the given platform and botId
  static String generateWebhookUrl(String platform, String botId) {
    return '${ApiConstants.kbCoreApiUrl}/kb-core/v1/hook/$platform/$botId';
  }
  
  /// Generates a Messenger callback URL for the given botId
  static String generateMessengerCallbackUrl(String botId) {
    return generateWebhookUrl('messenger', botId);
  }
  
  /// Generates a Slack callback URL for the given botId
  static String generateSlackCallbackUrl(String botId) {
    return generateWebhookUrl('slack', botId);
  }
  
  /// Generates a Telegram webhook URL for the given botId
  static String generateTelegramWebhookUrl(String botId) {
    return generateWebhookUrl('telegram', botId);
  }
  
  /// Creates a widget to display webhook URL with a copy button
  static Widget buildWebhookUrlDisplay({
    required BuildContext context,
    required String webhookUrl,
    required String label,
    Color backgroundColor = const Color(0xFFE3F2FD),
    Color borderColor = const Color(0xFFBBDEFB),
    Color textColor = const Color(0xFF1565C0),
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.content_copy, size: 18),
                tooltip: 'Copy to clipboard',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: webhookUrl));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$label copied to clipboard'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            webhookUrl,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
