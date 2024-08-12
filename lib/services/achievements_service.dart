import 'package:cloud_firestore/cloud_firestore.dart';
import 'points_service.dart'; // Service to fetch user points and levels
import 'friends_service.dart'; // Service to manage and fetch friends data

// Service class to manage achievements
class AchievementsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore instance for database operations
  final PointsService _pointsService = PointsService(); // Service to get user points and level
  final FriendsService _friendsService = FriendsService(); // Service to get user friends and count

  // Unlocks a specific achievement for a user
  Future<void> unlockAchievement(String userId, String achievementId) async {
    try {
      // Update the user's achievements document with the new achievement
      await _firestore
          .collection('achievements')
          .doc(userId)
          .set({achievementId: true}, SetOptions(merge: true));
    } catch (e) {
      // Handle potential errors (e.g., network issues, permission errors)
      // Optionally log the error or notify the user
    }
  }

  // Checks if a specific achievement is unlocked for a user
  Future<bool> isAchievementUnlocked(String userId, String achievementId) async {
    try {
      // Fetch the achievements document for the user
      DocumentSnapshot<Map<String, dynamic>> doc = await _firestore
          .collection('achievements')
          .doc(userId)
          .get();
      // Return true if the achievement is unlocked, false otherwise
      return doc.exists && doc.data()?[achievementId] == true;
    } catch (e) {
      // Return false in case of any error
      return false;
    }
  }

  // Checks user level and unlocks level-based achievements
  Future<void> checkAndUnlockLevelAchievements(String userId) async {
    try {
      // Get the user's current level
      int level = await _pointsService.getUserLevel(userId);

      // Unlock achievements based on the user's level
      if (level >= 1) {
        await unlockAchievement(userId, 'level_1');
      }
      if (level >= 5) {
        await unlockAchievement(userId, 'level_5');
      }
      if (level >= 10) {
        await unlockAchievement(userId, 'level_10');
      }
      if (level >= 20) {
        await unlockAchievement(userId, 'level_20');
      }
      if (level >= 50) {
        await unlockAchievement(userId, 'level_50');
      }
    } catch (e) {
      // Handle potential errors (e.g., issues fetching user level)
      // Optionally log the error or notify the user
    }
  }

  // Checks the number of friends and unlocks friend-related achievements
  Future<void> checkAndUnlockFriendAchievements(String userId) async {
    try {
      // Get the count of the user's friends (pals)
      int palsCount = await _friendsService.getPalsCount(userId);

      // Unlock achievements based on the number of friends
      if (palsCount >= 1) {
        await unlockAchievement(userId, 'made_1_pal');
      }
      if (palsCount >= 10) {
        await unlockAchievement(userId, 'made_10_pals');
      }
    } catch (e) {
      // Handle potential errors (e.g., issues fetching friends count)
      // Optionally log the error or notify the user
    }
  }
}
