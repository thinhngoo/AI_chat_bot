// This file provides stubs for Firebase Auth on Windows to avoid import errors

class FirebaseAuth {
  static final FirebaseAuth _instance = FirebaseAuth._();
  static FirebaseAuth get instance => _instance;

  FirebaseAuth._();
  
  dynamic get currentUser => null;
  
  Future<dynamic> signInWithEmailAndPassword({
    required String email, 
    required String password
  }) async => null;
  
  Future<dynamic> createUserWithEmailAndPassword({
    required String email, 
    required String password
  }) async => null;
  
  Future<void> signOut() async {}
  
  Future<void> sendPasswordResetEmail({
    required String email
  }) async {}
}

class User {
  final String? email;
  final bool emailVerified = false;
  
  User({this.email});
  
  Future<void> sendEmailVerification() async {}
  Future<void> reload() async {}
}

class UserCredential {
  final User? user;
  UserCredential({this.user});
}