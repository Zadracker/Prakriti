import 'package:flutter/material.dart';
import 'package:prakriti/models/profile_assets.dart';
import 'package:prakriti/services/profile_service.dart';
import 'package:prakriti/services/shop_service.dart';
import 'package:prakriti/commons/profile_settings.dart';

class ProfileCardEdit extends StatefulWidget {
  final ProfileService profileService;
  final ShopService shopService;

  const ProfileCardEdit({super.key, required this.profileService, required this.shopService});

  @override
  _ProfileCardEditState createState() => _ProfileCardEditState();
}

class _ProfileCardEditState extends State<ProfileCardEdit> {
  late String _profileImage;
  late String _backgroundImage;

  @override
  void initState() {
    super.initState();
    _profileImage = widget.profileService.profileImage;
    _backgroundImage = widget.profileService.backgroundImage;
  }

  void _updateProfileImage(String image) {
    setState(() {
      _profileImage = image;
    });
  }

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
        title: const Text('Edit Profile'),
        elevation: 4.0,
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
                  final selectedImage = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileImageSelectionPage(
                        currentProfileImage: _profileImage,
                        onSelect: _updateProfileImage,
                        profileService: widget.profileService,
                        shopService: widget.shopService,
                      ),
                    ),
                  );
                  if (selectedImage != null) {
                    setState(() {
                      _profileImage = selectedImage;
                    });
                  }
                },
                child: CircleAvatar(
                  radius: screenWidth > 600 ? 120 : 80, // Responsive size
                  backgroundImage: _profileImage == ProfileService.defaultProfileImage
                      ? null
                      : AssetImage(ProfileAssets.getAssetPath(_profileImage)),
                  child: _profileImage == ProfileService.defaultProfileImage
                      ? Icon(Icons.account_circle, size: screenWidth > 600 ? 120 : 80)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            // Background Image Section
            GestureDetector(
              onTap: () async {
                final selectedBackground = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BackgroundSelectionPage(
                      currentBackgroundImage: _backgroundImage,
                      onSelect: _updateBackgroundImage,
                      profileService: widget.profileService,
                      shopService: widget.shopService,
                    ),
                  ),
                );
                if (selectedBackground != null) {
                  setState(() {
                    _backgroundImage = selectedBackground;
                  });
                }
              },
              child: Container(
                height: screenWidth > 600 ? 300 : 200, // Responsive size
                width: screenWidth * 0.8, // 80% of screen width
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: _backgroundImage == ProfileService.defaultBackgroundImage
                        ? const AssetImage(ProfileService.defaultBackgroundImage)
                        : AssetImage(ProfileAssets.getAssetPath(_backgroundImage)),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(8.0), // Rounded corners
                ),
                child: _backgroundImage == ProfileService.defaultBackgroundImage
                    ? Center(
                        child: Text(
                          'Select Background',
                          style: TextStyle(color: Colors.white, fontSize: screenWidth > 600 ? 24 : 18, fontWeight: FontWeight.bold),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16.0),
            // Save Changes Button
            Center(
              child: SizedBox(
                width: screenWidth > 600 ? 200 : 150, // Responsive width
                child: ElevatedButton(
                  onPressed: () {
                    // Update the profile with the new images
                    widget.profileService.setProfileImage(_profileImage);
                    widget.profileService.setBackgroundImage(_backgroundImage);
                    widget.profileService.updateUserProfile();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green, // Button color
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    textStyle: const TextStyle(fontSize: 16.0),
                  ),
                  child: const Text('Save Changes'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
