import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // Import this for Flutter icons
import 'package:prakriti/services/user_service.dart';
import 'package:prakriti/models/profile_assets.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String userId;
  String profileImage;
  String backgroundImage;

  // Use Flutter icon instead of an asset path for default profile image
  static const String defaultProfileImage = 'flutter_icon'; // Use identifier for default icon
  static const String defaultBackgroundImage = 'assets/default_background_image.png'; // Update to correct asset path

  ProfileService({
    required this.userId,
    this.profileImage = defaultProfileImage,
    this.backgroundImage = defaultBackgroundImage,
  });

  /// Fetches the user profile from Firestore.
  Future<void> fetchUserProfile() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> profileDoc = await _firestore.collection('profiles').doc(userId).get();
      if (profileDoc.exists) {
        Map<String, dynamic>? data = profileDoc.data();
        profileImage = data?['profile_image'] ?? defaultProfileImage;
        backgroundImage = data?['background_image'] ?? defaultBackgroundImage;
      } else {
        await createDefaultUserProfile();
      }
    } catch (e) {
    }
  }

  /// Creates a default user profile in Firestore.
  Future<void> createDefaultUserProfile() async {
    try {
      await _firestore.collection('profiles').doc(userId).set({
        'profile_image': defaultProfileImage,
        'background_image': defaultBackgroundImage,
      });
    } catch (e) {
    }
  }

  /// Updates the user profile in Firestore.
  Future<void> updateUserProfile() async {
    try {
      await _firestore.collection('profiles').doc(userId).set({
        'profile_image': profileImage,
        'background_image': backgroundImage,
      }, SetOptions(merge: true));
    } catch (e) {
    }
  }

  /// Sets the profile image and updates Firestore.
  void setProfileImage(String assetId) {
    String imagePath = ProfileAssets.getAssetPath(assetId);
    profileImage = imagePath.isEmpty ? defaultProfileImage : imagePath;
    updateUserProfile();
  }

  /// Sets the background image and updates Firestore.
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
  Widget getProfileImageWidget(String imageUrl) {
    if (imageUrl == defaultProfileImage) {
      return const Icon(
        Icons.account_circle,
        size: 100, // Adjust size as needed
        color: Colors.grey, // Set color for the default icon
      );
    } else {
      return Image.asset(ProfileAssets.getAssetPath(imageUrl)); // For custom asset image
    }
  }
}
