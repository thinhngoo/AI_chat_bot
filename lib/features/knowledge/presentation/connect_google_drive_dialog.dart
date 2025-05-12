import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/knowledge_base_service.dart';
import '../../../widgets/button.dart';
import '../../../widgets/text_field.dart';

class ConnectGoogleDriveDialog extends StatefulWidget {
  final String knowledgeBaseId;

  const ConnectGoogleDriveDialog({
    super.key,
    required this.knowledgeBaseId,
  });

  @override
  State<ConnectGoogleDriveDialog> createState() => _ConnectGoogleDriveDialogState();
}

class _ConnectGoogleDriveDialogState extends State<ConnectGoogleDriveDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fileIdController = TextEditingController();
  bool _isLoading = false;
  bool _isConnecting = false;
  String? _error;
  GoogleSignInAccount? _googleUser;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/drive.readonly'],
  );

  final KnowledgeBaseService _knowledgeBaseService = KnowledgeBaseService();

  @override
  void dispose() {
    _fileIdController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isConnecting = true;
      _error = null;
    });

    try {
      final GoogleSignInAccount? user = await _googleSignIn.signIn();
      
      setState(() {
        _googleUser = user;
        _isConnecting = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to sign in with Google: $e';
        _isConnecting = false;
      });
    }
  }

  Future<void> _connectGoogleDrive() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _knowledgeBaseService.connectGoogleDrive(
        widget.knowledgeBaseId,
        _fileIdController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to connect Google Drive: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.folder_shared,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(height: 16),
                Text(
                  'Connect Google Drive',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Connect your Google Drive to import documents.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(204),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                
                if (_googleUser == null) ...[
                  const SizedBox(height: 12),
                  Button(
                    label: 'Sign in with Google',
                    icon: Icons.login,
                    onPressed: _isConnecting ? null : _signInWithGoogle,
                    variant: ButtonVariant.primary,
                    isDarkMode: isDarkMode,
                    fontWeight: FontWeight.bold,
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(30),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: _googleUser?.photoUrl != null
                              ? NetworkImage(_googleUser!.photoUrl!)
                              : null,
                          child: _googleUser?.photoUrl == null
                              ? Text(_googleUser!.displayName![0])
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _googleUser!.displayName ?? 'Google User',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _googleUser!.email,
                                style: TextStyle(
                                  color: Theme.of(context).hintColor,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Button(
                          label: 'Change',
                          onPressed: () {
                            _googleSignIn.signOut();
                            setState(() {
                              _googleUser = null;
                            });
                          },
                          variant: ButtonVariant.ghost,
                          isDarkMode: isDarkMode,
                          size: ButtonSize.small,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: _fileIdController,
                    label: 'Google Drive File/Folder ID',
                    hintText: 'Enter the ID from the Drive URL',
                    prefixIcon: Icons.folder_shared,
                    darkMode: isDarkMode,
                    errorText: _error,
                  ),
                ],
                
                if (_error != null && _googleUser != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Button(
                        label: 'Cancel',
                        onPressed: _isLoading 
                            ? null 
                            : () => Navigator.of(context).pop(),
                        variant: ButtonVariant.ghost,
                        isDarkMode: isDarkMode,
                        color: isDarkMode
                            ? Theme.of(context).colorScheme.onSurface.withAlpha(180)
                            : Theme.of(context).colorScheme.onSurface.withAlpha(120),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Button(
                        label: 'Connect',
                        onPressed: (_isLoading || _googleUser == null) 
                            ? null 
                            : _connectGoogleDrive,
                        variant: ButtonVariant.primary,
                        isDarkMode: isDarkMode,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}