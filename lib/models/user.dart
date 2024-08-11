// lib/models/user.dart

class UserModel {
  final String uid;
  final String email;
  final String username; // Added username
  final String role; // Added role
  final String profileImageUrl; // Added profile image URL

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.role,
    required this.profileImageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'role': role,
      'profileImageUrl': profileImageUrl,
    };
  }

  static UserModel fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      email: map['email'],
      username: map['username'],
      role: map['role'],
      profileImageUrl: map['profileImageUrl'],
    );
  }
}
