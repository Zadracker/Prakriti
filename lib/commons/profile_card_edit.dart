import 'package:flutter/material.dart';
import 'package:prakriti/models/profile_assets.dart'; // Import the profile assets model
import 'package:prakriti/services/profile_service.dart'; // Import the service for profile-related operations
import 'package:prakriti/services/shop_service.dart'; // Import the service for shop-related operations
import 'package:prakriti/commons/profile_settings.dart'; // Import the profile settings page

// ProfileCardEdit is a StatefulWidget that allows users to edit their profile and background images
class ProfileCardEdit extends StatefulWidget {
  final ProfileService profileService; // Service for managing profile data
  final ShopService shopService; // Service for managing shop-related operations

  const ProfileCardEdit({super.key, required this.profileService, required this.shopService});

  @override
  _ProfileCardEditState createState() => _ProfileCardEditState();
}

class _ProfileCardEditState extends State<ProfileCardEdit> {
  late String _profileImage; // Holds the current profile image URL
  late String _backgroundImage; // Holds the current background image URL

  @override
  void initState() {
    super.initState();
    // Initialize profile and background images from the profile service
    _profileImage = widget.profileService.profileImage;
    _backgroundImage = widget.profileService.backgroundImage;
  }

  // Updates the profile image and triggers a rebuild
  void _updateProfileImage(String image) {
    setState(() {
      _profileImage = image;
    });
  }

  // Updates the background image and triggers a rebuild
  void _updateBackgroundImage(String image) {
    setState(() {
      _backgroundImage = image;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width to adjust layout for different devices
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'), // Title of the page
        elevation: 4.0, // Elevation of the app bar
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Image Section
            Center(
              child: GestureDetector(
                onTap: () async {
                  // Navigate to the profile image selection page
                  final selectedImage = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileImageSelectionPage(
                        currentProfileImage: _profileImage,
                        onSelect: _updateProfileImage, // Callback to update profile image
                        profileService: widget.profileService,
                        shopService: widget.shopService,
                      ),
                    ),
                  );
                  if (selectedImage != null) {
                    setState(() {
                      _profileImage = selectedImage; // Update profile image
                    });
                  }
                },
                child: CircleAvatar(
                  radius: screenWidth > 600 ? 120 : 80, // Responsive size based on screen width
                  backgroundImage: _profileImage == ProfileService.defaultProfileImage
                      ? null
                      : AssetImage(ProfileAssets.getAssetPath(_profileImage)), // Display the profile image
                  child: _profileImage == ProfileService.defaultProfileImage
                      ? Icon(Icons.account_circle, size: screenWidth > 600 ? 120 : 80) // Default icon if no profile image
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            // Background Image Section
            GestureDetector(
              onTap: () async {
                // Navigate to the background image selection page
                final selectedBackground = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BackgroundSelectionPage(
                      currentBackgroundImage: _backgroundImage,
                      onSelect: _updateBackgroundImage, // Callback to update background image
                      profileService: widget.profileService,
                      shopService: widget.shopService,
                    ),
                  ),
                );
                if (selectedBackground != null) {
                  setState(() {
                    _backgroundImage = selectedBackground; // Update background image
                  });
                }
              },
              child: Container(
                height: screenWidth > 600 ? 300 : 200, // Responsive height based on screen width
                width: screenWidth * 0.8, // 80% of screen width
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: _backgroundImage == ProfileService.defaultBackgroundImage
                        ? const AssetImage(ProfileService.defaultBackgroundImage)
                        : AssetImage(ProfileAssets.getAssetPath(_backgroundImage)), // Display the background image
                    fit: BoxFit.cover, // Cover the entire container
                  ),
                  borderRadius: BorderRadius.circular(8.0), // Rounded corners
                ),
                child: _backgroundImage == ProfileService.defaultBackgroundImage
                    ? Center(
                        child: Text(
                          'Select Background',
                          style: TextStyle(color: Colors.white, fontSize: screenWidth > 600 ? 24 : 18, fontWeight: FontWeight.bold), // Text style
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16.0),
            // Save Changes Button
            Center(
              child: SizedBox(
                width: screenWidth > 600 ? 200 : 150, // Responsive width based on screen width
                child: ElevatedButton(
                  onPressed: () {
                    // Update the profile with the new images and save changes
                    widget.profileService.setProfileImage(_profileImage);
                    widget.profileService.setBackgroundImage(_backgroundImage);
                    widget.profileService.updateUserProfile(); // Save profile changes
                    Navigator.pop(context); // Return to previous screen
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green, // Button color
                    padding: const EdgeInsets.symmetric(vertical: 14.0), // Button padding
                    textStyle: const TextStyle(fontSize: 16.0), // Text style
                  ),
                  child: const Text('Save Changes'), // Button text
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
