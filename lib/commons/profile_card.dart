import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prakriti/services/user_service.dart';
import 'package:prakriti/services/achievements_service.dart';
import 'package:flutter/services.dart'; // For clipboard operations

class ProfileCard extends StatefulWidget {
  final String userId;

  const ProfileCard({super.key, required this.userId});

  @override
  _ProfileCardState createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  String? _profileImage;
  String? _backgroundImage;
  String? _username;
  String? _role;
  Map<String, bool> _achievements = {};

  final UserService _userService = UserService(); // Instantiate UserService
  final AchievementsService _achievementsService = AchievementsService(); // Instantiate AchievementsService

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadUserAchievements();
  }

  Future<void> _loadUserProfile() async {
    try {
      // Fetch profile details from Firestore
      DocumentSnapshot<Map<String, dynamic>> profileDoc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(widget.userId)
          .get();

      if (profileDoc.exists) {
        setState(() {
          _profileImage = profileDoc.data()?['profile_image'];
          _backgroundImage = profileDoc.data()?['background_image'];
        });
      }

      // Fetch username and role using UserService
      String? username = await _userService.getUserUsername(widget.userId);
      String? role = await _userService.getUserRole(widget.userId);

      setState(() {
        _username = username;
        _role = role;
      });
    } catch (e) {
    }
  }

  Future<void> _loadUserAchievements() async {
    try {
      List<String> achievementIds = [
        'level_1', 'level_5', 'level_10', 'level_20', 'level_50',
        'made_1_pal', 'made_10_pals'
      ];
      Map<String, bool> achievements = {};
      
      for (String id in achievementIds) {
        achievements[id] = await _achievementsService.isAchievementUnlocked(widget.userId, id);
      }
      
      setState(() {
        _achievements = achievements;
      });
    } catch (e) {
    }
  }

  Widget _buildAchievementIcon(String achievementId, IconData icon) {
    bool isUnlocked = _achievements[achievementId] ?? false;

    return isUnlocked
        ? Icon(
            icon,
            color: Colors.green,
            size: 30,
          )
        : const SizedBox.shrink(); // Hide the icon if not unlocked
  }

  void _copyUserId() {
    Clipboard.setData(ClipboardData(text: widget.userId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('User ID copied to clipboard!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        width: 300, // Adjusted width
        height: 400, // Adjusted height
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          image: _backgroundImage != null && _backgroundImage != 'none'
              ? DecorationImage(
                  image: AssetImage(_backgroundImage!),
                  fit: BoxFit.cover,
                )
              : null,
          color: _backgroundImage == 'none' ? Colors.grey.shade200 : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: _profileImage != null && _profileImage != 'none'
                    ? AssetImage(_profileImage!)
                    : null,
                child: _profileImage == 'none'
                    ? const Icon(
                        Icons.account_circle,
                        size: 100,
                      )
                    : null,
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(8),
                child: Text(
                  _username ?? 'Username',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 5),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Role: ${_role ?? 'Unknown'}',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.userId,
                              style: const TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, color: Colors.white),
                            onPressed: _copyUserId,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Achievements',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
