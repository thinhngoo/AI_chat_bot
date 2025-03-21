import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();
  
  // Reference to users collection
  CollectionReference get _usersCollection => _firestore.collection('users');
  
  // Create or update user document
  Future<void> saveUserData(UserModel user) async {
    try {
      await _usersCollection.doc(user.uid).set({
        'email': user.email,
        'name': user.name,
        'createdAt': FieldValue.serverTimestamp(),
        'isEmailVerified': user.isEmailVerified,
      });
      _logger.i('User data saved to Firestore: ${user.email}');
    } catch (e) {
      _logger.e('Error saving user data to Firestore: $e');
      throw 'Failed to save user data: $e';
    }
  }
  
  // Update a specific field in a user document
  Future<void> updateUserField(String uid, String field, dynamic value) async {
    try {
      await _usersCollection.doc(uid).update({field: value});
      _logger.i('Updated user field: $field');
    } catch (e) {
      _logger.e('Error updating user field: $e');
      throw 'Failed to update user data: $e';
    }
  }
  
  // Update email verification status
  Future<void> updateEmailVerificationStatus(String uid, bool isVerified) async {
    await updateUserField(uid, 'isEmailVerified', isVerified);
  }
  
  // Get user document by uid
  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return UserModel.fromMap({
          'uid': uid,
          ...data,
          // Convert Timestamp to DateTime string
          'createdAt': data['createdAt'] != null 
              ? (data['createdAt'] as Timestamp).toDate().toIso8601String()
              : DateTime.now().toIso8601String(),
        });
      }
      return null;
    } catch (e) {
      _logger.e('Error getting user data: $e');
      return null;
    }
  }
  
  // Delete user data
  Future<void> deleteUser(String uid) async {
    try {
      await _usersCollection.doc(uid).delete();
      _logger.i('User data deleted: $uid');
    } catch (e) {
      _logger.e('Error deleting user data: $e');
      throw 'Failed to delete user data: $e';
    }
  }
}
