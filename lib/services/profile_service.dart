import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // Import this for Flutter icons
import 'package:prakriti/services/user_service.dart';
import 'package:prakriti/models/profile_assets.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String userId; // Unique identifier for the user
  String profileImage; // URL or path to the user's profile image
  String backgroundImage; // URL or path to the user's background image

  // Default values for profile and background images
  static const String defaultProfileImage = 'flutter_icon'; // Use identifier for default icon
  static const String defaultBackgroundImage = 'assets/default_background_image.png'; // Correct asset path

  // Constructor for initializing ProfileService with a user ID and optional image paths
  ProfileService({
    required this.userId,
    this.profileImage = defaultProfileImage,
    this.backgroundImage = defaultBackgroundImage,
  });

  /// Fetches the user profile from Firestore.
  /// If the profile does not exist, a default profile is created.
  Future<void> fetchUserProfile() async {
    try {
      // Get the user's profile document from Firestore
      DocumentSnapshot<Map<String, dynamic>> profileDoc = await _firestore.collection('profiles').doc(userId).get();
      
      if (profileDoc.exists) {
        // If the document exists, set the profile and background images
        Map<String, dynamic>? data = profileDoc.data();
        profileImage = data?['profile_image'] ?? defaultProfileImage;
        backgroundImage = data?['background_image'] ?? defaultBackgroundImage;
      } else {
        // If the document does not exist, create a default profile
        await createDefaultUserProfile();
      }
    } catch (e) {
      // Handle any errors that occur
    }
  }

  /// Creates a default user profile in Firestore with default images.
  Future<void> createDefaultUserProfile() async {
    try {
      await _firestore.collection('profiles').doc(userId).set({
        'profile_image': defaultProfileImage,
        'background_image': defaultBackgroundImage,
      });
    } catch (e) {
      // Handle any errors that occur
    }
  }

  /// Updates the user profile in Firestore with the current profile and background images.
  Future<void> updateUserProfile() async {
    try {
      await _firestore.collection('profiles').doc(userId).set({
        'profile_image': profileImage,
        'background_image': backgroundImage,
      }, SetOptions(merge: true)); // Merge with existing data
    } catch (e) {
      // Handle any errors that occur
    }
  }

  /// Sets the profile image and updates Firestore.
  /// Uses the asset identifier to get the image path.
  void setProfileImage(String assetId) {
    String imagePath = ProfileAssets.getAssetPath(assetId);
    profileImage = imagePath.isEmpty ? defaultProfileImage : imagePath;
    updateUserProfile();
  }

  /// Sets the background image and updates Firestore.
  /// Uses the asset identifier to get the image path.
  void setBackgroundImage(String assetId) {
    String imagePath = ProfileAssets.getAssetPath(assetId);
    backgroundImage = imagePath.isEmpty ? defaultBackgroundImage : imagePath;
    updateUserProfile();
  }

  /// Returns the default profile image URL.
  Future<String> getDefaultProfileImage() async {
    return defaultProfileImage;
  }

  /// Returns the profile image URL based on user role and settings.
  /// If the user is an ECO_ADVOCATE, it checks for a custom profile image URL.
  Future<String> getProfileImage(String uid) async {
    UserService userService = UserService();
    String? role = await userService.getUserRole(uid);

    if (role == UserService.ECO_ADVOCATE) {
      // Check for custom profile image URL
      String? profileImageUrl = await userService.getUserProfileImageUrl(uid);
      if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
        return profileImageUrl;
      }
    }
    // Use default profile image if not ECO_ADVOCATE or no custom URL
    return defaultProfileImage;
  }

  /// Returns a widget for the profile image, using default or custom image.
  /// Displays an icon if the image is the default profile image.
  Widget getProfileImageWidget(String imageUrl) {
    if (imageUrl == defaultProfileImage) {
      return const Icon(
        Icons.account_circle,
        size: 100, // Adjust size as needed
        color: Colors.grey, // Set color for the default icon
      );
    } else {
      // For custom asset images, use the asset path
      return Image.asset(ProfileAssets.getAssetPath(imageUrl));
    }
  }
}
