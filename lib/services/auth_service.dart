import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;
      if (user != null) {
        DocumentSnapshot<Map<String, dynamic>> userDoc = await _firestore.collection('users').doc(user.uid).get();
        String role = userDoc.data()?['role'] ?? 'member';

        // Redirect based on user role
        if (role == 'admin') {
          // Navigate to manage_applications.dart
          // Example:
          // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ManageApplicationsPage()));
        } else {
          // Navigate to the main page
          // Example:
          // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainPage()));
        }
        return userCredential;
      }
      return null;
    } catch (e) {
      debugPrint('Sign-in error: $e');
      return null;
    }
  }

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword(String username, String email, String password, File? profileImage) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;
      if (user != null) {
        await user.updateProfile(displayName: username);
        await user.reload();

        // Initialize user data
        Map<String, dynamic> userData = {
          'username': username,
          'email': email,
          'role': 'member',
          'profileImageUrl': '',
        };

        // If profile image is provided, upload it and update the URL
        if (profileImage != null) {
          String imageUrl = await uploadProfileImage(user.uid, profileImage);
          userData['profileImageUrl'] = imageUrl;
        }

        await _firestore.collection('users').doc(user.uid).set(userData);

        // Send email verification
        await sendEmailVerification(user);

        return userCredential;
      }
      return null;
    } catch (e) {
      debugPrint('Sign-up error: $e');
      return null;
    }
  }

  // Upload profile image to Firebase Storage
  Future<String> uploadProfileImage(String userId, File profileImage) async {
    try {
      final ref = _storage.ref().child('profile_images').child('$userId.jpg');
      await ref.putFile(profileImage);
      final imageUrl = await ref.getDownloadURL();
      return imageUrl;
    } catch (e) {
      debugPrint('Upload error: $e');
      throw Exception('Failed to upload profile image');
    }
  }

  // Send email verification
  Future<void> sendEmailVerification(User user) async {
    try {
      if (!user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      debugPrint('Email verification error: $e');
      throw Exception('Failed to send email verification');
    }
  }

  // Reset password
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Password reset error: $e');
      throw Exception('Failed to send password reset email');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign-out error: $e');
      throw Exception('Failed to sign out');
    }
  }

  // Method to update username or profile image
  Future<void> updateUserProfile(String userId, {String? username, File? profileImage}) async {
    try {
      User? user = _auth.currentUser;

      Map<String, dynamic> updateData = {};
      if (username != null && username.isNotEmpty) {
        await user?.updateProfile(displayName: username);
        updateData['username'] = username;
      }

      if (profileImage != null) {
        String imageUrl = await uploadProfileImage(userId, profileImage);
        updateData['profileImageUrl'] = imageUrl;
      }

      if (updateData.isNotEmpty) {
        await _firestore.collection('users').doc(userId).update(updateData);
      }
    } catch (e) {
      debugPrint('Update profile error: $e');
      throw Exception('Failed to update user profile');
    }
  }
}
