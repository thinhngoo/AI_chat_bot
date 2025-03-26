class UserModel {
  final String uid;
  final String email;
  final String? name;
  final DateTime createdAt;
  final bool isEmailVerified;
  final String? selectedModel; // Add selected model field

  UserModel({
    required this.uid,
    required this.email,
    this.name,
    required this.createdAt,
    this.isEmailVerified = false,
    this.selectedModel, // Add to constructor
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'isEmailVerified': isEmailVerified,
      'selectedModel': selectedModel, // Add to map
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'],
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      isEmailVerified: map['isEmailVerified'] ?? false,
      selectedModel: map['selectedModel'], // Get from map
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    DateTime? createdAt,
    bool? isEmailVerified,
    String? selectedModel, // Add to copyWith
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      selectedModel: selectedModel ?? this.selectedModel, // Include in copy
    );
  }
}