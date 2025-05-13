import 'package:flutter/material.dart';

class SelectKnowledgeSourceDialog extends StatelessWidget {
  const SelectKnowledgeSourceDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    SizedBox(width: 40),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Select Source',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    CloseButton(),
                  ],
                )),
            // const SizedBox(height: 16),

            // List of source options
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSourceOption(
                      context: context,
                      icon: Icons.insert_drive_file,
                      iconColor: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(120),
                      title: 'Local files',
                      description: 'Upload pdf, docx, ...',
                      value: 'file',
                    ),
                    _buildSourceOption(
                      context: context,
                      imagePath: 'assets/images/slack_logo.png',
                      title: 'Slack',
                      description: 'Connect to Slack workspace',
                      value: 'slack',
                    ),
                    _buildSourceOption(
                      context: context,
                      imagePath: 'assets/images/confluence_logo.png',
                      title: 'Confluence',
                      description: 'Connect to Confluence',
                      value: 'confluence',
                    ),
                    _buildSourceOption(
                      context: context,
                      imagePath: 'assets/images/notion_logo.png',
                      title: 'Notion',
                      description: 'Connect to Notion workspace',
                      value: 'notion',
                    ),
                    _buildSourceOption(
                      context: context,
                      icon: Icons.discord,
                      iconColor: const Color(0xFF5865F2),
                      title: 'Discord',
                      description: 'Connect to Discord server',
                      value: 'discord',
                    ),
                    _buildSourceOption(
                      context: context,
                      icon: Icons.language,
                      iconColor: Colors.blue,
                      title: 'Website',
                      description: 'Connect Website to get data',
                      value: 'website',
                      isDeveloped: false,
                    ),
                    _buildSourceOption(
                      context: context,
                      imagePath: 'assets/images/google_logo.png',
                      title: 'Google Drive',
                      description: 'Connect to Google Drive',
                      value: 'google_drive',
                      isDeveloped: false,
                    ),
                    _buildSourceOption(
                      context: context,
                      icon: Icons.code,
                      iconColor: const Color(0xFF171515),
                      title: 'GitHub Repository',
                      description: 'Connect to GitHub Repository',
                      value: 'github',
                      isDeveloped: false,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required BuildContext context,
    IconData? icon,
    Color? iconColor,
    String? imagePath,
    required String title,
    required String description,
    required String value,
    bool isDeveloped = true,
  }) {
    assert((icon != null && iconColor != null) || imagePath != null,
        'Either provide icon and iconColor, or imagePath');

    return InkWell(
      onTap: () => Navigator.of(context).pop(value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(50)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: imagePath == null
                      ? iconColor!.withAlpha((0.2 * 255).round())
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                width: 40,
                height: 40,
                child: imagePath == null
                    ? Icon(icon, color: iconColor, size: 24)
                    : Image.asset(
                        imagePath,
                        fit: BoxFit.contain,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isDeveloped) ...[
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withAlpha(24),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            child: Text(
                              'Coming soon',
                              style: TextStyle(
                                fontSize: 8,
                                fontFamily: 'monospace',
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).hintColor,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
