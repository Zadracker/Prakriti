import 'package:flutter/material.dart';
import 'package:prakriti/services/profile_service.dart';
import 'package:prakriti/services/shop_service.dart';
import 'package:prakriti/models/profile_assets.dart';

// Page for selecting a profile image
class ProfileImageSelectionPage extends StatefulWidget {
  final String? currentProfileImage; // Current profile image of the user
  final ValueChanged<String> onSelect; // Callback function for when an image is selected
  final ProfileService profileService; // Service for handling profile-related operations
  final ShopService shopService; // Service for handling shop-related operations

  const ProfileImageSelectionPage({super.key, 
    this.currentProfileImage,
    required this.onSelect,
    required this.profileService,
    required this.shopService,
  });

  @override
  _ProfileImageSelectionPageState createState() => _ProfileImageSelectionPageState();
}

class _ProfileImageSelectionPageState extends State<ProfileImageSelectionPage> {
  List<String> unlockedProfileImages = []; // List of profile images that the user has unlocked

  @override
  void initState() {
    super.initState();
    _fetchUnlockedAssets(); // Fetch unlocked assets when the page is initialized
  }

  // Fetches the list of unlocked profile images from the shop service
  Future<void> _fetchUnlockedAssets() async {
    final unlockedAssets = await widget.shopService.getUserUnlockedAssets();
    setState(() {
      unlockedProfileImages = unlockedAssets['profileImages'] ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Profile Image'), // Page title
      ),
      body: Column(
        children: [
          // Display the currently selected profile image or a default icon
          if (widget.currentProfileImage != null)
            CircleAvatar(
              radius: 50,
              backgroundImage: widget.currentProfileImage == ProfileService.defaultProfileImage
                  ? null
                  : AssetImage(ProfileAssets.getAssetPath(widget.currentProfileImage!)),
              child: widget.currentProfileImage == ProfileService.defaultProfileImage
                  ? const Icon(Icons.account_circle, size: 100)
                  : null,
            )
          else
            const CircleAvatar(
              radius: 50,
              child: Icon(Icons.account_circle, size: 100),
            ),
          Expanded(
            child: ListView(
              children: unlockedProfileImages.isEmpty
                  ? [
                      Center(
                        child: ListTile(
                          title: const Text('None bought yet! Go to store and buy.'), // Message if no images are unlocked
                          onTap: () {
                            Navigator.pushNamed(context, '/store'); // Navigate to the store page
                          },
                        ),
                      ),
                    ]
                  : [
                      // Display available profile images categorized by type
                      _buildExpansionTile('Normal', ProfileAssets.normalProfileImages, unlockedProfileImages),
                      _buildExpansionTile('Premium', ProfileAssets.premiumProfileImages, unlockedProfileImages),
                      _buildExpansionTile('Special', ProfileAssets.specialProfileImages, unlockedProfileImages),
                    ],
            ),
          ),
        ],
      ),
    );
  }

  // Builds an ExpansionTile for categorizing profile images
  Widget _buildExpansionTile(String title, Map<String, String> assets, List<String> unlockedAssets) {
    return ExpansionTile(
      title: Text(title), // Title of the category
      children: assets.entries
          .where((entry) => unlockedAssets.contains(entry.key)) // Filter unlocked assets
          .map(
            (entry) => ListTile(
              leading: CircleAvatar(
                backgroundImage: AssetImage(entry.value), // Display the profile image
              ),
              title: Text(entry.key), // Display the name of the profile image
              onTap: () {
                widget.onSelect(entry.key); // Notify the parent widget about the selection
                Navigator.pop(context); // Close the selection page
              },
            ),
          )
          .toList(),
    );
  }
}

// Page for selecting a background image
class BackgroundSelectionPage extends StatefulWidget {
  final String? currentBackgroundImage; // Current background image of the user
  final ValueChanged<String> onSelect; // Callback function for when an image is selected
  final ProfileService profileService; // Service for handling profile-related operations
  final ShopService shopService; // Service for handling shop-related operations

  const BackgroundSelectionPage({super.key, 
    this.currentBackgroundImage,
    required this.onSelect,
    required this.profileService,
    required this.shopService,
  });

  @override
  _BackgroundSelectionPageState createState() => _BackgroundSelectionPageState();
}

class _BackgroundSelectionPageState extends State<BackgroundSelectionPage> {
  List<String> unlockedBackgrounds = []; // List of background images that the user has unlocked

  @override
  void initState() {
    super.initState();
    _fetchUnlockedAssets(); // Fetch unlocked assets when the page is initialized
  }

  // Fetches the list of unlocked background images from the shop service
  Future<void> _fetchUnlockedAssets() async {
    final unlockedAssets = await widget.shopService.getUserUnlockedAssets();
    setState(() {
      unlockedBackgrounds = unlockedAssets['backgrounds'] ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Background Image'), // Page title
      ),
      body: Column(
        children: [
          // Display the currently selected background image or a default message
          if (widget.currentBackgroundImage != null)
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: widget.currentBackgroundImage == ProfileService.defaultBackgroundImage
                      ? AssetImage(ProfileAssets.getAssetPath(ProfileService.defaultBackgroundImage))
                      : AssetImage(ProfileAssets.getAssetPath(widget.currentBackgroundImage!)),
                  fit: BoxFit.cover, // Cover the entire container
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 200,
              color: Colors.grey[200], // Default background color
              child: const Center(child: Text('No Background Selected')), // Default message
            ),
          Expanded(
            child: ListView(
              children: unlockedBackgrounds.isEmpty
                  ? [
                      Center(
                        child: ListTile(
                          title: const Text('None bought yet! Go to store and buy.'), // Message if no backgrounds are unlocked
                          onTap: () {
                            Navigator.pushNamed(context, '/store'); // Navigate to the store page
                          },
                        ),
                      ),
                    ]
                  : [
                      // Display available background images categorized by type
                      _buildExpansionTile('Normal', ProfileAssets.normalBackgrounds, unlockedBackgrounds),
                      _buildExpansionTile('Premium', ProfileAssets.premiumBackgrounds, unlockedBackgrounds),
                      _buildExpansionTile('Special', ProfileAssets.specialBackgrounds, unlockedBackgrounds),
                    ],
            ),
          ),
        ],
      ),
    );
  }

  // Builds an ExpansionTile for categorizing background images
  Widget _buildExpansionTile(String title, Map<String, String> assets, List<String> unlockedAssets) {
    return ExpansionTile(
      title: Text(title), // Title of the category
      children: assets.entries
          .where((entry) => unlockedAssets.contains(entry.key)) // Filter unlocked assets
          .map(
            (entry) => ListTile(
              leading: Image.asset(entry.value, width: 50, height: 50, fit: BoxFit.cover), // Display the background image
              title: Text(entry.key), // Display the name of the background image
              onTap: () {
                widget.onSelect(entry.key); // Notify the parent widget about the selection
                Navigator.pop(context); // Close the selection page
              },
            ),
          )
          .toList(),
    );
  }
}
