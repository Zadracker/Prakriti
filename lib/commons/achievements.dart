import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prakriti/services/achievements_service.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  _AchievementsPageState createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  final AchievementsService _achievementsService = AchievementsService();
  final User? _user = FirebaseAuth.instance.currentUser;
  Map<String, bool> _achievements = {};

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    if (_user != null) {
      String userId = _user.uid;
      
      // Load level and friend achievements
      await _achievementsService.checkAndUnlockLevelAchievements(userId);
      await _achievementsService.checkAndUnlockFriendAchievements(userId);
      
      // Define all achievement IDs
      List<String> achievementIds = [
        'level_1', 'level_5', 'level_10', 'level_20', 'level_50',
        'made_1_pal', 'made_10_pals'
      ];
      
      // Check and update achievements
      Map<String, bool> achievements = {};
      for (String id in achievementIds) {
        achievements[id] = await _achievementsService.isAchievementUnlocked(userId, id);
      }
      
      setState(() {
        _achievements = achievements;
      });
    }
  }

  void _showAchievementDetails(String achievementId) {
    String title;
    String description;
    IconData icon;

    // Define details for each achievement
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
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAchievementCard(String achievementId, IconData icon) {
    bool isUnlocked = _achievements[achievementId] ?? false;

    return GestureDetector(
      onTap: () => _showAchievementDetails(achievementId),
      child: Card(
        color: isUnlocked ? Colors.green : Colors.grey,
        child: SizedBox(
          width: 100,
          height: 100,
          child: Center(
            child: Icon(
              icon,
              color: isUnlocked ? Colors.white : Colors.black,
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
        title: const Text('Achievements'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAchievements,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
