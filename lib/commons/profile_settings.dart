import 'package:flutter/material.dart';
import 'package:prakriti/services/profile_service.dart';
import 'package:prakriti/services/shop_service.dart';
import 'package:prakriti/models/profile_assets.dart';

class ProfileImageSelectionPage extends StatefulWidget {
  final String? currentProfileImage;
  final ValueChanged<String> onSelect;
  final ProfileService profileService;
  final ShopService shopService;

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
  List<String> unlockedProfileImages = [];

  @override
  void initState() {
    super.initState();
    _fetchUnlockedAssets();
  }

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
        title: const Text('Select Profile Image'),
      ),
      body: Column(
        children: [
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
                          title: const Text('None bought yet! Go to store and buy.'),
                          onTap: () {
                            Navigator.pushNamed(context, '/store'); // Navigate to the store page
                          },
                        ),
                      ),
                    ]
                  : [
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

  Widget _buildExpansionTile(String title, Map<String, String> assets, List<String> unlockedAssets) {
    return ExpansionTile(
      title: Text(title),
      children: assets.entries
          .where((entry) => unlockedAssets.contains(entry.key))
          .map(
            (entry) => ListTile(
              leading: CircleAvatar(
                backgroundImage: AssetImage(entry.value),
              ),
              title: Text(entry.key),
              onTap: () {
                widget.onSelect(entry.key);
                Navigator.pop(context);
              },
            ),
          )
          .toList(),
    );
  }
}

class BackgroundSelectionPage extends StatefulWidget {
  final String? currentBackgroundImage;
  final ValueChanged<String> onSelect;
  final ProfileService profileService;
  final ShopService shopService;

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
  List<String> unlockedBackgrounds = [];

  @override
  void initState() {
    super.initState();
    _fetchUnlockedAssets();
  }

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
        title: const Text('Select Background Image'),
      ),
      body: Column(
        children: [
          if (widget.currentBackgroundImage != null)
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: widget.currentBackgroundImage == ProfileService.defaultBackgroundImage
                      ? AssetImage(ProfileAssets.getAssetPath(ProfileService.defaultBackgroundImage))
                      : AssetImage(ProfileAssets.getAssetPath(widget.currentBackgroundImage!)),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 200,
              color: Colors.grey[200],
              child: const Center(child: Text('No Background Selected')),
            ),
          Expanded(
            child: ListView(
              children: unlockedBackgrounds.isEmpty
                  ? [
                      Center(
                        child: ListTile(
                          title: const Text('None bought yet! Go to store and buy.'),
                          onTap: () {
                            Navigator.pushNamed(context, '/store'); // Navigate to the store page
                          },
                        ),
                      ),
                    ]
                  : [
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

  Widget _buildExpansionTile(String title, Map<String, String> assets, List<String> unlockedAssets) {
    return ExpansionTile(
      title: Text(title),
      children: assets.entries
          .where((entry) => unlockedAssets.contains(entry.key))
          .map(
            (entry) => ListTile(
              leading: Image.asset(entry.value, width: 50, height: 50, fit: BoxFit.cover),
              title: Text(entry.key),
              onTap: () {
                widget.onSelect(entry.key);
                Navigator.pop(context);
              },
            ),
          )
          .toList(),
    );
  }
}
