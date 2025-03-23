import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Class to handle Firestore security rule issues
class FirebaseRulesManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();
  
  /// Singleton instance
  static final FirebaseRulesManager _instance = FirebaseRulesManager._();
  static FirebaseRulesManager get instance => _instance;
  
  /// Private constructor for singleton
  FirebaseRulesManager._();
  
  /// Tests permissions by attempting to read the current user's document
  Future<bool> testUserPermissions() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _logger.w('Cannot test permissions - no user logged in');
        return false;
      }
      
      // Try to read the current user's document
      await _firestore.collection('users').doc(user.uid).get();
      _logger.i('User has permission to read their own document');
      return true;
    } catch (e) {
      if (e is FirebaseException && e.code == 'permission-denied') {
        _logger.e('Permission denied when reading user document. Security rules may be misconfigured.');
        return false;
      }
      _logger.e('Error testing user permissions: $e');
      return false;
    }
  }
  
  /// Show recommended security rules
  String getRecommendedSecurityRules() {
    // Escape $ with \ to avoid Dart interpreting it as string interpolation
    return '''
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow users to read and write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Chat sessions - users can only access their own chats
    match /chatSessions/{sessionId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
      
      // Messages in chat sessions
      match /messages/{messageId} {
        allow read, write: if request.auth != null && 
                           get(/databases/\$(database)/documents/chatSessions/\$(sessionId)).data.userId == request.auth.uid;
      }
    }
    
    // Allow users to create auth events
    match /authEvents/{eventId} {
      allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
      allow read, update, delete: if false;
    }
  }
}
''';
  }
  
  /// Test if a collection is accessible
  Future<bool> testCollectionAccess(String collectionPath) async {
    try {
      // Just attempt to get one document to test permissions
      await _firestore.collection(collectionPath).limit(1).get();
      _logger.i('Access to collection $collectionPath: SUCCESS');
      return true;
    } catch (e) {
      if (e is FirebaseException && e.code == 'permission-denied') {
        _logger.e('Permission denied when accessing collection: $collectionPath');
        return false;
      }
      _logger.e('Error accessing collection $collectionPath: $e');
      return false;
    }
  }

  /// Get a diagnostic report of Firestore permissions
  Future<Map<String, dynamic>> getDiagnosticReport() async {
    final report = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'collections': <String, bool>{},
      'auth': <String, dynamic>{},
    };
    
    // Check authentication status
    final user = FirebaseAuth.instance.currentUser;
    report['auth']['isLoggedIn'] = user != null;
    if (user != null) {
      report['auth']['uid'] = user.uid;
      report['auth']['email'] = user.email;
      report['auth']['emailVerified'] = user.emailVerified;
    }
    
    // Test common collections
    final collections = ['users', 'chatSessions', 'authEvents'];
    for (final collection in collections) {
      report['collections'][collection] = await testCollectionAccess(collection);
    }
    
    // Special test: Current user's document
    if (user != null) {
      report['userDocumentAccess'] = await testUserPermissions();
    }
    
    _logger.i('Firebase rules diagnostic report generated');
    return report;
  }
}
