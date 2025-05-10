import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/email_model.dart';
import '../services/email_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/text_field.dart';
import '../../../widgets/button.dart';
import '../../../widgets/information.dart';
class EmailComposeScreen extends StatefulWidget {
  final String originalEmail;
  final EmailActionType actionType;

  const EmailComposeScreen({
    super.key,
    required this.originalEmail,
    required this.actionType,
  });

  @override
  State<EmailComposeScreen> createState() => _EmailComposeScreenState();
}

class _EmailComposeScreenState extends State<EmailComposeScreen> {
  // Using EmailService but removed unused logger
  final EmailService _emailService = EmailService();

  final TextEditingController _toController = TextEditingController();
  final TextEditingController _ccController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  final FocusNode _subjectFocusNode = FocusNode();
  final FocusNode _bodyFocusNode = FocusNode();

  bool _isLoading = true;
  bool _showCcBcc = false;
  final bool _isSaving = false;
  final bool _isImproving = false;
  final bool _hasUnsavedChanges = false;
  String _errorMessage = '';
  EmailDraft _emailDraft = EmailDraft();

  @override
  void initState() {
    super.initState();
    _generateResponse();
  }

  @override
  void dispose() {
    _toController.dispose();
    _ccController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    _subjectFocusNode.dispose();
    _bodyFocusNode.dispose();
    super.dispose();
  }

  Future<void> _generateResponse() async {
    if (widget.originalEmail.isEmpty) {
      setState(() {
        _errorMessage = 'Original email is empty';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final draft = await _emailService.composeEmail(
        widget.originalEmail,
        widget.actionType,
      );

      if (!mounted) return;

      setState(() {
        _emailDraft = draft;
        _subjectController.text = draft.subject;
        _bodyController.text = draft.body;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _improveEmail() async {
    if (_bodyController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Email body is empty';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final currentDraft = EmailDraft(
        to: _toController.text,
        cc: _ccController.text,
        subject: _subjectController.text,
        body: _bodyController.text,
      );

      final improvedDraft = await _emailService.improveEmailDraft(
        currentDraft,
        widget.actionType,
      );

      if (!mounted) return;

      setState(() {
        _emailDraft = improvedDraft;
        _bodyController.text = improvedDraft.body;
        _isLoading = false;
      });

      _showSnackBar('Email improved successfully!');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _copyToClipboard() async {
    // Update the current draft with controller values
    _updateDraftFromControllers();

    // Copy to clipboard
    final textToCopy = 'Subject: ${_emailDraft.subject}\n\n${_emailDraft.body}';

    await Clipboard.setData(ClipboardData(text: textToCopy));

    if (!mounted) return;

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _shareEmail() async {
    // Update the current draft with controller values
    _updateDraftFromControllers();

    // Share using the share_plus package
    final textToShare =
        'Subject: ${_emailDraft.subject}\n\n${_emailDraft.body}';

    await Share.share(
      textToShare,
      subject: _emailDraft.subject,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !_hasUnsavedChanges || _isSaving,
      onPopInvokedWithResult: (didPop, result) async {
        // If we're already popping or there's no unsaved changes, allow the pop
        if (didPop || !_hasUnsavedChanges || _isSaving) {
          return;
        }

        // Show confirmation dialog
        final shouldPop = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Discard changes?'),
                content: const Text(
                    'You have unsaved changes that will be lost if you leave this screen.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('CANCEL'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('DISCARD'),
                  ),
                ],
              ),
            ) ??
            false;

        // If user confirmed, allow the pop
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_emailDraft.subject.isNotEmpty
              ? _emailDraft.subject
              : 'Compose ${widget.actionType.label} Email'),
          centerTitle: true,
          actions: [
            // Share button
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _isLoading ? null : _shareEmail,
              tooltip: 'Share',
            ),

            // Copy button
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 8, 0),
              child: IconButton(
                icon: Icon(Icons.copy),
                tooltip: 'Copy to clipboard',
                onPressed: _copyToClipboard,
              ),
            ),
          ],
        ),
        body: _isLoading
            ? 
            InformationIndicator(
              variant: InformationVariant.loading,
              message: 'Composing ${widget.actionType.label.toLowerCase()} email...',
            )
            : _errorMessage.isNotEmpty
              ? InformationIndicator(
                variant: InformationVariant.error,
                message: _errorMessage,
                buttonText: 'Try Again',
                onButtonPressed: _generateResponse,
              )
                : Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // To field
                              FloatingLabelTextField(
                                controller: _toController,
                                label: 'To',
                                hintText: 'Email recipients',
                                prefixIcon: Icons.person,
                                keyboardType: TextInputType.emailAddress,
                                darkMode: isDarkMode,
                              ),

                              // Show/hide CC and BCC
                              if (!_showCcBcc)
                                TextButton(
                                  onPressed: () =>
                                      setState(() => _showCcBcc = true),
                                  style: TextButton.styleFrom(
                                    alignment: Alignment.centerLeft,
                                    padding: EdgeInsets.only(left: 8),
                                  ),
                                  child: Text('Show Cc/Bcc', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).hintColor)),
                                ),

                              // CC fields (shown conditionally)
                              if (_showCcBcc) ...[
                                const SizedBox(height: 16),

                                FloatingLabelTextField(
                                  controller: _ccController,
                                  label: 'Cc',
                                  hintText: 'Carbon copy recipients',
                                  prefixIcon: Icons.people,
                                  keyboardType: TextInputType.emailAddress,
                                  darkMode: isDarkMode,
                                ),

                                TextButton(
                                  onPressed: () =>
                                      setState(() => _showCcBcc = false),
                                  style: TextButton.styleFrom(
                                    alignment: Alignment.centerLeft,
                                    padding: EdgeInsets.only(left: 8),
                                  ),
                                  child: Text('Hide Cc/Bcc', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).hintColor)),
                                ),
                              ],

                              const SizedBox(height: 16),

                              // Subject field
                              FloatingLabelTextField(
                                controller: _subjectController,
                                label: 'Subject',
                                hintText: 'Email subject',
                                prefixIcon: Icons.subject,
                                darkMode: isDarkMode,
                                focusNode: _subjectFocusNode,
                              ),

                              const SizedBox(height: 16),

                              // Email body
                              FloatingLabelTextField(
                                controller: _bodyController,
                                label: 'Message',
                                hintText: 'Compose your email...',
                                maxLines: 12,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                darkMode: isDarkMode,
                                focusNode: _bodyFocusNode,
                              ),

                              const SizedBox(height: 24),

                              // AI suggestions to improve the email
                              Text(
                                'Improve this email:',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 8),

                              // Horizontal scrolling list of improvement options
                              SizedBox(
                                height: 85,
                                child: Row(
                                  children: [
                                    Expanded(
                                        child: _buildImprovementCard(
                                            EmailActionType.formal)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                        child: _buildImprovementCard(
                                            EmailActionType.informal)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                        child: _buildImprovementCard(
                                            EmailActionType.shorter)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                        child: _buildImprovementCard(
                                            EmailActionType.detailed)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                        child: _buildImprovementCard(
                                            EmailActionType.urgent)),
                                  ],
                                ),
                              ),

                              // Show original email
                              const SizedBox(height: 24),
                              Theme(
                                data: Theme.of(context).copyWith(
                                  dividerColor: Colors.transparent,
                                ),
                                child: ExpansionTile(
                                  title: Text(
                                    'Original Email',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  collapsedIconColor: Theme.of(context).colorScheme.primary,
                                  iconColor: Theme.of(context).colorScheme.primary,
                                  initiallyExpanded: false,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surface,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        widget.originalEmail,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Improvement loading indicator
                      if (_isImproving)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text('Improving email...',
                                    style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                        ),

                      // Bottom action bar
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          border: Border(
                            top: BorderSide(
                              color: Theme.of(context).colorScheme.onSurface.withAlpha(20),
                              width: 1,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDarkMode ? Colors.transparent : Theme.of(context).colorScheme.onSurface.withAlpha(30),
                              blurRadius: 3,
                              offset: const Offset(0, -1),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Button(
                                label: 'Save Draft',
                                icon: Icons.save,
                                onPressed: _isLoading || _isSaving
                                    ? null
                                    : () {
                                        // Return true to indicate the email was saved
                                        Navigator.pop(context, true);
                                      },
                                variant: ButtonVariant.normal,
                                isDarkMode: isDarkMode,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Button(
                                label: 'Send Email',
                                icon: Icons.send,
                                onPressed: _isLoading || _isSaving
                                    ? null
                                    : _shareEmail,
                                variant: ButtonVariant.primary,
                                isDarkMode: isDarkMode,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildImprovementCard(EmailActionType actionType) {
    final theme = Theme.of(context);
    final AppColors colors = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;

    return InkWell(
      onTap: _isLoading || _isImproving ? null : () => _improveEmail(),
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isImproving ? colors.primary : colors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colors.primary.withAlpha(100),
              width: 1.0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                actionType.icon,
                color: _isImproving ? colors.primaryForeground : colors.primary,
                size: 24,
              ),

              const SizedBox(height: 4),
              
              Text(
                actionType.label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateDraftFromControllers() {
    _emailDraft = _emailDraft.copyWith(
      to: _toController.text,
      cc: _ccController.text,
      subject: _subjectController.text,
      body: _bodyController.text,
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
