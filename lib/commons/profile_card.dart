import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prakriti/services/user_service.dart';
import 'package:prakriti/services/achievements_service.dart';
import 'package:flutter/services.dart'; // For clipboard operations

// ProfileCard is a StatefulWidget that displays a user's profile information including their achievements
class ProfileCard extends StatefulWidget {
  final String userId; // The ID of the user whose profile is being displayed

  const ProfileCard({super.key, required this.userId});

  @override
  _ProfileCardState createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  String? _profileImage; // URL of the user's profile image
  String? _backgroundImage; // URL of the user's background image
  String? _username; // The username of the user
  String? _role; // The role of the user (e.g., admin, member)
  Map<String, bool> _achievements = {}; // Map of achievements and their unlocked status

  final UserService _userService = UserService(); // Instance of UserService for fetching user-related data
  final AchievementsService _achievementsService = AchievementsService(); // Instance of AchievementsService for fetching achievements

  @override
  void initState() {
    super.initState();
    _loadUserProfile(); // Load user profile information
    _loadUserAchievements(); // Load user achievements
  }

  // Fetches the user's profile information from Firestore
  Future<void> _loadUserProfile() async {
    try {
      // Retrieve profile document from Firestore
      DocumentSnapshot<Map<String, dynamic>> profileDoc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(widget.userId)
          .get();

      if (profileDoc.exists) {
        setState(() {
          // Set profile and background images if they exist
          _profileImage = profileDoc.data()?['profile_image'];
          _backgroundImage = profileDoc.data()?['background_image'];
        });
      }

      // Fetch username and role using UserService
      String? username = await _userService.getUserUsername(widget.userId);
      String? role = await _userService.getUserRole(widget.userId);

      setState(() {
        _username = username; // Update username
        _role = role; // Update role
      });
    } catch (e) {
      // Handle errors (e.g., network issues, missing data)
    }
  }

  // Fetches the user's achievements status
  Future<void> _loadUserAchievements() async {
    try {
      List<String> achievementIds = [
        'level_1', 'level_5', 'level_10', 'level_20', 'level_50',
        'made_1_pal', 'made_10_pals'
      ];
      Map<String, bool> achievements = {};

      // Check if each achievement is unlocked
      for (String id in achievementIds) {
        achievements[id] = await _achievementsService.isAchievementUnlocked(widget.userId, id);
      }

      setState(() {
        _achievements = achievements; // Update achievements map
      });
    } catch (e) {
      // Handle errors (e.g., network issues, missing data)
    }
  }

  // Builds the icon for an achievement based on its unlocked status
  Widget _buildAchievementIcon(String achievementId, IconData icon) {
    bool isUnlocked = _achievements[achievementId] ?? false;

    return isUnlocked
        ? Icon(
            icon,
            color: Colors.green, // Color for unlocked achievements
            size: 30, // Size of the icon
          )
        : const SizedBox.shrink(); // Hide the icon if not unlocked
  }

  // Copies the user ID to the clipboard and shows a confirmation snack bar
  void _copyUserId() {
    Clipboard.setData(ClipboardData(text: widget.userId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('User ID copied to clipboard!'), // Snack bar message
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5, // Elevation for card shadow
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), // Rounded corners for the card
      ),
      child: Container(
        width: 300, // Width of the profile card
        height: 400, // Height of the profile card
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10), // Rounded corners for the container
          image: _backgroundImage != null && _backgroundImage != 'none'
              ? DecorationImage(
                  image: AssetImage(_backgroundImage!), // Background image
                  fit: BoxFit.cover, // Cover the entire container
                )
              : null,
          color: _backgroundImage == 'none' ? Colors.grey.shade200 : null, // Fallback color if no background image
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Padding inside the card
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile Image Section
              CircleAvatar(
                radius: 50, // Radius of the profile image
                backgroundImage: _profileImage != null && _profileImage != 'none'
                    ? AssetImage(_profileImage!) // Profile image
                    : null,
                child: _profileImage == 'none'
                    ? const Icon(
                        Icons.account_circle,
                        size: 100, // Default icon size
                      )
                    : null,
              ),
              const SizedBox(height: 10), // Spacing between profile image and username
              // Username Section
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade800, // Background color for the username container
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                ),
                padding: const EdgeInsets.all(8), // Padding inside the container
                child: Text(
                  _username ?? 'Username', // Display username or placeholder text
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 5), // Spacing between username and role
              // Role Section
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade800, // Background color for the role container
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                ),
                padding: const EdgeInsets.all(8), // Padding inside the container
                child: Text(
                  'Role: ${_role ?? 'Unknown'}', // Display role or placeholder text
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 5), // Spacing between role and user ID
              // User ID Section with Copy Button
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800, // Background color for the user ID container
                        borderRadius: BorderRadius.circular(10), // Rounded corners
                      ),
                      padding: const EdgeInsets.all(8), // Padding inside the container
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.userId, // Display the user ID
                              style: const TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, color: Colors.white), // Copy icon
                            onPressed: _copyUserId, // Copy user ID to clipboard
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10), // Spacing before achievements
              const Text(
                'Achievements', // Title for achievements section
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5), // Spacing between title and achievement icons
              // Achievements Section
              Row(
                mainAxisAlignment: MainAxisAlignment.center, // Center align achievement icons
                children: [
                  _buildAchievementIcon('level_1', Icons.cake),
                  _buildAchievementIcon('level_5', Icons.arrow_upward),
                  _buildAchievementIcon('level_10', Icons.celebration),
                  _buildAchievementIcon('level_20', Icons.rocket_launch),
                  _buildAchievementIcon('level_50', Icons.stars_rounded),
                  _buildAchievementIcon('made_1_pal', Icons.handshake),
                  _buildAchievementIcon('made_10_pals', Icons.groups),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
