import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prakriti/services/achievements_service.dart';

// The AchievementsPage class displays the achievements of the user.
class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  _AchievementsPageState createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  // Service instance for handling achievement-related operations
  final AchievementsService _achievementsService = AchievementsService();
  // Currently logged-in user
  final User? _user = FirebaseAuth.instance.currentUser;
  // Map to store the unlocked status of achievements
  Map<String, bool> _achievements = {};

  @override
  void initState() {
    super.initState();
    _loadAchievements(); // Load achievements when the widget is initialized
  }

  // Loads the achievements data for the current user
  Future<void> _loadAchievements() async {
    if (_user != null) {
      String userId = _user.uid;
      
      // Load achievements related to levels and friends
      await _achievementsService.checkAndUnlockLevelAchievements(userId);
      await _achievementsService.checkAndUnlockFriendAchievements(userId);
      
      // Define all achievement IDs to check
      List<String> achievementIds = [
        'level_1', 'level_5', 'level_10', 'level_20', 'level_50',
        'made_1_pal', 'made_10_pals'
      ];
      
      // Check if each achievement is unlocked and update the map
      Map<String, bool> achievements = {};
      for (String id in achievementIds) {
        achievements[id] = await _achievementsService.isAchievementUnlocked(userId, id);
      }
      
      setState(() {
        _achievements = achievements; // Update the state with fetched achievements
      });
    }
  }

  // Shows a dialog with details about a specific achievement
  void _showAchievementDetails(String achievementId) {
    String title;
    String description;
    IconData icon;

    // Provide details for each achievement ID
    switch (achievementId) {
      case 'level_1':
        title = 'Level 1 Achiever';
        description = 'Congratulations on reaching Level 1!';
        icon = Icons.cake;
        break;
      case 'level_5':
        title = 'Level 5 Achiever';
        description = 'Congratulations on reaching Level 5!';
        icon = Icons.arrow_upward;
        break;
      case 'level_10':
        title = 'Level 10 Achiever';
        description = 'Congratulations on reaching Level 10!';
        icon = Icons.celebration;
        break;
      case 'level_20':
        title = 'Level 20 Achiever';
        description = 'Congratulations on reaching Level 20!';
        icon = Icons.rocket_launch;
        break;
      case 'level_50':
        title = 'Level 50 Achiever';
        description = 'Congratulations on reaching Level 50!';
        icon = Icons.stars_rounded;
        break;
      case 'made_1_pal':
        title = 'First Planet Pal';
        description = 'Congratulations on making your first Planet Pal!';
        icon = Icons.handshake;
        break;
      case 'made_10_pals':
        title = 'Planet Pal Master';
        description = 'Congratulations on making 10 Planet Pals!';
        icon = Icons.groups;
        break;
      default:
        title = 'Unknown Achievement';
        description = 'Details not available.';
        icon = Icons.help;
        break;
    }

    // Show a dialog with achievement details
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Row(
            children: [
              Icon(icon, size: 50),
              const SizedBox(width: 10),
              Expanded(child: Text(description)),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  // Builds a card widget for displaying an achievement
  Widget _buildAchievementCard(String achievementId, IconData icon) {
    bool isUnlocked = _achievements[achievementId] ?? false; // Check if the achievement is unlocked

    return GestureDetector(
      onTap: () => _showAchievementDetails(achievementId), // Show details on tap
      child: Card(
        color: isUnlocked ? Colors.green : Colors.grey, // Change color based on achievement status
        child: SizedBox(
          width: 100,
          height: 100,
          child: Center(
            child: Icon(
              icon,
              color: isUnlocked ? Colors.white : Colors.black, // Change icon color based on achievement status
              size: 50,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'), // App bar title
      ),
      body: RefreshIndicator(
        onRefresh: _loadAchievements, // Refresh achievements data on pull-to-refresh
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section for level achievements
                const Text(
                  'Level Achievements',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildAchievementCard('level_1', Icons.cake),
                    _buildAchievementCard('level_5', Icons.arrow_upward),
                    _buildAchievementCard('level_10', Icons.celebration),
                    _buildAchievementCard('level_20', Icons.rocket_launch),
                    _buildAchievementCard('level_50', Icons.stars_rounded),
                  ],
                ),
                const SizedBox(height: 20),
                // Section for Planet Pals achievements
                const Text(
                  'Planet Pals Achievements',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildAchievementCard('made_1_pal', Icons.handshake),
                    _buildAchievementCard('made_10_pals', Icons.groups),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
