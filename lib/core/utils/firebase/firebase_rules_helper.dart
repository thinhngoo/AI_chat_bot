import 'package:flutter/material.dart';
import '../../../core/services/firestore/firestore_data_service.dart';

class FirebaseRulesHelper {
  /// Shows a dialog with recommended Firestore rules
  static void showFirestoreRulesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Firebase Security Rules'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'To fix Firestore permission issues, update your Firebase security rules:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                'Steps:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('1. Go to Firebase Console (console.firebase.google.com)'),
              const Text('2. Select your project'),
              const Text('3. Navigate to "Firestore Database"'),
              const Text('4. Click on "Rules" tab'),
              const Text('5. Replace with the rules below and click "Publish"'),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const SelectableText(
                  'rules_version = \'2\';\n'
                  'service cloud.firestore {\n'
                  '  match /databases/{database}/documents {\n'
                  '    // Allow users to access their own chat sessions\n'
                  '    match /chatSessions/{sessionId} {\n'
                  '      allow read, write, create: if request.auth != null && \n'
                  '                           (request.auth.uid == resource.data.userId || request.resource.data.userId == request.auth.uid);\n'
                  '      \n'
                  '      // Messages subcollection\n'
                  '      match /messages/{messageId} {\n'
                  '        allow read, write, create: if request.auth != null;\n'
                  '      }\n'
                  '    }\n'
                  '    \n'
                  '    // Allow users to access their own user documents\n'
                  '    match /users/{userId} {\n'
                  '      allow read, write: if request.auth != null && \n'
                  '                           request.auth.uid == userId;\n'
                  '    }\n'
                  '  }\n'
                  '}'
                ),
              ),
              const SizedBox(height: 8),
              const Text('Note: Rules take a few minutes to update after publishing.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final firestoreService = FirestoreDataService();
                  firestoreService.resetPermissionCheck();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Permission flag reset. Next operation will try to access Firestore.'))
                  );
                },
                child: const Text('Reset Permission Check'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Returns the recommended Firestore rules as a string
  static String getRecommendedRules() {
    return '''rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow users to access their own chat sessions
    match /chatSessions/{sessionId} {
      allow read, write, create: if request.auth != null && 
                          (request.auth.uid == resource.data.userId || 
                           request.resource.data.userId == request.auth.uid);
      
      // Messages subcollection - allow if parent session is accessible
      match /messages/{messageId} {
        allow read, write, create: if request.auth != null;
      }
    }
    
    // Allow users to access their own user documents
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}''';
  }
}
