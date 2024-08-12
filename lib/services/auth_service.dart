import 'dart:io'; // Required for File operations
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Authentication
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore database
import 'package:firebase_storage/firebase_storage.dart'; // Firebase Storage for file uploads
import 'package:flutter/material.dart'; // Flutter framework

// Service class to handle authentication and user management
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Auth instance for authentication
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore instance for database operations
  final FirebaseStorage _storage = FirebaseStorage.instance; // Firebase Storage instance for file uploads

  // Signs in a user with email and password
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      // Authenticate user with provided email and password
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;
      if (user != null) {
        // Fetch user role from Firestore
        DocumentSnapshot<Map<String, dynamic>> userDoc = await _firestore.collection('users').doc(user.uid).get();
        String role = userDoc.data()?['role'] ?? 'member';

        // Redirect based on user role (admin or regular member)
        if (role == 'admin') {
          // Example navigation (admin page)
          // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ManageApplicationsPage()));
        } else {
          // Example navigation (main page for regular users)
          // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainPage()));
        }
        return userCredential;
      }
      return null; // Return null if user is not authenticated
    } catch (e) {
      debugPrint('Sign-in error: $e'); // Print error to console
      return null; // Return null in case of error
    }
  }

  // Signs up a new user with email, password, and optional profile image
  Future<UserCredential?> signUpWithEmailAndPassword(String username, String email, String password, File? profileImage) async {
    try {
      // Create a new user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;
      if (user != null) {
        // Update user's profile with username
        await user.updateProfile(displayName: username);
        await user.reload();

        // Initialize user data to be saved in Firestore
        Map<String, dynamic> userData = {
          'username': username,
          'email': email,
          'role': 'member', // Default role for new users
          'profileImageUrl': '', // Default profile image URL
        };

        // If profile image is provided, upload it and update the URL
        if (profileImage != null) {
          String imageUrl = await uploadProfileImage(user.uid, profileImage);
          userData['profileImageUrl'] = imageUrl;
        }

        // Save user data in Firestore
        await _firestore.collection('users').doc(user.uid).set(userData);

        // Send email verification
        await sendEmailVerification(user);

        return userCredential;
      }
      return null; // Return null if user is not created
    } catch (e) {
      debugPrint('Sign-up error: $e'); // Print error to console
      return null; // Return null in case of error
    }
  }

  // Uploads profile image to Firebase Storage
  Future<String> uploadProfileImage(String userId, File profileImage) async {
    try {
      // Reference for the profile image in Firebase Storage
      final ref = _storage.ref().child('profile_images').child('$userId.jpg');
      // Upload the file to Firebase Storage
      await ref.putFile(profileImage);
      // Get the download URL of the uploaded image
      final imageUrl = await ref.getDownloadURL();
      return imageUrl; // Return the image URL
    } catch (e) {
      debugPrint('Upload error: $e'); // Print error to console
      throw Exception('Failed to upload profile image'); // Throw exception if upload fails
    }
  }

  // Sends an email verification to the user
  Future<void> sendEmailVerification(User user) async {
    try {
      // Send email verification if not already verified
      if (!user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      debugPrint('Email verification error: $e'); // Print error to console
      throw Exception('Failed to send email verification'); // Throw exception if verification fails
    }
  }

  // Sends a password reset email to the specified email address
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      // Send password reset email
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Password reset error: $e'); // Print error to console
      throw Exception('Failed to send password reset email'); // Throw exception if reset email fails
    }
  }

  // Signs out the currently authenticated user
  Future<void> signOut() async {
    try {
      // Sign out the user
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign-out error: $e'); // Print error to console
      throw Exception('Failed to sign out'); // Throw exception if sign-out fails
    }
  }

  // Updates the user's profile with a new username or profile image
  Future<void> updateUserProfile(String userId, {String? username, File? profileImage}) async {
    try {
      User? user = _auth.currentUser; // Get the currently authenticated user

      Map<String, dynamic> updateData = {};
      // Update username if provided
      if (username != null && username.isNotEmpty) {
        await user?.updateProfile(displayName: username);
        updateData['username'] = username;
      }

      // Update profile image if provided
      if (profileImage != null) {
        String imageUrl = await uploadProfileImage(userId, profileImage);
        updateData['profileImageUrl'] = imageUrl;
      }

      // If there are any updates, apply them to Firestore
      if (updateData.isNotEmpty) {
        await _firestore.collection('users').doc(userId).update(updateData);
      }
    } catch (e) {
      debugPrint('Update profile error: $e'); // Print error to console
      throw Exception('Failed to update user profile'); // Throw exception if update fails
    }
  }
}
