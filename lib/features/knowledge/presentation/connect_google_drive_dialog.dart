import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/knowledge_base_service.dart';

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
    final theme = Theme.of(context);

    return Dialog(
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
                Text(
                  'Connect Google Drive',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Connect your Google Drive to import documents.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                if (_googleUser == null) ...[
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _isConnecting ? null : _signInWithGoogle,
                      icon: const Icon(Icons.login),
                      label: _isConnecting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Sign in with Google'),
                    ),
                  ),
                ] else ...[
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage: _googleUser?.photoUrl != null
                          ? NetworkImage(_googleUser!.photoUrl!)
                          : null,
                      child: _googleUser?.photoUrl == null
                          ? Text(_googleUser!.displayName![0])
                          : null,
                    ),
                    title: Text(_googleUser!.displayName ?? 'Google User'),
                    subtitle: Text(_googleUser!.email),
                    trailing: TextButton(
                      onPressed: () {
                        _googleSignIn.signOut();
                        setState(() {
                          _googleUser = null;
                        });
                      },
                      child: const Text('Change'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _fileIdController,
                    decoration: const InputDecoration(
                      labelText: 'Google Drive File/Folder ID',
                      hintText: 'Enter the ID from the Drive URL',
                      prefixIcon: Icon(Icons.folder_shared),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a file or folder ID';
                      }
                      return null;
                    },
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: (_isLoading || _googleUser == null) ? null : _connectGoogleDrive,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Connect'),
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