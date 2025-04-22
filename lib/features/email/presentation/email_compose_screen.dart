import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import '../models/email_model.dart';
import '../services/email_service.dart';
import '../../../widgets/common/typing_indicator.dart';
import 'package:share_plus/share_plus.dart';

class EmailComposeScreen extends StatefulWidget {
  final String originalEmail;
  final EmailActionType actionType;
  final bool isDarkMode;
  
  const EmailComposeScreen({
    super.key,
    required this.originalEmail,
    required this.actionType,
    required this.isDarkMode,
  });

  @override
  State<EmailComposeScreen> createState() => _EmailComposeScreenState();
}

class _EmailComposeScreenState extends State<EmailComposeScreen> {
  final Logger _logger = Logger();
  final EmailService _emailService = EmailService();
  
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _ccController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  
  final FocusNode _subjectFocusNode = FocusNode();
  final FocusNode _bodyFocusNode = FocusNode();
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isImproving = false;
  String _errorMessage = '';
  EmailDraft _emailDraft = EmailDraft();
  bool _showCcBcc = false;
  bool _hasUnsavedChanges = false;
  
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
    final textToShare = 'Subject: ${_emailDraft.subject}\n\n${_emailDraft.body}';
    
    await Share.share(
      textToShare,
      subject: _emailDraft.subject,
    );
  }
  
  Future<bool> _onWillPop() async {
    // Update the draft from controllers before checking if changed
    _updateDraftFromControllers();
    
    // Check if there are unsaved changes
    if (_emailDraft.hasContent) {
      // Show confirmation dialog
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Save draft?'),
          content: const Text('Do you want to save this email draft before leaving?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Discard
              child: const Text('Discard'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Save
              child: const Text('Save'),
            ),
          ],
        ),
      );
      
      // If user wants to save, return true (which will lead back to the parent with a "true" result)
      if (result == true) {
        Navigator.of(context).pop(true);
        return false;
      }
    }
    
    return true;
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = widget.isDarkMode;
    
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
              'You have unsaved changes that will be lost if you leave this screen.'
            ),
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
        ) ?? false;
        
        // If user confirmed, allow the pop
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.actionType.label} Email'),
          actions: [
            IconButton(
              icon: const Icon(Icons.content_copy),
              onPressed: _isLoading ? null : _copyToClipboard,
              tooltip: 'Copy to clipboard',
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _isLoading ? null : _shareEmail,
              tooltip: 'Share',
            ),
          ],
        ),
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    TypingIndicator(isTyping: true),
                    const SizedBox(height: 8),
                    Text(
                      'Composing ${widget.actionType.label.toLowerCase()} email...',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              )
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error generating email',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red[400]),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _generateResponse,
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
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
                              TextFormField(
                                controller: _toController,
                                decoration: const InputDecoration(
                                  labelText: 'To',
                                  hintText: 'Email recipients',
                                  prefixIcon: Icon(Icons.person),
                                ),
                                keyboardType: TextInputType.emailAddress,
                              ),
                              
                              // Show/hide CC and BCC
                              if (!_showCcBcc)
                                TextButton(
                                  onPressed: () => setState(() => _showCcBcc = true),
                                  style: TextButton.styleFrom(
                                    alignment: Alignment.centerLeft,
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: const Text('Show Cc/Bcc'),
                                ),
                              
                              // CC fields (shown conditionally)
                              if (_showCcBcc) ...[
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _ccController,
                                  decoration: const InputDecoration(
                                    labelText: 'Cc',
                                    hintText: 'Carbon copy recipients',
                                    prefixIcon: Icon(Icons.people),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                
                                TextButton(
                                  onPressed: () => setState(() => _showCcBcc = false),
                                  style: TextButton.styleFrom(
                                    alignment: Alignment.centerLeft,
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: const Text('Hide Cc/Bcc'),
                                ),
                              ],
                              
                              const SizedBox(height: 16),
                              
                              // Subject field
                              TextFormField(
                                controller: _subjectController,
                                focusNode: _subjectFocusNode,
                                decoration: const InputDecoration(
                                  labelText: 'Subject',
                                  hintText: 'Email subject',
                                  prefixIcon: Icon(Icons.subject),
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Email body
                              TextFormField(
                                controller: _bodyController,
                                focusNode: _bodyFocusNode,
                                maxLines: 12,
                                decoration: const InputDecoration(
                                  labelText: 'Message',
                                  alignLabelWithHint: true,
                                  hintText: 'Compose your email...',
                                ),
                                textCapitalization: TextCapitalization.sentences,
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // AI suggestions to improve the email
                              Text(
                                'Improve this email:',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              
                              // Horizontal scrolling list of improvement options
                              SizedBox(
                                height: 100,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    _buildImprovementCard(EmailActionType.formal, isDarkMode),
                                    _buildImprovementCard(EmailActionType.informal, isDarkMode),
                                    _buildImprovementCard(EmailActionType.shorter, isDarkMode),
                                    _buildImprovementCard(EmailActionType.detailed, isDarkMode),
                                    _buildImprovementCard(EmailActionType.urgent, isDarkMode),
                                  ],
                                ),
                              ),
                              
                              // Show original email
                              const SizedBox(height: 24),
                              ExpansionTile(
                                title: const Text('Original Email'),
                                initiallyExpanded: false,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? Colors.grey[800]
                                          : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(widget.originalEmail),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Improvement loading indicator
                      if (_isImproving)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          color: theme.colorScheme.surface,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 20, 
                                  height: 20, 
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                const SizedBox(width: 12),
                                Text('Improving email...', style: theme.textTheme.bodyMedium),
                              ],
                            ),
                          ),
                        ),
                      
                      // Bottom action bar
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.onSurface.withAlpha(204),
                              blurRadius: 3,
                              offset: const Offset(0, -1),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isLoading || _isSaving 
                                    ? null 
                                    : () {
                                        // Return true to indicate the email was saved
                                        Navigator.pop(context, true);
                                      },
                                icon: const Icon(Icons.save),
                                label: const Text('Save Draft'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isLoading || _isSaving
                                    ? null
                                    : _shareEmail,
                                icon: const Icon(Icons.send),
                                label: const Text('Send Email'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                ),
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
  
  Widget _buildImprovementCard(EmailActionType actionType, bool isDarkMode) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(right: 12.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: _isImproving ? null : () => _improveEmail(),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 100,
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                actionType.icon,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                actionType.label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
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