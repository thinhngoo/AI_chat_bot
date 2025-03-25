import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this import for FirebaseAuth
import 'package:logger/logger.dart';
import '../../models/user_model.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/message.dart';
import '../../models/firebase/firebase_chat_session.dart';
import '../../utils/firebase/firebase_rules_manager.dart';

class FirestoreDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();
  
  // Flag to track permission issues
  bool _hasPermissionIssues = false;
  
  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _chatSessionsCollection => _firestore.collection('chatSessions');
  CollectionReference get _authEventsCollection => _firestore.collection('authEvents');
  
  // User data operations
  Future<void> createOrUpdateUser(UserModel user) async {
    if (_hasPermissionIssues) {
      _logger.w('Skipping Firestore operation due to previous permission issues');
      return;
    }
    
    try {
      await _usersCollection.doc(user.uid).set({
        'email': user.email,
        'name': user.name ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'isEmailVerified': user.isEmailVerified,
      }, SetOptions(merge: true));
      
      _logger.i('User data saved to Firestore: ${user.email}');
    } catch (e) {
      _handleFirestoreError(e, 'saving user data');
    }
  }
  
  // Get user by ID from Firestore
  Future<UserModel?> getUserById(String uid) async {
    if (_hasPermissionIssues) {
      _logger.w('Skipping Firestore operation due to previous permission issues');
      return null;
    }
    
    try {
      final doc = await _usersCollection.doc(uid).get();
      
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      
      final data = doc.data() as Map<String, dynamic>;
      
      return UserModel(
        uid: uid,
        email: data['email'] ?? '',
        name: data['name'],
        createdAt: data['createdAt'] != null 
            ? (data['createdAt'] as Timestamp).toDate() 
            : DateTime.now(),
        isEmailVerified: data['isEmailVerified'] ?? false,
      );
    } catch (e) {
      _handleFirestoreError(e, 'getting user by ID');
      return null;
    }
  }
  
  // Update specific user fields
  Future<bool> updateUserFields(String uid, Map<String, dynamic> fields) async {
    if (_hasPermissionIssues) {
      _logger.w('Skipping Firestore operation due to previous permission issues');
      return false;
    }
    
    try {
      // Add lastUpdated timestamp
      fields['lastUpdated'] = FieldValue.serverTimestamp();
      
      await _usersCollection.doc(uid).update(fields);
      _logger.i('Updated user fields for $uid: ${fields.keys.join(', ')}');
      return true;
    } catch (e) {
      _handleFirestoreError(e, 'updating user fields');
      return false;
    }
  }
  
  // Delete user data
  Future<bool> deleteUser(String uid) async {
    if (_hasPermissionIssues) {
      _logger.w('Skipping Firestore operation due to previous permission issues');
      return false;
    }
    
    try {
      // Get all user's chat sessions
      final chatSessions = await _chatSessionsCollection
          .where('userId', isEqualTo: uid)
          .get();
      
      // Use a batch to delete all related data
      final batch = _firestore.batch();
      
      // Add user document deletion to batch
      batch.delete(_usersCollection.doc(uid));
      
      // Add chat sessions deletion to batch
      for (var doc in chatSessions.docs) {
        batch.delete(doc.reference);
      }
      
      // Commit the batch
      await batch.commit();
      
      _logger.i('User data deleted successfully for $uid');
      return true;
    } catch (e) {
      _handleFirestoreError(e, 'deleting user data');
      return false;
    }
  }
  
  // Record authentication events
  Future<void> recordAuthEvent(String userId, String email, String eventType) async {
    if (_hasPermissionIssues) {
      _logger.w('Skipping Firestore operation due to previous permission issues');
      return;
    }
    
    try {
      await _authEventsCollection.add({
        'userId': userId,
        'email': email,
        'eventType': eventType, // login, register, logout, etc.
        'timestamp': FieldValue.serverTimestamp(),
        'platform': getPlatformInfo(),
      });
      
      _logger.i('Recorded auth event: $eventType for $email');
    } catch (e) {
      _handleFirestoreError(e, 'recording auth event');
      // Don't throw - non-critical operation
    }
  }
  
  // Get platform information for logging
  Map<String, dynamic> getPlatformInfo() {
    try {
      // Return basic platform information - can be expanded later
      return {
        'appType': 'Flutter',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {'error': 'Could not determine platform'};
    }
  }
  
  // Chat message operations
  Future<String?> saveChatSession(ChatSession session, String userId) async {
    if (_hasPermissionIssues) {
      _logger.w('Skipping Firestore operation due to previous permission issues');
      return null;
    }
    
    try {
      // Convert to Firebase model
      final firebaseSession = FirebaseChatSession.fromChatSession(session, userId);
      
      // Save session document
      await _chatSessionsCollection.doc(session.id).set(firebaseSession.toMap());
      
      // Save all messages to subcollection
      final messagesCollection = _chatSessionsCollection
          .doc(session.id)
          .collection('messages');
      
      // Clear existing messages
      await _deleteAllMessages(session.id);
      
      // Add all messages
      for (var message in firebaseSession.messages) {
        await messagesCollection.add(message.toMap());
      }
      
      return session.id;
    } catch (e) {
      _handleFirestoreError(e, 'saving chat session');
      return null;
    }
  }

  // Add single message to a chat session
  Future<bool> addMessageToSession(String sessionId, Message message, String userId) async {
    if (_hasPermissionIssues) {
      _logger.w('Skipping Firestore operation due to previous permission issues');
      return false;
    }
    
    try {
      // First check if the session exists
      final sessionDoc = await _chatSessionsCollection.doc(sessionId).get();
      
      if (!sessionDoc.exists) {
        // Create a minimal session document if it doesn't exist
        await _chatSessionsCollection.doc(sessionId).set({
          'userId': userId,
          'title': 'New Chat',
          'createdAt': FieldValue.serverTimestamp(),
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Just update the timestamp
        await _chatSessionsCollection.doc(sessionId).update({
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      // Add the message
      final firebaseMessage = FirebaseMessage.fromMessage(message);
      await _chatSessionsCollection
          .doc(sessionId)
          .collection('messages')
          .add(firebaseMessage.toMap());
      
      return true;
    } catch (e) {
      _handleFirestoreError(e, 'adding message');
      return false;
    }
  }
  
  // Delete all messages in a chat session
  Future<void> _deleteAllMessages(String sessionId) async {
    if (_hasPermissionIssues) {
      _logger.w('Skipping Firestore operation due to previous permission issues');
      return;
    }
    
    try {
      final messagesCollection = _chatSessionsCollection
          .doc(sessionId)
          .collection('messages');
          
      final messagesSnapshot = await messagesCollection.get();
      
      if (messagesSnapshot.docs.isEmpty) return;
      
      // Use batch write for better performance
      final batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      _handleFirestoreError(e, 'deleting messages');
    }
  }
  
  // Get all chat sessions for a user with proper message loading
  Future<List<ChatSession>> getUserChatSessions(String userId) async {
    if (_hasPermissionIssues) {
      _logger.w('Skipping Firestore operation due to previous permission issues');
      return [];
    }
    
    try {
      _logger.i('Fetching chat sessions for user: $userId');
      final querySnapshot = await _chatSessionsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('lastUpdatedAt', descending: true)
          .get();
          
      _logger.i('Found ${querySnapshot.docs.length} chat sessions');
      List<ChatSession> chatSessions = [];
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final sessionId = doc.id;
        
        _logger.i('Loading messages for session: $sessionId');
        
        // Get messages for this session
        final messagesSnapshot = await _chatSessionsCollection
            .doc(sessionId)
            .collection('messages')
            .orderBy('timestamp')
            .get();
            
        _logger.i('Found ${messagesSnapshot.docs.length} messages for session $sessionId');
            
        // Convert messages
        List<Message> messages = messagesSnapshot.docs.map((msgDoc) {
          final msgData = msgDoc.data();
          return Message(
            text: msgData['text'] ?? '',
            isUser: msgData['isUser'] ?? false,
            timestamp: msgData['timestamp'] != null 
                ? (msgData['timestamp'] as Timestamp).toDate() 
                : DateTime.now(),
            isTyping: msgData['isTyping'] ?? false,
          );
        }).toList();
        
        // Create ChatSession object
        chatSessions.add(ChatSession(
          id: sessionId,
          title: data['title'] ?? 'New Chat',
          messages: messages,
          createdAt: data['createdAt'] != null 
              ? (data['createdAt'] as Timestamp).toDate() 
              : DateTime.now(),
        ));
      }
      
      _logger.i('Successfully loaded ${chatSessions.length} chat sessions with messages');
      return chatSessions;
    } catch (e) {
      _handleFirestoreError(e, 'getting user chat sessions');
      return [];
    }
  }
  
  // Delete a chat session
  Future<bool> deleteChatSession(String sessionId) async {
    if (_hasPermissionIssues) {
      _logger.w('Skipping Firestore operation due to previous permission issues');
      return false;
    }
    
    try {
      // Delete all messages first
      await _deleteAllMessages(sessionId);
      
      // Delete the session document
      await _chatSessionsCollection.doc(sessionId).delete();
      
      return true;
    } catch (e) {
      _handleFirestoreError(e, 'deleting chat session');
      return false;
    }
  }
  
  // Handle Firestore errors centrally
  void _handleFirestoreError(dynamic error, String operation) {
    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        _hasPermissionIssues = true;
        _logger.e('⚠️ PERMISSION DENIED ERROR during $operation. This indicates your Firestore security rules are not correctly set.');
        _logger.e('Please configure your security rules in Firebase Console or review the instructions in the README.');
        
        // Log more diagnostic information
        _logger.i('Current Firebase Auth user: ${FirebaseAuth.instance.currentUser?.uid ?? "not logged in"}');
        
        // Log the recommended rules for reference
        _logger.i('Recommended security rules:\n${FirebaseRulesManager.instance.getRecommendedSecurityRules()}');
      } 
      else if (error.code == 'failed-precondition' && error.message?.contains('requires an index') == true) {
        _logger.e('⚠️ INDEX ERROR during $operation. This query requires a composite index.');
        
        // Extract the index creation URL if available
        final urlMatch = RegExp(r'https://console\.firebase\.google\.com[^\s]+').firstMatch(error.message ?? '');
        if (urlMatch != null) {
          _logger.i('Create the required index using this direct link:\n${urlMatch.group(0)}');
        }
        
        _logger.i('Index creation instructions:\n${FirebaseRulesManager.instance.getCompositeIndexInfo()}');
      }
      else {
        _logger.e('Error during $operation: $error');
      }
    } else {
      _logger.e('Error during $operation: $error');
    }
  }
  
  // Run a diagnostic check on Firestore permissions
  Future<Map<String, dynamic>> runDiagnosticCheck() async {
    return FirebaseRulesManager.instance.getDiagnosticReport();
  }
  
  // Reset the permission issues flag (e.g., after fixing rules)
  void resetPermissionCheck() {
    _hasPermissionIssues = false;
    _logger.i('Permission issue flag reset. Operations will be attempted again.');
  }
}
